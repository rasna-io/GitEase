#include "RepoNotesPlugin.h"

void RepoNotesPlugin::initialize(IPluginContext *ctx)
{
    ctx->registerDock(this);
}
