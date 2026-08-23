#pragma once

#include "Repository.h"
#include <QObject>
#include <QQmlEngine>
#include <git2/deprecated.h>
#include <QMutexLocker>
#include <QMutex>

class IGitController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(Repository* currentRepo READ currentRepo WRITE setCurrentRepo NOTIFY currentRepoChanged FINAL)

public:
    explicit IGitController(QObject *parent = nullptr);

    Repository *currentRepo() const;
    void setCurrentRepo(Repository *newCurrentRepo);

    QString gitOidToString(const git_oid *oid);

    /**
     * @brief The lock every libgit2 access must hold.
     *
     * A `git_repository*` is not safe for concurrent use, and libgit2's own caches are shared
     * process-wide, so one recursive lock guards all of it. Recursive because several
     * Q_INVOKABLEs legitimately call one another on the same thread.
     *
     * The async runner takes this around every queued job. Synchronous calls still made from
     * the GUI thread take it via QMutexLocker directly.
     */
    static QRecursiveMutex *repoMutex();
signals:
    void currentRepoChanged();
    void gitCommandGenerated(const QString &command);
protected:
    void emitGitCommand(const QString &command);
    static QString quoteCommandArg(const QString &argument);

    Repository *m_currentRepo = nullptr;
};
