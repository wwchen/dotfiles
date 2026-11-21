variable "state_passphrase" {
  description = "Passphrase for state encryption (from sops)."
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "Cloudflare account ID (from sops)."
  type        = string
}

variable "zone" {
  description = "DNS zone the tunnel hostnames live in."
  type        = string
}

variable "tunnels" {
  description = <<-EOT
    One remotely-managed tunnel per host. Key = Ansible inventory hostname, so the
    token can be handed to that host. Ingress rules are matched top to bottom; a
    final 404 catch-all is added automatically.
  EOT
  type = map(object({
    ingress = list(object({
      hostname = string
      service  = string
      path     = optional(string)
      # e.g. { no_tls_verify = true }
      origin_request = optional(object({
        access = optional(object({
          aud_tag   = list(string) # required by the provider whenever `access` is set
          team_name = string
          required  = optional(bool)
        }))
        ca_pool                  = optional(string)
        connect_timeout          = optional(number)
        disable_chunked_encoding = optional(bool)
        http2_origin             = optional(bool)
        http_host_header         = optional(string)
        keep_alive_connections   = optional(number)
        keep_alive_timeout       = optional(number)
        match_sn_ito_host        = optional(bool)
        no_happy_eyeballs        = optional(bool)
        no_tls_verify            = optional(bool)
        origin_server_name       = optional(string)
        proxy_type               = optional(string)
        tcp_keep_alive           = optional(number)
        tls_timeout              = optional(number)
      }))
    }))
  }))

  validation {
    condition = alltrue([
      for h in distinct(flatten([for t in values(var.tunnels) : [for r in t.ingress : r.hostname]])) :
      length([for t in values(var.tunnels) : t if contains([for r in t.ingress : r.hostname], h)]) == 1
    ])
    error_message = "Each hostname must belong to exactly one tunnel (its DNS record can only point at one)."
  }
}

variable "access_apps" {
  description = "Cloudflare Access self-hosted apps, gated to access_allowed_emails."
  type = map(object({
    name             = string
    domain           = string
    session_duration = optional(string, "24h")
  }))
  default = {}
}

variable "access_allowed_emails" {
  description = "Emails allowed through Access (from sops)."
  type        = list(string)
  sensitive   = true
}
