{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.graphical.git;
in
{
  options.modules.home.graphical.git = {
    enable = lib.mkEnableOption "git graphical packages / settings";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.git-credential-manager ];
    # This assumes home.terminal.git is also enabled.
    # TODO: Do i need to just enable here as well? 
    programs.git.extraConfig.credential.helper =
      "${pkgs.git-credential-manager}/bin/git-credential-manager";
  };
}
