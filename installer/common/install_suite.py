#!/usr/bin/env python3
"""Install and validate Lazarus AI Suite dependencies, packages and HTTPS runtime."""

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


ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "installer" / "dependencies.json"


def run(command: list[str], cwd: Path | None = None) -> bool:
    print("+", " ".join(str(item) for item in command), flush=True)
    return subprocess.run(command, cwd=str(cwd) if cwd else None).returncode == 0


def load_manifest() -> dict:
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def normalize_arch(value: str | None = None) -> str:
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


def platform_key(arch: str | None = None) -> str:
    system = platform.system().lower()
    if system.startswith("win"):
        system = "windows"
    return f"{system}-{normalize_arch(arch)}"


def find_lazbuild(explicit: str) -> Path | None:
    candidates: list[Path] = []
    if explicit:
        candidates.append(Path(explicit))
    found = shutil.which("lazbuild") or shutil.which("lazbuild.exe")
    if found:
        candidates.append(Path(found))
    candidates.extend([
        Path("C:/lazarus/lazbuild.exe"), Path("C:/Lazarus/lazbuild.exe"),
        Path("C:/Program Files/Lazarus/lazbuild.exe"), Path("/usr/bin/lazbuild"),
        Path("/usr/local/bin/lazbuild"), Path("/opt/lazarus/lazbuild"),
    ])
    return next((item.resolve() for item in candidates if item.is_file()), None)


def search_package(filename: str, env_name: str, dependency_dir: Path, lazbuild: Path) -> Path | None:
    roots: list[Path] = []
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


def resolve_dependencies(
    manifest: dict, lazbuild: Path, dependency_dir: Path, no_download: bool, profile: str
) -> bool:
    dependency_dir.mkdir(parents=True, exist_ok=True)
    ok = True
    selected_packages = set(manifest["profiles"][profile])
    for dep in manifest["dependencies"]:
        if not selected_packages.intersection(dep["required_by"]):
            continue
        package = search_package(dep["package"], dep["environment"], dependency_dir, lazbuild)
        checkout = dependency_dir / dep["name"].lower().replace(" ", "-")
        if package is None and dep.get("repository") and not no_download:
            if not checkout.exists():
                if not run(["git", "clone", "--depth", "1", dep["repository"], str(checkout)]):
                    ok = False
                    continue
            relative = dep.get("relative_package", "")
            candidate = checkout / relative
            package = candidate.resolve() if candidate.is_file() else None
        if package is None:
            print(f"[ERRO] Dependência não encontrada: {dep['name']} ({dep['package']})")
            if dep.get("note"):
                print("       " + dep["note"])
            ok = False
            continue
        print(f"[OK] {dep['name']}: {package}")
        if not run([str(lazbuild), "--add-package-link", str(package)]):
            ok = False
    return ok


def validate_openssl(manifest: dict, arch: str | None, target: Path | None) -> bool:
    key = platform_key(arch)
    entry = manifest["openssl"].get(key)
    if entry is None:
        print(f"[ERRO] Plataforma OpenSSL não declarada: {key}")
        return False
    if "system_libraries" in entry:
        missing = [name for name in entry["system_libraries"] if not ctypes.util.find_library(name)]
        if missing:
            print(f"[ERRO] OpenSSL do sistema incompleto ({key}): {', '.join(missing)}")
            print(f"       Instale o pacote {entry.get('package', 'OpenSSL')} da distribuição.")
            return False
        print(f"[OK] OpenSSL do sistema disponível para {key}.")
        return True
    source = ROOT / entry["source"]
    missing = [name for name in entry["files"] if not (source / name).is_file()]
    if missing:
        print(f"[ERRO] Runtime OpenSSL incompleto em {source}: {', '.join(missing)}")
        return False
    if target:
        target.mkdir(parents=True, exist_ok=True)
        for name in entry["files"]:
            shutil.copy2(source / name, target / name)
            print(f"[OK] OpenSSL copiado: {target / name}")
    else:
        print(f"[OK] Runtime OpenSSL disponível para {key}: {source}")
    return True


def is_runtime_only(package: Path) -> bool:
    try:
        content = package.read_text(encoding="utf-8", errors="ignore")
        return '<Type Value="RunTime"/>' in content or '<Type Value="RunTimeOnly"/>' in content
    except Exception:
        return False


