#pragma once

#include "RuleSupport.h"
#include <QJsonArray>

class BranchNameValidator
{
public:
    //! Naming rules for a branch that is being created or renamed.
    RuleViolations validateBranchName(const QString &branchName) const;

    //! Branches listed under "Block branch deletion" can never be deleted.
    RuleViolations validateDeletion(const QString &branchName) const;

    //! True when an enabled rule asks to delete merged branches and @p branchName is not protected.
    bool shouldAutoDeleteAfterMerge(const QString &branchName) const;

    void setRules(const QJsonArray &newRules);

private:
    QJsonArray m_rules;
};
