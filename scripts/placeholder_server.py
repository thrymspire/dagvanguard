#!/usr/bin/env python3
"""
DAGVanguard Fallback Placeholder & Mock Service Runner.
Provides fully functional mock endpoints on ports 8000, 8001, and 8050
when DAG Substrate / PostgreSQL is in standalone mode or initializing.
"""

from __future__ import annotations

import json
import sys
import time
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Any

MODE = sys.argv[1] if len(sys.argv) > 1 else "api"
PORT_MAP = {
    "api": 8000,
    "mcp": 8001,
    "visualizer": 8050,
}
PORT = PORT_MAP.get(MODE, 8000)

SAMPLE_GRAPH_DATA = {
    "counts": {
        "total_nodes": 250,
        "total_edges": 501,
        "total_events": 90,
        "projected_nodes": 250,
        "matrix_entries": 90,
        "buckets": 7,
        "fragments": 12,
    },
    "marker": "[DAGVANGUARD_PLACEHOLDER_ACTIVE]",
    "nodes": [
        {"id": "00000000-0000-0000-0000-000000000001", "name": "DAG Substrate Root", "node_type": "root", "layer": 0},
        {"id": "00000000-0000-0000-0000-000000000002", "name": "Ledger Set 90-Matrix", "node_type": "section", "layer": 1},
        {"id": "00000000-0000-0000-0000-000000000003", "name": "Projections Substrate", "node_type": "section", "layer": 1},
        {"id": "00000000-0000-0000-0000-000000000004", "name": "Cloudflare Edge Vanguard", "node_type": "object", "layer": 2},
    ],
    "edges": [
        {"from": "00000000-0000-0000-0000-000000000001", "to": "00000000-0000-0000-0000-000000000002", "type": "Specifies"},
        {"from": "00000000-0000-0000-0000-000000000001", "to": "00000000-0000-0000-0000-000000000003", "type": "Specifies"},
        {"from": "00000000-0000-0000-0000-000000000002", "to": "00000000-0000-0000-0000-000000000004", "type": "Emits"},
    ],
}

HTML_VIZ_PLACEHOLDER = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>DAG Substrate Live Visualizer [Placeholder Mode]</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    :root {
      --bg: #090d16;
      --card: #111827;
      --border: #1f2937;
      --text: #f3f4f6;
      --accent: #38bdf8;
      --accent-dim: #0284c7;
      --success: #10b981;
      --muted: #9ca3af;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      padding: 1.5rem;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
    }
    header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-bottom: 1rem;
      border-bottom: 1px solid var(--border);
      margin-bottom: 1.5rem;
    }
    .badge {
      display: inline-flex;
      align-items: center;
      gap: 0.4rem;
      background: rgba(16, 185, 129, 0.15);
      color: var(--success);
      padding: 0.35rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.85rem;
      font-weight: 600;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 1rem;
      margin-bottom: 1.5rem;
    }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1rem;
    }
    .card-title { font-size: 0.8rem; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; }
    .card-val { font-size: 1.75rem; font-weight: bold; color: var(--accent); margin-top: 0.35rem; }
    .canvas-container {
      flex: 1;
      min-height: 420px;
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: 1.5rem;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      text-align: center;
    }
    svg { max-width: 100%; height: auto; }
    .notice { margin-top: 1rem; color: var(--muted); font-size: 0.9rem; }
  </style>
</head>
<body>
  <header>
    <div>
      <h1>DAG Substrate Visualizer</h1>
      <p style="color: var(--muted); font-size: 0.9rem;">Turnkey Standalone & Substrate Live Surface</p>
    </div>
    <div class="badge"><span style="display:inline-block;width:8px;height:8px;border-radius:50%;background:var(--success);"></span> OPERATIONAL</div>
  </header>

  <div class="grid">
    <div class="card"><div class="card-title">Nodes</div><div class="card-val" id="cnt-nodes">250</div></div>
    <div class="card"><div class="card-title">Edges</div><div class="card-val" id="cnt-edges">501</div></div>
    <div class="card"><div class="card-title">Matrix Entries</div><div class="card-val" id="cnt-matrix">90</div></div>
    <div class="card"><div class="card-title">Buckets</div><div class="card-val" id="cnt-buckets">7</div></div>
  </div>

  <div class="canvas-container">
    <svg width="480" height="240" viewBox="0 0 480 240" fill="none" xmlns="http://www.w3.org/2000/svg">
      <circle cx="80" cy="120" r="30" fill="#1e293b" stroke="#38bdf8" stroke-width="2"/>
      <text x="80" y="125" text-anchor="middle" fill="#f8fafc" font-size="11" font-weight="600">ROOT</text>
      
      <path d="M 110 120 L 210 70" stroke="#38bdf8" stroke-width="2" stroke-dasharray="4"/>
      <path d="M 110 120 L 210 170" stroke="#38bdf8" stroke-width="2"/>

      <circle cx="240" cy="70" r="30" fill="#1e293b" stroke="#818cf8" stroke-width="2"/>
      <text x="240" y="75" text-anchor="middle" fill="#f8fafc" font-size="10">90-Matrix</text>

      <circle cx="240" cy="170" r="30" fill="#1e293b" stroke="#818cf8" stroke-width="2"/>
      <text x="240" y="175" text-anchor="middle" fill="#f8fafc" font-size="10">Projections</text>

      <path d="M 270 70 L 370 120" stroke="#818cf8" stroke-width="2"/>
      <path d="M 270 170 L 370 120" stroke="#818cf8" stroke-width="2"/>

      <circle cx="400" cy="120" r="30" fill="#1e293b" stroke="#34d399" stroke-width="2"/>
      <text x="400" y="125" text-anchor="middle" fill="#f8fafc" font-size="10">Vanguard</text>
    </svg>
    <div class="notice">
      Marker: <code>[DAGVANGUARD_PLACEHOLDER_ACTIVE]</code> — Turnkey status ready.
    </div>
  </div>
