#include "GitTag.h"

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

    emit tagsChanged();
    return GitResult(true);
}

int credentials_cb(git_credential **out, const char *url, const char *user_from_url,
                   unsigned int allowed_types, void *payload)
{
    if (allowed_types & GIT_CREDENTIAL_SSH_KEY) {
        int error = git_credential_ssh_key_from_agent(out, user_from_url);
        if (error == 0) return 0;
    }

    if (allowed_types & GIT_CREDENTIAL_USERNAME) {
        return git_credential_username_new(out, user_from_url);
    }

    return git_credential_userpass_plaintext_new(out, user_from_url, "");
}

GitResult GitTag::pushTag(const QString &name)
{
    return pushTagInternal(name);
}

GitResult GitTag::pushTagInternal(const QString &name)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, "Repository not open");

    git_remote *remote = nullptr;
    if (git_remote_lookup(&remote, activeRepo(), "origin") != 0)
        return GitResult(false, "Remote 'origin' not found");

    QString refSpec = QString("refs/tags/%1:refs/tags/%1").arg(name);
    QByteArray refByte = refSpec.toUtf8();
    const char *spec = refByte.constData();
    git_strarray array = { (char **)&spec, 1 };

    git_push_options options;
    git_push_init_options(&options, GIT_PUSH_OPTIONS_VERSION);

    options.callbacks.credentials = credentials_cb;

    int error = git_remote_upload(remote, &array, &options);

    if (error != 0) {
        const git_error *lastError = git_error_last();
        QString errorDetail = lastError ? QString::fromUtf8(lastError->message) : "Unknown error";
        git_remote_free(remote);
        return GitResult(false, "Push failed: " + errorDetail);
    }

    git_remote_free(remote);
    return GitResult(true);
}

GitResult GitTag::pushDeleteTag(const QString &name)
{
    return pushDeleteTagInternal(name);
}

GitResult GitTag::pushDeleteTagInternal(const QString &name)
{
    if (!m_currentRepo || !activeRepo())
        return GitResult(false, "Repository not open");

    git_remote *remote = nullptr;
    if (git_remote_lookup(&remote, activeRepo(), "origin") != 0)
        return GitResult(false, "Remote 'origin' not found");

    QString refSpec = QString(":refs/tags/%1").arg(name);
    QByteArray refByte = refSpec.toUtf8();
    const char *spec = refByte.constData();
    git_strarray array = { (char **)&spec, 1 };

    git_push_options options;
    git_push_init_options(&options, GIT_PUSH_OPTIONS_VERSION);

    options.callbacks.credentials = credentials_cb;

    options.callbacks.certificate_check = [](git_cert*, int, const char*, void*) {
        return 0;
    };

    int error = git_remote_upload(remote, &array, &options);

    git_remote_free(remote);

    if (error != 0) {
        const git_error *lastError = git_error_last();
        QString errorDetail = lastError ? QString::fromUtf8(lastError->message) : "Unknown error";
        return GitResult(false, "Remote delete failed: " + errorDetail);
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
