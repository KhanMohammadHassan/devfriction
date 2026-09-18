#!/usr/bin/env python3

import http.server
import signal
import sys


def ignore_sigterm(signum, frame):
    print("SIGTERM received, ignoring it.", flush=True)


def main():
    if len(sys.argv) != 2:
        print("Usage: stubborn-server.py <port>", file=sys.stderr)
        sys.exit(2)

    port = int(sys.argv[1])

    signal.signal(signal.SIGTERM, ignore_sigterm)

    server = http.server.HTTPServer(
        ("127.0.0.1", port),
        http.server.SimpleHTTPRequestHandler,
    )

    actual_port = server.server_address[1]
    print(f"STUBBORN_SERVER_PORT={actual_port}", flush=True)

    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()