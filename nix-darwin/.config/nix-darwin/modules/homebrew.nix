# Homebrew module — casks and brews
{ ... }: {
  nix-homebrew.trust.casks = [
    "abue-ammar/tinycast/tinycast"
    "stablyai/orca/orca"
  ];

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    taps = [
      "abue-ammar/tinycast"
      "stripe/stripe-cli"
      "stablyai/orca"
    ];
    brews = [
      "hunk"
      "worktrunk"
      "railway"
      "uv"
      "colima"
      "docker"
      "docker-compose"
      "docker-buildx"
      "gettext"
      "openssl@3"
      "glib"
      "pango"
      "libmagic"
      "ffmpeg"
      "stripe/stripe-cli/stripe"
    ];
    casks = [
      "karabiner-elements"
      "font-iosevka"
      "font-iosevka-nerd-font"
      "bitwarden"
      "ghostty"
      "1password"
      "1password-cli"
      "tinycast"
      "stablyai/orca/orca"
      "jetbrains-toolbox"
      "whatsapp"
      "google-gemini"
      "meetingbar"
      "surfshark"
      "notion"
      "grok-bot"
      "opensuperwhisper"
      "bruno"
      "linear"
      "rectangle"
      "espanso"
      "grandperspective"
      "background-music"
      "todoist-app"
    ];
  };
}
