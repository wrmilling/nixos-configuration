---
name: agent-sandbox
description: Use this skill when you change the agent-sandbox microVM in this flake. This includes the host modules, the guest configuration, shares, volumes, and agent/socket forwarding. Also use it when you work from inside the sandbox guest. The skill gives the file layout, the option and lib conventions, the channels that cross the host/guest boundary, and the limits of guest access.
---

# Agent sandbox

The agent sandbox is a microVM (microvm.nix). It runs a coding agent harness
against a shared workspace. The VM is isolated from the host that runs it.

The design is harness-agnostic. The guest enables `home.terminal.claude-code`
today, but no part of the design is specific to Claude. The name
`agent-sandbox` is general so that a different harness can use it. Do not put
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

Each wrapper sets `nixpkgs.hostPlatform` and imports the same `guest.nix`.

**Make all guest changes in `guest.nix`.** If you change a wrapper, the two
architectures become different.

`lib/agent-sandbox.nix` is a plain function. It takes `{ lib }` only. It is
not a module. Import it where you need it:

```nix
sandboxLib = import ../../../lib/agent-sandbox.nix { inherit lib; };
```

It holds `shareType`, `mkShares`, `mkVolumes`, `userInterface`,
`mkCommandScript`, `imageName`, the pinned `guestUid`, the forwarded socket
paths, and the sandbox SSH identity path. Put values that both host platforms
need in this file. This prevents differences between the qemu and vfkit
modules.

Two helpers take the platform difference as an argument:

- `mkVolumes { diskSizeMB, dir ? null }`. If `dir` is `null`, the image path
  stays relative. qemu needs this because `microvm@.service` sets
  `WorkingDirectory`. A user starts vfkit from any directory, so the Darwin
  host passes an absolute `dir` (its `stateDir`).
- `userInterface`. This is the user-mode NAT interface. It is the only network
  type that both hypervisors support. qemu adds `forwardPorts` to it. vfkit
  cannot, because microvm.nix asserts that `forwardPorts` needs qemu.

## Conventions

- **Add each new knob as an option on `modules.{nixos,darwin}.agentSandbox`.**
  Keep the defaults the same on both platforms: `vcpu = 4`,
  `memoryMB = 8192`, `diskSizeMB = 32768`. If you change one platform, change
  the other.
- **Put per-host shares in the host's own
  `configurations/nixos/<host>/default.nix`**, in `extraShares`. Do not put
  them in the component. `mkShares` always adds the workspace share. Use
  `extraShares` for all other shares.
- **Do not put a share inside a directory that home-manager owns.** systemd
  creates the missing parent directories of a mount point. It does this as
  root, before home-manager activates. A share at `~/.config/gcloud`
  therefore leaves `~/.config` owned by root. Activation then fails with
  `mkdir: cannot create directory '/home/w4cbe/.config/systemd': Permission
  denied`. The guest cannot repair this, because `sudo` in the guest needs a
  password that no user can type. Mount the share directly in the home
  directory, like the NixOS hosts' `~/.kube`, or outside the home directory.
  If you must nest a share, return the parent to the user:
  ```nix
  systemd.tmpfiles.rules = [ "d /home/w4cbe/.config 0755 w4cbe users - -" ];
  ```
  tmpfiles runs from `sysinit.target`. This is after the mounts and before
  home-manager. The Darwin gcloud share was removed. The guest authenticates
  to gcloud itself instead. This also removes one host credential from the
  boundary.
- **If a home-manager module and a host module share a bare path, write the
  path in both files.** Add a comment in each file that names the other. Do
  not import `sandboxLib` into a host configuration to share one string. This
  was tried and reverted. Use `lib/agent-sandbox.nix` for helpers, and for
  values that the two *host platforms* share. Do not use it for every
  constant.
- **Names.** The VM, the systemd unit, the disk image, and the launcher are
  all `agent-sandbox`. The guest `networking.hostName` is `sandbox`.
- **`diskSizeMB` applies only when the image is created.** The microvm volume
  script skips `mkfs` if the image exists. A change to this value does not
  resize a live image. Use `agent-sandbox reset` to delete the image first.
