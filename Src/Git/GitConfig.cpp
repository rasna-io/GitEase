#include "GitConfig.h"
#include <git2.h>
#include <QDebug>

GitConfig::GitConfig(QObject *parent)
    : IGitController{parent}
{
}

GitResult GitConfig::getAllConfigs()
{
    // Check if the repository is open
    if (!m_currentRepo || !activeRepo()) {
        return GitResult(false, QVariant(), "Repository not found.");
    }

    QVariantList configList;
    git_config *cfg = nullptr;
    int error = 0;

    // Open default config
    error = git_config_open_default(&cfg);
    if (error != 0) {
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open git config");
    }

    // Get System config
    Config systemConfig = getConfigAtLevel(cfg, Config::ConfigLevel::System);
    if (!systemConfig.name().isEmpty() || !systemConfig.email().isEmpty()) {
        configList.append(QVariant::fromValue(systemConfig));
    }

    // Get Global config
    Config globalConfig = getConfigAtLevel(cfg, Config::ConfigLevel::Global);
    if (!globalConfig.name().isEmpty() || !globalConfig.email().isEmpty()) {
        configList.append(QVariant::fromValue(globalConfig));
    }

    // Get Local config (if repository is open)
    if (m_currentRepo && activeRepo()) {
        git_config *repoConfig = nullptr;
        error = git_repository_config(&repoConfig, activeRepo());
        if (error == 0) {
            Config localConfig = getConfigAtLevel(repoConfig, Config::ConfigLevel::Local);
            if (!localConfig.name().isEmpty() || !localConfig.email().isEmpty()) {
                configList.append(QVariant::fromValue(localConfig));
            }
            git_config_free(repoConfig);
        }
    }

    git_config_free(cfg);

    emitGitCommand("git config --list --show-origin");

    return GitResult(true, configList);
}

GitResult GitConfig::getConfig(int level)
{
    git_config *cfg = nullptr;
    int error = 0;

    Config::ConfigLevel configLevel = static_cast<Config::ConfigLevel>(level);

    // For local/worktree, need repository
    if ((configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) &&
        (!m_currentRepo || !activeRepo())) {
        return GitResult(false, QVariant(), "No repository open");
    }

    if (configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) {
        error = git_repository_config(&cfg, activeRepo());
    } else {
        error = git_config_open_default(&cfg);
    }

    if (error != 0) {
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open git config");
    }

    Config config = getConfigAtLevel(cfg, configLevel);
    git_config_free(cfg);

    const QString levelFlag = configLevelFlag(configLevel);
    emitGitCommand(levelFlag.isEmpty()
                       ? "git config user.name && git config user.email"
                       : QString("git config %1 user.name && git config %1 user.email").arg(levelFlag));

    return GitResult(true, QVariant::fromValue(config));
}

