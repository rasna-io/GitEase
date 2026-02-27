#ifndef GITCONFLICT_H
#define GITCONFLICT_H

#include <QObject>

class GitConflict : public QObject
{
    Q_OBJECT
public:
    explicit GitConflict(QObject *parent = nullptr);

signals:
};

#endif // GITCONFLICT_H