- **vfkit does not enforce `readOnly` on a share.** State this in any option
  documentation. Do not depend on it on the Darwin host.
- **virtiofs does not proxy `AF_UNIX`.** If you share a socket, the guest gets
  an inode that it cannot connect to. Any socket, such as the Docker socket,
  needs a TCP relay on both sides instead of a share. The two platforms use
  different mechanisms, because only the Darwin guest shares a subnet with its
  host:
  - **Darwin.** Bind the host end to the vmnet gateway
    (`hostDocker.listenAddress`, `192.168.64.1`). Do not bind a wildcard. Both
    ends read the same option. If the two addresses disagree, the guest cannot
    reach the host, so it gains nothing to resolve the address in the guest
    from the default route. It only adds a dependency.
  - **NixOS/qemu.** There is no shared subnet. The relay uses qemu `guestfwd`
    instead. These are `microvm.forwardPorts` entries with `from = "guest"`.
    The qemu process intercepts a guest connection to
    `hostDocker.guestAddress:port` and pipes it to `nc 127.0.0.1 port` on the
    host. No real network traffic occurs. The host relay therefore binds
    loopback only, and the guest never gets a route to it. `guestAddress` must
    be a VLAN address that SLIRP does not already use. SLIRP uses `.2` for the
    gateway, `.3` for DNS, and `.15` for the guest DHCP address.

  The guest half is the same on both platforms. It holds the CLI packages, the
  `docker` group, and the socket relay unit. It lives once in
  `lib/agent-sandbox.nix` as `mkHostDockerGuestModule { address; port; }`. The
  address comes from each platform's mechanism.
- **For a real daemon in the guest, use `guestDocker`, not `hostDocker`.**
  `guestDocker` sets `virtualisation.docker.enable = true` in the guest,
  shared as `sandboxLib.guestDockerModule`. It needs no relay, no shared
  subnet, and no guestfwd. Nothing crosses the boundary. The cost is a
  separate image and layer cache from the host cache. The two options are
  mutually exclusive, because both bind `/run/docker.sock` in the guest. Each
  platform module asserts against both options together.
- **A unit `script` gets a minimal PATH.** It holds `coreutils`, `findutils`,
  `gnugrep`, `gnused`, and `systemd`, and nothing else. See
  `nixos/lib/systemd-lib.nix`, `stage2ServiceConfig`. It has no `gawk`, so an
  `awk` command in a unit script exits 127. Prefer an `ExecStart` that names
  each binary by absolute store path with `lib.getExe`. Do not use a `script`
  with a `path` list. `ExecStart` cannot fail this way, and it creates no
  wrapper derivation.
- **Two knobs are Darwin-only.** `stateDir` holds the disk image and both
  sockets. vfkit has no systemd unit to anchor a relative path, so without
  `stateDir` the image is created in the working directory of the
  `agent-sandbox` command. `guestUid` is described in the guest section. The
  rule to keep defaults identical applies only to knobs that both platforms
  have. `hostDocker` and `guestDocker` exist on both platforms with the same
  shape and the same default, which is off. Only their host mechanics differ.
- **The Darwin host needs an aarch64-linux builder in its own module.** The
  guest is a Linux closure, so `darwin-rebuild` cannot build the runner alone.
  `modules/darwin/linuxBuilder` is independent of
  `modules.darwin.agentSandbox.enable`. When `nix.linux-builder` was inside
  the sandbox module `mkIf`, the only switch that could activate the builder
  already needed the builder. Three rules follow:
  - Put **only darwin-side knobs** in `nix.linux-builder.config`. Use
    `virtualisation.cores` and
    `virtualisation.darwin-builder.{memorySize,diskSize}`. These keep the
    builder closure substitutable, at 4 aarch64-darwin derivations. Any
    guest-side value rebuilds the aarch64-linux toplevel and restores the
    circular dependency. Examples are `nix.settings`, `min-free`, `max-free`,
    extra substituters, and packages.
  - Use `virtualisation.darwin-builder.{memorySize,diskSize}`. Do not use
    `virtualisation.{memorySize,diskSize}`. The second form conflicts with the
    definitions in the `nix-builder.nix` profile and needs `lib.mkForce`.
  - Set `ephemeral = true`. The builder qcow2 image grows on demand and never
    shrinks. Its internal auto-GC runs only below `min-free`, which is 1 GiB.
    The image therefore grows to `diskSize` and stays there. A wipe on each
    restart is the only limit that is not itself an aarch64-linux build. Nix
    copies outputs back to the Darwin store as each build finishes, so a wipe
    never forces a rebuild of a path that the host already has.
