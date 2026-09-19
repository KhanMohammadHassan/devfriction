# Roadmap

## Completed: M1 — local TCP exposure detection

M1 provides:

- `devfriction security exposure list`
- Shared local TCP listener discovery using `ss` or `lsof`
- Binding classification and limited risk annotation
- Read-only reporting of local listener state
- Manual checks for loopback and all-interface bindings
- Automated BATS coverage for the security command

## Next: M2 — exposure memory

M2 will add a snapshot and comparison workflow:

```text
security exposure snapshot
        ↓
security exposure diff
```

The goal is to identify meaningful binding changes, such as a service moving from `127.0.0.1` to `0.0.0.0`, as a potential security regression.

## Later: M3

After M1 and M2 are stable, possible additions include structured JSON output, a CI-oriented check command, and Docker context. These are planned ideas, not features currently provided by the project.