GitResult GitConfig::setConfig(int level, const QString &name, const QString &email)
{
    git_config *cfg = nullptr;
    int error = 0;

    Config::ConfigLevel configLevel = static_cast<Config::ConfigLevel>(level);

    // For local/worktree, need repository
    if ((configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) &&
        (!m_currentRepo || !activeRepo())) {
        return GitResult(false, QVariant(), "No repository open");
    }

    if (configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) {
        error = git_repository_config(&cfg, activeRepo());
    } else {
        error = git_config_open_default(&cfg);
    }

    if (error != 0) {
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open git config");
    }

    // Get the config snapshot for the specific level
    git_config *levelCfg = nullptr;
    git_config_level_t gitLevel;

    switch (configLevel) {
    case Config::ConfigLevel::System:
        gitLevel = GIT_CONFIG_LEVEL_SYSTEM;
        break;
    case Config::ConfigLevel::Global:
        gitLevel = GIT_CONFIG_LEVEL_GLOBAL;
        break;
    case Config::ConfigLevel::Local:
        gitLevel = GIT_CONFIG_LEVEL_LOCAL;
        break;
    case Config::ConfigLevel::Worktree:
        gitLevel = GIT_CONFIG_LEVEL_WORKTREE;
        break;
    default:
        git_config_free(cfg);
        return GitResult(false, QVariant(), "Invalid config level");
    }

    error = git_config_open_level(&levelCfg, cfg, gitLevel);
    if (error != 0) {
        git_config_free(cfg);
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open config level");
    }


    error = git_config_set_string(levelCfg, "user.name", name.toUtf8().constData());
    if (error != 0) {
        git_config_free(levelCfg);
        git_config_free(cfg);
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to set user.name");
    }

    error = git_config_set_string(levelCfg, "user.email", email.toUtf8().constData());
    if (error != 0) {
        git_config_free(levelCfg);
        git_config_free(cfg);
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to set user.email");
    }

    git_config_free(levelCfg);
    git_config_free(cfg);

    const QString levelFlag = configLevelFlag(configLevel);
    emitGitCommand(levelFlag.isEmpty()
                       ? QString("git config user.name %1 && git config user.email %2")
                             .arg(quoteCommandArg(name), quoteCommandArg(email))
                       : QString("git config %1 user.name %2 && git config %1 user.email %3")
                             .arg(levelFlag, quoteCommandArg(name), quoteCommandArg(email)));

    return GitResult(true, QVariant(), "Config set successfully");
}

GitResult GitConfig::getUserName(int level)
{
    return getValue(level, "user.name");
}

GitResult GitConfig::getUserEmail(int level)
{
    return getValue(level, "user.email");
}

Config GitConfig::getConfigAtLevel(git_config *cfg, Config::ConfigLevel level)
{
    git_config_level_t gitLevel;

    switch (level) {
    case Config::ConfigLevel::System:
        gitLevel = GIT_CONFIG_LEVEL_SYSTEM;
        break;
    case Config::ConfigLevel::Global:
        gitLevel = GIT_CONFIG_LEVEL_GLOBAL;
        break;
    case Config::ConfigLevel::Local:
        gitLevel = GIT_CONFIG_LEVEL_LOCAL;
        break;
    case Config::ConfigLevel::Worktree:
        gitLevel = GIT_CONFIG_LEVEL_WORKTREE;
        break;
    default:
        return Config("", "", level);
    }

    git_config *levelCfg = nullptr;
    int error = git_config_open_level(&levelCfg, cfg, gitLevel);
    if (error != 0) {
        return Config("", "", level);
    }

    QString name = getConfigValue(levelCfg, "user.name");
    QString email = getConfigValue(levelCfg, "user.email");

    git_config_free(levelCfg);

    return Config(name, email, level);
}

QString GitConfig::getConfigValue(git_config *cfg, const QString &key)
{
    git_config_entry *entry = nullptr;
    int error = git_config_get_entry(&entry, cfg, key.toUtf8().constData());
    
    if (error != 0 || !entry) {
        return QString();
    }

    QString value = QString::fromUtf8(entry->value);
    git_config_entry_free(entry);
    
    return value;
}