- **Keep the `runner` indirection.** The Darwin module exposes `runner` as a
  `readOnly` option. `flake.nix` re-exports it as
  `packages.aarch64-darwin.agent-sandbox-vm`. This indirection keeps the
  `flake.nix` entry to one line.
- **The `agent-sandbox` command has one shape and two backends.**
  `sandboxLib.mkCommandScript` owns the dispatch and the help text. The
  subcommands are `start`, `stop`, `status`, `reset`, and `help`. No argument
  means start and then enter. Each platform module supplies its own `start`,
  `stop`, `status`, `enter`, and `reset` shell snippets. Only the platform
  module knows the mechanics.
  - **NixOS/qemu.** Use `systemctl start`, `systemctl stop`, and
    `systemctl is-active` on `microvm@agent-sandbox.service`. `enter` polls
    SSH and then execs into it.
  - **Darwin/vfkit.** `enter` uses SSH, as qemu does. The session then ends
    when the harness exits, instead of getty restarting it. There is no port
    forwarding, because `forwardPorts` needs qemu. The Apple shared vmnet puts
    the host and the guest on one subnet, so the host reaches the guest
    directly at a DHCP address. `enter` reads that address from
    `/var/db/dhcpd_leases`. bootpd keys this file by the guest DHCP hostname,
    which is `networking.hostName`, read from the flake. The file survives a
    VM restart.

    The other subcommands use dtach, because there is no daemon. The
    `microvm-run` process is the VM, and its stdio is the console. `dtach -n
    <socket> ... microvm-run` puts it in the background. `dtach -a` reattaches
    to it. The presence of the socket is the running check, because dtach
    removes the socket when the child exits. This behaviour is verified, and
    dtach is portable, so a Mac is not needed to test it.
  - **`stop` does not use the generated `microvm-shutdown` script.** That
    script sends bare JSON to the vfkit socket. `microvm.socket` enables
    `--restful-uri`, which serves HTTP on that socket. vfkit therefore answers
    `400 Bad Request` and the VM continues to run. This is an upstream defect
    in the microvm.nix vfkit runner: correct JSON, wrong transport. Send the
    same body as a real `POST /vm/state` with curl over `--unix-socket`. Then
    wait until the dtach socket disappears, so that a stop and start pair
    cannot run two vfkit processes on one disk image. Keep `microvm.socket`
    set. It is what creates the REST API. Without it, `stop` can only kill the
    process. `GET /vm/state` and `GET /vm/inspect` on that socket are useful
    for debugging.
  - **dtach must not exec `microvm-run` directly.** dtach gives the child pty
    the termios of the invoking terminal without change. See `master.c`,
    `the_pty.term = orig_term`. `ISIG` therefore stays on, and that pty
    consumes Ctrl+C instead of the guest. This sends SIGINT to vfkit and stops
    the VM. The `consoleScript` wrapper runs `stty raw -echo` first. The byte
    then reaches hvc0, and the guest line discipline signals the process that
    the agent runs. The client half needs no change: `attach.c` clears `ISIG`
    locally, and dtach never rewrites the child pty after it creates it, so
    the single `stty` call persists. The loss of `-opost` is also correct,
    because the guest console already emits CRLF and the pty translated it a
    second time.

### Errors to avoid

