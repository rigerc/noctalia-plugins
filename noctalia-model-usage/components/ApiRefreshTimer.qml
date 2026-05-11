import QtQuick

// Reusable auto-poll timer for API-backed providers.
// Bind providerEnabled to the provider's enabled condition;
// connect onTick to the fetch function.
Timer {
    id: root

    // Bind to the provider's enabled (and optionally api-key-present) condition.
    property bool providerEnabled: false

    // Interval in minutes. Clamped to [1, 1440] as a safety guard.
    property int intervalMin: 5

    signal tick()

    interval: Math.min(1440, Math.max(1, root.intervalMin)) * 60 * 1000
    running: root.providerEnabled
    repeat: true
    onTriggered: root.tick()
}
