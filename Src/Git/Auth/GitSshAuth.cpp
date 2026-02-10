#include "GitSshAuth.h"


GitSshAuth::GitSshAuth()
{
    if (ensureAgentRunning()) {
        // Agent is accessible, check if keys are loaded
        if (!hasSshKeysLoaded()) {
            if (!loadDefaultSshKeys()) {
                m_setupError = "SSH agent is running but no SSH keys could be loaded. "
                              "Please ensure you have SSH keys in ~/.ssh/ and load them manually.";
            }
        }
    } else {
        m_setupError = "Failed to start or connect to SSH authentication agent. "
                      "Please ensure the OpenSSH Authentication Agent service is running.";
    }
}

QString GitSshAuth::getSetupError() const
{
    return m_setupError;
}

bool GitSshAuth::ensureAgentRunning()
{
    // First check if agent is accessible
    if (isSshAgentAccessible())
        return true;

    // If not accessible, check if service is running
    if (!isSshAgentRunning()) {
        // Try to start service (don't modify startup type)
        if (!startSshAgent()) {
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
            QProcess proc;
            proc.start("ssh-add", QStringList() << keyPath);
            proc.waitForFinished(5000);

            if (proc.exitCode() == 0) {
                loadedAny = true;
            }
        }
    }

    return loadedAny;
}

bool GitSshAuth::setupSshEnvironment()
{
    // On Windows, the SSH agent uses a named pipe
    QString pipePath = "\\\\.\\pipe\\openssh-ssh-agent";

    // Check if the pipe exists and set the environment variable
    if (QFile::exists(pipePath)) {
        qputenv("SSH_AUTH_SOCK", pipePath.toUtf8());
        return isSshAgentAccessible();
    }

    return false;
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

int GitSshAuth::credentialsCallback(git_cred** out,
                                    const char* url,
                                    const char* username_from_url,
                                    unsigned int allowed_types,
                                    void*)
{
    if (allowed_types & GIT_CREDTYPE_SSH_KEY)
    {
        // First verify agent is accessible
        if (!isSshAgentAccessible()) {
            return GIT_EAUTH;
        }

        // Check if keys are loaded
        if (!hasSshKeysLoaded()) {
            return GIT_EAUTH;
        }

        const char* user =
            username_from_url ? username_from_url : "git";

        int result = git_cred_ssh_key_from_agent(out, user);
        return result;
    }

    return GIT_PASSTHROUGH;
}
