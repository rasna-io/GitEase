#include "GitCommandText.h"

GitCommandText::GitCommandText(QObject *parent)
    : QObject{parent}
{}

QString GitCommandText::quote(const QString &argument)
{
    if (argument.isEmpty())
        return argument;

    QString escaped = argument;
    escaped.replace("\\", "\\\\");
    escaped.replace("\"", "\\\"");
    return "\"" + escaped + "\"";
}