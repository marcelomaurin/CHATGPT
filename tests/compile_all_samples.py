#!/usr/bin/env python3
"""
CI Sample Compiler (CHATGPT-014).
Compiles all supported samples for the current OS from tests/samples_inventory.json.
"""

import sys
import json
import subprocess
import shutil
import platform
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
INVENTORY_FILE = REPO_ROOT / "tests" / "samples_inventory.json"

def find_lazbuild() -> str | None:
    found = shutil.which("lazbuild")
    if found:
        return found
    if platform.system() == "Windows":
        for cand in [
            r"C:\lazarus\lazbuild.exe",
            r"C:\Program Files\Lazarus\lazbuild.exe",
            r"C:\Program Files (x86)\Lazarus\lazbuild.exe",
            r"D:\lazarus\lazbuild.exe",
        ]:
            if Path(cand).exists():
                return cand
    else:
        for cand in ["/usr/bin/lazbuild", "/usr/local/bin/lazbuild", "/opt/lazarus/lazbuild"]:
            if Path(cand).exists():
                return cand
    return None

def main():
    lazbuild = find_lazbuild()
    if not lazbuild:
        print("[ERRO] lazbuild não encontrado.")
        sys.exit(2)

    if not INVENTORY_FILE.exists():
        print(f"[ERRO] Inventário não encontrado: {INVENTORY_FILE}")
        sys.exit(1)

    inventory = json.loads(INVENTORY_FILE.read_text(encoding="utf-8"))
    current_os = "windows" if platform.system() == "Windows" else "linux"

    passed = []
    failed = []
    ignored = []

    print(f"=== Compilação dos Samples ({current_os.upper()}) ===")
    print(f"Total de samples no inventário: {len(inventory)}")

    for rel_path, meta in inventory.items():
        sample_path = REPO_ROOT / rel_path
        if not sample_path.exists():
            print(f"[FALTA] {rel_path}")
            failed.append((rel_path, "Arquivo .lpi não encontrado no disco"))
            continue

        if current_os not in meta.get("platforms", ["windows", "linux"]):
            ignored.append((rel_path, f"Específico para {meta.get('platforms')}"))
            continue

        print(f"[COMPILANDO] {meta['name']} ({rel_path})...")
        cmd = [lazbuild, "--build-all", str(sample_path)]
        res = subprocess.run(cmd, capture_output=True, text=True, cwd=str(sample_path.parent))

        if res.returncode == 0:
            print(f"  -> [OK] {meta['name']}")
            passed.append(rel_path)
        else:
            print(f"  -> [ERRO] {meta['name']}")
            failed.append((rel_path, res.stdout[-500:] if res.stdout else "Erro de compilação"))

    print("\n" + "=" * 60)
    print("           RELATÓRIO DE COMPILAÇÃO DOS SAMPLES")
    print("=" * 60)
    print(f"Total no inventário: {len(inventory)}")
    print(f"Compilados com SUCESSO: {len(passed)}")
    print(f"Falhas                : {len(failed)}")
    print(f"Ignorados (outro OS)  : {len(ignored)}")
    print("=" * 60)

    if failed:
        print("\nLista de falhas:")
        for path, err in failed:
            print(f"  ! {path}")
        sys.exit(1)

    print("\nTodos os samples suportados foram compilados com sucesso!")
    sys.exit(0)

if __name__ == "__main__":
    main()
