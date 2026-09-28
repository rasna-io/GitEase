#pragma once

#include <QObject>
#include <QtPlugin>

#include "IDiffPlugin.h"

class SyntaxColorsPlugin : public QObject, public IDiffPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IDiffPlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IDiffPlugin)

public:
    QString id()      const override { return QStringLiteral("com.gitease.syntax-colors"); }
    QString name()    const override { return QStringLiteral("Syntax Colors"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext *ctx) override;
    void shutdown() override {}

    //! Every extension and well-known file name (Makefile, Dockerfile...) of the supported languages.
    QStringList handledExtensions() const override;
    QUrl        colorizerQmlUrl()   const override
    {
        return QUrl(QStringLiteral("qrc:/com.gitease.syntax-colors/qml/Colorizer.qml"));
    }
};
