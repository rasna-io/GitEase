import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

Flickable {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property color ruleColor

    /* Object Properties
     * ****************************************************************************************/
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 5

        BasicInfoRect {
            ruleColor: root.ruleColor
        }

        RuleChip {
            headerText: "Length & Format"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Min Length"
                    subtitle: "Subject line chars"
                    control: ModernSpinBox {
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max Length"
                    subtitle: "Subject line chars"
                    control: ModernSpinBox {
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Require Prefix"
                    subtitle: "feat|fix|chore..."

                    control: RowLayout {
                        anchors.fill: parent

                        Rectangle {
                            id: rowRect
                            Layout.preferredWidth: 50
                            Layout.fillHeight: true
                            Layout.margins: 0
                            color: "transparent"

                            Switch {
                                anchors.fill: parent
                                Material.accent: Style.colors.accent
                                scale: 0.8
                            }
                        }

                        HorizontalTagInput {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "No trailing period"

                    control: Rectangle {
                        width: 50
                        height: parent.height
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
                    title: "Imperative verb"
                    subtitle: "First word must be a verb"

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
            }
        }

        RuleChip {
            headerText: "References & Body"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Forbidden words"
                    subtitle: "Blocks if subject contains"

                    control: HorizontalTagInput {
                        anchors.fill: parent
                        color: Style.colors.secondaryBackground
                        radius: 5
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Ticket reference"
                    subtitle: "Regex, e.g. JIRA-\d+"

                    control: RowLayout {
                        anchors.fill: parent

                        Rectangle {
                            Layout.preferredWidth: 50
                            Layout.fillHeight: true
                            Layout.margins: 0
                            color: "transparent"

                            Switch {
                                anchors.fill: parent
                                Material.accent: Style.colors.accent
                                scale: 0.8
                            }
                        }

                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "JIRA-\d+"
                            selectByMouse: true

                            background: Rectangle {
                                color: Style.colors.secondaryBackground
                                radius: 5
                            }
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Body separator"

                    control: RowLayout {
                        anchors.fill: parent

                        Rectangle {
                            Layout.preferredWidth: 50
                            Layout.fillHeight: true
                            Layout.margins: 0
                            color: "transparent"

                            Switch {
                                anchors.fill: parent
                                Material.accent: Style.colors.accent
                                scale: 0.8
                            }
                        }

                        Text {
                            text: "Blank line required between subject and body"
                            font.family: Style.fontTypes.roboto
                            color: Style.colors.mutedText
                            font.pixelSize: 12
                        }

                        Item {
                            Layout.fillWidth: true
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Min Length"
                    subtitle: "Subject line chars"
                    control: ModernSpinBox {
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Require Signed-off-by"

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
            }
        }

        RuleChip {
            headerText: "Custom Validator (Optional)"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Regex pattern"
                    subtitle: "Tested against full message"

                    control: TextField {
                        anchors.fill: parent
                        placeholderText: "^(feat|fix)\(.+\):.+"
                        selectByMouse: true

                        background: Rectangle {
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Error message"

                    control: TextField {
                        anchors.fill: parent
                        placeholderText: "Commit message must match ..."
                        selectByMouse: true

                        background: Rectangle {
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
                    }
                }
            }
        }

    }
}
