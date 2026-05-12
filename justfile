packages := 'fish nvim tmux aerospace'

install:
	stow --dotfiles {{packages}}

dry-run:
	stow --dotfiles -n -v {{packages}}

uninstall:
	stow -D --dotfiles {{packages}}
