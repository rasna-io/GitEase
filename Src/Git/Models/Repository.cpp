#include "Repository.h"

Repository::Repository(QObject *parent)
    : QObject{parent}
{}


Repository::Repository(git_repository *repo, QObject *parent) : QObject(parent),
    repo(repo)
{}
