#pragma once

#include <QObject>

#include "GitResult.h"
#include "IGitController.h"

class GitReset : public IGitController
{
    Q_OBJECT
    QML_ELEMENT
public:
    GitReset(QObject *parent = nullptr);

    /**
     * @brief Git reset HEAD types.
     *
     * - Soft: keeps all changes staged
     * - Mixed: unstages changes but keeps working directory intact
     * - Hard: discards all local changes
     */
    enum ResetMode {
        Soft,
        Mixed,
        Hard
    };
    Q_ENUM(ResetMode)

    /**
     * @brief Resets HEAD to the specified commit.
     * @param commit The target commit hash or reference (e.g. HEAD~1, branch name, or SHA).
     * @param mode The reset mode controlling how changes are applied.
     * @return GitResult
     */
    Q_INVOKABLE GitResult resetHead(const QString &commit, ResetMode mode);
};

