# dotfiles

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) for dotfiles management.

To prevent the repository from being cluttered with hidden files (which are invisible by default when using `ls`), this repository leverages Stow's `--dotfiles` feature. All hidden configurations that normally start with `.` (e.g., `.config`, `.zshrc`) have been renamed to use the `dot-` prefix instead (e.g., `dot-config`, `dot-zshrc`).

## Usage

Because of the `dot-` prefix structure, you **must use the `--dotfiles` flag** when running Stow commands. This ensures Stow automatically converts the `dot-` prefix back to `.` when creating the symlinks in your home directory.

Run Stow from the repository root (the directory that contains the package folders such as `fish` and `nvim`).

### Install (recommended)

Use [Just](https://github.com/casey/just) with the `justfile` in this repository so only intended packages are linked. This avoids `stow --dotfiles *`, which would also pick up non-configuration trees such as `RSS/`. From the repository root:

```bash
just install      # symlink fish, nvim, tmux, aerospace
just dry-run      # stow -n -v (no changes)
just uninstall    # stow -D (remove symlinks for those packages)
```

The package list is `fish nvim tmux aerospace`. Edit `packages` at the top of the `justfile` if you need a different set.

### Stow (manual)

To symlink a single package (e.g., `nvim`) to your home directory:

```bash
stow --dotfiles nvim
```

To remove symlinks for one package:

```bash
stow -D --dotfiles nvim
```
