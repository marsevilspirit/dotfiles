packages := 'fish nvim tmux aerospace'

[private]
default:
	@just --list

install:
	stow --dotfiles {{packages}}

dry-run:
	stow --dotfiles -n -v {{packages}}

uninstall:
	stow -D --dotfiles {{packages}}
