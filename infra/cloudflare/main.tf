data "cloudflare_zone" "this" {
  filter = {
    name = var.zone
  }
}

# --- Tunnels -----------------------------------------------------------------

resource "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  for_each = var.tunnels

  account_id = var.account_id
  name       = each.key
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  for_each = var.tunnels

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[each.key].id

  config = {
    ingress = concat(
      [for r in each.value.ingress : {
        hostname       = r.hostname
        service        = r.service
        path           = r.path
        origin_request = r.origin_request
      }],
      [{ service = "http_status:404" }],
    )
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "this" {
  for_each = var.tunnels

  account_id = var.account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.this[each.key].id
}

# One proxied CNAME per distinct hostname, pointing at its tunnel.
locals {
  tunnel_hostnames = merge([
    for host, t in var.tunnels : { for r in t.ingress : r.hostname => host }
  ]...)
}

resource "cloudflare_dns_record" "tunnel" {
  for_each = local.tunnel_hostnames

  zone_id = data.cloudflare_zone.this.zone_id
  name    = each.key
  type    = "CNAME"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.this[each.value].id}.cfargotunnel.com"
  proxied = true
  ttl     = 1
}

# --- Access ------------------------------------------------------------------

resource "cloudflare_zero_trust_access_policy" "allow_me" {
  account_id = var.account_id
  name       = "Allow my emails"
  decision   = "allow"
  include    = [for e in var.access_allowed_emails : { email = { email = e } }]
}

resource "cloudflare_zero_trust_access_application" "this" {
  for_each = var.access_apps

  account_id       = var.account_id
  name             = each.value.name
  domain           = each.value.domain
  type             = "self_hosted"
  session_duration = each.value.session_duration

  policies = [{
    id         = cloudflare_zero_trust_access_policy.allow_me.id
    precedence = 1
  }]
}
