#pragma once

#include <QObject>

#include "GitResult.h"
#include "IGitController.h"

class GitReset : public IGitController
{
    Q_OBJECT
    QML_ELEMENT
public:
    GitReset(QObject *parent = nullptr);

    enum ResetMode {
        Soft,
        Mixed,
        Hard
    };
    Q_ENUM(ResetMode)

    Q_INVOKABLE GitResult resetHead(const QString &commit, ResetMode mode);
};

