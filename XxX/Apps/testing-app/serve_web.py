import http.server
import socketserver
import os
import sys

PORT = 8060
DIRECTORY = os.path.join(os.path.dirname(os.path.abspath(__file__)), "build", "web")

class GodotHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-cache, no-store, must-revalidate")
        super().end_headers()

if __name__ == "__main__":
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("127.0.0.1", PORT), GodotHTTPRequestHandler) as httpd:
        print(f"Serving Godot web build at http://127.0.0.1:{PORT}/")
        sys.stdout.flush()
        httpd.serve_forever()
