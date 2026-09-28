#pragma once

#include "RuleSupport.h"
#include <QJsonArray>

class CommitMessageValidator
{
public:
    //! Returns at most one violation per enabled rule.
    RuleViolations validateCommitMessage(const QString &message) const;
    void setRules(const QJsonArray &newRules);

private:
    QJsonArray m_rules;
};