- **`networking.firewall.extraInputRules` works only with the nftables
  backend.** The guest uses the iptables backend. The option is a valid string
  there, but nothing applies it. An SSH source restriction written this way
  had no effect, and port 22 stayed open to the whole subnet. Use
  `extraCommands` instead, and use `-I`:
  ```nix
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -p tcp --dport 22 ! -s 192.168.64.1 -j DROP
  '';
  ```
  `extraCommands` runs after the firewall appends its own
  `--dport 22 accept` rule. An `-A` rule is therefore after the accept rule
  and never matches. `-I` inserts the rule before it. Verify against the
  generated script, not the source:
  ```
  grep <addr> $(systemctl cat firewall.service \
    | grep -oE '/nix/store/[^ ]*firewall-start[^ ]*' | head -1)
  ```
- **`disable_ipv6` does not inherit.** `networking.enableIPv6 = false` sets the
  `all` and `default` sysctls. It leaves an interface that already exists at
  `0`, and that interface keeps its RA address and route. `guest.nix`
  therefore sets both that option and
  `boot.kernelParams = [ "ipv6.disable=1" ]`. The kernel parameter is the
  guarantee. Do not remove it.
- **Do not reuse the `stop` snippet inside `reset`.** The Darwin `stop` snippet
  runs `echo "not running"; exit 0` when the VM is stopped. In `reset` this
  exits before the delete step. The mechanics are in a `stopIfRunning` binding
  that has no early exit. `stop` adds the message.
- **To remove `hostDocker` you must also stop the running job.**
  `hostDocker.enable = false` plus a `darwin switch` removes the launchd
  definition. It does not stop the running `KeepAlive` job, and a stale plist
  remains. Neither `agent-sandbox stop` nor the switch stops that job. Until
  you run the commands below, the relay port stays bound and still reaches the
  host daemon.
  ```fish
  launchctl bootout gui/<uid>/org.nixos.agent-sandbox-docker-relay
  rm ~/Library/LaunchAgents/org.nixos.agent-sandbox-docker-relay.plist
  ```

### The CA bundle problem

`security.pki` behaves differently on the two platforms. The corporate bundle
is malformed, and only one platform detects this:

- **nix-darwin** concatenates `certificateFiles` into
  `/etc/ssl/certs/ca-certificates.crt`.
- **NixOS** rebuilds `nss-cacert` with `buildcatrust`. Its PEM delimiters are
  line-anchored: `^-----BEGIN ([^-]+)-----$`.

Corporate tooling generates `secrets/certs/cert.pem`. It appends certificates
without a separating newline. One line therefore reads
`-----END CERTIFICATE----------BEGIN CERTIFICATE-----`. A simple regular
expression scan accepts this file. buildcatrust reads the joined line as
base64 and fails the build.

`configurations/darwin/work` repairs the file with `builtins.replaceStrings`
on `----------BEGIN `. This is a no-op on a correct bundle. It passes the
result as `security.pki.certificates`. The sandbox module inherits that list
instead of reading the file again, so the repair exists in one place. Do not
change either side back to a raw `certificateFiles` path.

The same defect also degraded the host. `curl` rejects such a file with
`error setting certificate verify locations`, and openssl does not load it.
`NIX_SSL_CERT_FILE` points at that file, and `virtualisation.useHostCerts`
copies it into the linux-builder. The builder could then reach no substituter
and rebuilt every path from source. If builds are slow for no clear reason,
check that this command succeeds:

```
curl --cacert /etc/ssl/certs/ca-certificates.crt https://cache.nixos.org/nix-cache-info
```

## Guest design decisions

Each decision below has a reason. Keep it unless you intend to change it.

- **`microvm.writableStoreOverlay` is required.** microvm.nix masks
  `nix-daemon` when there is no writable store. This breaks home-manager
  activation and every build in the guest. It also forces
  `nix.settings.auto-optimise-store = lib.mkForce false`.
- **`register-store-closure.service` runs before
  `home-manager-w4cbe.service`.** It registers the shared store closure in the
  guest Nix database. The microvm.nix registration is not ordered against
  home-manager, which is a race condition.
- **The guest runs no local gpg-agent.**
  `modules/home/agent-sandbox.nix` sets
  `services.gpg-agent.enable = lib.mkForce false`. The forwarded host agent
  owns that socket path. A local agent would bind the path first.
- **`development.graphical.enable = false`.** The guest is headless, so this
  removes the GUI packages.
