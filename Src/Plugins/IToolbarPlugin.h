#pragma once

#include "IPlugin.h"
#include <QList>
#include <QVariantMap>
#include <QtPlugin>

/*!
 * \brief Plugin interface for adding buttons to the main application toolbar.
 *
 * Call ctx->registerToolbar(this) inside initialize().
 */
class IToolbarPlugin : public IPlugin
{
public:
    struct ToolbarAction {
        QString id;
        QString tooltip;
        QString icon;    // Font Awesome codepoint
        int     order = 100;
    };

    virtual QList<ToolbarAction> toolbarActions() const = 0;

    // Called when the user clicks an action registered by this plugin
    virtual void onToolbarAction(const QString&    actionId,
                                 const QVariantMap& ctx) = 0;
};

Q_DECLARE_INTERFACE(IToolbarPlugin, "com.gitease.IToolbarPlugin/1.0")
