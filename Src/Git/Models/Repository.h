#pragma once

#include <QObject>
#include <git2/types.h>

class Repository : public QObject
{
    Q_OBJECT
public:
    explicit Repository(QObject *parent = nullptr);
    Repository(git_repository *repo, QObject *parent = nullptr);

    git_repository* repo = nullptr;

};

