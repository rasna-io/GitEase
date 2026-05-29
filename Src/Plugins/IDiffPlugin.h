#pragma once

#include "IPlugin.h"
#include <QStringList>
#include <QUrl>
#include <QtPlugin>

class IDiffPlugin : public IPlugin
{
public:
    virtual QStringList handledExtensions() const = 0;
    virtual QUrl        diffViewerQmlUrl()  const { return {}; }
    virtual QUrl        colorizerQmlUrl()   const { return {}; }
};

Q_DECLARE_INTERFACE(IDiffPlugin, "com.gitease.IDiffPlugin/1.0")
