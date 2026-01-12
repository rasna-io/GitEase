#pragma once

#include "Repository.h"
#include <QObject>
#include <QQmlEngine>
#include <git2/deprecated.h>

class IGitController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(Repository* currentRepo READ currentRepo WRITE setCurrentRepo NOTIFY currentRepoChanged FINAL)

public:
    explicit IGitController(QObject *parent = nullptr);

    Repository *currentRepo() const;
    void setCurrentRepo(Repository *newCurrentRepo);

    QString gitOidToString(const git_oid *oid);

signals:
    void currentRepoChanged();
protected:
    Repository *m_currentRepo = nullptr;
};
