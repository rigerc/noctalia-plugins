#!/usr/bin/env bash
set -euo pipefail

ACTION_DELAY_SECONDS="${ACTION_DELAY_SECONDS:-3}"
FOCUS_DELAY_SECONDS="${FOCUS_DELAY_SECONDS:-1}"
WORKSPACE_DELAY_SECONDS="${WORKSPACE_DELAY_SECONDS:-2}"
PRESET_DELAY_SECONDS="${PRESET_DELAY_SECONDS:-5}"
IPC_CMD=()
PRESET_LIMIT=""

ORIGINAL_SETTINGS_JSON=""
ORIGINAL_WORKSPACE_ID=""

log() {
    printf '[scrollbar-test] %s\n' "$*"
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$1" >&2
        exit 1
    fi
}

resolve_ipc_cmd() {
    if [[ -n "${NOCTALIA_IPC_CMD:-}" ]]; then
        # shellcheck disable=SC2206
        IPC_CMD=(${NOCTALIA_IPC_CMD})
        return
    fi

    if command -v noctalia-shell >/dev/null 2>&1; then
        IPC_CMD=(noctalia-shell)
        return
    fi

    if command -v qs >/dev/null 2>&1; then
        if qs -c noctalia-shell ipc show >/dev/null 2>&1; then
            IPC_CMD=(qs -c noctalia-shell)
            return
        fi

        if qs ipc show >/dev/null 2>&1; then
            IPC_CMD=(qs)
            return
        fi
    fi

    printf 'Unable to find a working Noctalia IPC command. Set NOCTALIA_IPC_CMD if needed.\n' >&2
    exit 1
}

ipc_call() {
    "${IPC_CMD[@]}" ipc call "$@"
}

hypr_json() {
    hyprctl -j "$@"
}

hypr_dispatch() {
    hyprctl dispatch "$@"
}

sleep_after_action() {
    sleep "$ACTION_DELAY_SECONDS"
}

sleep_after_focus() {
    sleep "$FOCUS_DELAY_SECONDS"
}

sleep_after_workspace() {
    sleep "$WORKSPACE_DELAY_SECONDS"
}

sleep_after_preset() {
    sleep "$PRESET_DELAY_SECONDS"
}

run_action() {
    local description="$1"
    shift
    log "$description"
    "$@"
    sleep_after_action
}

run_focus_action() {
    local description="$1"
    shift
    log "$description"
    "$@"
    sleep_after_focus
}

run_workspace_action() {
    local description="$1"
    shift
    log "$description"
    "$@"
    sleep_after_workspace
}

get_active_workspace_id() {
    hypr_json activeworkspace | jq -r '.id'
}

list_workspace_client_addresses() {
    local workspace_id="$1"
    hypr_json clients | jq -r --argjson workspace_id "$workspace_id" \
        '.[] | select(.workspace.id == $workspace_id and .workspace.id >= 0) | .address'
}

count_workspace_clients() {
    local workspace_id="$1"
    hypr_json clients | jq -r --argjson workspace_id "$workspace_id" \
        '[.[] | select(.workspace.id == $workspace_id and .workspace.id >= 0)] | length'
}

ensure_workspace_has_windows() {
    local workspace_id="$1"
    if [[ "$(count_workspace_clients "$workspace_id")" -gt 0 ]]; then
        return
    fi

    run_action "No windows on workspace ${workspace_id}; launching kitty" hypr_dispatch exec kitty
}

find_new_address() {
    local before_file="$1"
    local after_file="$2"
    while IFS= read -r address; do
        if ! grep -Fxq "$address" "$before_file"; then
            printf '%s\n' "$address"
            return 0
        fi
    done <"$after_file"
    return 1
}

