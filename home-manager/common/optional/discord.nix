{
  pkgs,
  lib,
  config,
  ...
}: let
  discord-name = pkgs.makeDesktopItem {
    name = "discord-name";
    desktopName = "Discord (Name)";
    genericName = "Discord";
    comment = "All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.";
    icon = "discord";
    categories = ["Network" "InstantMessaging"];
    exec = "${pkgs.bashInteractive}/bin/bash -c \"export XDG_CONFIG_HOME=~/.config/discord-name\; export TMPDIR=~/.config/discord-name/tmp\; ${pkgs.discord}/bin/discord\"";
  };
  discord-game = pkgs.makeDesktopItem {
    name = "discord-game";
    desktopName = "Discord (Game)";
    genericName = "Discord";
    comment = "All-in-one voice and text chat for gamers that's free, secure, and works on both your desktop and phone.";
    icon = "discord";
    categories = ["Network" "InstantMessaging"];
    exec = "${pkgs.bashInteractive}/bin/bash -c \"export XDG_CONFIG_HOME=~/.config/discord-game\; export TMPDIR=~/.config/discord-game/tmp\; ${pkgs.discord}/bin/discord\"";
  };
in {
  home.packages = with pkgs; [
    discord
    discord-name
    discord-game
  ];
  home.file.".discord-name-keep" = {
    text = " ";
    target = ".config/discord-name/tmp/.keep";
  };
  home.file.".discord-game-keep" = {
    text = " ";
    target = ".config/discord-game/tmp/.keep";
  };
}
