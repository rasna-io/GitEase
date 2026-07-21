import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * SettingsPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool       showRawOutput: true

    property var        results:        []

    property string     titleText:      "Fetch Summary"

    property string     subtitleText:   ""

    readonly property color infoAccent:    Style.colors.notificationInfoIcon

    readonly property color successAccent: Style.colors.notificationSuccessIcon

    readonly property color errorAccent:   Style.colors.notificationErrorIcon


    /* Object Properties
     * ****************************************************************************************/
    modal: true
    focus: true

    width: showRawOutput ? Math.min(parent ? parent.width * 0.9 : 1100, 1150)
                         : Math.min(parent ? parent.width * 0.65 : 700, 750)
    height: Math.min(parent ? parent.height * 0.85 : 700, 800)

    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

    onOpened: subtitleText = Qt.formatDateTime(new Date(), "MMM dd, yyyy • hh:mm ap")

    background: Rectangle {
        color: Style.colors.primaryBackground
        radius: 20
        border.color: Style.colors.primaryBorder
        layer.enabled: true
        layer.effect: DropShadow {
            transparentBorder: true; radius: 28; samples: 36; color: "#60000000"; verticalOffset: 12
        }
    }

    /* Children
     * ****************************************************************************************/

    contentItem: ColumnLayout {
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 16

                Text {
                    text: titleText
                    color: Style.colors.foreground
                    font.pixelSize: Style.appFont.xlPt
                    font.weight: Font.Bold
                }

                Rectangle {
                    width: 1;
                    height: 16;
                    color: Style.colors.primaryBorder;
                    Layout.leftMargin: 4
                }

                Text {
                    text: subtitleText
                    color: Style.colors.mutedText
                    font.pixelSize: Style.appFont.mediumPt
                    Layout.fillWidth: true
                }

                Row {
                    spacing: 8
                    StatChip {
                        label: "Total";
                        value: results.length;
                        accent: root.infoAccent
                    }
                    StatChip {
                        label: "Success";
                        value: successCount(results);
                        accent: root.successAccent;
                        visible: value > 0
                    }
                    StatChip {
                        label: "Failed";
                        value: failureCount(results);
                        accent: root.errorAccent;
                        visible: value > 0
                    }
                }

                Button {
                    id: closeBtn; flat: true; onClicked: root.close()
                    contentItem: Text {
                        text: "✕";
                        color: closeBtn.hovered ? Style.colors.foreground : Style.colors.mutedText;
                        font.pixelSize: Style.appFont.h2Pt
                    }
                    background: Rectangle {
                        implicitWidth: 32;
                        implicitHeight: 32;
                        radius: 8;
                        color: closeBtn.hovered ? Style.colors.surfaceLight : "transparent"
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            Layout.preferredHeight: 44
            color: Style.colors.secondaryBackground
            border.color: Style.colors.primaryBorder
            border.width: 1


            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                CheckBox {
                    id: rawLogCheck
                    checked: root.showRawOutput
                    text: "Show Raw Terminal Output"
                    onCheckedChanged: root.showRawOutput = checked
                    Material.accent: Style.colors.accent
                    Material.foreground: Style.colors.foreground

                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "View: " + (root.showRawOutput ? "Standard" : "Compact")
                    font.pixelSize: Style.appFont.smallPt
                    color: Style.colors.mutedText
                    font.capitalization: Font.AllUppercase
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: 20
            Layout.rightMargin: 20
            spacing: 0

            ScrollView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                ListView {
                    model: results; spacing: 10
                    topMargin: 20; bottomMargin: 20; leftMargin: 20; rightMargin: 20

                    delegate: Rectangle {
                        width: ListView.view.width - 40
                        implicitHeight: cardCol.implicitHeight + 24
                        radius: 12; color: Style.colors.secondaryBackground
                        border.color: Style.colors.primaryBorder

                        ColumnLayout {
                            id: cardCol; anchors.fill: parent; anchors.margins: 16; spacing: 10
                            RowLayout {
                                Text {
                                    text: modelData.remote; font.weight: Font.DemiBold
                                    font.pixelSize: Style.appFont.h3Pt; color: Style.colors.foreground
                                }
                                Rectangle {
                                    width: 4;
                                    height: 4;
                                    radius: 2;
                                    color: Style.colors.primaryBorder
                                }
                                Text {
                                    text: modelData.success ? "Successfully fetched" : "Fetch failed"
                                    font.pixelSize: Style.appFont.mediumPt;
                                    color: modelData.success ? root.successAccent : root.errorAccent
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: shortSha(modelData.data.timestamp);
                                    font.pixelSize: Style.appFont.defaultPt;
                                    color: Style.colors.mutedText
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 4
                                visible: modelData.data.heads.length > 0
                                Repeater {
                                    model: modelData.data.heads
                                    delegate: RowLayout {
                                        Text { text: "•"; color: root.infoAccent }
                                        Text {
                                            text: modelData.summary.trim()
                                            font.family: Style.fontTypes.jetBrainsMono; font.pixelSize: Style.appFont.defaultPt
                                            color: Style.colors.secondaryText; Layout.fillWidth: true; elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true

                Layout.preferredWidth: root.showRawOutput ? 380 : 0
                color: Style.colors.secondaryBackground
                clip: true
                visible: root.showRawOutput

                Behavior on Layout.preferredWidth { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 12
                    Text { text: "RAW TERMINAL LOG"; font.pixelSize: Style.appFont.smallPt; font.weight: Font.Black; color: Style.colors.mutedText; font.letterSpacing: 1 }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Style.colors.primaryBorder }

                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        Text {
                            width: parent.width; text: logText(results)
                            font.family: Style.fontTypes.jetBrainsMono; font.pixelSize: Style.appFont.defaultPt; color: Style.colors.secondaryText; wrapMode: Text.Wrap; lineHeight: 1.4
                        }
                    }
                }
            }
        }
    }

    // --- SHARED COMPONENTS ---
    component StatChip : Rectangle {
        property string label; property string value; property color accent
        implicitWidth: statRow.implicitWidth + 20; implicitHeight: 28; radius: 6
        color: Qt.rgba(accent.r, accent.g, accent.b, 0.08)
        border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.15)
        RowLayout { id: statRow; anchors.centerIn: parent; spacing: 6
            Text { text: label; color: Style.colors.mutedText; font.pixelSize: Style.appFont.smallPt }
            Text { text: value; color: accent; font.pixelSize: Style.appFont.defaultPt; font.weight: Font.Bold }
        }
    }

    /* Functions
     * ****************************************************************************************/

    function successCount(arr) {
        return arr ? arr.filter(i => i.success).length : 0
    }

    function failureCount(arr) {
        return arr ? arr.filter(i => !i.success).length : 0
    }

    function shortSha(ts) {
        return ts ? ts.split('T')[1].substring(0,5) : ""
    }

    function logText(res) {
        let lines = [];
        res.forEach(r => { if(r.data && r.data.log) lines = lines.concat(r.data.log) });
        return lines.length ? lines.join("\n") : "No output recorded."
    }
}
