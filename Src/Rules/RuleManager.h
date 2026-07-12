#pragma once

#include <QObject>
#include <QQmlEngine>
#include "Repository.h"

class GitResult;

class RuleManager : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(Repository* currentRepo READ currentRepo WRITE setCurrentRepo NOTIFY currentRepoChanged FINAL)

public:
    explicit RuleManager(QObject *parent = nullptr);

    Q_INVOKABLE GitResult saveRules(const QString &jsonText);
    Q_INVOKABLE GitResult loadRules();

    Repository *currentRepo() const;
    Q_INVOKABLE void setCurrentRepo(Repository *newCurrentRepo);

signals:
    void currentRepoChanged();

private:
    QString rulesFilePath();
    Repository *m_currentRepo = nullptr;
};


