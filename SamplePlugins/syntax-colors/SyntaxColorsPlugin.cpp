#include "SyntaxColorsPlugin.h"

#include "IPluginContext.h"
#include "Languages.h"
#include "SyntaxColorizer.h"

#include <QQmlEngine>

void SyntaxColorsPlugin::initialize(IPluginContext *ctx)
{
    qmlRegisterType<SyntaxColorizer>("GitEaseSyntaxColors", 1, 0, "SyntaxColorizer");
    ctx->registerDiff(this);
}

QStringList SyntaxColorsPlugin::handledExtensions() const
{
    QStringList extensions;
    for (const CodeViewer::Language &language : CodeViewer::languages()) {
        if (language.id == QStringLiteral("plaintext"))
            continue;
        for (const QString &extension : language.extensions)
            extensions.append(extension.toLower());
        // The host looks files up by the text after the last dot, which is the whole name
        // for files such as "Makefile".
        for (const QString &fileName : language.fileNames)
            if (!fileName.contains(QLatin1Char('.')))
                extensions.append(fileName.toLower());
    }
    // CMakeLists.txt is detected by name once the colorizer sees the path.
    extensions.append(QStringLiteral("txt"));
    extensions.removeDuplicates();
    return extensions;
}
