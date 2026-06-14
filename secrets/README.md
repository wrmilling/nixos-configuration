# Secrets

## Add new host for sops-nix

Get key for target machine: `nix-shell -p ssh-to-age --run 'ssh-keyscan example.com | ssh-to-age'`
Put the new key in `.sops.yaml` in root of repo and add it to any specific secret it needs.
Update the secrets where the key was added, e.g.: `sops updatekeys secrets/general.yaml`

## Home-Manager secrets with sops-nix

The NixOS layer decrypts secrets with the root-owned host SSH keys. Standalone
Home-Manager runs as your unprivileged user and cannot read those keys, so it uses a
dedicated **per-user age key** instead. The reusable module lives at
`modules/home/components/sops.nix` and exposes `modules.home.sops.enable` (off by
default). It sets `sops.age.keyFile` to `~/.config/sops/age/keys.txt` and intentionally
leaves `defaultSopsFile` unset — every secret declares its own `sopsFile`.

### 1. Generate the user age key (once per user/machine)

```sh
mkdir -p ~/.config/sops/age/ && nix-shell -p age --run 'age-keygen -o ~/.config/sops/age/keys.txt'
```

This prints the **public** key (`age1...`); keep the file itself private. The private key
is read at activation time and is never copied into the Nix store.

### 2. Register the public key in `.sops.yaml`

Add a new anchor alongside the existing host anchors and reference it from the
`key_groups.age` list of any `creation_rules` entry whose file should hold Home-Manager
secrets:

```yaml
keys:
  - &w4cbe age1... # the public key from step 1

creation_rules:
  - path_regex: secrets/home.yaml$
    key_groups:
      - pgp:
          - *primary
        age:
          - *w4cbe
```

### 3. Re-key any existing files that gained the new recipient

```sh
sops updatekeys secrets/home.yaml
```

### 4. Enable the module in a home profile or configuration

```nix
modules.home.sops.enable = true;
```

### 5. Declare and use a secret

Because there is no default sops file, every secret sets its own `sopsFile`:

```nix
sops.secrets."example/token" = {
  sopsFile = ../../secrets/home.yaml;
};
```

Reference it through its runtime path (never inline the value):

```nix
config.sops.secrets."example/token".path
```

### Notes

- On Linux the secrets are decrypted by a `sops-nix` **systemd user service** that runs on
  Home-Manager activation; on macOS a launchd agent runs at login.
- Unless overridden with `path`, decrypted secrets land at
  `~/.config/sops-nix/secrets/<name>`.
- sops-nix never writes plaintext into the Nix store — only the runtime path is exposed.
