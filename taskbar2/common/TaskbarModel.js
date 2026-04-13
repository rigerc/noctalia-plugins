function normalizeAppId(appId) {
    if (!appId || typeof appId !== "string")
        return "";
    let id = appId.toLowerCase().trim();
    if (id.endsWith(".desktop"))
        id = id.substring(0, id.length - 8);
    return id;
}

function getWindowHandle(window) {
    if (!window)
        return null;
    if (window.handle)
        return window.handle;
    if (window.toplevel)
        return window.toplevel;
    return null;
}

function getStableWindowKey(ctx, window) {
    if (!window)
        return "";

    const handle = getWindowHandle(window);
    if (handle) {
        for (let i = 0; i < ctx.stableWindowKeyEntries.length; i++) {
            const entry = ctx.stableWindowKeyEntries[i];
            if (entry && entry.handle === handle)
                return entry.key;
        }

        ctx.stableWindowKeyCounter += 1;
        const key = "window:" + ctx.stableWindowKeyCounter;
        ctx.stableWindowKeyEntries = ctx.stableWindowKeyEntries.concat([
            {
                "handle": handle,
                "key": key
            }
        ]);
        return key;
    }

    if (window.id !== undefined && window.id !== null)
        return "backend:" + String(window.id);

    return "fallback:" + normalizeAppId(window.appId) + ":" + String(window.workspaceId ?? "") + ":" + String(window.output ?? "");
}

function pruneStableWindowKeys(ctx, activeWindows) {
    if (!ctx.stableWindowKeyEntries || ctx.stableWindowKeyEntries.length === 0)
        return;

    const activeHandles = [];
    (activeWindows || []).forEach(window => {
        const handle = getWindowHandle(window);
        if (handle)
            activeHandles.push(handle);
    });

    if (activeHandles.length === 0)
        return;

    const nextEntries = ctx.stableWindowKeyEntries.filter(entry => {
        return activeHandles.some(handle => handle === entry.handle);
    });

    if (nextEntries.length !== ctx.stableWindowKeyEntries.length)
        ctx.stableWindowKeyEntries = nextEntries;
}

function getAppKey(ctx, appData) {
    if (!appData)
        return null;
    if (appData.type === "separator")
        return null;

    if (appData.orderKey !== undefined)
        return appData.orderKey;

    if (ctx.groupApps)
        return appData.appId;

    if (appData.type === "pinned" || appData.type === "pinned-running")
        return appData.appId;

    if (appData.windowStableKey)
        return appData.windowStableKey;

    if (appData.window)
        return appData.window;

    return appData.appId;
}

function getEntryKey(ctx, appData) {
    if (!appData)
        return "";
    if (appData.type === "separator")
        return "";

    if (ctx.groupApps)
        return "app:" + appData.appId;

    if (appData.windowStableKey)
        return appData.windowStableKey;

    if (appData.window)
        return getStableWindowKey(ctx, appData.window);

    return "pinned:" + appData.appId;
}

function isAppEntry(entry) {
    return !!entry && entry.type !== "workspace-target";
}

function getAppEntries(entries) {
    const sourceEntries = entries || [];
    return sourceEntries.filter(entry => isAppEntry(entry));
}

function getWorkspaceInfo(ctx, workspaceId) {
    const fallbackIndex = (typeof workspaceId === "number" && !isNaN(workspaceId)) ? workspaceId : 0;
    const workspaces = ctx.CompositorService.workspaces;

    if (workspaces && workspaces.count !== undefined && workspaces.get) {
        for (let i = 0; i < workspaces.count; i++) {
            const workspace = workspaces.get(i);
            if (workspace && workspace.id === workspaceId) {
                return {
                    "id": workspace.id,
                    "index": workspace.idx !== undefined ? workspace.idx : fallbackIndex,
                    "name": workspace.name || ""
                };
            }
        }
    }

    return {
        "id": workspaceId,
        "index": fallbackIndex,
        "name": ""
    };
}

