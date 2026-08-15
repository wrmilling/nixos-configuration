#!/usr/bin/env bash
set -euo pipefail

data_root="${XDG_DATA_HOME:-$HOME/.local/share}/fusion360"
prefix="$data_root/wineprefix"
downloads="$data_root/downloads"
installer="$downloads/Fusion Admin Install.exe"
installer_url="https://dl.appstreaming.autodesk.com/production/installers/Fusion%20Admin%20Install.exe"
webview2_installer="$downloads/MicrosoftEdgeWebview2Setup.exe"
# The small Evergreen Bootstrapper (~2MB); linkid=2124701 resolves to the much
# larger (~200MB) Standalone installer instead, which fails under Wine.
webview2_url="https://go.microsoft.com/fwlink/p/?LinkId=2124703"

export WINEARCH=win64
export WINEPREFIX="$prefix"

mkdir -p "$prefix" "$downloads"

reg_override() {
  wine reg add 'HKEY_CURRENT_USER\Software\Wine\DllOverrides' /v "$1" /d "$2" /f >/dev/null
}

# Picks DXVK (Direct3D-to-Vulkan) or OpenGL, mirroring upstream's check_gpu_driver:
# Secure Boot + NVIDIA (or a GTX 970, which predates DXVK's minimum driver
# requirements) forces OpenGL; NVIDIA or AMD otherwise get DXVK; Intel-only
# and undetected GPUs fall back to OpenGL. A hybrid NVIDIA+Intel/AMD laptop
# is asked, defaulting to DXVK.
select_gpu_driver() {
  local secure_boot=0
  if command -v mokutil >/dev/null 2>&1 &&
    mokutil --sb-state 2>/dev/null | grep -qE 'SecureBoot enabled|Secure Boot enabled'; then
    secure_boot=1
  fi

  local gpu_vendor=""
  if command -v lspci >/dev/null 2>&1; then
    gpu_vendor="$(lspci | grep -E 'VGA|3D|Display' | grep -oE 'NVIDIA|AMD|Intel' | head -n1)"
  fi

  local nvidia_present=0 amd_present=0 intel_present=0
  case "$gpu_vendor" in
    NVIDIA) nvidia_present=1 ;;
    AMD) amd_present=1 ;;
    Intel) intel_present=1 ;;
  esac

  if
    ((!secure_boot)) && command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1
  then
    nvidia_present=1
  fi

  if ((!nvidia_present)) && command -v glxinfo >/dev/null 2>&1; then
    case "$(glxinfo 2>/dev/null | grep 'OpenGL vendor string' | cut -d: -f2)" in
      *AMD* | *ATI*) amd_present=1 ;;
      *Intel*) intel_present=1 ;;
    esac
  fi

  local older_nvidia=0
  if command -v lspci >/dev/null 2>&1 && lspci | grep -q "GTX 970"; then
    older_nvidia=1
  fi

  if ((secure_boot && nvidia_present)) || ((older_nvidia)); then
    echo "==> Secure Boot + NVIDIA (or an older NVIDIA GPU) detected; using OpenGL." >&2
    gpu_driver=OpenGL
  elif ((nvidia_present && (intel_present || amd_present))); then
    echo "==> Multiple GPUs detected. Select which to use for Fusion 360:" >&2
    echo "      1) NVIDIA (DXVK)" >&2
    echo "      2) Intel/AMD (OpenGL)" >&2
    read -r -p "    Enter your choice [1]: " gpu_choice || gpu_choice=""
    case "$gpu_choice" in
      2) gpu_driver=OpenGL ;;
      *) gpu_driver=DXVK ;;
    esac
  elif ((nvidia_present || amd_present)); then
    gpu_driver=DXVK
  elif ((intel_present)); then
    gpu_driver=OpenGL
  else
    echo "==> Could not detect a GPU; defaulting to OpenGL." >&2
    gpu_driver=OpenGL
  fi

  echo "==> Selected GPU driver: $gpu_driver" >&2
}

gpu_driver=DXVK
select_gpu_driver

# Each step below is independently idempotent and checks its own completion,
# rather than being gated on one all-or-nothing "first run" flag -- a step
# that fails partway (network hiccup, a flaky installer under Wine, ...)
# must not permanently skip everything after it on the next launch.

if [ ! -f "$prefix/system.reg" ]; then
  echo "==> Setting up the Fusion 360 Wine prefix (first run only)..." >&2
  wineboot --init
  wineserver --wait