close_newest_workspace_client() {
    local workspace_id="$1"
    local before_file after_file new_address

    before_file="$(mktemp)"
    after_file="$(mktemp)"
    list_workspace_client_addresses "$workspace_id" >"$before_file"

    run_action "Opening kitty on workspace ${workspace_id}" hypr_dispatch exec kitty
    list_workspace_client_addresses "$workspace_id" >"$after_file"

    new_address=""
    if new_address="$(find_new_address "$before_file" "$after_file")"; then
        run_action "Closing new kitty window ${new_address}" hypr_dispatch closewindow "address:${new_address}"
    else
        run_action "Falling back to closing the active window" hypr_dispatch killactive anything
    fi

    rm -f "$before_file" "$after_file"
}

open_three_kitties_and_close_one() {
    local workspace_id="$1"

    run_action "Opening kitty 1 on workspace ${workspace_id}" hypr_dispatch exec kitty
    run_action "Opening kitty 2 on workspace ${workspace_id}" hypr_dispatch exec kitty
    run_action "Opening kitty 3 on workspace ${workspace_id}" hypr_dispatch exec kitty
    run_action "Closing one active window on workspace ${workspace_id}" hypr_dispatch killactive anything
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --presets)
                if [[ $# -lt 2 ]]; then
                    printf 'Missing value for --presets\n' >&2
                    exit 1
                fi
                PRESET_LIMIT="$2"
                if ! [[ "$PRESET_LIMIT" =~ ^[1-9][0-9]*$ ]]; then
                    printf 'Invalid --presets value: %s\n' "$PRESET_LIMIT" >&2
                    exit 1
                fi
                shift 2
                ;;
            *)
                printf 'Unknown argument: %s\n' "$1" >&2
                exit 1
                ;;
        esac
    done
}

restore_state() {
    local exit_code="$1"

    if [[ -n "$ORIGINAL_SETTINGS_JSON" ]]; then
        log "Restoring original Scrollbar settings"
        ipc_call plugin:scrollbar applySettingsSnapshot "$ORIGINAL_SETTINGS_JSON" >/dev/null || true
    fi

    if [[ -n "$ORIGINAL_WORKSPACE_ID" ]]; then
        log "Restoring workspace ${ORIGINAL_WORKSPACE_ID}"
        hypr_dispatch workspace "$ORIGINAL_WORKSPACE_ID" >/dev/null || true
    fi

    exit "$exit_code"
}

main() {
    parse_args "$@"

    require_cmd hyprctl
    require_cmd jq
    require_cmd kitty
    resolve_ipc_cmd

    ORIGINAL_SETTINGS_JSON="$(ipc_call plugin:scrollbar getSettingsSnapshot)"
    ORIGINAL_WORKSPACE_ID="$(get_active_workspace_id)"

    trap 'restore_state $?' EXIT INT TERM

    local presets_json
    presets_json="$(ipc_call plugin:scrollbar listPresets)"

    mapfile -t preset_ids < <(printf '%s\n' "$presets_json" | jq -r '.[].id')
    if [[ "${#preset_ids[@]}" -eq 0 ]]; then
        log "No presets available"
        return
    fi

    if [[ -n "$PRESET_LIMIT" && "$PRESET_LIMIT" -lt "${#preset_ids[@]}" ]]; then
        preset_ids=("${preset_ids[@]:0:$PRESET_LIMIT}")
    fi

    log "Testing ${#preset_ids[@]} presets"

    for preset_id in "${preset_ids[@]}"; do
        log "Preset: ${preset_id}"
        run_action "Loading ${preset_id}" ipc_call plugin:scrollbar loadPreset "$preset_id"

        run_workspace_action "Switching to workspace 1" hypr_dispatch workspace 1
        ensure_workspace_has_windows 1
        run_focus_action "Browsing windows on workspace 1" hypr_dispatch cyclenext
        close_newest_workspace_client 1

        run_workspace_action "Switching to workspace 2" hypr_dispatch workspace 2
        open_three_kitties_and_close_one 2
        run_workspace_action "Returning to workspace 1" hypr_dispatch workspace 1

        log "Waiting before next preset"
        sleep_after_preset
    done

    log "Preset test run completed"
}

main "$@"
