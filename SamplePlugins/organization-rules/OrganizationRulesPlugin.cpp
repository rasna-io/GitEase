#include "OrganizationRulesPlugin.h"
#include "RuleManager.h"
#include "IPluginContext.h"

#include <QQmlEngine>

#include <algorithm>

namespace {

bool hasBlocking(const RuleViolations &violations)
{
    return std::any_of(violations.begin(), violations.end(),
                       [](const RuleViolation &v) { return v.blocking; });
}

bool localBranchExists(const QString &repoPath, const QString &branch)
{
    return GitCli::run(repoPath, { "show-ref", "--verify", "--quiet", "refs/heads/" + branch }) == 0;
}

} // namespace

void OrganizationRulesPlugin::initialize(IPluginContext *ctx)
{
    m_ruleManager = new RuleManager(this);
    m_reporter.setContext(ctx);

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

    switch (context->type) {
    case ActionType::Commit_msg:
        return checkCommit(*context);

    case ActionType::BranchCreate:
        return report("branch create",
                      m_ruleManager->branchNameValidator().validateBranchName(context->branchName));

    case ActionType::BranchDelete:
        return report("branch delete",
                      m_ruleManager->branchNameValidator().validateDeletion(context->branchName));

    case ActionType::Push:
        return checkPush(*context);

    case ActionType::PostMerge:
        return afterMerge(*context);

    case ActionType::PostCheckout:
        return report("checkout", m_ruleManager->hookRunner().run(
                                      { "post-checkout", m_ruleManager->currentRepoPath(), {}, {},
                                        context->branchName }));
    }

    return GitResult(true);
}

GitResult OrganizationRulesPlugin::checkCommit(const ActionContext &context)
{
    const QString repoPath = m_ruleManager->currentRepoPath();

    RuleViolations violations = m_ruleManager->commitMessageValidator().validateCommitMessage(context.commitMessage);
    violations << m_ruleManager->fileRuleValidator().validateStagedChanges(repoPath);

    // Hooks can be slow; skip them when the commit is already rejected.
    if (!hasBlocking(violations)) {
        const HookRunner &hooks = m_ruleManager->hookRunner();
        violations << hooks.run({ "pre-commit", repoPath, context.commitMessage, {}, {} });
        if (!hasBlocking(violations))
            violations << hooks.run({ "commit-msg", repoPath, context.commitMessage, {}, {} });
    }

    return report("commit", violations);
}

GitResult OrganizationRulesPlugin::checkPush(const ActionContext &context)
{
    const QString repoPath = m_ruleManager->currentRepoPath();

    RuleViolations violations = m_ruleManager->pushRuleValidator().validatePush(
        repoPath, context.remoteName, context.branchName, context.forcePush);

    if (!hasBlocking(violations)) {
        violations << m_ruleManager->hookRunner().run(
            { "pre-push", repoPath, {}, context.remoteName, context.branchName });
    }

    return report("push", violations);
}

GitResult OrganizationRulesPlugin::afterMerge(const ActionContext &context)
{
    const QString repoPath = m_ruleManager->currentRepoPath();

    report("merge", m_ruleManager->hookRunner().run({ "post-merge", repoPath, {}, {}, context.branchName }));

    if (m_ruleManager->branchNameValidator().shouldAutoDeleteAfterMerge(context.branchName)
        && localBranchExists(repoPath, context.branchName)) {
        return GitResult(true, QVariantMap{ { "autoDeleteSourceBranch", true } });
    }

    return GitResult(true);
}

GitResult OrganizationRulesPlugin::report(const QString &action, const RuleViolations &violations)
{
    m_reporter.setRules(m_ruleManager->notificationRules());
    return m_reporter.report(m_ruleManager->currentRepoPath(), action, violations);
}
