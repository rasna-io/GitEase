#pragma once

#include "GitResult.h"
#include "IGitController.h"

#include <QObject>
#include <QQmlEngine>

/**
 * @class GitBundle
 * @brief A Qt-based Git bundle management class using libgit2
 *
 * This class provides functionality for creating and extracting Git bundles,
 * which are archives containing Git objects and references. Bundles can be
 * used to transfer Git history between repositories without requiring a
 * direct connection.
 *
 * Supports both complete bundles (entire repository history) and diff bundles
 * (changes between two references).
 */
class GitBundle : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

    /**
     * @struct BundleContext
     * @brief Internal structure for managing bundle creation context
     */
    struct BundleContext {
        QString bundlePath;  ///< Path where the bundle file will be created
        QString commitSha;   ///< SHA of the commit being bundled
        QString branchName;  ///< Name of the branch being bundled
        QString refName;     ///< Full reference name (refs/heads/branch or refs/tags/tag)
        bool verified = false; ///< Whether the bundle has been verified
    };

public:

    /**
     * @brief Constructs a GitBundle instance
     * @param parent The parent QObject
     */
    explicit GitBundle(QObject *parent = nullptr);

    /**
     * @brief Creates a complete bundle containing all history from a branch
     *
     * This method creates a bundle file that contains the complete Git history
     * starting from the specified branch, including all commits, trees, and blobs
     * reachable from that branch.
     *
     * @param resolvedBranchName The actual branch name (e.g., "main", "feature-x")
     * @param refBranchName The reference name for the bundle header (e.g., "refs/heads/main")
     * @param path The file path where the bundle should be created (with or without .bundle extension)
     * @return GitResult indicating success or failure with details
     */
    Q_INVOKABLE GitResult buildCompleteBundle(const QString &resolvedBranchName,
                                              const QString &refBranchName,
                                              const QString &path);

    /**
     * @brief Creates a diff bundle containing changes between two references
     *
     * This method creates a bundle file that contains only the Git objects
     * that are present in the target reference but not in the base reference.
     * Useful for incremental updates or patches.
     *
     * @param baseRef The base reference to compare against (e.g., "main", commit SHA)
     * @param targetRef The target reference to bundle (e.g., "feature-branch", commit SHA)
     * @param refBranchName The reference name for the bundle header (e.g., "refs/heads/feature-branch")
     * @param path The file path where the bundle should be created (with or without .bundle extension)
     * @return GitResult indicating success or failure with details
     */
    Q_INVOKABLE GitResult buildDiffBundle(const QString &baseRef,
                                          const QString &targetRef,
                                          const QString &refBranchName,
                                          const QString &path);

    /**
     * @brief Unbundles using the Git CLI command
     *
     * This method uses the system's Git command-line tool to unbundle
     * the specified bundle file. The CLI handles all the complex pack
     * file operations and reference updates.
     *
     * @param bundlePath Path to the bundle file to unbundle
     * @return GitResult with success status and the unbundled commit SHA
     */
    Q_INVOKABLE GitResult unbundleWithCli(const QString &bundlePath);

    /**
     * @brief Unbundles using pure libgit2 (no CLI dependencies)
     *
     * This method extracts the pack data from the bundle file and indexes
     * it directly into the repository using libgit2. Does not create or
     * update any references - only returns the commit SHA for further processing.
     *
     * @param bundlePath Path to the bundle file to unbundle
     * @return GitResult with success status and the unbundled commit SHA
     */
    Q_INVOKABLE GitResult unbundle(const QString &bundlePath);

private:

    /**
     * @brief Writes the pack data to a bundle file with proper header
     * @param packbuilder The prepared pack builder containing objects to bundle
     * @param context Bundle context information (paths, SHAs, etc.)
     * @return GitResult indicating success or failure
     */
    GitResult writeBundleFile(git_packbuilder *packbuilder, const BundleContext &context);

    /**
     * @brief Cleans up libgit2 resources to prevent memory leaks
     * @param ref Git reference to free (can be nullptr)
     * @param object Git object to free (can be nullptr)
     * @param walker Git revision walker to free (can be nullptr)
     * @param packbuilder Git pack builder to free (can be nullptr)
     */
    void cleanupBundleResources(git_reference *ref, git_object *object, git_revwalk *walker, git_packbuilder *packbuilder);

    /**
     * @brief Sets up a pack builder for complete bundle creation
     * @param targetOid The OID of the commit to start bundling from
     * @param packbuilder Output parameter for the created pack builder
     * @param walker Output parameter for the revision walker
     * @return GitResult indicating success or failure
     */
    GitResult setupCompletePackbuilder(const git_oid *targetOid, git_packbuilder *&packbuilder, git_revwalk *&walker);

    /**
     * @brief Resolves a reference string to its commit OID and SHA
     * @param ref The reference string (branch name, tag, SHA, etc.)
     * @return Pair containing the commit OID and its SHA string
     */
    QPair<const git_oid*, QString> getReferenceCommit(const QString &ref);

    /**
     * @brief Sets up a pack builder for diff bundle creation
     * @param baseOid The base commit OID to compare against
     * @param targetOid The target commit OID to bundle
     * @param packbuilder Output parameter for the created pack builder
     * @param walker Output parameter for the revision walker
     * @param commitCount Output parameter for the number of new commits
     * @param newCommitShas Output parameter for list of new commit SHAs
     * @return GitResult indicating success or failure
     */
    GitResult setupDiffPackbuilder(const git_oid *baseOid,
                                   const git_oid *targetOid,
                                   git_packbuilder *&packbuilder,
                                   git_revwalk *&walker,
                                   int &commitCount,
                                   QStringList &newCommitShas);

    /**
     * @brief Recursively collects all Git objects from a tree
     * @param tree The Git tree to traverse
     * @param collectedObjects Set to store collected object SHAs
     */
    void collectTreeObjects(git_tree* tree, QSet<QString>& collectedObjects);

    /**
     * @brief Collects all Git objects reachable from a commit
     * @param commitOid The OID of the commit to analyze
     * @param collectedObjects Set to store collected object SHAs
     */
    void collectCommitObjects(const git_oid* commitOid, QSet<QString>& collectedObjects);

    /**
     * @brief Parses the header of a bundle file
     * @param bundlePath Path to the bundle file
     * @param commitSha Output parameter for the commit SHA from header
     * @param refName Output parameter for the reference name from header
     * @return GitResult indicating success or failure
     */
    GitResult parseBundleHeader(const QString &bundlePath,
                                QString &commitSha,
                                QString &refName);

    /**
     * @brief Extracts raw pack data from a bundle file
     * @param bundlePath Path to the bundle file
     * @param packData Output parameter for the extracted pack data
     * @return true if extraction successful, false otherwise
     */
    bool extractPackDataFromBundle(const QString &bundlePath, QByteArray &packData);

    /**
     * @brief Manually verifies pack data integrity
     * @param packData The raw pack data to verify
     * @return true if pack data is valid, false otherwise
     */
    bool verifyPackDataManually(const QByteArray &packData);

    /**
     * @brief Adds pack data to the repository using libgit2 indexer
     * @param packData The pack data to add to the repository
     * @return true if indexing successful, false otherwise
     */
    bool addPackDataToRepository(const QByteArray &packData);

    /**
     * @brief Finds the offset where pack data starts in a bundle file
     * @param bundlePath Path to the bundle file
     * @return Offset in bytes where pack data begins, or -1 on error
     */
    qint64 findPackDataOffset(const QString &bundlePath);
};
