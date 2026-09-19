# Security exposure module

## What it detects

`devfriction security exposure list` inspects local TCP listeners and classifies their binding as one of:

| Scope | Meaning |
| --- | --- |
| `loopback` | Bound only to the local machine, such as `127.0.0.1` or `::1`. |
| `all-interfaces` | Bound to all local interfaces, such as `0.0.0.0`, `::`, or `*`. |
| `interface-bound` | Bound to one non-loopback interface address. |
| `link-local` | Bound to a link-local address, such as `169.254.x.x` or `fe80::/10`. |
| `unknown` | The binding could not be classified safely. |

It also reports process, PID, and user details when the operating system exposes them, plus limited port context for services that commonly warrant review.

## Potential exposure is not proven reachability

`all-interfaces` means that a service accepts connections on all local interfaces. DevFriction labels this as `POTENTIAL-NETWORK-EXPOSURE`; it does not claim external reachability because firewall rules, routing, VPNs, and network policy may prevent access.

## Scope and boundaries

Does:

- Inspect local TCP listeners.
- Classify listener bindings.
- Identify process, PID, and user details when available.
- Provide risk context without changing system state.

Does not:

- Perform remote port scanning.
- Modify firewall or network configuration.
- Terminate processes through the security command.
- Prove that a listener is reachable from another machine.

The existing `devfriction port <port>` command remains the separate action workflow and asks for confirmation before process termination.