- **The harness runs on the local console only.** Autologin and
  `programs.fish.loginShellInit` exec the harness. A guard on
  `$SSH_CONNECTION` keeps SSH sessions unaffected.
- **`users.users.w4cbe.uid` is pinned to `sandboxLib.guestUid`, which is
  1000.** `RemoteForward` expands no tokens in the remote path, so the
  forwarded socket paths must be known at evaluation time. This value also
  matches the user on the NixOS hosts, which is why the workspace share works
  there without more configuration.
- **The Darwin host must renumber the uid.** vfkit passes the host uid and gid
  through virtiofs without mapping. The macOS account is `501:20`. A guest
  that runs as 1000 therefore gets a read-only workspace. The Darwin module
  applies `guestUid`, default 501, in its `extendModules` block. NixOS rejects
  a uid below 1000 for a normal user, so the same override sets
  `isSystemUser` and restates `group` and `createHome`. Lima and
  `podman machine` use the same method. Three consequences follow:
  - Files that the guest creates are owned by `501:100` on the host. The host
    user still owns them. A matching gid would need gid 20, which collides
    with the static `lp` group in NixOS.
  - Any code that derives a per-uid path must read
    `config.users.users.w4cbe.uid`, not `sandboxLib.guestUid`. This is why
    `guest.nix` builds `SSH_AUTH_SOCK` from the former.
  - `autoSubUidGidRange` defaults to true only through `isNormalUser`. The
    Darwin guest therefore has no subuid or subgid range, and
    `virtualisation.docker.rootless` cannot work there until you set the range
    explicitly. The NixOS guest already has a range.
- **Garbage collection is automatic and affects the guest only.** The guest
  `/nix/store` is an overlay. The guest cannot damage the read-only lower
  layer. On the NixOS hosts that layer is a virtiofs share of the host store.
  On the Darwin host it is an erofs image, built by `microvm.storeOnDisk`.
  That option enables itself because the Darwin host shares no `ro-store`; the
  macOS store holds darwin paths. In both cases, a delete of a lower-layer
  path only writes an overlayfs whiteout in the guest overlay. Guest GC
  therefore reclaims only the writable upper layer, `/nix/.rw-store`, which
  `agent-sandbox.img` backs. This holds guest-local builds and home-manager
  generations.

  The interactive `ncl` abbreviation in
  `modules/home/components/terminal.fish.nix` does not work in the guest. Its
  `sudo nix-collect-garbage -d` step waits for a password that no user can
  type. `guest.nix` therefore sets
  `nix.gc = { automatic = true; dates = "weekly"; options = "-d"; }`, which is
  a systemd timer and uses no sudo. `modules/home/agent-sandbox.nix` sets
  `services.home-manager.autoExpire.enable = true` at the same interval,
  because an unexpired generation is a GC root that the timer cannot remove.

## What crosses the boundary

The sandbox is isolated from the host *system*. It is not fully sealed. Read
that statement with these three corrections:

- **The writable `workspace` share is a channel for code execution on the
  host.** It is more than a file share. The host later executes or obeys
  `.claude/settings.json`, `.claude/skills/`, `CLAUDE.md`, and `.git/hooks/`
  from that share. `core.hooksPath` in
  `modules/home/components/terminal.git.nix` disables the git hooks, and the
  codegraph prompt hook is disabled on the host. The files still influence any
  agent that reads them. What keeps a guest edit out of the host system is
  that `nhs` and `dhs` build from `~/.nixos-configuration`, which is not
  shared. A guest change reaches the host only through commit, push, and pull,
  which means through review. Review is the control.
- **With `hostDocker.enable`, the guest is equivalent to the host.** It is not
  sandboxed. Use `guestDocker` instead.
- **The harness permission list is a usability guard, not a boundary.** Its
  `deny` rules do not stop a process inside the guest. Any other reader
  bypasses them, and `Bash(git show *)` is itself on the allow list. An agent
  can also grant itself more permissions in `settings.local.json`. Do not use
  this list to protect anything.

These channels are intentional:

