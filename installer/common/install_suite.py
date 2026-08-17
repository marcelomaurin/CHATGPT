#!/usr/bin/env python3
"""Install and validate Lazarus AI Suite dependencies, packages and HTTPS runtime.

The installer deliberately supports Python 3.8+ so it can still be used on
legacy Windows installations where a newer interpreter may not be available.
"""

from __future__ import annotations

import argparse
import ctypes.util
import json
import os
import platform
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "installer" / "dependencies.json"


def run(command: List[str], cwd: Optional[Path] = None) -> bool:
    print("+", " ".join(str(item) for item in command), flush=True)
    try:
        return subprocess.run(command, cwd=str(cwd) if cwd else None).returncode == 0
    except OSError as exc:
        print("[ERRO] Falha ao executar %s: %s" % (command[0], exc))
        return False


def command_output(command: List[str], cwd: Optional[Path] = None) -> str:
    try:
        result = subprocess.run(
            command,
            cwd=str(cwd) if cwd else None,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            universal_newlines=True,
        )
        return result.stdout.strip() if result.returncode == 0 else ""
    except OSError:
        return ""


def load_manifest() -> Dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def normalize_arch(value: Optional[str] = None) -> str:
    machine = (value or platform.machine()).lower()
    if machine in {"amd64", "x64", "x86_64"}:
        return "x86_64"
    if machine in {"x86", "i386", "i486", "i586", "i686"}:
        return "x86"
    if machine in {"arm64", "aarch64"}:
        return "aarch64"
    if machine.startswith("arm"):
        return "armhf"
    return machine


def platform_key(arch: Optional[str] = None) -> str:
    system = platform.system().lower()
    if system.startswith("win"):
        system = "windows"
    return "%s-%s" % (system, normalize_arch(arch))


def find_lazbuild(explicit: str) -> Optional[Path]:
    candidates = []  # type: List[Path]
    if explicit:
        candidates.append(Path(explicit))
    found = shutil.which("lazbuild") or shutil.which("lazbuild.exe")
    if found:
        candidates.append(Path(found))
    candidates.extend(
        [
            Path("C:/lazarus/lazbuild.exe"),
            Path("C:/Lazarus/lazbuild.exe"),
            Path("C:/Program Files/Lazarus/lazbuild.exe"),
            Path("C:/Program Files (x86)/Lazarus/lazbuild.exe"),
            Path("/usr/bin/lazbuild"),
            Path("/usr/local/bin/lazbuild"),
            Path("/opt/lazarus/lazbuild"),
        ]
    )
    for item in candidates:
        try:
            if item.is_file():
                return item.resolve()
        except OSError:
            pass
    return None


def find_fpc(lazbuild: Path) -> Optional[Path]:
    found = shutil.which("fpc") or shutil.which("fpc.exe")
    candidates = []  # type: List[Path]
    if found:
        candidates.append(Path(found))
    candidates.extend(
        [
            lazbuild.parent / "fpc.exe",
            lazbuild.parent / "fpc" / "bin" / "i386-win32" / "fpc.exe",
            lazbuild.parent / "fpc" / "bin" / "x86_64-win64" / "fpc.exe",
            Path("/usr/bin/fpc"),
            Path("/usr/local/bin/fpc"),
        ]
    )
    for item in candidates:
        try:
            if item.is_file():
                return item.resolve()
        except OSError:
            pass
    return None


def search_package(
    filename: str, env_name: str, dependency_dir: Path, lazbuild: Path
) -> Optional[Path]:
    roots = []  # type: List[Path]
    if os.environ.get(env_name):
        roots.append(Path(os.environ[env_name]))
    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        roots.append(Path(local_app_data) / "lazarus" / "onlinepackagemanager" / "packages")
    app_data = os.environ.get("APPDATA")
    if app_data:
        roots.append(Path(app_data) / "lazarus" / "onlinepackagemanager" / "packages")
    roots.extend([dependency_dir, lazbuild.parent, lazbuild.parent.parent])
    for root in roots:
        if not root.exists():
            continue
        direct = root / filename
        if direct.is_file():
            return direct.resolve()
        try:
            result = next(root.rglob(filename), None)
        except OSError:
            result = None
        if result and result.is_file():
            return result.resolve()
    return None


def dependency_checkout_name(dep: Dict) -> str:
    return dep.get("checkout_dir") or dep["name"].lower().replace(" ", "-").replace("/", "-")


