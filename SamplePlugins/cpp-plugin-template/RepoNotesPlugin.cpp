#include "RepoNotesPlugin.h"

void RepoNotesPlugin::initialize(IPluginContext* ctx)
{
    m_ctx = ctx;

    // All calls go through the IPluginContext vtable —
    // no direct linkage to the host executable required.
    ctx->registerDock(this);
}
