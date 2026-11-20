# Non-secret config. Secrets (account id, emails, API token) come from sops via `just`.
#
# FIRST RUN: these reflect what pi-tx's compose file implies, not what Cloudflare
# actually has. Run `just cf-import`, copy the real ingress/app settings over these,
# and keep running `just cf-plan` until it reports no changes before you `cf-apply`.

zone = "floo.ca"

tunnels = {
  "pi-tx" = {
    ingress = [
      { hostname = "arthur.floo.ca", path = "^/dash", service = "http://grafana:3000" },
      { hostname = "arthur.floo.ca", service = "http://teslamate:4000" },
    ]
  }
}

access_apps = {
  teslamate = {
    name   = "TeslaMate"
    domain = "arthur.floo.ca"
  }
}
