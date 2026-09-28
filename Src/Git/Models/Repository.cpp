#include "Repository.h"

#include <git2.h>

Repository::Repository(QObject *parent)
    : QObject{parent}
{}


Repository::Repository(git_repository *repo, QObject *parent) : QObject(parent),
    repo(repo)
{}

Repository::~Repository()
{
    if (repo) {
        git_repository_free(repo);
        repo = nullptr;
    }

    if (netRepo) {
        git_repository_free(netRepo);
        netRepo = nullptr;
    }
}
