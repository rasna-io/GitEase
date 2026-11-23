#pragma once

#include "Record.h"

namespace Log
{
    /**
     * \brief Destination of log records (file, console, model, ...)
     *
     * The logger only calls a sink from its worker thread, so implementations do not need to
     * synchronize write() and flush(). A sink must never log through the logger itself.
     */
    class ISink
    {
    public:
        virtual ~ISink() = default;

        /** \brief Called once per record, in the order the records were logged */
        virtual void write(const Record &record) = 0;

        /** \brief Called after every drained batch and on demand through Logger::flush() */
        virtual void flush()
        {
        }
    };
} // namespace Log
