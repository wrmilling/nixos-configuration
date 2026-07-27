#!/usr/bin/env python3
"""Replace the RK3399 CPU/GPU operating-point tables in a decompiled
Pinebook Pro device tree (dtc -I dtb -O dts output) with riker's
overclock/undervolt curve, preserving each table's existing phandle so
other nodes' numeric references to it stay valid.
"""

import re
import sys

# (opp-hz, opp-microvolt min, target, max, clock-latency-ns or None)
OPP_TABLES = {
    "opp-table-0": {  # cluster0: A53 "little" cores
        "opp-shared": True,
        "entries": [
            (408000000, 825000, 825000, 1200000, 40000),
            (600000000, 825000, 825000, 1200000, None),
            (816000000, 850000, 850000, 1200000, None),
            (1008000000, 900000, 900000, 1200000, None),
            (1200000000, 975000, 975000, 1200000, None),
            (1416000000, 1100000, 1100000, 1200000, None),
            (1512000000, 1150000, 1150000, 1200000, None),
            (1608000000, 1200000, 1200000, 1200000, None),
        ],
    },
    "opp-table-1": {  # cluster1: A72 "big" cores
        "opp-shared": True,
        "entries": [
            (408000000, 825000, 825000, 1250000, 40000),
            (600000000, 825000, 825000, 1250000, None),
            (816000000, 825000, 825000, 1250000, None),
            (1008000000, 850000, 850000, 1250000, None),
            (1200000000, 900000, 900000, 1250000, None),
            (1416000000, 975000, 975000, 1250000, None),
            (1608000000, 1050000, 1050000, 1250000, None),
            (1800000000, 1150000, 1150000, 1250000, None),
            (2016000000, 1250000, 1250000, 1250000, None),
            (2108000000, 1250000, 1250000, 1250000, None),
        ],
    },
    "opp-table-2": {  # GPU (Mali T860MP4)
        "opp-shared": False,
        "entries": [
            (200000000, 825000, 825000, 1200000, None),
            (297000000, 825000, 825000, 1200000, None),
            (400000000, 825000, 825000, 1200000, None),
            (500000000, 850000, 850000, 1200000, None),
            (600000000, 925000, 925000, 1200000, None),
            (800000000, 1075000, 1075000, 1200000, None),
            (950000000, 1200000, 1200000, 1200000, None),
        ],
    },
}


def build_block(name, table, phandle_line):
    lines = [f"\t{name} {{", '\t\tcompatible = "operating-points-v2";']
    if table["opp-shared"]:
        lines.append("\t\topp-shared;")
    if phandle_line:
        lines.append(f"\t\t{phandle_line}")

    for i, (hz, uv_min, uv_target, uv_max, latency) in enumerate(table["entries"]):
        lines.append(f"\n\t\topp{i:02d} {{")
        lines.append(f"\t\t\topp-hz = /bits/ 64 <{hz}>;")
        lines.append(f"\t\t\topp-microvolt = <{uv_min} {uv_target} {uv_max}>;")
        if latency is not None:
            lines.append(f"\t\t\tclock-latency-ns = <{latency}>;")
        lines.append("\t\t};")

    lines.append("\t};\n")
    return "\n".join(lines)


def patch(text):
    for name, table in OPP_TABLES.items():
        pattern = re.compile(r"\t" + re.escape(name) + r" \{.*?\n\t\};\n", re.S)
        m = pattern.search(text)
        if not m:
            sys.exit(f"error: could not find {name} in input dts")

        phandle_match = re.search(r"phandle = <(0x[0-9a-fA-F]+)>;", m.group(0))
        if not phandle_match:
            sys.exit(f"error: {name} has no phandle to preserve")
        phandle_line = f"phandle = <{phandle_match.group(1)}>;"

        block = build_block(name, table, phandle_line)
        text = text[: m.start()] + block + text[m.end() :]
    return text


if __name__ == "__main__":
    src, dst = sys.argv[1], sys.argv[2]
    with open(src) as f:
        text = f.read()
    text = patch(text)
    with open(dst, "w") as f:
        f.write(text)
