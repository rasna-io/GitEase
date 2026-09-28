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

    QJsonDocument doc = QJsonDocument::fromJson(jsonText.toUtf8());
    if (doc.isObject())
        applyRules(doc.object()["rules"].toObject());

    return GitResult(true);
}

GitResult RuleManager::loadRules()
{
    QString path = rulesFilePath();
    if (path.isEmpty())
        return GitResult(false, QVariant(), "No repository is currently open");

    QFile file(path);
    if (!file.exists()) {
        applyRules(QJsonObject());
        return GitResult(true, QString(""));
    }

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return GitResult(false, QVariant(), "Failed to open rules file for reading: " + path);

    QString content = QString::fromUtf8(file.readAll());
    file.close();

    QJsonDocument doc = QJsonDocument::fromJson(content.toUtf8());
    if (!doc.isObject())
        return GitResult(false, {}, "Invalid rules file.");

    applyRules(doc.object()["rules"].toObject());

    return GitResult(true, content);
}

void RuleManager::applyRules(const QJsonObject &rules)
{
    m_commitMessageValidator.setRules(rules["commitMessage"].toArray());
    m_branchNameValidator.setRules(rules["branchNaming"].toArray());
    m_fileRuleValidator.setRules(rules["fileCode"].toArray());
    m_pushRuleValidator.setRules(rules["pushRules"].toArray());
    m_hookRunner.setRules(rules["customHooks"].toArray());
    m_notificationRules = rules["notification"].toArray();
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

void RuleManager::setCurrentRepoPath(const QString &newCurrentRepoPath)
{
    if(m_currentRepoPath == newCurrentRepoPath) return;
    m_currentRepoPath = newCurrentRepoPath;
    loadRules();
    emit currentRepoChanged();
}