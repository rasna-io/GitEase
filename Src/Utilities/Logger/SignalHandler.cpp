#include "SignalHandler.h"

#include <QByteArray>
#include <QFile>

#if defined(Q_OS_LINUX)

#include <cerrno>
#include <csignal>
#include <cstddef>
#include <cstring>
#include <ctime>

#include <fcntl.h>
#include <sys/syscall.h>
#include <unistd.h>

#if __has_include(<execinfo.h>)
#include <execinfo.h>
#define LOGGER_HAS_BACKTRACE 1
#endif

namespace Log
{
    namespace
    {
        const int kSignals[] = { SIGSEGV, SIGBUS, SIGFPE, SIGILL, SIGABRT };
        constexpr size_t kSignalCount = sizeof(kSignals) / sizeof(kSignals[0]);

        constexpr size_t kPathCapacity = 4096;
        constexpr size_t kAlternateStackSize = 64 * 1024;
        constexpr int kMaxFrames = 64;
        constexpr unsigned kCallbackTimeoutSeconds = 3;

        struct sigaction s_previous[kSignalCount];
        char s_crashFilePath[kPathCapacity] = {};
        SignalHandler::Callback s_callback = nullptr;

        alignas(16) char s_alternateStack[kAlternateStackSize];
        stack_t s_previousStack;
        bool s_ownsAlternateStack = false;

        bool s_installed = false;
        volatile sig_atomic_t s_handling = 0;

        // Fixed size text buffer that formats without allocating, so it can be used inside a signal
        // handler. Text that does not fit is cut off
        class Buffer
        {
        public:
            void append(const char *text)
            {
                while(*text != '\0' && m_length < kCapacity)
                {
                    m_data[m_length] = *text;
                    ++m_length;
                    ++text;
                }
            }

            void appendUnsigned(unsigned long long value)
            {
                char digits[24];
                size_t count = 0;

                do
                {
                    digits[count] = static_cast<char>('0' + value % 10);
                    ++count;
                    value /= 10;
                } while(value != 0);

                while(count > 0)
                {
                    --count;
                    appendChar(digits[count]);
                }
            }

            void appendSigned(long long value)
            {
                if(value < 0)
                {
                    appendChar('-');
                    appendUnsigned(0ULL - static_cast<unsigned long long>(value));
                }
                else
                {
                    appendUnsigned(static_cast<unsigned long long>(value));
                }
            }

            void appendHex(unsigned long long value)
            {
                static const char hexDigits[] = "0123456789abcdef";

                char digits[16];
                size_t count = 0;

                do
                {
                    digits[count] = hexDigits[value & 0xF];
                    ++count;
                    value >>= 4;
                } while(value != 0);

                append("0x");

                while(count > 0)
                {
                    --count;
                    appendChar(digits[count]);
                }
            }

            // Appends value with at least width digits, padded with zeros
            void appendPadded(unsigned long long value, int width)
            {
                char digits[24];
                int count = 0;

                do
                {
                    digits[count] = static_cast<char>('0' + value % 10);
                    ++count;
                    value /= 10;
                } while(value != 0 && count < 20);

                for(int pad = count; pad < width; ++pad)
                {
                    appendChar('0');
                }

                while(count > 0)
                {
                    --count;
                    appendChar(digits[count]);
                }
            }

            const char *data() const
            {
                return m_data;
            }

            size_t size() const
            {
                return m_length;
            }

        private:
            void appendChar(char character)
            {
                if(m_length < kCapacity)
                {
                    m_data[m_length] = character;
                    ++m_length;
                }
            }

            static constexpr size_t kCapacity = 2048;

            char m_data[kCapacity];
            size_t m_length = 0;
        };

        void writeAll(int fd, const char *data, size_t size)
        {
            while(size > 0)
            {
                const ssize_t written = ::write(fd, data, size);

                if(written < 0)
                {
                    if(errno == EINTR)
                    {
                        continue;
                    }

                    return;
                }

                data += written;
                size -= static_cast<size_t>(written);
            }
        }

