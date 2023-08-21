{ config, pkgs, ... }:

{
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
      "homebrew/cask"
      "homebrew/cask-fonts"
      "homebrew/core"
      "homebrew/services"
    ];
    casks = [
      "flameshot"
      "microsoft-remote-desktop"
      "obs"
      "alacritty"
      "barrier"
      "vivaldi"
      "visual-studio-code"
      "font-source-code-pro"
      "datagrip"
    ];
    masApps = {
      Tailscale = 1475387142;
    };
  };
}