| Channel | Shape |
| --- | --- |
| `workspace` | virtiofs, **read-write**, mounted at the same path on both sides. The guest edits the real host files. |
| `/nix/store` | **NixOS hosts:** virtiofs, read-only, at `/nix/.ro-store`, with a writable overlay above it. **Darwin:** no store share. `microvm.storeOnDisk` builds an erofs image of the guest closure, with the same overlay above it. |
| `kube` | Read-only share of a kubeconfig that sops decrypted. NixOS hosts only. The Darwin host has no kube share. |
| gpg-agent extra socket | Forwarded to the standard `S.gpg-agent` path in the guest. Signing works. Card management is refused. |
| gpg-agent ssh socket | Forwarded. The guest `SSH_AUTH_SOCK` points at it, so `git push` and `git pull` authenticate as the host YubiKey. |
| network | User-mode NAT through `sandboxLib.userInterface`. Outbound traffic works on both platforms. **NixOS hosts:** slirp, with one inbound path from host `127.0.0.1:2222` to guest `22`. Gateway `10.0.2.2` maps to the host **loopback**. **Darwin:** vmnet NAT, with no port forwarding. The host and the guest share the `192.168.64.0/24` subnet and reach each other directly. The host is `.1`, on `bridge100`. |
| corporate CA | Darwin only. The guest inherits the host `security.pki.certificates`, plus `NODE_EXTRA_CA_CERTS` and `REQUESTS_CA_BUNDLE`. Guest traffic NATs through the host stack and meets the same TLS interception. The NixOS sandbox is unchanged. See the CA bundle problem above. |
| host Docker | Opt-in through `hostDocker.enable`. Off by default on both platforms. It is a TCP relay in two hops: a user-level relay on the host, from the real docker socket to a TCP endpoint, and a guest unit that returns it to `/run/docker.sock`. The guest gets `docker-client` and compose, but no daemon. **This is the widest channel here.** The Docker API is equivalent to root on the machine that runs the daemon. On the Darwin host, the Rancher VM also mounts the macOS home directory, so this channel defeats workspace-only sharing. |
| guest Docker | Opt-in through `guestDocker.enable`. Off by default on both platforms. Mutually exclusive with `hostDocker`, because both bind `/run/docker.sock` in the guest. It sets `virtualisation.docker.enable = true` in the guest. There is no relay, and nothing crosses the boundary. The cost is a separate image and layer cache. |

Keep these four distinctions clear:

- **A read-only mount is not a read-only credential.** The `kube` share is
  mounted read-only, but RBAC is what limits it. The kubeconfig holds a
  ServiceAccount token scoped to `view`, which is
  `kube-system/agent-readonly` in the `k3s-gitops` repo. It is not the host
  `system:admin` configuration.
- **The `path` of a sops-nix secret is always a symlink.** It points into a
  per-generation `$XDG_RUNTIME_DIR/secrets.d/<n>` directory. A custom `path`
  adds another symlink; it never becomes a real file. virtiofs shares a
  symlink as a symlink, so a share whose source is an unresolved sops path
  appears in the guest as a broken link to a host-only runtime directory.
  This is why the source of the `kube` share is not the sops path. A
  `home.activation` step in `modules/home/personal.nix`, ordered
  `entryAfter [ "sops-nix" ]`, resolves the link and installs the real bytes
  at the fixed shared path. Any new secret that you share into the guest needs
  the same copy step. Do not use a raw `sops.secrets.<name>.path`.
- **A forwarded agent is not a standing credential.** Both gpg sockets return
  to the real host agent, and the guest holds no key material. Two limits
  apply. First, the gpg cache TTLs in `terminal.gpg.nix` let a recently used
  agent sign again without a new touch, unless the key enforces a touch for
  each operation. Second, a touch proves **presence, not intent**. The token
  cannot separate the signature that you requested from an SSH
  authentication that a guest agent started a moment earlier. The socket is
  limited to neither git nor one remote: it authenticates to any host that
  trusts the key. `Bash(git push *)` is therefore absent from the harness
  allow list, so that the prompt supplies the intent that the touch cannot.
