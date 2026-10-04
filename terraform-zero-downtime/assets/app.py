"""Tiny demo web app.

- Waits STARTUP_DELAY seconds before it starts listening (simulates a slow boot,
  so "container is running" and "app is ready" are two different moments).
- Reads its banner ONCE at startup (so a config change needs a new container).
- Keeps no data itself: /store/<key> reads and writes values in the data store,
  which it finds by name on the Docker network. While there is no store, those
  two routes answer 503 and everything else keeps working.
- Exits immediately on SIGTERM (fast, clean shutdown).
"""
import os
import signal
import socket
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VERSION = os.environ.get("APP_VERSION", "unknown")
DELAY = float(os.environ.get("STARTUP_DELAY", "5"))
BANNER_FILE = os.environ.get("BANNER_FILE", "/config/banner.txt")
PORT = int(os.environ.get("PORT", "8080"))
STORE_HOST = os.environ.get("STORE_HOST", "store")


def read_banner():
    try:
        with open(BANNER_FILE) as f:
            return f.read().strip()
    except OSError:
        return "(no banner)"


BANNER = read_banner()


def store(*command):
    """Send one command to the store (Redis); return its reply, or None for a missing key.

    Redis speaks a small text protocol, so a socket is enough for GET and SET.
    A real application would use a client library.
    """
    parts = [part.encode() for part in command]
    request = b"*%d\r\n" % len(parts) + b"".join(b"$%d\r\n%b\r\n" % (len(p), p) for p in parts)
    with socket.create_connection((STORE_HOST, 6379), timeout=1) as conn:
        conn.sendall(request)
        reply = conn.makefile("rb")
        head = reply.readline().rstrip()
        if head.startswith(b"$"):  # a value follows; a length of -1 means "no such key"
            size = int(head[1:])
            return None if size < 0 else reply.read(size).decode()
        if head.startswith(b"-"):
            raise OSError(head[1:].decode())
        return head[1:].decode()  # a status such as OK


class Handler(BaseHTTPRequestHandler):
    def route(self):
        """One case per endpoint; returns the status and the text of the answer."""
        match self.command, self.path.strip("/").split("/"):
            case "GET", [""]:  # what the traffic generator asks for
                return 200, f"version={VERSION} banner={BANNER}"
            case "GET", ["health"]:  # readiness: must not depend on the store
                return 200, "ok"
            case "GET", ["store", key]:
                value = store("GET", key)
                return (200, value) if value is not None else (404, f"{key} is not set")
            case "PUT", ["store", key]:
                size = int(self.headers.get("Content-Length", 0))
                store("SET", key, self.rfile.read(size).decode())
                return 200, f"stored {key}"
            case _:
                return 404, "not found"

    def respond(self):
        try:
            status, text = self.route()
        except OSError:  # no store (yet), or it does not answer
            status, text = 503, "store unavailable"
        body = f"{text}\n".encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    do_GET = do_PUT = respond

    def log_message(self, *args):
        pass


signal.signal(signal.SIGTERM, lambda *_: os._exit(0))
time.sleep(DELAY)
ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
