# dotfiles

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) for dotfiles management.

To prevent the repository from being cluttered with hidden files (which are invisible by default when using `ls`), this repository leverages Stow's `--dotfiles` feature. All hidden configurations that normally start with `.` (e.g., `.config`, `.zshrc`) have been renamed to use the `dot-` prefix instead (e.g., `dot-config`, `dot-zshrc`).

## Usage

Because of the `dot-` prefix structure, you **must use the `--dotfiles` flag** when running Stow commands. This ensures Stow automatically converts the `dot-` prefix back to `.` when creating the symlinks in your home directory.

### Stow (Apply Configuration)

To symlink a specific package (e.g., `nvim`) to your home directory:

```bash
stow --dotfiles nvim
```

To apply all configurations at once:

```bash
stow --dotfiles *
```

### Unstow (Remove Configuration)

To safely remove the symlinks from your home directory:

```bash
stow -D --dotfiles nvim
```
