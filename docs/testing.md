# Testing

DevFriction uses [BATS](https://bats-core.readthedocs.io/) to exercise actual command behavior rather than only testing text helpers.

## Run the suite

```bash
bats tests/port.bats tests/security-exposure.bats
```

The current suite has **19 passing tests**.

## Exposure classification tests

The security tests start a controlled Python TCP listener, wait until the operating system reports it, run DevFriction, and always stop the listener during teardown.

```text
BATS
 ↓
temporary listener on 127.0.0.1
 ↓
security exposure list
 ↓
loopback + LOCAL-ONLY
```

```text
BATS
 ↓
temporary listener on 0.0.0.0
 ↓
security exposure list
 ↓
all-interfaces + POTENTIAL-NETWORK-EXPOSURE
```

The suite also verifies the security command’s help text, invalid arguments, and the routed CLI path.

## Existing port workflow

`tests/port.bats` protects the original command’s behavior: validation, unused ports, confirmation, graceful termination, and confirmed forceful termination. This regression coverage prevents security-module changes from silently breaking the existing workflow.
