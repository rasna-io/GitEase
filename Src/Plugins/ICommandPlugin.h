#pragma once

#include "IPlugin.h"
#include <QList>
#include <QStringList>
#include <QVariantMap>
#include <QtPlugin>

class ICommandPlugin : public IPlugin
{
public:
    struct Command {
        QString     id;
        QString     label;
        QString     icon;
        QString     shortcut;
        QStringList contexts; // "repository" | "branch" | "commit" | "file"
    };

    virtual QList<Command> commands()                                          const = 0;
    virtual void           execute(const QString& commandId,
                                   const QVariantMap& ctx)                           = 0;
};

Q_DECLARE_INTERFACE(ICommandPlugin, "com.gitease.ICommandPlugin/1.0")
