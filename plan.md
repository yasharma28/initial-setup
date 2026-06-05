# initial-setup — modernization plan

Living audit of the repo against the owner's code standards (`~/.claude/rules/`)
and industry-standard dotfiles practice. We walk the repo in dependency order
(leaves → orchestration → governance/docs); each round is finalized here before
any code changes. Implementation happens **after** the whole audit is agreed.

Audit order: 1) shell/terminal · 2) editors · 3) brew · 4) secrets-adjacent
(aws/ssh) · 5) windows · 6) scripts · 7) Makefile · 8) meta + governance/CI ·
9) README.

---

## Cross-cutting decisions (apply repo-wide)

These were settled during Round 1 but govern every later round:

- **D1 — Deployment via GNU Stow.** Stop `cp`-ing configs into place (the source
  of drift we fought all session). Restructure dotfiles into per-tool Stow
  packages; deployment becomes `stow <pkg>`, symlinking into `$HOME`. The repo
  becomes the single source of truth — edits to live files write straight back.
  Touches: directory layout (Rounds 1–5), `scripts/`, `Makefile` (Rounds 6–7).
- **D2 — Repo must be portable + public-safe.** The repo is public and is meant
  to deploy on **both personal and work laptops**. No machine-specific or
  employer-internal values committed. Internal config (hostnames, internal repo
  paths, role aliases) is externalized to a non-committed local file sourced if
  present (e.g. `~/.secrets/local` / `~/.secrets.sh`).

---

## Round 1 — shell/terminal configs (`zsh_config/` → per-tool) — FINALIZED

### Current state
Strong WHY comments and structure; Homebrew prefix is now portable; secrets are
already externalized to `~/.secrets.sh`. Main problems are drift (`cp` model),
internal infra committed to a public repo, a mixed-purpose directory name, and
one redundant file.

### Decisions
1. **Layout — split per-tool.** Break `zsh_config/` into Stow packages:
   `zsh/`, `tmux/`, `starship/`, `sesh/`, `iterm/` (exact package boundaries
   finalized alongside the Stow work in Rounds 6–7). Directory name no longer
   lies about contents; layout is Stow-ready.
2. **Externalize internal infra (D2).** Move out of the committed `.zshrc` into
   a sourced-if-present local file:
   - `VAULT_ADDR` (currently a stage Vault hostname)
   - the IAM-role-injector path (`github_earth_dimension_c132/.../meta_assume.sh`)
   - the Pindrop role aliases (`dev`/`pci-dev`/`staging`/`prd`/`devops`/`hashi`…)
   - the internal path name referenced in `sesh.toml`'s comment
3. **Remove the `codebase-memory-mcp` artifact.** `.zshrc` lines ~197–198 are a
   tool-appended block that re-exports `~/.local/bin` already present in the
   `path` array — delete (DRY).
4. **Delete `install.txt`.** Fully redundant with `bootstrap_terminal.sh` +
   README.
