---
name: agent-sandbox
description: Use when changing the agent-sandbox microVM in this flake — host modules, guest config, shares, volumes, agent/socket forwarding — or when working from inside the sandbox guest itself. Covers the file layout, the option and lib conventions, what deliberately crosses the host/guest boundary, and what the guest can and cannot reach.
---

# Agent sandbox

A microVM (microvm.nix) that runs a coding agent harness against a shared
workspace, isolated from the host it runs on. It is **harness-agnostic** —
the guest happens to enable `home.terminal.claude-code` today, but nothing
in the design is Claude-specific, and the naming (`agent-sandbox`) is
deliberate so another harness can reuse it. Don't reintroduce
harness-specific names into options, units, or paths.

## Layout

```
lib/agent-sandbox.nix                          shared helpers, both platforms
modules/nixos/components/agent-sandbox.nix     host side, NixOS (qemu)
modules/darwin/agent-sandbox.nix               host side, macOS (vfkit)
modules/home/agent-sandbox.nix                 homeType.agentSandbox (guest user)
configurations/nixos/agent-sandbox/guest.nix   the guest, shared by both arches
configurations/nixos/agent-sandbox/default.nix       x86_64 wrapper
configurations/nixos/agent-sandbox-aarch64/default.nix  aarch64 wrapper
```

The two wrappers only set `nixpkgs.hostPlatform` and import the same
`guest.nix`. **All guest changes go in `guest.nix`** — never in a wrapper,
or the arches drift.

`lib/agent-sandbox.nix` is a plain function taking `{ lib }` only — not a
module. Import it where needed:

```nix
sandboxLib = import ../../../lib/agent-sandbox.nix { inherit lib; };
```

It holds `shareType`, `mkShares`, `mkVolumes`, the pinned `guestUid`, the
forwarded socket paths, and the sandbox SSH identity path. Anything both
host platforms need lives here so qemu and vfkit can't diverge.

## Conventions

- **New knob → an option on `modules.{nixos,darwin}.agentSandbox`**, with
  defaults kept identical across the two platforms (`vcpu = 4`,
  `memoryMB = 8192`, `diskSizeMB = 32768`). If you change one, change both.
- **Per-host shares go in the host's own `configurations/nixos/<host>/default.nix`**
  via `extraShares`, not in the component. The workspace share is always
  present via `mkShares`; `extraShares` is for everything else.
- **A bare path shared between a home-manager module and a host module gets
  hardcoded in both**, with a comment cross-referencing the other. Do not
  thread a `sandboxLib` import into host configs just to share one string —
  that was tried and deliberately reverted. `lib/agent-sandbox.nix` is for
  helpers and for values the two *host platforms* share, not for every
  constant.
- **Naming:** the VM, systemd unit, disk image, and launcher are all
  `agent-sandbox`. The guest's `networking.hostName` is `sandbox`.
- `diskSizeMB` applies **only at image creation** — microvm's volume script
  skips `mkfs` if the image exists. Changing it does not resize a live
  image.
- macOS-specific: `readOnly` on a share is **not enforced by vfkit**. Say so
  in any option docs, and don't rely on it for the Mac.
- The Darwin module exposes `runner` as a `readOnly` option; `flake.nix`
  re-exports it as `packages.aarch64-darwin.agent-sandbox-vm`. Keep that
  indirection — it's what keeps `flake.nix` to one line.
