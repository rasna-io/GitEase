#include <QtTest/QtTest>
#include <QDir>
#include <QFile>
#include <QTemporaryDir>

#include <git2.h>

#include "Git/GitRemote.h"
#include "Git/GitResult.h"
#include "Git/Models/Repository.h"

namespace {

bool writeTextFile(const QString& filePath, const QByteArray& payload)
{
    QFile file(filePath);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return false;
    }
    return file.write(payload) == payload.size();
}

bool createInitialCommit(git_repository* repo, const QString& relativeFile, const QByteArray& content)
{
    const char* workdir = git_repository_workdir(repo);
    if (!workdir) {
        return false;
    }

    const QString filePath = QDir::fromNativeSeparators(QString::fromUtf8(workdir)) + "/" + relativeFile;
    if (!writeTextFile(filePath, content)) {
        return false;
    }

    git_index* index = nullptr;
    if (git_repository_index(&index, repo) != GIT_OK) {
        return false;
    }

    const QByteArray rel = relativeFile.toUtf8();
    if (git_index_add_bypath(index, rel.constData()) != GIT_OK) {
        git_index_free(index);
        return false;
    }

    if (git_index_write(index) != GIT_OK) {
        git_index_free(index);
        return false;
    }

    git_oid treeOid;
    if (git_index_write_tree(&treeOid, index) != GIT_OK) {
        git_index_free(index);
        return false;
    }

    git_tree* tree = nullptr;
    if (git_tree_lookup(&tree, repo, &treeOid) != GIT_OK) {
        git_index_free(index);
        return false;
    }

    git_signature* signature = nullptr;
    if (git_signature_now(&signature, "GitEase Tests", "tests@gitease.local") != GIT_OK) {
        git_tree_free(tree);
        git_index_free(index);
        return false;
    }

    git_oid commitOid;
    const int commitResult = git_commit_create_v(
        &commitOid,
        repo,
        "HEAD",
        signature,
        signature,
        nullptr,
        "initial commit",
        tree,
        0);

    git_signature_free(signature);
    git_tree_free(tree);
    git_index_free(index);

    return commitResult == GIT_OK;
}

QString currentBranchName(git_repository* repo)
{
    git_reference* headRef = nullptr;
    if (git_repository_head(&headRef, repo) != GIT_OK) {
        return {};
    }

    const char* shorthand = git_reference_shorthand(headRef);
    const QString name = shorthand ? QString::fromUtf8(shorthand) : QString();
    git_reference_free(headRef);
    return name;
}

bool initRepository(const QString& path, bool bare, git_repository** outRepo)
{
    *outRepo = nullptr;
    return git_repository_init(outRepo, path.toUtf8().constData(), bare ? 1 : 0) == GIT_OK;
}

//! Commits files (path -> content) on top of HEAD, or as the first commit.
bool commitFiles(git_repository* repo, const QMap<QString, QByteArray>& files, const char* message)
{
    const QString workdir = QDir::fromNativeSeparators(QString::fromUtf8(git_repository_workdir(repo)));

    git_index* index = nullptr;
    if (git_repository_index(&index, repo) != GIT_OK)
        return false;

    for (auto it = files.constBegin(); it != files.constEnd(); ++it) {
        if (!writeTextFile(workdir + "/" + it.key(), it.value())
            || git_index_add_bypath(index, it.key().toUtf8().constData()) != GIT_OK) {
            git_index_free(index);
            return false;
        }
    }

    git_oid treeOid;
    const bool indexOk = git_index_write(index) == GIT_OK && git_index_write_tree(&treeOid, index) == GIT_OK;
    git_index_free(index);
    if (!indexOk)
        return false;

    git_tree* tree = nullptr;
    git_signature* signature = nullptr;
    git_commit* parent = nullptr;
    git_oid parentOid;
    const bool hasParent = git_reference_name_to_id(&parentOid, repo, "HEAD") == GIT_OK
                           && git_commit_lookup(&parent, repo, &parentOid) == GIT_OK;

    git_oid commitOid;
    const bool ok = git_tree_lookup(&tree, repo, &treeOid) == GIT_OK
                    && git_signature_now(&signature, "GitEase Tests", "tests@gitease.local") == GIT_OK
                    && git_commit_create_v(&commitOid, repo, "HEAD", signature, signature, nullptr,
                                           message, tree, hasParent ? 1 : 0, parent) == GIT_OK;

    git_commit_free(parent);
    git_signature_free(signature);
    git_tree_free(tree);
    return ok;
}

//! Line endings normalized, since checkout honours the user's core.autocrlf.
QByteArray readTextFile(const QString& filePath)
{
    QFile file(filePath);
    return file.open(QIODevice::ReadOnly) ? file.readAll().replace("\r\n", "\n") : QByteArray();
}

