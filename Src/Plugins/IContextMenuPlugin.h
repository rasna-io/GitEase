#pragma once

#include "IPlugin.h"
#include <QList>
#include <QVariantMap>
#include <QtPlugin>

/*!
 * \brief Plugin interface for extending context menus in the UI.
 *
 * Implement this to add items to commit graph, branch, or file right-click menus.
 * Call ctx->registerContextMenu(this) inside initialize().
 */
class IContextMenuPlugin : public IPlugin
{
public:
    enum class MenuTarget {
        CommitGraph,  // right-click on a commit row in the graph
        Branch,       // right-click on a branch item
        File          // right-click on a file in the changes list
    };

    struct MenuItem {
        QString id;
        QString label;
        QString icon;          // Font Awesome codepoint or empty
        bool    separator = false;
        int     order     = 100;
    };

    // Which surfaces this plugin contributes to
    virtual QList<MenuTarget> targets() const = 0;

    // Items to show for the given target; ctx contains: hash, branch, filePath, repoPath, etc.
    virtual QList<MenuItem> menuItems(MenuTarget target,
                                      const QVariantMap& ctx) const = 0;

    // Called when the user clicks an item registered by this plugin
    virtual void executeAction(const QString& itemId,
                               MenuTarget     target,
                               const QVariantMap& ctx) = 0;
};

Q_DECLARE_INTERFACE(IContextMenuPlugin, "com.gitease.IContextMenuPlugin/1.0")
