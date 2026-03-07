#pragma once

#include "GitResult.h"
#include "IGitController.h"
#include <QObject>

struct git_index_entry;

/**
 * @brief Handles inspection and resolution of merge conflicts.
 *
 * This class works with the Git index and working directory to list
 * conflicted files and to accept "ours" or "theirs" versions.
 */
class GitConflict : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

private:
    // Write content from a specific stage (1=base, 2=ours, 3=theirs) to working directory and stage it
    GitResult writeConflictFromStage(const QString& filePath, int stage);

    // Helper to read blob content as QString
    QString readBlobContent(const git_index_entry* entry) const;

public:
    explicit GitConflict(QObject* parent = nullptr);

    /**
     * @brief Retrieves the list of files currently in conflict.
     * @return GitResult containing a QVariantList of conflict entries.
     *         Each entry is a QVariantMap with keys:
     *         - "path": file path relative to repo root
     *         - "ourContent": content from our side (stage 2)
     *         - "theirContent": content from their side (stage 3)
     *         - "baseContent": content from merge base (stage 1)
     */
    Q_INVOKABLE GitResult getMergeConflicts();

    /**
     * @brief Resolves a conflict by keeping the "ours" version.
     * @param filePath Path to the conflicted file.
     * @return GitResult indicating success or failure.
     */
    Q_INVOKABLE GitResult acceptConflictOurs(const QString& filePath);

    /**
     * @brief Resolves a conflict by keeping the "theirs" version.
     * @param filePath Path to the conflicted file.
     * @return GitResult indicating success or failure.
     */
    Q_INVOKABLE GitResult acceptConflictTheirs(const QString& filePath);
};