function getWorkspaceLabel(ctx, workspaceIndex) {
    return (ctx.workspaceSeparatorPrefix || "") + workspaceIndex + (ctx.workspaceSeparatorSuffix || "");
}

function isWorkspaceIgnored(ctx, workspaceId) {
    const workspaceInfo = getWorkspaceInfo(ctx, workspaceId);
    const idString = String(workspaceInfo.id ?? workspaceId ?? "").trim();
    const nameString = String(workspaceInfo.name || "").trim();
    if ((ctx.ignoredWorkspaceIds || []).some(id => String(id).trim() === idString))
        return true;
    if (nameString.length > 0 && (ctx.ignoredWorkspaceNames || []).some(name => String(name).trim() === nameString))
        return true;
    return false;
}

function getWorkspaceReference(ctx, workspaceId) {
    const workspaceInfo = getWorkspaceInfo(ctx, workspaceId);
    if (workspaceInfo.name && String(workspaceInfo.name).trim().length > 0)
        return String(workspaceInfo.name);
    return String(workspaceInfo.index);
}

function collectVisibleWindows(ctx) {
    const windows = [];
    try {
        const total = ctx.CompositorService.windows.count || 0;
        for (let i = 0; i < total; i++) {
            const window = ctx.CompositorService.windows.get(i);
            if (window && !isWorkspaceIgnored(ctx, window.workspaceId))
                windows.push(window);
        }
    } catch (e) {}
    return windows;
}

function getActiveWorkspaceIds(ctx) {
    const activeWorkspaces = ctx.CompositorService.getActiveWorkspaces ? ctx.CompositorService.getActiveWorkspaces() : [];
    return activeWorkspaces.map(ws => ws.id);
}

function windowPasses(ctx, window, activeIds) {
    if (!window)
        return false;
    const passOutput = (!ctx.onlySameOutput) || (window.output === ctx.screen?.name);
    const passWorkspace = ((!ctx.onlyActiveWorkspaces) || activeIds.includes(window.workspaceId)) && !isWorkspaceIgnored(ctx, window.workspaceId);
    return passOutput && passWorkspace;
}

function buildGroupedModel(ctx, apps) {
    if (!ctx.groupApps) {
        return apps.map(app => {
            return {
                "entryKey": getEntryKey(ctx, app),
                "appId": app.appId,
                "type": app.type,
                "fallbackTitle": app.title || ctx.getAppNameFromDesktopEntry(app.appId),
                "isPinned": app.type === "pinned" || app.type === "pinned-running",
                "orderKey": getAppKey(ctx, app),
                "windowStableKey": app.windowStableKey || "",
                "workspaceId": app.workspaceId ?? -1,
                "workspaceIndex": app.workspaceIndex ?? -1
            };
        });
    }

    const grouped = [];
    const groupedById = new Map();
    const orderByStableKey = {};

    apps.forEach((app, appIndex) => {
        const appId = app.appId;
        const windows = app.window ? [app.window] : [];
        const existing = groupedById.get(appId);
        windows.forEach(window => {
            const stableKey = getStableWindowKey(ctx, window);
            if (stableKey && orderByStableKey[stableKey] === undefined)
                orderByStableKey[stableKey] = appIndex;
        });

        if (existing) {
            windows.forEach(window => {
                const stableKey = getStableWindowKey(ctx, window);
                if (window && stableKey && existing.windowStableKeys.indexOf(stableKey) === -1)
                    existing.windowStableKeys.push(stableKey);
            });
            if (app.type === "pinned" || app.type === "pinned-running")
                existing.isPinned = true;
        } else {
            const wsId = app.workspaceId ?? -1;
            const entry = {
                "entryKey": ctx.workspaceGroupingActive ? ("app:" + appId + ":ws" + wsId) : ("app:" + appId),
                "appId": appId,
                "type": app.type,
                "fallbackTitle": app.title || ctx.getAppNameFromDesktopEntry(appId),
                "windowStableKeys": windows.map(window => getStableWindowKey(ctx, window)).filter(windowKey => windowKey !== ""),
                "isPinned": app.type === "pinned" || app.type === "pinned-running",
                "orderKey": appId,
                "workspaceId": app.workspaceId ?? -1,
                "workspaceIndex": app.workspaceIndex ?? -1,
                "anchorWindowStableKey": windows.length > 0 ? getStableWindowKey(ctx, windows[0]) : "",
                "anchorOrder": appIndex
            };
            grouped.push(entry);
            groupedById.set(appId, entry);
        }
    });

    grouped.forEach(entry => {
        if (entry.windowStableKeys.length > 0 && entry.isPinned)
            entry.type = "pinned-running";
        else if (entry.windowStableKeys.length > 0)
            entry.type = "running";
        else
            entry.type = "pinned";
    });

    grouped.forEach(entry => {
        if (!entry.windowStableKeys || entry.windowStableKeys.length === 0) {
            entry.anchorWindowStableKey = "";
            return;
        }

        entry.anchorWindowStableKey = entry.windowStableKeys[0];
        const liveWindows = collectVisibleWindows(ctx);
        for (let i = 0; i < entry.windowStableKeys.length; i++) {
            const candidate = liveWindows.find(window => getStableWindowKey(ctx, window) === entry.windowStableKeys[i]);
            if (candidate && candidate.isFocused) {
                entry.anchorWindowStableKey = entry.windowStableKeys[i];
                entry.workspaceId = candidate.workspaceId ?? entry.workspaceId;
                entry.workspaceIndex = getWorkspaceInfo(ctx, candidate.workspaceId).index;
                break;
            }
        }
        entry.anchorOrder = orderByStableKey[entry.anchorWindowStableKey] ?? entry.anchorOrder ?? 0;
    });

    grouped.sort((a, b) => (a.anchorOrder ?? 0) - (b.anchorOrder ?? 0));
    return grouped;
}

