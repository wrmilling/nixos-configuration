{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.gaming;
in
{
  options.modules.nixos.gaming = {
    enable = lib.mkEnableOption "gaming packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.steam = {
      enable = true;
      # Steam's bubblewrap sandbox drops all capabilities, which blocks
      # CAP_SYS_NICE and breaks async reprojection in VR. See:
      # https://wiki.nixos.org/wiki/VR
      package = pkgs.steam.override {
        buildFHSEnv = pkgs.buildFHSEnv.override {
          bubblewrap = pkgs.bubblewrap.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./assets/bwrap-cap-fix.patch ];
          });
        };
        extraBwrapArgs = [ "--cap-add ALL" ];
      };
    };

    networking.firewall.allowedTCPPorts = [
      27036 # Steam Remote Play
      27037 # Steam Remote Play
    ];

    networking.firewall.allowedUDPPorts = [
      27031 # Steam Remote Play
      27036 # Steam Remote Play
    ];

    environment.systemPackages = [
      pkgs.lutris
      pkgs.heroic
      pkgs.protonup-qt
      # pkgs.mcpelauncher-ui-qt-git
    ];

    # For MCPE Launcher (TEMP)
    # TODO: Remove later
    services.flatpak.enable = true;
  };
}
