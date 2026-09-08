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
modules/darwin/linux-builder.nix               aarch64-linux build capability
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

It holds `shareType`, `mkShares`, `mkVolumes`, `userInterface`, the pinned
`guestUid`, the forwarded socket paths, and the sandbox SSH identity path.
Anything both host platforms need lives here so qemu and vfkit can't diverge.

Two of those take platform differences as arguments rather than forking:

- `mkVolumes { diskSizeMB, dir ? null }` — `dir = null` leaves the image path
  relative, which is what qemu wants because `microvm@.service` sets
  `WorkingDirectory`. vfkit is started by hand from an arbitrary cwd, so the
  Darwin host passes an absolute `dir` (its `stateDir`).
- `userInterface` — the user-mode NAT interface, the only networking both
  hypervisors implement. qemu layers `forwardPorts` on top of it; vfkit
  cannot (microvm.nix asserts `forwardPorts` needs qemu).

## Conventions

- **New knob → an option on `modules.{nixos,darwin}.agentSandbox`**, with
  defaults kept identical across the two platforms (`vcpu = 4`,
  `memoryMB = 8192`, `diskSizeMB = 32768`). If you change one, change both.
- **Per-host shares go in the host's own `configurations/nixos/<host>/default.nix`**
  via `extraShares`, not in the component. The workspace share is always
  present via `mkShares`; `extraShares` is for everything else.
