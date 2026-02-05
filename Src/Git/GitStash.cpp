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

    git_stash_flags flags = GIT_STASH_DEFAULT;
    if (keepIndex) {
        flags = GIT_STASH_KEEP_INDEX;
    }

    const char *msg = message.isEmpty() ? nullptr : message.toUtf8().constData();

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
        return GitResult(false, QVariant(), "Repository not found.");
    }

    QList<StashEntry> stashes;

    // Walk through all stash references
    git_reference_iterator *iter = nullptr;
    int result = git_reference_iterator_new(&iter, m_currentRepo->repo);

    if (result != GIT_OK) {
        return GitResult(false, QVariant(), "Failed to create reference iterator.");
    }

    git_reference *ref = nullptr;
    int stashIndex = 0;

    while (git_reference_next(&ref, iter) == 0) {
        const char *refName = git_reference_name(ref);

        // Check if this is a stash reference
        if (QString(refName).startsWith("refs/stash")) {
            git_commit *commit = nullptr;

            if (git_reference_peel((git_object **)&commit, ref, GIT_OBJECT_COMMIT) == GIT_OK) {
                // Get commit details
                const git_signature *author = git_commit_author(commit);
                const git_oid *oid = git_commit_id(commit);
                const char *commitMsg = git_commit_message(commit);

                StashEntry entry;
                entry.message = QString(commitMsg).trimmed();
                entry.hash = oidToString(oid);
                entry.author = QString(author->name);
                entry.email = QString(author->email);
                entry.dateTime = QDateTime::fromSecsSinceEpoch(author->when.time);
                entry.index = stashIndex;

                stashes.append(entry);
                stashIndex++;

                git_commit_free(commit);
            }
        }

        git_reference_free(ref);
        ref = nullptr;
    }

    git_reference_iterator_free(iter);

    // Sort stashes by index (most recent first)
    std::sort(stashes.begin(), stashes.end(), [](const StashEntry &a, const StashEntry &b) {
        return a.index < b.index;
    });

    QVariantList resultList;
    for (const auto &stash : stashes) {
        QVariantMap stashMap;
        stashMap["message"] = stash.message;
        stashMap["hash"] = stash.hash;
        stashMap["author"] = stash.author;
        stashMap["email"] = stash.email;
        stashMap["dateTime"] = stash.dateTime;
        stashMap["index"] = stash.index;
        resultList.append(stashMap);
    }

    return GitResult(true, resultList, QString("Found %1 stashes.").arg(stashes.size()));
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
