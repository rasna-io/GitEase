#pragma once

#include <QObject>

class GitUtils : public QObject
{
    Q_OBJECT
public:
    explicit GitUtils(QObject *parent = nullptr);


    static QString getLastError();
};