def checkout_dependency(dep: Dict, checkout: Path) -> bool:
    repository = dep.get("repository", "")
    ref = dep.get("ref", "")
    if not repository:
        return False

    if not checkout.exists():
        clone = ["git", "clone"]
        if ref:
            clone.extend(["--branch", ref])
        clone.extend(["--depth", "1", repository, str(checkout)])
        if not run(clone):
            return False
    elif not (checkout / ".git").exists():
        print("[ERRO] Diretório de dependência existe mas não é um clone Git: %s" % checkout)
        return False

    # When a commit SHA is supplied, verify it explicitly.  For a tag/branch,
    # clone --branch already checks out the requested revision.
    expected_commit = dep.get("commit", "").strip()
    if expected_commit:
        current = command_output(["git", "rev-parse", "HEAD"], checkout)
        if not current.lower().startswith(expected_commit.lower()):
            if not run(["git", "fetch", "--depth", "1", "origin", expected_commit], checkout):
                return False
            if not run(["git", "checkout", "--detach", expected_commit], checkout):
                return False
            current = command_output(["git", "rev-parse", "HEAD"], checkout)
        if not current.lower().startswith(expected_commit.lower()):
            print("[ERRO] Revisão inesperada para %s: %s" % (dep["name"], current))
            return False
    return True


def resolve_dependencies(
    manifest: Dict,
    lazbuild: Path,
    dependency_dir: Path,
    no_download: bool,
    profile: str,
    report: Dict,
) -> bool:
    dependency_dir.mkdir(parents=True, exist_ok=True)
    ok = True
    selected_packages = set(manifest["profiles"][profile])

    for dep in manifest["dependencies"]:
        if not selected_packages.intersection(dep["required_by"]):
            continue

        package = search_package(dep["package"], dep["environment"], dependency_dir, lazbuild)
        checkout = dependency_dir / dependency_checkout_name(dep)

        if package is None and dep.get("repository") and not no_download:
            if checkout_dependency(dep, checkout):
                relative = dep.get("relative_package", "")
                candidate = checkout / relative
                package = candidate.resolve() if candidate.is_file() else None

        if package is None:
            msg = "%s (%s)" % (dep["name"], dep["package"])
            print("[ERRO] Dependência não encontrada: " + msg)
            if dep.get("note"):
                print("       " + dep["note"])
            report["failed_deps"].append(msg)
            ok = False
            continue

        print("[OK] %s: %s" % (dep["name"], package))
        if run([str(lazbuild), "--add-package-link", str(package)]):
            report["installed_deps"].append("%s: %s" % (dep["name"], package))
        else:
            report["failed_deps"].append(dep["name"])
            ok = False
    return ok


def validate_openssl(manifest: Dict, arch: Optional[str], target: Optional[Path]) -> bool:
    key = platform_key(arch)
    entry = manifest["openssl"].get(key)
    if entry is None:
        print("[ERRO] Plataforma OpenSSL não declarada: %s" % key)
        return False
    if "system_libraries" in entry:
        missing = [name for name in entry["system_libraries"] if not ctypes.util.find_library(name)]
        if missing:
            print("[ERRO] OpenSSL do sistema incompleto (%s): %s" % (key, ", ".join(missing)))
            print("       Instale o pacote %s da distribuição." % entry.get("package", "OpenSSL"))
            return False
        print("[OK] OpenSSL do sistema disponível para %s." % key)
        return True

    source = ROOT / entry["source"]
    missing = [name for name in entry["files"] if not (source / name).is_file()]
    if missing:
        print("[ERRO] Runtime OpenSSL incompleto em %s: %s" % (source, ", ".join(missing)))
        return False
    if target:
        target.mkdir(parents=True, exist_ok=True)
        for name in entry["files"]:
            shutil.copy2(source / name, target / name)
            print("[OK] OpenSSL copiado: %s" % (target / name))
    else:
        print("[OK] Runtime OpenSSL disponível para %s: %s" % (key, source))
    return True


def is_runtime_only(package: Path) -> bool:
    try:
        content = package.read_text(encoding="utf-8", errors="ignore")
        return '<Type Value="RunTime"/>' in content or '<Type Value="RunTimeOnly"/>' in content
    except Exception:
        return False


def process_packages(
    manifest: Dict, lazbuild: Path, profile: str, install: bool, report: Optional[Dict] = None
) -> bool:
    names = manifest["profiles"][profile]
    tracked = {path.stem for path in (ROOT / "pacote" / "packages").glob("*.lpk")}
    declared = set(manifest["profiles"]["all"])
    missing_manifest = sorted(tracked - declared)
    missing_files = sorted(declared - tracked)

    if profile == "all" and (missing_manifest or missing_files):
        print("[ERRO] Pacotes fora do manifesto: %s" % missing_manifest)
        print("[ERRO] Pacotes declarados e ausentes: %s" % missing_files)
        if report is not None:
            report["errors"].append(
                "Manifest mismatch: outside=%s, missing=%s" % (missing_manifest, missing_files)
            )
        return False

    ok = True
    if not install:
        for name in names:
            package = ROOT / "pacote" / "packages" / (name + ".lpk")
            if package.is_file() and not run([str(lazbuild), "--add-package-link", str(package)]):
                print("[ERRO] Não foi possível registrar o link interno: %s" % name)
                ok = False
        if not ok:
            return False

    for name in names:
        package = ROOT / "pacote" / "packages" / (name + ".lpk")
        if not package.is_file():
            print("[ERRO] Pacote ausente: %s" % package)
            if report is not None:
                report["failed_packages"].append(name)
            ok = False
            continue

        arguments = [str(lazbuild)]
        if install:
            if is_runtime_only(package):
                if not run([str(lazbuild), "--add-package-link", str(package)]):
                    if report is not None:
                        report["failed_packages"].append(name)
                    ok = False
                    continue
                arguments.append(str(package))
            else:
                arguments.extend(["--add-package", str(package)])
        else:
            arguments.append(str(package))

        if not run(arguments):
            print("[ERRO] Falha no pacote: %s" % name)
            if report is not None:
                report["failed_packages"].append(name)
            ok = False
        else:
            print("[OK] Pacote: %s" % name)
            if report is not None:
                report["compiled_packages"].append(name)
    return ok


