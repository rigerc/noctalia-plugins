import QtQuick
import Quickshell.Io

Item {
    id: root
    visible: false

    property string codexbarProvider: ""
    property bool running: proc.running
    property bool _fetchActive: false
    property bool _completed: false
    property string _stdout: ""
    property string _stderr: ""

    signal dataReady(var result)
    signal fetchError(string message)

    function fetch() {
        if (!root.codexbarProvider || proc.running)
            return;

        root._fetchActive = true;
        root._completed = false;
        root._stdout = "";
        root._stderr = "";
        proc.running = true;
    }

    function completeWithError(message) {
        if (!root._fetchActive || root._completed)
            return;
        root._completed = true;
        root._fetchActive = false;
        root.fetchError(message);
    }

    function completeWithData(result) {
        if (!root._fetchActive || root._completed)
            return;
        root._completed = true;
        root._fetchActive = false;
        root.dataReady(result);
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
            if (!root._fetchActive || root._completed)
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
