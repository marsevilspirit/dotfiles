[private]
default:
	@just --list

# Apply managed dotfiles to HOME (~/.config, ~/.tmux.conf, etc.)
apply:
	chezmoi apply --source .

# Preview changes before applying (exits 0 even when diff is non-empty)
diff:
	chezmoi diff --source .; status=$?; test $status -le 1

# Point chezmoi at this repo as source (one-time setup)
init:
	chezmoi init --source . --apply=false

# List files managed by chezmoi
managed:
	chezmoi managed --source .

# Sync all managed files from HOME into this repo
sync:
	#!/usr/bin/env bash
	set -euo pipefail
	mapfile -t targets < <(chezmoi managed --source . --include=files)
	existing=()
	for target in "${targets[@]}"; do
		[[ -f "$target" ]] && existing+=("$target")
	done
	((${#existing[@]})) || exit 0
	chezmoi add --source . "${existing[@]}"

# Preview what sync would update (HOME → repo)
sync-diff:
	#!/usr/bin/env bash
	set -euo pipefail
	mapfile -t targets < <(chezmoi managed --source . --include=files)
	existing=()
	for target in "${targets[@]}"; do
		[[ -f "$target" ]] && existing+=("$target")
	done
	((${#existing[@]})) || exit 0
	chezmoi add --source . --dry-run --verbose "${existing[@]}"

# Add or update paths from HOME (e.g. just add ~/.config/nvim/init.lua)
add *paths:
	chezmoi add --source . {{paths}}
