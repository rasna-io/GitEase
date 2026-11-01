#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QStringList>
#include <QUrl>
#include <QVariantList>
#include <git2.h>

#include "GitResult.h"
#include "IGitController.h"

class QTimer;

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

    /**
     * @brief Writes the staged blob for @p path to @p targetPath.
     *        The index is not a commit, so saveFileContent() cannot read it.
     */
    Q_INVOKABLE GitResult saveIndexFileContent(const QString &path, const QString &targetPath);

    /**
     * @brief Path this file had in @p oldRevision when the change is a rename.
     *        @p mode is "workdir" (old revision to the working tree), "index"
     *        (old revision to the index), or "commit" (old revision to @p newRevision).
     *        Returns @p filePath when the file was not renamed.
     */
    Q_INVOKABLE QString previousPath(const QString &filePath, const QString &oldRevision,
                                     const QString &mode, const QString &newRevision);

    //! Absolute path of a working-tree file. Does not check that the file exists.
    Q_INVOKABLE QString absoluteWorkdirFile(const QString &repositoryPath, const QString &filePath) const;

    Q_INVOKABLE bool localFileExists(const QString &path) const;

    Q_INVOKABLE QUrl localFileUrl(const QString &path) const;

    //! Unique path under the system temp directory. The file is not created yet.
    Q_INVOKABLE QString makeTempImagePath(const QString &extension) const;

    //! Deletes temp files this class created. Ignores every other path.
    //! Removal is retried briefly so a picture that still has the file open can finish with it.
    Q_INVOKABLE void discardTempFiles(const QStringList &paths);

    ~GitTree() override;

private:
    void flushTempFiles();

    QTimer *m_tempDiscardTimer = nullptr;
    QStringList m_pendingTempFiles;
    int m_tempDiscardAttempts = 0;
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
