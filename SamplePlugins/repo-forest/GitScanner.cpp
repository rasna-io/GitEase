#include "GitScanner.h"

#include <QDir>
#include <QFileInfo>
#include <QQueue>
#include <QStringList>
#include <QtConcurrent>

GitScanner::GitScanner(QObject* parent)
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

bool GitScanner::busy() const
{
    return m_busy.load();
}

void GitScanner::scan(const QString& rootPath)
{
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
        queue.enqueue(rootPath);

        while (!queue.isEmpty() && !m_stopRequested.load()) {
            const QString dirPath = queue.dequeue();
            QDir dir(dirPath);
            if (!dir.exists())
                continue;

            if (dir.exists(QStringLiteral(".git"))) {
                repos.append(dirPath);
                emit pathFound(dirPath);
                continue; // do not walk inside a discovered repository
            }

            const QFileInfoList subdirs = dir.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
            for (const QFileInfo& info : subdirs)
                queue.enqueue(info.absoluteFilePath());
        }

        return repos;
    });

    m_watcher.setFuture(future);
}

void GitScanner::stop()
{
    if (!m_watcher.isRunning())
        return;

    m_stopRequested.store(true);
}
