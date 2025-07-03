package app.whiles.spp_serial.constant

enum class ServerConnectState {
    STARTING, CONNECTED, STOPPED
}

enum class ClientConnectState {
    IDLE,
    CONNECTING,
    CONNECTED
}