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

    property Component mainWindowPreload: null

    property bool contentReady: false
    property bool revealed: false


    /* Object Properties
     * ****************************************************************************************/
    width: 523
    height: 475
    visible: window.contentReady
    opacity: 0
    color: Style.colors.primaryBackground
    title: qsTr("GitEase")
    
    /* Functions
     * ****************************************************************************************/
    function preloadMainWindow() {
        if(window.mainWindowPreload) {
            return
        }

        window.mainWindowPreload = Qt.createComponent("qrc:/GitEase/Qml/View/MainWindow.qml",
                                                      Component.Asynchronous, window)
    }

    function revealWindow() {
        if(window.contentReady) {
            return
        }

        mainContentLoader.opacity = 1
        window.contentReady = true
        revealFallbackTimer.restart()
    }

    function showRevealedWindow() {
        if(window.revealed) {
            return
        }

        window.revealed = true
        revealFallbackTimer.stop()
        windowRevealAnimation.restart()
    }

    /* Event Handlers
     * ****************************************************************************************/
    Connections {
        target: window

        function onFrameSwapped() {
            if(window.contentReady) {
                window.showRevealedWindow()
            }
        }
    }

    Timer {
        id: revealFallbackTimer

        interval: 1000
        repeat: false

        onTriggered: window.showRevealedWindow()
    }

    NumberAnimation {
        id: windowRevealAnimation

        target: window
        property: "opacity"
        from: 0
        to: 1
        duration: Style.motionFast
        easing.type: Easing.OutCubic
    }

    Connections {
        target: Qt.application

        function onStateChanged(state) {
            if(state !== Qt.ApplicationActive) {
                return
            }

            if(window.hasActivatedBefore) {
                uiSession?.gitStateNotifier?.notifyChanged()
            }

            window.hasActivatedBefore = true
        }
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
        popups: popupsLoader.item

        Component.onCompleted: {
            uiSession.windowController.window = window
            Qt.callLater(function() {
                uiSession.updateController.checkForUpdatesOnStartup()
            })
        }
    }

    Loader {
        id: popupsLoader

        readonly property bool needsPopupsNow: uiSession?.shellController?.commandExecuted ?? false

        active: window.revealed || openRepositoryTransition.opening || popupsLoader.needsPopupsNow
        asynchronous: !popupsLoader.needsPopupsNow

        sourceComponent: UiSessionPopups {
            width: window.width
            height: window.height
            appModel: uiSession.appModel
            notificationController: uiSession.notificationController
            guideController: uiSession.guideController
            sshKeyController: uiSession.sshKeyController
            textDirectionController: uiSession.textDirectionController
        }
    }

    // Main content loader - switches between welcome flow and main application
    // Check flag BEFORE creating any components
    Loader {
        id: mainContentLoader
        anchors.fill: parent
        opacity: 0

        sourceComponent: uiSession?.shellController.commandExecuted
                         ? mainApplicationComponent : welcomeFlowComponent

        onLoaded: {
            if(mainContentLoader.sourceComponent !== mainApplicationComponent) {
                return
            }

            if(window.contentReady) {
                mainContentFadeIn.restart()
            } else {
                window.revealWindow()
            }
        }

        NumberAnimation {
            id: mainContentFadeIn

            target: mainContentLoader
            property: "opacity"
            from: 0
            to: 1
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }
    }

    OpenRepositoryTransition {
        id: openRepositoryTransition

        anchors.fill: parent
        z: 1
        window: window
        session: uiSession
        preload: window.mainWindowPreload

        onFinished: mainContentLoader.sourceComponent = mainApplicationComponent
    }

    // Welcome Flow Component
    Component {
        id: welcomeFlowComponent

        Item {
            anchors.fill: parent

            Timer {
                id: preloadTimer

                interval: 50
                repeat: false
                running: true

                onTriggered: {
                    preloadTimer.stop()
                    window.preloadMainWindow()
                }
            }

            WelcomeController {
                id: welcomeController

                currentPageIndex: uiSession.appModel.appSettings.hasCompletedWelcome ? Enums.WelcomePages.OpenRepository : Enums.WelcomePages.WelcomeBanner
                onWelcomeFlowCompleted: {
                    uiSession.appModel.appSettings.hasCompletedWelcome = true
                    uiSession.appModel.save()
                    openRepositoryTransition.start()
                }
            }

            Loader {
                id: welcomePageLoader
                anchors.fill: parent
                asynchronous: true
                source: "qrc:/GitEase/Qml/Pages/WelcomePage.qml"

                onStatusChanged: {
                    if(welcomePageLoader.status === Loader.Error) {
                        window.revealWindow()
                    }
                }

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

                    window.revealWindow()
                }
            }
        }
    }

    // Main Application Component
    Component {
        id: mainApplicationComponent

        Item {
            id: mainWindowContainer
            anchors.fill: parent

            Loader {
                anchors.fill: parent
                active: openRepositoryTransition.mainWindow === null

                Component.onCompleted: setSource("qrc:/GitEase/Qml/View/MainWindow.qml",
                                                 { "uiSession": uiSession })
            }

            Component.onCompleted: {
                openRepositoryTransition.adoptInto(mainWindowContainer)

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
