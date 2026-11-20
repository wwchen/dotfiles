# Adopt existing Cloudflare resources. `just cf-import` writes the IDs to generated/imports.tf;
# move the blocks here with these `to` addresses, then `just cf-plan`.
# import {
#   to = cloudflare_zero_trust_tunnel_cloudflared.this["pi-tx"]
#   id = "<account_id>/<tunnel_id>"
# }
# import {
#   to = cloudflare_zero_trust_tunnel_cloudflared_config.this["pi-tx"]
#   id = "<account_id>/<tunnel_id>"
# }
# import {
#   to = cloudflare_dns_record.tunnel["arthur.floo.ca"]
#   id = "<zone_id>/<dns_record_id>"
# }
# import {
#   to = cloudflare_zero_trust_access_application.this["teslamate"]
#   id = "accounts/<account_id>/<app_id>"
# }
# import {
#   to = cloudflare_zero_trust_access_policy.allow_me
#   id = "<account_id>/<policy_id>"
# }
