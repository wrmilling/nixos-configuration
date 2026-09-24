{ lib, ... }:
{
  imports = [ ./guest.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Enables only on personal machines for now, expects the
  # personal home manager config to have the api keys set.
  home-manager.users.w4cbe.modules.homeType.agentSandbox = {
    providers.z-ai.enable = true;
    providers.opencode-go.enable = true;
  };
}