function buildWorkspaceGroupedModel(ctx, apps) {
    const groupedByWorkspace = new Map();
    const workspaceOrder = [];
    const unassignedEntries = [];

    apps.forEach(app => {
        if (app.workspaceId === undefined || app.workspaceId === null || app.workspaceId === "" || app.workspaceId === -1) {
            unassignedEntries.push(app);
            return;
        }

        const key = String(app.workspaceId);
        if (!groupedByWorkspace.has(key)) {
            groupedByWorkspace.set(key, {
                "workspaceId": app.workspaceId,
                "workspaceIndex": app.workspaceIndex ?? app.workspaceId,
                "entries": []
            });
            workspaceOrder.push(key);
        }
        groupedByWorkspace.get(key).entries.push(app);
    });

    workspaceOrder.sort((a, b) => {
        const groupA = groupedByWorkspace.get(a);
        const groupB = groupedByWorkspace.get(b);
        const indexA = groupA ? groupA.workspaceIndex : 0;
        const indexB = groupB ? groupB.workspaceIndex : 0;
        if (indexA !== indexB)
            return indexA - indexB;
        return String(a).localeCompare(String(b));
    });

    const renderEntries = [];
    const workspaces = ctx.CompositorService.workspaces;
    if (workspaces && workspaces.count !== undefined && workspaces.get) {
        for (let i = 0; i < workspaces.count; i++) {
            const workspace = workspaces.get(i);
            if (!workspace || isWorkspaceIgnored(ctx, workspace.id))
                continue;
            const key = String(workspace.id);
            if (groupedByWorkspace.has(key))
                continue;
            groupedByWorkspace.set(key, {
                "workspaceId": workspace.id,
                "workspaceIndex": workspace.idx ?? 0,
                "entries": []
            });
            workspaceOrder.push(key);
        }
    }

    workspaceOrder.sort((a, b) => {
        const groupA = groupedByWorkspace.get(a);
        const groupB = groupedByWorkspace.get(b);
        const indexA = groupA ? groupA.workspaceIndex : 0;
        const indexB = groupB ? groupB.workspaceIndex : 0;
        if (indexA !== indexB)
            return indexA - indexB;
        return String(a).localeCompare(String(b));
    });

    workspaceOrder.forEach((key, index) => {
        const workspaceGroup = groupedByWorkspace.get(key);
        if (!workspaceGroup)
            return;

        if (ctx.showWorkspaceSeparators && (index > 0 || ctx.workspaceSeparatorShowForFirst)) {
            renderEntries.push({
                "type": "workspace-target",
                "workspaceId": workspaceGroup.workspaceId,
                "workspaceIndex": workspaceGroup.workspaceIndex,
                "showSeparator": true
            });
        } else if (!ctx.showWorkspaceSeparators) {
            renderEntries.push({
                "type": "workspace-target",
                "workspaceId": workspaceGroup.workspaceId,
                "workspaceIndex": workspaceGroup.workspaceIndex,
                "showSeparator": false
            });
        }

        buildGroupedModel(ctx, workspaceGroup.entries || []).forEach(entry => renderEntries.push(entry));
    });

    if (unassignedEntries.length > 0)
        buildGroupedModel(ctx, unassignedEntries).forEach(entry => renderEntries.push(entry));

    return renderEntries;
}

