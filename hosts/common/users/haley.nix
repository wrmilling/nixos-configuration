{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.fish = {
    enable = true;
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };

  users.users.haley = {
    uid = 1001;
    shell = pkgs.fish;
    isNormalUser = true;
    home = "/home/haley";
    description = "Haley C. Milling";
    extraGroups = [
      "networkmanager"
      "audio"
      "uucp"
      "dialout"
      "video"
    ];
  };
}
