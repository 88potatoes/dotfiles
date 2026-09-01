# CLI packages — imported into environment.systemPackages
pkgs: with pkgs; [
  # shell / core
  coreutils
  curl
  wget
  git
  pkgs.unstable.gh
  gnugrep
  gnused
  jq
  yq
  ripgrep
  fd

  # monitoring
  htop
  btop

  # editors
  # note we use bob to install nvim
  pkgs.unstable.bob-nvim

  # file mgmt / tmux
  yazi
  zellij
  lazygit

  # nix utils
  nix-output-monitor
  nix-tree
  comma

  starship
  fzf
  zoxide
  mise
  zsh-autosuggestions
  zsh-syntax-highlighting
  stow
  go-task
  awscli2
  deno

  # editor tooling
  nodePackages.eslint_d

  # languages
  openjdk
  lazygit
  gitleaks
  pre-commit
  just
  postgresql
]