- **The `agent-sandbox` command is one shared shape, two backends.**
  `sandboxLib.mkCommandScript` owns the dispatch (`start`/`stop`/`status`/
  `help`, no-args = start + enter) and the help text; each platform module
  supplies its own `start`/`stop`/`status`/`enter` shell snippets and stays
  the only place that knows the mechanics:
  - **NixOS/qemu**: `systemctl {start,stop,is-active}` on
    `microvm@agent-sandbox.service`; enter polls SSH then execs into it.
  - **Darwin/vfkit**: there is no daemon and no networking to SSH over —
    `microvm-run` *is* the VM, its stdio *is* the console. `dtach` stands in
    for both: `dtach -n <socket> ... microvm-run` backgrounds it, `dtach -a`
    reattaches, and the socket's mere existence *is* the running/stopped
    check (dtach removes it when the child exits — verified empirically,
    dtach is portable and this doesn't need a Mac to test). `stop` calls the
    upstream-generated `microvm-shutdown`, which only exists because
    `microvm.socket` is set on the vfkit config (enables vfkit's
    `--restful-uri`) — don't remove that option thinking it's unused, it's
    what makes `stop` graceful instead of a bare kill.

## Guest design decisions

These exist for a reason; leave them in place unless you're deliberately
revisiting them.

- `microvm.writableStoreOverlay` is **required**: microvm.nix masks
  `nix-daemon` when there's no writable store, which breaks home-manager
  activation and any in-guest build. It also forces
  `nix.settings.auto-optimise-store = lib.mkForce false`.
- `register-store-closure.service` registers the shared store closure in the
  guest's Nix DB and is ordered **before** `home-manager-w4cbe.service`.
  microvm.nix's own registration runs unordered against home-manager, which
  is a race.
- **No local gpg-agent in the guest** (`services.gpg-agent.enable = lib.mkForce false`
  in `modules/home/agent-sandbox.nix`). The host's forwarded agent owns that
  socket path; a local agent would bind it first.
- `development.graphical.enable = false` — the guest is headless, so GUI
  packages are gated out.
- Autologin + `programs.fish.loginShellInit` exec the harness on the local
  console only, guarded on `$SSH_CONNECTION` so SSH sessions are unaffected.
- `users.users.w4cbe.uid` is pinned to `sandboxLib.guestUid` (1000):
  `RemoteForward` expands no tokens for the remote path, so the forwarded
  socket paths must be predictable at eval time.

## What crosses the boundary

The sandbox is isolated from the host's *system*, not hermetically sealed.
These channels are deliberate:

| Channel | Shape |
| --- | --- |
| `workspace` | virtiofs, **read-write**, mounted at the identical path in both. The guest edits the host's real files. |
| `/nix/store` | virtiofs read-only at `/nix/.ro-store`, with a writable overlay on top. |
| `kube` | read-only share of a sops-decrypted kubeconfig. Linux hosts only — the Mac has no kube share. |
| gpg-agent extra socket | forwarded to the guest's standard `S.gpg-agent` path. Signing works; card management is refused. |
| gpg-agent ssh socket | forwarded; the guest's `SSH_AUTH_SOCK` points at it, so `git push`/`pull` authenticate as the host's YubiKey. |
| network | slirp user-mode NAT. Outbound works; the only inbound path is host `127.0.0.1:2222` → guest `22`. Gateway `10.0.2.2` maps to the host's **loopback**. |

Two distinctions worth keeping straight:

- **A read-only mount is not a read-only credential.** The `kube` share is
  mounted read-only, but what bounds it is RBAC: the kubeconfig holds a
  `view`-scoped ServiceAccount token (`kube-system/agent-readonly` in the
  `k3s-gitops` repo), not the host's `system:admin` config.
- **Forwarded agent ≠ standing credential.** Both gpg sockets round-trip to
  the host's real agent, so every signature and every git push needs a PIN
  and a physical touch on the host. The guest holds no key material.

The sandbox's *own* SSH login key is separate: a dedicated sops-stored
keypair (`sandbox/sshKey`), so starting the VM needs no touch. It
authenticates host → guest only and is not usable for anything outbound.

## Working from inside the guest

- `hostname` is `sandbox`. You are uid 1000 and in `wheel`, but `sudo`
  requires a password nobody is there to type — treat the guest as
  unprivileged.
- **Memory (`memoryMB`, 8192 by default) is a real constraint.** A full
  `nix eval` of a large host config can still OOM, and the MCP servers
  running alongside eat into the same budget. Prefer `nix-instantiate
  --parse` for syntax, and run full `nix eval` on the host. If an eval dies
  with exit 137, that's the OOM killer, not your change — and don't pipe it
  through `tail`, which hides the exit code.
- `microvm.balloon = true` (qemu/NixOS only — vfkit throws on it) only lets
  the *host* reclaim memory the guest isn't using while idle. It does not
  raise what a single guest process can allocate; that ceiling is always
  `memoryMB`. If you see guest-side OOM kills, raise `memoryMB` — ballooning
  is orthogonal and won't help.
- The workspace is the host's real directory. Changes there are **not**
  sandboxed from the host's files.
- Anything needing the YubiKey blocks on a physical touch. Don't expect
  signing, `git push`, or `git pull` to work unattended.

## Verifying changes

```
nix eval .#nixosConfigurations.agent-sandbox.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath   # host side
```

The Mac runner builds as `.#packages.aarch64-darwin.agent-sandbox-vm`. Run
`nix fmt` before finishing, as everywhere else in this flake.
