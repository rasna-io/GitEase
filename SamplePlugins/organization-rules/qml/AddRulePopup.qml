import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseOrganizationRulesPlugin

/*! ***********************************************************************************************
 * AddRulePopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var categoriesModel

    /* Signals
     * ****************************************************************************************/
    signal categoryClicked(int index)

    /* Object Properties
     * ****************************************************************************************/
    width: 640
    height: 360
    padding: 0

    contentItem: Rectangle {
        color: Style.colors.popupBackground
        radius: 10
        clip: true
        border.color: Style.colors.popupBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                Layout.leftMargin: 20
                Layout.rightMargin: 16
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Add a rule"
                        color: Style.colors.popupTitleText
                        font.family: Style.fontTypes.inter
                        font.weight: Font.DemiBold
                        font.pixelSize: Style.appFont.mediumPt
                    }

                    Text {
                        text: "Choose what kind of rule you want to enforce in this repository."
                        color: Style.colors.popupSectionLabel
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                    }
                }

                Text {
                    text: "\u00d7"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h2Pt
                    color: closeMouse.containsMouse ? Style.colors.popupCloseButtonHover
                                                    : Style.colors.popupCloseButton

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.popupHeaderSeparator
            }

            GridView {
                id: gridView

                //! Space kept free on the right for the scrollbar plus breathing room.
                readonly property int scrollGutter: contentHeight > height ? 18 : 8

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 14
                Layout.rightMargin: 6
                Layout.topMargin: 14
                Layout.bottomMargin: 14
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                model: root.categoriesModel

                ScrollBar.vertical: RuleScrollBar {}

                cellWidth: (width - scrollGutter) / 2
                cellHeight: 76

                delegate: Item {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    Rectangle {
                        id: categoryCard

                        readonly property color tone: modelData.color

                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 10
                        color: cardMouse.containsMouse ? Style.colors.controlBackgroundHover
                                                       : Style.colors.pluginCardBackground
                        border.width: 1
                        border.color: cardMouse.containsMouse ? Qt.rgba(tone.r, tone.g, tone.b, 0.6)
                                                              : Style.colors.pluginCardBorder

                        Behavior on color { ColorAnimation { duration: Style.motionFast } }
                        Behavior on border.color { ColorAnimation { duration: Style.motionFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            Rectangle {
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 36
                                Layout.alignment: Qt.AlignVCenter
                                radius: 9
                                color: Qt.rgba(categoryCard.tone.r, categoryCard.tone.g, categoryCard.tone.b, 0.14)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon || Style.icons.rules
                                    font.family: Style.fontTypes.font6Pro
                                    font.styleName: "Solid"
                                    font.pixelSize: Style.appFont.mediumPt
                                    color: categoryCard.tone
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 3

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.defaultPt
                                    font.weight: Font.DemiBold
                                    color: Style.colors.pluginCardTitle
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.description
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.captionPt
                                    color: Style.colors.pluginCardDescription
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                Layout.alignment: Qt.AlignVCenter
                                text: Style.icons.plus
                                font.family: Style.fontTypes.font6Pro
                                font.styleName: "Solid"
                                font.pixelSize: Style.appFont.captionPt
                                color: cardMouse.containsMouse ? categoryCard.tone : Style.colors.pluginCardMetaText
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                root.categoryClicked(index)
                                root.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