QString headOid(git_repository* repo)
{
    git_oid oid;
    if (git_reference_name_to_id(&oid, repo, "HEAD") != GIT_OK)
        return {};
    char hash[GIT_OID_HEXSZ + 1];
    git_oid_tostr(hash, sizeof(hash), &oid);
    return QString::fromLatin1(hash);
}

}  // namespace

class TestGitRemote : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    void remoteCrudWorks();
    void pushFetchAndUpstreamWork();
    void fastForwardPullKeepsLocalChanges();
    void noRepositoryValidation();
};

void TestGitRemote::initTestCase()
{
    QVERIFY(git_libgit2_init() >= 0);
}

void TestGitRemote::cleanupTestCase()
{
    git_libgit2_shutdown();
}

void TestGitRemote::remoteCrudWorks()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString localPath = dir.path() + "/local";
    const QString remotePath = dir.path() + "/remote.git";
    QVERIFY(QDir().mkpath(localPath));
    QVERIFY(QDir().mkpath(remotePath));

    git_repository* localRepo = nullptr;
    git_repository* bareRemoteRepo = nullptr;

    QVERIFY(initRepository(localPath, false, &localRepo));
    QVERIFY(initRepository(remotePath, true, &bareRemoteRepo));
    QVERIFY(createInitialCommit(localRepo, "README.md", "hello"));

    Repository current(localRepo);
    GitRemote controller;
    controller.setCurrentRepo(&current);

    GitResult addResult = controller.addRemote("origin", QDir::fromNativeSeparators(remotePath));
    QVERIFY(addResult.success());

    GitResult duplicateAdd = controller.addRemote("origin", QDir::fromNativeSeparators(remotePath));
    QVERIFY(!duplicateAdd.success());

    GitResult getUrl = controller.getRemoteUrl("origin");
    QVERIFY(getUrl.success());
    const QVariantMap urlMap = getUrl.data().toMap();
    QCOMPARE(urlMap.value("remote").toString(), QString("origin"));
    QVERIFY(!urlMap.value("fetchUrl").toString().isEmpty());

    GitResult remotes = controller.getRemotes();
    QVERIFY(remotes.success());

    const QString updatedUrl = QDir::fromNativeSeparators(dir.path() + "/remote-renamed.git");
    QVERIFY(QDir().mkpath(updatedUrl));
    git_repository* renamedBareRemoteRepo = nullptr;
    QVERIFY(initRepository(updatedUrl, true, &renamedBareRemoteRepo));

    GitResult edit = controller.editRemote("origin", "upstream", updatedUrl);
    QVERIFY(edit.success());

    GitResult getEdited = controller.getRemoteUrl("upstream");
    QVERIFY(getEdited.success());
    QCOMPARE(getEdited.data().toMap().value("remote").toString(), QString("upstream"));

    GitResult remove = controller.removeRemote("upstream");
    QVERIFY(remove.success());

    GitResult removeMissing = controller.removeRemote("upstream");
    QVERIFY(!removeMissing.success());

    git_repository_free(renamedBareRemoteRepo);
    git_repository_free(bareRemoteRepo);
    // localRepo is owned by `current` (Repository), freed by its destructor.
}

