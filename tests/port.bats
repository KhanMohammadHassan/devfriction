#!/usr/bin/env bats

PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
DEVFRICTION="$PROJECT_ROOT/bin/devfriction"
STUBBORN_SERVER="$BATS_TEST_DIRNAME/fixtures/stubborn-server.py"

setup() {
    TEST_PORT="$(python3 -c 'import socket; s = socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()')"
    SERVER_PID=""
}

teardown() {
    if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill -KILL "$SERVER_PID" 2>/dev/null || true
    fi

    if [[ -n "$SERVER_PID" ]]; then
        wait "$SERVER_PID" 2>/dev/null || true
    fi
}

port_is_listening() {
    lsof -nP -iTCP:"$TEST_PORT" -sTCP:LISTEN -t >/dev/null 2>&1
}

wait_for_port() {
    for _ in {1..50}; do
        if port_is_listening; then
            return 0
        fi

        sleep 0.1
    done

    return 1
}

start_server() {
    python3 -m http.server "$TEST_PORT" \
        >"$BATS_TEST_TMPDIR/test-server.log" 2>&1 &

    SERVER_PID=$!

    if wait_for_port; then
        return 0
    fi

    echo "Test server failed to start."
    cat "$BATS_TEST_TMPDIR/test-server.log"
    return 1
}

start_stubborn_server() {
    python3 "$STUBBORN_SERVER" "$TEST_PORT" \
        >"$BATS_TEST_TMPDIR/stubborn-server.log" 2>&1 &

    SERVER_PID=$!

    if wait_for_port; then
        return 0
    fi

    echo "Stubborn server failed to start."
    cat "$BATS_TEST_TMPDIR/stubborn-server.log"
    return 1
}

@test "port --help displays usage" {
    run "$DEVFRICTION" port --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage: devfriction port <port>"* ]]
}

@test "port fails when no port is provided" {
    run "$DEVFRICTION" port

    [ "$status" -eq 2 ]
    [[ "$output" == *"Error: a port number is required."* ]]
}

@test "port rejects non-numeric input" {
    run "$DEVFRICTION" port abc

    [ "$status" -eq 2 ]
    [[ "$output" == *"Error: port must be a number."* ]]
}

@test "port rejects port zero" {
    run "$DEVFRICTION" port 0

    [ "$status" -eq 2 ]
    [[ "$output" == *"Error: port must be between 1 and 65535."* ]]
}

@test "port accepts port one" {
    run "$DEVFRICTION" port 1

    [ "$status" -eq 0 ]
    [[ "$output" != *"Error: port must be between 1 and 65535."* ]]
}

@test "port rejects values above 65535" {
    run "$DEVFRICTION" port 65536

    [ "$status" -eq 2 ]
    [[ "$output" == *"Error: port must be between 1 and 65535."* ]]
}

@test "port accepts the maximum port" {
    run "$DEVFRICTION" port 65535

    [ "$status" -eq 0 ]
    [[ "$output" != *"Error: port must be between 1 and 65535."* ]]
}

@test "port normalizes leading-zero ports" {
    run "$DEVFRICTION" port 03000

    [ "$status" -eq 0 ]
    [[ "$output" == *"Port 3000 is not in use."* ]]
}

@test "port reports an unused port" {
    run "$DEVFRICTION" port 65535

    [ "$status" -eq 0 ]
    [[ "$output" == *"Port 65535 is not in use."* ]]
}

@test "port detects a listening process" {
    start_server

    run bash -c "printf 'n\n' | '$DEVFRICTION' port '$TEST_PORT' 2>&1"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Status:  IN USE"* ]]
    [[ "$output" == *"Process:"* ]]
    [[ "$output" == *"PID:"* ]]
    [[ "$output" == *"No action taken."* ]]

    port_is_listening
}

@test "port does not terminate process when user declines" {
    start_server

    run bash -c "printf '\n' | '$DEVFRICTION' port '$TEST_PORT' 2>&1"

    [ "$status" -eq 0 ]
    [[ "$output" == *"No action taken."* ]]

    port_is_listening
}

@test "port terminates a normal process with SIGTERM" {
    start_server

    run bash -c "printf 'y\n' | '$DEVFRICTION' port '$TEST_PORT' 2>&1"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Sending SIGTERM..."* ]]
    [[ "$output" == *"Port $TEST_PORT is now available."* ]]

    ! port_is_listening
    wait "$SERVER_PID" 2>/dev/null || true
}

@test "port keeps stubborn process alive when SIGKILL is declined" {
    start_stubborn_server

    run bash -c "printf 'y\nn\n' | '$DEVFRICTION' port '$TEST_PORT' 2>&1"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Process is still running after SIGTERM."* ]]
    #[[ "$output" == *"Force termination with SIGKILL?"* ]]
    [[ "$output" == *"No forceful termination."* ]]

    port_is_listening
}

@test "port forcefully terminates stubborn process when SIGKILL is confirmed" {
    start_stubborn_server

    run bash -c "printf 'y\ny\n' | '$DEVFRICTION' port '$TEST_PORT' 2>&1"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Process is still running after SIGTERM."* ]]
    [[ "$output" == *"Sending SIGKILL..."* ]]
    [[ "$output" == *"Port $TEST_PORT is now available."* ]]

    ! port_is_listening
    wait "$SERVER_PID" 2>/dev/null || true
}

@test "port does not SIGKILL stubborn process on invalid confirmation" {
    start_stubborn_server

    run bash -c "printf 'y\nabc\n' | '$DEVFRICTION' port '$TEST_PORT' 2>&1"

    [ "$status" -eq 1 ]
    [[ "$output" == *"No forceful termination."* ]]

    port_is_listening
}