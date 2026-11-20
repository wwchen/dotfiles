# Personal infra.
#   just          pick a command (type to filter, enter to run)
#   just -l       list commands
#   just <Tab>    complete command names

set shell := ["bash", "-euo", "pipefail", "-c"]

secrets := "secrets/infra.sops.yaml"
ansible_dir := "infra/ansible"
cf_dir := "infra/cloudflare"

[private]
default:
    @if command -v fzf >/dev/null && [ -t 0 ]; then just --choose; else just --list --unsorted; fi

# Set up / re-check this Mac (interactive)
[group('mac')]
bootstrap *args:
    ./bootstrap.sh {{ args }}

# Show what `apply` would change in your home folder (uses this checkout)
[group('mac')]
diff:
    chezmoi --source {{ justfile_directory() }} diff

# Apply dotfiles; installs anything missing from the Brewfiles
[group('mac')]
apply:
    chezmoi --source {{ justfile_directory() }} apply -v

# Dry run of apply: list every file and script it would change or run, change nothing
[group('mac')]
apply-dry:
    chezmoi --source {{ justfile_directory() }} apply --dry-run --verbose

# Walk through installed-vs-Brewfile drift and update the Brewfiles
[group('mac')]
brew-sync:
    scripts/brew-sync

# Report Brewfile drift only (exit 1 if any)
[group('mac')]
brew-check:
    scripts/brew-sync --check

# Save iTerm2's "Default" profile (the one to tweak in Settings) into the repo
[group('mac')]
iterm-export profile="Default":
    scripts/iterm-export "{{ profile }}"
    @echo "Next: git diff to review, then 'just apply' to load it into iTerm2."

# Create secrets/infra.sops.yaml from the example (once)
[group('secrets')]
secrets-init:
    #!/usr/bin/env bash
    set -euo pipefail
    test ! -e {{ secrets }} || { echo "{{ secrets }} already exists"; exit 1; }
    # Encrypt via a temp file so a sops failure never leaves plaintext at the real path.
    tmp="secrets/.tmp-$$.sops.yaml"
    trap 'rm -f "$tmp" "$tmp.enc"' EXIT
    cp secrets/infra.example.yaml "$tmp"
    sops encrypt "$tmp" > "$tmp.enc"
    mv "$tmp.enc" {{ secrets }}
    echo "Now run: just secrets-edit"

# Edit encrypted secrets in $EDITOR
[group('secrets')]
secrets-edit:
    sops {{ secrets }}

# Generate HCL + import blocks for what already exists in Cloudflare (first-time adoption)
[group('cloudflare')]
cf-import:
    #!/usr/bin/env bash
    set -euo pipefail
    export CLOUDFLARE_API_TOKEN="$(sops -d --extract '["cloudflare"]["api_token"]' {{ secrets }})"
    acct="$(sops -d --extract '["cloudflare"]["account_id"]' {{ secrets }})"
    out="{{ cf_dir }}/generated"; mkdir -p "$out"
    for r in cloudflare_zero_trust_tunnel_cloudflared cloudflare_zero_trust_tunnel_cloudflared_config \
             cloudflare_zero_trust_access_application cloudflare_zero_trust_access_policy; do
      cf-terraforming generate --account "$acct" --resource-type "$r" > "$out/$r.tf" || true
      cf-terraforming import   --account "$acct" --resource-type "$r" --modern-import-block >> "$out/imports.tf" || true
    done
    echo "Wrote $out/ — copy the real values into terraform.tfvars, then 'just cf-plan' until it shows no changes."

# Preview Cloudflare changes
[group('cloudflare')]
cf-plan:
    @just _tofu plan

# Apply Cloudflare changes
[group('cloudflare')]
cf-apply:
    @just _tofu apply

[private]
_tofu *args:
    #!/usr/bin/env bash
    set -euo pipefail
    export CLOUDFLARE_API_TOKEN="$(sops -d --extract '["cloudflare"]["api_token"]' {{ secrets }})"
    export TF_VAR_account_id="$(sops -d --extract '["cloudflare"]["account_id"]' {{ secrets }})"
    export TF_VAR_access_allowed_emails="$(sops -d --extract '["cloudflare"]["access_allowed_emails"]' --output-type json {{ secrets }})"
    export TF_VAR_state_passphrase="$(sops -d --extract '["tofu_state_passphrase"]' {{ secrets }})"
    tofu -chdir={{ cf_dir }} {{ args }}

# Dry run: show what would change on a host (or group)
[group('pis')]
pi-check host="all" *args:
    @just _ansible --check --diff --limit {{ host }} {{ args }}

# Apply the playbook to a host (or group)
[group('pis')]
pi-apply host="all" *args:
    @just _ansible --diff --limit {{ host }} {{ args }}

[private]
_ansible *args:
    #!/usr/bin/env bash
    set -euo pipefail
    # Tunnel tokens come from OpenTofu state so Cloudflare stays the single source of truth.
    export CLOUDFLARE_TUNNEL_TOKENS="$(just _tofu output -json tunnel_tokens 2>/dev/null || echo '{}')"
    cd {{ ansible_dir }} && ansible-playbook site.yml {{ args }}

# Lint everything (shell, ansible, tofu)
[group('checks')]
lint:
    shellcheck bootstrap.sh scripts/*
    cd {{ ansible_dir }} && ansible-lint
    tofu -chdir={{ cf_dir }} fmt -check -recursive
    TF_VAR_state_passphrase=placeholder-not-a-secret tofu -chdir={{ cf_dir }} validate
