"""HTTP-сервер для build/web с fallback на index.html (go_router path URLs)."""
import sys
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

WEB = Path(__file__).resolve().parents[1] / "build" / "web"
PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8765


class SpaHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB), **kwargs)

    def send_error(self, code, message=None, explain=None):
        if code == 404:
            self.path = "/index.html"
            return self.do_GET()
        return super().send_error(code, message, explain)


if __name__ == "__main__":
    httpd = ThreadingHTTPServer(("127.0.0.1", PORT), SpaHandler)
    print(f"Serving {WEB} at http://127.0.0.1:{PORT}")
    httpd.serve_forever()
