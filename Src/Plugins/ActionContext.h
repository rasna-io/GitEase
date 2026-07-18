#pragma once

#include "GitResult.h"
#include <QMetaType>

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

Q_DECLARE_METATYPE(ActionContext*)

