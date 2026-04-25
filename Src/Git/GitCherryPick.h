#pragma once

#include "GitResult.h"
#include "IGitController.h"
#include <QObject>
#include <QStringList>
#include "GitUtils.h"
#include <git2.h>
#include <QVariantList>

struct git_commit;

/**
 * @brief Handles cherry-pick operations (single and multiple commits).
 *
 * Responsibilities:
 *  - Apply one or more commits onto current HEAD
 *  - Detect and expose conflict state
 *  - Continue after conflicts
 *  - Abort and restore original HEAD
 */
class GitCherryPick : public IGitController
{
    Q_OBJECT
    Q_PROPERTY(bool cherryPickConflicts READ hasCherryPickConflicts NOTIFY cherryPickStateChanged FINAL)
    Q_PROPERTY(bool cherryPickInProgress READ isCherryPickInProgress NOTIFY cherryPickStateChanged FINAL)
    QML_ELEMENT

private:
    GitResult processCommits();
    GitResult applyCommit(const QString& commitHash);
    GitResult createCommitFromPick(git_commit* pickedCommit);
    GitResult conflictResult(const QString& commitHash, const QString& message);
    GitResult resetToOriginalHead();
    void clearState();

    git_commit* lookupCommit(const QString& commitHash, QString* errorMessage) const;
    bool repositoryHasConflicts() const;
    QString headHash() const;

    QStringList m_pendingCommits;
    int m_currentIndex = -1;
    QString m_startHeadHash;
    bool m_inProgress = false;
    bool m_hasConflicts = false;

public:
    explicit GitCherryPick(QObject* parent = nullptr);

    /// Cherry-pick a single commit hash.
    Q_INVOKABLE GitResult cherryPickCommit(const QString& commitHash);

    /// Cherry-pick multiple commits (applied in the order provided).
    Q_INVOKABLE GitResult cherryPickCommits(const QStringList& commitHashes);

    /// Continue a cherry-pick after conflicts are resolved.
    Q_INVOKABLE GitResult continueCherryPick();

    /// Skip the current conflicting commit and continue with the rest.
    Q_INVOKABLE GitResult skipCherryPick();

    /// Abort an in-progress cherry-pick and restore original HEAD.
    Q_INVOKABLE GitResult abortCherryPick();

    /// Return cherry-pick progress and conflict status.
    Q_INVOKABLE GitResult cherryPickStatus();

    Q_INVOKABLE bool hasCherryPickConflicts() const;
    Q_INVOKABLE bool isCherryPickInProgress() const;

signals:
    void cherryPickStateChanged();
};
