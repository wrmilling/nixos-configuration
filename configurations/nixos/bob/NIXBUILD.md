# Nix remote builder SSH key rotation

This repo currently expects:

- the remote builder host to be `bob.<your-domain>`
- the remote builder user to be `nixbuild`
- the client private key to live at `/etc/nixbuild/nixbuild-client`

The configuration can still evaluate if the key is wrong or stale, but actual remote builds will fail until the key pair and host trust are updated.

## 1. Generate a new client key pair

Run this on the client machine that will offload builds:

```fish
sudo install -d -m 0700 /etc/nixbuild
sudo ssh-keygen -t ed25519 -f /etc/nixbuild/nixbuild-client -C "nixbuild-client" -N ""
sudo chmod 0600 /etc/nixbuild/nixbuild-client
sudo chmod 0644 /etc/nixbuild/nixbuild-client.pub
```

This creates:

- private key: `/etc/nixbuild/nixbuild-client`
- public key: `/etc/nixbuild/nixbuild-client.pub`

## 2. Install the public key on `bob`

### Preferred repo-managed approach

Replace the key in `modules/nixos/components/nixbuild-host.nix` with the contents of:

- `/etc/nixbuild/nixbuild-client.pub`

Then deploy `bob` normally.

### Manual host-side placement

If you need to update `bob` before doing a rebuild, place the public key in the `nixbuild` account's authorized keys file:

```fish
sudo install -d -m 0755 /etc/ssh/authorized_keys.d
sudo install -m 0644 /etc/nixbuild/nixbuild-client.pub /etc/ssh/authorized_keys.d/nixbuild
```

If the `nixbuild` user does not exist yet, the host still needs the NixOS module applied at least once.

## 3. Update the client-side host trust

The client module pins the SSH host key for `bob.<your-domain>` in `modules/nixos/components/nixbuild-client.nix`.

If `bob`'s SSH host key changed, get the current public host key from `bob` and replace the `programs.ssh.knownHosts.nixbuild.publicKey` value in that module.

To inspect the current host key on `bob`:

```fish
sudo cat /etc/ssh/ssh_host_ed25519_key.pub
```

## 4. Manually configure a client without `nixos-rebuild`

If you want to enable remote builds immediately on a client without rebuilding NixOS, configure SSH and Nix directly.

### Create the SSH trust files

```fish
sudo install -d -m 0700 /root/.ssh
sudo sh -c 'printf "%s\n" "bob.<your-domain> ssh-ed25519 <bob-host-public-key>" > /root/.ssh/known_hosts'
sudo chmod 0600 /root/.ssh/known_hosts
```

### Add a root SSH config for the builder

```fish
sudo sh -c 'cat > /root/.ssh/config <<"EOF"
Host bob.<your-domain>
  User nixbuild
  IdentityFile /etc/nixbuild/nixbuild-client
  IdentitiesOnly yes
  ServerAliveInterval 60
  IPQoS throughput
EOF'
sudo chmod 0600 /root/.ssh/config
```

### Add the remote builder to `/etc/nix/nix.conf`

Append or merge these settings into `/etc/nix/nix.conf`:

```conf
distributed-builds = true
builders = ssh-ng://nixbuild@bob.<your-domain> aarch64-linux /etc/nixbuild/nixbuild-client 4
builders-use-substitutes = true
```

If `builders` already exists, merge this builder into the existing value instead of creating a second `builders =` line.

### Test the SSH connection

```fish
sudo ssh -i /etc/nixbuild/nixbuild-client nixbuild@bob.<your-domain> true
```

### Test remote builder selection

```fish
sudo nix store ping --store ssh-ng://nixbuild@bob.<your-domain>
```

## 5. Apply the repo-managed version later

After the manual workaround is in place, update the checked-in keys/host key in:

- `modules/nixos/components/nixbuild-host.nix`
- `modules/nixos/components/nixbuild-client.nix`

Then apply the permanent configuration from the repo.
