#include "GitFileStatus.h"
#include <git2/diff.h>

GitFileStatus::GitFileStatus()
{}

GitFileStatus::GitFileStatus(const QString &path, const Status &status, bool isStaged,
                             bool isUntracked, bool isUnstaged) : m_path(path),
    m_status(status),
    m_isStaged(isStaged),
    m_isUnstaged(isUnstaged),
    m_isUntracked(isUntracked)
{}

GitFileStatus::GitFileStatus(const git_status_entry *entry)
{

    if (!entry)
        return;

    // Get file path - check both staged and unstaged locations
    const char* path = entry->head_to_index ?
                           entry->head_to_index->old_file.path :  // Staged changes path
                           entry->index_to_workdir->old_file.path; // Unstaged changes path

    if (path)
        m_path = QString::fromUtf8(path);  // Store path

    m_status = static_cast<GitFileStatus::Status>(entry->status);


    // Classify the status for easy UI filtering
    m_isStaged = entry->status & (GIT_STATUS_INDEX_NEW |
                                     GIT_STATUS_INDEX_MODIFIED |
                                     GIT_STATUS_INDEX_DELETED |
                                     GIT_STATUS_INDEX_RENAMED);

    m_isUnstaged = entry->status & (GIT_STATUS_WT_MODIFIED |
                                       GIT_STATUS_WT_DELETED |
                                       GIT_STATUS_WT_RENAMED |
                                       GIT_STATUS_WT_TYPECHANGE);

    m_isUntracked = entry->status & GIT_STATUS_WT_NEW;
}

GitFileStatus::GitFileStatus(const git_diff_delta *delta, int additions, int deletions)
{
    if (!delta)
        return;

    m_path = QString::fromUtf8(delta->new_file.path);
    m_additionsCount = additions;
    m_deletionsCount = deletions;
    m_deltaStatus = static_cast<DeltaStatus>(delta->status);
}

QString GitFileStatus::path() const
{
    return m_path;
}

GitFileStatus::Status GitFileStatus::status() const
{
    return m_status;
}

bool GitFileStatus::isStaged() const
{
    return m_isStaged;
}

bool GitFileStatus::isUnstaged() const
{
    return m_isUnstaged;
}

bool GitFileStatus::isUntracked() const
{
    return m_isUntracked;
}


int GitFileStatus::deletionsCount() const
{
    return m_deletionsCount;
}

int GitFileStatus::additionsCount() const
{
    return m_additionsCount;
}

GitFileStatus::DeltaStatus GitFileStatus::deltaStatus() const
{
    return m_deltaStatus;
}
