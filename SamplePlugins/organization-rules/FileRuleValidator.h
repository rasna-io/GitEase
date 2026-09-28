#pragma once

#include "RuleSupport.h"
#include <QJsonArray>

/*!
 * @brief File & Code rules, checked against the staged index right before a commit.
 */
class FileRuleValidator
{
public:
    RuleViolations validateStagedChanges(const QString &repoPath) const;
    void setRules(const QJsonArray &newRules);

    bool hasEnabledRules() const;

private:
    QJsonArray m_rules;
};
