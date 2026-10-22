#pragma once

#include <QObject>
#include "IPagePlugin.h"

class PalettoPlugin : public QObject, public IPagePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IPagePlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IPagePlugin)

public:
    QString id()      const override;
    QString name()    const override;
    QString version() const override;

    void initialize(IPluginContext* ctx) override;
    void shutdown() override;

    QString pageId()     const override;
    QString pageTitle()  const override;
    QString pageIcon()   const override;
    QUrl    pageQmlUrl() const override;
    int     pageOrder()  const override;
};
