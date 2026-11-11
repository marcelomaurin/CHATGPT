#!/usr/bin/env python3
"""
CI Validator: Component and Icon Consistency Guard (CHATGPT-004).
Compares registered components (RegisterComponents in .pas), .lrs resource files,
and icons generated in pacote/generate_all_icons.py.
"""

import sys
import re
import struct
import xml.etree.ElementTree as ET
from pathlib import Path
from collections import defaultdict

def extract_registered_components(repo_root: Path) -> dict[str, list[dict]]:
    """
    Scans all .pas files in pacote/ for RegisterComponents calls and extracts class names.
    """
    pacote_dir = repo_root / "pacote"
    registered = defaultdict(list)

    # RegisterComponents('Category', [TComponent1, TComponent2]);
    reg_pattern = re.compile(
        r"RegisterComponents\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*\[([^\]]+)\]\s*\)",
        re.IGNORECASE | re.DOTALL
    )

    for pas_file in sorted(pacote_dir.rglob("*.pas")):
        if "fixtures" in str(pas_file).lower():
            continue
        try:
            content = pas_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue

        for match in reg_pattern.finditer(content):
            page_name = match.group(1).strip()
            comps_str = match.group(2)
            # Remove comments
            comps_clean = re.sub(r"\{.*?\}|//.*|\(\*.*?\*\)", "", comps_str, flags=re.DOTALL)
            comp_names = [c.strip() for c in comps_clean.split(",") if c.strip()]
            for cname in comp_names:
                registered[cname.lower()].append({
                    "raw_name": cname,
                    "page": page_name,
                    "file": pas_file.relative_to(repo_root)
                })

    return registered

def extract_lrs_resources(repo_root: Path) -> dict[str, list[dict]]:
    """
    Scans all .lrs files in pacote/ and extracts LazarusResources.Add calls.
    """
    pacote_dir = repo_root / "pacote"
    resources = defaultdict(list)

    # LazarusResources.Add('resname', 'BMP', [...])
    res_pattern = re.compile(
        r"LazarusResources\.Add\s*\(\s*['\"]([^'\"]+)['\"]\s*,\s*['\"]([^'\"]+)['\"]",
        re.IGNORECASE
    )

    for lrs_file in sorted(pacote_dir.rglob("*.lrs")):
        try:
            content = lrs_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue

        for match in res_pattern.finditer(content):
            res_name = match.group(1).strip().lower()
            res_type = match.group(2).strip()
            resources[res_name].append({
                "type": res_type,
                "file": lrs_file.relative_to(repo_root)
            })

    return resources

def extract_lrs_includes(repo_root: Path) -> dict[str, list[Path]]:
    """
    Scans .pas files for {$I filename.lrs} includes.
    """
    pacote_dir = repo_root / "pacote"
    includes = defaultdict(list)
    inc_pattern = re.compile(r"\{\$I\s+[\'\"]?([^}\'\"]+\.lrs)[\'\"]?\s*\}", re.IGNORECASE)

    for pas_file in sorted(pacote_dir.rglob("*.pas")):
        try:
            content = pas_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue

        for match in inc_pattern.finditer(content):
            lrs_name = match.group(1).strip().lower()
            includes[lrs_name].append(pas_file.relative_to(repo_root))

    return includes


def validate_bitmap_payloads(repo_root: Path) -> list[str]:
    """Validate the bytes Lazarus will decode, not just the resource names."""
    errors = []
    pattern = re.compile(
        r"LazarusResources\.Add\s*\(\s*['\"]([^'\"]+)['\"]\s*,"
        r"\s*['\"]BMP['\"]\s*,\s*\[(.*?)\]\s*\)", re.I | re.S)
    for path in sorted((repo_root / 'pacote').rglob('*.lrs')):
        text = path.read_text(encoding='utf-8', errors='replace')
        for name, payload in pattern.findall(text):
            try:
                values = [int(value) for value in re.findall(r'#(\d+)', payload)]
                data = bytes(values)
                if len(data) < 54 or data[:2] != b'BM':
                    raise ValueError('missing BMP header')
                size, offset = struct.unpack_from('<I', data, 2)[0], struct.unpack_from('<I', data, 10)[0]
                width, height = struct.unpack_from('<ii', data, 18)
                if size != len(data) or not (0 < offset < len(data)):
                    raise ValueError('invalid BMP file size or pixel offset')
                if width <= 0 or height == 0 or width > 256 or abs(height) > 256:
                    raise ValueError('invalid palette bitmap dimensions')
            except (ValueError, struct.error) as exc:
                errors.append(f"Invalid bitmap '{name}' in {path.relative_to(repo_root)}: {exc}")
    return errors


