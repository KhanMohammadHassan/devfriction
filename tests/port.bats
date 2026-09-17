#!/usr/bin/env bats
#fixture support

PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
DEVFRICTION="$PROJECT_ROOT/bin/devfriction"
STUBBORN_SERVER="$BATS_TEST_DIRNAME/fixtures/stubborn-server.py"

TEST_PORT=45678
SERVER_PID=""

setup() {
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

start_stubborn_server() {
    python3 "$STUBBORN_SERVER" "$TEST_PORT" \
        >"$BATS_TEST_TMPDIR/stubborn-server.log" 2>&1 &

    SERVER_PID=$!

    for _ in {1..50}; do
        if lsof -nP -iTCP:"$TEST_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
            return 0
        fi

        sleep 0.1
    done

    echo "Stubborn server failed to start."
    cat "$BATS_TEST_TMPDIR/stubborn-server.log"
    return 1
}
#end of fixture support


PROJECT_ROOT="$BATS_TEST_DIRNAME/.."
DEVFRICTION="$PROJECT_ROOT/bin/devfriction"

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

@test "port rejects values above 65535" {
    run "$DEVFRICTION" port 65536

    [ "$status" -eq 2 ]
    [[ "$output" == *"Error: port must be between 1 and 65535."* ]]
}

@test "port reports an unused port" {
    run "$DEVFRICTION" port 65535

    [ "$status" -eq 0 ]
    [[ "$output" == *"Port 65535 is not in use."* ]]
}
setup() {
    TEST_PORT=45678
    SERVER_PID=""
}

teardown() {
    if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" 2>/dev/null; then
        kill -KILL "$SERVER_PID" 2>/dev/null || true
    fi
}

start_server() {
    python3 -m http.server "$TEST_PORT" >/tmp/devfriction-test-server.log 2>&1 &
    SERVER_PID=$!

    for _ in {1..20}; do
        if lsof -nP -iTCP:"$TEST_PORT" -sTCP:LISTEN -t >/dev/null 2>&1; then
            return 0
        fi

        sleep 0.1
    done

    echo "Test server failed to start."
    return 1
}

#Added the SIGKILL decline test

@test "port does not terminate process when user declines" {
    start_server

    run bash -c "printf 'n\n' | '$DEVFRICTION' port '$TEST_PORT'"

    [ "$status" -eq 0 ]
    [[ "$output" == *"No action taken."* ]]

    kill -0 "$SERVER_PID"
}
@test "port terminates a normal process with SIGTERM" {
    start_server

    run bash -c "printf 'y\n' | '$DEVFRICTION' port '$TEST_PORT'"

    [ "$status" -eq 0 ]
    [[ "$output" == *"Sending SIGTERM..."* ]]
    [[ "$output" == *"Port $TEST_PORT is now available."* ]]

    ! kill -0 "$SERVER_PID" 2>/dev/null
}

@test "port keeps stubborn process alive when SIGKILL is declined" {
    start_stubborn_server

    run bash -c "printf 'y\nn\n' | '$DEVFRICTION' port '$TEST_PORT'"

    [ "$status" -eq 1 ]
    [[ "$output" == *"Process is still running after SIGTERM."* ]]
    [[ "$output" == *"Force termination with SIGKILL? [y/N]:"* ]]
    [[ "$output" == *"No forceful termination."* ]]

    kill -0 "$SERVER_PID"
}