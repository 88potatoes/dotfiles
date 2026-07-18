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
    ];
  };
}