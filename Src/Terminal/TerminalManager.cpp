#include "TerminalManager.h"
#include "ShellSession.h"
#include <QSysInfo>
#include <QDir>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>

/**
 * @brief Returns the directory a repository's shell runs in: its working directory, or the
 *        repository itself when it is bare. Empty without a repository.
 */
static QString repositoryDirectory(git_repository *repo)
{
    if (!repo)
        return QString();

    if (const char *workdir = git_repository_workdir(repo))
        return QString::fromUtf8(workdir);

    return QString::fromUtf8(git_repository_path(repo));
}

TerminalManager::TerminalManager(QObject *parent)
    : IGitController(parent)
{
    startShell();
    connect(this, &TerminalManager::currentRepoChanged, this, &TerminalManager::updateWorkingDirectory);
}

TerminalManager::~TerminalManager()
{
    if (m_process && m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(1000);
    }
}

void TerminalManager::startShell()
{
    m_process = new QProcess(this);

#ifdef Q_OS_WIN
    m_process->setProcessChannelMode(QProcess::MergedChannels);
#else
    m_process->setProcessChannelMode(QProcess::SeparateChannels);
#endif

    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &TerminalManager::onReadyReadStandardOutput);
    connect(m_process, &QProcess::readyReadStandardError,
            this, &TerminalManager::onReadyReadStandardError);
    connect(m_process, &QProcess::stateChanged,
            this, &TerminalManager::onProcessStateChanged);

#ifdef Q_OS_WIN
    m_process->start("cmd.exe");
#else
    m_process->start("/usr/bin/script", {"-q", "-c", "/bin/bash --login", "/dev/null"});
#endif

    if (!m_process->waitForStarted(3000)) {
        return;
    }

#ifdef Q_OS_WIN
    QTimer::singleShot(200, this, [this]() {
        m_process->write("chcp 65001\r\n");
        m_process->write("PROMPT ##PROMPT##\r\n");
    });
#else
    m_process->write("export HISTCONTROL=ignorespace:ignoreboth\n");
    QTimer::singleShot(200, this, [this]() {
        m_process->write(" export PS1='##PROMPT##:$?'\n");
        m_process->write(" stty -echo\n");
        m_process->write(" export PAGER=cat\n");
        m_process->write(" export GIT_PAGER=cat\n");
        m_process->write(" export GIT_TERMINAL_PROMPT=0\n");
    });
#endif
}

void TerminalManager::sendCommand(const QString &command)
{
    if (!m_process || m_process->state() != QProcess::Running)
        return;

    m_gitStateUpdateRequired = false;

    if(!command.startsWith("git")) {
        QJsonArray arr;
        QJsonObject obj;
        obj["text"] = "Only git commands are currently supported";
        obj["color"] = "#e6edf3";
        arr.append(obj);

        emit lineReceived(QJsonDocument(arr).toJson(QJsonDocument::Compact));
        return;
    }

    const QStringList updateRequiringCommands = {
        "git commit", "git merge", "git rebase", "git cherry-pick", "git revert",
        "git reset", "git pull", "git fetch", "git push",
        "git branch", "git tag", "git stash",
        "git add", "git rm", "git mv", "git restore",
        "git switch", "git checkout", "git clean", "git apply", "git am"
    };

    for (const QString &cmd : updateRequiringCommands) {
        if (command.trimmed().startsWith(cmd)) {
            m_gitStateUpdateRequired = true;
            break;
        }
    }

    QString cmd = command.trimmed();
    if (cmd.startsWith("git "))
        cmd = "git -c color.ui=always " + cmd.mid(4);

    m_lastCommand = cmd;

#ifdef Q_OS_WIN
    m_process->write((cmd + "\r\n").toUtf8());
#else
    m_process->write((cmd + "\n").toUtf8());
#endif

    emit commandStarted();
}

void TerminalManager::kill()
{
    if (!m_process) return;
    m_process->kill();
    m_process->waitForFinished(1000);
    startShell();
}

void TerminalManager::onReadyReadStandardOutput()
{
    const QString output = QString::fromUtf8(m_process->readAllStandardOutput());
    QString cleaned = output;
    cleaned.remove('\r');
    const QStringList lines = cleaned.split('\n');
    for (const QString &line : lines) {
        const QString trimmed = line.trimmed();
        if (trimmed.isEmpty()) continue;
        if (!m_lastCommand.isEmpty() && trimmed == m_lastCommand.trimmed()) {
ShellSession *TerminalManager::sessionFor(const QString &workingDirectory)
{
    if (ShellSession *session = m_sessions.value(workingDirectory))
        return session;

    auto *session = new ShellSession(workingDirectory, this);
    m_sessions.insert(workingDirectory, session);

    connect(session, &ShellSession::lineReceived, this, [this, workingDirectory](const QString &segmentsJson) {
        emit lineReceived(workingDirectory, segmentsJson);
    });
    connect(session, &ShellSession::commandStarted, this, [this, workingDirectory]() {
        emit commandStarted(workingDirectory);
    });
    connect(session, &ShellSession::commandFinished, this, [this, workingDirectory]() {
        emit commandFinished(workingDirectory);
    });
    connect(session, &ShellSession::gitStateChanged, this, [this, workingDirectory]() {
        emit gitStateChanged(workingDirectory);
    });

    // running and busy describe the current repository's session only
    connect(session, &ShellSession::runningChanged, this, [this, session]() {
        if (session == currentSession())
            emit runningChanged();
    });
    connect(session, &ShellSession::busyChanged, this, [this, session]() {
        if (session == currentSession())
            emit busyChanged();
    });

    connect(session, &ShellSession::closed, this, [this, session, workingDirectory]() {
        if (m_sessions.value(workingDirectory) == session)
            m_sessions.remove(workingDirectory);

        session->deleteLater();
    });

    return session;
}

ShellSession *TerminalManager::currentSession() const
{
    return m_sessions.value(m_workingDirectory);
}

QString TerminalManager::workingDirectory() const
{
    return m_workingDirectory;
}

bool TerminalManager::running() const
{
    return m_running;
}

void TerminalManager::updateWorkingDirectory()
{
    if (!m_process || m_process->state() != QProcess::Running)
        return;

    if (m_currentRepo) {
        const char* workdir = git_repository_workdir(activeRepo());
        if (workdir) {
            QString dir = QString::fromUtf8(workdir);
            m_process->setWorkingDirectory(dir);
            m_workingDirectory = dir;
            emit workingDirectoryChanged();
#ifdef Q_OS_WIN
            m_process->write(("cd /d \"" + dir + "\"\r\n").toUtf8());
#else
            m_process->write((" cd \"" + dir + "\"\n").toUtf8());
#endif
        }
    } else {
        QString home = QDir::homePath();
        m_process->setWorkingDirectory(home);
        m_workingDirectory = home;
        emit workingDirectoryChanged();
#ifdef Q_OS_WIN
        m_process->write(("cd /d \"" + home + "\"\r\n").toUtf8());
#else
        m_process->write((" cd \"" + home + "\"\n").toUtf8());
#endif
    }
}

QString TerminalManager::username() const
{
    return qEnvironmentVariable("USER", qEnvironmentVariable("USERNAME", "user"));
}

QString TerminalManager::hostname() const
{
    return QSysInfo::machineHostName();
}