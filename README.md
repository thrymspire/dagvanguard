# dagvanguard

**Turn-key, self-healing production host for DAG Substrate (dagtko) + static showcase & Cloudflare Edge Tunnel**  
Designed for always-on Pixel 10 Pro XL (Debian 13 aarch64) and Linux/Docker environments.

- **Self-Healing Supervisor:** Survives terminal disconnects, process crashes, and system reboots via `systemd --user` with user session lingering.
- **Cloudflare Edge Tunnel:** Free automatic SSL + zero open inbound ports on the device (traffic routed securely via outbound encrypted tunnel).
- **Turnkey Standalone & Substrate Live Execution:** Automatic fallback to embedded mock/placeholder service with markers when standalone, and seamless discovery of full 250-node DAG substrate when linked.
- **Docker & Docker Compose Ready:** Single-container and multi-container configurations included.
- **Egress IP Watcher:** Dynamic detection of mobile network IP changes with optional Cloudflare DNS auto-sync and webhook notifications.

**Domain:** `stacktaskservices.systems`  
**Target Hardware:** Pixel 10 Pro XL · Debian 13 (trixie) · aarch64 · systemd user units / Docker

---

## Quick Start (Native Host)

```bash
# 1. Clone repository
git clone git@github.com:thrymspire/dagvanguard.git
cd dagvanguard

# 2. One-time install (cloudflared, caddy, dependencies, systemd user units)
./install.sh

# 3. Configure (Optional: add your Cloudflare Tunnel Token if you have it)
# edit config/env and set CLOUDFLARE_TUNNEL_TOKEN=...

# 4. Start everything
./start.sh
```

After every future `git pull`, simply run `./start.sh` to update and verify services.

---

## Docker & Docker Compose Deployment

### Option A: Docker Compose (Full Stack)
Run the entire stack (Caddy Reverse Proxy, Ingest API, MCP Server, Live Visualizer, PostgreSQL 16, Redis 7, and Cloudflare Tunnel):

```bash
docker compose up -d --build
```

### Option B: Standalone All-In-One Container
Run all microservices inside a single turnkey container:

```bash
# Build the image
docker build -t dagvanguard .

# Run with local port mappings
docker run -d \
  --name dagvanguard \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8000:8000 \
  -p 8001:8001 \
  -p 8050:8050 \
  -e CLOUDFLARE_TUNNEL_TOKEN="" \
  dagvanguard
```

---

## Running Services & Architecture

| Component              | Port (Local) | Public Endpoint (via Cloudflare Tunnel) | Description |
|------------------------|--------------|-----------------------------------------|-------------|
| **Static Showcase Site** | `8080` (Caddy) | `https://stacktaskservices.systems` | Static visualizer showcase & path-based reverse proxy |
| **dagtko Domain API**  | `8000`       | `https://api.stacktaskservices.systems` | FastAPI typed edge/event emitter, work orders & Ollama grounding |
| **dagtko MCP Server**  | `8001`       | `https://mcp.stacktaskservices.systems` | MCP tool surface for AI agent DAG pipeline operations |
| **Live Visualizer**    | `8050`       | `https://viz.stacktaskservices.systems` | Symbol-centric Cytoscape graph visualizer |
| **Health Ping**        | `8081` (Caddy) | Internal / Local monitor | Local heartbeat verification |
| **Cloudflare Tunnel**  | Outbound     | All public hostnames above | Encrypted outbound tunnel, automatic TLS termination |
| **IP Watcher**         | Timer (5min) | — | Tracks public IP changes and synchronizes DNS |

All local microservices bind to `127.0.0.1` / internal network. Only `cloudflared` communicates with the internet.

---

## Standalone Fallbacks & Turnkey Placeholders

When PostgreSQL or the native `dagtko` foundation is warming up or deployed standalone, DAG Vanguard automatically activates the internal fallback runner (`scripts/placeholder_server.py`):
- Endpoints return `200 OK` with structured responses and explicit markers: `[DAGVANGUARD_PLACEHOLDER_ACTIVE]`, `[DAGVANGUARD_MOCK_SUCCESS]`.
- As soon as the substrate is mounted at `DAGTKO_ROOT` (default `/home/droid/dagtko`), full native 250-node services take over seamlessly.

---

## Cloudflare Tunnel & SSL Configuration

1. In Cloudflare Dashboard → **Zero Trust** → **Networks** → **Tunnels**:
   - Create a tunnel named `dagvanguard-pixel`.
   - Copy your Tunnel Token (`eyJhIjoi...`).
2. Add your token to `config/env`:
   ```bash
   CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoi...
   ```
3. Restart the tunnel service:
   ```bash
   systemctl --user restart dag-tunnel.service
   ```
4. Configure public hostnames in Cloudflare Zero Trust:
   - `stacktaskservices.systems` → `http://127.0.0.1:8080`
   - `api.stacktaskservices.systems` → `http://127.0.0.1:8000`
   - `mcp.stacktaskservices.systems` → `http://127.0.0.1:8001`
   - `viz.stacktaskservices.systems` → `http://127.0.0.1:8050`

See [01-CLOUDFLARE-SETUP.md](docs/01-CLOUDFLARE-SETUP.md) and [02-DNS-AND-SSL.md](docs/02-DNS-AND-SSL.md) for step-by-step guides.

---

## Status & Operational Commands

```bash
# Check complete status table
./status.sh

# Run comprehensive healthcheck across all ports
./scripts/healthcheck.sh

# Stop all background units
./stop.sh

# View live tunnel or service logs
journalctl --user -u dag-tunnel -f
journalctl --user -u dag-api -f
```

---

## Directory Structure

```
dagvanguard/
├── Dockerfile                   # Production container definition
├── docker-compose.yml           # Full multi-container composition
├── docker-entrypoint.sh         # Flexible container entrypoint supervisor
├── install.sh                   # Native host one-time installer
├── start.sh                     # Idempotent turn-key launcher
├── stop.sh                      # Clean shutdown script
├── status.sh                    # Live status dashboard reporter
├── config/
│   ├── Caddyfile                # Reverse proxy & static routing rules
│   ├── env.example              # Environment variables template
│   └── cloudflared.yml.example  # Cloudflare tunnel configuration template
├── systemd/                     # Systemd user service units & timers
│   ├── dag-api.service
│   ├── dag-caddy.service
│   ├── dag-ipwatch.service
│   ├── dag-ipwatch.timer
│   ├── dag-mcp.service
│   ├── dag-tunnel.service
│   └── dag-visualizer.service
├── scripts/                     # Operational scripts & fallbacks
│   ├── healthcheck.sh           # Automated health verification
│   ├── ip-watch.py              # Egress IP tracker & DNS updater
│   ├── notify.sh                # Webhook & Telegram notification helper
│   ├── placeholder_server.py    # Fallback mock service runner
│   ├── start-dagtko.sh          # Microservice launcher
│   └── start-tunnel.sh          # Cloudflare tunnel supervisor
├── static/                      # Static showcase site & vector assets
│   ├── index.html
│   └── assets/                  # High-resolution DAG SVG topologies
└── docs/                        # Complete setup, DNS, recovery & tuning guides
```

---

## License

Open source, production-oriented substrate tooling.
