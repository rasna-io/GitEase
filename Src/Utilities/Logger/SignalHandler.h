#pragma once

#include <QString>

namespace Log
{
    /**
     * \brief Reports fatal signals (SIGSEGV, SIGBUS, SIGFPE, SIGILL, SIGABRT) before a crash
     *
     * Implemented on Linux, elsewhere install() does nothing and returns false.
     *
     * The report only uses async-signal-safe calls. It goes to stderr and to the crash file, with
     * a backtrace when glibc's <execinfo.h> is available. Then the optional callback runs under a
     * 3 second alarm(), so a deadlock (e.g. on a corrupted heap) cannot hang the process. At the
     * end the previous handler is restored and the signal is raised again, so the default action
     * (core dump) or another crash reporter still runs.
     *
     * The handler runs on an alternate stack, so stack overflows are reported too. That stack is
     * installed for the calling thread only, so call install() from the main thread.
     */
    class SignalHandler
    {
    public:
        /** \brief Called from inside the signal handler after the report was written */
        using Callback = void (*)(int signalNumber);

        /**
         * \brief Installs the handlers
         * \param crashFilePath File the report is appended to, skipped when empty. The directory
         *        must exist. The report always goes to stderr as well.
         * \param callback Optional function to run after the report
         * \return false when the handlers are already installed or the platform is unsupported
         */
        static bool install(const QString &crashFilePath, Callback callback = nullptr);

        /** \brief Restores the handlers that were active before install() */
        static void uninstall();

        /** \brief "SIGSEGV" and friends, "UNKNOWN" for anything else, safe inside a handler */
        static const char *signalName(int signalNumber);
    };
} // namespace Log