void TestGitRemote::pushFetchAndUpstreamWork()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString localPath = dir.path() + "/local";
    const QString remotePath = dir.path() + "/remote.git";
    const QString consumerPath = dir.path() + "/consumer";
    QVERIFY(QDir().mkpath(localPath));
    QVERIFY(QDir().mkpath(remotePath));
    QVERIFY(QDir().mkpath(consumerPath));

    git_repository* localRepo = nullptr;
    git_repository* bareRemoteRepo = nullptr;
    git_repository* consumerRepo = nullptr;

    QVERIFY(initRepository(localPath, false, &localRepo));
    QVERIFY(initRepository(remotePath, true, &bareRemoteRepo));
    QVERIFY(initRepository(consumerPath, false, &consumerRepo));

    QVERIFY(createInitialCommit(localRepo, "main.txt", "v1"));
    const QString branch = currentBranchName(localRepo);
    QVERIFY(!branch.isEmpty());

    Repository localWrapper(localRepo);
    GitRemote localController;
    localController.setCurrentRepo(&localWrapper);

    QVERIFY(localController.addRemote("origin", QDir::fromNativeSeparators(remotePath)).success());

    QSignalSpy pushSpy(&localController, &GitRemote::pushFinished);
    GitResult pushStart = localController.push("origin", branch, "dummy-token", false);
    QVERIFY(pushStart.success());
    QVERIFY(pushSpy.wait(5000));
    QVERIFY(pushSpy.at(0).at(0).toMap().value("success").toBool());

    git_reference* remoteBranch = nullptr;
    QCOMPARE(git_branch_lookup(&remoteBranch,
                               bareRemoteRepo,
                               branch.toUtf8().constData(),
                               GIT_BRANCH_LOCAL),
             GIT_OK);
    git_reference_free(remoteBranch);

    git_reference* localBranch = nullptr;
    QCOMPARE(git_branch_lookup(&localBranch,
                               localRepo,
                               branch.toUtf8().constData(),
                               GIT_BRANCH_LOCAL),
             GIT_OK);
    QCOMPARE(git_branch_set_upstream(localBranch, QString("origin/%1").arg(branch).toUtf8().constData()), GIT_OK);
    git_reference_free(localBranch);

    GitResult upstream = localController.getUpstreamName(branch);
    QVERIFY(upstream.success());
    QCOMPARE(upstream.data().toString(), QString("origin/%1").arg(branch));

    Repository consumerWrapper(consumerRepo);
    GitRemote consumerController;
    consumerController.setCurrentRepo(&consumerWrapper);
    QVERIFY(consumerController.addRemote("origin", QDir::fromNativeSeparators(remotePath)).success());

    GitResult autoFetch = consumerController.fetch("origin");
    QVERIFY(!autoFetch.success());

    QSignalSpy fetchSpy(&consumerController, &GitRemote::fetchFinished);
    GitResult fetchStart = consumerController.fetchWithToken("origin", "dummy-token");
    QVERIFY(fetchStart.success());
    QVERIFY(fetchSpy.wait(5000));
    QVERIFY(fetchSpy.at(0).at(0).toMap().value("success").toBool());

    git_reference* trackingRef = nullptr;
    const QByteArray trackingName = QString("refs/remotes/origin/%1").arg(branch).toUtf8();
    QCOMPARE(git_reference_lookup(&trackingRef, consumerRepo, trackingName.constData()), GIT_OK);
    git_reference_free(trackingRef);

    git_repository_free(bareRemoteRepo);
    // localRepo and consumerRepo are owned by localWrapper/consumerWrapper
    // (Repository), freed by their destructors.
}

void TestGitRemote::fastForwardPullKeepsLocalChanges()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString upstreamPath = QDir::fromNativeSeparators(dir.path() + "/upstream");
    const QString consumerPath = QDir::fromNativeSeparators(dir.path() + "/consumer");

    git_repository* upstreamRepo = nullptr;
    QVERIFY(initRepository(upstreamPath, false, &upstreamRepo));
    QVERIFY(commitFiles(upstreamRepo, { { "a.txt", "a1\n" }, { "b.txt", "b1\n" } }, "first"));

    git_repository* consumerRepo = nullptr;
    QCOMPARE(git_clone(&consumerRepo, upstreamPath.toUtf8().constData(),
                       consumerPath.toUtf8().constData(), nullptr), GIT_OK);

    Repository consumerWrapper(consumerRepo);
    GitRemote controller;
    controller.setCurrentRepo(&consumerWrapper);

    // Upstream changes a.txt while the consumer has an unrelated local edit in b.txt.
    QVERIFY(commitFiles(upstreamRepo, { { "a.txt", "a2\n" } }, "second"));
    QVERIFY(writeTextFile(consumerPath + "/b.txt", "local edit\n"));

    GitResult pull = controller.pull("origin", QString(), QString("token"));
    QVERIFY2(pull.success(), qPrintable(pull.errorMessage()));
    QCOMPARE(pull.data().toMap().value("status").toString(), QString("Fast-forward"));
    QCOMPARE(readTextFile(consumerPath + "/a.txt"), QByteArray("a2\n"));
    QCOMPARE(readTextFile(consumerPath + "/b.txt"), QByteArray("local edit\n"));
    QCOMPARE(headOid(consumerRepo), headOid(upstreamRepo));

    // Upstream now changes b.txt too: pulling would overwrite the local edit, so it must refuse.
    const QString headBefore = headOid(consumerRepo);
    QVERIFY(commitFiles(upstreamRepo, { { "b.txt", "b3\n" } }, "third"));

    GitResult blocked = controller.pull("origin", QString(), QString("token"));
    QVERIFY(!blocked.success());
    QVERIFY2(blocked.errorMessage().contains("local changes"), qPrintable(blocked.errorMessage()));
    QCOMPARE(readTextFile(consumerPath + "/b.txt"), QByteArray("local edit\n"));
    QCOMPARE(headOid(consumerRepo), headBefore);

    git_repository_free(upstreamRepo);
}

void TestGitRemote::noRepositoryValidation()
{
    GitRemote controller;

    QVERIFY(!controller.getRemotes().success());
    QVERIFY(!controller.addRemote("origin", "https://example.com/repo.git").success());
    QVERIFY(!controller.removeRemote("origin").success());
    QVERIFY(!controller.push("origin", "main", "token", false).success());
    QVERIFY(!controller.fetch("origin").success());
}

QTEST_MAIN(TestGitRemote)
#include "TestGitRemote.moc"
