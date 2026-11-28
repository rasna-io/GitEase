#pragma once
#include <QObject>
#include <QProcess>

/*!
 * @brief One embedded shell process, serving a single repository session of the terminal.
 *
 * The shell (bash on Unix, cmd.exe on Windows) is started in the repository's working directory
 * on the first command and stays there, so every repository gets a shell of its own: a command
 * running in one repository never delays or receives the output of another one's.
 *
 * Output is parsed for ANSI color codes and emitted as JSON-encoded color segments.
 *
 * Sentinel-based prompt detection is used to track command completion. The shell only counts as
 * ready once it printed its first sentinel, which keeps its start-up chatter (banner, echo of the
 * setup commands) out of the session, and lets a command written before that point simply wait
 * in the shell's input until the setup is done.
 */
class ShellSession : public QObject
{
    Q_OBJECT

public:
    explicit ShellSession(const QString &workingDirectory, QObject *parent = nullptr);
    ~ShellSession();

    /**
     * @brief Returns the directory the shell runs in.
     */
    QString workingDirectory() const;

    /**
     * @brief Returns true if the shell process is running.
     */
    bool running() const;

    /**
     * @brief Returns true from the moment a command is sent until its completion is detected.
     */
    bool busy() const;

    /**
     * @brief Sends a command to the shell, starting the shell first when it is not running.
     *
     * Git commands are automatically prefixed with `-c color.ui=always` to force
     * colored output. Commands matching known git state-changing operations will
     * trigger a \c gitStateChanged signal on successful completion.
     *
     * Ignored while a previous command is still running.
     *
     * @param command The command string to execute.
     */
    void sendCommand(const QString &command);

    /**
     * @brief Kills the shell process. The next command starts a new one.
     *
     * Use this to recover from a hung or crashed shell.
     */
    void kill();

    /**
     * @brief Ends the session, without ever cutting a running command short.
     *
     * An idle shell is terminated right away, a busy one as soon as its command completes.
     * \c closed is emitted once the shell is gone.
     */
    void close();

private:
    /**
     * @brief Starts the shell process and writes its setup commands.
     *
     * On Unix, launches bash via the \c script command to allocate a PTY.
     * On Windows, launches cmd.exe with UTF-8 encoding enabled.
     * The sentinel prompt is set by the last setup command, so the first sentinel marks the end
     * of the setup.
     */
    void start();

    /**
     * @brief Splits shell output into lines and dispatches them.
     */
    void handleOutput(const QString &output);

    /**
     * @brief Handles a sentinel prompt: the setup or the running command has completed.
     * @param exitCode Exit code of the command, 0 where the shell does not report one (Windows).
     */
    void handlePrompt(int exitCode);

    /**
     * @brief Ends the running command, if any, and notifies the listeners.
     * @param succeeded Whether the command may have changed the git state.
     */
    void finishCommand(bool succeeded);

    void setBusy(bool busy);

    QProcess *m_process = nullptr;
    QString   m_workingDirectory;
    bool      m_ready = false;
    bool      m_busy = false;
    bool      m_closing = false;
    bool      m_gitStateUpdateRequired = false;
    QString   m_lastCommand;

private slots:
    /**
     * @brief Reads and processes stdout from the shell process.
     */
    void onReadyReadStandardOutput();

    /**
     * @brief Reads and processes stderr from the shell process.
     */
    void onReadyReadStandardError();

    /**
     * @brief Handles shell process state transitions.
     */
    void onProcessStateChanged(QProcess::ProcessState state);

    /**
     * @brief Reports a shell that could not be started.
     */
    void onProcessErrorOccurred(QProcess::ProcessError error);

signals:
    /**
     * @brief Emitted when a line of output is received from the shell.
     * @param segmentsJson JSON array of color segments: [{text, color, bold}].
     */
    void lineReceived(const QString &segmentsJson);

    /**
     * @brief Emitted when a command is sent to the shell.
     */
    void commandStarted();

    /**
     * @brief Emitted when the running command completes, or the shell dies while running it.
     */
    void commandFinished();

    /**
     * @brief Emitted when a git state-changing command completes successfully.
     */
    void gitStateChanged();

    /**
     * @brief Emitted when the shell process state changes.
     */
    void runningChanged();

    /**
     * @brief Emitted when a command starts or finishes.
     */
    void busyChanged();

    /**
     * @brief Emitted once a session asked to close has terminated its shell.
     */
    void closed();
};
