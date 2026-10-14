#include <QtTest/QtTest>
#include <QDir>
#include <QFile>
#include <QTemporaryDir>

#include <git2.h>

#include "Git/Auth/GitHttpsAuth.h"
#include "Git/GitRemote.h"
#include "Git/GitResult.h"
#include "Git/GitTag.h"
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
QString configValue(git_repository* repo, const QString& key)
{
    git_config* config = nullptr;
    if (git_repository_config_snapshot(&config, repo) != GIT_OK)
        return {};

    git_buf value = GIT_BUF_INIT;
    QString result;
    if (git_config_get_string_buf(&value, config, key.toUtf8().constData()) == GIT_OK)
        result = QString::fromUtf8(value.ptr, static_cast<int>(value.size));

    git_buf_dispose(&value);
    git_config_free(config);
    return result;
}

bool setConfigValue(git_repository* repo, const QString& key, const QString& value)
{
    git_config* config = nullptr;
    if (git_repository_config(&config, repo) != GIT_OK)
        return false;

    const bool ok = git_config_set_string(config, key.toUtf8().constData(), value.toUtf8().constData()) == GIT_OK;
    git_config_free(config);
    return ok;
}

bool referenceExists(git_repository* repo, const QString& name)
{
    git_reference* ref = nullptr;
    if (git_reference_lookup(&ref, repo, name.toUtf8().constData()) != GIT_OK)
        return false;
    git_reference_free(ref);
    return true;
}

QString createBareRemote(const QTemporaryDir& dir, const QString& name)
{
    const QString path = QDir::fromNativeSeparators(dir.path() + "/" + name);
    git_repository* repo = nullptr;
    if (!QDir().mkpath(path) || !initRepository(path, true, &repo))
        return {};
    git_repository_free(repo);
    return path;
}

QVariantMap remoteTargetOf(GitRemote& controller)
{
    GitResult target = controller.remoteTarget();
    return target.success() ? target.data().toMap() : QVariantMap();
}

QStringList remoteNamesOf(const QVariantMap& target)
{
    QStringList names;
    for (const QVariant& remote : target.value("remotes").toList())
        names << remote.toMap().value("name").toString();
    return names;
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

    GitResult push = localController.push("origin", branch, "dummy-token", false);
    QVERIFY2(push.success(), qPrintable(push.errorMessage()));
    QCOMPARE(push.data().toMap().value("remote").toString(), QString("origin"));

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
    QVERIFY2(autoFetch.success(), qPrintable(autoFetch.errorMessage()));

    GitResult fetch = consumerController.fetchWithToken("origin", "dummy-token");
    QVERIFY2(fetch.success(), qPrintable(fetch.errorMessage()));
    QCOMPARE(fetch.data().toMap().value("remote").toString(), QString("origin"));

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
    QVERIFY(!controller.push("origin", "main", "main", "token", false, true).success());
    QVERIFY(!controller.fetch("origin").success());
    QVERIFY(!controller.remoteTarget().success());
    QVERIFY(!controller.setUpstream("main", "origin", "main").success());
}
void TestGitRemote::publishingPushSetsUpstream()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString originPath = createBareRemote(dir, "origin.git");
    const QString upstreamPath = createBareRemote(dir, "upstream.git");

    git_repository* repo = nullptr;
    QVERIFY(initRepository(dir.path() + "/local", false, &repo));
    QVERIFY(commitFiles(repo, { { "a.txt", "1\n" } }, "first"));
    const QString branch = currentBranchName(repo);

    Repository wrapper(repo);
    GitRemote controller;
    controller.setCurrentRepo(&wrapper);
    QVERIFY(controller.addRemote("origin", originPath).success());
    QVERIFY(controller.addRemote("upstream", upstreamPath).success());

    QStringList commands;
    connect(&controller, &IGitController::gitCommandGenerated, this,
            [&commands](const QString& command) { commands << command; });

    // The first push of a branch, like git push -u
    GitResult push = controller.push("upstream", branch, QString(), QString(), false, true);
    QVERIFY2(push.success(), qPrintable(push.errorMessage()));
    QVERIFY(push.data().toMap().value("upstreamSet").toBool());
    QCOMPARE(push.data().toMap().value("remoteBranch").toString(), branch);
    QVERIFY(commands.contains(QString("git push -u \"upstream\" \"%1\"").arg(branch)));

    git_repository* upstreamRepo = nullptr;
    QCOMPARE(git_repository_open(&upstreamRepo, upstreamPath.toUtf8().constData()), GIT_OK);
    QVERIFY(referenceExists(upstreamRepo, "refs/heads/" + branch));
    git_repository_free(upstreamRepo);

    QVERIFY(referenceExists(repo, "refs/remotes/upstream/" + branch));
    QCOMPARE(configValue(repo, "branch." + branch + ".remote"), QString("upstream"));

    // From now on the branch has a home, so nothing needs asking
    QVariantMap target = remoteTargetOf(controller);
    QCOMPARE(target.value("pullRemote").toString(), QString("upstream"));
    QCOMPARE(target.value("pushRemote").toString(), QString("upstream"));
    QCOMPARE(target.value("pushBranch").toString(), branch);
    QVERIFY(!target.value("publish").toBool());
}

