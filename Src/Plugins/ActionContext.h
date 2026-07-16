#pragma once

#include "GitResult.h"

enum ActionType
{
    Commit_msg,
    Push,
    BranchCreate
};

class ActionContext
{
public:
    ActionType type;

    GitResult result;

    QString commitMessage;
    QString branchName;
    QStringList changedFiles;
};

