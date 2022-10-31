{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware.nix
      ../../profiles/server.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "hermes"; # Define your hostname.
    domain = secrets.DOMAIN;
  };

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7AItff1gZXXS0qVsAIy8qBz4e/1etAArnj+qccuUVwf8ybAYQwD4910h1D4rFBSjf9KmMdY1nesprNKM8ICeA5jSH7kblkRYOB3nUjg5B/GqWDgtjU4ooJBBP7ibuqZfbwDzTPH1Cuodc4CBPdy/yulCHpAZRU7YauXxXvQOckbd8uHoPC5wggQSjVszsyfaQGTx0N0hMv1aHBPstp9It9JiHuxtwSvyctRiXFdWdmsBbTla086Nuc8uFoaKWiuxIRyplW0qSswIbrBdVUY7q+ss38pjcDhHSag3tItEU9FRBfYkcT3PxsmHFYTgjX4bNl2Y1VcxQ0n3Fs5yZYWZcbDtooPrHSyMwaoqm+QECIu6nKSVsa/Iq0d/3JaA8MJZ/zV1JlydSMcfi2XcXYvJauyuQgwOVIyXhb6N/zTs4pgwlVMkxtUCatPe2zWHvfRBOtfNbw1zDW/pzh/lJcIPuWmESv/zPcsJC4r+cD0lASi+UjZyIeVOaKuhznO7kRPfRO4H8BwW4T2qSo5xDrjR7gR820TyJWEUZbMdMByrgZvWyJEoxPfrAhMQdtnbaX0nRvdYcori/cL1b8QxUZTLdZgwVaxeyh0/P5fOK01OO9MH7O19ZtkkAx9dswk1Y5rQWzmQp6Ab+pAizPNZBwNDxdQaoB48ZAX/KDG3jmSdZgw=="
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIXRwspQVv8bM/2WXqbt2ZXldeesSMYSfdC316oGpCv8eYiR5RtvecTu5fW490Qu9KPAEqGKNrCKf+JHADJ3Mkm/iJN6+6eDy5GZUsSWyo09O2dE1jmtxFgRoc4tjODV8TrbuItAHnw10jQAhmE+A8L0a0l1xRGHzPa2c7VHANH0T0/KSGfXekpbEhK/amUUsfIpbsinCFErbSmpZ5fgwkfds4vdl/uAPmAx92KC7IcqgyjGLehSlhM2wHn8JvRWbTA+A3TSbls6VOkic2RMnmj4g1B+WnyVnfhS2/gleMHVqFGeiCesOsR4ZaI9jXr7nBaPzADUxf95ZkJIdKnijM3PcMH0U0Sp7PoEWDvMNa7s7Y9BpQqXelJ7iWhtRznr8N9epOeG9ux6aYz4+AcC9T3oam+IZb+7XAr617BxMcEp8sjzdd+yw2YhIylqCBnntLUk59VB5MRxLY6wqof81V/sh1D079nCSC64hL9iFANonIhl59H1V3MhTGKFhpPavJgAqyvuc5EbOo8rNNGdVBXYntI6whUbD5w+SG/ujQsgNyYlqp4QBtuofttQSu+GxG43khHJmpK9uNO8Dy790MCcCx3Z7kqi88njejyQ7k0lOgVqwFQHNjtuSjT7Rl+gfNj2tMyHlkVTskw20iOwSxxAjnpAGrjEQkjjHIc6hLUw=="
  ];

  system.stateVersion = "22.11"; # Did you read the comment?
}

