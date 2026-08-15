#!/usr/bin/env python3
"""
Samples Inventory & Validator (CHATGPT-013).
Scans all .lpi sample projects in pacote/samples/ and validates them against tests/samples_inventory.json.
"""

import sys
import json
import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
SAMPLES_DIR = REPO_ROOT / "pacote" / "samples"
INVENTORY_FILE = REPO_ROOT / "tests" / "samples_inventory.json"

def scan_all_samples() -> dict[str, dict]:
    discovered = {}
    for lpi in sorted(SAMPLES_DIR.rglob("*.lpi")):
        if "backup" in lpi.parts:
            continue
        rel = lpi.relative_to(REPO_ROOT).as_posix()
        name = lpi.stem
        
        # Read lpi to detect special requirements
        content = lpi.read_text(encoding="utf-8", errors="ignore")
        is_windows_only = bool(re.search(r"Windows|win32|win64|cef|kinect", content, re.IGNORECASE) or "kinect" in rel.lower() or "chromium" in rel.lower())
        
        category = lpi.parent.parent.name if lpi.parent.parent != SAMPLES_DIR else lpi.parent.name
        
        discovered[rel] = {
            "name": name,
            "category": category,
            "path": rel,
            "platforms": ["windows"] if is_windows_only else ["windows", "linux"],
            "requires_gui": True,
            "status": "active"
        }
    return discovered

def generate_or_update_inventory():
    discovered = scan_all_samples()
    if INVENTORY_FILE.exists():
        try:
            existing = json.loads(INVENTORY_FILE.read_text(encoding="utf-8"))
            # Merge existing attributes
            for k, v in discovered.items():
                if k in existing:
                    v.update(existing[k])
        except Exception:
            pass
            
    INVENTORY_FILE.write_text(json.dumps(discovered, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {len(discovered)} sample definitions to {INVENTORY_FILE}")
    return discovered

def validate_inventory() -> bool:
    if not INVENTORY_FILE.exists():
        print(f"[ERRO] Arquivo de inventário não encontrado: {INVENTORY_FILE}")
        return False
        
    inventory = json.loads(INVENTORY_FILE.read_text(encoding="utf-8"))
    discovered = scan_all_samples()
    
    missing_in_inventory = set(discovered.keys()) - set(inventory.keys())
    missing_on_disk = set(inventory.keys()) - set(discovered.keys())
    
    ok = True
    if missing_in_inventory:
        print(f"[ERRO] Samples novos no disco não classificados no inventário ({len(missing_in_inventory)}):")
        for m in sorted(missing_in_inventory):
            print(f"  + {m}")
        ok = False
        
    if missing_on_disk:
        print(f"[ERRO] Samples no inventário que não existem no disco ({len(missing_on_disk)}):")
        for m in sorted(missing_on_disk):
            print(f"  - {m}")
        ok = False
        
    if ok:
        print(f"[OK] Inventário de samples 100% consistente ({len(inventory)} samples rastreados).")
        
    return ok

def main():
    if "--generate" in sys.argv or not INVENTORY_FILE.exists():
        generate_or_update_inventory()
    if not validate_inventory():
        sys.exit(1)

if __name__ == "__main__":
    main()
