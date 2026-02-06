#pragma once

#include <QObject>
#include <git2/types.h>
#include <QQmlEngine>
#include <git2/stash.h>
#include <git2/commit.h>
#include <git2/signature.h>
#include <git2/errors.h>
#include <QDateTime>

#include "GitResult.h"
#include "IGitController.h"

class GitStash : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitStash(QObject *parent = nullptr);

    /**
     * \brief Save current changes to a stash
     * \param message Optional stash message
     * \param keepIndex Whether to keep staged changes in index
     * \return GitResult
     */
    Q_INVOKABLE GitResult save(const QString &message = "", bool keepIndex = false);

    /**
     * \brief Get list of all stashes
     * \return GitResult with list of StashEntry objects
     */
    Q_INVOKABLE GitResult list();

    /**
     * \brief Apply a stash to working directory
     * \param index Stash index (0 = most recent)
     * \param reinstateIndex Whether to reinstate index state
     * \return GitResult
     */
    Q_INVOKABLE GitResult apply(int index = 0, bool reinstateIndex = true);

    /**
     * \brief Remove a stash
     * \param index Stash index to remove (0 = most recent)
     * \return GitResult
     */
    Q_INVOKABLE GitResult remove(int index = 0);

    /**
     * \brief Apply and remove a stash in one operation
     * \param index Stash index (0 = most recent)
     * \param reinstateIndex Whether to reinstate index state
     * \return GitResult
     */
    Q_INVOKABLE GitResult pop(int index = 0, bool reinstateIndex = true);

private:
    // Payload passed to the foreach callback
    struct ListPayload {
        git_repository* repo;
        QVariantList* list;
    };
};
