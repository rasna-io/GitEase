#pragma once

#include <QObject>
#include "IDockPlugin.h"

class QmlHighlighterPlugin : public QObject, public IDockPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IDockPlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IDockPlugin)

public:
    QString id()      const override { return QStringLiteral("gitease.qml-highlighter"); }
    QString name()    const override { return QStringLiteral("QML Highlighter"); }
    QString version() const override { return QStringLiteral("1.0.0"); }
    QString dockTitle() const override { return QStringLiteral("QML Viewer"); }
    QString dockIcon()  const override { return {}; }

    QUrl dockQmlUrl() const override
    {
        return QUrl(QStringLiteral("qrc:/gitease.qml-highlighter/qml/HighlighterDock.qml"));
    }

    void initialize(IPluginContext* ctx) override;
    void shutdown()                      override {}

private:
    IPluginContext* m_ctx = nullptr;
};
