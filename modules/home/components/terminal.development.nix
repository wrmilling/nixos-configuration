{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.development;

  # Prefer Node.js 22 if available (required by Copilot CLI), fall back otherwise
  node = if pkgs ? nodejs_22 then pkgs.nodejs_22 else (pkgs.nodejs_latest or pkgs.nodejs);

  copilot = pkgs.writeShellScriptBin "copilot" ''
    #!${pkgs.bash}/bin/bash
    # Run GitHub Copilot CLI via npx so we don't need a separate package.
    # Requires network on first run to download @github/copilot.
    exec ${node}/bin/npx --yes @github/copilot "$@"
  '';
in
{
  options.modules.home.terminal.development = {
    enable = lib.mkEnableOption "development configuration file settings";
  };

  config = lib.mkIf cfg.enable {
    # Packages
    home.packages = [
      node
      copilot
    ];
  };
}