def process_packages(manifest: dict, lazbuild: Path, profile: str, install: bool, report: dict | None = None) -> bool:
    names = manifest["profiles"][profile]
    tracked = {path.stem for path in (ROOT / "pacote" / "packages").glob("*.lpk")}
    declared = set(manifest["profiles"]["all"])
    missing_manifest = sorted(tracked - declared)
    missing_files = sorted(declared - tracked)
    if profile == "all" and (missing_manifest or missing_files):
        print(f"[ERRO] Pacotes fora do manifesto: {missing_manifest}")
        print(f"[ERRO] Pacotes declarados e ausentes: {missing_files}")
        if report is not None:
            report["errors"].append(f"Manifest mismatch: outside={missing_manifest}, missing={missing_files}")
        return False
    ok = True
    if not install:
        for name in names:
            package = ROOT / "pacote" / "packages" / f"{name}.lpk"
            if package.is_file() and not run([str(lazbuild), "--add-package-link", str(package)]):
                print(f"[ERRO] Não foi possível registrar o link interno: {name}")
                ok = False
        if not ok:
            return False
    for name in names:
        package = ROOT / "pacote" / "packages" / f"{name}.lpk"
        if not package.is_file():
            print(f"[ERRO] Pacote ausente: {package}")
            if report is not None:
                report["failed_packages"].append(name)
            ok = False
            continue
        arguments = [str(lazbuild)]
        if install:
            if is_runtime_only(package):
                run([str(lazbuild), "--add-package-link", str(package)])
                arguments.append(str(package))
            else:
                arguments.extend(["--add-package", str(package)])
        else:
            arguments.append(str(package))
        if not run(arguments):
            print(f"[ERRO] Falha no pacote: {name}")
            if report is not None:
                report["failed_packages"].append(name)
            ok = False
        else:
            print(f"[OK] Pacote: {name}")
            if report is not None:
                report["compiled_packages"].append(name)
    return ok


def print_summary_report(report: dict, success: bool):
    print("\n" + "=" * 60)
    print("         RELATÓRIO CONSOLIDADO DO INSTALADOR CHATGPT")
    print("=" * 60)
    print(f"Status Final       : {'SUCESSO' if success else 'FALHA'}")
    print(f"Perfil de Instalação: {report.get('profile', 'N/A')}")
    print(f"Ação Executada     : {report.get('action', 'N/A')}")
    print(f"Plataforma         : {report.get('platform', 'N/A')}")
    print(f"Executável lazbuild: {report.get('lazbuild', 'N/A')}")
    print("-" * 60)
    print(f"Dependências Externas : {len(report.get('installed_deps', []))} instaladas, {len(report.get('failed_deps', []))} falhas")
    for dep in report.get('installed_deps', []):
        print(f"  [OK] {dep}")
    for dep in report.get('failed_deps', []):
        print(f"  [ERRO] {dep}")
    print("-" * 60)
    print(f"Pacotes da Suíte      : {len(report.get('compiled_packages', []))} compilados, {len(report.get('failed_packages', []))} falhas")
    for p in report.get('failed_packages', []):
        print(f"  [FALHA] {p}")
    if report.get('rebuild_ide'):
        print(f"Rebuild da IDE Lazarus: {'OK' if report.get('rebuild_ide') == 'OK' else 'FALHOU'}")
    print("=" * 60 + "\n")


def main() -> int:
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
        print("[ERRO] lazbuild não encontrado.")
        return 2

    report = {
        "action": args.action,
        "profile": args.profile,
        "platform": platform_key(args.arch or None),
        "lazbuild": str(lazbuild),
        "installed_deps": [],
        "failed_deps": [],
        "compiled_packages": [],
        "failed_packages": [],
        "errors": [],
        "rebuild_ide": None,
    }

    dependencies_ok = resolve_dependencies(
        manifest, lazbuild, Path(args.dependency_dir), args.no_download, args.profile
    )
    if dependencies_ok:
        report["installed_deps"] = [d["name"] for d in manifest["dependencies"] if set(manifest["profiles"][args.profile]).intersection(d["required_by"])]

    ssl_ok = validate_openssl(manifest, args.arch or None, Path(args.runtime_target) if args.runtime_target else None)
    packages_ok = dependencies_ok and process_packages(manifest, lazbuild, args.profile, args.action == "install", report)
    ide_ok = True
    if args.action == "install" and packages_ok and not args.skip_ide:
        ide_ok = run([str(lazbuild), "--build-ide="])
        report["rebuild_ide"] = "OK" if ide_ok else "FALHOU"

    total_ok = dependencies_ok and ssl_ok and packages_ok and ide_ok
    print_summary_report(report, total_ok)
    return 0 if total_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
