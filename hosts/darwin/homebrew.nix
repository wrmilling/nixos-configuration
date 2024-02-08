{
  config,
  pkgs,
  ...
}: {
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
    brews = [
      "cask"
    ];
    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/services"
    ];
    casks = [
      "flameshot"
      "microsoft-remote-desktop"
      "obs"
      "alacritty"
      "barrier"
      "firefox"
      "vivaldi"
      "visual-studio-code"
      "font-source-code-pro"
      "datagrip"
      "miro"
    ];
    masApps = {
      Tailscale = 1475387142;
    };
  };
}
