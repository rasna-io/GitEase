#pragma once

#include "GitResult.h"
#include <QJsonArray>

class CommitMessageValidator
{
public:
    GitResult validateCommitMessage(const QString &message);
    void setRules(const QJsonArray &newRules);

private:
    QJsonArray m_rules;
};

