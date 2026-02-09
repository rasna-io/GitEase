#include "GitSshAuth.h"
#include "QProcess"
#include "QDebug"
#include "QStandardPaths"
#include "QDir"
#include "QFile"
#include "QThread"

GitSshAuth::GitSshAuth()
{
    if (ensureAgentRunning()) {
        // Agent is accessible, check if keys are loaded
        if (!hasSshKeysLoaded()) {
            qDebug() << "No SSH keys loaded, attempting to load default keys";
            loadDefaultSshKeys();
        }
    } else {
        qWarning() << "Failed to ensure SSH agent is running";
    }
}

bool GitSshAuth::ensureAgentRunning()
{
    // First check if agent is accessible
    if (isSshAgentAccessible())
        return true;

    // If not accessible, check if service is running
    if (!isSshAgentRunning()) {
        // Try to enable auto-start and start service
        enableSshAgentAutoStart();
        if (!startSshAgent()) {
            qWarning() << "Failed to start SSH agent service";
            return false;
        }
    }

    // Give the service a moment to initialize
    QThread::msleep(500);

    // Check if agent became accessible after starting service
    if (isSshAgentAccessible())
        return true;

    // If still not accessible, try to set up environment variables manually
    return setupSshEnvironment();
}

void GitSshAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitSshAuth::credentialsCallback;
}

void GitSshAuth::applyFetch(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitSshAuth::credentialsCallback;
}


void GitSshAuth::applyPush(git_push_options& pushopts)
{
    pushopts.callbacks.credentials = &credentialsCallback;
}

bool GitSshAuth::isSshAgentRunning()
{
    QProcess proc;
    proc.start("powershell",
               {"-Command", "Get-Service ssh-agent | Select-Object -ExpandProperty Status"});
    proc.waitForFinished();

    QString output = proc.readAllStandardOutput().trimmed();
    return output == "Running";
}

bool GitSshAuth::isSshAgentAccessible()
{
    // Test actual SSH agent connectivity by trying to list keys
    QProcess proc;
    proc.start("ssh-add", QStringList() << "-l");
    proc.waitForFinished(3000); // 3 second timeout

    // ssh-add -l returns:
    // 0 if agent is accessible and has keys
    // 1 if agent is accessible but has no keys
    // 2 if agent is not accessible
    int exitCode = proc.exitCode();

    // Exit code 0 or 1 means agent is accessible
    // Exit code 2 means "Could not open a connection to your authentication agent"
    return exitCode == 0 || exitCode == 1;
}

bool GitSshAuth::setupSshEnvironment()
{
    // On Windows, try to find and set the SSH agent pipe
    // The SSH agent typically creates a named pipe like:
    // \\.\pipe\openssh-ssh-agent

    QString pipePath = "\\\\.\\pipe\\openssh-ssh-agent";

    // Check if the pipe exists
    if (QFile::exists(pipePath)) {
        qputenv("SSH_AUTH_SOCK", pipePath.toUtf8());
        qDebug() << "Set SSH_AUTH_SOCK to:" << pipePath;

        // Test if it's now accessible
        if (isSshAgentAccessible()) {
            qDebug() << "SSH agent is now accessible after setting environment";
            return true;
        }
    }

    // Try alternative approach: get environment from a fresh PowerShell session
    QProcess envProc;
    envProc.start("powershell", QStringList() << "-Command" << "ssh-agent");
    envProc.waitForFinished(5000);

    if (envProc.exitCode() == 0) {
        QString output = envProc.readAllStandardOutput();
        qDebug() << "ssh-agent output:" << output;

        // Parse the output to extract SSH_AUTH_SOCK and SSH_AGENT_PID
        QStringList lines = output.split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            if (line.contains("SSH_AUTH_SOCK=")) {
                QString sockValue = line.split('=').last().trimmed();
                if (!sockValue.isEmpty()) {
                    qputenv("SSH_AUTH_SOCK", sockValue.toUtf8());
                    qDebug() << "Set SSH_AUTH_SOCK from ssh-agent output:" << sockValue;
                }
            }
            if (line.contains("SSH_AGENT_PID=")) {
                QString pidValue = line.split('=').last().trimmed();
                if (!pidValue.isEmpty()) {
                    qputenv("SSH_AGENT_PID", pidValue.toUtf8());
                    qDebug() << "Set SSH_AGENT_PID from ssh-agent output:" << pidValue;
                }
            }
        }

        // Test accessibility again
        if (isSshAgentAccessible()) {
            qDebug() << "SSH agent is now accessible after parsing ssh-agent output";
            return true;
        }
    }

    qWarning() << "Failed to setup SSH environment";
    return false;
}

