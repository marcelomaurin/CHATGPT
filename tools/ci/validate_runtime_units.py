#!/usr/bin/env python3
"""Validate runtime/design-time boundaries for migrated Lazarus AI units.

Only units whose registration has already been split belong in RUNTIME_UNITS.
Pure-FPC graph units are independently protected by tests/ci_guard_fgx.py while
openai_graph completes its design-time migration package-by-package.
"""

from pathlib import Path
import re
from typing import List

ROOT = Path(__file__).resolve().parents[2]

RUNTIME_UNITS = [
    Path("pacote/AI/aibase.pas"),
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
    return re.sub(
        r"\{\$IFDEF\s+LCL\}[\s\S]*?\{\$ENDIF\}",
        "",
        text,
        flags=re.IGNORECASE,
    )


def uses_units(text: str) -> List[str]:
    result = []  # type: List[str]
    for clause in re.findall(r"\buses\b\s+([^;]+);", text, re.IGNORECASE):
        clause = re.sub(r"\{.*?\}", "", clause, flags=re.DOTALL)
        clause = re.sub(r"\(\*.*?\*\)", "", clause, flags=re.DOTALL)
        clause = re.sub(r"//.*", "", clause)
        for token in clause.split(","):
            token = token.strip()
            if token:
                result.append(token.split()[0].lower())
    return result


def validate(path: Path) -> List[str]:
    errors = []  # type: List[str]
    if not path.is_file():
        return ["missing runtime unit: %s" % path]

    content = path.read_text(encoding="utf-8", errors="ignore")
    pure = strip_conditional_lcl_blocks(content)
    lowered = pure.lower()

    for unit in uses_units(pure):
        if unit in FORBIDDEN:
            errors.append("design-time unit '%s' imported by runtime" % unit)

    if re.search(r"\{\$I\s+[^}]+\.lrs\s*\}", pure, re.IGNORECASE):
        errors.append(".lrs resource included by runtime")

    for marker in DESIGN_MARKERS:
        if marker in lowered:
            errors.append("design-time registration found in runtime: %s" % marker)

    return errors


def main() -> int:
    failures = 0
    print("=== Runtime/design-time boundary ===")
    for rel in RUNTIME_UNITS:
        path = ROOT / rel
        errors = validate(path)
        if errors:
            failures += len(errors)
            print("[FAIL] %s" % rel)
            for error in errors:
                print("       %s" % error)
        else:
            print("[PASS] %s" % rel)

    if failures:
        print("\n%d boundary violation(s)." % failures)
        return 1
    print("\n%d migrated runtime units validated." % len(RUNTIME_UNITS))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
