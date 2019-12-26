# tunnelize

Makes HTTP services bound to local ports, common in web development environments accessible on the internet through a remote server, like a cheap vps that costs you 2$ per month. This allows you to expose your server so that your web site or service can be accessed by colleagues, or receive webhook calls. Essentially, an open-soruce self-hosted alternative to services like ngrok and serveo which have limited free usage.

tunnelize runs an instance of Caddy server on the remote server and uses the reverse port-forwarding feature of the OpenSSH SSH Client to pipe connections from caddy to your locally-running service.

Thanks to Caddy server's awesome TLS features, certificate generation is done automatically through Let's Encrypt. You can specify the email address that will be present in the TLS certificate, although this is optional.

## Usage

`tunnelize [-e|--tls-email=email] user@host <expr> [<expr>] ...`

`<expr>` is of the form: `<local_url>@<remote_vhost>`

```
tunnelize --tls-email me@myhost.com myuser@myhost.com \
  localhost:8080@frontend.expose.myhost.com \
  localhost:3000@backend.expose.myhost.com
```

`tunnelize` will have Caddy pipe connections from the given remote host to the local running service bound to localhost:6000. The remote host will listen on https and http (which redirects to https).  The https certificate will be associated with the given email address.

## Setting up the remote server

The remote server needs to have Caddy server installed on it, available through the caddy command. See the caddy server website on https://caddyserver.com/ for installation instructions. As of the time of writing, this is a manual process.

The caddy command will also need the special capability to bind to ports 80 and 443, unless you want to run the remote server as root, which is generally not advisable. This can be done via the following command, as root:

```
# setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy
```

Please mind that the location of the caddy command on your system may vary.

### DNS

A domain name is also required so that your services can be properly exposed under a domain name. It is recommended that you create a wildcard A/AAAA record under a subdomain so that you can easily create exposed services on the fly. The usage example given would assume that such a DNS record exists for `*.expose.myhost.com`, pointing to the remote host's IP address.