5. **Leave as-is:** `starship.toml` (clean), `tmux.conf.local` (gpakosz template,
   meant to be edited in place — splitting fights the framework),
   `iterm_*.json` (machine-generated profile export; add a one-line note that
   it's generated, not hand-edited).

### Out of scope for this round
The actual symlink mechanics live in `scripts/` + `Makefile` (Rounds 6–7); here
we only fix file content + agree the target layout.

---

## Round 2 — editors (`nvim/`, `vim/.vimrc`) — FINALIZED

### Current state
`nvim/` was overhauled this session and is near-compliant: thin `init.lua`,
one-plugin-per-file, file-level WHY comments, reproducible (`lazy-lock.json` +
version pins). `vim/.vimrc` is the well-known tutorial vimrc and is the outlier.

### Decisions
1. **`nvim/` — add `.stylua.toml`.** The one gap was no auto-formatting for the
   Lua. Add a stylua config so formatting is tool-enforced (matches the
   "tools enforce formatting" principle). Otherwise leave the config as-is —
   it already meets the standards.
2. **`vim/.vimrc` — slim to a portable fallback.** Rewrite as a
   **dependency-free** `.vimrc`: sane defaults only (numbers, relativenumber,
   incsearch/smartcase, expandtab/shiftwidth, undodir, statusline) and **no
   plugins** (drop `vim-plug`, ALE, NERDTree, molokai). Rationale: it must
   actually work on a bare server — the one place plain `vim` matters — where
   the current plugin-dependent version errors until vim-plug is bootstrapped.
   Strip the tutorial WHAT-comments (they narrate each line); keep only WHY
   notes where a setting is non-obvious.

### Notes
- nvim's `undodir = ~/.vim/undodir` keeps `vim/` and `nvim/` sharing the
  `.vim` dir — harmless; no nvim dependency on the vimrc itself.
- `nvim/README.md` stays; cross-link it from the top-level README in Round 9.

---

## Round 3 — package manifest (`brew/Brewfile`) — FINALIZED

### Current state
Cleanly grouped + alphabetized with good comments, but (a) missing the DevOps
CLIs the shell config assumes, and (b) mixes personal + work apps into one file
(conflicts with D2).

### Decisions
1. **Add a DevOps CLI group** to the core Brewfile so a fresh machine's shell
   actually resolves what `.zshrc` references. Minimum set:
   `kubectl`, `kubectx` (provides `kubens`), `krew`, `terraform`, `awscli`,
   `google-cloud-sdk`, `direnv`, `ripgrep`, `jq`, and `vault` (via
   `hashicorp/tap`). Keep the group alphabetized with a WHY header.
2. **Split into core + personal + work** (D2):
   - `brew/Brewfile` — core: terminal stack, DevOps CLIs, fonts. Always installed.
   - `brew/Brewfile.personal` — today's GUI apps (Discord, WhatsApp, Zoom,
     microsoft-office, balenaetcher, iina, firefox-profile-switcher, authy, …).
   - `brew/Brewfile.work` — placeholder/stub for work-laptop extras.
   - The Makefile chooses which extras to bundle (decided in Round 7). The
     `HOMEBREW_BUNDLE_FILE` wiring in `.zshrc` (`~/.brew/Brewfile`) is revisited
     alongside the Stow/Makefile work.
   - VS Code extensions: keep with core (dev tooling, machine-agnostic) unless
     a clearer split emerges in Round 7.
3. **Hermetic exception (documented).** Brew formulae stay unpinned — latest is
   desired for dev tooling, and `brew bundle` has no real pinning. Reproducibility
   for this repo lives in `lazy-lock.json` + the committed tool configs, not in
   pinned formulae. Record this as an explicit, accepted deviation from
   principle #6.

---

## Round 4 — secrets-adjacent (`aws/`, `ssh/`) — FINALIZED

### Current state
No real secrets are committed (verified): `aws/config`, `aws/credentials`, and
`ssh/config` are all templates/configs. But the credentials template gets
deployed over real creds, models the wrong auth pattern, and the ssh config
isn't portable.

### Decisions
1. **Remove `aws/credentials` + gitignore it.** Delete the static-key placeholder.
   Never deploy or symlink a `credentials` file. Add `**/credentials` (and
   `aws/credentials`) to `.gitignore` so a real one can never be committed.
   Matches the SSO-only workflow; static long-lived keys are the anti-pattern
   SSO replaces.
2. **Convert `aws/config` to an SSO template.** Replace the static-key stub with
   `[sso-session]` + SSO profile examples that mirror the actual `aws-sso` /
   `assume` workflow (role assumption via SSO). Keep it as documented
   placeholders the user fills per machine (D2).
3. **`ssh/config` — apply all three fixes:**
   - Add `IgnoreUnknown UseKeychain` so the macOS-only `UseKeychain` keyword
     doesn't error on Linux/work boxes (D2 portability).
   - Make `~/.ssh/id_ed25519` the default `IdentityFile` under `Host *`
     (drop the legacy `id_rsa` default).
   - Drop `ForwardAgent yes` on the `github` host (unnecessary + mildly risky).
   - Deployment must only ever touch `~/.ssh/config` — never keys; ensure the
     deployed config lands at mode 600 (handled in Round 7).

