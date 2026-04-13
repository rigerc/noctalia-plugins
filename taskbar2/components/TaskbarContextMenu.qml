import QtQuick
import Quickshell
import qs.Commons
import qs.Services.UI
import qs.Widgets

NPopupContextMenu {
    id: root

    required property var barRoot

    signal requestFlushPendingModelRefresh

    function buildContextMenuModel(menuModeOverride) {
        const appId = barRoot.selectedAppId;
        const windows = barRoot.getLiveWindowsForEntryKey(barRoot.selectedEntryKey);
        const isRunning = windows.length > 0;
        const isPinned = barRoot.isAppPinned(appId);
        const grouped = barRoot.groupApps && windows.length > 1;
        const rawMode = menuModeOverride || barRoot.groupContextMenuMode || "extended";
        const menuMode = grouped ? ((rawMode === "list" || rawMode === "extended") ? rawMode : "extended") : "single";
        const items = [];

        if (!grouped || menuMode === "single") {
            if (isRunning) {
                items.push({
                    "label": I18n.tr("common.focus"),
                    "action": "focus",
                    "icon": "eye"
                });
            }

            items.push({
                "label": !isPinned ? I18n.tr("common.pin") : I18n.tr("common.unpin"),
                "action": "pin",
                "icon": !isPinned ? "pin" : "unpin"
            });

            if (isRunning) {
                items.push({
                    "label": I18n.tr("common.close"),
                    "action": "close",
                    "icon": "x"
                });
            }
        } else {
            windows.forEach((window, index) => {
                const windowTitle = (window.title && window.title.trim() !== "") ? window.title : (appId || ("Window " + (index + 1)));
                items.push({
                    "label": windowTitle,
                    "action": "focus-window",
                    "icon": window.isFocused ? "circle-filled" : "square-rounded",
                    "windowId": window.id
                });
            });

            if (menuMode === "extended") {
                items.push({
                    "action": "_separator",
                    "enabled": false
                });
                items.push({
                    "label": I18n.tr("common.focus"),
                    "action": "focus",
                    "icon": "eye"
                });
                items.push({
                    "label": !isPinned ? I18n.tr("common.pin") : I18n.tr("common.unpin"),
                    "action": "pin",
                    "icon": !isPinned ? "pin" : "unpin"
                });
                items.push({
                    "label": barRoot.pluginApi?.tr("menu.closeAll"),
                    "action": "close-all",
                    "icon": "x"
                });
            }
        }

        if ((!grouped || menuMode === "extended") && typeof DesktopEntries !== "undefined" && DesktopEntries.byId && appId) {
            const entry = (DesktopEntries.heuristicLookup) ? DesktopEntries.heuristicLookup(appId) : DesktopEntries.byId(appId);
            if (entry != null && entry.actions) {
                entry.actions.forEach(action => {
                    items.push({
                        "label": action.name,
                        "action": "desktop-action",
                        "icon": "chevron-right",
                        "desktopAction": action
                    });
                });
            }
        }

        items.push({
            "label": barRoot.pluginApi?.tr("menu.settings"),
            "action": "widget-settings",
            "icon": "settings"
        });

        return items;
    }

    function openForItem(item, menuModeOverride) {
        barRoot.selectedAppId = item && item.modelData ? item.modelData.appId : "";
        barRoot.selectedEntryKey = item && item.modelData ? item.modelData.entryKey : "";
        barRoot.selectedMenuMode = menuModeOverride || "";
        model = buildContextMenuModel(barRoot.selectedMenuMode);
        PanelService.showContextMenu(root, barRoot, barRoot.screen, item);
    }

    onVisibleChanged: {
        if (!visible)
            requestFlushPendingModelRefresh();
    }

    onTriggered: function (action, item) {
        root.close();
        PanelService.closeContextMenu(barRoot.screen);

        const primaryWindow = barRoot.getPrimaryWindowForEntryKey(barRoot.selectedEntryKey);

        if (action === "focus") {
            barRoot.focusWindow(primaryWindow);
        } else if (action === "focus-window" && item && item.windowId !== undefined) {
            barRoot.focusWindow(barRoot.getWindowById(item.windowId));
        } else if (action === "pin" && barRoot.selectedAppId) {
            barRoot.toggleAppPin(barRoot.selectedAppId);
        } else if (action === "close") {
            barRoot.closeWindow(primaryWindow);
        } else if (action === "close-all" && barRoot.selectedAppId) {
            barRoot.closeAllWindows(barRoot.selectedAppId);
        } else if (action === "widget-settings") {
            BarService.openPluginSettings(barRoot.screen, barRoot.pluginApi.manifest);
        } else if (action === "desktop-action" && item && item.desktopAction) {
            if (item.desktopAction.command && item.desktopAction.command.length > 0) {
                Quickshell.execDetached(item.desktopAction.command);
            } else if (item.desktopAction.execute) {
                item.desktopAction.execute();
            }
        }

        barRoot.selectedAppId = "";
        barRoot.selectedEntryKey = "";
        barRoot.selectedMenuMode = "";
    }
}
