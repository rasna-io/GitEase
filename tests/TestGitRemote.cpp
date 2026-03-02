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

}  // namespace

class TestGitRemote : public QObject
{
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    void remoteCrudWorks();
    void pushFetchAndUpstreamWork();
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
    git_repository_free(localRepo);
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

    GitResult pushResult = localController.push("origin", branch, "dummy-token", false);
    QVERIFY(pushResult.success());

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

    GitResult fetchWithToken = consumerController.fetchWithToken("origin", "dummy-token");
    QVERIFY(fetchWithToken.success());

    git_reference* trackingRef = nullptr;
    const QByteArray trackingName = QString("refs/remotes/origin/%1").arg(branch).toUtf8();
    QCOMPARE(git_reference_lookup(&trackingRef, consumerRepo, trackingName.constData()), GIT_OK);
    git_reference_free(trackingRef);

    git_repository_free(consumerRepo);
    git_repository_free(bareRemoteRepo);
    git_repository_free(localRepo);
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
