#include "GitBundle.h"

#include "GitResult.h"
#include "GitBranch.h"

#include <git2/errors.h>
#include <git2/pack.h>
#include <git2/types.h>
#include <git2/revwalk.h>
#include <git2/object.h>
#include <git2/refs.h>

#include <qprocess.h>
#include <qtemporarydir.h>

GitBundle::GitBundle(QObject *parent)
    : IGitController{parent}
{}

GitResult GitBundle::writeBundleFile(git_packbuilder *packbuilder,
                                           const BundleContext &context)
{
    // Create temporary directory for pack file
    QTemporaryDir tempDir;
    if (!tempDir.isValid()) {
        return GitResult(false, QVariant(),
                            "Failed to create temporary directory.");
    }

    // Write pack to temp directory
    int error = git_packbuilder_write(packbuilder,
                                      tempDir.path().toUtf8().constData(),
                                      0644, nullptr, nullptr);
    if (error != 0) {
        return GitResult(false, QVariant(),
                            "Failed to write pack files.");
    }

    // Find the created pack file
    QDir tempDirObj(tempDir.path());
    QFileInfoList packFiles = tempDirObj.entryInfoList(QStringList() << "*.pack",
                                                       QDir::Files);
    if (packFiles.isEmpty()) {
        return GitResult(false, QVariant(),
                            "No pack file was created.");
    }

    QString packFilePath = packFiles.first().absoluteFilePath();

    // Create bundle file
    QFile bundleFile(context.bundlePath);
    if (!bundleFile.open(QIODevice::WriteOnly)) {
        return GitResult(false, QVariant(),
                            QString("Cannot write to '%1'").arg(context.bundlePath));
    }

    // Write bundle header
    QByteArray header = "# v2 git bundle\n";
    header.append(context.commitSha.toUtf8());
    header.append(" ");
    header.append(context.refName.toUtf8());
    header.append("\n\n");

    if (bundleFile.write(header) != header.size()) {
        bundleFile.close();
        return GitResult(false, QVariant(), "Failed to write bundle header");
    }

    // Copy pack data to bundle
    QFile packFile(packFilePath);
    if (!packFile.open(QIODevice::ReadOnly)) {
        bundleFile.close();
        return GitResult(false, QVariant(), "Failed to read pack file");
    }

    const qint64 CHUNK_SIZE = 64 * 1024;
    while (!packFile.atEnd()) {
        QByteArray chunk = packFile.read(CHUNK_SIZE);
        if (bundleFile.write(chunk) != chunk.size()) {
            packFile.close();
            bundleFile.close();
            return GitResult(false, QVariant(), "Failed to write pack data");
        }
    }

    packFile.close();
    bundleFile.close();

    // Verify the bundle
    bool verified = verifyBundle(context.bundlePath);

    QString msg = verified
                      ? QString("Bundle created successfully at: %1").arg(context.bundlePath)
                      : QString("Bundle created but verification failed");

    return GitResult(verified, QVariant(), msg);
}


GitResult GitBundle::buildCompleteBundle(const QString &resolvedBranchName,
                                         const QString &refBranchName,
                                         const QString &path)
{
    BundleContext context;

    context.bundlePath = path.endsWith(".bundle") ? path : path + ".bundle";

    // Resolve branch to commit
    git_object* commit = GitBranch::getHead(m_currentRepo->repo, resolvedBranchName);

    const git_oid* commitOid = git_object_id(commit);
    QString headCommitSha = gitOidToString(commitOid);
    git_object_free(commit);


    context.commitSha = headCommitSha;
    context.branchName = resolvedBranchName;
    context.refName = refBranchName;

    // Setup packbuilder with all objects
    git_packbuilder* packbuilder = nullptr;
    git_revwalk* walker = nullptr;

    auto packResult = setupCompletePackbuilder(commitOid, packbuilder, walker);
    if (!packResult.success()) {
        cleanupBundleResources(nullptr, nullptr, walker, packbuilder);
        return packResult;
    }

    // Check object count
    size_t objectCount = git_packbuilder_object_count(packbuilder);
    if (objectCount == 0) {
        cleanupBundleResources(nullptr, nullptr, walker, packbuilder);
        return GitResult(false, QVariant(),
                            "No objects to bundle. Branch might be empty.");
    }

    GitResult result = writeBundleFile(packbuilder, context);

    cleanupBundleResources(nullptr, nullptr, walker, packbuilder);


    return GitResult(result.success());
}

