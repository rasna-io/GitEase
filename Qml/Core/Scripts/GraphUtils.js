/*! ***********************************************************************************************
 * GraphUtils Script
 * Practical tools for drawing nodes and graphs
 * ************************************************************************************************/

/* Property Declarations
 * ****************************************************************************************/
// Dynamic color generation for branches and tags
var branchColorCache = {}
var tagColorCache = {}
var colorIndex = 0

// Modern color palette for better visual appeal
var colorPalette = [
    "#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7",
    "#DDA0DD", "#98D8C8", "#F7DC6F", "#BB8FCE", "#85C1E2",
    "#F8B739", "#52B788", "#E76F51", "#8E44AD", "#3498DB",
    "#E74C3C", "#1ABC9C", "#F39C12", "#9B59B6", "#2ECC71",
    "#E67E22", "#34495E", "#16A085", "#27AE60", "#2980B9",
    "#8E44AD", "#C0392B", "#D35400", "#7F8C8D", "#17202A"
]

/* Functions
 * ****************************************************************************************/
function getBranchColor(branchName) {
    if (branchColorCache[branchName]) {
        return branchColorCache[branchName]
    }

    // Check for predefined colors first
    var predefinedColors = {
        "main": "#4a9eff",
        "develop": "#00ff88",
        "master": "#4a9eff",
        "dev": "#00ff88"
    }

    if (predefinedColors[branchName]) {
        branchColorCache[branchName] = predefinedColors[branchName]
        return predefinedColors[branchName]
    }

    // Generate dynamic color based on branch name hash
    var hash = 0
    for (var i = 0; i < branchName.length; i++) {
        hash = branchName.charCodeAt(i) + ((hash << 5) - hash)
    }

    var colorIndex = Math.abs(hash) % colorPalette.length
    var color = colorPalette[colorIndex]
    branchColorCache[branchName] = color

    return color
}

function getTagColor(tagName) {
    if (tagColorCache[tagName]) {
        return tagColorCache[tagName]
    }

    // Check for predefined colors first
    var predefinedColors = {
        "v1.0.0": "#ff00aa",
        "v1.1.0": "#aa00ff",
        "v1.2.0": "#00aaff",
        "v2.0.0": "#51cf66",
        "latest": "#ffd700",
        "stable": "#00ff00"
    }

    if (predefinedColors[tagName]) {
        tagColorCache[tagName] = predefinedColors[tagName]
        return predefinedColors[tagName]
    }

    // Generate dynamic color based on tag name hash (different palette offset)
    var hash = 0
    for (var i = 0; i < tagName.length; i++) {
        hash = tagName.charCodeAt(i) + ((hash << 5) - hash)
    }

    var colorIndex = (Math.abs(hash) + 15) % colorPalette.length // Offset for variety
    var color = colorPalette[colorIndex]
    tagColorCache[tagName] = color

    return color
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
