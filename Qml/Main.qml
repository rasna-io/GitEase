import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls

import GitEase
import GitEase_Style
import GitEase.Resources
import GitEase_Style_Impl




/*! ***********************************************************************************************
 * This is the highest level graphical object, i.e., the main application window. The state
 * of each instance is stored in the UiSession, which needs to be passed to its children.
 * Multiple instances can be created.
 * ************************************************************************************************/
ApplicationWindow {
    id: window

    /* Property Declarations
     * ****************************************************************************************/
    property bool closeAnimationPlayed: false
    property bool hasActivatedBefore: false


    /* Object Properties
     * ****************************************************************************************/
    width: 523
    height: 475
    visible: true
    color: Style.colors.primaryBackground
    title: qsTr("GitEase")
    
    /* Event Handlers
     * ****************************************************************************************/
    onActiveChanged: {
        if (!window.active)
            return

        if (window.hasActivatedBefore)
            uiSession?.gitStateNotifier?.notifyChanged()

        window.hasActivatedBefore = true
    }

    onClosing: function(close) {
        if (Style.motionEnabled && !window.closeAnimationPlayed) {
            close.accepted = false
            window.closeAnimationPlayed = true
            windowCloseAnimation.restart()
            return
        }

        close.accepted = true

        try {
            uiSession?.notificationController?.shutdown()
        } catch (e) {
            console.error("[MainWindow] notification shutdown failed:", e)
        }

        Qt.callLater(function() {
            Qt.exit(0)
        })
    }

    ParallelAnimation {
        id: windowCloseAnimation

        NumberAnimation {
            target: window
            property: "opacity"
            to: 0
            duration: Style.motionMedium
            easing.type: Easing.InCubic
        }

        NumberAnimation {
            target: window.contentItem
            property: "scale"
            to: 0.985
            duration: Style.motionMedium
            easing.type: Easing.InCubic
        }

        onStopped: window.close()
    }


    /* Fonts
     * ****************************************************************************************/
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Thin-100.otf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Solid-900.otf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Regular-400.otf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Font Awesome 6 Pro-Light-300.otf" }

    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Inter-Regular.ttf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Inter-Medium.ttf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Inter-SemiBold.ttf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/Inter-Bold.ttf" }

    FontLoader { source: "qrc:/GitEase/Resources/Fonts/JetBrainsMono-Regular.ttf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/JetBrainsMono-Medium.ttf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/JetBrainsMono-SemiBold.ttf" }
    FontLoader { source: "qrc:/GitEase/Resources/Fonts/JetBrainsMono-Bold.ttf" }

    /* Shortcuts
     * ****************************************************************************************/
    Action {
        text: qsTr("Increments font size")
        shortcut: qsTr("Ctrl+=")
        onTriggered: {
            let appearance = uiSession.appModel.appSettings.appearanceSettings
            appearance.fontSizePt = Math.min(Style.appFont.maxAppFontPt, appearance.fontSizePt + 1)
            uiSession.appModel.save()
        }
    }

    Action {
        text: qsTr("Decrements  font size")
        shortcut: qsTr("Ctrl+-")
        onTriggered: {
            let appearance = uiSession.appModel.appSettings.appearanceSettings
            appearance.fontSizePt = Math.max(Style.appFont.minAppFontPt, appearance.fontSizePt - 1)
            uiSession.appModel.save()
        }
    }

    /* Children
     * ****************************************************************************************/
    UiSession {
        id: uiSession
        popups: uiSessionPopups

        Component.onCompleted: {
            uiSession.windowController.window = window
            uiSession.proxyController.applyToQtNetwork()

            Qt.callLater(function() {
                uiSession.updateController.checkForUpdatesOnStartup()
            })
        }
    }

    UiSessionPopups {
        id: uiSessionPopups
        width: window.width
        height: window.height
        appModel: uiSession.appModel
        notificationController: uiSession.notificationController
        guideController: uiSession.guideController
        proxyController: uiSession.proxyController
    }

    // Main content loader - switches between welcome flow and main application
    // Check flag BEFORE creating any components
    Loader {
        id: mainContentLoader
        anchors.fill: parent
        opacity: 0

        sourceComponent: uiSession?.shellController.commandExecuted
                         ? mainApplicationComponent : welcomeFlowComponent

        onLoaded: mainContentFadeIn.restart()

        NumberAnimation {
            id: mainContentFadeIn

            target: mainContentLoader
            property: "opacity"
            from: 0
            to: 1
            duration: Style.motionPage
            easing.type: Easing.OutCubic
        }
    }

    // Welcome Flow Component
    Component {
        id: welcomeFlowComponent

        Item {
            anchors.fill: parent

            WelcomeController {
                id: welcomeController

                currentPageIndex: uiSession.appModel.appSettings.hasCompletedWelcome ? Enums.WelcomePages.OpenRepository : Enums.WelcomePages.WelcomeBanner
                onWelcomeFlowCompleted: {
                    uiSession.appModel.appSettings.hasCompletedWelcome = true
                    uiSession.appModel.save()
                    mainContentLoader.sourceComponent = mainApplicationComponent
                }
            }

            Loader {
                id: welcomePageLoader
                anchors.fill: parent
                source: "qrc:/GitEase/Qml/Pages/WelcomePage.qml"

                // Pass controller to loaded page
                onLoaded: {
                    if (item && item.hasOwnProperty("controller")) {
                        item.controller = Qt.binding(function() {return welcomeController})
                    }
                    if (item && item.hasOwnProperty("repositoryController")) {
                        item.repositoryController = Qt.binding(function() {return uiSession.repositoryController})
                    }
                    if (item && item.hasOwnProperty("userProfileController")) {
                        item.userProfileController = Qt.binding(function() {return uiSession.userProfileController})
                    }
                    if (item && item.hasOwnProperty("appModel")) {
                        item.appModel = Qt.binding(function() {return uiSession.appModel})
                    }
                    if (item && item.hasOwnProperty("windowController")) {
                        item.windowController = Qt.binding(function() {return uiSession.windowController})
                    }
                    if (item.hasOwnProperty("notificationController")) {
                        item.notificationController = Qt.binding(function() { return uiSession.notificationController })
                    }
                }
            }
        }
    }

    // Main Application Component
    Component {
        id: mainApplicationComponent

        Item {
            anchors.fill: parent

            Loader {
                anchors.fill: parent
                source: "qrc:/GitEase/Qml/View/MainWindow.qml"

                onLoaded: {
                    if (item && item.hasOwnProperty("uiSession")) {
                        item.uiSession = uiSession
                    }
                }
            }

            Component.onCompleted: {
                window.width = Qt.binding(function() {return Style.appWidth})
                window.height = Qt.binding(function() {return Style.appHeight})
                window.x = (Screen.width - Style.appWidth) / 2
                window.y = (Screen.height - Style.appHeight) / 2
            }
        }
    }

    Connections {
        target: uiSession.appModel

        function onCurrentRepositoryChanged() {
            let currentRepo = uiSession.appModel.currentRepository

            if (currentRepo) {
                Qt.callLater(() => TaskbarHelper.setRepoInfo(currentRepo.color, currentRepo.name))
            }
        }
    }
}
