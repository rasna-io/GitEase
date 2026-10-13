#include "GitTag.h"
#include "GitCommandText.h"
#include "GitRemote.h"
#include "GitRepository.h"
#include "Auth/GitHttpsAuth.h"

#include <algorithm>

GitTag::GitTag(QObject *parent)
    : IGitController(parent)
{
}

GitResult GitTag::list()
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not open");
    }

    QVariantList tagList;
    TagPayload payload;
    payload.repo = activeRepo();
    payload.list = &tagList;

    int error = git_tag_foreach(activeRepo(), tagForeachCallback, &payload);

    if (error < 0) {
        return GitResult(false, QVariant(), "Failed to iterate tags");
    }

    // Sort the list alphabetically by tag name
    std::sort(tagList.begin(), tagList.end(), [](const QVariant &a, const QVariant &b) {
        return a.toMap()["name"].toString() < b.toMap()["name"].toString();
    });

    emitGitCommand("git tag -l");

    return GitResult(true, tagList);
}

GitResult GitTag::create(const QString &name, const QString &targetId, const QString &message, bool force)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    git_oid target_oid;
    git_object *target_obj = nullptr;
    git_signature *signature = nullptr;
    git_oid tag_oid;
    int error = 0;

    if (strcmp(targetId.toUtf8().constData(), "HEAD") == 0) {
        error = git_revparse_single(&target_obj, activeRepo(), "HEAD^{commit}");
        if (error != 0)
            return GitResult(false, "Failed to resolve HEAD");

        const git_oid *oid = git_object_id(target_obj);
        git_oid_cpy(&target_oid, oid);
    } else {
        if (git_oid_fromstr(&target_oid, targetId.toUtf8().constData()) < 0)
            return GitResult(false, QVariant(), "Invalid Commit ID");

        if (git_object_lookup(&target_obj, activeRepo(), &target_oid, GIT_OBJECT_ANY) < 0)
        {
            git_object_free(target_obj);
            return GitResult(false);
        }
    }

    if (message.isEmpty()) {
        error = git_tag_create_lightweight(&tag_oid, activeRepo(), name.toUtf8().constData(), target_obj, force ? 1 : 0);
    } else {
        if (git_signature_default(&signature, activeRepo()) < 0) {
            git_object_free(target_obj);
            return GitResult(false, QVariant(), "Git signature not found (set user.name and user.email)");
        }

        error = git_tag_create(&tag_oid, activeRepo(), name.toUtf8().constData(), target_obj, signature, message.toUtf8().constData(), force ? 1 : 0);
    }

    if (signature) git_signature_free(signature);
    if (target_obj) git_object_free(target_obj);

    if (error < 0)
        return GitResult(false);

    emitGitCommand(GitCommandText::createTag(name, message, force));

    emit tagsChanged();
    return GitResult(true);
}

GitResult GitTag::remove(const QString &name)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    int error = git_tag_delete(activeRepo(), name.toUtf8().constData());

    if (error < 0)
        return GitResult(false);

    emitGitCommand(GitCommandText::deleteTag(name));

    emit tagsChanged();
    return GitResult(true);
}

GitResult GitTag::pushTag(const QString &remote, const QString &name, const QString &token)
{
    GitResult result = uploadTagRefspec(remote, QString("refs/tags/%1:refs/tags/%1").arg(name), token);

    if (!result.success())
        return GitResult(false, QVariant(), "Push failed: " + result.errorMessage());

    emitGitCommand(GitCommandText::pushTag(remote, name));
    return GitResult(true, remote);
}

static void applyTagPushAuth(git_remote *remote, git_push_options &options)
{
    const char *url = git_remote_pushurl(remote);
    if (!url)
        url = git_remote_url(remote);

    if (url && GitProtocolDetector::isSshUrl(QString::fromUtf8(url))) {
        GitSshAuth().applyPush(options);
        return;
    }

    options.callbacks.credentials = credentials_cb;
}

GitResult GitTag::pushTag(const QString &name)
{
    GitResult result = pushTagInternal(name);

    if (result.success())
        emitGitCommand(GitCommandText::pushTag(name));

    return result;
}

GitResult GitTag::uploadTagRefspec(const QString &remoteName, const QString &refspec, const QString &token)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, QVariant(), "Repository not open");

    if (remoteName.isEmpty())
        return GitResult(false, QVariant(), "Remote name cannot be empty");

    QString authError;
    std::unique_ptr<IGitAuth> auth = GitRemote::authForRemote(activeRepo(), remoteName, token, true, &authError);
    if (!auth)
        return GitResult(false, QVariant(), authError);

    git_remote *remote = nullptr;
    if (git_remote_lookup(&remote, activeRepo(), remoteName.toUtf8().constData()) != 0)
        return GitResult(false, QVariant(), QString("Remote '%1' not found").arg(remoteName));

    QByteArray refByte = refspec.toUtf8();
    char *spec = refByte.data();
    git_strarray array = { &spec, 1 };

    git_push_options options;
    git_push_options_init(&options, GIT_PUSH_OPTIONS_VERSION);

    GitRepository::GitPayload payload { this, auth.get() };
    options.callbacks.payload = &payload;
    auth->applyPush(options);

    int error = git_remote_upload(remote, &array, &options);

    const char *pushUrl = git_remote_pushurl(remote);
    const QString url = QString::fromUtf8(pushUrl && *pushUrl ? pushUrl : git_remote_url(remote));
    git_remote_free(remote);

    if (error != 0) {
        const auto *https = dynamic_cast<const GitHttpsAuth *>(auth.get());
        if (https && https->tokenRejected())
            return GitResult(false, QVariant(), GitHttpsAuth::rejectedTokenMessage(remoteName, url, true));

        const git_error *lastError = git_error_last();
        return GitResult(false, QVariant(), lastError ? QString::fromUtf8(lastError->message) : "Unknown error");
    }

    return GitResult(true);
}

int GitTag::tagForeachCallback(const char *name, git_oid *oid, void *payload)
{
    TagPayload *p = static_cast<TagPayload*>(payload);
    QVariantMap tagMap;

    QString fullPath = QString::fromUtf8(name);
    QString shortName = fullPath.startsWith("refs/tags/") ? fullPath.mid(10) : fullPath;

    tagMap["name"] = shortName;

    git_tag *tag = nullptr;
    if (git_tag_lookup(&tag, p->repo, oid) == 0) {
        tagMap["isAnnotated"] = true;
        tagMap["message"] = QString::fromUtf8(git_tag_message(tag));

        git_object *target = nullptr;
        if (git_tag_peel(&target, tag) == 0) {
            char oidStr[GIT_OID_HEXSZ + 1];
            git_oid_fmt(oidStr, git_object_id(target));
            oidStr[GIT_OID_HEXSZ] = '\0';
            tagMap["commitId"] = QString::fromUtf8(oidStr);
            git_object_free(target);
        }
        git_tag_free(tag);
    } else {
        char oidStr[GIT_OID_HEXSZ + 1];
        git_oid_fmt(oidStr, oid);
        oidStr[GIT_OID_HEXSZ] = '\0';

        tagMap["isAnnotated"] = false;
        tagMap["message"] = "";
        tagMap["commitId"] = QString::fromUtf8(oidStr);
    }

    p->list->append(tagMap);
    return 0;
}
