{
  lib,
  pkgs,
  secrets,
  ...
}:
{
  imports = [ ../agent-sandbox/guest.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  home-manager.users.w4cbe.modules.home.terminal.agents.mcpServers.flux.enable = false;
  home-manager.users.w4cbe.modules.home.terminal.claude-code.extraSettings = {
    extraKnownMarketplaces = secrets.hosts.work-mac.agents.marketplaces;
    inherit (secrets.hosts.work-mac.agents) enabledPlugins;
  };

  environment.systemPackages = [
    pkgs.cloudfoundry-cli
    pkgs.shiftleft-sl
    pkgs.wizcli
  ];
}
