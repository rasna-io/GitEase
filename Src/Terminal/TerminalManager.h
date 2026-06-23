#pragma once
#include "IGitController.h"
#include <QObject>
#include <QProcess>
#include <QTimer>

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

    QString workingDirectory() const;
    bool running() const;

    Q_INVOKABLE void sendCommand(const QString &command);
    Q_INVOKABLE void kill();

private:
    void startShell();
    QString username() const;
    QString hostname() const;

    QProcess *m_process = nullptr;
    QString   m_workingDirectory;
    bool      m_running = false;
    bool      m_gitStateUpdateRequired = false;

private slots:
    void onReadyReadStandardOutput();
    void onReadyReadStandardError();
    void onProcessStateChanged(QProcess::ProcessState state);
    void updateWorkingDirectory();

signals:
    void outputReceived(const QString &text);
    void lineReceived(const QString &segmentsJson);
    void workingDirectoryChanged();
    void commandStarted();
    void commandFinished();
    void runningChanged();
    void gitStateChanged();
};