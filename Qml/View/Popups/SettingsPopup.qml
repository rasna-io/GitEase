import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SettingsPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Object Properties
     * ****************************************************************************************/
    width: parent.width * 0.8
    height: parent.height * 0.8

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 0

            PageHeader {
                pageTitle: "Settings"
                showBackButton: true
                onBackClicked: {
                   root.close()
                }
            }

            RowLayout {
                Layout.fillHeight: true
                Layout.fillWidth: true

                PagesRail {
                    Layout.preferredWidth: parent.width * 0.15
                    Layout.fillHeight: true

                    radius: 5
                    color: "#F9F9F9"
                    model: [
                        {id: 0, title: "General", icon: Style.icons.clock},
                        {id: 0, title: "SSH", icon: Style.icons.clock},
                        {id: 0, title: "Theme", icon: Style.icons.clock},
                    ]
                    expanded: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#F9F9F9"
                    radius: 5
                    clip: true

                    SwipeView {
                        anchors.fill: parent

                        Item {
                        }
                    }
                }

            }
        }
    }
}
