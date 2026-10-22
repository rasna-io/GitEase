#include "ShellSession.h"
#include <QRegularExpression>
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

ShellSession::ShellSession(const QString &workingDirectory, QObject *parent)
    : QObject(parent)
    , m_process(new QProcess(this))
    , m_workingDirectory(workingDirectory)
{
    m_process->setWorkingDirectory(workingDirectory);

#ifdef Q_OS_WIN
    m_process->setProcessChannelMode(QProcess::MergedChannels);
#else
    m_process->setProcessChannelMode(QProcess::SeparateChannels);
#endif

    connect(m_process, &QProcess::readyReadStandardOutput,
            this, &ShellSession::onReadyReadStandardOutput);
    connect(m_process, &QProcess::readyReadStandardError,
            this, &ShellSession::onReadyReadStandardError);
    connect(m_process, &QProcess::stateChanged,
            this, &ShellSession::onProcessStateChanged);
    connect(m_process, &QProcess::errorOccurred,
            this, &ShellSession::onProcessErrorOccurred);
}

ShellSession::~ShellSession()
{
    disconnect(m_process, nullptr, this, nullptr);

    if (m_process->state() != QProcess::NotRunning) {
        m_process->kill();
        m_process->waitForFinished(1000);
    }
}

void ShellSession::start()
{
    m_ready = false;
    m_lastCommand.clear();

#ifdef Q_OS_WIN
    m_process->start("cmd.exe");
#else
    m_process->start("/usr/bin/script", {"-q", "-c", "/bin/bash --login", "/dev/null"});
#endif

    if (m_process->state() == QProcess::NotRunning)
        return;

#ifdef Q_OS_WIN
    m_process->write("chcp 65001\r\n");
    m_process->write("PROMPT ##PROMPT##$_\r\n");
#else
    m_process->write("export HISTCONTROL=ignorespace:ignoreboth\n");
    m_process->write(" stty -echo\n");
    m_process->write(" export PAGER=cat\n");
    m_process->write(" export GIT_PAGER=cat\n");
    m_process->write(" export GIT_TERMINAL_PROMPT=0\n");
    m_process->write(" unset PROMPT_COMMAND\n");
    m_process->write(" export PS1='##PROMPT##:$?\\n'\n");
#endif
}

void ShellSession::sendCommand(const QString &command)
{
    if (m_busy)
        return;

    if (m_process->state() == QProcess::NotRunning) {
        start();

        if (m_process->state() == QProcess::NotRunning)
            return;
    }

    m_gitStateUpdateRequired = false;

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

    setBusy(true);
    emit commandStarted();
}

void ShellSession::kill()
{
    if (m_process->state() == QProcess::NotRunning)
        return;

    m_process->kill();
    m_process->waitForFinished(1000);
}

void ShellSession::close()
{
    m_closing = true;

    // finishCommand() comes back here once the command completed
    if (m_busy)
        return;

    kill();
    emit closed();
}

void ShellSession::handleOutput(const QString &output)
{
    static QRegularExpression promptRegex("##PROMPT##(?::(\\d+))?\\s*$");

    QString cleaned = output;
    cleaned.remove('\r');
    const QStringList lines = cleaned.split('\n');
    for (const QString &line : lines) {
        const QString trimmed = line.trimmed();
        if (trimmed.isEmpty()) continue;
        if (!m_lastCommand.isEmpty() && trimmed == m_lastCommand.trimmed()) {
            // Windows — cmd.exe echoes the command it reads
            m_lastCommand.clear();
            continue;
        }

        const QRegularExpressionMatch prompt = promptRegex.match(line);
        if (prompt.hasMatch()) {
            const QString tail = line.left(prompt.capturedStart());
            if (m_ready && !tail.trimmed().isEmpty())
                emit lineReceived(segmentsToJson(parseAnsi(tail)));

            handlePrompt(prompt.captured(1).toInt());
            continue;
        }

        if (!m_ready) continue;

        emit lineReceived(segmentsToJson(parseAnsi(line)));
    }
}

void ShellSession::handlePrompt(int exitCode)
{
    if (!m_ready) {
        m_ready = true;
        return;
    }

    finishCommand(exitCode == 0);
}

void ShellSession::finishCommand(bool succeeded)
{
    if (!m_busy)
        return;

    if (succeeded && m_gitStateUpdateRequired)
        emit gitStateChanged();

    m_gitStateUpdateRequired = false;
    setBusy(false);
    emit commandFinished();

    if (m_closing)
        QMetaObject::invokeMethod(this, &ShellSession::close, Qt::QueuedConnection);
}

void ShellSession::setBusy(bool busy)
{
    if (m_busy == busy)
        return;

    m_busy = busy;
    emit busyChanged();
}

void ShellSession::onReadyReadStandardOutput()
{
    handleOutput(QString::fromUtf8(m_process->readAllStandardOutput()));
}

void ShellSession::onReadyReadStandardError()
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

void ShellSession::onProcessStateChanged(QProcess::ProcessState state)
{
    emit runningChanged();

    if (state != QProcess::NotRunning)
        return;

    m_ready = false;
    finishCommand(true);
}

void ShellSession::onProcessErrorOccurred(QProcess::ProcessError error)
{
    if (error != QProcess::FailedToStart)
        return;

    emit lineReceived(segmentsToJson(parseAnsi("Failed to start the shell: " + m_process->errorString())));
}

QString ShellSession::workingDirectory() const
{
    return m_workingDirectory;
}

bool ShellSession::running() const
{
    return m_process->state() == QProcess::Running;
}

bool ShellSession::busy() const
{
    return m_busy;
}
