#pragma once

#include "Level.h"

#include <QDateTime>
#include <QString>

namespace Log
{
    /**
     * \brief A single log entry
     *
     * Created on the calling thread, queued, and handed to every sink on the worker thread.
     */
    struct Record
    {
        QDateTime timestamp;
        Level level = Level::Info;
        QString category;
        QString message;

        // Source location, empty when the origin does not provide it (e.g. QML calls)
        QString file;
        int line = 0;
        QString function;

        quintptr threadId = 0;
        qint64 processId = 0;
    };
} // namespace Log
