{
  config,
  pkgs,
  lib,
  callPackage,
  ...
}: {
  environment.pathsToLink = [ "/share/cosmic" ];

  environment.systemPackages = with pkgs; [
    cosmic-applibrary
    cosmic-applets
    cosmic-bg
    lilyinstarlight.cosmic-comp
    cosmic-edit
    cosmic-files
    lilyinstarlight.cosmic-greeter
    cosmic-icons
    cosmic-launcher
    cosmic-notifications
    cosmic-osd
    lilyinstarlight.cosmic-panel
    cosmic-randr
    cosmic-screenshot
    lilyinstarlight.cosmic-settings
    cosmic-term
    cosmic-workspaces-epoch
  ];

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      lilyinstarlight.xdg-desktop-portal-cosmic
      xdg-desktop-portal-gtk
    ];
    configPackages = with pkgs; [
      lilyinstarlight.xdg-desktop-portal-cosmic
    ];
  };

  hardware.opengl.enable = true;
  services.xserver.libinput.enable = true;

  security.polkit.enable = true;

  services.xserver.displayManager.sessionPackages = with pkgs; [ cosmic-session ];
  systemd.packages = with pkgs; [ cosmic-session ];

  # services.xserver.displayManager.cosmic-greeter.enable = lib.mkDefault true;
  # In-lining the above as I am not pulling in the lilyinstarlight nixpkgs fully
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        user = "cosmic-greeter";
        command = "systemd-cat -t cosmic-greeter ${pkgs.lilyinstarlight.cosmic-comp}/bin/cosmic-comp ${pkgs.lilyinstarlight.cosmic-greeter}/bin/cosmic-greeter";
      };
    };
  };

  systemd.services.cosmic-greeter-daemon = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.lilyinstarlight.cosmic-greeter}/bin/cosmic-greeter-daemon";
      Restart = "on-failure";
    };
  };
  systemd.services.greetd.unitConfig.After = [ "cosmic-greeter-daemon.service" ];

  systemd.tmpfiles.rules = [
    "d '/var/lib/cosmic-greeter' - cosmic-greeter cosmic-greeter - -"
  ];

  users.users.cosmic-greeter = {
    isSystemUser = true;
    home = "/var/lib/cosmic-greeter";
    group = "cosmic-greeter";
  };

  users.groups.cosmic-greeter = { };

  # hardware.opengl.enable = true;
  # services.xserver.libinput.enable = true;

  security.pam.services.cosmic-greeter = {};

  services.dbus.packages = with pkgs; [ lilyinstarlight.cosmic-greeter ];
}