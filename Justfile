hello:
  echo "Hello, world!"

stow-all:
  stow zsh
  stow nvim
  stow zellij
  stow spotify-player
  stow ghostty
  stow btop
  stow karabiner

install-all:
  brew bundle --file ./Brewfile

