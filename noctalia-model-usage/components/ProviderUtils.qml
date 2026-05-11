import QtQuick

QtObject {
    id: root

    function formatResetTime(isoTimestamp) {
        if (!isoTimestamp)
            return "";
        const reset = new Date(isoTimestamp);
        const now = new Date();
        const diffMs = reset.getTime() - now.getTime();
        if (diffMs <= 0)
            return "now";
        const hours = Math.floor(diffMs / 3600000);
        const mins = Math.floor((diffMs % 3600000) / 60000);
        if (hours > 24)
            return Math.floor(hours / 24) + "d " + (hours % 24) + "h";
        if (hours > 0)
            return hours + "h " + mins + "m";
        return mins + "m";
    }

    function localDateString() {
        const now = new Date();
        const y = now.getFullYear();
        const m = String(now.getMonth() + 1).padStart(2, "0");
        const d = String(now.getDate()).padStart(2, "0");
        return y + "-" + m + "-" + d;
    }

    function normalizeResetAt(value) {
        if (value === null || value === undefined || value === "")
            return "";
        if (typeof value === "number" && isFinite(value)) {
            let ts = value;
            if (ts < 1e12)
                ts *= 1000;
            const d = new Date(ts);
            if (!isNaN(d.getTime()))
                return d.toISOString();
            return "";
        }
        const d = new Date(String(value));
        if (!isNaN(d.getTime()))
            return d.toISOString();
        return "";
    }
}
