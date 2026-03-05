{ config, pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
    brews = [
      "cask"
      "scrcpy"
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
      "firefox"
      "vivaldi"
      "visual-studio-code"
      "datagrip"
      "miro"
      "gather"
      "android-platform-tools"
      "gcloud-cli"
    ];
    masApps = {
      Tailscale = 1475387142;
    };
  };
}
