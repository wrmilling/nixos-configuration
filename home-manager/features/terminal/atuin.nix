{ pkgs, lib, config, inputs, ... }:

{
  programs.atuin = {
    enable = true;
    package = pkgs.atuin;

    flags = [
      "--disable-up-arrow"
    ];

    settings = {
      auto_sync = true;
      sync_frequency = "1h";
      search_mode = "fuzzy";
    };
  };
}