- **Don't nest a share inside a directory home-manager owns.** systemd creates
  a mount point's missing parents itself, as root, before home-manager
  activates. A share at `~/.config/gcloud` therefore leaves `~/.config`
  root-owned and activation dies with `mkdir: cannot create directory
  '/home/w4cbe/.config/systemd': Permission denied` -- and the guest cannot
  repair it, because `sudo` there wants a password nobody can type. Mount
  directly in the home dir (the Linux hosts' `~/.kube`) or somewhere outside
  it. If a nested share is ever genuinely needed, hand the parents back with
  `systemd.tmpfiles.rules = [ "d /home/w4cbe/.config 0755 w4cbe users - -" ]`
  -- tmpfiles runs from sysinit.target, after the mounts and before
  home-manager. The Mac's gcloud share was removed in favour of authenticating
  inside the guest, which is also one less host credential crossing the
  boundary.
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
- **virtiofs does not proxy `AF_UNIX`.** Sharing a socket gets the guest an
  inode it cannot connect to, so anything socket-shaped (the Docker socket,
  say) needs a TCP relay on both sides, not a share. Bind the host end to the
  vmnet gateway (`hostDocker.listenAddress`, `192.168.64.1`) rather than a
  wildcard, and have both ends read that same option -- an address that
  disagreed with the host's bind would be unreachable however the guest
  arrived at it, so resolving it guest-side from the default route buys
  nothing and only adds dependencies.
- **A unit's `script` gets a deliberately minimal PATH**: `coreutils`,
  `findutils`, `gnugrep`, `gnused`, `systemd`, and nothing else
  (`nixos/lib/systemd-lib.nix`, `stage2ServiceConfig`). No `gawk` -- an `awk`
  in a unit script exits 127. Prefer an `ExecStart` naming binaries by
  absolute store path (`lib.getExe`) over a `script` plus a `path` list; it
  cannot fail that way, and it generates no wrapper derivation.
- Some knobs have no counterpart on the other platform and are deliberately
  Darwin-only: `hostDocker`, `stateDir` (where the disk image and both sockets live — vfkit
  has no systemd unit to anchor relative paths, so without it the image lands
  in whatever cwd `agent-sandbox` was run from) and `guestUid` (see the guest
  section). The "keep defaults identical" rule applies to knobs both platforms
  actually have.
- **The Mac needs an aarch64-linux builder, and it lives in its own module.**
  The guest is a Linux closure, so `darwin-rebuild` cannot build the runner
  unaided. `modules/darwin/linuxBuilder` is deliberately independent of
  `modules.darwin.agentSandbox.enable`: when `nix.linux-builder` lived inside
  the sandbox module's `mkIf`, the only switch that could activate the builder
  was one that already needed it. Two rules follow:
  - Put **only darwin-side knobs** in `nix.linux-builder.config` —
    `virtualisation.cores` and `virtualisation.darwin-builder.{memorySize,diskSize}`
    keep the builder's own closure substitutable (4 aarch64-darwin
    derivations). Anything guest-side (`nix.settings`, `min-free`/`max-free`,
    extra substituters, packages) rebuilds the aarch64-linux toplevel and
    recreates the exact circularity the split removed.
  - Use `virtualisation.darwin-builder.{memorySize,diskSize}`, not
    `virtualisation.{memorySize,diskSize}` — the latter conflict with the
    `nix-builder.nix` profile's own definitions and need `lib.mkForce`.
  - `ephemeral = true` because the builder's qcow2 grows on demand and never
    shrinks, while its in-guest auto-GC only fires below `min-free` (1 GiB) —
    so left alone it creeps to `diskSize` and stays there. Wiping the image
    per restart is the only bound that isn't itself an aarch64-linux build.
    Outputs are copied back to the Mac's store as builds finish, so a wipe
    never forces a rebuild of something the Mac already has.
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
  - **Darwin/vfkit**: `enter` is SSH, same as qemu — so the session ends when
    the harness exits instead of getty respawning it. There is no port
    forwarding (`forwardPorts` is qemu-only), but Apple's shared vmnet puts
    host and guest on one subnet, so the guest is reachable directly at a
    DHCP-assigned address. `enter` finds it in `/var/db/dhcpd_leases`, which
    bootpd keys by the guest's own DHCP hostname (`networking.hostName`,
    read off the flake rather than hardcoded) and which outlives VM restarts.
    Everything else is still dtach, because there is no daemon —
    `microvm-run` *is* the VM, its stdio *is* the console. `dtach` stands in
    for both: `dtach -n <socket> ... microvm-run` backgrounds it, `dtach -a`
    reattaches, and the socket's mere existence *is* the running/stopped
    check (dtach removes it when the child exits — verified empirically,
    dtach is portable and this doesn't need a Mac to test).
  - **`stop` deliberately does not use the generated `microvm-shutdown`.**
    That script pipes bare JSON at the vfkit socket, but `microvm.socket`
    enables `--restful-uri`, which serves *HTTP* there — so vfkit answers
    `400 Bad Request` and the VM keeps running. This is an upstream bug in
    microvm.nix's vfkit runner: right JSON, wrong transport. We send the same
    body as a real `POST /vm/state` with curl over `--unix-socket`, then wait
    for the dtach socket to disappear so a stop/start pair cannot race two
    vfkit processes onto one disk image. Keep `microvm.socket` set regardless —
    it is what makes the REST API exist at all, and without it `stop` could
    only be a kill. (`GET /vm/state` and `/vm/inspect` on that socket are handy
    for debugging.)
  - **dtach does not exec `microvm-run` directly, and must not.** It hands the
    child pty the invoking terminal's termios verbatim (`master.c`:
    `the_pty.term = orig_term`), so `ISIG` stays on and that pty — not the
    guest — eats Ctrl+C, delivering SIGINT to vfkit and killing the VM. The
    `consoleScript` wrapper runs `stty raw -echo` first so the byte reaches
    hvc0 and the guest's own line discipline signals whatever the agent is
    running. The client half needs nothing: `attach.c` already clears `ISIG`
    locally, and dtach never rewrites the child pty after creation, so the
    one-time `stty` sticks. `-opost` going off is correct too — the guest's
    console already emits CRLF, so the pty was double-translating.

### The CA-bundle trap

`security.pki` behaves differently on the two platforms, and the corporate
bundle is malformed in a way that only one of them notices:

- **nix-darwin** just `cat`s `certificateFiles` together into
  `/etc/ssl/certs/ca-certificates.crt`.
- **NixOS** rebuilds `nss-cacert` with `buildcatrust`, whose PEM delimiters are
  line-anchored (`^-----BEGIN ([^-]+)-----$`).

`secrets/certs/cert.pem` is generated by corporate tooling that appends certs
without a separating newline, leaving one
`-----END CERTIFICATE----------BEGIN CERTIFICATE-----` on a single line. So a
naive regex scan sees a tidy bundle while buildcatrust reads the glued line as
base64 and fails the build outright.

