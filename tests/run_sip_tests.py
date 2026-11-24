#!/usr/bin/env python3
"""Compile and run the Pascal SIP/RTP loopback test against a real bridge."""
from pathlib import Path
import argparse
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fpc', default=shutil.which('fpc'))
    parser.add_argument('--bridge', required=True, type=Path)
    parser.add_argument('--unit-path', action='append', default=[],
                        help='Additional FPC unit directory (repeatable)')
    args = parser.parse_args()
    if not args.fpc:
        parser.error('Free Pascal not found; use --fpc')
    bridge = args.bridge.resolve()
    if not bridge.is_file():
        parser.error(f'Bridge not found: {bridge}')
    with tempfile.TemporaryDirectory(prefix='chatgpt-sip-') as directory:
        build = Path(directory)
        command = [args.fpc, '-B', '-gl', '-Cr', '-Co', f'-FU{build}', f'-FE{build}']
        command += [f'-Fu{p}' for p in [ROOT / 'pacote/AI',
                                      ROOT / 'pacote/AI Communication/AISIP',
                                      *args.unit_path]]
        command += [str(ROOT / 'tests/test_sip_loopback.lpr')]
        subprocess.run(command, check=True, cwd=build, timeout=120)
        executable = build / ('test_sip_loopback.exe' if os.name == 'nt' else 'test_sip_loopback')
        subprocess.run([str(executable), str(bridge)], check=True, cwd=build, timeout=90)

if __name__ == '__main__':
    main()
