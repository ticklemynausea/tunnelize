# tunnelize

Exposes HTTP services bound to local ports, common in web development environments,
to make them  accessible on the internet through a remote server, like a cheap vps
that costs you 2$.

Essentially, a self-hosted alternative to services like ngrok and serveo which have
limited free usage.

tunnelize runs an instance of Caddyproxy on the remote server and uses the reverse
port-forwarding feature of the OpenSSH SSH Client to pipe connections from
Caddyproxy to your locally-running service.

Thanks to Caddyproxy's awesome TLS features, certificate generation is done
automatically through Let's Encrypt. You can specify the email address that will
be present in the TLS certificate, although this is optional.


## 💩
As this is still a work in progress, it is still not as consumable as I want it to be.
It works, but it still lacks instructions and a provisioning feature to install Caddy
and configure the VPS server.

