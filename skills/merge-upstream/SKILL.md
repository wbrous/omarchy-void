# Merge Upstream Features into Omarchy-Void

Track and selectively port features from `basecamp/omarchy` (Arch) into `wbrous/omarchy-void` (Void).

## When to Use

- Upstream ships a feature you want in your Void fork
- You want to see what changed upstream without drowning in merge conflicts
- You need a repeatable workflow for cherry-picking and Void-adapting commits

## When Not to Use

- Do not use `git merge upstream/main` — the forks diverged too far (450+ files, different package manager, init system, bootloader). Automatic merges are a trap.
- Do not use this for bulk-syncing. Port one feature at a time.

## One-Time Setup

```bash
# Add upstream remote (safe, read-only tracking)
cd ~/.local/share/omarchy
git remote add upstream https://github.com/basecamp/omarchy.git 2>/dev/null || true
```

## Daily Workflow

### 1. Refresh upstream tracking

```bash
git fetch upstream
```

### 2. See what's new

```bash
# Commits upstream has that you don't
git log --oneline --graph --left-right HEAD...upstream/main | head -40

# Or: just the upstream-only commits
git log --oneline HEAD..upstream/main | head -40
```

### 3. Inspect a commit before deciding

```bash
COMMIT=abc1234

# What files did it touch?
git show --stat $COMMIT

# Full diff
git show $COMMIT

# Which of those files exist in your fork?
git show --pretty=format: --name-only $COMMIT | while read f; do
  [[ -f $f ]] && echo "EXISTS: $f" || echo "DELETED/MISSING: $f"
done
```

### 4. Classify the commit

| Files touched | Verdict | Action |
|---|---|---|
| `themes/*`, `config/*`, `default/hypr/*`, `default/waybar/*` | **Easy port** | Cherry-pick directly, fix any Arch refs if present |
| `bin/omarchy-*` | **Needs rewrite** | Cherry-pick to a temp branch, rewrite internals for xbps/runit/dracut/GRUB |
| `install/*` | **Needs rewrite** | Same as above — install scripts are Void-native now |
| `default/limine/*`, `default/pacman/*`, `default/systemd/*` | **Skip** | These directories were deleted; upstream changes here are Arch-only |
| `migrations/*` | **Skip** | All upstream migrations were deleted; your fork starts fresh |
| `README.md`, `AGENTS.md`, docs | **Review** | Decide case by case; some docs may still reference Arch |

### 5. Cherry-pick with rewrite

```bash
# Create a feature branch for the port
FEATURE="upstream-some-feature"
git checkout -b "$FEATURE"

# Cherry-pick the upstream commit (may conflict — that's expected)
git cherry-pick -x $COMMIT
# ...resolve conflicts, rewrite Arch-isms for Void...

# Or: apply only the diff, manually selecting hunks
git show $COMMIT -- '*.lua' '*.conf' | git apply --3way -v
```

### 6. Adaptation checklist

When cherry-picking any upstream change, run through this checklist:

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

### 7. Test and commit

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

## Automation Helpers

Add these to your shell profile for faster daily use:

```bash
# Show upstream commits not in your fork
omarchy-upstream-log() {
  git -C ~/.local/share/omarchy fetch upstream 2>/dev/null
  git -C ~/.local/share/omarchy log --oneline HEAD..upstream/main "$@"
}

# Show files touched by an upstream commit, with fork existence check
omarchy-upstream-files() {
  local commit="$1"
  git -C ~/.local/share/omarchy show --pretty=format: --name-only "$commit" | while read f; do
    if [[ -f ~/.local/share/omarchy/$f ]]; then
      echo "  [OK] $f"
    else
      echo "  [MISSING] $f"
    fi
  done
}

# Quick classification of a commit's merge difficulty
omarchy-upstream-classify() {
  local commit="$1"
  local files
  files=$(git -C ~/.local/share/omarchy show --pretty=format: --name-only "$commit")

  if echo "$files" | grep -qE '^migrations/|^default/limine/|^default/pacman/|^default/systemd/'; then
    echo "SKIP: touches deleted directories"
  elif echo "$files" | grep -qE '^bin/|^install/'; then
    echo "REWRITE: touches bin/ or install/ scripts"
  elif echo "$files" | grep -qE '^themes/|^config/|^default/hypr/|^default/waybar/'; then
    echo "EASY: likely distro-agnostic config"
  else
    echo "REVIEW: check manually"
  fi
}
```

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
