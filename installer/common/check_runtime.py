#!/usr/bin/env python3
"""
CHATGPT-AI runtime checker.

This script validates the local Python runtime used by Lazarus AI Suite
external components. It intentionally avoids installing anything.
"""

import argparse
import importlib
import platform
import sys
from pathlib import Path


def check_import(package_name: str) -> bool:
    try:
        importlib.import_module(package_name)
        print(f"[OK] import {package_name}")
        return True
    except Exception as exc:
        print(f"[WARN] import {package_name}: {exc}")
        return False


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate CHATGPT-AI runtime")
    parser.add_argument("--profile", default="core", choices=["core", "vision", "ml", "full", "arm"], help="Runtime profile")
    parser.add_argument("--install-dir", default="", help="Installation directory")
    args = parser.parse_args()

    print("CHATGPT-AI Runtime Check")
    print(f"System: {platform.system()}")
    print(f"Machine: {platform.machine()}")
    print(f"Python: {sys.version.split()[0]}")
    print(f"Executable: {sys.executable}")

    if args.install_dir:
        install_dir = Path(args.install_dir)
        print(f"InstallDir: {install_dir}")
        if not install_dir.exists():
            print("[WARN] install directory not found")

    ok = True

    # Minimal dependencies used by Python-enabled integrations.
    for pkg in ["requests"]:
        ok = check_import(pkg) and ok

    if args.profile in ("vision", "full"):
        for pkg in ["numpy", "PIL"]:
            ok = check_import(pkg) and ok
        # cv2 may be unavailable on ARM depending on distro/wheel support.
        check_import("cv2")

    if args.profile in ("ml", "full"):
        for pkg in ["numpy", "pandas"]:
            ok = check_import(pkg) and ok
        check_import("sklearn")

    print("Runtime ready." if ok else "Runtime has warnings/errors.")
    return 0 if ok else 2


if __name__ == "__main__":
    raise SystemExit(main())
