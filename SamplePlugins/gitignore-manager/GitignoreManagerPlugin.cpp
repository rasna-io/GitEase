#include "GitignoreManagerPlugin.h"
#include "GitignoreEngine.h"
#include "IPluginContext.h"

#include <QQmlEngine>

QString GitignoreManagerPlugin::id() const
{
    return QStringLiteral("com.gitease.gitignore-manager");
}

QString GitignoreManagerPlugin::name() const
{
    return QStringLiteral("Gitignore Manager");
}

QString GitignoreManagerPlugin::version() const
{
    return QStringLiteral("1.0.0");
}

void GitignoreManagerPlugin::initialize(IPluginContext* ctx)
{
    qmlRegisterType<GitignoreEngine>("GitEaseGitignore", 1, 0, "GitignoreEngine");
    ctx->registerPage(this);
}

void GitignoreManagerPlugin::shutdown()
{
}

QString GitignoreManagerPlugin::pageId() const
{
    return QStringLiteral("com.gitease.gitignore-manager");
}

QString GitignoreManagerPlugin::pageTitle() const
{
    return QStringLiteral("Gitignore");
}

QString GitignoreManagerPlugin::pageIcon() const
{
    return QStringLiteral("\uf05e"); // fa-ban
}

QUrl GitignoreManagerPlugin::pageQmlUrl() const
{
    return QUrl(QStringLiteral("qrc:/com.gitease.gitignore-manager/qml/GitignorePage.qml"));
}

int GitignoreManagerPlugin::pageOrder() const
{
    return 75;
}
