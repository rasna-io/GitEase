#pragma once

#include "IPlugin.h"
#include "Auth/IGitAuth.h"
#include <QtPlugin>

class IAuthPlugin : public IPlugin
{
public:
    virtual QString   authType()                    const = 0;
    virtual bool      canHandle(const QString& url) const = 0;
    virtual IGitAuth* createAuth()                        = 0;
};

Q_DECLARE_INTERFACE(IAuthPlugin, "com.gitease.IAuthPlugin/1.0")