### Note
With creds removed, the `cp -r aws ~/.aws` / `cp -r ssh ~/.ssh` deploy steps
must be reworked in Round 7 to deploy only the safe files (config) and never
clobber real credentials or keys.

---

## Round 5 — Windows (`powershell_config/`) — FINALIZED

### Current state
A stale 2023 personal/gaming snapshot with two concrete bugs (dead theme
reference, duplicate package) and no DevOps tooling. Decision: **keep + fully
modernize** so Windows reaches parity with the mac/Linux flow.

### Decisions
1. **Wire the profile to the committed theme.** `Microsoft.PowerShell_profile.ps1`
   currently inits oh-my-posh against the upstream bundled
   `jandedobbeleer.omp.json` and ignores the repo's `oh-my-posh_default.yaml`.
   Point the profile at the committed theme so the repo actually owns the prompt
   (and the committed yaml stops being dead config).
2. **Refresh + split the winget manifest (D2).** Re-export against current winget,
   then split:
   - `packages_windows.json` — core (Git, PowerShell, Windows Terminal, VS Code,
     oh-my-posh, MSYS2, browsers, VCRedist runtimes) + a **DevOps tooling** set
     (`Kubernetes.kubectl`, `Hashicorp.Terraform`, `Amazon.AWSCLI`,
     `Google.CloudSDK`, `sharkdp.ripgrep`, `jqlang.jq`, …).
   - `packages_windows.personal.json` — personal/gaming (Steam, Nvidia
     GeForce/PhysX, Discord, Evernote, TickTick, darktable, VLC, …).
   - Remove the **duplicate** `Notion.Notion` entry; drop unneeded VCRedist
     noise where not required.
3. **Add a header note** documenting that the Windows path is best-effort and how
   to re-export the winget manifest.
4. **`scripts/windows_utils.ps1`** is the installer this relies on — audited in
   Round 6; the keep-decision here means it must apply both the core and
   (optionally) personal manifests.

### Hermetic note
winget manifests stay unpinned — same accepted exception as brew (D-Round 3).

---

## Round 6 — provisioning scripts (`scripts/`) — FINALIZED

### Current state
`bootstrap_terminal.sh` is compliant (written this session). The rest violate
`bash.md` to varying degrees; `windows_utils.ps1` is logically broken (clobbers
the committed manifest, never installs the curated list).

### Standard applied to ALL scripts
`env` bash shebang, `# == Name ==` WHY header, `set -euo pipefail`, `readonly`
constants, `err`/`log` helpers, `main "$@"`, quoted vars, `[[ ]]` over `[ ]`.
**Zero ShellCheck warnings** is a hard gate (CI wired in Round 8).

### Decisions
1. **`bootstrap_terminal.sh` — keep** ~as-is (already compliant). Stays the
   framework installer Homebrew can't cover.
2. **`mac_utils.sh` — slim + de-risk:**
   - Replace the 14-branch `handle_exit_code` with simple `err`/`log` + a small
     set of explicit `readonly EXIT_*` codes (cuts complexity under threshold).
   - **Remove `aws_env_setup`** entirely — obsolete under SSO (R4), and exporting
     static long-lived keys is the anti-pattern SSO replaces.
   - Rework `-i`/`save_packages` Brewfile handling for the **split** Brewfiles +
     repo-relative paths; `bundle dump` must not flatten the personal/work split
     (point at the repo, not `~/.brew/Brewfile`).
3. **`debian_utils.sh` / `rhel_utils.sh` — full provision parity:**
   - Add the safety header + `set -euo pipefail`, `env` shebang, strip
     WHAT-comments.
   - Install the terminal stack: apt/dnf for `neovim`/`tmux`/`fzf`/`zoxide`/
     `ripgrep`/`git`, plus the official curl installers for `starship`/`sesh`;
     then call `bootstrap_terminal.sh`.
   - RHEL uses **`dnf`** (drop legacy `yum`).
