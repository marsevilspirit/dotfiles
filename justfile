[private]
default:
	@just --list

# Install macOS dependencies from Brewfile
install:
	brew bundle install --file=Brewfile --no-upgrade

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

# Check sync, autosave, startup error detection, and shell syntax in temporary directories
check:
	python3 tests/check.py

# Sync modified managed files from HOME; edit templates in the source instead
sync:
	chezmoi re-add --source .

# Preview what sync would update (HOME → repo)
sync-diff:
	chezmoi re-add --source . --dry-run --verbose

# Add or update paths from HOME (e.g. just add ~/.config/nvim/init.lua)
add *paths:
	chezmoi add --source . {{paths}}
