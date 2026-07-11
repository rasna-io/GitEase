import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * BranchNamingSettings
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
            headerText: "Name Rules"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Allowed prefixes"

                    control: HorizontalTagInput {
                        anchors.fill: parent
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Max name length"
                    subtitle: "Characters"
                    control: ModernSpinBox {
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Forbidden: spaces"

                    control: ModernSwitch {
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Forbidden: uppercase"

                    control: ModernSwitch {
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Forbidden: special chars"

                    control: ModernSwitch {
                        height: parent.height
                    }
                }
            }
        }

        RuleChip {
            headerText: "Branch Protection"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Ticket reference"
                    subtitle: "Required in branch name"

                    control: RowLayout {
                        anchors.fill: parent

                        ModernSwitch {
                            Layout.fillHeight: true
                        }

                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "[A-Z]+-\d+"
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
                    title: "Protected branches"
                    subtitle: "Glob patterns"

                    control: HorizontalTagInput {
                        anchors.fill: parent
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Auto-delete after merge"
                    subtitle: "Clean up merged branches"

                    control: ModernSwitch {
                        height: parent.height
                    }
                }
            }
        }
    }
}
