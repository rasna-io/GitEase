#pragma once

#include "IPlugin.h"
#include <QUrl>
#include <QtPlugin>

class IDockPlugin : public IPlugin
{
public:
    virtual QUrl    dockQmlUrl()     const = 0;
    virtual QString dockTitle()      const = 0;
    virtual QString dockIcon()       const { return {}; }
    virtual bool    defaultVisible() const { return true; }
};

Q_DECLARE_INTERFACE(IDockPlugin, "com.gitease.IDockPlugin/1.0")
