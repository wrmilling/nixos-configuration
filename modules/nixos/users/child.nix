{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.users.w4cbe;
  ifTheyExist = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
in
{
  options.modules.users.w4cbe = {
    enable = lib.mkEnableOption "child user";
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;
      vendor = {
        completions.enable = true;
        config.enable = true;
        functions.enable = true;
      };
    };

    users.users.child = {
      shell = pkgs.fish;
      isNormalUser = true;
      home = "/home/child";
      description = "Child Milling";
      extraGroups = [
      ] ++ ifTheyExist [
        "networkmanager"
        "audio"
        "video"
      ];
    };
  };
}
