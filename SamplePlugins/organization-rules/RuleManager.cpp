#include "RuleManager.h"
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <QDebug>

RuleManager::RuleManager(QObject *parent)
    : QObject{parent}
{

}

GitResult RuleManager::saveRules(const QString &jsonText)
{
    QString path = rulesFilePath();
    if (path.isEmpty())
        return GitResult(false, QVariant(), "No repository is currently open");

    QDir().mkpath(QFileInfo(path).absolutePath());

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return GitResult(false, QVariant(), "Failed to open rules file for writing: " + path);

    qint64 written = file.write(jsonText.toUtf8());
    file.close();

    if (written < 0)
        return GitResult(false, QVariant(), "Failed to write rules file");

    return GitResult(true);
}

GitResult RuleManager::loadRules()
{
    QString path = rulesFilePath();
    if (path.isEmpty())
        return GitResult(false, QVariant(), "No repository is currently open");

    QFile file(path);
    if (!file.exists())
        return GitResult(true, QString(""));

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return GitResult(false, QVariant(), "Failed to open rules file for reading: " + path);

    QString content = QString::fromUtf8(file.readAll());
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(content.toUtf8());
    if (!doc.isObject())
        return GitResult(false, {}, "Invalid rules file.");

    QJsonObject root = doc.object();
    QJsonObject rules = root["rules"].toObject();
    m_commitMessageValidator.setRules(rules["commitMessage"].toArray());

    return GitResult(true, content);
}

GitResult RuleManager::exportRules(const QUrl &fileUrl, const QString &jsonText)
{
    QString path = fileUrl.toLocalFile();
    if (path.isEmpty())
        return GitResult(false, QVariant(), "Invalid export path");

    QFile file(path);
    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
        return GitResult(false, QVariant(), "Failed to open file for writing: " + path);

    file.write(jsonText.toUtf8());
    file.close();

    return GitResult(true);
}

GitResult RuleManager::importRules(const QUrl &fileUrl)
{
    QString path = fileUrl.toLocalFile();
    if (path.isEmpty())
        return GitResult(false, QVariant(), "Invalid import path");

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return GitResult(false, QVariant(), "Failed to open file for reading: " + path);

    QString content = QString::fromUtf8(file.readAll());
    file.close();

    return GitResult(true, content);
}

QString RuleManager::rulesFilePath()
{
    if (m_currentRepoPath.isEmpty())
        return QString();

    return m_currentRepoPath + "/.gitease/rules.json";
}

CommitMessageValidator RuleManager::commitMessageValidator() const
{
    return m_commitMessageValidator;
}

void RuleManager::setCurrentRepoPath(const QString &newCurrentRepoPath)
{
    if(m_currentRepoPath == newCurrentRepoPath) return;
    m_currentRepoPath = newCurrentRepoPath;
    loadRules();
    emit currentRepoChanged();
}