hello:
  echo "Hello, world!"

stow-all:
  stow zsh
  stow nvim
  stow zellij
  stow spotify-player
  stow raycast
  stow ghostty
  stow btop

install-all:
  brew bundle --file ./Brewfile

