#include "GitSshAuth.h"
#include "QProcess"
#include "QDebug"

GitSshAuth::GitSshAuth()
{
    ensureAgentRunning();
}

bool GitSshAuth::ensureAgentRunning()
{
    if (isSshAgentRunning())
        return true;

    enableSshAgentAutoStart();
    return startSshAgent();
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
    return isSshAgentRunning();
}

void GitSshAuth::apply(git_fetch_options& fetchOpts)
{
    fetchOpts.callbacks.credentials = &GitSshAuth::credentialsCallback;
}

int GitSshAuth::credentialsCallback(git_cred** out,
                                    const char*,
                                    const char* username_from_url,
                                    unsigned int allowed_types,
                                    void*)
{
    if (allowed_types & GIT_CREDTYPE_SSH_KEY)
    {
        const char* user =
            username_from_url ? username_from_url : "git";

        return git_cred_ssh_key_from_agent(out, user);
    }

    return GIT_PASSTHROUGH;
}
