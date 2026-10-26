import QtQuick

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * OpenRepositoryTransition
 * Takes the application window from the welcome flow to the main window. The window grows to its
 * main size while the main window is built behind the welcome page, with a loading state on top,
 * and `finished` is emitted once both are done. This is the only window size change that is animated.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var        window:  null
    property var        session: null
    property Component  preload: null
    property Item       mainWindow: null
    property bool       opening: false
    property var        incubator: null

    /* Signals
     * ****************************************************************************************/
    signal finished()

    /* Functions
     * ****************************************************************************************/
    function start() {
        root.mainWindow = null

        if(!Style.motionEnabled) {
            root.finished()
            return
        }

        root.opening = true
        root.startIncubation()
        resizeAnimation.restart()
    }

    function adoptInto(container) {
        if(!root.mainWindow) {
            return
        }

        root.mainWindow.parent = container
        root.mainWindow.anchors.fill = container
    }

    function startIncubation() {
        let component = root.preload
        if(!component || component.status !== Component.Ready) {
            component = Qt.createComponent("qrc:/GitEase/Qml/View/MainWindow.qml")
        }

        let incubator = component.incubateObject(host, { "uiSession": root.session }, Qt.Asynchronous)
        root.incubator = incubator

        if(incubator.status === Component.Loading) {
            incubator.onStatusChanged = function() {
                root.finish()
            }
        }
    }

    function finish() {
        let incubator = root.incubator
        if(resizeAnimation.running || !incubator) {
            return
        }

        if(incubator.status === Component.Loading) {
            incubator.forceCompletion()
        }

        root.incubator = null

        if(incubator.status === Component.Ready) {
            root.mainWindow = incubator.object
        }

        root.finished()
        root.opening = false
    }

    /* Children
     * ****************************************************************************************/
    ParallelAnimation {
        id: resizeAnimation

        NumberAnimation {
            target: root.window
            property: "width"
            to: Style.appWidth
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root.window
            property: "height"
            to: Style.appHeight
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root.window
            property: "x"
            to: ((root.window?.screen.width ?? Style.appWidth) - Style.appWidth) / 2
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: root.window
            property: "y"
            to: ((root.window?.screen.height ?? Style.appHeight) - Style.appHeight) / 2
            duration: Style.motionMedium
            easing.type: Easing.OutCubic
        }

        onFinished: {
            root.window.width = Qt.binding(function() {return Style.appWidth})
            root.window.height = Qt.binding(function() {return Style.appHeight})

            root.finish()
        }
    }

    Item {
        id: host

        width: Style.appWidth
        height: Style.appHeight
        opacity: 0
        enabled: false
    }

    Loader {
        id: overlay

        anchors.fill: parent
        active: root.opening || opacity > 0
        opacity: root.opening ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: Style.motionMedium
                easing.type: Easing.OutCubic
            }
        }

        sourceComponent: BusyWaiter {
            message: qsTr("Opening repository")

            MouseArea {
                anchors.fill: parent
            }
        }
    }
}