def print_summary_report(report: Dict, success: bool) -> None:
    print("\n" + "=" * 60)
    print("         RELATÓRIO CONSOLIDADO DO INSTALADOR CHATGPT")
    print("=" * 60)
    print("Status Final        : %s" % ("SUCESSO" if success else "FALHA"))
    print("Perfil              : %s" % report.get("profile", "N/A"))
    print("Ação                : %s" % report.get("action", "N/A"))
    print("Plataforma          : %s" % report.get("platform", "N/A"))
    print("Python              : %s" % report.get("python", "N/A"))
    print("lazbuild            : %s" % report.get("lazbuild", "N/A"))
    print("FPC                 : %s" % report.get("fpc", "N/A"))
    print("-" * 60)
    print(
        "Dependências externas: %d OK, %d falhas"
        % (len(report.get("installed_deps", [])), len(report.get("failed_deps", [])))
    )
    for dep in report.get("installed_deps", []):
        print("  [OK] %s" % dep)
    for dep in report.get("failed_deps", []):
        print("  [ERRO] %s" % dep)
    print("-" * 60)
    print(
        "Pacotes da suíte: %d compilados, %d falhas"
        % (len(report.get("compiled_packages", [])), len(report.get("failed_packages", [])))
    )
    for package in report.get("failed_packages", []):
        print("  [FALHA] %s" % package)
    for error in report.get("errors", []):
        print("  [ERRO] %s" % error)
    if report.get("rebuild_ide"):
        print("Rebuild da IDE Lazarus: %s" % report.get("rebuild_ide"))
    print("=" * 60 + "\n")


def main() -> int:
    if sys.version_info < (3, 8):
        print("[ERRO] Este instalador requer Python 3.8 ou superior.")
        return 2

    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=["install", "check", "ci"])
    parser.add_argument("--profile", choices=["core", "recommended", "all"], default="recommended")
    parser.add_argument("--lazbuild", default="")
    parser.add_argument("--dependency-dir", default=str(ROOT / ".dependencies"))
    parser.add_argument("--runtime-target", default="")
    parser.add_argument("--arch", default="")
    parser.add_argument("--no-download", action="store_true")
    parser.add_argument("--skip-ide", action="store_true")
    args = parser.parse_args()

    manifest = load_manifest()
    lazbuild = find_lazbuild(args.lazbuild)
    if lazbuild is None:
        print("[ERRO] lazbuild não encontrado. Informe --lazbuild ou instale Lazarus.")
        return 2

    fpc = find_fpc(lazbuild)
    if fpc is None:
        print("[ERRO] FPC não encontrado. Verifique a instalação do Lazarus/FPC.")
        return 2

    report = {
        "action": args.action,
        "profile": args.profile,
        "platform": platform_key(args.arch or None),
        "python": sys.version.split()[0],
        "lazbuild": str(lazbuild),
        "fpc": str(fpc),
        "installed_deps": [],
        "failed_deps": [],
        "compiled_packages": [],
        "failed_packages": [],
        "errors": [],
        "rebuild_ide": None,
    }

    dependencies_ok = resolve_dependencies(
        manifest,
        lazbuild,
        Path(args.dependency_dir),
        args.no_download,
        args.profile,
        report,
    )
    ssl_ok = validate_openssl(
        manifest,
        args.arch or None,
        Path(args.runtime_target) if args.runtime_target else None,
    )
    packages_ok = dependencies_ok and process_packages(
        manifest, lazbuild, args.profile, args.action == "install", report
    )

    ide_ok = True
    if args.action == "install" and packages_ok and not args.skip_ide:
        ide_ok = run([str(lazbuild), "--build-ide="])
        report["rebuild_ide"] = "OK" if ide_ok else "FALHOU"

    total_ok = dependencies_ok and ssl_ok and packages_ok and ide_ok
    print_summary_report(report, total_ok)
    return 0 if total_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
