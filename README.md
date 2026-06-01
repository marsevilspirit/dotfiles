# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). The repository root is the chezmoi **source**; apply from here with `chezmoi --source .` or the `just` recipes below.

## Managed paths

| Source in repo | Target |
|----------------|--------|
| `dot_config/fish/` | `~/.config/fish` |
| `dot_config/nvim/` | `~/.config/nvim` |
| `dot_config/ghostty/` | `~/.config/ghostty` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `dot_vimrc` | `~/.vimrc` |
| `dot_zshrc` | `~/.zshrc` |
| `dot_ideavimrc` | `~/.ideavimrc` |

Chezmoi maps `dot_*` and `dot_config/` names to paths under `$HOME` automatically.

## Prerequisites

- [chezmoi](https://www.chezmoi.io/install/)
- [just](https://github.com/casey/just) (optional, for shortcuts)

```bash
# macOS
brew install chezmoi just

# Linux (official installer)
sh -c "$(curl -fsLS get.chezmoi.io)"

# Linux (if the installer is blocked; installs to ~/.local/bin)
go install github.com/twpayne/chezmoi/v2@latest
```

## First-time setup

```bash
git clone <repo-url> ~/dotfiles   # or your preferred path
cd ~/dotfiles
just apply                        # or: chezmoi apply --source .
```

On first apply, fish plugins listed in `dot_config/fish/fish_plugins` are installed by [Fisher](https://github.com/jorgebucaran/fisher) when you start an interactive fish session.

## Daily commands

From the repository root:

```bash
just --list   # show recipes and descriptions
just diff     # preview changes (chezmoi diff --source .)
just apply    # apply to $HOME (chezmoi apply --source .)
```

Equivalent chezmoi invocations:

```bash
chezmoi diff --source .
chezmoi apply --source .
```

`just diff` treats chezmoi exit code `1` (diff present) as success so scripts and CI can run it without failing when changes exist.

## Sync across machines

1. On machine A: edit files in this repo, commit, and `git push`.
2. On machine B: `git pull` in the clone, then `just apply`.

Machine-specific secrets and local overrides stay on each host (see below); they are not in git.

## Local-only files

These paths are listed in `.chezmoiignore` and are never overwritten by `chezmoi apply`:

| Path | Purpose |
|------|---------|
| `~/.config/fish/fish_variables` | fish universal variables |
| `~/.config/fish/secrets.fish` | API keys and tokens (sourced from `config.fish` if present) |
| `~/.config/fish/conf.d/local.fish` | per-machine fish overrides |

Create `secrets.fish` on each machine as needed; do not commit it.

## Platform notes

- **`RSS/`** in the repo is reference OPML only; it is not applied to `$HOME`.

## CI

GitHub Actions (`.github/workflows/ci.yml`) runs three jobs (`verify-linux`, `verify-macos`, `verify-windows`): each checks source paths, `chezmoi diff` / `apply` into a temporary home directory, and `nvim --headless "+checkhealth"`.