void TestGitRemote::pullFollowsUpstreamOfThatRemote()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());

    const QString sourcePath = QDir::fromNativeSeparators(dir.path() + "/source");
    const QString consumerPath = QDir::fromNativeSeparators(dir.path() + "/consumer");

    git_repository* sourceRepo = nullptr;
    QVERIFY(initRepository(sourcePath, false, &sourceRepo));
    QVERIFY(commitFiles(sourceRepo, { { "a.txt", "a1\n" } }, "first"));

    git_repository* consumerRepo = nullptr;
    QCOMPARE(git_clone(&consumerRepo, sourcePath.toUtf8().constData(),
                       consumerPath.toUtf8().constData(), nullptr), GIT_OK);
    const QString branch = currentBranchName(consumerRepo);

    // The source moves on, on a branch called trunk
    git_commit* first = nullptr;
    git_oid firstId;
    QCOMPARE(git_reference_name_to_id(&firstId, sourceRepo, "HEAD"), GIT_OK);
    QCOMPARE(git_commit_lookup(&first, sourceRepo, &firstId), GIT_OK);
    git_reference* trunk = nullptr;
    QCOMPARE(git_branch_create(&trunk, sourceRepo, "trunk", first, 0), GIT_OK);
    git_reference_free(trunk);
    git_commit_free(first);
    QCOMPARE(git_repository_set_head(sourceRepo, "refs/heads/trunk"), GIT_OK);
    QVERIFY(commitFiles(sourceRepo, { { "a.txt", "a2\n" } }, "second"));

    Repository consumerWrapper(consumerRepo);
    GitRemote controller;
    controller.setCurrentRepo(&consumerWrapper);
    QVERIFY(controller.addRemote("upstream", sourcePath).success());
    QVERIFY(controller.setUpstream(branch, "upstream", "trunk").success());

    // Pulling from upstream without naming a branch follows the upstream: upstream/trunk
    GitResult pull = controller.pull("upstream", QString(), QString(), false);
    QVERIFY2(pull.success(), qPrintable(pull.errorMessage()));
    QCOMPARE(pull.data().toMap().value("remoteBranch").toString(), QString("trunk"));
    QCOMPARE(pull.data().toMap().value("status").toString(), QString("Fast-forward"));
    QCOMPARE(headOid(consumerRepo), headOid(sourceRepo));
    QCOMPARE(readTextFile(consumerPath + "/a.txt"), QByteArray("a2\n"));

    // Origin is not the upstream, so there the branch's own name is used, which trunk is not
    GitResult fromOrigin = controller.pull("origin");
    QVERIFY(fromOrigin.success());
    QCOMPARE(fromOrigin.data().toMap().value("remoteBranch").toString(), branch);

    git_repository_free(sourceRepo);
}

void TestGitRemote::tagPushUsesTheGivenRemote()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString upstreamPath = createBareRemote(dir, "upstream.git");

    git_repository* repo = nullptr;
    QVERIFY(initRepository(dir.path() + "/local", false, &repo));
    QVERIFY(commitFiles(repo, { { "a.txt", "1\n" } }, "first"));

    Repository wrapper(repo);
    GitRemote remotes;
    remotes.setCurrentRepo(&wrapper);
    QVERIFY(remotes.addRemote("upstream", upstreamPath).success());

    GitTag tags;
    tags.setCurrentRepo(&wrapper);
    QVERIFY(tags.create("v1.0", "HEAD").success());

    QStringList commands;
    connect(&tags, &IGitController::gitCommandGenerated, this,
            [&commands](const QString& command) { commands << command; });

    // No origin anywhere: the tag goes where it is told
    GitResult push = tags.pushTag("upstream", "v1.0", QString());
    QVERIFY2(push.success(), qPrintable(push.errorMessage()));
    QVERIFY(commands.contains("git push \"upstream\" \"v1.0\""));

    git_repository* upstreamRepo = nullptr;
    QCOMPARE(git_repository_open(&upstreamRepo, upstreamPath.toUtf8().constData()), GIT_OK);
    QVERIFY(referenceExists(upstreamRepo, "refs/tags/v1.0"));

    GitResult remove = tags.pushDeleteTag("upstream", "v1.0", QString());
    QVERIFY2(remove.success(), qPrintable(remove.errorMessage()));
    QVERIFY(commands.contains("git push \"upstream\" --delete \"v1.0\""));
    QVERIFY(!referenceExists(upstreamRepo, "refs/tags/v1.0"));
    git_repository_free(upstreamRepo);

    // A remote that does not exist fails with its own name in the message
    GitResult missing = tags.pushTag("origin", "v1.0", QString());
    QVERIFY(!missing.success());
    QVERIFY2(missing.errorMessage().contains("'origin' not found"), qPrintable(missing.errorMessage()));
}

