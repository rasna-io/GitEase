#include "StatsPagePlugin.h"

void StatsPagePlugin::initialize(IPluginContext* ctx)
{
    ctx->registerPage(this);

    // Subscribe to events to demonstrate the event bus
    ctx->subscribe(QStringLiteral("commit.selected"), [ctx](const QVariantMap& payload) {
        Q_UNUSED(payload)
        // Event received — the QML page handles its own subscriptions via eventBus property
    });
}
