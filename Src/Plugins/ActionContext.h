#pragma once

#include "GitResult.h"
#include <QMetaType>

enum ActionType
{
    Commit_msg,
    Push,
    BranchCreate,

    // Appended so the values above stay stable for plugins built against older headers.
    BranchDelete,   //!< Before a local branch is deleted; branchName is the branch.
    PostMerge,      //!< After a successful merge; branchName is the merged source branch.
    PostCheckout    //!< After a successful checkout; branchName is the checked-out branch.
};

class ActionContext
{
public:
    ActionType type;

    GitResult result;

    QString commitMessage;
    QString branchName;
    QStringList changedFiles;

    // Appended members, filled for Push.
    QString remoteName;
    bool    forcePush = false;
};

Q_DECLARE_METATYPE(ActionContext*)
