#pragma once

#include "Repository.h"
#include <QObject>
#include <QQmlEngine>

class IGitController : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(Repository* currentRepo READ currentRepo WRITE setCurrentRepo NOTIFY currentRepoChanged FINAL)

public:
    explicit IGitController(QObject *parent = nullptr);

    Repository *currentRepo() const;
    void setCurrentRepo(Repository *newCurrentRepo);

signals:
    void currentRepoChanged();
protected:
    Repository *m_currentRepo = nullptr;
};
