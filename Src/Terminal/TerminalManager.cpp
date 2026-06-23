#include "TerminalManager.h"
#include <QRegularExpression>
#include <QSysInfo>
#include <QDir>
#include <QJsonArray>
#include <QJsonObject>
#include <QJsonDocument>

static QVariantList parseAnsi(const QString &line)
{
    QVariantList segments;
    static QRegularExpression ansiRegex("\x1b\\[([0-9;]*)m");

    QString currentColor;
    bool currentBold = false;
    int lastIndex = 0;

    QRegularExpressionMatchIterator it = ansiRegex.globalMatch(line);

    while (it.hasNext()) {
        QRegularExpressionMatch match = it.next();

        QString before = line.mid(lastIndex, match.capturedStart() - lastIndex);
        if (!before.isEmpty()) {
            QVariantMap seg;
            seg["text"]  = before;
            seg["color"] = currentColor;
            seg["bold"]  = currentBold;
            segments.append(seg);
        }

        const QStringList codes = match.captured(1).split(';');
        for (const QString &c : codes) {
            int n = c.toInt();
            switch (n) {
            case 0:  currentColor = ""; currentBold = false; break;
            case 1:  currentBold  = true; break;
            case 31: currentColor = "#f44747"; break;
            case 32: currentColor = "#89d185"; break;
            case 33: currentColor = "#dcdcaa"; break;
            case 34: currentColor = "#569cd6"; break;
            case 35: currentColor = "#c586c0"; break;
            case 36: currentColor = "#4ec9b0"; break;
            case 37: currentColor = "#d4d4d4"; break;
            }
        }

        lastIndex = match.capturedEnd();
    }

    QString remaining = line.mid(lastIndex);
    if (!remaining.isEmpty()) {
        QVariantMap seg;
        seg["text"]  = remaining;
        seg["color"] = currentColor;
        seg["bold"]  = currentBold;
        segments.append(seg);
    }

    if (segments.isEmpty()) {
        QVariantMap seg;
        seg["text"]  = line;
        seg["color"] = "";
        seg["bold"]  = false;
        segments.append(seg);
    }

    return segments;
}

static QString segmentsToJson(const QVariantList &segments)
{
    QJsonArray arr;
    for (const QVariant &v : segments)
        arr.append(QJsonObject::fromVariantMap(v.toMap()));
    return QString::fromUtf8(QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

static QString stripAnsi(const QString &text)
{
    QString result = text;
    static QRegularExpression ansiRegex("\x1b\\[[0-9;]*[A-Za-z]");
    result.remove(ansiRegex);
    return result;
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
        emit outputReceived("Failed to start shell.");
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

    emit outputReceived("Shell started.");
}

void TerminalManager::sendCommand(const QString &command)
{
    if (!m_process || m_process->state() != QProcess::Running)
        return;


    const QStringList updateRequiringCommands = {
        "git commit", "git merge", "git rebase", "git cherry-pick", "git revert",
        "git reset", "git pull", "git fetch", "git push",
        "git branch", "git tag", "git stash",
        "git add", "git rm", "git mv", "git restore",
        "git switch", "git checkout", "git clean", "git apply", "git am"
    };

    m_gitStateUpdateRequired = false;
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
    emit outputReceived("Shell restarted.");
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
            m_lastCommand.clear();
            continue;
        }
        if (trimmed.startsWith("cd ")) continue;
        if (trimmed.startsWith("##PROMPT##:")) {
            // Linux — has exit code
            int exitCode = trimmed.mid(11).trimmed().toInt();
            if (exitCode == 0 && m_gitStateUpdateRequired) {
                emit gitStateChanged();
            }
            m_gitStateUpdateRequired = false;
            emit commandFinished();
            continue;
        }

        if (trimmed == "##PROMPT##") {
            // Windows — no exit code available
            if (m_gitStateUpdateRequired) {
                emit gitStateChanged();
            }
            m_gitStateUpdateRequired = false;
            emit commandFinished();
            continue;
        }
        if (trimmed.startsWith("export ")) continue;
        if (trimmed.startsWith("stty ")) continue;
        if (trimmed.startsWith("Script started")) continue;
        if (trimmed.startsWith("Script done")) continue;

        emit lineReceived(segmentsToJson(parseAnsi(line)));
    }
}

void TerminalManager::onReadyReadStandardError()
{
    const QString err = QString::fromUtf8(m_process->readAllStandardError());
    QString cleaned = err;
    cleaned.remove('\r');

    const QStringList lines = cleaned.split('\n');
    for (const QString &line : lines) {
        if (!line.trimmed().isEmpty())
            emit lineReceived(segmentsToJson(parseAnsi(line)));
    }
}

void TerminalManager::onProcessStateChanged(QProcess::ProcessState state)
{
    m_running = (state == QProcess::Running);
    emit runningChanged();

    if (state == QProcess::NotRunning)
        emit outputReceived("Shell exited.");
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
        const char* workdir = git_repository_workdir(m_currentRepo->repo);
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