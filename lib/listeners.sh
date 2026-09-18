#!/usr/bin/env bash

# ------------------------------------------------------------
# Existing raw listener functions
#
# These are kept compatible with devfriction-port.
# ------------------------------------------------------------

list_tcp_listeners() {
    local port="${1:-}"

    if ! command -v lsof >/dev/null 2>&1; then
        return 127
    fi

    if [[ -n "$port" ]]; then
        lsof -nP "-iTCP:$port" -sTCP:LISTEN -Fpcun 2>/dev/null
    else
        lsof -nP -iTCP -sTCP:LISTEN -Fpcun 2>/dev/null
    fi
}

get_listener_pids() {
    local port="$1"

    list_tcp_listeners "$port" |
        awk '/^p/ { print substr($0, 2) }' |
        sort -u
}


# ------------------------------------------------------------
# Security exposure inventory
#
# Output format:
#
# proto <TAB> addr <TAB> port <TAB> scope <TAB> pid
#       <TAB> process <TAB> user <TAB> source
#
# Example:
#
# tcp  0.0.0.0  3000  all-interfaces  4521  node  hassan  ss
# ------------------------------------------------------------

_normalize_listener_address() {
    local endpoint="$1"

    # Remove surrounding brackets from IPv6.
    endpoint="${endpoint#[}"
    endpoint="${endpoint%]}"

    printf '%s\n' "$endpoint"
}


_extract_endpoint_address() {
    local endpoint="$1"

    # [IPv6]:PORT
    if [[ "$endpoint" == \[*\]:* ]]; then
        printf '%s\n' "${endpoint%%]:*}]"
        return
    fi

    # IPv4 / hostname / wildcard:
    # everything before the final :PORT
    printf '%s\n' "${endpoint%:*}"
}


_extract_endpoint_port() {
    local endpoint="$1"

    printf '%s\n' "${endpoint##*:}"
}


_ss_process_name() {
    local process_field="$1"

    # Example:
    # users:(("node",pid=4521,fd=23))
    #
    # Extract "node".
    printf '%s\n' "$process_field" |
        sed -n 's/.*(("\([^"]*\)".*/\1/p'
}


_ss_process_pid() {
    local process_field="$1"

    # Extract pid=1234
    printf '%s\n' "$process_field" |
        sed -n 's/.*pid=\([0-9][0-9]*\).*/\1/p'
}


_get_process_user() {
    local pid="$1"

    [[ -n "$pid" ]] || {
        printf '%s\n' "unknown"
        return
    }

    ps -o user= -p "$pid" 2>/dev/null |
        awk '{$1=$1; print; exit}'
}


_get_process_name() {
    local pid="$1"
    local fallback="${2:-unknown}"

    if [[ -n "$pid" ]]; then
        local name
        name="$(ps -o comm= -p "$pid" 2>/dev/null |
            awk '{$1=$1; print; exit}')"

        [[ -n "$name" ]] && {
            printf '%s\n' "$name"
            return
        }
    fi

    printf '%s\n' "$fallback"
}


_list_tcp_listeners_ss() {
    local line

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        # ss -H -tlnp fields:
        #
        # STATE RECV-Q SEND-Q LOCAL PEER USERS
        #
        # Example:
        # LISTEN 0 511 0.0.0.0:3000 0.0.0.0:* users:(("node",pid=4521,fd=23))

        read -r _state _recv_q _send_q local_endpoint _peer process_field <<< "$line"

        [[ -n "$local_endpoint" ]] || continue

        local addr
        local port
        local pid
        local process
        local user
        local scope

        addr="$(_extract_endpoint_address "$local_endpoint")"
        port="$(_extract_endpoint_port "$local_endpoint")"

        addr="$(_normalize_listener_address "$addr")"

        [[ "$port" =~ ^[0-9]+$ ]] || continue

        pid="$(_ss_process_pid "$process_field")"
        process="$(_ss_process_name "$process_field")"

        [[ -n "$process" ]] || process="unknown"

        user="$(_get_process_user "$pid")"

        # classify_binding is provided by lib/classify.sh
        if declare -F classify_binding >/dev/null 2>&1; then
            scope="$(classify_binding "$addr")"
        else
            scope="unknown"
        fi

        printf 'tcp\t%s\t%s\t%s\t%s\t%s\t%s\tss\n' \
            "$addr" \
            "$port" \
            "$scope" \
            "${pid:-unknown}" \
            "$process" \
            "$user"

    done < <(ss -H -tlnp 2>/dev/null)
}


_list_tcp_listeners_lsof() {
    if ! command -v lsof >/dev/null 2>&1; then
        return 127
    fi

    # macOS / fallback path.
    #
    # Use +c 15 to keep process names reasonably readable.
    lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null |
        awk '
        NR == 1 {
            next
        }

        {
            process=$1
            pid=$2
            user=$3

            endpoint=$(NF-1)

            if (endpoint !~ /\(LISTEN\)$/ && $NF !~ /\(LISTEN\)$/) {
                next
            }

            sub(/ \(LISTEN\)$/, "", endpoint)

            if (endpoint ~ /^\[/) {
                addr=endpoint
                sub(/^\[/, "", addr)
                sub(/\]:[0-9]+$/, "", addr)

                port=endpoint
                sub(/^.*\]:/, "", port)
            } else {
                addr=endpoint
                sub(/:[^:]*$/, "", addr)

                port=endpoint
                sub(/^.*:/, "", port)
            }

            if (addr == "*") {
                scope="all-interfaces"
            } else if (addr == "127.0.0.1" ||
                       addr == "::1" ||
                       addr == "localhost") {
                scope="loopback"
            } else if (addr ~ /^169\.254\./ ||
                       addr ~ /^fe80:/ ||
                       addr ~ /^FE80:/) {
                scope="link-local"
            } else {
                scope="interface-bound"
            }

            printf "tcp\t%s\t%s\t%s\t%s\t%s\t%s\tlsof\n",
                   addr,
                   port,
                   scope,
                   pid,
                   process,
                   user
        }'
}


list_normalized_tcp_listeners() {
    # Linux / WSL:
    # prefer ss because it is the native socket inventory.
    if command -v ss >/dev/null 2>&1; then
        _list_tcp_listeners_ss
        return $?
    fi

    # macOS / fallback:
    if command -v lsof >/dev/null 2>&1; then
        _list_tcp_listeners_lsof
        return $?
    fi

    return 127
}