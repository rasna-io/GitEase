#include "HookRunner.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonObject>
#include <QProcess>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QUuid>

#ifdef Q_OS_WIN
#include <qt_windows.h>
#endif

using namespace RuleSupport;

namespace {

enum OnFailure { Block = 0, Warn = 1, Ignore = 2 };

struct Command
{
    QString     program;
    QStringList arguments;
    QString     error;
};

QString writeTempFile(const QString &prefix, const QString &suffix, const QByteArray &content)
{
    const QString path = QDir(QDir::tempPath()).absoluteFilePath(
        QString("%1-%2%3").arg(prefix, QUuid::createUuid().toString(QUuid::Id128), suffix));
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly))
        return {};
    file.write(content);
    return path;
}

Command commandForScript(const QString &scriptPath)
{
    const QString suffix = QFileInfo(scriptPath).suffix().toLower();

    if (suffix == "ps1") {
        const QString shell = QStandardPaths::findExecutable("pwsh").isEmpty() ? "powershell" : "pwsh";
        return { shell, { "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", scriptPath }, {} };
    }
    if (suffix == "bat" || suffix == "cmd")
        return { "cmd.exe", { "/c", QDir::toNativeSeparators(scriptPath) }, {} };
    if (suffix == "exe")
        return { scriptPath, {}, {} };

    const QString sh = GitCli::shellExecutable();
    if (sh.isEmpty())
        return { {}, {}, "No POSIX shell found to run the hook (install Git for Windows)" };
    return { sh, { scriptPath }, {} };
}

QStringList hookArguments(const HookRunner::Invocation &invocation, const QString &messageFile)
{
    if (invocation.trigger == "commit-msg")
        return { messageFile };

    if (invocation.trigger == "pre-push") {
        QByteArray url;
        GitCli::run(invocation.repoPath, { "remote", "get-url", invocation.remoteName }, &url);
        return { invocation.remoteName, QString::fromUtf8(url).trimmed() };
    }

    if (invocation.trigger == "post-merge")
        return { "0" };

    if (invocation.trigger == "post-checkout") {
        QByteArray head;
        GitCli::run(invocation.repoPath, { "rev-parse", "HEAD" }, &head);
        const QString sha = QString::fromUtf8(head).trimmed();
        return { sha, sha, "1" };
    }

    return {};
}

//! Git feeds pre-push "<local ref> <local sha> <remote ref> <remote sha>" on stdin.
QByteArray prePushInput(const HookRunner::Invocation &invocation)
{
    const QString ref = "refs/heads/" + invocation.branchName;
    QByteArray local;
    QByteArray remote;
    GitCli::run(invocation.repoPath, { "rev-parse", ref }, &local);
    if (GitCli::run(invocation.repoPath,
                    { "rev-parse", "refs/remotes/" + invocation.remoteName + "/" + invocation.branchName },
                    &remote) != 0) {
        remote = QByteArray(40, '0');
    }
    return QString("%1 %2 %1 %3\n")
        .arg(ref, QString::fromUtf8(local).trimmed(), QString::fromUtf8(remote).trimmed())
        .toUtf8();
}

QProcessEnvironment hookEnvironment(const QJsonObject &rule, const HookRunner::Invocation &invocation)
{
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("GITEASE_HOOK", invocation.trigger);
    env.insert("GITEASE_REPO", invocation.repoPath);
    if (!invocation.branchName.isEmpty())
        env.insert("GITEASE_BRANCH", invocation.branchName);
    if (!invocation.remoteName.isEmpty())
        env.insert("GITEASE_REMOTE", invocation.remoteName);

    for (const QString &pair : splitList(rule["envVars"])) {
        const int eq = pair.indexOf('=');
        const QString key = (eq < 0 ? pair : pair.left(eq)).trimmed();
        if (!key.isEmpty())
            env.insert(key, eq < 0 ? QString() : pair.mid(eq + 1));
    }
    return env;
}

QString lastOutputLines(const QByteArray &output)
{
    QStringList lines = QString::fromUtf8(output).split('\n', Qt::SkipEmptyParts);
    for (QString &line : lines)
        line = line.trimmed();
    lines.removeAll(QString());
    while (lines.size() > 3)
        lines.removeFirst();
    QString text = lines.join(" | ");
    if (text.length() > 300)
        text = text.left(300) + "...";
    return text;
}

