import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * PopupDialog
 * The shared frame for the app's dialog popups: a header with an optional icon, the title and a
 * close button, a body, and a footer of right-aligned PopupButtons. Background, border, shadow,
 * dividers and spacing come from here, so every dialog built on it looks the same.
 *
 * The height follows the content. Escape and the close button close the popup.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title:      ""

    property string iconText:   ""
    property color  iconColor:  Style.colors.accent

    property Item   initialFocusItem: null

    property bool   hasCancel:      true
    property string cancelText:     "Cancel"
    property string cancelTooltip:  ""

    property alias  bodySpacing: body.spacing

    readonly property int elementSpacing: 2

    default property alias bodyData: body.data

    property alias  actions:    actionsRow.data

    /* Signals
     * ****************************************************************************************/
    signal dismissed()

    /* Object Properties
     * ****************************************************************************************/
    width: 380
    height: contentItem.implicitHeight
    padding: 0

    onOpened: {
        if (root.initialFocusItem)
            root.initialFocusItem.forceActiveFocus()
    }

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        radius: 8
        color: Style.colors.popupBackground
        border.color: Style.colors.popupBorder
        border.width: 1

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Style.colors.popupShadow
            shadowBlur: 1.0
            shadowVerticalOffset: 8
            blurMax: 32
        }
    }

    contentItem: ColumnLayout {
        spacing: 0

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            spacing: 8

            Text {
                visible: root.iconText !== ""
                text: root.iconText
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.mediumPt
                color: root.iconColor
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                textFormat: Text.PlainText
                color: Style.colors.popupTitleText
                font.family: Style.fontTypes.inter
                font.weight: Font.DemiBold
                font.pixelSize: Style.appFont.mediumPt
                elide: Text.ElideRight
            }

            Text {
                text: "\u00d7"
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.mediumPt
                color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                : Style.colors.popupCloseButton

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.closeButtonClicked()
                        root.close()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Style.colors.popupHeaderSeparator
        }

        // Body
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.topMargin: 16
            Layout.bottomMargin: 16
            spacing: 12
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            visible: footer.visible
            color: Style.colors.popupHeaderSeparator
        }

        // Footer
        RowLayout {
            id: footer
            Layout.fillWidth: true
            Layout.leftMargin: 18
            Layout.rightMargin: 18
            Layout.topMargin: 18
            Layout.bottomMargin: 18
            visible: actionsRow.children.length > 0
            spacing: 0

            Item {
                Layout.fillWidth: true
            }

            RowLayout {
                id: actionsRow
                spacing: 8
            }
        }
    }
}
