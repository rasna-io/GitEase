/*! ***********************************************************************************************
 * GraphUtils Script
 * Practical tools for drawing nodes and graphs
 * ************************************************************************************************/

.pragma library

/* Property Declarations
 * ****************************************************************************************/
// Dynamic color generation for branches and tags
var categoryColorCache = {}

/* Functions
 * ****************************************************************************************/
/**
 * Get color for a graph lane (column)
 * Lane colors are stable within a session and independent of branch names.
 */
/**
 * Deterministic, distinct-ish colors by insertion order.
 * We intentionally avoid branch-name fallbacks (like "main") to prevent
 * deleted/unknown branches sharing colors.
 */
function getCategoryColor(key) {
    if (!key)
        key = "default";

    if (categoryColorCache[key])
        return categoryColorCache[key];

    // Create a visually distinct color using golden angle steps in HSV.
    var index = Object.keys(categoryColorCache).length;
    var hue = (index * 137.508) % 360; // golden angle
    var saturation = 70;
    var lightness = 55;

    var rgb = hslToRgb(hue, saturation, lightness);
    var r = Math.round(rgb.r);
    var g = Math.round(rgb.g);
    var b = Math.round(rgb.b);

    var color = '#' + padString(r.toString(16), 2, '0') +
                padString(g.toString(16), 2, '0') +
                padString(b.toString(16), 2, '0');

    categoryColorCache[key] = color;
    return color;
}

function clearCategoryColorCache() {
    categoryColorCache = {};
}

function formatDate(date) {
    if (!date) return ""
    var d = new Date(date)
    var year = d.getFullYear()
    var month = String(d.getMonth() + 1).padStart(2, '0')
    var day = String(d.getDate()).padStart(2, '0')
    return year + "-" + month + "-" + day
}

function formatTime(date) {
    if (!date) return ""
    var d = new Date(date)
    var hours = String(d.getHours()).padStart(2, '0')
    var minutes = String(d.getMinutes()).padStart(2, '0')
    var seconds = String(d.getSeconds()).padStart(2, '0')
    return hours + ":" + minutes + ":" + seconds
}

function parseDateYYYYMMDD(str) {
    // Returns milliseconds since epoch, or NaN if invalid.
    // Accepts:
    // - YYYY-MM-DD
    // - YYYY/MM/DD (used by GraphViewPage placeholders)
    if (str === null || str === undefined)
        return NaN

    str = ("" + str).trim()
    if (str.length < 8)
        return NaN

    // Split on '-' or '/'
    var parts = str.split(/[-\/]/)
    if (parts.length !== 3)
        return NaN

    var y = parseInt(parts[0])
    var m = parseInt(parts[1])
    var d = parseInt(parts[2])
    if (isNaN(y) || isNaN(m) || isNaN(d))
        return NaN

    // local time midnight
    return new Date(y, m - 1, d, 0, 0, 0, 0).getTime()
}

function findInListModel(listModel, propertyName, value) {
    for (var i = 0; i < listModel.count; i++) {
        var item = listModel.get(i)
        if (item[propertyName] === value) {
            return item
        }
    }
    return null
}

function drawRoundedRect(ctx, x, y, width, height, radius) {
    ctx.beginPath()
    ctx.moveTo(x + radius, y)
    ctx.lineTo(x + width - radius, y)
    ctx.quadraticCurveTo(x + width, y, x + width, y + radius)
    ctx.lineTo(x + width, y + height - radius)
    ctx.quadraticCurveTo(x + width, y + height, x + width - radius, y + height)
    ctx.lineTo(x + radius, y + height)
    ctx.quadraticCurveTo(x, y + height, x, y + height - radius)
    ctx.lineTo(x, y + radius)
    ctx.quadraticCurveTo(x, y, x + radius, y)
    ctx.closePath()
}

function padString(str, length, padChar) {
    str = String(str)
    while (str.length < length) {
        str = padChar + str
    }
    return str
}

function lightenColor(color, amount) {
    var hex = color.replace('#', '')
    var r = parseInt(hex.substr(0, 2), 16)
    var g = parseInt(hex.substr(2, 2), 16)
    var b = parseInt(hex.substr(4, 2), 16)

    r = Math.min(255, Math.floor(r + (255 - r) * amount))
    g = Math.min(255, Math.floor(g + (255 - g) * amount))
    b = Math.min(255, Math.floor(b + (255 - b) * amount))

    return '#' + padString(r.toString(16), 2, '0') +
           padString(g.toString(16), 2, '0') +
           padString(b.toString(16), 2, '0')
}

function darkenColor(color, amount) {
    var hex = color.replace('#', '')
    var r = parseInt(hex.substr(0, 2), 16)
    var g = parseInt(hex.substr(2, 2), 16)
    var b = parseInt(hex.substr(4, 2), 16)

    r = Math.max(0, Math.floor(r * (1 - amount)))
    g = Math.max(0, Math.floor(g * (1 - amount)))
    b = Math.max(0, Math.floor(b * (1 - amount)))

    return '#' + padString(r.toString(16), 2, '0') +
           padString(g.toString(16), 2, '0') +
           padString(b.toString(16), 2, '0')
}

// New function to get contrasting text color
function getContrastColor(backgroundColor) {
    var hex = backgroundColor.replace('#', '')
    var r = parseInt(hex.substr(0, 2), 16)
    var g = parseInt(hex.substr(2, 2), 16)
    var b = parseInt(hex.substr(4, 2), 16)

    // Calculate luminance
    var luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

    return luminance > 0.5 ? "#000000" : "#ffffff"
}

/**
 * Convert HSL color values to RGB
 * @param h - Hue (0-360)
 * @param s - Saturation (0-100)
 * @param l - Lightness (0-100)
 * @returns Object with r, g, b values (0-255)
 */
function hslToRgb(h, s, l) {
    // Normalize values
    h = h / 360;
    s = s / 100;
    l = l / 100;
    
    var r, g, b;
    
    if (s === 0) {
        // Achromatic (grey)
        r = g = b = l;
    } else {
        var hue2rgb = function(p, q, t) {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1/6) return p + (q - p) * 6 * t;
            if (t < 1/2) return q;
            if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
            return p;
        };
        
        var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        var p = 2 * l - q;
        
        r = hue2rgb(p, q, h + 1/3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1/3);
    }
    
    return {
        r: r * 255,
        g: g * 255,
        b: b * 255
    };
}