4. **`windows_utils.ps1` — rewrite to provision:**
   - **Import the committed manifest** (core, + optional personal), wire the
     oh-my-posh theme (R5), add `$ErrorActionPreference = 'Stop'` + a real
     `param()` block. Stop the destructive `export`-over-repo.
5. **Stow deployment helper (D1):** add a small `scripts/link.sh` that wraps
   `stow <pkg>...` for the per-tool packages (or the Makefile calls `stow`
   directly — final split decided in Round 7). It must back up / refuse to
   clobber pre-existing real files (esp. never touch `~/.ssh` keys or real
   `~/.aws/credentials`, per R4).

---

## Round 7 — `Makefile` — FINALIZED

### Current state
Reasonable bones (`.DEFAULT_GOAL`, `.PHONY`, `backup`, OS-detect), but it's where
the `cp` model, the unsafe aws/ssh deploy, and the single-Brewfile assumption all
live. It must absorb D1 (Stow) + R3/R4/R6 decisions.

### Decisions
1. **Deploy via Stow (D1).** Rewrite every `*_setup` target to call
   `scripts/link.sh` (the Stow wrapper from R6 #5) instead of `cp`. Repo becomes
   the source of truth; edits to live files write back through the symlinks.
2. **Profile selection via `PROFILE=` variable.** `make mac_setup` installs the
   **core** stack; `make mac_setup PROFILE=personal` (or `=work`) layers that
   profile's Brewfile extras on top. Default = core only. Threads through to
   `mac_utils.sh -i` choosing `Brewfile` + optional `Brewfile.<profile>`.
3. **Safe aws/ssh deploy (R4).** Stop `cp -r aws ~/.aws` / `cp -r ssh ~/.ssh`.
   Deploy only `aws/config` and `ssh/config` (via stow), never `credentials` or
   keys; ensure `~/.ssh/config` lands at mode 600. `link.sh` refuses to clobber
   pre-existing real files.
4. **Add lifecycle targets** (matches your help→…→lint→…→clean ordering):
   - `lint` — `shellcheck scripts/*.sh` + `stylua --check nvim/` + `yamllint`
     (powers CI in R8).
   - `unlink` — `stow -D` to cleanly remove the symlinks.
   - `clean` — remove the dated `.BAK` backups created by `backup`.
5. **De-dupe `backup`.** Only `setup` (the OS-detect entry) depends on `backup`;
   the per-OS targets don't re-run it when invoked through `setup`.
6. **Cosmetics.** Drop the pointless `$(shell bash -c 'uname -s')` wrapper; make
   `help` a self-documenting target driven off `##` target comments (consistent,
   no `$(info)`/`@echo` mix).

### Note
`HOMEBREW_BUNDLE_FILE` in `.zshrc` (currently `~/.brew/Brewfile`) is repointed
here to the repo's core Brewfile, closing the R3 wiring item.

---

## Round 8 — meta + governance/CI — FINALIZED

### Current state
`LICENSE`, `CODEOWNERS`, `dependabot.yml` are fine (dependabot already trimmed).
`.gitignore` needs secret-safety additions. `.gitconfig` leaks a personal email
into work deploys, stores credentials in plaintext, and references a missing
commit template. `release.yml` uses a deprecated action and has a latent
first-release bug; there is no lint CI.

### Decisions
1. **`.gitignore` — add secret guards (R4).** Add `**/credentials`,
   `aws/credentials`, and secret patterns (`.secrets*`, `*.secret`) so real
   credentials can never be committed.
2. **`.gitconfig` identity — conditional includes (D2).** Ship a personal default
   plus `includeIf "gitdir:~/work/" → ~/.gitconfig-work`, so the right
   name/email is chosen by repo location. No employer-specific identity committed.
3. **`.gitconfig` hardening — fix both:**
   - `credential.helper store` → `osxkeychain` on macOS, with a portable guard so
     Linux doesn't break (no plaintext `~/.git-credentials`).
   - Ship a **`.gitmessage.txt`** encoding the `git.md` commit format so
     `commit.template` resolves on a fresh machine.
   - (Minor) note the `save = WIP` alias against the "no WIP commits" rule; keep
     but documented, or drop — owner's call at implementation time.
4. **CI — add lint workflow + fix release.yml:**
   - New `.github/workflows/ci.yml` runs `make lint` (shellcheck + stylua +
     yamllint) on PRs/pushes — enforces `bash.md`'s zero-warning gate and the
     stylua/yamllint standards.
   - `release.yml`: replace deprecated `actions/create-release@v1` with
     `softprops/action-gh-release` (or `gh release create`); fix the
     `((PATCH++))` bug (GHA runs `bash -e`, so `((var++))` exits 1 when var=0 →
     first release from `v0.0.0` fails) by using `PATCH=$((PATCH+1))`.
5. **Action pinning — keep tag pins** (`@v4`). Accepted: readability over
   SHA-pinning for a personal repo; Dependabot (github-actions ecosystem)
   still bumps them. Records a second, scoped deviation from principle #6
   (alongside the brew/winget exception).

### Note
`LICENSE` year and `CODEOWNERS` left as-is.

---

## Round 9 — `README.md` + docs — FINALIZED

### Current state
Well-written but stale against every decision above (still documents `cp`,
`zsh_config/`, the `~/homebrew` assumption, the aws credentials template, and
`install.txt`; silent on stow, `PROFILE=`, the splits, the new targets, and the
git identity/secrets externalization).

### Decisions
1. **Thin README + Divio `docs/`.** Slim the README to an entry point
   (one-paragraph what + quick start + pointer into docs) and move the detail
   into a numbered Divio tree per `documentation.md`:
   - `docs/00-index.md` — map of the docs
   - `docs/10-architecture.md` — how it fits together (Stow model, per-tool
     packages, core/personal/work split, the why behind D1/D2 + the unpinned
     exception — this absorbs the "explanation" role instead of ADRs)
   - `docs/20-setup.md` — how-to: fresh-machine setup (mac/Linux/Windows),
     `PROFILE=`, manual steps (iTerm font, first nvim launch, git identity,
     `~/.secrets/local`)
   - `docs/30-reference.md` — targets, scripts, package layout reference
   - `docs/99-troubleshooting.md` — tofu fonts, treesitter CLI, tmux/nvim warmup
   - README is exempt from numbering (entry point).
2. **No formal ADRs.** Architectural rationale lives in this `plan.md` (kept as a
   living doc) + commit messages + `docs/10-architecture.md`. (Conscious choice
   to skip `docs/adr/` despite the decisions qualifying — `plan.md` covers it.)
3. **Realign all README content** to Rounds 1–8: stow flow, per-tool structure
   tree, portable Homebrew prefix, removed creds/install.txt, new lifecycle
   targets, profile selection, Linux provisioning, git identity + secrets
   externalization, cross-link `nvim/README.md`.

### Note
`plan.md` is retained in-repo as the running modernization record/checklist.

---

## Audit complete — implementation sequencing

All nine rounds finalized. Suggested implementation order (mirrors dependency
order; each is a self-contained commit/PR slice):

1. **Restructure + content (R1–R5):** per-tool dirs, externalize internal infra,
   delete `install.txt`/`aws/credentials`, slim `vim/.vimrc`, add `.stylua.toml`,
   split Brewfiles + add DevOps CLIs, SSO `aws/config`, harden `ssh/config`,
   modernize Windows manifests/profile.
2. **Scripts (R6):** `scripts/link.sh` (stow wrapper), slim `mac_utils.sh`,
   Linux full-provision utils, rewrite `windows_utils.ps1`.
3. **Makefile (R7):** stow deploy, `PROFILE=`, safe aws/ssh deploy, lint/unlink/
   clean, de-dupe backup, help/cosmetics.
4. **Governance (R8):** `.gitignore` secret guards, `.gitconfig` conditional
   includes + keychain + `.gitmessage.txt`, `ci.yml` lint workflow, fix
   `release.yml`.
5. **Docs (R9):** thin README + Divio `docs/` tree.

Validation gates: `shellcheck scripts/*.sh`, `make -n` on every target,
`stylua --check nvim/`, `zsh -n` on the assembled zshrc, a dry stow run.
