{ lib, ... }:
{
  imports = [ ./guest.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Enables only on personal machines for now, expects the
  # personal home manager config to have the api key set.
  home-manager.users.w4cbe.modules.homeType.agentSandbox.zclaude.enable = true;
  home-manager.users.w4cbe.modules.homeType.agentSandbox.oclaude.enable = true;
  home-manager.users.w4cbe.modules.homeType.agentSandbox.maki.enable = true;
  home-manager.users.w4cbe.modules.homeType.agentSandbox.opencode.enable = true;
  home-manager.users.w4cbe.modules.homeType.agentSandbox.codex.enable = true;
}
