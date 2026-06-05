#!/usr/bin/env python3
"""Create chatgpt_ai_runtime.ini for the local installer."""

import argparse
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--platform", required=True)
    parser.add_argument("--arch", required=True)
    parser.add_argument("--install-dir", required=True)
    parser.add_argument("--lazbuild", default="")
    args = parser.parse_args()

    install_dir = Path(args.install_dir)
    config_file = install_dir / "chatgpt_ai_runtime.ini"

    lines = [
        "[Runtime]",
        f"Platform={args.platform}",
        f"Architecture={args.arch}",
        f"InstallPath={install_dir}",
        f"PackagePath={install_dir / 'packages'}",
        "",
        "[Lazarus]",
        f"LazbuildPath={args.lazbuild}",
        "Installed=0",
        "",
        "[Status]",
        "RuntimeReady=0",
        "PackagesInstalled=0",
        "LastInstall=",
        "",
    ]

    config_file.write_text("\n".join(lines), encoding="utf-8")
    print(f"Generated {config_file}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
