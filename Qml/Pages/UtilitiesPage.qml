import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * UtilitiesPage
 * Responsive utilities page with auto-wrapping layout
 */

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var page: null

    property BranchController branchController: null
    property BundleController bundleController: null
    property RemoteController remoteController: null
    property UiSessionPopups  uiSessionPopups: null

    property StashController  stashController   : null
    
    property NotificationController notificationController: null

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    readonly property int hSpacing: 8
    readonly property int vSpacing: 8

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true

        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        contentWidth: flow.width
        contentHeight: flow.implicitHeight

        Flow {
            id: flow
            width: flick.width
            spacing: hSpacing

            ImportExportBundleDock {
                width: 330
                height: 390
                branchController: root.branchController
                bundleController: root.bundleController
            }

            RemoteView {
                width: 330
                height: 390
                remoteController: root.remoteController
                addEditRemotePopup: uiSessionPopups.addEditRemotePopup
                notificationController: root.notificationController
            }


            BranchManagementView {
                width: 330
                height: 390
                branchController: root.branchController
                addBranchPopup: uiSessionPopups.addBranchPopup
                notificationController: root.notificationController
            }


            StashManagerDock {
                width: 330
                height: 390
                stashController: root.stashController
                addStashPopup: uiSessionPopups.addStashPopup

                notificationController: root.notificationController
            }
        }
    }

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }
}
