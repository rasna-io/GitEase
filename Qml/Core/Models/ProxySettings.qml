import QtQuick

/*! ***********************************************************************************************
 * ProxySettings
 * Persisted proxy configuration, password included - the password is stored in plaintext here,
 * next to the other proxy fields, so it lands in AppModel's JSON config. Fields mirror
 * ProxyManager's properties; ProxyController keeps this model in sync with the live
 * ProxyManager.
 * ************************************************************************************************/
QtObject {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int    proxyType:    0
    property string host:         ""
    property int    port:         0
    property bool   requiresAuth: false
    property string username:     ""
    property string password:     ""
    property string noProxyList:  ""

    /* Functions
     * ****************************************************************************************/
    function serialize() {
        let data = {
            proxyType: root.proxyType,
            host: root.host,
            port: root.port,
            requiresAuth: root.requiresAuth,
            username: root.username,
            password: root.password,
            noProxyList: root.noProxyList
        }

        return data;
    }

    function deserialize(data : var) {
        root.proxyType = data?.proxyType ?? 0
        root.host = data?.host ?? ""
        root.port = data?.port ?? 0
        root.requiresAuth = data?.requiresAuth ?? false
        root.username = data?.username ?? ""
        root.password = data?.password ?? ""
        root.noProxyList = data?.noProxyList ?? ""
    }
}
