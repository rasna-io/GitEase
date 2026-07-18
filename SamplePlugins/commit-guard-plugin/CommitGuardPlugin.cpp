#include "CommitGuardPlugin.h"

void CommitGuardPlugin::initialize(IPluginContext* ctx)
{
    m_ctx = ctx;
    ctx->registerWorkflow(this);
}

QStringList CommitGuardPlugin::handledEvents() const
{
    return { QStringLiteral("pre-commit") };
}

void CommitGuardPlugin::onEvent(const QString& event,
                                 const QVariantMap& context,
                                 std::function<void(bool)> resolve)
{
    if (event != QStringLiteral("pre-commit")) {
        resolve(true);
        return;
    }

    const QString message = context.value(QStringLiteral("message")).toString().trimmed();

    if (message.length() < kMinMessageLength) {
        if (m_ctx) {
            m_ctx->notify(
                QString("Commit blocked: message must be at least %1 characters (got %2).")
                    .arg(kMinMessageLength)
                    .arg(message.length()),
                QStringLiteral("warning")
            );
        }
        resolve(false);
        return;
    }

    // Warn if message doesn't start with a capital letter (best practice)
    if (!message.isEmpty() && !message.at(0).isUpper()) {
        if (m_ctx) {
            m_ctx->notify(
                QStringLiteral("Tip: commit messages conventionally start with a capital letter."),
                QStringLiteral("info")
            );
        }
    }

    resolve(true);
}
