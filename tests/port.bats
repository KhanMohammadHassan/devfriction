#!/usr/bin/env bats

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