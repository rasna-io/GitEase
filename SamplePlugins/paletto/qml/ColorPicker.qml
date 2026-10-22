import QtQuick
import QtQuick.Layouts

/*! ***********************************************************************************************
 * ColorPicker
 * Saturation / value area, hue bar and opacity bar. Emits edited() on every drag step so the
 * page can apply the color live.
 *
 *   ColorPicker {
 *       hex: "#2563eb"                       // "#rrggbb" or "#aarrggbb"
 *       onEdited: function(hex) { ... }
 *   }
 * ************************************************************************************************/
Item {
    id: root

    //! The editor colors and fonts, passed in by PalettoPage.
    required property PalettoChrome chrome

    /* Property Declarations
     * ****************************************************************************************/
    property string hex: "#000000"

    /* Signals
     * ****************************************************************************************/
    signal edited(string hex)

    //! Hue is kept separately: grays and blacks have no hue, and dragging would lose it.
    property real hue:   0
    property real sat:   0
    property real val:   0
    property real alpha: 1

    //! True while an edit made here travels through the page and comes back as `hex`.
    property bool emittingEdit: false

    implicitHeight: column.implicitHeight

    /* Functions
     * ****************************************************************************************/
    function sync() {
        const c = Qt.color(root.hex)
        if(c.hsvHue >= 0) {
            root.hue = c.hsvHue
        }
        root.sat = c.hsvSaturation
        root.val = c.hsvValue
        root.alpha = c.a
    }

    function clamp01(x) {
        return Math.max(0, Math.min(1, x))
    }

    function hex2(x) {
        const s = Math.round(clamp01(x) * 255).toString(16)
        return s.length < 2 ? "0" + s : s
    }

    function commit() {
        const c = Qt.hsva(root.hue, root.sat, root.val, root.alpha)
        const rgb = hex2(c.r) + hex2(c.g) + hex2(c.b)
        const out = root.alpha >= 0.995 ? "#" + rgb : "#" + hex2(root.alpha) + rgb

        root.emittingEdit = true
        root.edited(out)
        root.emittingEdit = false
    }

    onHexChanged: {
        if(!root.emittingEdit) {
            root.sync()
        }
    }
    Component.onCompleted: root.sync()

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 12

        // Saturation / value
        Rectangle {
            id: saturationValueArea
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(120, Math.round(width * 0.62))
            color: Qt.hsva(root.hue, 1, 1, 1)
            border.width: 1
            border.color: root.chrome.border

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(1, 1, 1, 1)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(1, 1, 1, 0)
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(0, 0, 0, 0)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(0, 0, 0, 1)
                    }
                }
            }

            Rectangle {
                x: root.sat * saturationValueArea.width - width / 2
                y: (1 - root.val) * saturationValueArea.height - height / 2
                width: 16
                height: 16
                radius: 8
                color: "transparent"
                border.width: 2
                border.color: "#FFFFFF"

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: "#66000000"
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                preventStealing: true

                function pick(mouse) {
                    root.sat = root.clamp01(mouse.x / width)
                    root.val = 1 - root.clamp01(mouse.y / height)
                    root.commit()
                }

                onPressed: function(mouse) {
                    pick(mouse)
                }
                onPositionChanged: function(mouse) {
                    if(pressed) {
                        pick(mouse)
                    }
                }
            }
        }

        // Hue
        Rectangle {
            id: hueBar
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            radius: 7
            border.width: 1
            border.color: root.chrome.border

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.000
                    color: "#FF0000"
                }
                GradientStop {
                    position: 0.167
                    color: "#FFFF00"
                }
                GradientStop {
                    position: 0.333
                    color: "#00FF00"
                }
                GradientStop {
                    position: 0.500
                    color: "#00FFFF"
                }
                GradientStop {
                    position: 0.667
                    color: "#0000FF"
                }
                GradientStop {
                    position: 0.833
                    color: "#FF00FF"
                }
                GradientStop {
                    position: 1.000
                    color: "#FF0000"
                }
            }

            Rectangle {
                x: root.hue * (hueBar.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 20
                radius: 4
                color: Qt.hsva(root.hue, 1, 1, 1)
                border.width: 2
                border.color: root.chrome.text
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true

                function pick(mouse) {
                    root.hue = root.clamp01(mouse.x / width)
                    root.commit()
                }

                onPressed: function(mouse) {
                    pick(mouse)
                }
                onPositionChanged: function(mouse) {
                    if(pressed) {
                        pick(mouse)
                    }
                }
            }
        }

        // Opacity
        Rectangle {
            id: alphaBar
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            radius: 7
            color: root.chrome.checkerDark
            border.width: 1
            border.color: root.chrome.border

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 6
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.hsva(root.hue, root.sat, root.val, 0)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.hsva(root.hue, root.sat, root.val, 1)
                    }
                }
            }

            Rectangle {
                x: root.alpha * (alphaBar.width - width)
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 20
                radius: 4
                color: root.chrome.panelRaised
                border.width: 2
                border.color: root.chrome.text
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true

                function pick(mouse) {
                    root.alpha = root.clamp01(mouse.x / width)
                    root.commit()
                }

                onPressed: function(mouse) {
                    pick(mouse)
                }
                onPositionChanged: function(mouse) {
                    if(pressed) {
                        pick(mouse)
                    }
                }
            }
        }
    }
}