fi

if ! grep -qx sandbox "$prefix/winetricks.log" 2>/dev/null; then
  # The sandbox verb strips the prefix's Z: drive and home-directory symlinks
  # (Desktop, Downloads, ...) for isolation, so re-link Downloads afterward --
  # installers we run expect it to resolve to a real, writable location.
  winetricks -q sandbox
  win_downloads="$prefix/drive_c/users/$USER/Downloads"
  rm -rf "$win_downloads"
  ln -s "$downloads" "$win_downloads"
fi

if ! grep -qx win11 "$prefix/winetricks.log" 2>/dev/null; then
  echo "==> Installing Windows compatibility components via winetricks..." >&2
  winetricks -q atmlib gdiplus corefonts cjkfonts dotnet20 dotnet48 \
    msxml4 msxml6 vcrun2022 fontsmooth=rgb winhttp win10 win11
  # cjkfonts and win10/win11 are sometimes reset by the verbs above; reapply.
  winetricks -q cjkfonts
  winetricks -q win11
fi

echo "==> Applying Fusion-specific Wine registry tweaks..." >&2
# Disable Autodesk's telemetry client ("calling home").
reg_override adpclientservice.exe native
# The nav bar renders incorrectly with anything but Wine's builtin browser.
reg_override AdCefWebBrowser.exe builtin
# Prefer the VC++ redist DLLs Fusion bundles with itself over Wine's own.
reg_override msvcp140 native
reg_override mfc140u native
# Without this override, sign-in fails.
reg_override bcp47langs ""
wine reg add 'HKEY_CURRENT_USER\Software\Wine\X11 Driver' /v Managed /d Y /f >/dev/null
wine reg add 'HKEY_CURRENT_USER\Software\Wine\X11 Driver' /v Decorated /d Y /f >/dev/null
# Prefer IPv4 over IPv6 (Microsoft's documented DisabledComponents=0x20,
# https://learn.microsoft.com/troubleshoot/windows-server/networking/configure-ipv6-in-windows).
# Autodesk's cloud endpoints are dual-stack; on a host with no real IPv6
# route, trying every AAAA record before falling back to IPv4 can stall
# sign-in/data-sync for minutes. This doesn't disable IPv6, just deprioritizes it.
wine reg add 'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' \
  /v DisabledComponents /t REG_DWORD /d 0x20 /f >/dev/null

webview2_marker="$data_root/.webview2-installed"
if [ ! -f "$webview2_marker" ]; then
  echo "==> Installing the Microsoft Edge WebView2 runtime (used by Fusion's sign-in UI)..." >&2
  if [ ! -f "$webview2_installer" ]; then
    curl --fail --location --progress-bar --output "$webview2_installer" "$webview2_url"
  fi
  wine "$webview2_installer" /silent /install || true

  # Wine bug 53925: the edgeupdate service is left running and keeps the
  # prefix alive indefinitely. Set it to manual startup and kill the
  # installer-spawned instance, matching winetricks' own webview2 verb.
  wine reg add 'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\edgeupdate' \
    /v Start /t REG_DWORD /d 3 /f >/dev/null
  pkill -KILL -f 'MicrosoftEdgeUpdate.exe /c' 2>/dev/null || true
  # Wine bug 58921: msedgewebview2.exe needs Windows 7 compatibility mode.
  wine reg add 'HKEY_CURRENT_USER\Software\Wine\AppDefaults\msedgewebview2.exe' \
    /v Version /d win7 /f >/dev/null

  if find "$prefix" -ipath '*/Microsoft/EdgeUpdate/MicrosoftEdgeUpdate.exe' -print -quit 2>/dev/null | grep -q .; then
    touch "$webview2_marker"
  else
    echo "warning: WebView2 install failed -- Fusion's sign-in UI may not render" >&2
    echo "         correctly. Will retry on the next launch." >&2
  fi
fi

