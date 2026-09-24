#pragma once

#include <QObject>
#include "IDockPlugin.h"

class RepoForestPlugin : public QObject, public IDockPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IDockPlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IDockPlugin)

public:
    QString id()      const override { return QStringLiteral("com.gitease.repo-forest"); }
    QString name()    const override { return QStringLiteral("Repo Forest"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext* ctx) override;
    void shutdown() override {}

    QUrl dockQmlUrl() const override
    {
        return QUrl(QStringLiteral("qrc:/com.gitease.repo-forest/qml/RepoForestDock.qml"));
    }

    QString dockTitle() const override { return QStringLiteral("Repo Forest"); }
    QString dockIcon()  const override { return QStringLiteral("tree"); }
};
