#include "ImageDiffPlugin.h"

#include "IPluginContext.h"

void ImageDiffPlugin::initialize(IPluginContext *ctx)
{
    ctx->registerDiff(this);
}

QStringList ImageDiffPlugin::handledExtensions() const
{
    return {
        QStringLiteral("png"),
        QStringLiteral("jpg"),
        QStringLiteral("jpeg"),
        QStringLiteral("gif"),
        QStringLiteral("webp"),
        QStringLiteral("bmp"),
        QStringLiteral("ico"),
        QStringLiteral("svg"),
        QStringLiteral("svgz")
    };
}
