#pragma once

#include "GitResult.h"
#include "IGitController.h"
#include <QObject>
#include <QVariantList>

struct git_index_entry;
struct git_annotated_commit;

/**
 * @brief Handles merge conflict inspection and resolution.
 *
 * Provides methods to:
 *  - List conflicted files and their conflict blocks.
 *  - Resolve individual blocks by choosing "ours", "theirs", or "both".
 *  - Write resolved content to the working directory and stage it.
 */
class GitConflict : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitConflict(QObject* parent = nullptr);

    /**
     * @brief Retrieves all merge conflicts in the repository.
     * @return GitResult containing a QVariantList. Each entry is a QVariantMap with:
     *         - "path": file path relative to repo root
     *         - "lines": raw lines of the working file (QStringList)
     *         - "blocks": list of conflict blocks (each block is a map with:
     *             "index": int, unique block index
     *             "startLine": int, 1‑based start line of the block
     *             "endLine": int, 1‑based end line of the block
     *             "currentText": QString, content of "ours" side
     *             "incomingText": QString, content of "theirs" side
     *             "lines": list of line maps (each with "number", "text", "role")
     *         )
     */
    Q_INVOKABLE GitResult getConflicts();

    /**
     * @brief Accepts the "ours" version for a specific conflict block.
     * @param filePath Path to the conflicted file.
     * @param blockIndex Index of the block (1‑based).
     * @return GitResult indicating success or failure.
     */
    Q_INVOKABLE GitResult acceptBlockOurs(const QString& filePath, int blockIndex);

    /**
     * @brief Accepts the "theirs" version for a specific conflict block.
     */
    Q_INVOKABLE GitResult acceptBlockTheirs(const QString& filePath, int blockIndex);

    /**
     * @brief Accepts both versions (concatenated) for a specific conflict block.
     */
    Q_INVOKABLE GitResult acceptBlockBoth(const QString& filePath, int blockIndex);

    /**
     * @brief Writes arbitrary content to a working file (used for manual edits).
     * @param filePath Path relative to repo root.
     * @param content New file content.
     * @return GitResult indicating success.
     */
    Q_INVOKABLE GitResult writeWorkingFile(const QString& filePath, const QString& content);

private:
    // Reads the current working file content as lines
    QStringList readWorkdirLines(const QString& filePath) const;

    // Parses conflict markers and returns a list of block maps
    QVariantList parseConflictBlocks(const QStringList& lines) const;

    // Writes content to working file (internal, no Git operations)
    bool writeFile(const QString& filePath, const QString& content) const;

    // Replaces a block (by index) with content determined by the three flags.
    // Exactly one of useOurs, useTheirs, useBoth should be true.
    GitResult replaceBlock(const QString& filePath, int blockIndex,
                           bool useOurs, bool useTheirs, bool useBoth);
};
