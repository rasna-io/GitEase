import QtQuick

/*! ***********************************************************************************************
 * StripedBackground
 * ************************************************************************************************/
Canvas {
    id: root


    /* Property Declarations
     * ****************************************************************************************/
    property color backgroundColor: "transparent"

    property color stripeColor: Qt.rgba(0, 0, 0, 0.15)

    property real stripeWidth: 8.0

    /* Object Properties
     * ****************************************************************************************/
    onPaint: {
        var ctx = getContext("2d");
        ctx.reset();

        ctx.fillStyle = backgroundColor;
        ctx.fillRect(0, 0, width, height);

        ctx.strokeStyle = stripeColor;
        ctx.lineWidth = 1;

        var step = stripeWidth;
        for (var i = -height; i < width; i += step) {
            ctx.beginPath();
            ctx.moveTo(i, 0);
            ctx.lineTo(i + height, height);
            ctx.stroke();
        }
    }

    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
