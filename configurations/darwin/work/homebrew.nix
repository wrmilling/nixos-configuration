{ config, pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
    onActivation.cleanup = "zap";
    onActivation.extraFlags = [ "--force-cleanup" ];
    brews = [
      "cask"
      "scrcpy"
    ];
    taps = [
      "homebrew/bundle"
      "homebrew/cask-fonts"
      "homebrew/services"
      "deskflow/tap"
    ];
    casks = [
      "appflowy"
      "deskflow"
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
