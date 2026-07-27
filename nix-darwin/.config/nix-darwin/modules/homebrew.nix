# Homebrew module — casks and brews
{ ... }: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    brews = [
      "worktrunk"
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
    ];
    casks = [
      "karabiner-elements"
      "font-iosevka"
      "bitwarden"
      "ghostty"
      "1password"
      "raycast"
      "jetbrains-toolbox"
      "whatsapp"
      "google-gemini"
      "meetingbar"
      "surfshark"
      "notion"
      "opensuperwhisper"
      "bruno"
    ];
  };
}