#pragma once

#include <QObject>
#include "GitResult.h"
#include "IGitController.h"
#include "Config.h"

class GitConfig : public IGitController
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit GitConfig(QObject *parent = nullptr);

    /**
     * \brief Get user name and email from all config levels
     * \return GitResult with QVariantList of Config objects
     * 
     * Returns user.name and user.email from:
     * - System config (git config --system)
     * - Global config (git config --global)
     * - Local config (git config --local) - if repository is open
     * - Worktree config (if applicable)
     */
    Q_INVOKABLE GitResult getAllConfigs();

    /**
     * \brief Get user name and email from a specific config level
     * \param level Config level (0=System, 1=Global, 2=Local, 3=Worktree)
     * \return GitResult with Config object
     */
    Q_INVOKABLE GitResult getConfig(int level);

    /**
     * \brief Set user name and email at a specific config level
     * \param level Config level
     * \param name User name
     * \param email User email
     * \return GitResult
     */
    Q_INVOKABLE GitResult setConfig(int level, const QString &name, const QString &email);

    /**
     * \brief Get user name from a specific config level
     * \param level Config level
     * \return GitResult with QString value
     */
    Q_INVOKABLE GitResult getUserName(int level);

    /**
     * \brief Get user email from a specific config level
     * \param level Config level
     * \return GitResult with QString value
     */
    Q_INVOKABLE GitResult getUserEmail(int level);

    /**
     * \brief Set any configuration key-value pair at a specific config level
     * \param level Config level (0=System, 1=Global, 2=Local, 3=Worktree)
     * \param key Configuration key (e.g., "user.name", "core.editor")
     * \param value Configuration value
     * \return GitResult indicating success or failure
     */
    Q_INVOKABLE GitResult setValue(int level, const QString &key, const QString &value);

    /**
     * \brief Get any configuration value by key from a specific config level
     * \param level Config level (0=System, 1=Global, 2=Local, 3=Worktree)
     * \param key Configuration key (e.g., "user.name", "core.editor")
     * \return GitResult with QString value
     */
    Q_INVOKABLE GitResult getValue(int level, const QString &key);

private:
    Config getConfigAtLevel(git_config *cfg, Config::ConfigLevel level);
    QString getConfigValue(git_config *cfg, const QString &key);
};
