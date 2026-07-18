#pragma once

#include <QObject>
#include "IWorkflowPlugin.h"

class CommitGuardPlugin : public QObject, public IWorkflowPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.gitease.IWorkflowPlugin/1.0" FILE "plugin.json")
    Q_INTERFACES(IPlugin IWorkflowPlugin)

public:
    // ── IPlugin ──────────────────────────────────────────────────────────────
    QString id()      const override { return QStringLiteral("com.gitease.commit-guard"); }
    QString name()    const override { return QStringLiteral("Commit Guard"); }
    QString version() const override { return QStringLiteral("1.0.0"); }

    void initialize(IPluginContext* ctx) override;
    void shutdown()                      override {}

    // ── IWorkflowPlugin ──────────────────────────────────────────────────────
    QStringList handledEvents() const override;
    void onEvent(const QString& event, const QVariantMap& context,
                 std::function<void(bool)> resolve) override;

private:
    IPluginContext* m_ctx = nullptr;

    static constexpr int kMinMessageLength = 10;
};
