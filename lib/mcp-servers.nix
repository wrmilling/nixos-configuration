# Projects modules.home.terminal.agents.mcpServers (defined in
# modules/home/components/terminal.agents.nix) into each harness's config
# shape. Only enabled servers are projected.
#
# Canonical server shape:
#   { command = "<store path>"; args = [ "<arg>" … ]; env = { NAME = "value"; }; }
{ lib }:
mcpServers:
let
  servers = lib.filterAttrs (_: s: s.enable) mcpServers;
in
{
  inherit servers;

  # Shape used by home-manager's programs.claude-code.mcpServers.
  claudeCode = lib.mapAttrs (
    _: s:
    {
      command = s.command;
      args = s.args;
    }
    // lib.optionalAttrs (s.env != { }) { env = s.env; }
  ) servers;

  # Attrset shape consumed by `pkgs.formats.toml` to render
  # `~/.codex/config.toml`. Env vars are nested under `.env` so they appear
  # in their own `[mcp_servers.<name>.env]` sub-table.
  codex = lib.mapAttrs (
    _: s:
    {
      type = "stdio";
      command = s.command;
      args = s.args;
    }
    // lib.optionalAttrs (s.env != { }) { env = s.env; }
  ) servers;

  # Shape used in the `mcp` key of `~/.config/opencode/opencode.json`.
  # OpenCode calls the field `environment` (not `env`) and stores the
  # command as a list (no separate `args`).
  openCode = lib.mapAttrs (_: s: {
    type = "local";
    command = [ s.command ] ++ s.args;
    environment = s.env;
  }) servers;

  # Shape used in the `[mcp.<name>]` sections of `~/.config/maki/mcp.toml`.
  # Maki stores `command` as an array (program + args) and env under
  # `environment`. Empty env maps are omitted.
  maki = lib.mapAttrs (
    _: s:
    { command = [ s.command ] ++ s.args; } // lib.optionalAttrs (s.env != { }) { environment = s.env; }
  ) servers;
}