if [ "$gpu_driver" = DXVK ]; then
  echo "==> Installing DXVK (Direct3D-to-Vulkan translation)..." >&2
  install -d "$prefix/drive_c/windows/system32" "$prefix/drive_c/windows/syswow64"
  for dll in d3d10core d3d11 dxgi; do
    cp -f "$FUSION360_DXVK_X64/$dll.dll" "$prefix/drive_c/windows/system32/"
    cp -f "$FUSION360_DXVK_X32/$dll.dll" "$prefix/drive_c/windows/syswow64/"
    # The leading "*" makes the override apply no matter how the DLL is
    # loaded (bare name, relative, or absolute path) -- winetricks' own
    # DXVK helper and upstream's DXVK.reg both rely on it; without it,
    # Fusion can load the real system DLL instead of DXVK's.
    reg_override "*$dll" native
  done
  # Fusion doesn't use d3d9, but upstream pins it to Wine's builtin explicitly.
  reg_override '*d3d9' builtin
fi
wineserver --wait

find_launcher() {
  find "$prefix" -iname Fusion360.exe -printf '%T@ %p\n' 2>/dev/null |
    sort -rn | head -n1 | cut -d' ' -f2-
}

launcher_exe="$(find_launcher)"

if [ -z "$launcher_exe" ]; then
  if [ ! -f "$installer" ]; then
    echo "==> Downloading the official Autodesk Fusion installer..." >&2
    curl --fail --location --progress-bar --output "$installer" "$installer_url"
  fi

  # "Fusion Admin Install.exe" is a 7z SFX wrapping a self-contained Python
  # "streaming installer" (streamer.exe + an embedded CPython runtime), not a
  # native installer. Running the SFX itself under Wine fails ("Can't load
  # config info"), and even running streamer.exe directly fails to find its
  # own stdlib if invoked from outside the prefix's drive_c -- Wine can't map
  # that to a drive letter, so it hands the app a "\\?\unix\..." path that
  # Python's own bootstrap can't parse. Extract with a native Linux 7z instead
  # of Wine, into drive_c, and run streamer.exe from there with a plain
  # relative path so Wine gives it an ordinary C:\... path.
  extract_dir="$prefix/drive_c/fusion-installer"
  rm -rf "$extract_dir"
  mkdir -p "$extract_dir"
  7z x -o"$extract_dir" -y "$installer" >/dev/null

  echo "==> Installing Autodesk Fusion 360 (silent, two-pass; this can take a while)..." >&2
  (cd "$extract_dir" && timeout -k 10m 9m wine streamer.exe --quiet) || true
  sleep 5
  (cd "$extract_dir" && timeout -k 5m 1m wine streamer.exe --quiet) || true
  wineserver --wait
  rm -rf "$extract_dir"

  launcher_exe="$(find_launcher)"
  if [ -z "$launcher_exe" ]; then
    echo "error: Fusion360.exe not found after installation." >&2
    echo "The install may have failed, or Autodesk changed its layout; check:" >&2
    echo "  $prefix/drive_c/users/*/AppData/Local/Autodesk/webdeploy" >&2
    exit 1
  fi

  echo "==> Applying known post-install fixes..." >&2
  # DeviceSettingsProvider.dll sometimes fails to load from its installed
  # location; Fusion also looks one directory up from ADPCER/.
  find "$prefix" -path '*/ADPCER/DeviceSettingsProvider.dll' 2>/dev/null | while read -r dll; do
    up="$(dirname "$(dirname "$dll")")/DeviceSettingsProvider.dll"
    [ -f "$up" ] || ln -sf "$dll" "$up"
  done

  # Seed Fusion's own renderer settings before its first launch, matching the
  # GPU driver picked above: DX11 (DXVK) or GLCore (OpenGL) for the 3D viewport.
  if [ "$gpu_driver" = DXVK ]; then
    machine_options_xml="$FUSION360_MACHINE_OPTIONS_XML_DXVK"
  else
    machine_options_xml="$FUSION360_MACHINE_OPTIONS_XML_OPENGL"
  fi
  for user_dir in "$prefix/drive_c/users"/*/; do
    [ -d "$user_dir" ] || continue
    for options_dir in \
      "$user_dir/AppData/Roaming/Autodesk/Neutron Platform/Options" \
      "$user_dir/AppData/Local/Autodesk/Neutron Platform/Options" \
      "$user_dir/Application Data/Autodesk/Neutron Platform/Options"; do
      mkdir -p "$options_dir"
      cp -f "$machine_options_xml" "$options_dir/NMachineSpecificOptions.xml"
    done
  done
fi

echo "==> Starting Autodesk Fusion 360..." >&2
DXVK_LOG_LEVEL=none WINEDEBUG=-all,+err wine "$launcher_exe" "$@" &
wine_pid=$!
wait "$wine_pid"
wineserver -k
