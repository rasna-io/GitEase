#include "GitUtils.h"
#include <git2/errors.h>

GitUtils::GitUtils(QObject *parent)
    : QObject{parent}
{}

QString GitUtils::getLastError()
{
    QString lastError;
    const git_error *error = git_error_last();
    if (error && error->message) {
        lastError = QString::fromUtf8(error->message);
    }

    return lastError;
}

