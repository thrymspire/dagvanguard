# 02 – DNS and SSL

## SSL decision

**We use Cloudflare’s free SSL.**  
No certificates need to be manually stored or renewed on the local host.

- Cloudflare terminates TLS at the edge.
- The Tunnel carries traffic encrypted from Cloudflare to `cloudflared` on the host.
- Local services speak plain HTTP on `127.0.0.1` only.

This is the strongest practical setup for an edge-hosted service.

## DNS records that should exist

Once the Tunnel is created and hostnames are configured you will see (or can create) this record in Cloudflare DNS:

```
Type   Name    Content                              Proxy status
CNAME  viz     <TUNNEL_ID>.cfargotunnel.com         Proxied
```

You can also add it from the Tunnel “Public Hostname” UI – Cloudflare creates the records for you.

## What happens when the public IP of the host changes

With a Cloudflare Tunnel the public IP of the host **does not matter**.  
The tunnel is an outbound connection from the host to Cloudflare.  
Network changes, CGNAT, or moving between Wi-Fi and ethernet/mobile data are all transparent.

The IP watcher is still useful for:

- visibility (you get notified if the host’s egress IP changes),
- future classic A-record use cases,
- debugging.

## Testing SSL

```bash
curl -I https://viz.stacktaskservices.systems
```

You should receive valid certificates issued under Cloudflare.
