# NixOS Configuration

A work in progress, attempting to make it handle multiple machines and share between them. Based on [samueldr's work](https://gitlab.com/samueldr/nixos-configuration).

## General Layout

```
- Machine (Serenity)
|--- Profile (Laptop)
|  |--- Modules (Audio, Bluetooth, Networking, etc.)
|--- Addons (Development, k8s-utils, tailscale)
```

The repository is split into three main sections:
- Machines: Definition of the individual machines to which I have deployed NixOS. In each machine folder you will also find the unique hardware definitions for each device. 
- Profiles: Define the use for the devices, in this case a Desktop, Laptop, or server. Underneith the Profile is all the shared modules that these will use as well as my basic set of utilities and preferred desktop environment. 
- Addons: Each machine can also define addons which install programs and features such as development applications and gaming applications or enhancements like enabling zram.   