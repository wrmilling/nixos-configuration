# Secrets

## Add new host

Get key for target machine: `nix-shell -p ssh-to-age --run 'ssh-keyscan example.com | ssh-to-age'`
Put the new key in `.sops.yaml` in root of repo and add it to any specific secret it needs.
Update the secrets where the key was added, e.g.: `sops updatekeys secrets/general.yaml`
