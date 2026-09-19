#!/usr/bin/env python3
"""Start one TCP listener for BATS exposure-command tests."""

import signal
import socket
import sys


def main() -> None:
    address = sys.argv[1]
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind((address, 0))
    server.listen()

    print(server.getsockname()[1], flush=True)

    def stop(_signum: int, _frame: object) -> None:
        server.close()
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    while True:
        try:
            connection, _ = server.accept()
        except OSError:
            break
        else:
            connection.close()


if __name__ == "__main__":
    main()