GitResult GitConfig::setValue(int level, const QString &key, const QString &value)
{
    git_config *cfg = nullptr;
    int error = 0;

    Config::ConfigLevel configLevel = static_cast<Config::ConfigLevel>(level);

    // For local/worktree, need repository
    if ((configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) &&
        (!m_currentRepo || !activeRepo())) {
        return GitResult(false, QVariant(), "No repository open");
    }

    if (configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) {
        error = git_repository_config(&cfg, activeRepo());
    } else {
        error = git_config_open_default(&cfg);
    }

    if (error != 0) {
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open git config");
    }

    // Get the config snapshot for the specific level
    git_config *levelCfg = nullptr;
    git_config_level_t gitLevel;

    switch (configLevel) {
    case Config::ConfigLevel::System:
        gitLevel = GIT_CONFIG_LEVEL_SYSTEM;
        break;
    case Config::ConfigLevel::Global:
        gitLevel = GIT_CONFIG_LEVEL_GLOBAL;
        break;
    case Config::ConfigLevel::Local:
        gitLevel = GIT_CONFIG_LEVEL_LOCAL;
        break;
    case Config::ConfigLevel::Worktree:
        gitLevel = GIT_CONFIG_LEVEL_WORKTREE;
        break;
    default:
        git_config_free(cfg);
        return GitResult(false, QVariant(), "Invalid config level");
    }

    error = git_config_open_level(&levelCfg, cfg, gitLevel);
    if (error != 0) {
        git_config_free(cfg);
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open config level");
    }

    error = git_config_set_string(levelCfg, key.toUtf8().constData(), value.toUtf8().constData());
    if (error != 0) {
        git_config_free(levelCfg);
        git_config_free(cfg);
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? QString("Failed to set %1").arg(key) : "Failed to set config value");
    }

    git_config_free(levelCfg);
    git_config_free(cfg);

    const QString levelFlag = configLevelFlag(configLevel);
    emitGitCommand(levelFlag.isEmpty()
                       ? QString("git config %1 %2").arg(quoteCommandArg(key), quoteCommandArg(value))
                       : QString("git config %1 %2 %3")
                             .arg(levelFlag, quoteCommandArg(key), quoteCommandArg(value)));

    return GitResult(true, QVariant(), QString("Successfully set %1 to %2").arg(key, value));
}

GitResult GitConfig::getValue(int level, const QString &key)
{
    git_config *cfg = nullptr;
    int error = 0;

    Config::ConfigLevel configLevel = static_cast<Config::ConfigLevel>(level);

    // For local/worktree, need repository
    if ((configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) &&
        (!m_currentRepo || !activeRepo())) {
        return GitResult(false, QVariant(), "No repository open");
    }

    if (configLevel == Config::ConfigLevel::Local || configLevel == Config::ConfigLevel::Worktree) {
        error = git_repository_config(&cfg, activeRepo());
    } else {
        error = git_config_open_default(&cfg);
    }

    if (error != 0) {
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open git config");
    }

    // Get the config snapshot for the specific level
    git_config *levelCfg = nullptr;
    git_config_level_t gitLevel;

    switch (configLevel) {
    case Config::ConfigLevel::System:
        gitLevel = GIT_CONFIG_LEVEL_SYSTEM;
        break;
    case Config::ConfigLevel::Global:
        gitLevel = GIT_CONFIG_LEVEL_GLOBAL;
        break;
    case Config::ConfigLevel::Local:
        gitLevel = GIT_CONFIG_LEVEL_LOCAL;
        break;
    case Config::ConfigLevel::Worktree:
        gitLevel = GIT_CONFIG_LEVEL_WORKTREE;
        break;
    default:
        git_config_free(cfg);
        return GitResult(false, QVariant(), "Invalid config level");
    }

    error = git_config_open_level(&levelCfg, cfg, gitLevel);
    if (error != 0) {
        git_config_free(cfg);
        const git_error *err = git_error_last();
        return GitResult(false, QVariant(), err ? err->message : "Failed to open config level");
    }

    QString value = getConfigValue(levelCfg, key);
    
    git_config_free(levelCfg);
    git_config_free(cfg);

    if (value.isEmpty()) {
        return GitResult(false, QVariant(), QString("Config key '%1' not found at specified level").arg(key));
    }

    const QString levelFlag = configLevelFlag(configLevel);
    emitGitCommand(levelFlag.isEmpty()
                       ? QString("git config --get %1").arg(quoteCommandArg(key))
                       : QString("git config %1 --get %2").arg(levelFlag, quoteCommandArg(key)));

    return GitResult(true, value, QString("Successfully retrieved %1").arg(key));
}

QString GitConfig::configLevelFlag(Config::ConfigLevel level)
{
    switch (level)
    {
        case Config::ConfigLevel::System:
            return "--system";
        case Config::ConfigLevel::Global:
            return "--global";
        case Config::ConfigLevel::Local:
            return "--local";
        case Config::ConfigLevel::Worktree:
            return "--worktree";
        default:
            return "";
    }
}
