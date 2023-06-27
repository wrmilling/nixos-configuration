{ inputs, outputs, secrets, lib, config, pkgs, ... }:

{
  imports = [
    ../common/terminal/default-darwin.nix
    ../common/graphical/default-darwin.nix
  ];

  nixpkgs = {
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      # outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = lib.mkDefault "${secrets.machines.work-mac.username}";
    homeDirectory = lib.mkDefault "/Users/${secrets.machines.work-mac.username}";
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # Fish Additions
  programs.fish = {
    loginShellInit = ''for p in (string split " " $NIX_PROFILES); fish_add_path --prepend --move $p/bin; end'';
    interactiveShellInit =
      # fix brew path (should not be needed but somehow is?)
      ''
      eval (/opt/homebrew/bin/brew shellenv)
      '' +
      # handle gcloud CLI
      ''
      bass source ~/google-cloud-sdk/path.bash.inc
      bass source ~/google-cloud-sdk/completion.bash.inc
      '' +
      # add custom localized paths
      ''
      fish_add_path $HOME/.rd/bin
      '';
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
