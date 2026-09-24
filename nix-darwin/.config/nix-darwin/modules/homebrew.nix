# Homebrew module — casks and brews
{ ... }: {
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "none";
    };
    taps = [
      "abue-ammar/tinycast"
    ];
    brews = [
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
    ];
  };
}
