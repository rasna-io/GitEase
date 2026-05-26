#pragma once

#include <QObject>
#include <QQmlEngine>
#include <git2.h>
#include <QVariantList>

#include "GitResult.h"
#include "IGitController.h"

/**
 * @class GitTag
 * @brief Manages Git tagging operations, providing integration for both
 * the Utility Page and the Graph View.
 */
class GitTag : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit GitTag(QObject *parent = nullptr);

    /**
     * @brief Retrieves all tags in the current repository.
     * @return GitResult with data as QVariantList containing Maps of {name, commitId, message, isAnnotated}
     */
    Q_INVOKABLE GitResult list();

    /**
     * @brief Creates a new tag at a specific commit.
     * @param name The tag name (e.g., "v1.0.0")
     * @param targetId The full 40-character OID of the commit to tag
     * @param message If not empty, creates an 'Annotated' tag; otherwise 'Lightweight'
     * @param force If true, overwrites any existing tag with the same name
     * @return GitResult indicating success or failure
     */
    Q_INVOKABLE GitResult create(const QString &name,
                                 const QString &targetId,
                                 const QString &message = "",
                                 bool force = false);

    /**
     * @brief Deletes a tag from the repository.
     * @param name The name of the tag to delete
     * @return GitResult indicating success or failure
     */
    Q_INVOKABLE GitResult remove(const QString &name);

    /**
     * @brief Pushes a specific tag asynchronously to the remote repository (origin).
     * @param name The name of the tag to push
     * @return GitResult indicating success or failure
     */
    Q_INVOKABLE GitResult pushTag(const QString &name);

    /**
    * @brief Deletes a specific tag asynchronously from the remote repository (origin).
    * @param name The name of the tag to delete from remote
    * @return GitResult indicating success or failure
    */
    Q_INVOKABLE GitResult pushDeleteTag(const QString &name);

signals:
    /**
     * @brief Notifies the UI (Graph/Utility Card) that tags have changed.
     */
    void tagsChanged();

    /**
     * @brief Notifies the UI (Graph/Utility Card) that tag has been created.
     */
    void pushTagFinished(GitResult result);

    /**
     * @brief Notifies the UI (Graph/Utility Card) that tag has been deleted.
     */
    void pushDeleteTagFinished(GitResult result, QString tagName);

private:
    /**
     * @brief Internal payload for libgit2 foreach callback.
     */
    struct TagPayload {
        git_repository* repo;
        QVariantList* list;
    };

    /**
     * @brief Static callback required by libgit2 to iterate over tags.
     */
    static int tagForeachCallback(const char *name, git_oid *oid, void *payload);


    /**
     * @brief Internal implementation for pushing a specific tag to remote repository (origin).
     * @param name The name of the tag to push
     * @return GitResult indicating success or failure
     */
    GitResult pushTagInternal(const QString &name);
    GitResult pushTagStartAsyncInternal(const QString &name);

    /**
     * @brief Internal implementation for deleting a specific tag from the remote repository (origin).
    * @param name The name of the tag to delete from remote
    * @return GitResult indicating success or failure
    */
    GitResult pushDeleteTagInternal(const QString &name);
    GitResult pushDeleteTagStartAsyncInternal(const QString &name);

private:
    bool m_pushTagInProgress{false};
    bool m_pushDeleteTagInProgress{false};
};