function buildLiveEntries(ctx, structuralEntries, windowsById, windowsByStableKey) {
    const liveEntries = {};

    structuralEntries.forEach(entry => {
        if (!isAppEntry(entry) || !entry.entryKey)
            return;

        const windowIds = [];
        const windows = [];

        if (ctx.groupApps) {
            if (entry.windowStableKeys) {
                entry.windowStableKeys.forEach(windowKey => {
                    const liveWindow = windowsByStableKey[windowKey];
                    if (liveWindow) {
                        windowIds.push(String(liveWindow.id));
                        windows.push(liveWindow);
                    }
                });
            }
        } else if (entry.windowStableKey) {
            const liveWindow = windowsByStableKey[entry.windowStableKey];
            if (liveWindow) {
                windowIds.push(String(liveWindow.id));
                windows.push(liveWindow);
            }
        }

        const primaryWindow = ctx.getPrimaryWindow(windows);
        let anchorWindow = primaryWindow;
        if (ctx.groupApps && entry.anchorWindowStableKey)
            anchorWindow = windowsByStableKey[entry.anchorWindowStableKey] || primaryWindow;
        let focusedWindowIndex = -1;
        for (let i = 0; i < windows.length; i++) {
            if (windows[i] && windows[i].isFocused) {
                focusedWindowIndex = i;
                break;
            }
        }

        liveEntries[entry.entryKey] = {
            "windows": windows,
            "windowIds": windowIds,
            "primaryWindow": primaryWindow,
            "anchorWindow": anchorWindow,
            "title": (primaryWindow && primaryWindow.title) ? primaryWindow.title : entry.fallbackTitle,
            "isFocused": focusedWindowIndex >= 0,
            "focusedWindowIndex": focusedWindowIndex,
            "groupedCount": windows.length
        };
    });

    return liveEntries;
}

function getStructuralSignature(ctx, entry) {
    if (!isAppEntry(entry))
        return ["separator", entry.workspaceId, entry.workspaceIndex, entry.label || ""].join("|");
    const ids = entry.windowStableKeys ? entry.windowStableKeys.join(",") : (entry.windowStableKey || "");
    return [entry.entryKey, entry.appId, entry.type, entry.isPinned ? "1" : "0", ids].join("|");
}

function hasStructuralChange(ctx, currentEntries, nextEntries) {
    if (currentEntries.length !== nextEntries.length)
        return true;

    for (let i = 0; i < nextEntries.length; i++) {
        if (getStructuralSignature(ctx, currentEntries[i]) !== getStructuralSignature(ctx, nextEntries[i]))
            return true;
    }

    return false;
}

