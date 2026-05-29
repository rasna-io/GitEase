#pragma once

#include "IPlugin.h"
#include <QtPlugin>

class IServicePlugin : public IPlugin
{
public:
    virtual void start() = 0;
    virtual void stop()  = 0;
};

Q_DECLARE_INTERFACE(IServicePlugin, "com.gitease.IServicePlugin/1.0")