#ifdef Q_OS_WIN
void hideConsoleWindow(QProcess &process)
{
    process.setCreateProcessArgumentsModifier([](QProcess::CreateProcessArguments *args) {
        args->flags &= ~CREATE_NEW_CONSOLE;
        args->flags |= CREATE_NO_WINDOW;
    });
}
#endif

} // namespace

RuleViolations HookRunner::run(const Invocation &invocation) const
{
    RuleViolations violations;
    if (invocation.repoPath.isEmpty())
        return violations;

    const bool postAction = invocation.trigger.startsWith("post-");

    for (const QJsonValue &value : m_rules) {
        const QJsonObject rule = value.toObject();
        if (!isRuleEnabled(rule) || rule["trigger"].toString("pre-commit") != invocation.trigger)
            continue;

        const int onFailure = intValue(rule, "onFailure", Block);
        auto fail = [&](const QString &text) {
            if (onFailure == Ignore)
                return;
            RuleViolation v = violation(rule, text);
            v.blocking = onFailure == Block && !postAction;
            violations << v;
        };

        const bool background = rule["runInBackground"].toBool();
        const QString scriptPath = resolveRepoPath(invocation.repoPath, rule["scriptPath"].toString().trimmed());
        const QString inlineScript = rule["inlineScript"].toString();

        QString script;
        bool temporaryScript = false;
        if (!scriptPath.isEmpty()) {
            if (!QFileInfo::exists(scriptPath)) {
                fail(QString("Hook script not found: %1").arg(scriptPath));
                continue;
            }
            script = scriptPath;
        } else if (!inlineScript.trimmed().isEmpty()) {
            QString content = inlineScript;
            content.replace("\r\n", "\n");
            script = writeTempFile("gitease-hook", ".sh", content.toUtf8());
            temporaryScript = true;
            if (script.isEmpty()) {
                fail("Could not write the inline hook script to a temporary file");
                continue;
            }
        } else {
            continue;
        }

        QString messageFile;
        if (invocation.trigger == "commit-msg")
            messageFile = writeTempFile("gitease-commit-msg", ".txt", invocation.commitMessage.toUtf8());

        Command command = commandForScript(script);
        if (!command.error.isEmpty()) {
            if (temporaryScript)
                QFile::remove(script);
            if (!messageFile.isEmpty())
                QFile::remove(messageFile);
            fail(command.error);
            continue;
        }
        command.arguments << hookArguments(invocation, messageFile);

        QProcess process;
        process.setProgram(command.program);
        process.setArguments(command.arguments);
        process.setWorkingDirectory(invocation.repoPath);
        process.setProcessEnvironment(hookEnvironment(rule, invocation));
        process.setProcessChannelMode(QProcess::MergedChannels);
#ifdef Q_OS_WIN
        hideConsoleWindow(process);
#endif

        // Background hooks never block the action; their temp files are left for the OS to clean.
        if (background) {
            if (!process.startDetached())
                fail(QString("Could not start hook: %1").arg(command.program));
            continue;
        }

        const int timeoutSeconds = intValue(rule, "timeoutSeconds", 30);
        process.start();
        QString failure;
        if (!process.waitForStarted(5000)) {
            failure = QString("Could not start hook: %1").arg(command.program);
        } else {
            if (invocation.trigger == "pre-push")
                process.write(prePushInput(invocation));
            process.closeWriteChannel();

            if (!process.waitForFinished(qMax(1, timeoutSeconds) * 1000)) {
                process.kill();
                process.waitForFinished(2000);
                failure = QString("Hook timed out after %1 s").arg(timeoutSeconds);
            } else if (process.exitStatus() != QProcess::NormalExit || process.exitCode() != 0) {
                const QString output = lastOutputLines(process.readAll());
                failure = QString("Hook failed (exit code %1)").arg(process.exitCode());
                if (!output.isEmpty())
                    failure += ": " + output;
            }
        }

        if (temporaryScript)
            QFile::remove(script);
        if (!messageFile.isEmpty())
            QFile::remove(messageFile);

        if (!failure.isEmpty())
            fail(failure);
    }

    return violations;
}

void HookRunner::setRules(const QJsonArray &newRules)
{
    m_rules = newRules;
}
