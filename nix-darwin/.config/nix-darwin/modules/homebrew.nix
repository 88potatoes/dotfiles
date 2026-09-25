# Homebrew module — casks and brews
{ ... }: {
  nix-homebrew.trust.casks = [
    "abue-ammar/tinycast/tinycast"
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
      "bitwarden"
      "ghostty"
      "1password"
      "tinycast"
      "jetbrains-toolbox"
      "whatsapp"
      "google-gemini"
      "meetingbar"
      "surfshark"
      "notion"
      "opensuperwhisper"
      "bruno"
      "linear"
      "rectangle"
      "grandperspective"
    ];
  };
}
