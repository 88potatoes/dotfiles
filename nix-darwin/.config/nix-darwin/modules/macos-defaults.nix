# macOS system defaults module
{ ... }: {
  system.defaults = {
    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.3;
      minimize-to-application = true;
      show-recents = false;
      static-only = true;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = false;
      ShowPathbar = true;
      ShowStatusBar = true;
      FXPreferredViewStyle = "Nlsv";
    };

    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowScrollBars = "Always";
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true;
      NSNavPanelExpandedStateForSaveMode2 = true;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };

    CustomUserPreferences = {
      "leits.MeetingBar" = {
        automaticEventJoin = 1;
      };
      "com.cmuxterm.app" = {
        browserDisabledOverride = 1;
      };
      "com.knollsoft.Rectangle" = {
        launchOnLogin = true;
      };
      "com.google.Chrome" = {
        GenAILocalFoundationalModelSettings = 1;
      };
      "com.tinycast.app" = {
        showInMenuBar = 1;
        extensionsEnabled = 1;
        snippetsEnabled = 1;
        calendarMenuBarDisplay = 0;
        "hotkey.togglePalette" = "{\"combo\":{\"_0\":{\"carbonModifiers\":256,\"carbonKeyCode\":49}}}";
        "hotkey.command:clipboard-history" = "{\"combo\":{\"_0\":{\"carbonKeyCode\":9,\"carbonModifiers\":768}}}";
      };
    };
  };
}