`configurations/darwin/work` repairs it with a `builtins.replaceStrings` on
`----------BEGIN ` (a no-op on a well-formed bundle) and passes it as
`security.pki.certificates`; the sandbox module inherits that list rather than
re-reading the file, so the repair has one home. Don't switch either side back
to a raw `certificateFiles` path.

The same break also silently degraded the *host*: `curl` refuses such a file
(`error setting certificate verify locations`) and openssl won't load it, and
since `NIX_SSL_CERT_FILE` points there and `virtualisation.useHostCerts` copies
it into the linux-builder, the builder could reach no substituter at all and
rebuilt everything from source. If builds are inexplicably slow, check that
`curl --cacert /etc/ssl/certs/ca-certificates.crt https://cache.nixos.org/nix-cache-info`
succeeds.

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
  socket paths must be predictable at eval time. It also happens to match the
  Linux hosts' own user, which is why the workspace share just works there.
- **On Darwin the uid is renumbered, and it has to be.** vfkit passes host
  uid/gid through virtiofs unmapped, and the Mac account is `501:20`, so a
  guest running as 1000 gets a read-only workspace. The Darwin module's
  `guestUid` (default 501) is applied in its `extendModules` block. NixOS
  refuses a uid below 1000 on a normal user, so that override also flips the
  user to `isSystemUser` and restates `group`/`createHome`. Lima and
  `podman machine` solve this the same way. Consequence: files the guest
  creates land as `501:100` on the host — the host user still owns them, and
  a matching gid would need gid 20, which collides with NixOS's static `lp`.
  Anything deriving a per-uid path must read
  `config.users.users.w4cbe.uid`, not `sandboxLib.guestUid` (that is why
  `guest.nix` builds `SSH_AUTH_SOCK` from the former).
- **Garbage collection is automatic and guest-only.** The guest's `/nix/store`
  is an overlay whose read-only lower layer the guest cannot damage: on Linux
  hosts it's a virtiofs share of the host's real store, on Darwin it's an
  erofs store image (`microvm.storeOnDisk`, which turns itself on because the
  Darwin host deliberately shares no `ro-store` — the Mac's store holds darwin
  paths). Either way, deleting a lower-layer path just writes an overlayfs
  whiteout in the guest's own overlay. GC in the guest only ever reclaims the writable upper layer
  (`/nix/.rw-store`, backed by `agent-sandbox.img`): guest-local builds and
  home-manager generations. The interactive `ncl` abbreviation
  (`modules/home/components/terminal.fish.nix`) doesn't work here — its
  `sudo nix-collect-garbage -d` step stalls on the password nobody's there to
  type — so `guest.nix` sets `nix.gc = { automatic = true; dates = "weekly";
  options = "-d"; }` (a systemd timer, no sudo involved) and
  `modules/home/agent-sandbox.nix` sets
  `services.home-manager.autoExpire.enable = true` on the same cadence, since
  an unexpired generation is itself a GC root the timer can't touch.

## What crosses the boundary

The sandbox is isolated from the host's *system*, not hermetically sealed.
These channels are deliberate:

| Channel | Shape |
| --- | --- |
| `workspace` | virtiofs, **read-write**, mounted at the identical path in both. The guest edits the host's real files. |
| `/nix/store` | **Linux hosts:** virtiofs read-only at `/nix/.ro-store`, with a writable overlay on top. **Darwin:** no store share; `microvm.storeOnDisk` builds an erofs image of the guest closure instead, same overlay on top. |
| `kube` | read-only share of a sops-decrypted kubeconfig. Linux hosts only — the Mac has no kube share. |
| gpg-agent extra socket | forwarded to the guest's standard `S.gpg-agent` path. Signing works; card management is refused. |
| gpg-agent ssh socket | forwarded; the guest's `SSH_AUTH_SOCK` points at it, so `git push`/`pull` authenticate as the host's YubiKey. |
| network | User-mode NAT via `sandboxLib.userInterface`. Outbound works on both. **Linux hosts:** slirp, with one inbound path (host `127.0.0.1:2222` → guest `22`) and gateway `10.0.2.2` mapping to the host's **loopback**. **Darwin:** vmnet NAT — no port forwarding, but host and guest share the `192.168.64.0/24` subnet, so each reaches the other directly (host is `.1`, on `bridge100`). |
| corporate CA | Darwin only: the guest inherits the host's `security.pki.certificates` plus `NODE_EXTRA_CA_CERTS`/`REQUESTS_CA_BUNDLE`, because guest traffic NATs out through the host's stack and meets the same TLS interception the Mac does. The Linux sandbox is left alone. See the CA-bundle trap below. |
| host Docker | Darwin only, opt-in via `hostDocker.enable`. TCP relay in two hops: a launchd agent on the host (`socat` from the Rancher Desktop socket to the vmnet gateway) and a guest unit relaying it back to `/run/docker.sock`. The guest gets `docker-client` (CLI, no daemon) and compose. **This is the widest channel here** — the Docker API is root-equivalent on whatever runs the daemon, and Rancher's VM mounts the macOS home directory, so it defeats workspace-only sharing. |

