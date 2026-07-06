#pragma once
#include "IGitController.h"
#include <QObject>
#include <QProcess>
#include <QTimer>

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
     * @brief Kills the current shell process and starts a new one.
     *
     * Use this to recover from a hung or crashed shell session.
     */
    Q_INVOKABLE void kill();

private:
    /**
     * @brief Starts the shell process and configures the environment.
     *
     * On Unix, launches bash via the \c script command to allocate a PTY.
     * On Windows, launches cmd.exe with UTF-8 encoding enabled.
     * Sets up sentinel-based prompt detection for command completion tracking.
     */
    void startShell();

    /**
     *  @brief Returns the OS username from environment variables.
     */
    QString username() const;

    /**
     * @brief Returns the machine hostname via QSysInfo.
     */
    QString hostname() const;

    QProcess *m_process = nullptr;
    QString   m_workingDirectory;
    bool      m_running = false;
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
     * @brief Updates the working directory when the active repository changes.
     *
     * Issues a \c cd command to the shell to align the shell's working directory
     * with the current repository's working directory.
     */
    void updateWorkingDirectory();

signals:
    /**
     * @brief Emitted when a line of output is received from the shell.
     * @param segmentsJson JSON array of color segments: [{text, color, bold}].
     */
    void lineReceived(const QString &segmentsJson);

    /**
     *  @brief Emitted when the working directory changes.
     */
    void workingDirectoryChanged();

    /**
     * @brief Emitted when a command is sent to the shell.
     */
    void commandStarted();

    /**
     * @brief Emitted when the shell prompt sentinel is detected, indicating command completion.
     */
    void commandFinished();

    /**
     * @brief Emitted when the shell process state changes.
     */
    void runningChanged();

    /**
     * @brief Emitted when a git state-changing command completes successfully.
     *
     * Connect this signal to refresh repository views such as the commit graph,
     * staging area, or branch list.
     */
    void gitStateChanged();
};