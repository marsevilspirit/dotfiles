[private]
default:
	@just --list

# Apply managed dotfiles to HOME (~/.config, ~/.tmux.conf, etc.)
apply:
	chezmoi apply --source .

# Preview changes before applying (exits 0 even when diff is non-empty)
diff:
	chezmoi diff --source .; status=$?; test $status -le 1
