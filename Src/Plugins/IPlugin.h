#pragma once

#include <QString>
#include <QtPlugin>
#include "IPluginContext.h"

class IPlugin
{
public:
    virtual ~IPlugin() = default;

    virtual QString id()      const = 0;
    virtual QString name()    const = 0;
    virtual QString version() const = 0;

    virtual void initialize(IPluginContext* ctx) = 0;
    virtual void shutdown() = 0;
};

Q_DECLARE_INTERFACE(IPlugin, "com.gitease.IPlugin/1.0")
