#pragma once

#include <QObject>
#include <QtPlugin>

#include "IDiffPlugin.h"

class ImageDiffPlugin : public QObject, public IDiffPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IDiffPlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IDiffPlugin)

public:
    QString id()      const override { return QStringLiteral("com.gitease.image-diff"); }
    QString name()    const override { return QStringLiteral("Image Diff"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext *ctx) override;
    void shutdown() override {}

    QStringList handledExtensions() const override;
    QUrl        diffViewerQmlUrl()  const override
    {
        return QUrl(QStringLiteral("qrc:/com.gitease.image-diff/qml/ImageDiffViewer.qml"));
    }
};
