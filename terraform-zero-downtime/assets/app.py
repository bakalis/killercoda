"""Tiny demo web app.

- Waits STARTUP_DELAY seconds before it starts listening (simulates a slow boot,
  so "container is running" and "app is ready" are two different moments).
- Reads its banner ONCE at startup (so a config change needs a new container).
- Exits immediately on SIGTERM (fast, clean shutdown).
"""
import os
import signal
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

VERSION = os.environ.get("APP_VERSION", "unknown")
DELAY = float(os.environ.get("STARTUP_DELAY", "5"))
BANNER_FILE = os.environ.get("BANNER_FILE", "/config/banner.txt")
PORT = int(os.environ.get("PORT", "8080"))


def read_banner():
    try:
        with open(BANNER_FILE) as f:
            return f.read().strip()
    except OSError:
        return "(no banner)"


BANNER = read_banner()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = b"ok\n" if self.path == "/health" else f"version={VERSION} banner={BANNER}\n".encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass


signal.signal(signal.SIGTERM, lambda *_: os._exit(0))
time.sleep(DELAY)
ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