        // "YYYY-MM-DD HH:MM:SS UTC" without gmtime(), which is not async-signal-safe
        void appendTimestamp(Buffer &buffer, time_t now)
        {
            long long days = static_cast<long long>(now) / 86400;
            const long long seconds = static_cast<long long>(now) % 86400;

            // Civil date from a day count (Howard Hinnant's date algorithms)
            days += 719468;

            const long long era = days / 146097;
            const long long dayOfEra = days - era * 146097;
            const long long yearOfEra =
                (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146096) / 365;
            const long long dayOfYear = dayOfEra -
                (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100);
            const long long monthIndex = (5 * dayOfYear + 2) / 153;
            const long long day = dayOfYear - (153 * monthIndex + 2) / 5 + 1;
            const long long month = monthIndex < 10 ? monthIndex + 3 : monthIndex - 9;
            const long long year = yearOfEra + era * 400 + (month <= 2 ? 1 : 0);

            buffer.appendPadded(static_cast<unsigned long long>(year), 4);
            buffer.append("-");
            buffer.appendPadded(static_cast<unsigned long long>(month), 2);
            buffer.append("-");
            buffer.appendPadded(static_cast<unsigned long long>(day), 2);
            buffer.append(" ");
            buffer.appendPadded(static_cast<unsigned long long>(seconds / 3600), 2);
            buffer.append(":");
            buffer.appendPadded(static_cast<unsigned long long>(seconds % 3600 / 60), 2);
            buffer.append(":");
            buffer.appendPadded(static_cast<unsigned long long>(seconds % 60), 2);
            buffer.append(" UTC");
        }

        const char *segvReason(int code)
        {
            switch(code)
            {
            case SEGV_MAPERR:
                return "address not mapped";
            case SEGV_ACCERR:
                return "invalid permissions for mapped address";
            default:
                return nullptr;
            }
        }

        bool hasFaultAddress(int signalNumber, const siginfo_t *info)
        {
            if(info == nullptr || info->si_code <= 0)
            {
                // Sent by kill(), raise() or abort(), there is no faulting address
                return false;
            }

            return signalNumber == SIGSEGV || signalNumber == SIGBUS || signalNumber == SIGFPE
                   || signalNumber == SIGILL;
        }

        void restorePreviousAndRaise(int signalNumber)
        {
            for(size_t i = 0; i < kSignalCount; ++i)
            {
                if(kSignals[i] == signalNumber)
                {
                    sigaction(signalNumber, &s_previous[i], nullptr);
                    break;
                }
            }

            // The signal is blocked while the handler runs. It is delivered, to the previous
            // handler or the default action, as soon as this handler returns.
            raise(signalNumber);
        }

        void handleSignal(int signalNumber, siginfo_t *info, void *)
        {
            const int savedErrno = errno;

            if(s_handling != 0)
            {
                // A second fatal signal while reporting the first one, stop here
                restorePreviousAndRaise(signalNumber);
                errno = savedErrno;
                return;
            }

            s_handling = 1;

            Buffer report;
            report.append("\n===== Fatal signal =====\n");

            report.append("time:    ");
            appendTimestamp(report, time(nullptr));
            report.append("\n");

            report.append("signal:  ");
            report.appendSigned(signalNumber);
            report.append(" (");
            report.append(SignalHandler::signalName(signalNumber));
            report.append(")\n");

            if(info != nullptr)
            {
                report.append("code:    ");
                report.appendSigned(info->si_code);

                const char *reason = signalNumber == SIGSEGV ? segvReason(info->si_code) : nullptr;

                if(reason != nullptr)
                {
                    report.append(" (");
                    report.append(reason);
                    report.append(")");
                }

                report.append("\n");
            }

            if(hasFaultAddress(signalNumber, info))
            {
                report.append("address: ");
                report.appendHex(reinterpret_cast<unsigned long long>(info->si_addr));
                report.append("\n");
            }

            report.append("pid:     ");
            report.appendSigned(getpid());
            report.append("\n");

            report.append("thread:  ");
            report.appendSigned(static_cast<long long>(syscall(SYS_gettid)));
            report.append("\n");

#if defined(LOGGER_HAS_BACKTRACE)
            report.append("backtrace:\n");
#endif

            int fileDescriptor = -1;

            if(s_crashFilePath[0] != '\0')
            {
                fileDescriptor = ::open(s_crashFilePath, O_WRONLY | O_CREAT | O_APPEND | O_CLOEXEC,
                                        0644);
            }

            writeAll(STDERR_FILENO, report.data(), report.size());

            if(fileDescriptor >= 0)
            {
                writeAll(fileDescriptor, report.data(), report.size());
            }

#if defined(LOGGER_HAS_BACKTRACE)
            void *frames[kMaxFrames];
            const int frameCount = backtrace(frames, kMaxFrames);

            backtrace_symbols_fd(frames, frameCount, STDERR_FILENO);

            if(fileDescriptor >= 0)
            {
                backtrace_symbols_fd(frames, frameCount, fileDescriptor);
            }
#endif

            static const char kFooter[] = "========================\n";

            writeAll(STDERR_FILENO, kFooter, sizeof(kFooter) - 1);

            if(fileDescriptor >= 0)
            {
                writeAll(fileDescriptor, kFooter, sizeof(kFooter) - 1);
                fsync(fileDescriptor);
                ::close(fileDescriptor);
            }

            if(s_callback != nullptr)
            {
                // The callback may take locks that the crashed thread holds. The default action of
                // SIGALRM terminates the process, which bounds a would-be hang
                alarm(kCallbackTimeoutSeconds);
                s_callback(signalNumber);
                alarm(0);
            }

            restorePreviousAndRaise(signalNumber);
            errno = savedErrno;
        }
    } // namespace

