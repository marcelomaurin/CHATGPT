#!/usr/bin/env python3
import json
from pathlib import Path

root = Path(__file__).resolve().parents[2]
manifest = json.loads((root / "installer" / "dependencies.json").read_text(encoding="utf-8"))
tracked = {path.stem for path in (root / "pacote" / "packages").glob("*.lpk")}
declared_list = manifest["profiles"]["all"]
declared = set(declared_list)
errors = []
if len(declared_list) != len(declared):
    errors.append("há pacotes duplicados no perfil all")
if tracked != declared:
    errors.append(f"somente no Git: {sorted(tracked - declared)}; somente no manifesto: {sorted(declared - tracked)}")
for dep in manifest["dependencies"]:
    unknown = set(dep["required_by"]) - tracked
    if unknown:
        errors.append(f"{dep['name']} referencia pacotes desconhecidos: {sorted(unknown)}")
if errors:
    raise SystemExit("\n".join("[ERRO] " + item for item in errors))
print(f"[OK] {len(tracked)} pacotes declarados exatamente uma vez.")
