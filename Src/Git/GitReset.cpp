#include "GitReset.h"
#include <git2/reset.h>

GitReset::GitReset(QObject *parent)
    : IGitController{parent}
{}

GitResult GitReset::resetHead(const QString &commit, ResetMode mode)
{
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    git_object *target = nullptr;
    int result = git_revparse_single(
        &target,
        activeRepo(),
        commit.toUtf8().constData()
        );

    if (result != GIT_OK) {
        git_object_free(target);
        return GitResult(false, {}, git_error_last()->message);
    }

    git_reset_t resetType;
    QString gitCmd = "git reset";

    switch (mode) {
    case ResetMode::Soft:
        resetType = GIT_RESET_SOFT;
        gitCmd += " --soft";
        break;

    case ResetMode::Mixed:
        resetType = GIT_RESET_MIXED;
        gitCmd += " --mixed";
        break;

    case ResetMode::Hard:
        resetType = GIT_RESET_HARD;
        gitCmd += " --hard";
        break;

    default:
        git_object_free(target);
        return GitResult(false, QVariant(), "Invalid reset mode.");
    }

    gitCmd += " " + commit;

    result = git_reset(activeRepo(), target, resetType, nullptr);

    git_object_free(target);

    if (result != GIT_OK) {
        const git_error *e = git_error_last();
        return GitResult(false, QVariant(),
                         e ? e->message : "Reset failed.");
    }

    emitGitCommand(gitCmd);

    return GitResult(true, QVariant(), "Reset successful.");
}

