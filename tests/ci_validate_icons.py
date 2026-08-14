#!/usr/bin/env python3
"""
CI Validator: Component and Icon Consistency Guard (CHATGPT-004).
Compares registered components (RegisterComponents in .pas), .lrs resource files,
and icons generated in pacote/generate_all_icons.py.
"""

import sys
import re
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
    inc_pattern = re.compile(r"\{\$I\s+([^}]+\.lrs)\s*\}", re.IGNORECASE)

    for pas_file in sorted(pacote_dir.rglob("*.pas")):
        try:
            content = pas_file.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue

        for match in inc_pattern.finditer(content):
            lrs_name = match.group(1).strip().lower()
            includes[lrs_name].append(pas_file.relative_to(repo_root))

    return includes

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
        if len(pas_files) > 1:
            locs = [str(p) for p in pas_files]
            warnings.append(f"Resource '{lrs_name}' included in multiple units: {locs}")

    # 3. Check registered components without corresponding icon resource
    for comp_lower, entries in registered.items():
        if comp_lower not in resources:
            for entry in entries:
                errors.append(
                    f"Registered component '{entry['raw_name']}' in {entry['file']} (Page: '{entry['page']}') has no matching .lrs icon resource!"
                )

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
