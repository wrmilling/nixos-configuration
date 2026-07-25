{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.vps-bench;
  vps-bench = pkgs.writeShellApplication {
    name = "vps-bench";
    runtimeInputs = with pkgs; [
      sysbench
      fio
      iperf3
      sysstat
      iproute2
      jq
    ];
    text = ''
      print_help() {
        cat <<'EOF'
      usage: vps-bench [options]

      Collects hard performance numbers for the local host (CPU steal, CPU
      throughput, memory bandwidth, disk IOPS/bandwidth, network latency/errors)
      so two VPS instances can be diffed against each other.

      Typical usage (bart vs goku, from your workstation):

        ssh bart vps-bench | tee bart.log
        ssh goku vps-bench | tee goku.log
        diff -u bart.log goku.log

      To also benchmark throughput directly between the two hosts:

        ssh goku vps-bench --serve          # leave running in one terminal
        ssh bart  vps-bench --peer goku     # from the other host

      Options:
        --duration <sec>   seconds per benchmark phase (default: 10)
        --disk-size <sz>   fio test file size, e.g. 1G, 512M (default: 1G)
        --disk-dir <path>  directory for the fio test file (default: /var/tmp)
        --peer <host>      run ping + iperf3 client tests against <host>
                            (requires "vps-bench --serve" already running there)
        --serve            run only "iperf3 -s" in the foreground, for the --peer
                            side to connect to; Ctrl-C to stop
        --skip-cpu         skip CPU steal/benchmark phases
        --skip-mem         skip memory bandwidth phase
        --skip-disk        skip disk IOPS/bandwidth phase
        --skip-net         skip network phase
        -h, --help         show this help and exit

      Output is plain text on stdout, one clearly-labelled section per phase, so
      two runs can be compared with `diff` directly. A copy is also written to
      $OUT_FILE (printed at the end of the run).
      EOF
      }

      DURATION=10
      DISK_SIZE=1G
      DISK_DIR=/var/tmp
      PEER=""
      SERVE=0
      SKIP_CPU=0
      SKIP_MEM=0
      SKIP_DISK=0
      SKIP_NET=0

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --duration)   DURATION="$2"; shift 2 ;;
          --disk-size)  DISK_SIZE="$2"; shift 2 ;;
          --disk-dir)   DISK_DIR="$2"; shift 2 ;;
          --peer)       PEER="$2"; shift 2 ;;
          --serve)      SERVE=1; shift ;;
          --skip-cpu)   SKIP_CPU=1; shift ;;
          --skip-mem)   SKIP_MEM=1; shift ;;
          --skip-disk)  SKIP_DISK=1; shift ;;
          --skip-net)   SKIP_NET=1; shift ;;
          -h|--help)    print_help; exit 0 ;;
          *) echo "unknown argument: $1" >&2; print_help >&2; exit 1 ;;
        esac
      done

      if [[ "$SERVE" -eq 1 ]]; then
        echo "iperf3 server listening on 0.0.0.0:5201 (Ctrl-C to stop)..."
        exec iperf3 -s
      fi

      TS="$(date -u +%Y%m%dT%H%M%SZ)"
      OUT_FILE="$HOME/vps-bench-$(hostname)-$TS.log"
      FIO_FILE="$DISK_DIR/vps-bench-fio-$$"

      cleanup() { rm -f "$FIO_FILE"; }
      trap cleanup EXIT

      exec > >(tee "$OUT_FILE") 2>&1

      hr()      { printf '%s\n' "----------------------------------------"; }
      section() { echo; hr; echo "-- $1 --"; hr; }

      echo "=== vps-bench :: $(hostname) :: $TS ==="

      section "system"
      echo "kernel:        $(uname -r)"
      if command -v nixos-version >/dev/null 2>&1; then
        echo "nixos-version: $(nixos-version)"
      fi
      virt=$(systemd-detect-virt 2>/dev/null || true); echo "virt:          ''${virt:-unknown}"
      echo "uptime:        $(uptime -p 2>/dev/null || uptime)"
      echo "loadavg:       $(cut -d' ' -f1-3 /proc/loadavg)"
      echo "cpu model:     $(awk -F': ' '/model name/{print $2; exit}' /proc/cpuinfo)"
      echo "vcpus:         $(nproc)"
      free -h | awk 'NR==1 || NR==2'
      root_dev=$(findmnt -no SOURCE /)
      root_fs=$(findmnt -no FSTYPE /)
      echo "root fs:       $root_dev ($root_fs)"
      df -h / | awk 'NR==1 || NR==2'

      if systemctl list-unit-files 2>/dev/null | grep -q '^renovate\.service'; then
        echo "renovate.service: $(systemctl is-active renovate.service 2>/dev/null || echo unknown)"
      fi

      if [[ "$SKIP_CPU" -eq 0 ]]; then
        section "cpu steal / utilization (mpstat, ''${DURATION}s avg)"
        mpstat 1 "$DURATION" | awk '/Average/{print}'
        echo "note: %steal above ~1-2% sustained means the hypervisor is not giving"
        echo "      this VM the CPU time it's owed (noisy neighbor / oversubscription)."

        section "cpu benchmark (sysbench, ''${DURATION}s, $(nproc) threads)"
        sysbench cpu --cpu-max-prime=20000 --threads="$(nproc)" --time="$DURATION" run \
          | grep -E 'events per second|total time|avg:|95th percentile:'
      fi

      if [[ "$SKIP_MEM" -eq 0 ]]; then
        section "memory bandwidth (sysbench, 1M blocks, $(nproc) threads)"
        sysbench memory --memory-block-size=1M --memory-total-size=10G --threads="$(nproc)" run \
          | grep -E 'transferred|MiB/sec|total time'
      fi

      if [[ "$SKIP_DISK" -eq 0 ]]; then
        section "disk random 4k iops (fio, iodepth=32, ''${DURATION}s, size=''${DISK_SIZE})"
        fio --name=randrw --filename="$FIO_FILE" --size="$DISK_SIZE" \
            --time_based --runtime="$DURATION" --ramp_time=2 \
            --ioengine=libaio --direct=1 --bs=4k --iodepth=32 \
            --rw=randrw --rwmixread=70 --group_reporting \
            --output-format=json 2>/dev/null \
          | jq -r 'def ms2: (.*100|round)/100;
            .jobs[0] |
              "read:  iops=\(.read.iops|round)  bw=\(.read.bw/1024|round)MiB/s  lat_avg=\(.read.lat_ns.mean/1e6|ms2)ms  lat_p99=\((.read.clat_ns.percentile."99.000000" // 0)/1e6|ms2)ms",
              "write: iops=\(.write.iops|round) bw=\(.write.bw/1024|round)MiB/s  lat_avg=\(.write.lat_ns.mean/1e6|ms2)ms lat_p99=\((.write.clat_ns.percentile."99.000000" // 0)/1e6|ms2)ms"'
        rm -f "$FIO_FILE"

        section "disk sequential throughput (fio, 1M blocks, ''${DURATION}s, size=''${DISK_SIZE})"
        fio --name=seqrw --filename="$FIO_FILE" --size="$DISK_SIZE" \
            --time_based --runtime="$DURATION" --ramp_time=2 \
            --ioengine=libaio --direct=1 --bs=1M --iodepth=8 \
            --rw=rw --rwmixread=50 --group_reporting \
            --output-format=json 2>/dev/null \
          | jq -r '.jobs[0] |
              "read:  bw=\(.read.bw/1024|round)MiB/s",
              "write: bw=\(.write.bw/1024|round)MiB/s"'
        rm -f "$FIO_FILE"
      fi

      if [[ "$SKIP_NET" -eq 0 ]]; then
        section "network latency (ping, 20 packets)"
        for target in 1.1.1.1 8.8.8.8; do
          echo "-> $target"
          ping -c 20 -i 0.2 "$target" 2>/dev/null | tail -3 || echo "   (unreachable)"
        done

        iface=$(ip -j route show default | jq -r '.[0].dev // empty')
        if [[ -n "$iface" ]]; then
          section "nic error/drop counters ($iface)"
          ip -s link show dev "$iface"
        fi

        if [[ -n "$PEER" ]]; then
          section "peer: $PEER"
          echo "-> ping"
          ping -c 20 -i 0.2 "$PEER" 2>/dev/null | tail -3 || echo "   (unreachable)"
          echo "-> iperf3 (requires \"vps-bench --serve\" running on $PEER)"
          if ! iperf3 -c "$PEER" -t "$DURATION" -J 2>/dev/null \
            | jq -r '"sent: \(.end.sum_sent.bits_per_second/1e6|round)Mbps  received: \(.end.sum_received.bits_per_second/1e6|round)Mbps  retransmits: \(.end.sum_sent.retransmits)"'; then
            echo "   (iperf3 failed - is --serve running on $PEER, and is it reachable?)"
          fi
        fi
      fi

      section "done"
      echo "report written to: $OUT_FILE"
      echo "compare two hosts with: diff -u bart.log goku.log"
    '';
  };
in
{
  options.modules.home.scripts.vps-bench = {
    enable = lib.mkEnableOption "vps-bench - host performance benchmarking/diffing tool";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ vps-bench ];
  };
}
