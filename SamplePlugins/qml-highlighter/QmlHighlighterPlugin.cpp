#include "QmlHighlighterPlugin.h"
#include "QmlSyntaxHighlighter.h"
#include <QQmlEngine>

void QmlHighlighterPlugin::initialize(IPluginContext* ctx)
{
    m_ctx = ctx;

    // Register our highlighter type so the dock QML can use it as:
    //   QmlSyntaxHighlighter { textDocument: editor.textDocument }
    qmlRegisterType<QmlSyntaxHighlighter>(
        "GitEase.Plugins.QmlHighlighter", 1, 0, "QmlSyntaxHighlighter");

    ctx->registerDock(this);
}
