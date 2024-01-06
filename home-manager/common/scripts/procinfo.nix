{
  config,
  pkgs,
  ...
}: let
  procinfo = pkgs.writeShellScriptBin "procinfo" ''
    # Provides useful information for the Pine64 Pinebook Pro
    # CPU Core Frequencies
    a53freq=$(${pkgs.coreutils-full}/bin/cat /sys/devices/system/cpu/cpu1/cpufreq/scaling_cur_freq | ${pkgs.gawk}/bin/awk '{print $1 / 1000000}')
    a72freq=$(${pkgs.coreutils-full}/bin/cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_cur_freq | ${pkgs.gawk}/bin/awk '{print $1 / 1000000}')
    cpu=$(${pkgs.coreutils-full}/bin/cat /sys/class/thermal/thermal_zone0/temp)

    # GPU Core Frequencies
    gpufreq=$(${pkgs.coreutils-full}/bin/cat /sys/devices/platform/ff9a0000.gpu/devfreq/ff9a0000.gpu/cur_freq | ${pkgs.gawk}/bin/awk '{print $1 / 1000000}')
    gpu=$(${pkgs.coreutils-full}/bin/cat /sys/class/thermal/thermal_zone1/temp)

    power_divisor=1000000000000
    # Battery usage in Watts
    bat_current_now=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/cw2015-battery/current_now)
    bat_voltage_now=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/cw2015-battery/voltage_now)
    bat_power_now=$(echo "scale=2;$bat_current_now * $bat_voltage_now / $power_divisor" | bc -l)

    # Charger draw in Watts
    chg_current_now=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/tcpm-source-psy-4-0022/current_now)
    chg_voltage_now=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/tcpm-source-psy-4-0022/voltage_now)
    chg_power_now=$(echo "scale=2;$chg_current_now * $chg_voltage_now / $power_divisor" | bc -l)

    # Is the barrel plug being used. We don't have current/voltage for barrel.
    barrel_charging=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/dc-charger/online)

    # Current battery level
    bat_current_level=$(${pkgs.coreutils-full}/bin/cat /sys/class/power_supply/cw2015-battery/capacity)

    # Print everything out
    echo CPU Temp: ${cpu::2}C '|' A53 Freq: $a53freq Ghz '|' A72 Freq: $a72freq Ghz
    echo GPU Temp: ${gpu::2}C '|' GPU Freq: $gpufreq Mhz
    echo Battery Charge Level is $bat_current_level %

    if [[ "$bat_power_now" != "0" ]]; then
      echo Battery Discharging at $bat_power_now Watts
    fi

    if [[ "$chg_power_now" != "0" ]]; then
      echo USB-C Charger Supplying $chg_power_now Watts
    elif [[ "$barrel_charging" == "1" ]]; then
      echo Charging via Barrel Plug
    fi
  '';
in {
  home.packages = [procinfo];
}
