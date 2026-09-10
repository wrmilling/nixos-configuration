{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.home.terminal.k8s-utils;
in
{
  imports = [ inputs.sofka.homeManagerModules.default ];

  options.modules.home.terminal.k8s-utils = {
    enable = lib.mkEnableOption "k8s-utils packages / settings";
  };

  config = lib.mkIf cfg.enable {
    # :debug on a pod/node covers k9s's old debug-container plugin natively
    # (https://github.com/derailed/k9s/blob/master/plugins/debug-container.yaml).
    programs.sofka = {
      enable = true;
      settings = {
        skin.name = "tokyo-night";
        debug.image = "nicolaka/netshoot:v0.12";
      };
    };
  };
}
