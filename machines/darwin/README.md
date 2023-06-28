# Darwin

![neofetch screenshot](https://i.imgur.com/vwRq77j.png)

Currently my only darwin-based nix system and used for work. Utilizes [nix-darwin](https://github.com/LnL7/nix-darwin) and [homebrew](https://brew.sh) for package and system management, going to be different than any of my other [NixOS](https://nixos.org)-based systems. 

## System Setup

Utilize a combined certificate to assuage the MitM gods throughout the process. As part of my latest install I included the certificate as the `ssl-cert-path1` in `/root/.config/nix/nix.conf`, set in my local environment under `NIX_SSL_CERT_PATH` and as part of the initial nix-darwin build as `security.pki.certificateFiles = [ "/path/to/cert" ];`. You most likely won't have to do any of this mess, but this documentation is also for me, so here it is. 

### Install [Nix](https://nixos.org/download.html#nix-install-macos)

```
sh <(curl -L https://nixos.org/nix/install) --daemon
```

### Install [nix-darwin](https://github.com/LnL7/nix-darwin#install)

Pay attention to any warnings, etc., that it gives you during this process. Other files may need to be edited, deleted, or otherwise dealt with.

```
nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer
```

### Install [homebrew](https://brew.sh)

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

```

## Using This Flake

```
git clone https://git.sr.ht/~wrmilling/nixos-configuration ~/.nixos-configuration
```

Note: `~/.nixos-configuration` is where I put it, you can chose your own as you see fit, just be sure to update the fish shell references. 

You will also need to define your own secrets file which includes the following in it (or just eliminate the secrets file and update your machine and usernames in the configuration):

```
{
  machines = {
    work-mac = {
      username = "XXXXX";
      hostname = "XXXXX";
      email = {
        short = "xxxx@example.com";
        long = "xxxx_xxxx@example.com";
      };
    };
  };
}

```

Finally you can build/install the flake:

```
darwin-rebuild switch --flake ~/.nixos-confiugration/
home-manager switch --flake ~/.nixos-confiugration/
```

## Other Things

Post install cleanup items (lest your shell yell at you).

### atuin login

```shell
atuin login --username "<YOUR_USERNAME>" --key "<YOUR_KEY"
atuin import auto
atuin sync
```