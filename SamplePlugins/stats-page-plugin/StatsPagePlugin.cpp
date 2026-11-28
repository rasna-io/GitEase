#include "StatsPagePlugin.h"

void StatsPagePlugin::initialize(IPluginContext* ctx)
{
    ctx->registerPage(this);
}
