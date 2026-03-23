#pragma once

#include <QObject>
#include <QQmlEngine>
#include <QFutureWatcher>

class GitScanner : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

public:
    explicit GitScanner(QObject *parent = nullptr);

    Q_INVOKABLE void scan(const QString &rootPath);
    Q_INVOKABLE void stop();

    bool busy() const;

signals:
    void pathFound(const QString &path);
    void scanStarted();
    void scanFinished(const QStringList &repos);
    void scanStopped();
    void busyChanged();

private:
    std::atomic_bool m_stopRequested;
    QFutureWatcher<QStringList> m_watcher;
    std::atomic_bool m_busy;
};
