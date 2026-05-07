{ lib, ... }:

{
  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = lib.mkDefault true;
  hardware.deviceTree.filter = lib.mkForce "bcm2711-rpi-4*.dtb";

  hardware.deviceTree.overlays = [
    {
      name = "rpi-poe-overlay-mainline-v7";
      dtsText = ''
        /*
         * Host-local Raspberry Pi PoE HAT overlay for mainline-style v7.x Pi 4 DTs.
         */
        /dts-v1/;
        /plugin/;

        / {
          compatible = "brcm,bcm2711";

          fragment@0 {
            target-path = "/";
            __overlay__ {
              poe_fan: pwm-fan {
                compatible = "pwm-fan";
                cooling-levels = <0 1 10 100 255>;
                #cooling-cells = <2>;
                pwms = <&poe_fwpwm 0 80000 0>;
              };
            };
          };

          fragment@1 {
            target = <&cpu_thermal>;
            __overlay__ {
              polling-delay = <2000>;
            };
          };

          fragment@2 {
            target-path = "/thermal-zones/cpu-thermal/trips";
            __overlay__ {
              poe_fan_trip0: poe-fan-trip0 {
                temperature = <40000>;
                hysteresis = <2000>;
                type = "active";
              };

              poe_fan_trip1: poe-fan-trip1 {
                temperature = <45000>;
                hysteresis = <2000>;
                type = "active";
              };

              poe_fan_trip2: poe-fan-trip2 {
                temperature = <50000>;
                hysteresis = <2000>;
                type = "active";
              };

              poe_fan_trip3: poe-fan-trip3 {
                temperature = <55000>;
                hysteresis = <5000>;
                type = "active";
              };
            };
          };

          fragment@3 {
            target-path = "/thermal-zones/cpu-thermal/cooling-maps";
            __overlay__ {
              poe_fan_map0 {
                trip = <&poe_fan_trip0>;
                cooling-device = <&poe_fan 0 1>;
              };

              poe_fan_map1 {
                trip = <&poe_fan_trip1>;
                cooling-device = <&poe_fan 1 2>;
              };

              poe_fan_map2 {
                trip = <&poe_fan_trip2>;
                cooling-device = <&poe_fan 2 3>;
              };

              poe_fan_map3 {
                trip = <&poe_fan_trip3>;
                cooling-device = <&poe_fan 3 4>;
              };
            };
          };

          fragment@4 {
            target = <&firmware>;
            __overlay__ {
              poe_fwpwm: pwm {
                compatible = "raspberrypi,firmware-poe-pwm";
                #pwm-cells = <2>;
              };
            };
          };
        };
      '';
    }
  ];
}
