#include "ConsoleSink.h"

#include <QByteArray>

#include <cstdio>
#include <utility>

#if defined(Q_OS_WIN)
#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <unistd.h>
#endif

namespace Log
{
    namespace
    {
        const char *const kAnsiReset = "\x1b[0m";

#if defined(Q_OS_WIN)

        HANDLE standardErrorHandle()
        {
            HANDLE handle = GetStdHandle(STD_ERROR_HANDLE);

            if(handle == nullptr || handle == INVALID_HANDLE_VALUE)
            {
                return nullptr;
            }

            if(GetFileType(handle) == FILE_TYPE_UNKNOWN)
            {
                return nullptr;
            }

            return handle;
        }

        bool isConsoleHandle(HANDLE handle)
        {
            DWORD mode = 0;
            return handle != nullptr && GetConsoleMode(handle, &mode) != 0;
        }

        void enableVirtualTerminal(HANDLE handle)
        {
            DWORD mode = 0;

            if(GetConsoleMode(handle, &mode) != 0)
            {
                SetConsoleMode(handle, mode | ENABLE_VIRTUAL_TERMINAL_PROCESSING);
            }
        }

#endif
    } // namespace

    ConsoleSink::ConsoleSink(std::shared_ptr<IFormatter> formatter, Colors colors)
        : m_formatter(std::move(formatter))
    {
#if defined(Q_OS_WIN)
        HANDLE handle = standardErrorHandle();
        m_hasStream = handle != nullptr;
        m_toConsole = isConsoleHandle(handle);

        if(m_toConsole)
        {
            enableVirtualTerminal(handle);
        }

        const bool interactive = m_toConsole;
#else
        m_hasStream = true;
        const bool interactive = isatty(fileno(stderr)) != 0;
#endif

        m_useColors = colors == Colors::Always
            || (colors == Colors::Auto && interactive);
    }

    void ConsoleSink::write(const Record &record)
    {
        if(!m_formatter)
        {
            return;
        }

        QString text = m_formatter->format(record);

        if(m_useColors)
        {
            text = QString::fromLatin1(levelAnsiColor(record.level))
                + text
                + QString::fromLatin1(kAnsiReset);
        }

        text.append(QLatin1Char('\n'));

#if defined(Q_OS_WIN)
        HANDLE handle = standardErrorHandle();

        if(handle == nullptr)
        {
            OutputDebugStringW(reinterpret_cast<LPCWSTR>(text.utf16()));
            return;
        }

        if(m_toConsole)
        {
            DWORD written = 0;
            WriteConsoleW(handle,
                          text.utf16(),
                          static_cast<DWORD>(text.size()),
                          &written,
                          nullptr);
            return;
        }

        const QByteArray bytes = text.toUtf8();
        DWORD written = 0;
        WriteFile(handle, bytes.constData(), static_cast<DWORD>(bytes.size()), &written, nullptr);
#else
        const QByteArray bytes = text.toUtf8();
        std::fwrite(bytes.constData(), 1, static_cast<size_t>(bytes.size()), stderr);
#endif
    }

    void ConsoleSink::flush()
    {
#if !defined(Q_OS_WIN)
        std::fflush(stderr);
#endif
    }
} // namespace Log
