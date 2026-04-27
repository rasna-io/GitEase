import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase

/*! ***********************************************************************************************
 * DropZone
 * Contain Docks and control detachable docks
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int            orientation:            Qt.Horizontal
    default property alias  content:                contentItem.data

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.fillHeight: true

    /* Children
     * ****************************************************************************************/
    Item {
        id: contentItem
        anchors.fill: parent

        onChildrenChanged: Qt.callLater(updateLayout)
        Component.onCompleted: Qt.callLater(updateLayout)

        function updateLayout() {
            const visibleChildren = children.filter(child => {
                if (child.hasOwnProperty('detached')) {
                    try {
                        child.detachedChanged.disconnect(updateLayout)
                    } catch(e) {}

                    child.visible = Qt.binding(() => !child.detached)
                    child.detachedChanged.connect(updateLayout)

                    return !child.detached
                }
                child.visible = true
                return true
            })

            root.visible = !!visibleChildren.length

            if (!visibleChildren.length) {
                return
            }

            const isHorizontal = root.orientation === Qt.Horizontal

            visibleChildren.forEach((child, i) => {
                child.x = Qt.binding(() => isHorizontal ? i * root.width / visibleChildren.length : 0)
                child.y = Qt.binding(() => isHorizontal ? 0 : i * root.height / visibleChildren.length)
                child.width = Qt.binding(() => isHorizontal ? root.width / visibleChildren.length : root.width)
                child.height = Qt.binding(() => isHorizontal ? root.height : root.height / visibleChildren.length)
            })
        }
    }

    /* Functions
     * ****************************************************************************************/
}
