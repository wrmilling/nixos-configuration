{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [ i3status-rust ];
  home.file."i3status-rust-config" = {
    target = ".config/i3status-rust/config.toml";
    text = ''
      [theme]
      theme = "slick"

      [icons]
      icons = "awesome4"

      [[block]]
      block = "cpu"
      interval = 5

      [[block]]
      block = "memory"
      format = " $icon $mem_avail.eng(p:M,w:3) "

      [[block]]
      block = "temperature"
      interval = 10
      format = " $icon $average "
      chip = "cpu_thermal-*"

      [[block]]
      block = "temperature"
      interval = 10
      format = " $icon $average "
      chip = "gpu_thermal-*"

      [[block]]
      block = "disk_space"
      path = "/"
      interval = 20
      warning = 20.0
      alert = 10.0
      format = " $icon $available.eng(p:G,w:3) "

      [[block]]
      block = "battery"
      device = "cw2015-battery"
      interval = 10

      [[block]]
      block = "time"
      interval = 5
      format = " $icon $timestamp.datetime() "
    '';
  };
}
