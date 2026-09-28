#pragma once

#include "IPlugin.h"
#include <QStringList>
#include <QVariantMap>
#include <functional>
#include <QtPlugin>

/*!
 * \brief Plugin interface for hooking into git workflow lifecycle events.
 *
 * Implement this to intercept or react to git operations.
 * Call ctx->registerWorkflow(this) inside initialize().
 *
 * Pre-events ("pre-commit", "pre-push", "pre-merge"):
 *   Call resolve(true) to allow or resolve(false) to block the operation.
 *   The plugin MUST call resolve exactly once (may be deferred to after UI interaction).
 *
 * Post-events ("post-commit", "post-fetch", "post-checkout"):
 *   Called for notification only; resolve's bool value is ignored.
 */
class IWorkflowPlugin : public IPlugin
{
public:
    virtual QStringList handledEvents() const = 0;
    // Supported events:
    //   "pre-commit"    "post-commit"
    //   "pre-push"      "post-push"
    //   "post-fetch"
    //   "pre-merge"     "post-merge"
    //   "post-checkout"

    virtual void onEvent(const QString&              event,
                         const QVariantMap&          context,
                         std::function<void(bool)>   resolve) = 0;
};

Q_DECLARE_INTERFACE(IWorkflowPlugin, "com.gitease.IWorkflowPlugin/1.0")
