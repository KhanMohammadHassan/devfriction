# DevFriction

DevFriction is a developer-focused CLI toolkit that reduces recurring workflow friction, beginning with a defensive security module for inspecting local TCP listener exposure.

## The problem

Developers routinely start local services for development and testing. A service intended to be local can accidentally listen on every network interface instead:

```text
127.0.0.1:8000  → loopback-only
0.0.0.0:8000    → accepts connections on all local interfaces
```

Operating-system tools such as `lsof` and `ss` can list listeners, but their raw output is not a developer-oriented security assessment. It is easy to miss a binding that deserves review.

## The current solution

`devfriction security exposure list` inventories local TCP listeners, classifies their binding scope, identifies the owning process where the operating system provides it, and presents a readable assessment.

```text
OS listener data
       ↓
lib/listeners.sh
       ↓
normalized listener records
       ↓
lib/classify.sh
       ↓
security exposure list
       ↓
human-readable assessment
```

For example, a listener bound to all interfaces is reported as `POTENTIAL-NETWORK-EXPOSURE`, rather than as definitely exposed. Firewall and network conditions determine whether another machine can actually reach it.

## Try it

```bash
./bin/devfriction
./bin/devfriction security exposure list
./bin/devfriction port 8000
```

The security command is read-only. `devfriction port <port>` is the separate, confirmation-based workflow for inspecting and optionally terminating a local process that owns a port.

## Security scope

The current M1 security module focuses on local TCP listener discovery and binding classification. It does not scan remote systems, change firewall rules, terminate processes from the security command, or prove external reachability.

See [the security module documentation](docs/security-module.md) for the full scope and terminology.

## Verification

The repository uses BATS with real, temporary TCP listeners to verify both the existing port workflow and the security classification flow.

```bash
bats tests/port.bats tests/security-exposure.bats
```

Current result: **19 passing tests**.

## Documentation

- [Architecture](docs/architecture.md)
- [Security module](docs/security-module.md)
- [Testing](docs/testing.md)
- [Demo guide](docs/demo.md)
- [Roadmap](docs/roadmap.md)
