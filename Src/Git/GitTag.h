#pragma once

#include <QObject>
#include <QQmlEngine>
#include <git2.h>
#include <QVariantList>

#include "GitResult.h"
#include "IGitController.h"

/**`
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

signals:
    /**
     * @brief Notifies the UI (Graph/Utility Card) that tags have changed.
     */
    void tagsChanged();

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
};
