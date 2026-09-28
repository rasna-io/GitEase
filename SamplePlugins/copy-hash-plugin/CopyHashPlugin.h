#pragma once

#include <QObject>
#include "IContextMenuPlugin.h"

class CopyHashPlugin : public QObject, public IContextMenuPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IContextMenuPlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IContextMenuPlugin)

public:
    // ── IPlugin ──────────────────────────────────────────────────────────────
    QString id()      const override { return QStringLiteral("com.gitease.copy-hash"); }
    QString name()    const override { return QStringLiteral("Copy Hash"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext* ctx) override;
    void shutdown()                      override {}

    // ── IContextMenuPlugin ───────────────────────────────────────────────────
    QList<MenuTarget> targets() const override;
    QList<MenuItem>   menuItems(MenuTarget target, const QVariantMap& ctx) const override;
    void              executeAction(const QString& itemId, MenuTarget target,
                                   const QVariantMap& ctx) override;

private:
    IPluginContext* m_ctx = nullptr;
};
