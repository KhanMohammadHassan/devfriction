#!/usr/bin/env bats

PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
EXPOSURE_COMMAND="$PROJECT_ROOT/libexec/devfriction-security-exposure-list"
DEVFRICTION="$PROJECT_ROOT/bin/devfriction"
LISTENER_SERVER="$BATS_TEST_DIRNAME/fixtures/listener-server.py"

setup() {
    SERVER_PID=""
    SERVER_PORT=""
}

teardown() {
    if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill "$SERVER_PID" 2>/dev/null || true
    fi

    if [[ -n "$SERVER_PID" ]]; then
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

port_is_listening() {
    lsof -nP -iTCP:"$SERVER_PORT" -sTCP:LISTEN -t >/dev/null 2>&1
}

start_listener() {
    local address="$1"
    local port_file="$BATS_TEST_TMPDIR/listener-port"

    python3 "$LISTENER_SERVER" "$address" >"$port_file" 2>"$BATS_TEST_TMPDIR/listener.log" &
    SERVER_PID=$!

    for _ in {1..50}; do
        if [[ -s "$port_file" ]]; then
            SERVER_PORT="$(head -n 1 "$port_file")"
            if [[ "$SERVER_PORT" =~ ^[0-9]+$ ]] && port_is_listening; then
                return 0
            fi
        fi

        sleep 0.1
    done

    echo "Listener failed to start."
    cat "$BATS_TEST_TMPDIR/listener.log"
    return 1
}

@test "security exposure list --help displays usage" {
    run "$EXPOSURE_COMMAND" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: devfriction security exposure list"* ]]
    [[ "$output" == *"This command is read-only."* ]]
}

@test "security exposure list rejects unexpected arguments" {
    run "$EXPOSURE_COMMAND" unexpected

    [ "$status" -eq 2 ]
    [[ "$output" == *"Error: unexpected argument: unexpected"* ]]
}

@test "direct command classifies a loopback listener as local-only" {
    start_listener "127.0.0.1"

    run "$EXPOSURE_COMMAND"

    [ "$status" -eq 0 ]
    local listener_row="tcp[[:space:]]+127\\.0\\.0\\.1[[:space:]]+${SERVER_PORT}[[:space:]]+loopback"
    [[ "$output" =~ $listener_row ]]
    [[ "$output" == *"LOCAL-ONLY"* ]]
}

@test "routed command classifies an all-interface listener as potential exposure" {
    start_listener "0.0.0.0"

    run "$DEVFRICTION" security exposure list

    [ "$status" -eq 0 ]
    local listener_row="tcp[[:space:]]+(\\*|0\\.0\\.0\\.0)[[:space:]]+${SERVER_PORT}[[:space:]]+all-interfaces"
    [[ "$output" =~ $listener_row ]]
    [[ "$output" == *"POTENTIAL-NETWORK-EXPOSURE"* ]]
}
