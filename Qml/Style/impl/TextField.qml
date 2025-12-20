import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl

import GitEase_Style

/*! ***********************************************************************************************
 * TextField
 * Custom TextField component with automatic sizing, icon support, and error state
 * ************************************************************************************************/
T.TextField {
    id: control

    /* Property Declarations
     * ****************************************************************************************/
    // Visual properties
    property bool error: false
    property string icon: ""
    
    // Customization properties
    property color backgroundColor: Style.colors.surfaceLight
    property color borderColor: Style.colors.primaryBorder
    property color focusBorderColor: Style.colors.accent
    property color errorBorderColor: Style.colors.error
    property int borderRadius: 5
    property int baseFontSize: 12
    
    // Icon properties
    property string iconFontFamily: Style.fontTypes.font6Pro
    property int iconSize: 18
    property color iconColor: Style.colors.mutedText
    
    /* Internal Automatic Calculations
     * ****************************************************************************************/
    readonly property int _horizontalPadding: baseFontSize
    readonly property int _verticalPadding: Math.max(8, baseFontSize * 0.7)
    readonly property int _iconLeftMargin: 12
    readonly property int _iconTotalSpace: icon !== "" ? (iconSize + _iconLeftMargin * 2) : 0
    
    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: Math.max(200, contentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(38, contentHeight + topPadding + bottomPadding)

    // Automatic padding based on icon presence
    leftPadding: icon !== "" ? _iconTotalSpace : _horizontalPadding
    rightPadding: _horizontalPadding
    topPadding: _verticalPadding
    bottomPadding: _verticalPadding

    // Text colors
    color: enabled ? Style.colors.foreground : Style.colors.mutedText
    selectionColor: Style.colors.accent
    selectedTextColor: "white"
    placeholderTextColor: Style.colors.placeholderText
    verticalAlignment: TextInput.AlignVCenter
    
    // Font setup
    font.pixelSize: baseFontSize
    font.family: Style.fontTypes.roboto
    font.weight: 400

    /* Placeholder Text
     * ****************************************************************************************/
    PlaceholderText {
        id: placeholder
        x: control.leftPadding
        y: control.topPadding
        width: control.width - (control.leftPadding + control.rightPadding)
        height: control.height - (control.topPadding + control.bottomPadding)

        text: control.placeholderText
        font: control.font
        color: control.error ? control.errorBorderColor : control.placeholderTextColor
        verticalAlignment: control.verticalAlignment
        visible: !control.length && !control.preeditText && !control.activeFocus
        elide: Text.ElideRight
        renderType: control.renderType
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    /* Icon
     * ****************************************************************************************/
    Text {
        id: iconText
        visible: control.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: control._iconLeftMargin
        anchors.verticalCenter: parent.verticalCenter
        text: control.icon
        font.family: control.iconFontFamily
        font.pixelSize: control.iconSize
        color: control.error ? control.errorBorderColor : control.iconColor
        
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }

    /* Background
     * ****************************************************************************************/
    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 38
        radius: control.borderRadius
        border.width: control.activeFocus ? 2 : 1
        color: control.backgroundColor
        border.color: control.error ? control.errorBorderColor
                        : control.activeFocus ? control.focusBorderColor 
                        : control.borderColor
        
        Behavior on border.width {
            NumberAnimation { duration: 150 }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }
    }
}
