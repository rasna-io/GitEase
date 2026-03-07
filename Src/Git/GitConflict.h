#pragma once

#include "GitResult.h"
#include "IGitController.h"
#include <QObject>

struct git_index_entry;

class GitConflict : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

private:
    GitResult writeConflictFromStage(const QString& filePath, int stage);

    QString readBlobContent(const git_index_entry* entry) const;

public:
    explicit GitConflict(QObject* parent = nullptr);

    Q_INVOKABLE GitResult getMergeConflicts();


    Q_INVOKABLE GitResult acceptConflictOurs(const QString& filePath);

    Q_INVOKABLE GitResult acceptConflictTheirs(const QString& filePath);
};
