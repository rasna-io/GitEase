import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * UseAsDefaultDialog
 * "Use as default" makes a user the global one. The open repository has its own user, though,
 * and git prefers that one there. Asks whether to keep it, or use the new default here too.
 * Closing the dialog cancels; nothing is changed then.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string repositoryName:     ""
    property string repositoryUserName: ""
    property string defaultUserName:    ""

    /* Signals
     * ****************************************************************************************/
    //! Make the user the default, and leave the repository's own user as it is.
    signal keepRepositoryUser()

    //! Make the user the default, and remove the repository's own user so it follows the default.
    signal useHereToo()

    /* Object Properties
     * ****************************************************************************************/
    width: 440
    height: contentItem.implicitHeight
    padding: 0

    closePolicy: Popup.CloseOnEscape

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        implicitHeight: layout.implicitHeight
        color: Style.colors.popupBackground
        radius: 8
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                spacing: 8

                Text {
                    text: qsTr("Use %1 as default").arg(root.defaultUserName)
                    color: Style.colors.popupTitleText
                    font.family: Style.fontTypes.inter
                    font.weight: Font.DemiBold
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: "×"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.mediumPt
                    color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                    : Style.colors.popupCloseButton
                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 16
                Layout.bottomMargin: 16
                text: qsTr("%1 has its own user (%2). Use %3 here too?")
                      .arg(root.repositoryName !== "" ? root.repositoryName : qsTr("This repository"))
                      .arg(root.repositoryUserName)
                      .arg(root.defaultUserName)
                color: Style.colors.popupCheckboxLabelText
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.defaultPt
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            // Footer
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 18
                Layout.rightMargin: 18
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                spacing: 8

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    id: keepButton
                    text: qsTr("Keep %1").arg(root.repositoryUserName)
                    Layout.maximumWidth: 170
                    Layout.alignment: Qt.AlignVCenter
                    topPadding: 6
                    bottomPadding: 6
                    leftPadding: 14
                    rightPadding: 14

                    background: Rectangle {
                        implicitHeight: 32
                        color: "transparent"
                        border.color: Style.colors.popupCancelButtonBorder
                        border.width: 1
                        radius: 5
                        opacity: keepButton.hovered ? 1.0 : 0.7
                    }

                    contentItem: Text {
                        text: keepButton.text
                        color: Style.colors.popupCancelButtonText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    onClicked: {
                        root.close()
                        root.keepRepositoryUser()
                    }
                }

                Button {
                    id: useHereButton
                    text: qsTr("Use %1 here").arg(root.defaultUserName)
                    Layout.maximumWidth: 170
                    Layout.alignment: Qt.AlignVCenter
                    topPadding: 6
                    bottomPadding: 6
                    leftPadding: 16
                    rightPadding: 16

                    background: Rectangle {
                        implicitHeight: 32
                        color: useHereButton.hovered ? Style.colors.accentHover : Style.colors.accent
                        radius: 5
                    }

                    contentItem: Text {
                        text: useHereButton.text
                        color: Style.colors.onAccentText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    onClicked: {
                        root.close()
                        root.useHereToo()
                    }
                }
            }
        }
    }
}
