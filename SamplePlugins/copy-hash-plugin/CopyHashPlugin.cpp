#include "CopyHashPlugin.h"
#include <QGuiApplication>
#include <QClipboard>

void CopyHashPlugin::initialize(IPluginContext* ctx)
{
    m_ctx = ctx;
    ctx->registerContextMenu(this);
}

QList<IContextMenuPlugin::MenuTarget> CopyHashPlugin::targets() const
{
    return { MenuTarget::CommitGraph };
}

QList<IContextMenuPlugin::MenuItem> CopyHashPlugin::menuItems(MenuTarget /*target*/,
                                                               const QVariantMap& /*ctx*/) const
{
    return {
        { QStringLiteral("copy-full-hash"),  QStringLiteral("Copy Full Hash"),  QStringLiteral("copy"),  false, 10 },
        { QStringLiteral("copy-short-hash"), QStringLiteral("Copy Short Hash"), QStringLiteral("copy"),  false, 11 },
    };
}

void CopyHashPlugin::executeAction(const QString& itemId,
                                    MenuTarget /*target*/,
                                    const QVariantMap& ctx)
{
    const QString hash = ctx.value(QStringLiteral("hash")).toString();
    if (hash.isEmpty()) return;

    auto* clipboard = QGuiApplication::clipboard();

    if (itemId == QStringLiteral("copy-full-hash")) {
        clipboard->setText(hash);
        if (m_ctx) m_ctx->notify(QStringLiteral("Full hash copied: ") + hash, QStringLiteral("info"));
    } else if (itemId == QStringLiteral("copy-short-hash")) {
        const QString shortHash = hash.left(7);
        clipboard->setText(shortHash);
        if (m_ctx) m_ctx->notify(QStringLiteral("Short hash copied: ") + shortHash, QStringLiteral("info"));
    }
}
