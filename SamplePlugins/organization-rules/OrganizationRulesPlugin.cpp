#include "OrganizationRulesPlugin.h"
#include "RuleManager.h"
#include "IPluginContext.h"

#include <QQmlEngine>

void OrganizationRulesPlugin::initialize(IPluginContext *ctx)
{
    m_ruleManager = new RuleManager(this);

    qmlRegisterSingletonInstance(
        "GitEaseOrganizationRulesPlugin",
        1, 0,
        "RuleController",
        m_ruleManager);
    ctx->registerPage(this);
    ctx->registerRule(this);
}

void OrganizationRulesPlugin::repositoryChanged(const QString &repoPath)
{
    m_ruleManager->setCurrentRepoPath(repoPath);
}

GitResult OrganizationRulesPlugin::check(ActionContext *context)
{
    if (!context || !m_ruleManager)
        return GitResult(true);

    if (context->type == ActionType::Commit_msg)
        return m_ruleManager->commitMessageValidator().validateCommitMessage(context->commitMessage);

    return GitResult(true);
}


