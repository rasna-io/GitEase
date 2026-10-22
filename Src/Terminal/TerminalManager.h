#pragma once
#include "IGitController.h"
#include <QHash>
#include <QObject>

class ShellSession;

/*!
 * @brief Manages an embedded shell process for executing git and system commands.
 *
 * TerminalManager spawns a persistent shell process (bash on Unix, cmd.exe on Windows)
 * and provides a QML-accessible interface for sending commands and receiving output.
 * Output is parsed for ANSI color codes and emitted as JSON-encoded color segments.
 *
 * Sentinel-based prompt detection is used to track command completion and trigger
 * git state updates when relevant commands are executed.
 */
class TerminalManager : public IGitController
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QString workingDirectory READ workingDirectory NOTIFY workingDirectoryChanged)
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString username READ username CONSTANT)
    Q_PROPERTY(QString hostname READ hostname CONSTANT)

public:
    explicit TerminalManager(QObject *parent = nullptr);
    ~TerminalManager();

    /**
     * @brief Returns the current working directory of the shell process.
     */
    QString workingDirectory() const;

    /**
     * @brief Returns true if the shell process is running
     */
    bool running() const;

    /**
     * @brief Returns true while a command is running in the current repository's shell.
     */
    bool busy() const;

    /**
     * @brief Sends a command to the shell process for execution.
     *
     * Git commands are automatically prefixed with `-c color.ui=always` to force
     * colored output. Commands matching known git state-changing operations will
     * trigger a \c gitStateChanged signal on successful completion.
     *
     * @param command The command string to execute.
     */
    Q_INVOKABLE void sendCommand(const QString &command);

    /**
     * @brief Kills the current repository's shell process; the next command starts a new one.
     *
     * Use this to recover from a hung or crashed shell session. The other repositories' shells
     * keep running.
     */
    Q_INVOKABLE void kill();

    /**
     * @brief Ends the shell session of a repository being closed.
     *
     * A command still running there is allowed to complete first, so closing a repository never
     * interrupts a git operation halfway.
     *
     * @param repository The repository being closed.
     */
    Q_INVOKABLE void closeSession(Repository *repository);

private:
    /**
     * @brief Returns the session of a working directory, creating it on first use.
     */
    ShellSession *sessionFor(const QString &workingDirectory);

    /**
     * @brief Returns the current repository's session, or nullptr before its first command.
     */
    ShellSession *currentSession() const;

    /**
     *  @brief Returns the OS username from environment variables.
     */
    QString username() const;

    /**
     * @brief Returns the machine hostname via QSysInfo.
     */
    QString hostname() const;

    QHash<QString, ShellSession *> m_sessions;
    QString                        m_workingDirectory;

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
     * @brief Updates the working directory when the active repository changes.
     *
     * Issues a \c cd command to the shell to align the shell's working directory
     * with the current repository's working directory.
     */
    void updateWorkingDirectory();

signals:
    /**
     * @brief Emitted when a line of output is received from a shell.
     * @param workingDirectory Working directory of the session the line belongs to.
     * @param segmentsJson JSON array of color segments: [{text, color, bold}].
     */
    void lineReceived(const QString &workingDirectory, const QString &segmentsJson);

    /**
     *  @brief Emitted when the current repository, and with it the working directory, changes.
     */
    void workingDirectoryChanged();

    /**
     * @brief Emitted when a command is sent to a shell.
     * @param workingDirectory Working directory of the session running the command.
     */
    void commandStarted(const QString &workingDirectory);

    /**
     * @brief Emitted when the shell prompt sentinel is detected, indicating command completion.
     * @param workingDirectory Working directory of the session that ran the command.
     */
    void commandFinished(const QString &workingDirectory);

    /**
     * @brief Emitted when the current repository's shell process state changes.
     */
    void runningChanged();

    /**
     * @brief Emitted when a command starts or finishes in the current repository's shell.
     */
    void busyChanged();

    /**
     * @brief Emitted when a git state-changing command completes successfully.
     *
     * Connect this signal to refresh repository views such as the commit graph,
     * staging area, or branch list. Commands run in the background repositories' shells too, so
     * a view showing only the current repository compares \a workingDirectory first.
     *
     * @param workingDirectory Working directory of the session that ran the command.
     */
    void gitStateChanged(const QString &workingDirectory);
};