Two distinctions worth keeping straight:

- **A read-only mount is not a read-only credential.** The `kube` share is
  mounted read-only, but what bounds it is RBAC: the kubeconfig holds a
  `view`-scoped ServiceAccount token (`kube-system/agent-readonly` in the
  `k3s-gitops` repo), not the host's `system:admin` config.
- **A sops-nix secret's `path` is always a symlink** into a per-generation
  `$XDG_RUNTIME_DIR/secrets.d/<n>` directory — setting a custom `path` just
  adds another symlink hop, it never becomes a real file. virtiofs shares a
  symlink as a symlink, so a share source that's an unresolved sops path is a
  dangling link in the guest pointing at a host-only runtime directory. This
  is why the `kube` share's source isn't the sops secret's own path: a
  `home.activation` step in `modules/home/personal.nix` (ordered
  `entryAfter [ "sops-nix" ]`) dereferences it and `install`s the real bytes
  at the fixed shared path instead. Any future secret shared into the guest
  needs the same copy step, not a raw `sops.secrets.<name>.path`.
- **Forwarded agent ≠ standing credential.** Both gpg sockets round-trip to
  the host's real agent, so every signature and every git push needs a PIN
  and a physical touch on the host. The guest holds no key material.
- **Both platforms forward the sockets, from different places.** They arrive
  over `RemoteForward` on the host → guest SSH connection. The Linux hosts
  forward from `$XDG_RUNTIME_DIR/gnupg`; macOS keeps its agent sockets in
  `~/.gnupg`, so the Darwin module forwards from there. The remote paths come
  from `sandboxLib.{gpgAgentSocket,sshAgentSocket} <uid>` — functions, not
  constants, because the Darwin guest runs at a different uid.

The sandbox's *own* SSH login key is separate: a dedicated sops-stored
keypair (`sandbox/sshKey`), so starting the VM needs no touch. It
authenticates host → guest only and is not usable for anything outbound.

## Working from inside the guest

- `hostname` is `sandbox`. You are uid 1000 on a Linux host and uid 501 on a
  Mac (see the uid note above), and in `wheel` — but `sudo` requires a
  password nobody is there to type, so treat the guest as unprivileged.
- **You normally arrive over SSH on both platforms**, so the forwarded
  gpg/ssh agents are there and `$SSH_CONNECTION` is set (which is what stops
  `guest.nix` re-exec'ing the harness over the top of your shell). Arriving on
  the vfkit console instead means someone attached with dtach for debugging:
  no forwarded agents, and the harness is the login shell.
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
nix eval .#nixosConfigurations.agent-sandbox-aarch64.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath   # host side
nix eval .#darwinConfigurations.<mac>.config.system.build.toplevel.drvPath   # Mac host side
```

Touching `lib/agent-sandbox.nix` or `guest.nix` changes **both** platforms —
eval the NixOS and Darwin sides, not just the one you were aiming at.

The Mac runner builds as `.#packages.aarch64-darwin.agent-sandbox-vm`. It needs
a live aarch64-linux builder, so on a Mac that has never had one, `nix build`
fails with `Required system: 'aarch64-linux'` rather than anything about your
change. First activation on such a Mac is two-phase: switch once with
`modules.darwin.agentSandbox.enable = false` (which brings up
`modules.darwin.linuxBuilder` on its own — verified darwin-only, 12
derivations), then re-enable and switch again. Every switch after that is one
command.

Run `nix fmt .` before finishing, as everywhere else in this flake — bare
`nix fmt` reads stdin and errors on empty input.
