#!/usr/bin/env python3
"""
CI Guard: FGX and FPC Standalone Units Validator (CHATGPT-002).
Ensures that runtime units designated for pure FPC do not import Lazarus/LCL units.
"""

import sys
import re
from pathlib import Path

# Explicit core units that must remain pure FPC
PURE_FPC_CORE_UNITS = [
    Path("pacote/AI/aibase.pas"),
    Path("pacote/AI Graph/aidependencygraph.pas"),
]

# Directory of FGX tools that must remain pure FPC
FGX_SRC_DIR = Path("pacote/samples/AI Project/framework_graph_explorer/src")

FORBIDDEN_UNITS = {
    "lresources",
    "forms",
    "controls",
    "graphics",
    "dialogs",
    "lcl",
    "lclintf",
    "lcltype",
    "lazutils",
    "editbtn",
    "checklst",
}

def check_file(file_path: Path) -> list[str]:
    if not file_path.exists():
        return [f"File not found: {file_path}"]

    errors = []
    content = file_path.read_text(encoding="utf-8", errors="ignore")

    # For pure FPC checking, strip out {$IFDEF LCL}...{$ENDIF} blocks
    pure_content = re.sub(r"\{\$IFDEF\s+LCL\}[\s\S]*?\{\$ENDIF\}", "", content, flags=re.IGNORECASE)

    # Match uses clauses (interface or implementation) in pure FPC mode
    uses_matches = re.findall(r"\buses\b\s+([^;]+);", pure_content, re.IGNORECASE)
    for clause in uses_matches:
        # Strip comments
        clean_clause = re.sub(r"\{.*?\}", "", clause, flags=re.DOTALL)
        clean_clause = re.sub(r"//.*", "", clean_clause)
        clean_clause = re.sub(r"\(\*.*?\*\)", "", clean_clause, flags=re.DOTALL)
        tokens = [t.strip().lower() for t in clean_clause.split(",") if t.strip()]
        for token in tokens:
            # Handle 'unit in file' syntax
            unit_name = token.split()[0] if " " in token else token
            if unit_name in FORBIDDEN_UNITS:
                errors.append(f"{file_path.name}: Forbidden Lazarus/LCL unit in uses: '{unit_name}'")

    # Check for {$I ...lrs} outside of {$IFDEF LCL}
    if re.search(r"\{\$I\s+[^}]+\.lrs\s*\}", pure_content, re.IGNORECASE):
        errors.append(f"{file_path.name}: Forbidden .lrs resource inclusion found in pure FPC unit")

    return errors

def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    all_errors = []

    print("=== CI Guard: Validating Pure FPC / FGX Units (CHATGPT-002) ===")

    units_to_check = [repo_root / u for u in PURE_FPC_CORE_UNITS]
    fgx_dir = repo_root / FGX_SRC_DIR
    if fgx_dir.exists():
        for p in sorted(fgx_dir.glob("*.pas")):
            units_to_check.append(p)
        for lpr in sorted(fgx_dir.glob("*.lpr")):
            units_to_check.append(lpr)

    for unit_path in units_to_check:
        rel_path = unit_path.relative_to(repo_root)
        errs = check_file(unit_path)
        if errs:
            all_errors.extend(errs)
            print(f"[FAIL] {rel_path}")
            for e in errs:
                print(f"       -> {e}")
        else:
            print(f"[PASS] {rel_path}")

    if all_errors:
        print(f"\nTotal violations found: {len(all_errors)}")
        return 1

    print(f"\nAll {len(units_to_check)} pure FPC / FGX units verified successfully (0 forbidden dependencies).")
    return 0

if __name__ == "__main__":
    sys.exit(main())
