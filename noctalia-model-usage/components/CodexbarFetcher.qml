import QtQuick
import Quickshell.Io

Item {
    id: root
    visible: false

    property string codexbarProvider: ""
    property bool running: proc.running
    property bool _fetchActive: false
    property bool _completed: false
    property bool _queuedFetch: false
    property string _stdout: ""
    property string _stderr: ""
    property int timeoutMs: 30000

    signal dataReady(var result)
    signal fetchError(string message)

    function fetch() {
        if (!root.codexbarProvider)
            return;

        if (proc.running || root._fetchActive) {
            root._queuedFetch = true;
            return;
        }

        root._fetchActive = true;
        root._completed = false;
        root._stdout = "";
        root._stderr = "";
        proc.running = true;
        timeoutTimer.restart();
    }

    function runQueuedFetchIfNeeded() {
        if (!root._queuedFetch)
            return;
        root._queuedFetch = false;
        root.fetch();
    }

    function completeWithError(message) {
        if (!root._fetchActive || root._completed)
            return;
        timeoutTimer.stop();
        root._completed = true;
        root._fetchActive = false;
        root.fetchError(message);
        queueDrainTimer.restart();
    }

    function completeWithData(result) {
        if (!root._fetchActive || root._completed)
            return;
        timeoutTimer.stop();
        root._completed = true;
        root._fetchActive = false;
        root.dataReady(result);
        queueDrainTimer.restart();
    }

    Timer {
        id: timeoutTimer
        interval: root.timeoutMs
        repeat: false
        onTriggered: {
            if (!root._fetchActive || root._completed)
                return;
            proc.running = false;
            root.completeWithError("codexbar timed out");
        }
    }

    Timer {
        id: queueDrainTimer
        interval: 1
        repeat: false
        onTriggered: root.runQueuedFetchIfNeeded()
    }

    Process {
        id: proc
        command: ["codexbar", "usage", "--provider", root.codexbarProvider, "--json-only", "--no-color"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root._fetchActive)
                    return;

                root._stdout = text.trim();
                if (!root._stdout)
                    return;

                try {
                    const parsed = JSON.parse(root._stdout);
                    const item = Array.isArray(parsed) ? parsed[0] : parsed;
                    if (item?.error)
                        root.completeWithError(item.error.message ?? "codexbar error");
                    else
                        root.completeWithData(item ?? ({}));
                } catch (e) {
                    root.completeWithError("Failed to parse codexbar output");
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: root._stderr = text.trim()
        }

        // qmllint disable signal-handler-parameters
        onExited: code => {
            if (root._completed) {
                queueDrainTimer.restart();
                return;
            }
            if (!root._fetchActive)
                return;

            if (code !== 0) {
                const details = root._stderr ? ": " + root._stderr : "";
                root.completeWithError("codexbar exited with code " + code + details);
            } else if (!root._stdout) {
                root.completeWithError("codexbar returned no output");
            }
        }
        // qmllint enable signal-handler-parameters
    }
}
