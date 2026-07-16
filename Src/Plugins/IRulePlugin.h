#pragma once

#include "IPlugin.h"
#include "ActionContext.h"
#include <QUrl>
#include <QtPlugin>

class IRulePlugin
{
public:
    virtual ~IRulePlugin() = default;

    virtual GitResult check(ActionContext* context) = 0;
};

Q_DECLARE_INTERFACE(IRulePlugin, "com.gitease.IRulePlugin/1.0")
