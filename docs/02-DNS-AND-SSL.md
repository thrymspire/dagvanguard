# 02 – DNS and SSL

## SSL decision

**We use Cloudflare’s free SSL.**  
No certificates are stored or renewed on the Pixel.

- Cloudflare terminates TLS at the edge.
- The Tunnel carries traffic encrypted from Cloudflare to `cloudflared` on the phone.
- Local services (Caddy, dagtko) speak plain HTTP on `127.0.0.1` only.

This is the strongest practical setup for a mobile always-on device.

## DNS records that should exist

Once the Tunnel is created and hostnames are configured you will see (or can create) these records in Cloudflare DNS:

```
Type   Name    Content                              Proxy status
CNAME  @       <TUNNEL_ID>.cfargotunnel.com         Proxied
CNAME  www     <TUNNEL_ID>.cfargotunnel.com         Proxied
CNAME  api     <TUNNEL_ID>.cfargotunnel.com         Proxied
CNAME  mcp     <TUNNEL_ID>.cfargotunnel.com         Proxied
CNAME  viz     <TUNNEL_ID>.cfargotunnel.com         Proxied
```

You can also add them from the Tunnel “Public Hostname” UI – Cloudflare creates the records for you.

## What happens when the public IP of the phone changes

With a Cloudflare Tunnel the public IP of the Pixel **does not matter**.  
The tunnel is an outbound connection from the phone to Cloudflare.  
Carrier IP changes, CGNAT, or moving between Wi-Fi and mobile data are all transparent.

The IP watcher is still useful for:

- visibility (you get notified if the phone’s egress IP changes),
- future classic A-record use cases,
- debugging.

## Manual DNS update (if you ever need an A record)

```bash
# after putting CLOUDFLARE_API_TOKEN and CLOUDFLARE_ZONE_ID in config/env
./scripts/ip-watch.py
```

Or edit the A record by hand in the Cloudflare dashboard (set TTL low while testing).

## Testing SSL

```bash
curl -I https://stacktaskservices.systems
curl -I https://api.stacktaskservices.systems
```

You should receive valid certificates issued by Google Trust Services or Let’s Encrypt under Cloudflare.
