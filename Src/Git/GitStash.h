#pragma once

#include <QObject>
#include <git2/types.h>
#include "GitResult.h"
#include "IGitController.h"
#include <QQmlEngine>

/**
 * \brief Structure to hold stash information
 */
struct StashEntry
{
    QString message;        ///< Stash message
    QString hash;          ///< Stash commit hash
    QString author;        ///< Author name
    QString email;         ///< Author email
    QDateTime dateTime;    ///< When stash was created
    int index;             ///< Stash index (0 = most recent)
};

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
    /**
     * \brief Convert git_oid to QString hash
     * \param oid Git OID
     * \return QString hash
     */
    QString oidToString(const git_oid *oid);
};
