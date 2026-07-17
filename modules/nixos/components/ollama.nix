{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.ollama;

  accelerationPackages = {
    cpu = pkgs.ollama-cpu;
    cuda = pkgs.ollama-cuda;
    rocm = pkgs.ollama-rocm;
    vulkan = pkgs.ollama-vulkan;
  };
in
{
  options.modules.nixos.ollama = {
    enable = lib.mkEnableOption "ollama local LLM server";

    acceleration = lib.mkOption {
      type = lib.types.enum [
        "cpu"
        "cuda"
        "rocm"
        "vulkan"
      ];
      default = "cpu";
      description = "Hardware acceleration backend for ollama";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = accelerationPackages.${cfg.acceleration};
    };
  };
}
