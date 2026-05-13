import QtQuick

QtObject {
    id: root

    readonly property var defaultProviderOrder: ["claude", "codex", "copilot", "openrouter", "zen", "deepseek", "kilocode", "zai", "gemini"]
    readonly property var codexbarProviderIds: ["claude", "codex", "copilot", "openrouter", "zen", "kilocode", "zai", "gemini"]

    function normalizeProviderOrder(savedOrder) {
        const source = Array.isArray(savedOrder) ? savedOrder : [];
        const result = [];
        const seen = {};

        for (const rawId of source) {
            const id = String(rawId || "");
            if (root.defaultProviderOrder.indexOf(id) !== -1 && !seen[id]) {
                result.push(id);
                seen[id] = true;
            }
        }

        for (const id of root.defaultProviderOrder) {
            if (!seen[id])
                result.push(id);
        }

        return result;
    }

    function supportsCodexbar(providerId) {
        return root.codexbarProviderIds.indexOf(String(providerId || "")) !== -1;
    }

    function codexbarName(providerId) {
        const map = {
            kilocode: "kilo",
            zen: "opencode"
        };
        return map[providerId] ?? providerId;
    }
}
