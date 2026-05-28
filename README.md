# dotfiles

This repository uses [chezmoi](https://www.chezmoi.io/) for dotfiles management.

The managed set includes:

- `dot_config/fish` -> `~/.config/fish`
- `dot_config/nvim` -> `~/.config/nvim`
- `dot_config/aerospace` -> `~/.config/aerospace` (macOS only)
- `dot_config/ghostty` -> `~/.config/ghostty`
- `dot_ideavimrc` -> `~/.ideavimrc`
- `dot_tmux.conf` -> `~/.tmux.conf`
- `dot_vimrc` -> `~/.vimrc`
- `dot_zshrc` -> `~/.zshrc`

`RSS/` is kept for reference and excluded from `chezmoi apply` by `.chezmoiignore`.

## Usage

Install chezmoi first:

```bash
brew install chezmoi
# or
sh -c "$(curl -fsLS get.chezmoi.io)"
```

From the repository root:

```bash
just install    # chezmoi apply --source .
just dry-run    # chezmoi diff --source .
just diff       # same as dry-run
```

Or run chezmoi directly:

```bash
chezmoi apply --source .
chezmoi diff --source .
```

## Local Files

Machine-specific fish files are intentionally not tracked:

- `~/.config/fish/fish_variables`
- `~/.config/fish/secrets.fish`
- `~/.config/fish/conf.d/local.fish`
