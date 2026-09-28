#include "RuleSupport.h"

#include <QDir>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>

namespace RuleSupport {

QStringList splitList(const QJsonValue &value)
{
    QStringList items;
    const QStringList parts = value.toString().split(',', Qt::SkipEmptyParts);
    for (const QString &part : parts) {
        const QString trimmed = part.trimmed();
        if (!trimmed.isEmpty())
            items << trimmed;
    }
    return items;
}

bool isRuleEnabled(const QJsonObject &rule)
{
    if (rule.contains("enabled"))
        return rule["enabled"].toBool();
    return rule["isActive"].toBool(true);
}

bool isBlocking(const QJsonObject &rule)
{
    return rule["severity"].toVariant().toInt() == 0;
}

int intValue(const QJsonObject &rule, const QString &key, int defaultValue)
{
    const QJsonValue value = rule[key];
    if (value.isUndefined() || value.isNull())
        return defaultValue;

    bool ok = false;
    const int result = value.toVariant().toInt(&ok);
    return ok ? result : defaultValue;
}

bool matchesAnyGlob(const QString &text, const QStringList &patterns)
{
    for (const QString &pattern : patterns) {
        const QRegularExpression glob(QRegularExpression::wildcardToRegularExpression(pattern));
        if (glob.match(text).hasMatch())
            return true;
    }
    return false;
}

RuleViolation violation(const QJsonObject &rule, const QString &message)
{
    RuleViolation v;
    v.ruleName = rule["ruleName"].toString();
    v.message = message;
    v.blocking = isBlocking(rule);
    return v;
}

QString resolveRepoPath(const QString &repoPath, const QString &path)
{
    if (path.isEmpty() || QFileInfo(path).isAbsolute())
        return path;
    return QDir(repoPath).absoluteFilePath(path);
}

} // namespace RuleSupport

namespace GitCli {

QString gitExecutable()
{
    static const QString cached = [] {
        QString path = QStandardPaths::findExecutable("git");
#ifdef Q_OS_WIN
        if (path.isEmpty()) {
            const QStringList candidates = {
                "C:/Program Files/Git/cmd/git.exe",
                "C:/Program Files (x86)/Git/cmd/git.exe"
            };
            for (const QString &candidate : candidates) {
                if (QFileInfo::exists(candidate)) {
                    path = candidate;
                    break;
                }
            }
        }
#endif
        return path;
    }();
    return cached;
}

QString shellExecutable()
{
    static const QString cached = [] {
#ifdef Q_OS_WIN
        // git.exe lives in <root>/cmd, <root>/bin or <root>/mingw64/bin; sh.exe in <root>/bin.
        const QString git = gitExecutable();
        if (!git.isEmpty()) {
            QDir dir = QFileInfo(git).absoluteDir();
            for (int level = 0; level < 3; ++level) {
                const QString candidate = dir.absoluteFilePath("bin/sh.exe");
                if (QFileInfo::exists(candidate))
                    return candidate;
                if (!dir.cdUp())
                    break;
            }
        }
#endif
        QString sh = QStandardPaths::findExecutable("sh");
        if (sh.isEmpty())
            sh = QStandardPaths::findExecutable("bash");
        return sh;
    }();
    return cached;
}

int run(const QString &repoPath,
        const QStringList &args,
        QByteArray *output,
        const QByteArray &input,
        int timeoutMs)
{
    const QString git = gitExecutable();
    if (git.isEmpty())
        return -1;

    QProcess process;
    process.setWorkingDirectory(repoPath);
    process.setProcessChannelMode(QProcess::SeparateChannels);
    process.start(git, args);
    if (!process.waitForStarted(5000))
        return -1;

    if (!input.isEmpty())
        process.write(input);
    process.closeWriteChannel();

    if (!process.waitForFinished(timeoutMs)) {
        process.kill();
        process.waitForFinished(1000);
        return -1;
    }

    if (output)
        *output = process.readAllStandardOutput();

    return process.exitStatus() == QProcess::NormalExit ? process.exitCode() : -1;
}

} // namespace GitCli
