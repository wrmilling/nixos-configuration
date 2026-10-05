{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.syncthingHub;

  knownDevices = lib.filterAttrs (_: id: id != null);
  folders = lib.filterAttrs (_: folder: knownDevices folder.devices != { }) cfg.folders;
in
{
  options.modules.nixos.syncthingHub = {
    enable = lib.mkEnableOption ''
      an always-on Syncthing peer that relays folders between devices which
      are rarely online together. Every folder is receiveencrypted, so this
      host stores only ciphertext and never holds a folder password
    '';

    certFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to the hub's Syncthing cert.pem, which fixes its device ID.";
    };

    keyFile = lib.mkOption {
      type = lib.types.str;
      description = "Path to the hub's Syncthing key.pem.";
    };

    folders = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.devices = lib.mkOption {
            type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
            description = ''
              Device name to Syncthing device ID for each device sharing this
              folder. Null IDs are skipped, so a device can be listed before
              its identity exists; a folder with none is left out.
            '';
          };
        }
      );
      default = { };
      description = "Folders to hold encrypted, keyed by Syncthing folder ID.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open Syncthing's sync port (TCP and UDP 22000).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      cert = cfg.certFile;
      key = cfg.keyFile;
      settings = {
        options = {
          localAnnounceEnabled = false;
          urAccepted = -1;
        };
        devices = lib.concatMapAttrs (
          _: folder: lib.mapAttrs (_: id: { inherit id; }) (knownDevices folder.devices)
        ) folders;
        folders = lib.mapAttrs (id: folder: {
          inherit id;
          path = "${config.services.syncthing.dataDir}/${id}";
          type = "receiveencrypted";
          devices = lib.attrNames (knownDevices folder.devices);
        }) folders;
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [ 22000 ];
    };
  };
}
