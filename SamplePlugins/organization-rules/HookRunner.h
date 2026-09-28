#pragma once

#include "RuleSupport.h"
#include <QJsonArray>

/*!
 * @brief Runs the enabled custom hooks for a trigger ("pre-commit", "commit-msg", "pre-push",
 * "post-merge", "post-checkout").
 *
 * Foreground hooks block the calling (GUI) thread for at most their timeout. Hooks that fail
 * become violations according to their "On failure" setting; post-* hooks can only warn.
 */
class HookRunner
{
public:
    struct Invocation
    {
        QString trigger;
        QString repoPath;
        QString commitMessage;
        QString remoteName;
        QString branchName;
    };

    RuleViolations run(const Invocation &invocation) const;
    void setRules(const QJsonArray &newRules);

private:
    QJsonArray m_rules;
};
