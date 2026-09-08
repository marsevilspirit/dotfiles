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
| `dot_local/share/nvim/leetcode/` | `~/.local/share/nvim/leetcode/` |

Chezmoi maps `dot_*` and `dot_config/` names to paths under `$HOME` automatically.

## Prerequisites

- [chezmoi](https://www.chezmoi.io/install/)
- [just](https://github.com/casey/just) (optional, for shortcuts)

```bash
# macOS
brew install chezmoi just

# Linux (official installer)
sh -c "$(curl -fsLS get.chezmoi.io)"

# Linux (Go alternative; installs to $(go env GOPATH)/bin by default)
go install github.com/twpayne/chezmoi/v2@latest
```

The Neovim configuration uses `vim.pack` and native LSP. Use [Neovim nightly](https://github.com/neovim/neovim/releases/tag/nightly), as CI does; if you use Bob, run `bob use nightly`. The locked nvim-treesitter requires Neovim 0.12 or newer.

For the configured editor features on macOS:

```bash
brew install fish ripgrep fd go node tree-sitter-cli
# Optional shell conveniences; fish also starts without these:
brew install fzf zoxide eza fastfetch
```

On Linux or Windows, install the equivalent tools through your package manager. Parser builds require a C compiler, `curl`, `tar`, and tree-sitter CLI >= 0.26.1. Mason uses Go for `gopls` and Node/npm for `pyright` and `prettier`; it downloads the other configured servers as binaries. Neovim installs `stylua`, `clangd`, `rust-analyzer`, `lua-language-server`, `gopls`, `protols`, `pyright`, and `prettier` on first startup. Watch progress with `:Mason`; after a failed run, inspect `:MasonLog` and retry missing tools with `:MasonToolsInstall`.

## First-time setup

```bash
git clone <repo-url> ~/dotfiles   # or your preferred path
cd ~/dotfiles
just apply                        # or: chezmoi apply --source .
```

The Dracula theme is included in the source and loaded with `fish_config theme choose "Dracula Official"`. Update the theme in this repository, then apply it with chezmoi. Applying also removes the retired Fisher files and frozen theme snapshot listed in `.chezmoiremove`.

## Daily commands

From the repository root:

```bash
just --list   # show recipes and descriptions
just diff     # preview changes (chezmoi diff --source .)
just apply    # apply to $HOME (chezmoi apply --source .)
just sync-diff # preview HOME -> repo changes
just sync     # import modified managed files, preserving source templates
just check    # run regression checks in temporary directories
```

Equivalent chezmoi invocations:

```bash
chezmoi diff --source .
chezmoi apply --source .
```

`just diff` treats chezmoi exit code `1` (diff present) as success so scripts and CI can run it without failing when changes exist.

`sync` and `sync-diff` use `chezmoi re-add`. Templates are intentionally skipped: edit `.tmpl` files in the repository, then apply them. Review `just sync-diff` before importing local edits.

## LeetCode in Neovim

[leetcode.nvim](https://github.com/kawre/leetcode.nvim) uses **leetcode.cn**, Chinese descriptions, and **C++** by default. It reuses Snacks for problem selection and preserves existing solutions when reopening solved problems.

On macOS, install the CLI used to build the HTML parser for problem descriptions:

```bash
brew install tree-sitter-cli
chezmoi apply --source . -- ~/.config/nvim \
  ~/.local/share/nvim/leetcode/.clangd ~/.local/share/nvim/leetcode/leetcode.hpp
nvim leetcode.nvim
```

On other platforms, install `tree-sitter-cli` (>= 0.26.1) from your package manager or the official binary release, not npm, plus a C compiler, `curl`, and `tar`. The HTML parser installs automatically; run `:TSUpdate html` after updating nvim-treesitter.

You can also open the dashboard with `:Leet` or `<Space>ll` from an existing Neovim session. Sign in once by copying the **Cookie request header** from a logged-in `leetcode.cn` browser request into the plugin's sign-in prompt. Keep the cookie local; never put it in this repository.

After opening the LeetCode dashboard:

| Key | Command | Action |
|-----|---------|--------|
| `<Space>ll` | `:Leet` | Dashboard |
| `<Space>lf` | `:Leet list` | Find a problem |
| `<Space>lr` | `:Leet run` | Run test cases |
| `<Space>ls` | `:Leet submit` | Submit solution |
| `<Space>ld` | `:Leet desc` | Toggle description |
| `<Space>lc` | `:Leet lang` | Change language |

Use `:Leet exit` to leave the plugin. Solutions live under `stdpath('data')/leetcode` and authentication/cache under `stdpath('cache')/leetcode`. The C++ template uses standard headers instead of GCC-only `bits/stdc++.h` for macOS clangd; add further headers as needed. These injected headers remain outside the submitted code section. Change permanent defaults in `dot_config/nvim/plugin/leetcode.lua`.

The `.clangd` file in `~/.local/share/nvim/leetcode` disables unused-header warnings for both new and existing practice files. It also force-includes `leetcode.hpp` so clangd recognizes the judge-provided `ListNode` and `TreeNode` types; this header is never sent to LeetCode. Other diagnostics remain enabled. If you change the solution storage directory, move both files and update the include path in `.clangd`. Run `:lsp restart clangd` to refresh diagnostics in an already-open session.

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

Runtime `*.log` files are excluded from Git and chezmoi. Existing local logs are left in place.

## Platform notes

- **`RSS/`** in the repo is reference OPML only; it is not applied to `$HOME`.

## CI

GitHub Actions runs the same checks on Linux, macOS, and Windows. `just check` requires Python 3, Bash, chezmoi, just, and Neovim; Unix also requires fish and zsh. It tests the actual sync recipes in a temporary destination, template preservation, log exclusions, autosave behavior, and rejection of deliberately broken Neovim startup/health checks. Unix jobs syntax-check every fish file and `.zshrc`, and start fish without optional tools.

CI additionally runs `python tests/check.py --integration`: apply the configuration in isolation, wait for LSP/formatter and HTML parser installation, then check `vim.lsp`, `vim.treesitter`, `nvim-treesitter`, and `blink.cmp`. Startup errors, missing required executables, parser timeouts, and health errors fail the job explicitly. Warnings remain visible. Terminal/graphics checks belong in an interactive `:checkhealth`, since headless runners have no graphical terminal. Integration checks require network access; temporary configurations and data are removed afterward.
