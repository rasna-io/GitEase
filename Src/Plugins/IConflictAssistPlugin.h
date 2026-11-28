#pragma once

#include <QString>
#include <QUrl>
#include <QtPlugin>

/*!
 * \brief Plugin interface for the conflict window's advisor strip.
 *
 * Call ctx->registerConflictAssist(this) inside initialize(). Any number of
 * plugins may register. The conflict window lists each one and loads its QML
 * into the shared advisor area. The host does not know what the plugin does.
 *
 * QML contract for assistQmlUrl(). The root item provides:
 *   property string repositoryPath
 *   property string filePath
 *   property int    regionIndex
 *   function start()
 *   function dismiss()
 *   signal applied(string message)
 *   signal dismissed()
 *   signal failed(string message)
 *
 * Optional, for a card action once a suggestion exists:
 *   readonly property bool hasRecommendation
 *   readonly property bool busy
 *   readonly property string recommendationText
 *   function applyRecommendation()
 *
 * The host saves the open file, sets the three properties, and calls start().
 * regionIndex counts still-open conflict regions from the top of the file.
 * applied() means the working file changed. dismiss() cancels work in progress
 * and does not emit dismissed().
 */
class IConflictAssistPlugin
{
public:
    virtual ~IConflictAssistPlugin() = default;

    virtual QString assistId()     const = 0;
    virtual QString assistTitle()  const = 0;
    virtual QString assistAction() const = 0;
    virtual QUrl    assistQmlUrl() const = 0;
    virtual int     assistOrder()  const { return 100; }
};

Q_DECLARE_INTERFACE(IConflictAssistPlugin, "com.gitease.IConflictAssistPlugin/1.0")
