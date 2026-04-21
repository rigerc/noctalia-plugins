import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

SettingsTabPage {
    id: tab

    property var rootSettings: null

    title: rootSettings?.pluginApi?.tr("settings.config.title") || "Config"
    description: rootSettings?.pluginApi?.tr("settings.config.description") || "Edit ~/.codexbar/config.json"
    icon: "mdi:cog-outline"

    property string configContent: ""
    property string configPath: StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.codexbar/config.json"

    FileView {
        id: configFile
        path: tab.configPath
        watchChanges: false

        onLoaded: {
            tab.configContent = text || "";
        }
        onError: (errorString) => {
            Logger.w("CodexBar", "Config load error: " + errorString);
        }
    }

    NScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: 360 * Style.uiScaleRatio

        TextArea {
            id: configEdit
            width: parent?.width ?? 200
            text: tab.configContent
            font.family: "monospace"
            font.pixelSize: Style.fontSizeS
            color: Color.mOnSurface
            selectedTextColor: Color.mOnPrimary
            selectionColor: Color.mPrimary
            background: Rectangle {
                color: Color.mSurfaceVariant
                radius: Style.radiusM
            }
            onTextChanged: {
                tab.configContent = text;
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
            text: rootSettings?.pluginApi?.tr("settings.config.save") || "Save Config"
            icon: "mdi:content-save"
            onClicked: saveConfigProcess.running = true
        }

        NButton {
            text: rootSettings?.pluginApi?.tr("settings.config.openEditor") || "Open in Editor"
            icon: "mdi:open-in-new"
            outlined: true
            onClicked: Quickshell.execDetached(["xdg-open", tab.configPath])
        }

        Item {
            Layout.fillWidth: true
        }

        NText {
            id: saveStatus
            text: ""
            font.pixelSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
        }
    }

    Process {
        id: saveConfigProcess

        command: ["tee", tab.configPath]
        running: false

        stdin: tab.configContent

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                Logger.w("CodexBar", "Config save stderr: " + this.text);
            }
        }

        onExited: function (exitCode) {
            if (exitCode === 0) {
                saveStatus.text = "Saved";
                saveStatus.color = Color.mPrimary;
            } else {
                saveStatus.text = "Error: exit " + exitCode;
                saveStatus.color = Color.mError;
            }
            statusTimer.start();
        }
    }

    Timer {
        id: statusTimer
        interval: 3000
        repeat: false
        onTriggered: saveStatus.text = ""
    }
}
