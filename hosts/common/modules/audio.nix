{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [ pkgs.pw-volume ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.extraConfig."10-bluez" = {
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.enable-hw-volume" = true;
        "bluez5.roles" = [
          "hsp_hs"
          "hsp_ag"
          "hfp_hf"
          "hfp_ag"
          "a2dp_sink"
          "a2dp_source"
          "bap_sink"
          "bap_source"
        ];
        "bluez5.codecs" = [
          "ldac"
          "aptx"
          "aptx_ll_duplex"
          "aptx_ll"
          "aptx_hd"
          "opus_05_pro"
          "opus_05_71"
          "opus_05_51"
          "opus_05"
          "opus_05_duplex"
          "aac"
          "sbc_xq"
        ];
      };
    };
  };
}