def validate_package_icon_loading(repo_root: Path, registered: dict) -> tuple[list[str], int]:
    """Check that each owning package actually includes its component's resource.

    A bitmap elsewhere in the repository does not make it available in the IDE.
    Palette-only helper units are regular package files and are included here.
    """
    packages, owners, errors = {}, defaultdict(set), []
    resource_cache = {}
    include_pattern = re.compile(r"\{\$I\s+[\'\"]?([^}\'\"]+\.lrs)[\'\"]?\s*\}", re.I)
    resource_pattern = re.compile(r"LazarusResources\.Add\s*\(\s*['\"]([^'\"]+)['\"]", re.I)

    def path_key(path):
        return str(path.resolve()).casefold()

    def included_icons(source):
        key = path_key(source)
        if key in resource_cache:
            return resource_cache[key]
        names = set()
        text = source.read_text(encoding='utf-8', errors='replace')
        for include in include_pattern.findall(text):
            resource = (source.parent / include.strip().replace('\\', '/')).resolve()
            if resource.is_file():
                names.update(name.lower() for name in resource_pattern.findall(
                    resource.read_text(encoding='utf-8', errors='replace')))
            else:
                errors.append(f"Resource include '{include}' not found in {source.relative_to(repo_root)}")
        resource_cache[key] = names
        return names

    for lpk in sorted((repo_root / 'pacote/packages').glob('*.lpk')):
        tree = ET.parse(lpk)
        sources = []
        for node in tree.findall('./Package/Files/*/Filename'):
            source = (lpk.parent / node.get('Value', '').replace('\\', '/')).resolve()
            if source.is_file() and source.suffix.lower() in ('.pas', '.pp'):
                sources.append(source)
                owners[path_key(source)].add(lpk.stem)
        packages[lpk.stem] = (sources, [node.get('Value', '') for node in
                                      tree.findall('./Package/RequiredPkgs/*/PackageName')])

    def closure(name, seen):
        if name in seen or name not in packages:
            return
        seen.add(name)
        for dependency in packages[name][1]:
            closure(dependency, seen)

    available = {}
    for name in packages:
        dependencies = set()
        closure(name, dependencies)
        available[name] = set().union(*(included_icons(source) for dependency in dependencies
                                        for source in packages[dependency][0]))
    owned_count = 0
    for component, entries in registered.items():
        owning = set().union(*(owners[path_key(repo_root / entry['file'])] for entry in entries))
        if owning:
            owned_count += 1
        for package in sorted(owning):
            if component not in available[package]:
                errors.append(f"Package '{package}' does not load the icon for '{entries[0]['raw_name']}'")
    return errors, owned_count


def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    print("=== CI Validator: Component & Icon Consistency (CHATGPT-004) ===")

    registered = extract_registered_components(repo_root)
    resources = extract_lrs_resources(repo_root)
    includes = extract_lrs_includes(repo_root)

    print(f"Total components found in RegisterComponents: {len(registered)}")
    print(f"Total .lrs resources declared: {len(resources)}")
    print(f"Total .lrs includes across units: {len(includes)}")

    errors = []
    warnings = []

    # 1. Check duplicate resources in .lrs files
    for res_name, entries in resources.items():
        if len(entries) > 1:
            locs = [str(e["file"]) for e in entries]
            errors.append(f"Duplicate resource name '{res_name}' declared in multiple locations: {locs}")

    # 2. Check duplicate includes of same .lrs across different units (excluding root/wrapper if intentional)
    for lrs_name, pas_files in includes.items():
        if len(set(pas_files)) > 1:
            locs = sorted(str(p) for p in set(pas_files))
            warnings.append(f"Resource '{lrs_name}' included in multiple units: {locs}")

    # 3. Check registered components without corresponding icon resource
    for comp_lower, entries in registered.items():
        if comp_lower not in resources:
            for entry in entries:
                errors.append(
                    f"Registered component '{entry['raw_name']}' in {entry['file']} (Page: '{entry['page']}') has no matching .lrs icon resource!"
                )

    errors.extend(validate_bitmap_payloads(repo_root))
    loading_errors, owned_count = validate_package_icon_loading(repo_root, registered)
    errors.extend(loading_errors)
    print(f'Components checked in owning packages: {owned_count}')

    # 4. Check icon resources without corresponding registered component
    for res_name, entries in resources.items():
        if res_name not in registered:
            for entry in entries:
                warnings.append(
                    f"Resource '{res_name}' in {entry['file']} does not match any known RegisterComponents class."
                )

    print("\n--- Relatório de Validação de Ícones ---")
    if warnings:
        print(f"\n[AVISOS] ({len(warnings)}):")
        for w in warnings:
            print(f"  * {w}")

    if errors:
        print(f"\n[ERROS CRÍTICOS] ({len(errors)}):")
        for e in errors:
            print(f"  ! {e}")
        print("\n[VALIDAÇÃO FALHOU] Inconsistências de ícones detectadas.")
        return 1

    print("\n[VALIDAÇÃO APROVADA] Todos os componentes registrados possuem ícones correspondentes e válidos (0 erros).")
    return 0

if __name__ == "__main__":
    sys.exit(main())
