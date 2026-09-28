#pragma once

#include "RuleSupport.h"
#include <QJsonArray>

/*!
 * @brief Push rules, checked against the commits of @p branch that @p remote does not have yet.
 */
class PushRuleValidator
{
public:
    RuleViolations validatePush(const QString &repoPath,
                                const QString &remote,
                                const QString &branch,
                                bool force) const;
    void setRules(const QJsonArray &newRules);

private:
    QJsonArray m_rules;
};
