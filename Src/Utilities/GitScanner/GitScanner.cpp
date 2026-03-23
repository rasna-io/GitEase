#include "GitScanner.hpp"

#include <QDir>
#include <QFile>
#include <QProcess>
#include <QTextStream>
#include <QDateTime>
#include <QStandardPaths>
#include <QtConcurrent>
#include <QDirIterator>
#include <atomic>

GitScanner::GitScanner(QObject *parent)
    : QObject(parent)
    , m_stopRequested(false)
    , m_busy(false)
{
    connect(&m_watcher, &QFutureWatcher<QStringList>::finished, this, [this]() {

        if (m_busy.load()) {
            m_busy.store(false);
            emit busyChanged();
        }

        if (m_stopRequested.load()) {
            emit scanStopped();
        } else {
            emit scanFinished(m_watcher.result());
        }
    });
}

bool GitScanner::busy() const {
    return m_busy.load();
}

void GitScanner::scan(const QString &rootPath) {
    if (m_watcher.isRunning())
        return;

    m_stopRequested = false;

    if (!m_busy.load()) {
        m_busy.store(true);
        emit busyChanged();
    }

    emit scanStarted();

    auto future = QtConcurrent::run([this, rootPath]() {

        QStringList repos;

        QQueue<QString> queue;
        QMutex mutex;

        queue.enqueue(rootPath);

        int workers = QThread::idealThreadCount();

        QList<QFuture<void>> tasks;

        for (int i = 0; i < workers; ++i) {

            tasks.append(QtConcurrent::run([&, this]() {

                while (!m_stopRequested) {

                    QString dirPath;
                    {
                        QMutexLocker lock(&mutex);

                        if (queue.isEmpty())
                            return;

                        dirPath = queue.dequeue();
                    }

                    QDir dir(dirPath);

                    if (dir.exists(".git")) {
                        QMutexLocker lock(&mutex);
                        repos.append(dirPath);
                        emit pathFound(dirPath);
                    }

                    QFileInfoList subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);

                    for (const QFileInfo &info : std::as_const(subdirs)) {
                        QMutexLocker lock(&mutex);
                        queue.enqueue(info.absoluteFilePath());
                    }
                }
            }));
        }

        for (auto &t : tasks)
            t.waitForFinished();

        return repos;
    });

    m_watcher.setFuture(future);
}

void GitScanner::stop() {
    if (!m_watcher.isRunning())
        return;

    m_stopRequested.store(true);
}
