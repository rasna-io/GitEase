import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import "qrc:/GitEase/Qml/Core/Scripts/PluginDetailFormat.js" as Format

/*! ***********************************************************************************************
 * PluginDetailOverview
 * Overview tab: screenshots, about text, feature highlights and the getting started guide.
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string pluginId: ""
    property var    screenshots: []
    property string aboutText: ""
    property string installGuide: ""
    property var    features: []
    property color  tint: Style.colors.accent

    readonly property int  highlightCount: 4
    readonly property bool hasContent: root.screenshots.length > 0
                                       || root.aboutText.length > 0
                                       || root.installGuide.length > 0
                                       || root.features.length > 0

    /* Signals
     * ****************************************************************************************/
    signal seeAllFeaturesRequested()

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    spacing: Style.dp(16)

    /* Children
     * ****************************************************************************************/
    PluginDetailGallery {
        visible: root.screenshots.length > 0
        pluginId: root.pluginId
        screenshots: root.screenshots
        tint: root.tint
    }

    PluginDetailCard {
        visible: root.aboutText.length > 0
        title: "About"
        iconText: Style.icons.info
        tint: root.tint

        PluginDetailRichText {
            text: root.aboutText
        }
    }

    PluginDetailCard {
        visible: root.features.length > 0
        title: "Highlights"
        iconText: Style.icons.circleCheck
        tint: root.tint
        trailing: root.features.length > root.highlightCount
                  ? ("+" + (root.features.length - root.highlightCount) + " more") : ""

        Repeater {
            model: root.features.slice(0, root.highlightCount)

            delegate: RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(10)

                Text {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Style.dp(3)
                    text: Style.icons.check
                    font.family: Style.fontTypes.font6Pro
                    font.styleName: "Solid"
                    font.pixelSize: Style.appFont.captionPt
                    color: root.tint
                }

                Label {
                    Layout.fillWidth: true
                    text: Format.featureTitle(modelData)
                    color: Style.colors.pluginCardDescription
                    font.pixelSize: Style.appFont.mediumPt
                    font.family: Style.fontTypes.inter
                    wrapMode: Text.WordWrap
                }
            }
        }

        PluginDetailLink {
            visible: root.features.length > root.highlightCount
            text: "See all features"
            tint: root.tint

            onClicked: root.seeAllFeaturesRequested()
        }
    }

    PluginDetailCard {
        visible: root.installGuide.length > 0
        title: "Getting started"
        iconText: Style.icons.list
        tint: root.tint

        PluginDetailRichText {
            text: root.installGuide
        }
    }

    PluginDetailCard {
        visible: !root.hasContent

        Label {
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(12)
            Layout.bottomMargin: Style.dp(12)
            text: "The author hasn't provided a description for this plugin yet."
            color: Style.colors.pluginCardMetaText
            font.pixelSize: Style.appFont.mediumPt
            font.family: Style.fontTypes.inter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
