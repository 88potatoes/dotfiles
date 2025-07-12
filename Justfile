hello:
  echo "Hello, world!"

stow:
  stow zsh
  stow nvim
  stow zellij
  stow spotify-player
  stow raycast
  stow ghostty
  stow btop

install-all:
  brew install stow
  brew install neovim
  brew install yazi
  brew install zellij
  brew install --cask brave-browser
  brew install --cask ghostty