    bool SignalHandler::install(const QString &crashFilePath, Callback callback)
    {
        if(s_installed)
        {
            return false;
        }

        const QByteArray encodedPath = QFile::encodeName(crashFilePath);

        if(static_cast<size_t>(encodedPath.size()) < kPathCapacity)
        {
            std::memcpy(s_crashFilePath, encodedPath.constData(),
                        static_cast<size_t>(encodedPath.size()));
            s_crashFilePath[encodedPath.size()] = '\0';
        }
        else
        {
            s_crashFilePath[0] = '\0';
        }

        s_callback = callback;
        s_handling = 0;

#if defined(LOGGER_HAS_BACKTRACE)
        // The first backtrace() call may load libgcc, which is unsafe inside a signal handler
        void *warmUp[1];
        backtrace(warmUp, 1);
#endif

        // Use an alternate stack so a stack overflow can still be reported, but leave an
        // existing one alone
        stack_t current;
        std::memset(&current, 0, sizeof(current));

        if(sigaltstack(nullptr, &current) == 0 && (current.ss_flags & SS_DISABLE) != 0)
        {
            stack_t stack;
            std::memset(&stack, 0, sizeof(stack));
            stack.ss_sp = s_alternateStack;
            stack.ss_size = sizeof(s_alternateStack);
            stack.ss_flags = 0;

            s_ownsAlternateStack = sigaltstack(&stack, &s_previousStack) == 0;
        }

        struct sigaction action;
        std::memset(&action, 0, sizeof(action));
        action.sa_sigaction = &handleSignal;
        action.sa_flags = SA_SIGINFO | SA_ONSTACK;
        sigemptyset(&action.sa_mask);

        for(size_t i = 0; i < kSignalCount; ++i)
        {
            sigaction(kSignals[i], &action, &s_previous[i]);
        }

        s_installed = true;
        return true;
    }

    void SignalHandler::uninstall()
    {
        if(!s_installed)
        {
            return;
        }

        for(size_t i = 0; i < kSignalCount; ++i)
        {
            struct sigaction current;
            std::memset(&current, 0, sizeof(current));

            // Somebody installed a handler after us, leave theirs in place
            if(sigaction(kSignals[i], nullptr, &current) == 0
               && current.sa_sigaction == &handleSignal)
            {
                sigaction(kSignals[i], &s_previous[i], nullptr);
            }
        }

        if(s_ownsAlternateStack)
        {
            sigaltstack(&s_previousStack, nullptr);
            s_ownsAlternateStack = false;
        }

        s_callback = nullptr;
        s_crashFilePath[0] = '\0';
        s_installed = false;
    }

    const char *SignalHandler::signalName(int signalNumber)
    {
        switch(signalNumber)
        {
        case SIGSEGV:
            return "SIGSEGV";
        case SIGBUS:
            return "SIGBUS";
        case SIGFPE:
            return "SIGFPE";
        case SIGILL:
            return "SIGILL";
        case SIGABRT:
            return "SIGABRT";
        default:
            return "UNKNOWN";
        }
    }
} // namespace Log

#else // !Q_OS_LINUX

namespace Log
{
    bool SignalHandler::install(const QString &crashFilePath, Callback callback)
    {
        Q_UNUSED(crashFilePath)
        Q_UNUSED(callback)

        return false;
    }

    void SignalHandler::uninstall()
    {
    }

    const char *SignalHandler::signalName(int signalNumber)
    {
        Q_UNUSED(signalNumber)

        return "UNKNOWN";
    }
} // namespace Log

#endif
