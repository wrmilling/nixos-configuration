{ inputs, outputs, secrets, lib, config, pkgs, ... }:

{
  imports = [
    ../common/terminal/default-darwin.nix
    ../common/graphical/default-darwin.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = lib.mkDefault "${secrets.hosts.work-mac.username}";
    homeDirectory = lib.mkDefault "/Users/${secrets.hosts.work-mac.username}";
  };

  programs.git = {
    userEmail = secrets.hosts.work-mac.email.long;
    signing.signByDefault = false;
    includes = [
      {
        condition = "gitdir:~/.nixos-configuration/";
        contents = {
          user = {
            email = "Winston@Milli.ng";
          };
        };
      }
    ];
  };

  programs.home-manager.enable = true;

  # Fish Additions
  programs.fish = {
    loginShellInit = ''for p in (string split " " $NIX_PROFILES); fish_add_path --prepend --move $p/bin; end'';
    interactiveShellInit =
      # fix brew path (should not be needed but somehow is?)
      ''
      eval (/opt/homebrew/bin/brew shellenv)
      '';
  };

  # Alacritty Font Fixes
  programs.alacritty.settings.font = {
    normal.family = "Source Code Pro";
    bold.family = "Source Code Pro";
    italic.family = "Source Code Pro";
    bold_italic.family = "Source Code Pro";
    size = 16;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
