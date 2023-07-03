{ config, lib, pkgs, ... }:

{
  sops.secrets."users/w4cbe/passwd" = {};
  sops.secrets."users/w4cbe/passwd".neededForUsers = true;

  programs.fish = {
    enable = true;
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };

  users.users.w4cbe = {
    uid = 1000;
    shell = pkgs.fish;
    isNormalUser = true;
    home = "/home/w4cbe";
    description = "Winston R. Milling";
    passwordFile = config.sops.secrets."users/w4cbe/passwd".path;
    extraGroups = [
      "trusted-users"
      "wheel"
      "networkmanager"
      "audio"
      "uucp"
      "dialout"
      "video"
    ];
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7AItff1gZXXS0qVsAIy8qBz4e/1etAArnj+qccuUVwf8ybAYQwD4910h1D4rFBSjf9KmMdY1nesprNKM8ICeA5jSH7kblkRYOB3nUjg5B/GqWDgtjU4ooJBBP7ibuqZfbwDzTPH1Cuodc4CBPdy/yulCHpAZRU7YauXxXvQOckbd8uHoPC5wggQSjVszsyfaQGTx0N0hMv1aHBPstp9It9JiHuxtwSvyctRiXFdWdmsBbTla086Nuc8uFoaKWiuxIRyplW0qSswIbrBdVUY7q+ss38pjcDhHSag3tItEU9FRBfYkcT3PxsmHFYTgjX4bNl2Y1VcxQ0n3Fs5yZYWZcbDtooPrHSyMwaoqm+QECIu6nKSVsa/Iq0d/3JaA8MJZ/zV1JlydSMcfi2XcXYvJauyuQgwOVIyXhb6N/zTs4pgwlVMkxtUCatPe2zWHvfRBOtfNbw1zDW/pzh/lJcIPuWmESv/zPcsJC4r+cD0lASi+UjZyIeVOaKuhznO7kRPfRO4H8BwW4T2qSo5xDrjR7gR820TyJWEUZbMdMByrgZvWyJEoxPfrAhMQdtnbaX0nRvdYcori/cL1b8QxUZTLdZgwVaxeyh0/P5fOK01OO9MH7O19ZtkkAx9dswk1Y5rQWzmQp6Ab+pAizPNZBwNDxdQaoB48ZAX/KDG3jmSdZgw=="
    ];
  };
}