GitResult GitBundle::buildDiffBundle(const QString &baseRef, const QString &targetRef,
                                     const QString &refBranchName,
                                     const QString &path)
{

    BundleContext context;
    context.bundlePath = path.endsWith(".bundle") ? path : path + ".bundle";

    // Resolve both references
    QPair<const git_oid *, QString> baseResult = getReferenceCommit(baseRef);
    if (!baseResult.first || baseResult.second.isEmpty())
        return GitResult(false);

    git_oid baseOid = *baseResult.first;
    QString baseSha = baseResult.second;

    QPair<const git_oid *, QString> targetResult = getReferenceCommit(targetRef);
    if (!targetResult.first || targetResult.second.isEmpty())
        return GitResult(false);

    git_oid targetOid = *targetResult.first;
    QString targetSha = targetResult.second;

    context.commitSha = targetSha;
    context.branchName = targetRef;
    context.refName = refBranchName;

    // Setup packbuilder with only new objects
    git_packbuilder* packbuilder = nullptr;
    git_revwalk* walker = nullptr;
    int commitCount = 0;
    QStringList newCommitShas;

    auto packResult = setupDiffPackbuilder(&baseOid, &targetOid,
                                           packbuilder, walker,
                                           commitCount, newCommitShas);
    if (!packResult.success()) {
        cleanupBundleResources(nullptr, nullptr, walker, packbuilder);
        return packResult;
    }

    // Validate we have new commits
    if (commitCount == 0) {
        cleanupBundleResources(nullptr, nullptr, walker, packbuilder);

        if (git_oid_equal(&baseOid, &targetOid)) {
            return GitResult(false, QVariant(),
                                QString("Base and target are the same commit (%1)")
                                    .arg(baseSha.left(8)));
        }

        return GitResult(false, QVariant(),
                            "No new commits to bundle.");
    }

    GitResult result = writeBundleFile(packbuilder, context);

    cleanupBundleResources(nullptr, nullptr, walker, packbuilder);

    return result;
}

GitResult GitBundle::setupCompletePackbuilder(const git_oid *targetOid,
                                                    git_packbuilder *&packbuilder,
                                                    git_revwalk *&walker)
{
    int error = git_packbuilder_new(&packbuilder, m_currentRepo->repo);
    if (error != GIT_OK) {
        return GitResult(false, QVariant(),
                            "Failed to create packbuilder.");
    }

    error = git_packbuilder_insert_commit(packbuilder, targetOid);
    if (error != GIT_OK) {
        return GitResult(false, QVariant(),
                            "Failed to insert objects into packbuilder.");
    }

    // Walk through history to include all commits
    error = git_revwalk_new(&walker, m_currentRepo->repo);
    if (error == GIT_OK) {
        git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL);
        git_revwalk_push(walker, targetOid);

        git_oid commitOid;
        int count = 0;
        while (git_revwalk_next(&commitOid, walker) == 0) {
            git_packbuilder_insert(packbuilder, &commitOid, nullptr);
            count++;
        }
    }

    return GitResult(true);
}

QPair<const git_oid *, QString> GitBundle::getReferenceCommit(const QString &ref)
{
    git_object* obj = nullptr;
    int error = git_revparse_single(&obj, m_currentRepo->repo,
                                    ref.toUtf8().constData());
    if (error != 0) {
        return QPair<git_oid *, QString>(nullptr, "");
    }

    const git_oid* commitOid = git_object_id(obj);
    QString commitSha = gitOidToString(commitOid);

    git_object_free(obj);
    return QPair<const git_oid *, QString>(commitOid, commitSha);
}