- **Both platforms forward the sockets, from different directories.** The
  sockets arrive over `RemoteForward` on the host-to-guest SSH connection. The
  NixOS hosts forward from `$XDG_RUNTIME_DIR/gnupg`. macOS keeps its agent
  sockets in `~/.gnupg`, so the Darwin module forwards from there. The remote
  paths come from `sandboxLib.gpgAgentSocket <uid>` and
  `sandboxLib.sshAgentSocket <uid>`. These are functions, not constants,
  because the Darwin guest uses a different uid.

The SSH login key of the sandbox is separate. It is a dedicated keypair stored
in sops as `sandbox/sshKey`, so a VM start needs no touch. It authenticates
from the host to the guest only. It is not usable for any outbound connection.

## Working from inside the guest

- The hostname is `sandbox`. You are uid 1000 on a NixOS host and uid 501 on
  the Darwin host. See the uid note above. You are in `wheel`, but `sudo`
  needs a password that no user can type.
- **You are not unprivileged.** `sudo` is an inconvenience, not a boundary.
  `guest.nix` pins `nix.settings.trusted-users` to `root` because a trusted
  nix user can set `build-users-group=""` and `sandbox = false`, and then the
  root daemon runs a builder as root. Check with
  `nix store ping --store daemon --json`. It must report `"trusted":false`.
  With `guestDocker` enabled, the `docker` group is still equivalent to root
  inside the VM, through `docker run --privileged -v /:/mnt`. This is
  accepted, because it does not cross the hypervisor boundary. **Design
  consequence: hardening inside the guest is advisory. Put any control that
  must hold on the host.**
- **You normally arrive over SSH on both platforms.** The forwarded gpg and
  ssh agents are then present, and `$SSH_CONNECTION` is set. That variable is
  what stops `guest.nix` from exec'ing the harness over your shell. If you
  arrive on the vfkit console instead, a user attached with dtach to debug.
  There are then no forwarded agents, and the harness is the login shell.
- **Memory is a real limit.** The default `memoryMB` is 8192. A full
  `nix eval` of a large host configuration can still exhaust it, and the MCP
  servers use the same memory. Use `nix-instantiate --parse` to check syntax,
  and run a full `nix eval` on the host. Exit code 137 means the OOM killer
  stopped the process; it does not mean your change is wrong. Do not pipe the
  command through `tail`, because that hides the exit code.
- **`nix` prints a warning about `trusted-public-keys` on every call here.**
  This is `trusted-users = root` working as intended. See the privilege note
  above. The substituters are set for the whole system, so nothing is broken.
  Ignore the warning.
- **`microvm.balloon = true` works on qemu and NixOS only.** vfkit rejects it.
  It lets the host reclaim memory that the guest does not use while idle. It
  does not raise the limit for a single guest process. That limit is always
  `memoryMB`. If the guest reports OOM kills, raise `memoryMB`. Ballooning
  does not help.
- **The workspace is the real host directory.** Changes there are not
  isolated from the host files.
- **Any operation that uses the YubiKey waits for a physical touch.** Do not
  expect signing, `git push`, or `git pull` to work unattended.

## Verifying changes

```
nix eval .#nixosConfigurations.agent-sandbox.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.agent-sandbox-aarch64.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath   # host side
nix eval .#darwinConfigurations.<mac>.config.system.build.toplevel.drvPath   # Darwin host side
```

A change to `lib/agent-sandbox.nix` or `guest.nix` affects **both** platforms.
Evaluate the NixOS side and the Darwin side, not only the one you changed. A
new required argument to `mkCommandScript` breaks the platform that does not
pass it, and the Darwin evaluation also builds the guest runner.

The Darwin runner builds as `.#packages.aarch64-darwin.agent-sandbox-vm`. It
needs a live aarch64-linux builder. On a Mac that never had one, `nix build`
fails with `Required system: 'aarch64-linux'`. This message is not about your
change. First activation on such a Mac needs two phases:

1. Switch once with `modules.darwin.agentSandbox.enable = false`. This brings
   up `modules.darwin.linuxBuilder` alone, which is verified as darwin-only,
   at 12 derivations.
2. Enable the sandbox again and switch a second time.

Every later switch is one command.

Run `nix fmt .` before you finish, as in the rest of this flake. A bare
`nix fmt` reads stdin and fails on empty input.
