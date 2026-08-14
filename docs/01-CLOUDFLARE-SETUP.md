# 01 – Cloudflare Tunnel + Token Setup

You already have the domain `stacktaskservices.systems` in Cloudflare (or it is propagating).  
Follow these exact steps.

## 1. Create the Tunnel

1. Go to https://dash.cloudflare.com → **Zero Trust** (left sidebar).  
   If prompted, choose the Free plan.
2. Networks → **Tunnels** → **Create a tunnel**.
3. Select **Cloudflared**.
4. Name it `dagvanguard-tunnel` (or any name you like).
5. Click **Save tunnel**.

## 2. Get the Token (easiest method)

On the next screen Cloudflare shows install commands.  
Look for the long token that starts with `eyJhIjoi...`.

Copy the entire token.

In the dagvanguard repo:

```bash
nano config/env
```

Set:

```bash
CLOUDFLARE_TUNNEL_TOKEN=eyJhIjoi...paste-the-whole-token-here
```

Also set the domain if not already:

```bash
DOMAIN=stacktaskservices.systems
```

Save the file.

## 3. (Optional) Classic credentials file

If you prefer the classic method instead of a token:

```bash
cloudflared tunnel login          # opens browser, select the domain
cloudflared tunnel create dagvanguard-tunnel
# note the Tunnel ID it prints
cloudflared tunnel route dns dagvanguard-tunnel viz.stacktaskservices.systems
```

Then edit `config/cloudflared.yml` with the Tunnel ID and credentials path.

The systemd unit supports **both** styles.

## 4. DNS records (automatic with Tunnel)

When you create the public hostnames inside the Tunnel dashboard (or use `tunnel route dns`), Cloudflare automatically creates the CNAME records pointing at the tunnel.

You should end up with:

| Type  | Name | Content                     | Proxy |
|-------|------|-----------------------------|-------|
| CNAME | viz  | `<tunnel-id>.cfargotunnel.com` | Proxied |

Because the records are Proxied (orange cloud), Cloudflare terminates SSL.  
You never need a certificate on the local host.

## 5. Optional – API Token for automatic DNS updates

If the host's public IP ever needs to be reflected in a classic A record (rare with Tunnel), create an API Token:

1. My Profile → API Tokens → Create Token.
2. Use the “Edit zone DNS” template.
3. Zone Resources → Include → Specific zone → `stacktaskservices.systems`.
4. Copy the token into `config/env` as `CLOUDFLARE_API_TOKEN=...`.
5. Also put the Zone ID (found on the domain overview page on the right) as `CLOUDFLARE_ZONE_ID=...`.

The IP watcher will then be able to update the A record automatically if you ever need it.

---

After the token is in `config/env`, just run:

```bash
./start.sh
```

The tunnel unit will pick it up and connect.
