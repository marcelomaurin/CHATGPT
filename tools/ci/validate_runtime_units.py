#!/usr/bin/env python3
"""Validate runtime/design-time boundaries for selected Lazarus AI units.

This is intentionally conservative: units listed here are expected to be usable
at runtime without design-time-only Lazarus resources.  The list grows as each
package is migrated.
"""

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[2]

RUNTIME_UNITS = [
    Path("pacote/AI/aibase.pas"),
    Path("pacote/AI Graph/aidependencygraph.pas"),
    Path("pacote/AI Agent/aiagent_actions.pas"),
    Path("pacote/AI Agent/aiagent_sourceactions.pas"),
]

FORBIDDEN = {
    "lresources",
    "ideintf",
    "propedits",
    "componenteditors",
}

DESIGN_MARKERS = (
    "registercomponents(",
    "registerpropertyeditor(",
    "registercomponenteditor(",
)


def strip_conditional_lcl_blocks(text: str) -> str:
    # Pure-FPC units may keep backward-compatible registration guarded by LCL.
    # Nested blocks are intentionally not accepted here: migrate those into a
    # dedicated *_register unit instead of making the guard more permissive.
    return re.sub(
        r"\{\$IFDEF\s+LCL\}[\s\S]*?\{\$ENDIF\}",
        "",
        text,
        flags=re.IGNORECASE,
    )


def uses_units(text: str) -> list[str]:
    result: list[str] = []
    for clause in re.findall(r"\buses\b\s+([^;]+);", text, re.IGNORECASE):
        clause = re.sub(r"\{.*?\}", "", clause, flags=re.DOTALL)
        clause = re.sub(r"\(\*.*?\*\)", "", clause, flags=re.DOTALL)
        clause = re.sub(r"//.*", "", clause)
        for token in clause.split(","):
            token = token.strip()
            if token:
                result.append(token.split()[0].lower())
    return result


def validate(path: Path) -> list[str]:
    errors: list[str] = []
    if not path.is_file():
        return [f"missing runtime unit: {path}"]

    content = path.read_text(encoding="utf-8", errors="ignore")
    pure = strip_conditional_lcl_blocks(content)
    lowered = pure.lower()

    for unit in uses_units(pure):
        if unit in FORBIDDEN:
            errors.append(f"design-time unit '{unit}' imported by runtime")

    if re.search(r"\{\$I\s+[^}]+\.lrs\s*\}", pure, re.IGNORECASE):
        errors.append(".lrs resource included by runtime")

    for marker in DESIGN_MARKERS:
        if marker in lowered:
            errors.append(f"design-time registration found in runtime: {marker}")

    return errors


def main() -> int:
    failures = 0
    print("=== Runtime/design-time boundary ===")
    for rel in RUNTIME_UNITS:
        path = ROOT / rel
        errors = validate(path)
        if errors:
            failures += len(errors)
            print(f"[FAIL] {rel}")
            for error in errors:
                print(f"       {error}")
        else:
            print(f"[PASS] {rel}")

    if failures:
        print(f"\n{failures} boundary violation(s).")
        return 1
    print(f"\n{len(RUNTIME_UNITS)} runtime units validated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