void TestGitRemote::rejectedTokenIsNotReplayed()
{
    GitHttpsAuth auth("ghp_token");
    git_push_options options;
    QCOMPARE(git_push_options_init(&options, GIT_PUSH_OPTIONS_VERSION), GIT_OK);
    auth.applyPush(options);
    QVERIFY(options.callbacks.credentials);

    GitRepository::GitPayload payload { nullptr, &auth };
    const char* url = "https://github.com/owner/repo.git";

    // The first request gets the token
    git_credential* credential = nullptr;
    QCOMPARE(options.callbacks.credentials(&credential, url, nullptr, GIT_CREDENTIAL_USERPASS_PLAINTEXT, &payload), 0);
    QVERIFY(credential);
    git_credential_free(credential);
    QVERIFY(!auth.tokenRejected());

    // libgit2 asks again for the same URL only after the server refused it: fail instead of replaying
    credential = nullptr;
    QCOMPARE(options.callbacks.credentials(&credential, url, nullptr, GIT_CREDENTIAL_USERPASS_PLAINTEXT, &payload),
             static_cast<int>(GIT_EAUTH));
    QVERIFY(!credential);
    QVERIFY(auth.tokenRejected());

    const QString message = GitHttpsAuth::rejectedTokenMessage("myself", url, true);
    QVERIFY2(message.startsWith("github.com did not accept the token for 'myself'"), qPrintable(message));
    QVERIFY2(message.contains("allowed to push to owner/repo"), qPrintable(message));
    QVERIFY2(message.contains("\"repo\" scope"), qPrintable(message));
}

void TestGitRemote::defaultRemoteDecidesWherePushGoes()
{
    QTemporaryDir dir;
    QVERIFY(dir.isValid());
    const QString originPath = createBareRemote(dir, "origin.git");
    const QString upstreamPath = createBareRemote(dir, "upstream.git");
    const QString forkPath = createBareRemote(dir, "fork.git");

    git_repository* repo = nullptr;
    QVERIFY(initRepository(dir.path() + "/local", false, &repo));
    QVERIFY(commitFiles(repo, { { "a.txt", "1\n" } }, "first"));
    const QString branch = currentBranchName(repo);

    Repository wrapper(repo);
    GitRemote controller;
    controller.setCurrentRepo(&wrapper);
    QVERIFY(controller.addRemote("origin", originPath).success());
    QVERIFY(controller.addRemote("upstream", upstreamPath).success());
    QVERIFY(controller.addRemote("fork", forkPath).success());

    // Several remotes and no upstream: nothing decides yet
    QVariantMap target = remoteTargetOf(controller);
    QVERIFY(target.value("defaultRemote").toString().isEmpty());
    QVERIFY(target.value("pushRemote").toString().isEmpty());

    QStringList commands;
    connect(&controller, &IGitController::gitCommandGenerated, this,
            [&commands](const QString& command) { commands << command; });

    // A default remote decides push and, without an upstream, pull
    GitResult set = controller.setDefaultRemote("fork");
    QVERIFY2(set.success(), qPrintable(set.errorMessage()));
    QCOMPARE(configValue(repo, "remote.pushDefault"), QString("fork"));
    QVERIFY(commands.contains("git config remote.pushDefault \"fork\""));

    target = remoteTargetOf(controller);
    QCOMPARE(target.value("defaultRemote").toString(), QString("fork"));
    QCOMPARE(target.value("pushRemote").toString(), QString("fork"));
    QCOMPARE(target.value("pushBranch").toString(), branch);
    QCOMPARE(target.value("pullRemote").toString(), QString("fork"));
    QCOMPARE(target.value("suggestedRemote").toString(), QString("fork"));

    // It also wins over the upstream for push, the way git's remote.pushDefault does; pull keeps
    // following the upstream
    QVERIFY(controller.push("upstream", branch, branch, QString(), false, true).success());
    target = remoteTargetOf(controller);
    QCOMPARE(target.value("upstreamRemote").toString(), QString("upstream"));
    QCOMPARE(target.value("pushRemote").toString(), QString("fork"));
    QCOMPARE(target.value("pullRemote").toString(), QString("upstream"));

    // Changing it is a matter of setting another one
    QVERIFY(controller.setDefaultRemote("origin").success());
    QCOMPARE(remoteTargetOf(controller).value("pushRemote").toString(), QString("origin"));

    // Clearing it gives the upstream back, and clearing twice is fine
    QVERIFY(controller.setDefaultRemote(QString()).success());
    QVERIFY(controller.setDefaultRemote(QString()).success());
    QVERIFY(configValue(repo, "remote.pushDefault").isEmpty());
    QVERIFY(commands.contains("git config --unset remote.pushDefault"));
    target = remoteTargetOf(controller);
    QVERIFY(target.value("defaultRemote").toString().isEmpty());
    QCOMPARE(target.value("pushRemote").toString(), QString("upstream"));

    // A remote that does not exist cannot be the default
    GitResult missing = controller.setDefaultRemote("nope");
    QVERIFY(!missing.success());
    QVERIFY2(missing.errorMessage().contains("'nope' not found"), qPrintable(missing.errorMessage()));
}

QTEST_MAIN(TestGitRemote)
#include "TestGitRemote.moc"
