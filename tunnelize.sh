#!/usr/bin/env bash

function usage {
  cat <<EOF

  Usage: tunnelize [-p|--provision] [-e|--tls-email=email] user@host <expr> [<expr>] ...

Makes HTTP services bound to local ports, common in web development environments
accessible on the internet through a remote server, like a cheap vps that costs you 2$.

Essentially, a self-hosted alternative to services like ngrok and serveo which have
limited free usage.

tunnelize runs an instance of Caddyproxy on the remote server and uses the reverse
port-forwarding feature of the OpenSSH SSH Client to pipe connections from
Caddyproxy to your locally-running service.

Thanks to Caddyproxy's awesome TLS features, certificate generation is done
automatically through Let's Encrypt. You can specify the email address that will
be present in the TLS certificate, although this is optional.

<expr> is of the following form:

  <local_url>@<remote_vhost>

Usage examples:
  expese --tls-email me@myhost.com myuser@myhost.com \
    localhost:8080@frontend.expose.myhost.com \
    localhost:3000@backend.expose.myhost.com

This means tunnelize will have Caddy pipe connections from the given remote host
to the local running service bound to localhost:6000. The remote host will listen
on https and http (which redirects to https).

There is no limit to the number of forwards you can specify. This can be useful
to either give remote access to your local development environment, or to receive
webhook callbacks from any service you are integrating.


  Provisioning

The remote host needs to be provisioned with an installation of Caddyproxy,
and, since you probably don't want to run the remote webserver as root,
to give it the capability to bound to lower ports 80 and 443. This can be done
either manually by the user, or automatically through the --provision switch.

EOF
}

function provision {
  echo "omg prov"
}

function ssh_connect {
  remote_vhost=$1
  tls_email=$2
  remote_port=$3
  forwards=$4

  caddy_config=''
  remote_ports=()
  reverse_proxies=()

  for forward in ${forwards[*]}; do
    if [[ $forward =~ (.+)@(.+) ]]; then
      local_url=${BASH_REMATCH[1]}
      remote_vhost=${BASH_REMATCH[2]}

      if ! (( ${#remote_ports[@]} )); then
        remote_ports+=('5000')
      else
        remote_ports+=($((${remote_ports[-1]} + 1000)))
      fi

      caddy_config="$caddy_config"$'\n'"$(parse_caddy_tmpl "$remote_vhost" "$tls_email" "${remote_ports[-1]}")"$'\n'
      reverse_proxies+=("-R ${remote_ports[-1]}:$local_url")
    else
      echo "Unknown <expr>: $forward"
      echo "See usage"
      exit 1
    fi
  done

  ssh -t -t "${reverse_proxies[@]}" "$host"  "caddy -agree -conf <(echo '$caddy_config')"
}


function parse_caddy_tmpl {
  remote_vhost=$1
  tls_email=$2
  remote_port=$3

  CADDY_TMPL='http://{{remote_vhost}}/ {
  redir https://{host}{uri}
}

https://{{remote_vhost}}/ {
  tls {{tls_email}}

  proxy / http://localhost:{{remote_port}} {
    transparent
  }
}'

  echo "$CADDY_TMPL" | \
    sed -e "s|{{remote_vhost}}|$remote_vhost|g" -e "s|{{tls_email}}|$tls_email|" -e "s|{{remote_port}}|$remote_port|"
}

if [[ "$#" -lt 1 ]]; then
  usage
  exit 1
fi

forwards=()
while (( "$#" )); do
  case "$1" in
    -p|--provision)
      provision=1
      shift
      ;;
    -e|--tls-email)
      tls_email=$2
      shift 2
      ;;
    --)
      shift
      break
      ;;
    --*|-*)
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *)
      if [[ -z $host ]]; then
        host="$1"
      else
        forwards+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ "$provision" == "1" ]]; then
  if [[ -z $host ]]; then
    echo "Error: --provision requires user@host"
    exit 1
  fi

  echo "Provisioning $host"
  provision "$host"
  exit 0
fi

ssh_connect "$remote_vhost" "$tls_email" "$remote_port" "${forwards[@]}"


