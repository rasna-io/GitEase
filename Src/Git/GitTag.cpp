#include "GitTag.h"

GitTag::GitTag(QObject *parent)
    : IGitController(parent)
{
}

GitResult GitTag::list()
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository not open");

    QVariantList tagList;
    TagPayload payload;
    payload.repo = m_currentRepo->repo;
    payload.list = &tagList;

    int error = git_tag_foreach(m_currentRepo->repo, tagForeachCallback, &payload);

    if (error < 0)
        return GitResult(false);

    return GitResult(true, tagList);
}

GitResult GitTag::create(const QString &name, const QString &targetId, const QString &message, bool force)
{
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository not open");

    git_oid target_oid;
    git_object *target_obj = nullptr;
    git_signature *signature = nullptr;
    git_oid tag_oid;
    int error = 0;

    if (git_oid_fromstr(&target_oid, targetId.toUtf8().constData()) < 0)
        return GitResult(false, QVariant(), "Invalid Commit ID");

    if (git_object_lookup(&target_obj, m_currentRepo->repo, &target_oid, GIT_OBJECT_ANY) < 0)
        return GitResult(false);

    if (message.isEmpty()) {
        error = git_tag_create_lightweight(&tag_oid, m_currentRepo->repo, name.toUtf8().constData(), target_obj, force ? 1 : 0);
    } else {
        if (git_signature_default(&signature, m_currentRepo->repo) < 0) {
            git_object_free(target_obj);
            return GitResult(false, QVariant(), "Git signature not found (set user.name and user.email)");
        }

        error = git_tag_create(&tag_oid, m_currentRepo->repo, name.toUtf8().constData(), target_obj, signature, message.toUtf8().constData(), force ? 1 : 0);
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
    if (!m_currentRepo || !m_currentRepo->repo)
        return GitResult(false, QVariant(), "Repository not open");

    int error = git_tag_delete(m_currentRepo->repo, name.toUtf8().constData());

    if (error < 0)
        return GitResult(false);

    emit tagsChanged();
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
