{ lib, pkgs, ... }:
{
  imports = [ ../agent-sandbox/guest.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  home-manager.users.w4cbe.modules.home.terminal.agents.mcpServers.flux.enable = false;

  environment.systemPackages = [
    pkgs.cloudfoundry-cli
    pkgs.shiftleft-sl
    pkgs.wizcli
  ];
}
