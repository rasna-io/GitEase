#pragma once

#include <QObject>
#include <QQmlEngine>
#include <git2.h>
#include <QVariantList>

#include "GitResult.h"
#include "IGitController.h"

/**
 * @class GitTree
 * @brief Provides read-only access to the repository file tree at any commit,
 * used by the Commit File Browser (browse files at a commit).
 */
class GitTree : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitTree(QObject *parent = nullptr);

    /**
     * @brief Retrieves the full file tree of the repository at a specific commit.
     * @param sha The full OID (or any revision string) of the commit
     * @return GitResult with data as QVariantList containing Maps of
     *         {name, path, type ("blob"|"tree"), depth, parentPath}
     *         ordered depth-first with folders before files inside each directory.
     */
    Q_INVOKABLE GitResult getFileTree(const QString &sha);

    /**
     * @brief Retrieves the content of a single file as it existed at a specific commit.
     * @param sha The full OID (or any revision string) of the commit
     * @param path Repository-relative file path (e.g. "Src/main.cpp")
     * @return GitResult with data as QVariantMap {path, content, isBinary, size}.
     *         For binary blobs, content is empty and isBinary is true.
     */
    Q_INVOKABLE GitResult getFileContent(const QString &sha, const QString &path);

    /**
     * @brief Saves the raw blob content of a file at a specific commit to a local path.
     *        Works for both text and binary files.
     * @param sha The full OID (or any revision string) of the commit
     * @param path Repository-relative file path
     * @param targetPath Absolute local filesystem path to write to
     * @return GitResult indicating success or failure
     */
    Q_INVOKABLE GitResult saveFileContent(const QString &sha, const QString &path, const QString &targetPath);

private:
    /**
     * @brief Resolves a revision string to the root tree of its commit.
     *        Works on any commit, including merge commits.
     * @return nullptr on failure (error message written to errorMessage)
     */
    git_tree* lookupCommitTree(const QString &sha, QString &errorMessage);

    /**
     * @brief Looks up the blob for a path inside a commit tree.
     * @return nullptr on failure (error message written to errorMessage)
     */
    git_blob* lookupBlob(const QString &sha, const QString &path, QString &errorMessage);

    /**
     * @brief Recursively appends tree entries (folders first, then files) to the list.
     * @return true on success, false if a subtree lookup failed
     */
    bool appendTreeEntries(git_tree *tree, const QString &basePath, int depth, QVariantList &entries);
};
