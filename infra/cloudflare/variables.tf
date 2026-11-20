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
    }))
  }))
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
