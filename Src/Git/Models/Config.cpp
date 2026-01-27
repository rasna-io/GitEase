#include "Config.h"

Config::Config()
    : m_name("")
    , m_email("")
    , m_level(ConfigLevel::App)
{}

Config::Config(const QString &name, const QString &email, ConfigLevel level)
    : m_name(name)
    , m_email(email)
    , m_level(level)
{}

QString Config::name() const
{
    return m_name;
}

QString Config::email() const
{
    return m_email;
}

Config::ConfigLevel Config::level() const
{
    return m_level;
}

QString Config::levelName() const
{
    switch (m_level) {
    case ConfigLevel::System:
        return "System";
    case ConfigLevel::Global:
        return "Global";
    case ConfigLevel::Local:
        return "Local";
    case ConfigLevel::Worktree:
        return "Worktree";
    case ConfigLevel::App:
        return "Application";
    default:
        return "Unknown";
    }
}
