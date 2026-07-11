import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * FileSettings
 * ************************************************************************************************/

Flickable {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string ruleColor: ""

    /* Object Properties
     * ****************************************************************************************/
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 5

        BasicInfoRect {
            ruleColor: root.ruleColor
        }

        RuleChip {
            headerText: "File Restrictions"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Forbidden extensions"
                    subtitle: "Blocks these file types"

                    control: HorizontalTagInput {
                        anchors.fill: parent
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max file size"
                    subtitle: "Megabytes"

                    control: ModernSpinBox {
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "No trailing whitespace"

                    control: ModernSwitch {
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Require final newline"

                    control: ModernSwitch {
                        height: parent.height
                    }
                }
            }
        }

        RuleChip {
            headerText: "Secret Detection"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Secret patterns"
                    subtitle: "Regex per line scanned"
                    rowHeight: verticalTagInput.height + 10

                    control: VerticalTagInput {
                        id: verticalTagInput
                        width: parent.width
                        placeHolderText: "(?i)aws_secret_access_key"
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block conflict markers"

                    control: Rectangle {
                        width: 50
                        height: parent.height
                        Layout.margins: 0
                        color: "transparent"

                        Switch {
                            anchors.fill: parent
                            Material.accent: Style.colors.accent
                            scale: 0.8
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Block WIP commits"

                    control: Rectangle {
                        width: 50
                        height: parent.height
                        Layout.margins: 0
                        color: "transparent"

                        Switch {
                            anchors.fill: parent
                            Material.accent: Style.colors.accent
                            scale: 0.8
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max commits per push"
                    subtitle: "0 = unlimited"
                    control: ModernSpinBox {
                    }
                }
            }
        }
    }
}
