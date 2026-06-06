# Template for ~/.secrets.sh — machine-private shell config.
#
# Copy to ~/.secrets.sh and fill in real values; ~/.zshrc sources it last so it
# can override anything above. NEVER commit the populated file — it holds
# environment-specific endpoints, internal tool paths, and private role names
# that must not live in this public repo (see D2 in plan.md). Values below are
# placeholders.

# --- Repo checkout (enables the HOMEBREW_BUNDLE_FILE default in .zshrc) ---
# export DOTFILES="${HOME}/path/to/initial-setup"

# --- Environment-specific endpoints ---
# export VAULT_ADDR="https://vault.example.internal/"

# --- AWS role assumption (org-internal injector tool) ---
# Point IAM_INJECTOR at your injector script, then the assume() helper works.
# export IAM_INJECTOR="${HOME}/path/to/iam-role-injector/meta_assume.sh"
#
# assume() {
#   local role="${1:?Usage: assume <role-name>}"
#   if [[ -f "${IAM_INJECTOR:-}" ]]; then
#     source "${IAM_INJECTOR}" "${role}"
#   else
#     echo "IAM injector not found — set IAM_INJECTOR in ~/.secrets.sh" >&2
#     return 1
#   fi
# }
#
# Private per-role convenience aliases (names are environment-specific):
# alias dev='assume <dev-role>'
# alias prd='assume <prd-role>'
# alias devops='assume <devops-role>'
