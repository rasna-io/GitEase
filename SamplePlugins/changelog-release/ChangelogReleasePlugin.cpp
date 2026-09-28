#include "ChangelogReleasePlugin.h"
#include "ReleaseEngine.h"
#include "IPluginContext.h"

#include <QQmlEngine>

void ChangelogReleasePlugin::initialize(IPluginContext* ctx)
{
    qmlRegisterType<ReleaseEngine>("GitEaseChangelog", 1, 0, "ReleaseEngine");
    ctx->registerPage(this);
}
