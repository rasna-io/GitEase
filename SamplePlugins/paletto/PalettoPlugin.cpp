#include "PalettoPlugin.h"
#include "PalettoEngine.h"
#include "EyeDropper.h"
#include "IPluginContext.h"

#include <QQmlEngine>

QString PalettoPlugin::id() const
{
    return QStringLiteral("com.gitease.paletto");
}

QString PalettoPlugin::name() const
{
    return QStringLiteral("Paletto");
}

QString PalettoPlugin::version() const
{
    return QStringLiteral("1.0.0");
}

void PalettoPlugin::initialize(IPluginContext* ctx)
{
    qmlRegisterType<PalettoEngine>("GitEasePaletto", 1, 0, "PalettoEngine");
    qmlRegisterType<EyeDropper>("GitEasePaletto", 1, 0, "EyeDropper");
    ctx->registerPage(this);
}

void PalettoPlugin::shutdown()
{
}

QString PalettoPlugin::pageId() const
{
    return QStringLiteral("com.gitease.paletto");
}

QString PalettoPlugin::pageTitle() const
{
    return QStringLiteral("Paletto");
}

QString PalettoPlugin::pageIcon() const
{
    return QStringLiteral(""); // fa-palette
}

QUrl PalettoPlugin::pageQmlUrl() const
{
    return QUrl(QStringLiteral("qrc:/com.gitease.paletto/qml/PalettoPage.qml"));
}

int PalettoPlugin::pageOrder() const
{
    return 80;
}
