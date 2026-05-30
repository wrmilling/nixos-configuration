{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  modules = {
    homeType.personal.enable = true;
    home.terminal.opencode = {
      plugin = [ "oh-my-openagent" ];
    };
  };

 # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
  
  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
