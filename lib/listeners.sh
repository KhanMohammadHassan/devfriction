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