</body>
</html>
"""


class PlaceholderHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code: int, data: Any):
        payload = json.dumps(data, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
        self.wfile.write(payload)

    def _send_html(self, status_code: int, html_text: str):
        payload = html_text.encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_GET(self):
        path = self.path.split("?")[0]

        if MODE == "visualizer":
            if path in ("/", "/index.html"):
                self._send_html(200, HTML_VIZ_PLACEHOLDER)
                return
            elif path == "/api/data":
                self._send_json(200, SAMPLE_GRAPH_DATA)
                return

        elif MODE == "mcp":
            if path in ("/", "/health"):
                self._send_json(200, {
                    "status": "ok",
                    "service": "dagtko-mcp",
                    "mode": "placeholder",
                    "marker": "[DAGVANGUARD_PLACEHOLDER_ACTIVE]",
                    "tools_registered": 4,
                    "categories": {"domain_ledger": 2, "dynamic_dag": 1, "image_sideload": 1},
                })
                return
            elif path in ("/tools", "/mcp/tools"):
                self._send_json(200, [
                    {
                        "name": "list_ledger_nodes",
                        "description": "List nodes in the Ledger Set DAG [Placeholder Mode]",
                        "inputSchema": {"type": "object", "properties": {"layer": {"type": "integer"}}},
                    },
                    {
                        "name": "get_ledger_node",
                        "description": "Get detailed node properties and symbolic SVG [Placeholder Mode]",
                        "inputSchema": {"type": "object", "properties": {"node_id": {"type": "string"}}},
                    },
                    {
                        "name": "execute_dag_pipeline",
                        "description": "Execute or query DAG pipeline [Placeholder Mode]",
                        "inputSchema": {"type": "object", "properties": {"pipeline_id": {"type": "string"}}},
                    },
                ])
                return

        # Default / API mode
        if path == "/health":
            self._send_json(200, {
                "status": "ok",
                "service": "dagtko-api",
                "mode": "placeholder",
                "marker": "[DAGVANGUARD_PLACEHOLDER_ACTIVE]",
                "timestamp": int(time.time()),
            })
            return
        elif path == "/work-orders":
            self._send_json(200, [
                {
                    "work_order_id": "00000000-0000-0000-0000-000000000001",
                    "title": "Turnkey DAG Vanguard Initial Baseline",
                    "status": "active",
                    "marker": "[DAGVANGUARD_INITIALIZED]",
                }
            ])
            return
        elif path in ("/", "/status", "/nodes"):
            self._send_json(200, {
                "service": "dagtko-api",
                "status": "operational",
                "mode": "placeholder",
                "marker": "[DAGVANGUARD_PLACEHOLDER_ACTIVE]",
                "endpoints": ["/health", "/work-orders", "/nodes"],
                "data": SAMPLE_GRAPH_DATA,
            })
            return

        self._send_json(404, {"error": "Not Found", "path": path, "mode": "placeholder"})

    def do_POST(self):
        path = self.path.split("?")[0]
        content_len = int(self.headers.get("Content-Length", 0))
        post_body = self.rfile.read(content_len) if content_len > 0 else b"{}"
        try:
            body_json = json.loads(post_body.decode("utf-8"))
        except Exception:
            body_json = {}

        if MODE == "mcp" and path in ("/tools/call", "/call", "/mcp/call"):
            tool_name = body_json.get("name", "unknown")
            self._send_json(200, {
                "content": [
                    {
                        "type": "text",
                        "text": f"Mock MCP response for tool '{tool_name}' [DAGVANGUARD_MOCK_SUCCESS]",
                    }
                ],
                "is_error": False,
            })
            return

        # Generic API POST
        self._send_json(200, {
            "status": "accepted",
            "marker": "[DAGVANGUARD_MOCK_SUCCESS]",
            "echo": body_json,
        })

    def log_message(self, format, *args):
        return  # Suppress console clutter


def run():
    print(f"=== DAGVanguard Placeholder Server [{MODE.upper()}] ===")
    print(f"  Listening on http://0.0.0.0:{PORT}")
    print(f"  Marker: [DAGVANGUARD_PLACEHOLDER_ACTIVE]")
    server = HTTPServer(("0.0.0.0", PORT), PlaceholderHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        server.server_close()


if __name__ == "__main__":
    run()
