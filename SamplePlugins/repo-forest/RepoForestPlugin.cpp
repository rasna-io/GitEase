#include "RepoForestPlugin.h"
#include "GitScanner.h"
#include "IPluginContext.h"

#include <QQmlEngine>

void RepoForestPlugin::initialize(IPluginContext* ctx)
{
    qmlRegisterType<GitScanner>("GitEaseRepoForest", 1, 0, "GitScanner");
    ctx->registerDock(this);
}
