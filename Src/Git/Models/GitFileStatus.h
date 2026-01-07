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

    explicit GitFileStatus();

    GitFileStatus(const QString &path, const Status &status, bool isStaged,
                  bool isUnstaged, bool isUntracked);

    GitFileStatus(const git_status_entry *entry);

    QString path() const;

    Status status() const;

    bool isStaged() const;

    bool isUnstaged() const;

    bool isUntracked() const;


private:
    QString m_path;
    Status m_status;
    bool m_isStaged;
    bool m_isUnstaged;
    bool m_isUntracked;
};