# Architecture

DevFriction uses a small command router and reusable shell libraries. The security module separates listener discovery, binding classification, and presentation so that each responsibility stays testable.

```text
bin/devfriction
      ↓
CLI router
      ↓
libexec/devfriction-security-exposure-list
      ↓
lib/listeners.sh
      ↓
lib/classify.sh
      ↓
ss or lsof
```

| File | Responsibility |
| --- | --- |
| `bin/devfriction` | Routes commands such as `security exposure list`. |
| `lib/listeners.sh` | Discovers TCP listeners and normalizes their details. |
| `lib/classify.sh` | Classifies an address binding by scope. |
| `libexec/devfriction-security-exposure-list` | Creates the user-facing security report and risk context. |
| `tests/fixtures/listener-server.py` | Starts controlled listeners for automated tests. |
| `tests/security-exposure.bats` | Validates security-command behavior end to end. |

Normalized records contain the protocol, address, port, scope, PID, process, user, and discovery source. The exposure command consumes those records; it does not parse `lsof` or `ss` output itself.