GitResult GitBundle::setupDiffPackbuilder(const git_oid *baseOid, const git_oid *targetOid, git_packbuilder *&packbuilder, git_revwalk *&walker, int &commitCount, QStringList &newCommitShas)
{
    int error = git_packbuilder_new(&packbuilder, m_currentRepo->repo);
    if (error != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to create packbuilder.");
    }

    error = git_revwalk_new(&walker, m_currentRepo->repo);
    if (error != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to create revision walker.");
    }

    // Configure walker: target minus base
    git_revwalk_sorting(walker, GIT_SORT_TOPOLOGICAL);
    git_revwalk_push(walker, targetOid);
    git_revwalk_hide(walker, baseOid);

    git_oid commitOid;
    newCommitShas.clear();

    while (git_revwalk_next(&commitOid, walker) == GIT_OK) {
        git_packbuilder_insert(packbuilder, &commitOid, nullptr);
        newCommitShas.append(gitOidToString(&commitOid));
        git_packbuilder_insert_commit(packbuilder, &commitOid);
        commitCount++;
    }

    return GitResult(true, QVariantMap());
}

bool GitBundle::verifyBundle(const QString &bundlePath)
{
    if (!QFile::exists(bundlePath)) {
        return false;
    }

    QProcess gitProcess;
    gitProcess.setProgram("git");
    gitProcess.setArguments(QStringList() << "bundle" << "verify" << bundlePath);

    // Get repository working directory
    const char* repoPath = git_repository_workdir(m_currentRepo->repo);
    QString workingDir;

    if (repoPath) {
        workingDir = QString::fromUtf8(repoPath);
    } else {
        repoPath = git_repository_path(m_currentRepo->repo);
        workingDir = QString::fromUtf8(repoPath);

        // For bare repos, go up one directory
        if (workingDir.endsWith("/.git")) {
            workingDir = workingDir.left(workingDir.length() - 5);
        }
    }

    gitProcess.setWorkingDirectory(workingDir);
    gitProcess.setProcessChannelMode(QProcess::MergedChannels);

    gitProcess.start();

    if (!gitProcess.waitForStarted(3000)) {
        return false;
    }

    if (!gitProcess.waitForFinished(15000)) {
        gitProcess.kill();
        return false;
    }

    QString output = QString::fromUtf8(gitProcess.readAll()).trimmed();

    return gitProcess.exitCode() == 0;
}

GitResult GitBundle::unbundleWithCli(const QString &bundlePath)
{
    if (!QFile::exists(bundlePath)) {
        return false;
    }

    QProcess gitProcess;
    gitProcess.setProgram("git");
    gitProcess.setArguments(QStringList() << "bundle" << "unbundle" << bundlePath);

    gitProcess.start();

    if (!gitProcess.waitForStarted(3000)) {
        return GitResult(false, QVariant(), "Failed to start Git verify process.");
    }

    if (!gitProcess.waitForFinished(15000)) {
        gitProcess.kill();
        return GitResult(false, QVariant(), "Git Unbundle timed out.");
    }

    QString output = QString::fromUtf8(gitProcess.readAll()).trimmed();

    if((gitProcess.exitCode() == 0)){
        QStringList outputSplited = output.split(" ");

        QVariantMap data;
        data["SHA"] =outputSplited[0];

        return GitResult(true, data);
    }

    return GitResult(false, QVariant(), output);
}

void GitBundle::cleanupBundleResources(git_reference *ref, git_object *object, git_revwalk *walker, git_packbuilder *packbuilder)
{
    if (packbuilder)
        git_packbuilder_free(packbuilder);
    if (walker)
        git_revwalk_free(walker);
    if (object)
        git_object_free(object);
    if (ref)
        git_reference_free(ref);
}
