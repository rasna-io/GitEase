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
    connect(this, &TerminalManager::currentRepoChanged, this, &TerminalManager::updateWorkingDirectory);
}

TerminalManager::~TerminalManager()
{
    qDeleteAll(m_sessions);
}

void TerminalManager::sendCommand(const QString &command)
{
    if(!command.startsWith("git")) {
        QJsonArray arr;
        QJsonObject obj;
        obj["text"] = "Only git commands are currently supported";
        obj["color"] = "#e6edf3";
        arr.append(obj);

        emit lineReceived(m_workingDirectory, QJsonDocument(arr).toJson(QJsonDocument::Compact));
        return;
    }

    sessionFor(m_workingDirectory)->sendCommand(command);
}

void TerminalManager::kill()
{
    if (ShellSession *session = currentSession())
        session->kill();
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