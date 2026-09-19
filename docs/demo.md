# Demo guide

Use this sequence for a short demonstration. Run it only on a machine you control.

## 1. Inspect the current listener inventory

```bash
./bin/devfriction security exposure list
```

Explain: DevFriction converts local listener data into a binding-scope assessment without changing any system state.

## 2. Demonstrate a local-only listener

In one terminal:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

In another terminal:

```bash
./bin/devfriction security exposure list
```

Show the listener’s address, port, `loopback` scope, and `LOCAL-ONLY` assessment. Stop the server with `Ctrl-C`.

## 3. Demonstrate an all-interface listener

In one terminal:

```bash
python3 -m http.server 8000 --bind 0.0.0.0
```

In another terminal:

```bash
./bin/devfriction security exposure list
```

Show its `all-interfaces` scope and `POTENTIAL-NETWORK-EXPOSURE` assessment. Clarify that this does not prove external reachability; firewall and network policy still apply. Stop the server with `Ctrl-C`.

## 4. Demonstrate the existing action workflow

With a server still listening on port `8000`:

```bash
./bin/devfriction port 8000
```

Explain that the security command only detects and reports, while `port` asks before terminating a process.

## Pitch outline

1. **Problem:** development services can be bound more broadly than intended.
2. **Why it matters:** raw OS output is easy to overlook during normal work.
3. **Solution:** DevFriction inventories listeners and explains their binding scope.
4. **How it works:** listener discovery → binding classification → readable report.
5. **Proof:** live listener demonstrations and automated tests.
6. **Limitations:** no remote scanning and no reachability claim.
7. **Future:** snapshots and diffs to identify exposure regressions over time.
