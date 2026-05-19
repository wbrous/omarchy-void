---
name: merge-upstream
description: >
  Track and selectively port features from basecamp/omarchy (Arch Linux) into a
  Void Linux fork. Use this skill whenever the user wants to merge upstream
  changes, port a feature from the original Arch-based Omarchy, cherry-pick a
  commit, see what changed upstream, or sync with basecamp/omarchy. Also use
  when the user mentions upstream, backporting, feature ports, or keeping their
  fork in sync with the original project.
compatibility: >
  Requires git, omarchy-upstream-* commands in PATH, and a git remote named
  'upstream' pointing to basecamp/omarchy.
---

# Merge Upstream Features into Omarchy-Void

Track and selectively port features from `basecamp/omarchy` (Arch) into
`wbrous/omarchy-void` (Void).

## When to Use

- Upstream ships a feature you want in your Void fork
- You want to see what changed upstream without drowning in merge conflicts
- You need a repeatable workflow for cherry-picking and Void-adapting commits

## When Not to Use

- Do not use `git merge upstream/master` — the forks diverged too far (450+
  files, different package manager, init system, bootloader). Automatic merges
  are a trap.
- Do not use this for bulk-syncing. Port one feature at a time.

## One-Time Setup

```bash
# Add upstream remote (safe, read-only tracking)
cd ~/.local/share/omarchy
git remote add upstream https://github.com/basecamp/omarchy.git 2>/dev/null || true
```

## Daily Workflow

Use the `omarchy upstream *` commands installed by this fork:

### 1. Refresh upstream tracking

```bash
omarchy upstream sync
```

This adds the upstream remote if missing and fetches all branches.

### 2. See what's new

```bash
omarchy upstream log [N]   # default 30 commits
```

Shows commits upstream has that you don't, newest first.

### 3. Inspect a commit before deciding

```bash
omarchy upstream show <commit-ish>
```

Outputs:
- Commit metadata (author, date, stat)
- File existence check in your fork (`[OK]` / `[MISSING]`)
- Classification (`SKIP`, `REWRITE`, `EASY`, `REVIEW`)

Example:

```
=== Commit ===
abc1234 Add new theme: tokyo-day
 themes/tokyo-day/ | 12 files changed

=== File existence ===
  [OK]      themes/tokyo-day/colors.toml
  [MISSING] themes/tokyo-day/preview.png

=== Classification ===
  EASY — likely distro-agnostic config
```

### 4. Cherry-pick with rewrite

```bash
omarchy upstream port <commit-ish>
```

This:
1. Resolves the commit to a full hash
2. Creates a branch named `upstream-port-<hash>`
3. Runs `git cherry-pick -x`
4. If conflicts occur, prints the adaptation checklist inline

After resolving conflicts and adapting for Void:

```bash
# Syntax-check modified shell scripts
find bin/ install/ -name '*.sh' -newer .git/HEAD -exec bash -n {} \;

# Stage and commit with clear provenance
git add -A
git commit -m "feat: port <upstream-feature> from basecamp/omarchy

Upstream commit: basecamp/omarchy@$COMMIT
Adapted for Void Linux:
- <what you changed>"
```

### 5. Adaptation checklist

When cherry-picking any upstream change, run through this checklist before
committing:

- [ ] `pacman` → `xbps-install` / `xbps-remove` / `xbps-query`
- [ ] `systemctl enable/start` → `ln -sf /etc/sv/SVC /var/service/` or `sv start`
- [ ] `systemctl --user` → Hyprland autostart.lua or `pkill + restart`
- [ ] `mkinitcpio` → `dracut --force --regenerate-all`
- [ ] `limine` / `limine-mkinitcpio` → `grub-mkconfig -o /boot/grub/grub.cfg`
- [ ] `journalctl -b` → `dmesg | tail` or `svlogd` logs
- [ ] `/etc/pacman.conf` or `/etc/pacman.d/*` → `/etc/xbps.d/*.conf`
- [ ] `/etc/systemd/*` → `/etc/sv/*` or `/etc/elogind/*`
- [ ] Arch package names → Void equivalents (check `install/omarchy-base.packages`)
- [ ] New upstream commands using systemd/pacman → rewrite for Void or skip

## Port Priority Guide

Port these first — high value, low rewrite effort:

1. **Themes** (`themes/*/`) — usually just colors/wallpapers, mostly distro-agnostic
2. **Hyprland configs** (`default/hypr/*.lua`) — unless they add `systemctl` calls
3. **Waybar styles** (`default/waybar/`) — pure CSS/config
4. **Desktop app configs** (`default/walker/`, `default/sddm/`, `default/plymouth/`) — check for systemd refs

Port these last — high rewrite effort:

1. **New bin commands** that wrap pacman/systemd/mkinitcpio
2. **Install scripts** that configure services or packages
3. **Hardware-specific scripts** with Arch-only packages or mkinitcpio modules

Never port:

1. **Migrations** — your fork deleted them all; start fresh
2. **Limine/pacman/systemd configs** — your fork deleted these directories
