import QtQuick
import QtQuick.Controls
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
    icon: "settings"

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string configDir: homeDir !== "" ? homeDir + "/.codexbar" : ""
    readonly property string configPath: configDir !== "" ? configDir + "/config.json" : ""

    readonly property var providerIds: [
        "codex", "claude", "cursor", "opencode", "factory", "gemini", "antigravity",
        "copilot", "zai", "minimax", "kimi", "kilo", "kiro", "vertexai", "augment",
        "jetbrains", "kimik2", "amp", "ollama", "synthetic", "warp", "openrouter"
    ]
    readonly property var sourceModes: ["auto", "web", "cli", "oauth", "api"]
    readonly property var cookieSourceModes: ["auto", "manual", "off"]

    readonly property var providerOptions: providerIds.map(id => ({
        "key": id,
        "name": id
    }))
    readonly property var sourceModeOptions: sourceModes.map(m => ({
        "key": m,
        "name": m
    }))
    readonly property var cookieSourceModeOptions: cookieSourceModes.map(m => ({
        "key": m,
        "name": m
    }))

    readonly property string defaultTemplate: '{\n  "version": 1,\n  "providers": [\n    {\n      "id": "codex",\n      "enabled": true,\n      "source": "auto",\n      "cookieSource": "auto",\n      "cookieHeader": null,\n      "apiKey": null,\n      "region": null,\n      "workspaceID": null,\n      "tokenAccounts": null\n    }\n  ]\n}\n'

    property string configContent: ""
    property bool configIsValid: true
    property string configError: ""
    property bool isDirty: false
    property bool showRawEditor: false

    property int versionValue: 1
    property var providers: []
    property string addProviderId: "codex"

    component SectionBox: NBox {
        id: section
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: body.implicitHeight + Style.marginL * 2

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: Style.marginL
            spacing: Style.marginM
        }
    }

    function setStatus(message, isError) {
        saveStatus.text = message;
        saveStatus.color = isError ? Color.mError : Color.mPrimary;
        statusTimer.restart();
    }

    function markDirty() {
        tab.isDirty = true;
    }

    function parseJsonOrNull(text) {
        try {
            return JSON.parse(String(text || ""));
        } catch (_error) {
            return null;
        }
    }

    function buildConfigObject() {
        return {
            "version": tab.versionValue,
            "providers": tab.providers
        };
    }

    function syncJsonFromModel() {
        tab.configContent = JSON.stringify(tab.buildConfigObject(), null, 2) + "\n";
        tab.validateConfigContent(false);
    }

    function validateTokenAccounts(tokenAccounts) {
        if (tokenAccounts === null)
            return "";
        if (typeof tokenAccounts !== "object" || Array.isArray(tokenAccounts))
            return rootSettings?.pluginApi?.tr("settings.config.tokenAccountsObject");
        if (tokenAccounts.version !== undefined && typeof tokenAccounts.version !== "number")
            return rootSettings?.pluginApi?.tr("settings.config.tokenAccountsVersion");
        if (tokenAccounts.activeIndex !== undefined && typeof tokenAccounts.activeIndex !== "number")
            return rootSettings?.pluginApi?.tr("settings.config.tokenAccountsActiveIndex");
        if (tokenAccounts.accounts !== undefined && !Array.isArray(tokenAccounts.accounts))
            return rootSettings?.pluginApi?.tr("settings.config.tokenAccountsAccounts");
        return "";
    }

    function validateProvider(provider, index) {
        if (provider === null || typeof provider !== "object" || Array.isArray(provider))
            return rootSettings?.pluginApi?.tr("settings.config.providerObject").replace("{index}", String(index));
        if (typeof provider.id !== "string" || provider.id.trim() === "")
            return rootSettings?.pluginApi?.tr("settings.config.providerIdRequired").replace("{index}", String(index));
        if (tab.providerIds.indexOf(provider.id) < 0)
            return rootSettings?.pluginApi?.tr("settings.config.providerIdUnknown").replace("{id}", provider.id);
        if (provider.enabled !== undefined && typeof provider.enabled !== "boolean")
            return rootSettings?.pluginApi?.tr("settings.config.providerEnabledBoolean").replace("{id}", provider.id);
        if (provider.source !== undefined && tab.sourceModes.indexOf(provider.source) < 0)
            return rootSettings?.pluginApi?.tr("settings.config.providerSourceInvalid").replace("{id}", provider.id);
        if (provider.cookieSource !== undefined && tab.cookieSourceModes.indexOf(provider.cookieSource) < 0)
            return rootSettings?.pluginApi?.tr("settings.config.providerCookieSourceInvalid").replace("{id}", provider.id);
        if (provider.apiKey !== undefined && provider.apiKey !== null && typeof provider.apiKey !== "string")
            return rootSettings?.pluginApi?.tr("settings.config.providerApiKeyString").replace("{id}", provider.id);
        if (provider.cookieHeader !== undefined && provider.cookieHeader !== null && typeof provider.cookieHeader !== "string")
            return rootSettings?.pluginApi?.tr("settings.config.providerCookieHeaderString").replace("{id}", provider.id);
        if (provider.region !== undefined && provider.region !== null && typeof provider.region !== "string")
            return rootSettings?.pluginApi?.tr("settings.config.providerRegionString").replace("{id}", provider.id);
        if (provider.workspaceID !== undefined && provider.workspaceID !== null && typeof provider.workspaceID !== "string")
            return rootSettings?.pluginApi?.tr("settings.config.providerWorkspaceString").replace("{id}", provider.id);

        var tokenAccountsError = tab.validateTokenAccounts(provider.tokenAccounts);
        if (tokenAccountsError !== "")
            return tokenAccountsError.replace("{id}", provider.id);

        return "";
    }

    function validateParsedConfig(parsed) {
        if (parsed.version !== undefined && typeof parsed.version !== "number")
            return rootSettings?.pluginApi?.tr("settings.config.versionNumber");
        if (parsed.providers === undefined)
            return rootSettings?.pluginApi?.tr("settings.config.providersRequired");
        if (!Array.isArray(parsed.providers))
            return rootSettings?.pluginApi?.tr("settings.config.providersArray");

        for (var index = 0; index < parsed.providers.length; index++) {
            var providerError = tab.validateProvider(parsed.providers[index], index);
            if (providerError !== "")
                return providerError;
        }

        return "";
    }

    function validateConfigContent(showValidMessage) {
        if (tab.configPath === "") {
            tab.configIsValid = false;
            tab.configError = rootSettings?.pluginApi?.tr("settings.config.pathUnavailable");
            saveStatus.text = tab.configError;
            saveStatus.color = Color.mError;
            return false;
        }

        var source = String(tab.configContent || "").trim();
        if (source === "") {
            tab.configIsValid = false;
            tab.configError = rootSettings?.pluginApi?.tr("settings.config.empty");
            saveStatus.text = tab.configError;
            saveStatus.color = Color.mError;
            return false;
        }

        try {
            var parsed = JSON.parse(source);
            if (parsed === null || Array.isArray(parsed) || typeof parsed !== "object") {
                tab.configIsValid = false;
                tab.configError = rootSettings?.pluginApi?.tr("settings.config.mustBeObject");
                saveStatus.text = tab.configError;
                saveStatus.color = Color.mError;
                return false;
            }

            var schemaError = tab.validateParsedConfig(parsed);
            if (schemaError !== "") {
                tab.configIsValid = false;
                tab.configError = schemaError;
                saveStatus.text = tab.configError;
                saveStatus.color = Color.mError;
                return false;
            }
        } catch (error) {
            tab.configIsValid = false;
            tab.configError = rootSettings?.pluginApi?.tr("settings.config.invalidJson") + ": " + error;
            saveStatus.text = tab.configError;
            saveStatus.color = Color.mError;
            return false;
        }

        tab.configIsValid = true;
        tab.configError = "";
        if (showValidMessage) {
            saveStatus.text = rootSettings?.pluginApi?.tr("settings.config.valid");
            saveStatus.color = Color.mPrimary;
            statusTimer.restart();
        } else if (saveStatus.color === Color.mError) {
            saveStatus.text = "";
        }
        return true;
    }

    function loadModelFromParsed(parsed) {
        var schemaError = tab.validateParsedConfig(parsed);
        if (schemaError !== "")
            return false;

        tab.versionValue = parsed.version;
        tab.providers = parsed.providers.map(function (provider) {
            return {
                "id": String(provider.id || ""),
                "enabled": provider.enabled !== false,
                "source": typeof provider.source === "string" ? provider.source : "auto",
                "cookieSource": typeof provider.cookieSource === "string" ? provider.cookieSource : "auto",
                "cookieHeader": provider.cookieHeader === undefined ? null : provider.cookieHeader,
                "apiKey": provider.apiKey === undefined ? null : provider.apiKey,
                "region": provider.region === undefined ? null : provider.region,
                "workspaceID": provider.workspaceID === undefined ? null : provider.workspaceID,
                "tokenAccounts": provider.tokenAccounts === undefined ? null : provider.tokenAccounts
            };
        });

        tab.isDirty = false;
        tab.syncJsonFromModel();
        return true;
    }

    function formatJson() {
        var parsed = tab.parseJsonOrNull(tab.configContent);
        if (!parsed) {
            tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.formatFailed"), true);
            return;
        }
        tab.configContent = JSON.stringify(parsed, null, 2) + "\n";
        tab.validateConfigContent(true);
    }

    function resetToTemplate() {
        var parsed = tab.parseJsonOrNull(tab.defaultTemplate);
        if (!parsed)
            return;
        tab.loadModelFromParsed(parsed);
        tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.templateLoaded"), false);
    }

    function applyRawToModel() {
        var parsed = tab.parseJsonOrNull(tab.configContent);
        if (!parsed) {
            tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.invalidJson"), true);
            return;
        }
        if (!tab.loadModelFromParsed(parsed)) {
            tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.schemaInvalid"), true);
            return;
        }
        tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.rawApplied"), false);
    }

    function providerExists(providerId) {
        for (var i = 0; i < tab.providers.length; i++) {
            if (tab.providers[i] && tab.providers[i].id === providerId)
                return true;
        }
        return false;
    }

    function addProvider() {
        if (!tab.addProviderId || tab.addProviderId.trim() === "") {
            tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.providerMissing"), true);
            return;
        }
        if (tab.providerExists(tab.addProviderId)) {
            tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.providerAlreadyExists"), true);
            return;
        }

        var next = tab.providers.slice();
        next.push({
            "id": tab.addProviderId,
            "enabled": true,
            "source": "auto",
            "cookieSource": "auto",
            "cookieHeader": null,
            "apiKey": null,
            "region": null,
            "workspaceID": null,
            "tokenAccounts": null
        });
        tab.providers = next;
        tab.markDirty();
        tab.syncJsonFromModel();
        tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.providerAdded"), false);
    }

    function removeProviderAt(index) {
        var next = tab.providers.slice();
        next.splice(index, 1);
        tab.providers = next;
        tab.markDirty();
        tab.syncJsonFromModel();
    }

    function moveProvider(index, direction) {
        var toIndex = index + direction;
        if (toIndex < 0 || toIndex >= tab.providers.length)
            return;
        var next = tab.providers.slice();
        var tmp = next[index];
        next[index] = next[toIndex];
        next[toIndex] = tmp;
        tab.providers = next;
        tab.markDirty();
        tab.syncJsonFromModel();
    }

    function updateProviderField(index, field, value) {
        var next = tab.providers.slice();
        var existing = next[index] || ({});
        var updated = Object.assign({}, existing);
        updated[field] = value;
        next[index] = updated;
        tab.providers = next;
        tab.markDirty();
        tab.syncJsonFromModel();
    }

    function buildSaveScript() {
        var configPathEsc = tab.configPath.replace(/'/g, "'\\''");
        var configDirEsc = tab.configDir.replace(/'/g, "'\\''");
        var delimiter = "__CODEXBAR_CONFIG_EOF__";

        while (tab.configContent.indexOf("\n" + delimiter + "\n") >= 0
               || tab.configContent === delimiter
               || tab.configContent.indexOf(delimiter + "\n") === 0
               || tab.configContent.lastIndexOf("\n" + delimiter) === tab.configContent.length - delimiter.length - 1) {
            delimiter += "_";
        }

        var script = "mkdir -p '" + configDirEsc + "' && cat > '" + configPathEsc + "' <<'" + delimiter + "'\n";
        script += tab.configContent;
        script += "\n" + delimiter + "\n";
        return script;
    }

    FileView {
        id: configFile
        path: tab.configPath !== "" ? tab.configPath : undefined
        watchChanges: false
        printErrors: false

        onLoaded: {
            tab.configContent = text() || tab.defaultTemplate;
            var parsed = tab.parseJsonOrNull(tab.configContent);
            if (!parsed || !tab.loadModelFromParsed(parsed)) {
                tab.configContent = tab.defaultTemplate;
                tab.loadModelFromParsed(tab.parseJsonOrNull(tab.defaultTemplate));
                tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.loadFallback"), false);
            }
        }
        onLoadFailed: function (error) {
            Logger.w("CodexBar", "Config load error: " + error);
            tab.configContent = tab.defaultTemplate;
            tab.loadModelFromParsed(tab.parseJsonOrNull(tab.defaultTemplate));
            tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.loadFallback"), false);
        }
    }

    SectionBox {
        NText {
            Layout.fillWidth: true
            text: rootSettings?.pluginApi?.tr("settings.config.securityNote")
            color: Color.mOnSurface
            wrapMode: Text.Wrap
        }
        NText {
            Layout.fillWidth: true
            text: rootSettings?.pluginApi?.tr("settings.config.reference")
            color: Color.mOnSurfaceVariant
            pointSize: Style.fontSizeXS
            wrapMode: Text.Wrap
        }
    }

    SectionBox {
        enabled: !tab.showRawEditor

        NText {
            Layout.fillWidth: true
            text: rootSettings?.pluginApi?.tr("settings.config.providersTitle")
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
            font.weight: Font.Medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            NComboBox {
                Layout.fillWidth: true
                label: rootSettings?.pluginApi?.tr("settings.config.addProvider")
                model: tab.providerOptions
                currentKey: tab.addProviderId
                onSelected: key => tab.addProviderId = key
            }

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.config.add")
                icon: "plus"
                onClicked: tab.addProvider()
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Style.marginM

            Repeater {
                model: tab.providers

                delegate: SectionBox {
                    required property int index
                    required property var modelData

                    property bool showAdvanced: false

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginM

                        NText {
                            Layout.fillWidth: true
                            text: modelData.id
                            color: Color.mOnSurface
                            pointSize: Style.fontSizeM
                            font.weight: Font.Medium
                        }

                        NButton {
                            icon: "arrow-up"
                            outlined: true
                            enabled: index > 0
                            onClicked: tab.moveProvider(index, -1)
                        }
                        NButton {
                            icon: "arrow-down"
                            outlined: true
                            enabled: index < tab.providers.length - 1
                            onClicked: tab.moveProvider(index, +1)
                        }
                        NButton {
                            icon: "trash"
                            outlined: true
                            onClicked: tab.removeProviderAt(index)
                        }
                    }

                    NToggle {
                        label: rootSettings?.pluginApi?.tr("settings.config.enabledField")
                        checked: modelData.enabled !== false
                        onToggled: checked => tab.updateProviderField(index, "enabled", checked)
                    }

                    NComboBox {
                        Layout.fillWidth: true
                        label: rootSettings?.pluginApi?.tr("settings.config.sourceField")
                        model: tab.sourceModeOptions
                        currentKey: modelData.source || "auto"
                        onSelected: key => tab.updateProviderField(index, "source", key)
                    }

                    NComboBox {
                        Layout.fillWidth: true
                        label: rootSettings?.pluginApi?.tr("settings.config.cookieSourceField")
                        model: tab.cookieSourceModeOptions
                        currentKey: modelData.cookieSource || "auto"
                        onSelected: key => tab.updateProviderField(index, "cookieSource", key)
                    }

                    NToggle {
                        label: rootSettings?.pluginApi?.tr("settings.config.advancedFields")
                        checked: showAdvanced
                        onToggled: checked => showAdvanced = checked
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: showAdvanced
                        spacing: Style.marginM

                        NTextInput {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.config.regionField")
                            text: modelData.region ?? ""
                            onTextChanged: tab.updateProviderField(index, "region", text !== "" ? text : null)
                        }

                        NTextInput {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.config.workspaceField")
                            text: modelData.workspaceID ?? ""
                            onTextChanged: tab.updateProviderField(index, "workspaceID", text !== "" ? text : null)
                        }

                        NTextInput {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.config.apiKeyField")
                            text: modelData.apiKey ?? ""
                            onTextChanged: tab.updateProviderField(index, "apiKey", text !== "" ? text : null)
                        }

                        NTextInput {
                            Layout.fillWidth: true
                            label: rootSettings?.pluginApi?.tr("settings.config.cookieHeaderField")
                            text: modelData.cookieHeader ?? ""
                            onTextChanged: tab.updateProviderField(index, "cookieHeader", text !== "" ? text : null)
                        }
                    }
                }
            }
        }
    }

    SectionBox {
        NText {
            Layout.fillWidth: true
            text: rootSettings?.pluginApi?.tr("settings.config.advancedTitle")
            color: Color.mOnSurface
            pointSize: Style.fontSizeS
            font.weight: Font.Medium
        }

        NToggle {
            Layout.fillWidth: true
            label: rootSettings?.pluginApi?.tr("settings.config.showRaw")
            checked: tab.showRawEditor
            onToggled: checked => tab.showRawEditor = checked
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginM
            visible: tab.showRawEditor

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.config.applyRaw")
                icon: "list-details"
                onClicked: tab.applyRawToModel()
            }

            NButton {
                text: rootSettings?.pluginApi?.tr("settings.config.format")
                icon: "brackets"
                outlined: true
                onClicked: tab.formatJson()
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: tab.showRawEditor ? (360 * Style.uiScaleRatio) : 0
            visible: tab.showRawEditor

            TextArea {
                anchors.fill: parent
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
                    tab.validateConfigContent(false);
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NButton {
            text: rootSettings?.pluginApi?.tr("settings.config.template")
            icon: "file-plus"
            outlined: true
            enabled: !saveConfigProcess.running
            onClicked: tab.resetToTemplate()
        }

        NButton {
            text: rootSettings?.pluginApi?.tr("settings.config.save") || "Save Config"
            icon: "device-floppy"
            enabled: tab.configIsValid && tab.configPath !== "" && !saveConfigProcess.running
            onClicked: {
                if (!tab.validateConfigContent(true))
                    return;
                saveConfigProcess.command = ["sh", "-c", tab.buildSaveScript()];
                saveConfigProcess.running = true;
                tab.isDirty = false;
            }
        }

        NButton {
            text: rootSettings?.pluginApi?.tr("settings.config.openEditor") || "Open in Editor"
            icon: "external-link"
            outlined: true
            enabled: tab.configPath !== ""
            onClicked: Quickshell.execDetached(["xdg-open", tab.configPath])
        }

        Item {
            Layout.fillWidth: true
        }

        NText {
            id: saveStatus
            text: ""
            pointSize: Style.fontSizeXS
            color: Color.mOnSurfaceVariant
        }
    }

    Process {
        id: saveConfigProcess
        running: false

        stdout: StdioCollector {}
        stderr: StdioCollector {
            onStreamFinished: {
                Logger.w("CodexBar", "Config save stderr: " + this.text);
            }
        }

        onExited: function (exitCode) {
            if (exitCode === 0) {
                tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.saved"), false);
            } else {
                tab.setStatus(rootSettings?.pluginApi?.tr("settings.config.saveFailed") + ": exit " + exitCode, true);
            }
        }
    }

    Timer {
        id: statusTimer
        interval: 3000
        repeat: false
        onTriggered: saveStatus.text = ""
    }
}

