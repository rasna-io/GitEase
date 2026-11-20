#pragma once

#include "Formatter.h"
#include "Sink.h"

#include <memory>

namespace Log
{
    /**
     * \brief Writes records to stderr
     *
     * A Windows GUI application without a console writes to the debugger output instead
     * (OutputDebugString), which is where Qt's default message handler would put it.
     */
    class ConsoleSink final : public ISink
    {
    public:
        enum class Colors
        {
            // Only when stderr is an interactive terminal or console
            Auto,
            Always,
            Never
        };

        explicit ConsoleSink(std::shared_ptr<IFormatter> formatter, Colors colors = Colors::Auto);

        void write(const Record &record) override;
        void flush() override;

    private:
        std::shared_ptr<IFormatter> m_formatter;
        bool m_useColors = false;
        bool m_toConsole = false;
        bool m_hasStream = false;
    };
} // namespace Log
