# hermes

![neofetch screenshot](https://i.imgur.com/Mrwx9pL.png)

This is a Oracle Free Tier AM1 ARM64 system. I am generally following [this guide](https://blog.korfuri.fr/posts/2022/08/nixos-on-an-oracle-free-tier-ampere-machine/) for the initial setup steps, copied/paraphrased below in case of link rot.

## Installation

### Create Your Machine

Register for Oracle Free tier and create an instance in your desired size running the latest LTS of Ubuntu available as a free-tier image. This may also require setting up an Oracle [VCN](https://www.oracle.com/cloud/networking/virtual-cloud-network/) (its been a minute since I did initial setup) with your desired ports open for the instance, google is a friend here. 

For my instance, I built the VM.Standard.A1.Flex with 4 OCPU and 24GB of memory (just like the article linked above). For my block storage, I chose 150GB to be allocated to this instance, the other 50GB in the free tier being allocated to the also-free x86_64 instance available at Oracle. 

Once your machine is created, its time to...

### Install Nix

Which will follow the [standard multi-user install guide](https://nixos.org/manual/nix/stable/installation/installing-binary.html#multi-user-installation):

```
$ ssh ubuntu@<IP_ADDRESS>
$ sh <(curl -L https://nixos.org/nix/install) --daemon  # this will prompt you for a few choices, answer n, y, y
```

Log-out and Log-in again to get a working nix shell. At this point, we can...

### Prepare the in-Memory NixOS System

Following the guide linked at the top of this README, which follows the [NixOS guide for a server with a different filesystem](https://nixos.wiki/wiki/Install_NixOS_on_a_Server_With_a_Different_Filesystem), we will create an in-memory NixOS install to take-over the system with:

```
$ git clone https://github.com/cleverca22/nix-tests.git
$ cd nix-tests/kexec
$ nano myconfig.nix
```

Config being edited looking something like this (don't forget to add SSH key to the config): 

```
{
  imports = [
    ./configuration.nix
  ];

  # Make it use predictable interface names starting with eth0
  boot.kernelParams = [ "net.ifnames=0" ];

  networking.useDHCP = true;

  kexec.autoReboot = false;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa ....."
  ];
}
```

Once save, you can build the system: 

```
$ nix-build '<nixpkgs/nixos>' -A config.system.build.kexec_tarball -I nixos-config=./myconfig.nix
```

And finally run the in-memory system which will take 5-10 minutes to execute, you are looking for `+ kexec -e` to know when to terminate the ssh connection and re-connect (hit `enter`, then `~`, finally `.` to exit the connection): 

```
$ tar -xf ./result/tarball/nixos-system-aarch64-linux.tar.xz
$ sudo ./kexec_nixos
```

Once you have exited, ssh in again as root: 

```
$ ssh-keygen -R <IP_ADDRESS>
$ ssh root@<IP_ADDRESS>
```

And we are now able to...

### Install NixOS to the Disk

We are in an in-memory NixOS install now, we can use this to install direct to the VM's disk. Do not reboot yet, you will be back in Ubuntu at that point. These steps are approximated to what I did a little different than the guide, but 99% the same.

First, partitioning:

```
# parted
(parted) rm 1
(parted) rm 15
(parted) mkpart
Partition name?  []? boot
File system type?  [ext2]? fat32
Start? 2048s
End? 5GB
(parted) print all
Model: ORACLE BlockVolume (scsi)
Disk /dev/sda: 150.0GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
 1      1049kB  5.0GB  4999MB  fat32        boot  msftdata


(parted) set 1 boot on
(parted) set 1 esp on
(parted) mkpart
Partition name?  []?
File system type?  [ext2]? ext4
Start? 5GB
End? -1s
Warning: You requested a partition from 5.0GB to 150.0GB (sectors XXXXX..XXXX).
The closest location we can manage is 5.0GB to 150.0GB (sectors XXXXX..XXXX).
Is this still acceptable to you?
Yes/No? yes
(parted) quit
```

Then creating the filesystems and setting up a basic configuration:

```
$ mkfs.fat -F 32 /dev/sda1
$ mkfs.ext4 /dev/sda2
$ mkdir -p /mnt/boot
$ mount /dev/sda2 /mnt/
$ mount /dev/sda1 /mnt/boot/
$ nixos-generate-config --root /mnt
$ nano /mnt/etc/nixos/configuration.nix   # You want to at least set openssh.enable = true; and add an ssh key for root, like we did in the temporary system above.
```

Finally, install the base system and reboot if successful: 

```
$ nixos-install
$ reboot
```

At this point, we can log back into the system again and...

### Use This Flake

Once logged back into the fresh system as root, I will normally do the following to utilize this repo:

```
$ cd /etc/nixos/
$ nix-shell -p git --run "git clone https://git.sr.ht/~wrmilling/nixos-configuration .
```

Make sure the disk UUIDs are correct in `hardware.nix` from the machine generated `configuration.nix` before proceeding, they will change after a rebuild. Also, my config currently assumes a secrets file in `/etc/nixos` with the following contents for this machine: 

```
{
  hosts: {
    hermes: {
      domain: <DOMAIN_NAME>;
    };
  };
}
```

Finally: 

```
$ nixos-rebuild switch --flake .#hermes
```

All goes well, the system is humming along happily.

## Credits

Just want to mention it again, [this guide](https://blog.korfuri.fr/posts/2022/08/nixos-on-an-oracle-free-tier-ampere-machine/) by korfuri was invaluable in building this machine. 