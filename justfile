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
    # A fresh random state passphrase, so the example value can never end up in use.
    pw="$(openssl rand -base64 32)"
    perl -pi -e "s{^tofu_state_passphrase: \"\"}{tofu_state_passphrase: \"$pw\"}" "$tmp"
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
    zone="$(sed -nE 's/^zone *= *"([^"]+)".*/\1/p' {{ cf_dir }}/terraform.tfvars)"
    zone_id="$(curl -fsS -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
      "https://api.cloudflare.com/client/v4/zones?name=$zone" \
      | python3 -c 'import json,sys; r=json.load(sys.stdin)["result"]; print(r[0]["id"] if r else "")')"
    [[ -n "$zone_id" ]] || { echo "zone $zone not visible to this API token" >&2; exit 1; }

    # cf-terraforming reads the provider schema from an initialised working directory and
    # can't parse the real one (state encryption block), so give it a throwaway one, on tofu.
    work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
    printf 'terraform {\n  required_providers {\n    cloudflare = {\n      source  = "cloudflare/cloudflare"\n      version = "~> 5.0"\n    }\n  }\n}\n' > "$work/main.tf"
    cp {{ cf_dir }}/.terraform.lock.hcl "$work/"
    tofu -chdir="$work" init -input=false >/dev/null
    cft=(--terraform-binary-path "$(command -v tofu)" --terraform-install-path "$work")

    out="{{ cf_dir }}/generated"; mkdir -p "$out"; : > "$out/imports.tf"
    failed=()
    grab() {  # grab <--account|--zone> <id> <resource type>
      if cf-terraforming generate "${cft[@]}" "$1" "$2" --resource-type "$3" > "$out/$3.tf" \
         && cf-terraforming import "${cft[@]}" "$1" "$2" --resource-type "$3" --modern-import-block >> "$out/imports.tf"; then
        echo "  ok      $3"
      else
        echo "  FAILED  $3" >&2; failed+=("$3")
      fi
    }
    for r in cloudflare_zero_trust_tunnel_cloudflared cloudflare_zero_trust_tunnel_cloudflared_config \
             cloudflare_zero_trust_access_application cloudflare_zero_trust_access_policy; do
      grab --account "$acct" "$r"
    done
    grab --zone "$zone_id" cloudflare_dns_record
    echo "Wrote $out/. Copy the real values into terraform.tfvars and the import blocks into"
    echo "imports.tf (addresses as shown there), then 'just cf-plan' until it shows no changes."
    if (( ${#failed[@]} )); then
      echo "Not generated: ${failed[*]}. Fill those import IDs in imports.tf by hand (formats shown there)." >&2
      exit 1
    fi

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
    if (( ${#TF_VAR_state_passphrase} < 16 )) || [[ "$TF_VAR_state_passphrase" == change-me* ]]; then
      echo "tofu_state_passphrase in {{ secrets }} must be a real random value (16+ chars):" >&2
      echo "  openssl rand -base64 32" >&2
      exit 1
    fi
    # .terraform/ isn't committed; fetch the provider on first use (to stderr, so `output -json` stays clean).
    [[ -d {{ cf_dir }}/.terraform ]] || tofu -chdir={{ cf_dir }} init -input=false >&2
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
    # No silent fallback: an empty map would make the teslamate role drop cloudflared.
    # SKIP_TUNNEL_TOKENS=1 skips the lookup (e.g. for --tags base); hosts that run a tunnel
    # then fail their token check instead of losing the connector.
    if [[ -n "${SKIP_TUNNEL_TOKENS:-}" ]]; then
      tokens='{}'
    elif ! tokens="$(just _tofu output -json tunnel_tokens)"; then
      echo "Couldn't read tunnel tokens from OpenTofu (error above). 'just cf-plan' to check;" >&2
      echo "before Cloudflare is adopted, run 'just cf-import' and 'just cf-apply' first." >&2
      exit 1
    fi
    export CLOUDFLARE_TUNNEL_TOKENS="$tokens"
    cd {{ ansible_dir }} && ansible-playbook site.yml {{ args }}

# Lint everything (shell, ansible, tofu)
[group('checks')]
lint:
    shellcheck bootstrap.sh scripts/*
    cd {{ ansible_dir }} && ansible-lint
    tofu -chdir={{ cf_dir }} fmt -check -recursive
    [[ -d {{ cf_dir }}/.terraform ]] || TF_VAR_state_passphrase=placeholder-not-a-secret tofu -chdir={{ cf_dir }} init -input=false >/dev/null
    TF_VAR_state_passphrase=placeholder-not-a-secret tofu -chdir={{ cf_dir }} validate
