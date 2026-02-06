#include "GitStash.h"

#include <git2/stash.h>
#include <git2/commit.h>
#include <git2/signature.h>
#include <git2/refs.h>
#include <git2/errors.h>
#include <QDateTime>
#include <QList>

GitStash::GitStash(QObject *parent)
    : IGitController{parent}
{}

GitResult GitStash::save(const QString &message, bool keepIndex)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_signature *signature = nullptr;
    int result = git_signature_default(&signature, m_currentRepo->repo);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to create signature.");
    }

    git_stash_flags flags = keepIndex ? GIT_STASH_KEEP_INDEX : GIT_STASH_DEFAULT;

    QByteArray msgArray = message.toUtf8();
    const char* msg = msgArray.isEmpty() ? nullptr : msgArray.constData();

    git_oid stashOid;
    result = git_stash_save(
        &stashOid,
        m_currentRepo->repo,
        signature,
        msg,
        flags
        );

    git_signature_free(signature);

    if (result != GIT_OK)
        return GitResult(false, {}, git_error_last()->message);

    return GitResult(true, {}, "Stash saved successfully.");
}


GitResult GitStash::list()
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, {}, "Repository not found.");
    }

    QVariantList resultList;

    int result = git_stash_foreach(
        m_currentRepo->repo,
        [](size_t index,
           const char* message,
           const git_oid* stash_id,
           void* payload) -> int
        {
            auto* list = static_cast<QVariantList*>(payload);

            QVariantMap m;
            m["index"] = static_cast<int>(index);
            m["message"] = message
                               ? QString::fromUtf8(message).trimmed()
                               : QStringLiteral("WIP");

            list->append(m);
            return 0;
        },
        &resultList
        );

    if (result != GIT_OK) {
        return GitResult(false, {}, git_error_last()->message);
    }

    return GitResult(
        true,
        resultList,
        QString("Found %1 stashes.").arg(resultList.size())
        );
}

GitResult GitStash::apply(int index, bool reinstateIndex)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_stash_apply_options options = GIT_STASH_APPLY_OPTIONS_INIT;
    options.checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;

    if (reinstateIndex) {
        options.flags |= GIT_STASH_APPLY_REINSTATE_INDEX;
    }

    int result = git_stash_apply(m_currentRepo->repo, index, &options);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to apply stash: %1").arg(git_error_last()->message));
    }

    return GitResult(true, QVariant(), "Stash applied successfully.");
}

GitResult GitStash::remove(int index)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    int result = git_stash_drop(m_currentRepo->repo, index);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to remove stash: %1").arg(git_error_last()->message));
    }

    return GitResult(true, QVariant(), "Stash removed successfully.");
}

GitResult GitStash::pop(int index, bool reinstateIndex)
{
    if (!m_currentRepo || !m_currentRepo->repo) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_stash_apply_options options = GIT_STASH_APPLY_OPTIONS_INIT;
    options.checkout_options.checkout_strategy = GIT_CHECKOUT_SAFE;

    if (reinstateIndex) {
        options.flags |= GIT_STASH_APPLY_REINSTATE_INDEX;
    }

    int result = git_stash_pop(m_currentRepo->repo, index, &options);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), QString("Failed to pop stash: %1").arg(git_error_last()->message));
    }

    return GitResult(true, QVariant(), "Stash popped successfully.");
}

QString GitStash::oidToString(const git_oid *oid)
{
    if (!oid) return QString();

    char hash[GIT_OID_HEXSZ + 1];
    git_oid_fmt(hash, oid);
    hash[GIT_OID_HEXSZ] = '\0';

    return QString(hash);
}
