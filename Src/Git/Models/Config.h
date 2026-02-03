#pragma once

#include <QObject>
#include <QQmlEngine>

class Config
{
    Q_GADGET
    QML_ELEMENT

    Q_PROPERTY(QString name READ name CONSTANT FINAL)
    Q_PROPERTY(QString email READ email CONSTANT FINAL)
    Q_PROPERTY(ConfigLevel level READ level CONSTANT FINAL)
    Q_PROPERTY(QString levelName READ levelName CONSTANT FINAL)

public:
    enum ConfigLevel {
        System = 0,    // System-wide configuration
        Global = 1,    // User-level configuration
        Local = 2,     // Repository-level configuration
        Worktree = 3,  // Worktree-level configuration
        App = 4        // Application-level configuration
    };
    Q_ENUM(ConfigLevel)

    explicit Config();

    Config(const QString &name, const QString &email, ConfigLevel level);

    QString name() const;
    QString email() const;
    ConfigLevel level() const;
    QString levelName() const;

private:
    QString m_name;
    QString m_email;
    ConfigLevel m_level;
};

Q_DECLARE_METATYPE(Config)
