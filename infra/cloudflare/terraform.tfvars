# Non-secret config; secrets come from sops via `just`.
# First run: guessed from pi-tx's compose file. `just cf-import`, copy the real settings here,
# and `just cf-plan` until it shows no changes, before `just cf-apply`.

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
