output "tunnel_tokens" {
  description = "Connector token per host, consumed by Ansible (`just pi-apply`)."
  value       = { for k, t in data.cloudflare_zero_trust_tunnel_cloudflared_token.this : k => t.token }
  sensitive   = true
}

output "tunnel_ids" {
  value = { for k, t in cloudflare_zero_trust_tunnel_cloudflared.this : k => t.id }
}
