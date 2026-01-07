#pragma once

#include <QObject>
#include <git2/status.h>
#include <QQmlEngine>

class GitFileStatus
{
    Q_GADGET
    QML_ELEMENT

    Q_PROPERTY(QString path READ path CONSTANT FINAL)
    Q_PROPERTY(Status status READ status CONSTANT FINAL)
    Q_PROPERTY(bool isStaged READ isStaged CONSTANT FINAL)
    Q_PROPERTY(bool isUnstaged READ isUnstaged CONSTANT FINAL)
    Q_PROPERTY(bool isUntracked READ isUntracked CONSTANT FINAL)

    Q_PROPERTY(int deletionsCount READ deletionsCount CONSTANT FINAL)
    Q_PROPERTY(int additionsCount READ additionsCount CONSTANT FINAL)
    Q_PROPERTY(DeltaStatus deltaStatus READ deltaStatus CONSTANT FINAL)

public:
    enum Status {
        Untracked = GIT_STATUS_WT_NEW,
        Modified = GIT_STATUS_WT_MODIFIED,
        Deleted = GIT_STATUS_WT_DELETED,
        Renamed = GIT_STATUS_WT_RENAMED,
        TypeChange = GIT_STATUS_WT_TYPECHANGE,
        StagedNew = GIT_STATUS_INDEX_NEW,
        StagedModified = GIT_STATUS_INDEX_MODIFIED,
        StagedDeleted = GIT_STATUS_INDEX_DELETED,
        StagedRenamed = GIT_STATUS_INDEX_RENAMED,
        Unknown = 0
    };

    Q_ENUM(Status)

    enum DeltaStatus {
        ADDED = GIT_DELTA_ADDED,
        DELETED = GIT_DELTA_DELETED,
        MODIFIED = GIT_DELTA_MODIFIED,
        RENAMED = GIT_STATUS_WT_TYPECHANGE,
        UNTRACKED,
    };

    Q_ENUM(DeltaStatus)


    explicit GitFileStatus();

    GitFileStatus(const QString &path, const Status &status, bool isStaged,
                  bool isUnstaged, bool isUntracked);

    GitFileStatus(const git_status_entry *entry);

    GitFileStatus(const git_diff_delta *delta, int additions, int deletions);


    QString path() const;

    Status status() const;

    bool isStaged() const;

    bool isUnstaged() const;

    bool isUntracked() const;

    int deletionsCount() const;

    int additionsCount() const;

    DeltaStatus deltaStatus() const;

private:
    QString m_path;
    Status m_status;
    bool m_isStaged;
    bool m_isUnstaged;
    bool m_isUntracked;
    int m_deletionsCount;
    int m_additionsCount;
    DeltaStatus m_deltaStatus;
};