function buildStructuralEntries(ctx) {
    const pinnedApps = ctx.Settings.data.dock.pinnedApps || [];
    const combined = [];
    const processedWindows = new Set();
    const processedPinnedAppIds = new Set();
    const runningWindows = collectVisibleWindows(ctx);
    const activeIds = getActiveWorkspaceIds(ctx);

    function pushEntry(entryType, window, appId, title) {
        const canonicalId = ctx.isAppIdPinned(appId, pinnedApps) ? (pinnedApps.find(p => normalizeAppId(p) === normalizeAppId(appId)) || appId) : appId;
        const workspaceInfo = window ? getWorkspaceInfo(ctx, window.workspaceId) : null;

        if (window) {
            if (processedWindows.has(window))
                return;
            if (!windowPasses(ctx, window, activeIds))
                return;
            combined.push({
                "type": entryType,
                "window": window,
                "windowStableKey": getStableWindowKey(ctx, window),
                "appId": canonicalId,
                "title": title || window.title || ctx.getAppNameFromDesktopEntry(appId),
                "workspaceId": workspaceInfo ? workspaceInfo.id : -1,
                "workspaceIndex": workspaceInfo ? workspaceInfo.index : -1
            });
            processedWindows.add(window);
        } else {
            if (processedPinnedAppIds.has(canonicalId))
                return;
            combined.push({
                "id": canonicalId,
                "type": entryType,
                "window": null,
                "appId": canonicalId,
                "title": title || ctx.getAppNameFromDesktopEntry(canonicalId),
                "workspaceId": -1,
                "workspaceIndex": -1
            });
            processedPinnedAppIds.add(canonicalId);
        }
    }

    function pushRunning(firstPass) {
        runningWindows.forEach(window => {
            if (!window)
                return;
            const isPinned = ctx.isAppIdPinned(window.appId, pinnedApps);
            if (!firstPass && isPinned && processedWindows.has(window))
                return;
            pushEntry((firstPass && isPinned) ? "pinned-running" : "running", window, window.appId, window.title);
        });
    }

    function pushPinned() {
        pinnedApps.forEach(pinnedAppId => {
            const normalizedPinnedId = normalizeAppId(pinnedAppId);
            const matchingWindows = runningWindows.filter(window => {
                if (!window || !windowPasses(ctx, window, activeIds))
                    return false;
                if (normalizeAppId(window.appId) === normalizedPinnedId)
                    return true;
                const resolved = ctx.resolveToDesktopEntryId(window.appId);
                return resolved !== window.appId && normalizeAppId(resolved) === normalizedPinnedId;
            });

            if (matchingWindows.length > 0) {
                matchingWindows.forEach(window => {
                    pushEntry("pinned-running", window, pinnedAppId, window.title);
                });
            } else if (ctx.showPinnedApps) {
                pushEntry("pinned", null, pinnedAppId, ctx.getAppNameFromDesktopEntry(pinnedAppId));
            }
        });
    }

    pushRunning(true);
    pushPinned();

    const runningEntries = combined.filter(entry => entry.window);
    const pinnedEntries = combined.filter(entry => !entry.window);
    const pinnedLookup = new Map();
    pinnedEntries.forEach(entry => pinnedLookup.set(normalizeAppId(entry.appId), entry));
    const orderedPinnedEntries = [];
    pinnedApps.forEach(appId => {
        const pinnedEntry = pinnedLookup.get(normalizeAppId(appId));
        if (pinnedEntry)
            orderedPinnedEntries.push(pinnedEntry);
    });
    pinnedEntries.forEach(entry => {
        if (orderedPinnedEntries.indexOf(entry) === -1)
            orderedPinnedEntries.push(entry);
    });

    if (ctx.workspaceGroupingActive)
        return orderedPinnedEntries.concat(buildWorkspaceGroupedModel(ctx, runningEntries));
    return orderedPinnedEntries.concat(buildGroupedModel(ctx, runningEntries));
}

function getFocusedEntryKey(liveEntries) {
    const entries = liveEntries || ({});
    for (var entryKey in entries) {
        if (entries[entryKey] && entries[entryKey].isFocused)
            return entryKey;
    }
    return "";
}

