import QtQuick

QtObject {
    id: root

    function boundedPercent(rawPercent) {
        return Math.min(1, Math.max(0, Number(rawPercent ?? 0) / 100));
    }

    function shouldRefresh(lastRefreshAtMs, refreshIntervalSec, force) {
        if (force || lastRefreshAtMs <= 0)
            return true;
        return (Date.now() - lastRefreshAtMs) >= Math.max(5, refreshIntervalSec) * 1000;
    }

    function applyCodexbarData(provider, result, utils) {
        const usage = result?.usage ?? null;
        const primary = usage?.primary ?? null;
        const secondary = usage?.secondary ?? null;
        const identity = usage?.identity ?? null;
        const credits = result?.credits ?? null;

        if (secondary) {
            provider.rateLimitPercent = root.boundedPercent(secondary.usedPercent);
            provider.rateLimitLabel = utils.windowMinutesToLabel(secondary.windowMinutes) || "7d";
            provider.rateLimitResetAt = secondary.resetsAt ?? "";
        } else {
            provider.rateLimitPercent = -1;
            provider.rateLimitLabel = "";
            provider.rateLimitResetAt = "";
        }

        if (primary) {
            provider.secondaryRateLimitPercent = root.boundedPercent(primary.usedPercent);
            provider.secondaryRateLimitLabel = utils.windowMinutesToLabel(primary.windowMinutes) || "5h";
            provider.secondaryRateLimitResetAt = primary.resetsAt ?? "";
        } else {
            provider.secondaryRateLimitPercent = -1;
            provider.secondaryRateLimitLabel = "";
            provider.secondaryRateLimitResetAt = "";
        }

        if (!secondary && credits && Number(credits.total ?? 0) > 0) {
            const used = Number(credits.used ?? 0);
            const total = Number(credits.total ?? 0);
            provider.rateLimitPercent = Math.min(1, Math.max(0, used / total));
            provider.rateLimitLabel = "Credits ($" + used.toFixed(2) + " / $" + total.toFixed(2) + ")";
            provider.rateLimitResetAt = "";
        }

        provider.tierLabel = identity?.loginMethod ?? provider.tierLabel;
        provider.usageStatusText = "";
        provider.ready = true;
    }
}
