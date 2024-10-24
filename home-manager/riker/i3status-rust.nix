{
  pkgs,
  lib,
  config,
  ...
}:
let
  bat-draw = pkgs.writeShellScriptBin "bat-draw" ''
    power_divisor=1000000000000
    bat_current_now=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/cw2015-battery/current_now)
    bat_voltage_now=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/cw2015-battery/voltage_now)
    bat_power_now=$(echo "scale=2;$bat_current_now * $bat_voltage_now / $power_divisor" | bc -l)
    printf "%sW" $bat_power_now
  '';
in
{
  home.packages = [
    pkgs.i3status-rust
    pkgs.bat-draw
  ];
  home.file."i3status-rust-config" = {
    target = ".config/i3status-rust/config.toml";
    text = ''
      [theme]
      theme = "slick"

      [icons]
      icons = "awesome4"

      [[block]]
      block = "cpu"
      interval = 10

      [[block]]
      block = "memory"
      format = " $icon $mem_avail.eng(p:M,w:3) "
      interval = 30

      [[block]]
      block = "temperature"
      interval = 30
      format = " $icon $average "
      chip = "cpu_thermal-*"

      [[block]]
      block = "temperature"
      interval = 30
      format = " $icon $average "
      chip = "gpu_thermal-*"

      [[block]]
      block = "disk_space"
      path = "/"
      interval = 60
      warning = 20.0
      alert = 10.0
      format = " $icon $available.eng(p:G,w:3) "

      [[block]]
      block = "disk_space"
      path = "/mnt/NVMe"
      interval = 60
      warning = 20.0
      alert = 10.0
      format = " $icon $available.eng(p:G,w:3) "

      [[block]]
      block = "battery"
      device = "cw2015-battery"
      interval = 30

      [[block]]
      block = "custom"
      command = "echo '\uf0e7 ' $(${bat-draw}/bin/bat-draw)"
      interval = 20

      [[block]]
      block = "time"
      interval = 5
      format = " $icon $timestamp.datetime() "
    '';
  };
}