bool GitSshAuth::hasSshKeysLoaded()
{
    QProcess proc;
    proc.start("ssh-add", QStringList() << "-l");
    proc.waitForFinished(3000);

    // Exit code 0 means keys are loaded
    // Exit code 1 means agent is accessible but no keys loaded
    return proc.exitCode() == 0;
}

bool GitSshAuth::loadDefaultSshKeys()
{
    // Try to load default SSH keys
    QStringList defaultKeyPaths = {
        QDir::homePath() + "/.ssh/id_rsa",
        QDir::homePath() + "/.ssh/id_ed25519",
        QDir::homePath() + "/.ssh/id_ecdsa"
    };

    bool loadedAny = false;
    for (const QString& keyPath : defaultKeyPaths) {
        if (QFile::exists(keyPath)) {
            qDebug() << "Attempting to load SSH key:" << keyPath;
            QProcess proc;
            proc.start("ssh-add", QStringList() << keyPath);
            proc.waitForFinished(5000);

            if (proc.exitCode() == 0) {
                qDebug() << "Successfully loaded SSH key:" << keyPath;
                loadedAny = true;
            } else {
                QString error = proc.readAllStandardError();
                qWarning() << "Failed to load SSH key" << keyPath << ":" << error;
            }
        }
    }

    return loadedAny;
}

bool GitSshAuth::enableSshAgentAutoStart()
{
    QProcess proc;
    proc.start("powershell", {
                                 "-Command",
                                 "Set-Service ssh-agent -StartupType Automatic"
                             });
    proc.waitForFinished();

    return proc.exitCode() == 0;
}

bool GitSshAuth::startSshAgent()
{
    QProcess proc;
    proc.start("powershell", {
                                 "-Command",
                                 "Start-Service ssh-agent"
                             });
    proc.waitForFinished();

    return proc.exitStatus() == QProcess::NormalExit && proc.exitCode() == 0;
}

bool GitSshAuth::isAgentReady()
{
    return isSshAgentAccessible();
}

void GitSshAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitSshAuth::credentialsCallback;
}

int GitSshAuth::credentialsCallback(git_cred** out,
                                    const char* url,
                                    const char* username_from_url,
                                    unsigned int allowed_types,
                                    void*)
{
    qDebug() << "SSH credentials callback called for URL:" << url
             << "username:" << username_from_url
             << "allowed_types:" << allowed_types;

    if (allowed_types & GIT_CREDTYPE_SSH_KEY)
    {
        // First verify agent is accessible
        if (!isSshAgentAccessible()) {
            qWarning() << "SSH agent not accessible during authentication";
            return GIT_EAUTH;
        }

        // Check if keys are loaded
        if (!hasSshKeysLoaded()) {
            qWarning() << "No SSH keys loaded in agent";
            return GIT_EAUTH;
        }

        const char* user =
            username_from_url ? username_from_url : "git";

        qDebug() << "Attempting SSH authentication with user:" << user;
        int result = git_cred_ssh_key_from_agent(out, user);

        if (result != 0) {
            const git_error *err = git_error_last();
            qWarning() << "SSH authentication failed:" << (err ? err->message : "Unknown error");
        } else {
            qDebug() << "SSH credentials obtained successfully";
        }

        return result;
    }

    qWarning() << "SSH key authentication not allowed by server";
    return GIT_PASSTHROUGH;
}
