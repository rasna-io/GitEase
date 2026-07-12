#include "RuleManager.h"
#include "GitResult.h"
#include <QFile>
#include <QDir>
#include <QFileInfo>
#include <git2/repository.h>

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

    return GitResult(true, content);
}

QString RuleManager::rulesFilePath()
{
    if (!m_currentRepo)
        return QString();

    const char* workdir = git_repository_workdir(m_currentRepo->repo);
    if (!workdir)
        return QString();

    QString dir = QString::fromUtf8(workdir);

    return dir + "/.gitease/rules.json";
}

Repository *RuleManager::currentRepo() const
{
    return m_currentRepo;
}

void RuleManager::setCurrentRepo(Repository *newCurrentRepo)
{
    if (m_currentRepo == newCurrentRepo)
        return;

    qDebug() << "changegeggegeggege";
    m_currentRepo = newCurrentRepo;
    emit currentRepoChanged();
}
