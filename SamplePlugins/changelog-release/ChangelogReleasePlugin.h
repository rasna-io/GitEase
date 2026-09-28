#pragma once

#include <QObject>
#include "IPagePlugin.h"

class ChangelogReleasePlugin : public QObject, public IPagePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IPagePlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IPagePlugin)

public:
    QString id()      const override { return QStringLiteral("com.gitease.changelog-release"); }
    QString name()    const override { return QStringLiteral("Changelog & Release"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext* ctx) override;
    void shutdown() override {}

    QString pageId()     const override { return QStringLiteral("com.gitease.changelog-release"); }
    QString pageTitle()  const override { return QStringLiteral("Releases"); }
    QString pageIcon()   const override { return QStringLiteral("\uf02b"); } // fa-tag
    QUrl    pageQmlUrl() const override
    {
        return QUrl(QStringLiteral("qrc:/com.gitease.changelog-release/qml/ChangelogPage.qml"));
    }
    int     pageOrder()  const override { return 70; }
};
