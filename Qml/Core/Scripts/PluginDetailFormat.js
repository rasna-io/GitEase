.pragma library

/*! ***********************************************************************************************
 * PluginDetailFormat
 * Text helpers shared by the plugin detail components.
 * ************************************************************************************************/

function formatCount(n) {
    if(n >= 1000000) {
        return (n / 1000000).toFixed(n >= 10000000 ? 0 : 1).replace(/\.0$/, "") + "M"
    }

    if(n >= 1000) {
        return (n / 1000).toFixed(n >= 10000 ? 0 : 1).replace(/\.0$/, "") + "k"
    }

    return String(n)
}

function featureTitle(f) {
    if(typeof f === "string") {
        return f
    }

    return f?.title || f?.name || f?.description || ""
}

function featureDescription(f) {
    if(typeof f === "string" || !(f?.title || f?.name)) {
        return ""
    }

    return f?.description || ""
}

function changeNotes(entry) {
    let notes = entry?.notes ?? entry?.changes ?? ""
    const isList = typeof notes !== "string" && notes && typeof notes.length === "number"

    if(isList) {
        return Array.from(notes).map(function(n) {
            return "- " + n
        }).join("\n")
    }

    return notes
}

function withAlpha(color, alpha) {
    return Qt.rgba(color.r, color.g, color.b, alpha)
}
