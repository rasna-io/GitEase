#pragma once

#include <QObject>
#include <QtPlugin>

#include "IDockPlugin.h"

class RepoNotesPlugin : public QObject, public IDockPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IDockPlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IDockPlugin)

public:
    QString id()      const override { return QStringLiteral("com.gitease.repo-notes"); }
    QString name()    const override { return QStringLiteral("Repo Notes"); }
    QString version() const override { return QStringLiteral("1.1.0"); }

    void initialize(IPluginContext *ctx) override;
    void shutdown() override {}

    QUrl    dockQmlUrl() const override
    {
        return QUrl(QStringLiteral("qrc:/com.gitease.repo-notes/qml/NotesDock.qml"));
    }
    QString dockTitle() const override { return QStringLiteral("Repo Notes"); }
    QString dockIcon()  const override { return QStringLiteral("\uf03a"); }
};
