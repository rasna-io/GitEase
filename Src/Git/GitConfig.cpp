#include "GitConfig.h"
#include "GitCommandText.h"
#include "GitUtils.h"
#include <git2.h>
#include <QDebug>

namespace
{
    //! The Config level GitEase shows for a libgit2 config level.
    Config::ConfigLevel configLevelOf(git_config_level_t level)
    {
        switch (level) {
        case GIT_CONFIG_LEVEL_PROGRAMDATA:
        case GIT_CONFIG_LEVEL_SYSTEM:
            return Config::ConfigLevel::System;
        case GIT_CONFIG_LEVEL_XDG:
        case GIT_CONFIG_LEVEL_GLOBAL:
            return Config::ConfigLevel::Global;
        case GIT_CONFIG_LEVEL_WORKTREE:
            return Config::ConfigLevel::Worktree;
        default:
            return Config::ConfigLevel::Local;
        }
    }

    //! Higher for levels that win: a repository's value beats the global one, and so on.
    int specificity(int level)
    {
        switch (static_cast<Config::ConfigLevel>(level)) {
        case Config::ConfigLevel::System:   return 0;
        case Config::ConfigLevel::Global:   return 1;
        case Config::ConfigLevel::Local:    return 2;
        case Config::ConfigLevel::Worktree: return 3;
        default:                            return -1;
        }
    }
}

GitConfig::GitConfig(QObject *parent)
    : IGitController{parent}
{
}

GitResult GitConfig::getAllConfigs()
{
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
    emitGitCommand(GitCommandText::setUserIdentity(name, email, levelFlag));

    return GitResult(true, QVariant(), "Config set successfully");
}

GitResult GitConfig::resolveIdentity()
{
    git_config *cfg = nullptr;
    const int openError = (m_currentRepo && activeRepo())
                              ? git_repository_config_snapshot(&cfg, activeRepo())
                              : git_config_open_default(&cfg);
    if (openError != GIT_OK) {
        const QString reason = GitUtils::getLastError();
        return GitResult(false, QVariant(), reason.isEmpty() ? "Failed to open git config" : reason);
    }

    QVariantMap data;
    int level = -1;       // where the values come from: the more specific level of the two
    int blankLevel = -1;  // a level whose empty value hides any value set below it

    const struct { const char *key; const char *field; } keys[] = {
        { "user.name",  "name"  },
        { "user.email", "email" },
    };

    for (const auto &item : keys) {
        git_config_entry *entry = nullptr;
        if (git_config_get_entry(&entry, cfg, item.key) != GIT_OK || !entry)
            continue;

        const QString value = QString::fromUtf8(entry->value);
        const int entryLevel = static_cast<int>(configLevelOf(entry->level));
        git_config_entry_free(entry);

        data[item.field] = value;
        if (specificity(entryLevel) > specificity(level))
            level = entryLevel;
        if (value.trimmed().isEmpty() && specificity(entryLevel) > specificity(blankLevel))
            blankLevel = entryLevel;
    }
    git_config_free(cfg);

    data["level"] = level;
    data["blankLevel"] = blankLevel;

    const QByteArray name = data.value("name").toString().toUtf8();
    const QByteArray email = data.value("email").toString().toUtf8();
    if (name.trimmed().isEmpty() || email.trimmed().isEmpty())
        return identityMissingResult(QString(), data);

    git_signature *probe = nullptr;
    if (git_signature_new(&probe, name.constData(), email.constData(), 0, 0) != GIT_OK)
        return identityMissingResult(GitUtils::getLastError(), data);
    git_signature_free(probe);

    return GitResult(true, data);
}

GitResult GitConfig::unsetIdentity(int level)
{
    const Config::ConfigLevel configLevel = static_cast<Config::ConfigLevel>(level);

    git_config *root = nullptr;
    git_config *levelCfg = nullptr;
    GitResult opened = openLevelConfig(configLevel, &root, &levelCfg);
    if (!opened.success())
        return opened;

    for (const char *key : { "user.name", "user.email" }) {
        int error = git_config_delete_entry(levelCfg, key);
        if (error != GIT_OK && error != GIT_ENOTFOUND)
            error = git_config_delete_multivar(levelCfg, key, ".*"); // the key is set more than once
        if (error != GIT_OK && error != GIT_ENOTFOUND) {
            const QString reason = GitUtils::getLastError();
            git_config_free(levelCfg);
            git_config_free(root);
            return GitResult(false, QVariant(),
                             reason.isEmpty() ? QString("Failed to remove %1").arg(key) : reason);
        }
    }

    git_config_free(levelCfg);
    git_config_free(root);

    emitGitCommand(GitCommandText::unsetUserIdentity(configLevelFlag(configLevel)));

    return GitResult(true);
}

GitResult GitConfig::openLevelConfig(Config::ConfigLevel level, git_config **root, git_config **levelCfg)
{
    *root = nullptr;
    *levelCfg = nullptr;

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
        return GitResult(false, QVariant(), "Invalid config level");
    }

    const bool repositoryLevel = level == Config::ConfigLevel::Local
                                 || level == Config::ConfigLevel::Worktree;
    if (repositoryLevel && (!m_currentRepo || !activeRepo()))
        return GitResult(false, QVariant(), "No repository open");

    int error = repositoryLevel ? git_repository_config(root, activeRepo())
                                : git_config_open_default(root);
    if (error == GIT_OK)
        error = git_config_open_level(levelCfg, *root, gitLevel);

    if (error != GIT_OK) {
        const QString reason = GitUtils::getLastError();
        git_config_free(*root);
        *root = nullptr;
        return GitResult(false, QVariant(), reason.isEmpty() ? "Failed to open git config" : reason);
    }

    return GitResult(true);
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
