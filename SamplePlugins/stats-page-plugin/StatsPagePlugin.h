#pragma once

#include <QObject>
#include "IPagePlugin.h"

class StatsPagePlugin : public QObject, public IPagePlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IPagePlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IPagePlugin)

public:
    // ── IPlugin ──────────────────────────────────────────────────────────────
    QString id()      const override { return QStringLiteral("com.gitease.stats-page"); }
    QString name()    const override { return QStringLiteral("Stats Page"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext* ctx) override;
    void shutdown()                      override {}

    // ── IPagePlugin ──────────────────────────────────────────────────────────
    QString pageId()     const override { return QStringLiteral("stats"); }
    QString pageTitle()  const override { return QStringLiteral("Stats"); }
    QString pageIcon()   const override { return QStringLiteral("\uf080"); } // fa-chart-bar
    QUrl    pageQmlUrl() const override
    {
        return QUrl(QStringLiteral("qrc:/com.gitease.stats-page/qml/StatsPage.qml"));
    }
    int pageOrder() const override { return 90; } // after built-in pages
};
