#pragma once

#include <QString>
#include <QUrl>
#include <QtPlugin>

class IRepositoryAwarePlugin
{
public:
    virtual ~IRepositoryAwarePlugin() = default;

    virtual void repositoryChanged(const QString& repoPath) = 0;
};

Q_DECLARE_INTERFACE(IRepositoryAwarePlugin, "com.gitease.IRepositoryAwarePlugin/1.0")
