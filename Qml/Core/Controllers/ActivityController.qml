import QtQuick

QtObject{

    property var activities: []
    property int maxEntries: 100

    function addActivity(command){
        if (!command || command.trim().length === 0)
            return

        let updated = activities.slice(0)
        updated.unshift({
            command: command,
            time: new Date()
        })

        if (updated.length > maxEntries)
            updated = updated.slice(0, maxEntries)

        activities = updated
    }
}
