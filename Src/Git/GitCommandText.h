#pragma once

#include <QObject>
#include <QQmlEngine>

/*!
 * @brief Builds the git command strings shown to the user.
 *
 * Both sides of the app go through here: the controllers pass the result to emitGitCommand()
 * after an operation succeeds, and the forms call the same function to preview the command
 * before the user commits to it. Keeping one implementation is what stops a preview from
 * promising something other than what the controller runs.
 */
class GitCommandText : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    explicit GitCommandText(QObject *parent = nullptr);
};
