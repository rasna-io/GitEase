#pragma once

#include "IPlugin.h"
#include <QUrl>
#include <QtPlugin>

/*!
 * \brief Plugin interface for registering full navigation pages.
 *
 * Implement this to add a new page to the NavigationRail.
 * Call ctx->registerPage(this) inside initialize().
 */
class IPagePlugin : public IPlugin
{
public:
    virtual QString pageId()     const = 0;  // unique, e.g. "com.acme.ci-dashboard"
    virtual QString pageTitle()  const = 0;  // shown in NavigationRail tooltip / label
    virtual QString pageIcon()   const = 0;  // Font Awesome Unicode codepoint string
    virtual QUrl    pageQmlUrl() const = 0;  // file:// or qrc:// to the full-page QML
    virtual int     pageOrder()  const { return 100; } // sort weight; built-in pages use 0–50
};

Q_DECLARE_INTERFACE(IPagePlugin, "com.gitease.IPagePlugin/1.0")
