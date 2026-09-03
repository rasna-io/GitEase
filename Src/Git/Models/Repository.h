#pragma once

#include <QObject>
#include <QRecursiveMutex>
#include <git2/types.h>

class Repository : public QObject
{
    Q_OBJECT
public:
    explicit Repository(QObject *parent = nullptr);
    Repository(git_repository *repo, QObject *parent = nullptr);
    ~Repository() override;

    git_repository* repo = nullptr;

    //! A second handle on the same repository, used only by long remote transfers.
    git_repository* netRepo = nullptr;

     //! Serialises libgit2 access to this repository.
    QRecursiveMutex mutex;

    //! Guards netRepo. Deliberately separate from mutex, so a transfer blocks no reads.
    QRecursiveMutex netMutex;
};

