[private]
default:
	@just --list

install:
	chezmoi apply --source .

dry-run:
	chezmoi diff --source .; status=$?; test $status -le 1

diff:
	chezmoi diff --source .; status=$?; test $status -le 1
