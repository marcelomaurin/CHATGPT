#!/usr/bin/env bash
set -u

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SAMPLES_DIR="$ROOT_DIR/pacote/samples"
OUT_DIR="${OUT_DIR:-$ROOT_DIR/.sample-build/linux-x64}"
REPORT="$OUT_DIR/REPORT.md"
LOG_DIR="$OUT_DIR/logs"
BIN_DIR="$OUT_DIR/bin"

mkdir -p "$LOG_DIR" "$BIN_DIR"

LAZBUILD="${LAZBUILD:-$(command -v lazbuild || true)}"
if [[ -z "$LAZBUILD" ]]; then
  echo "ERRO: lazbuild não encontrado" >&2
  exit 2
fi

mapfile -d '' PROJECTS < <(find "$SAMPLES_DIR" -type f -name '*.lpi' -print0 | sort -z)

TOTAL=${#PROJECTS[@]}
OK=0
FAIL=0

{
  echo "# Samples Linux x64"
  echo
  echo "- Plataforma: x86_64-linux"
  echo "- lazbuild: $($LAZBUILD --version 2>&1 | head -1)"
  echo "- Total de projetos: $TOTAL"
  echo
  echo "| Sample | Resultado |"
  echo "|---|---|"
} > "$REPORT"

for LPI in "${PROJECTS[@]}"; do
  REL="${LPI#$ROOT_DIR/}"
  SAFE="$(printf '%s' "$REL" | tr '/ ' '__' | tr -cd '[:alnum:]_.-')"
  LOG="$LOG_DIR/$SAFE.log"
  SAMPLE_DIR="$(dirname "$LPI")"

  echo "============================================================"
  echo "Compilando: $REL"
  echo "============================================================"

  BEFORE="$OUT_DIR/.before"
  AFTER="$OUT_DIR/.after"
  find "$SAMPLE_DIR" -maxdepth 2 -type f -executable -printf '%p\n' 2>/dev/null | sort > "$BEFORE" || true

  if "$LAZBUILD" --build-all --cpu=x86_64 --os=linux "$LPI" >"$LOG" 2>&1; then
    OK=$((OK+1))
    echo "| \`$REL\` | OK |" >> "$REPORT"

    find "$SAMPLE_DIR" -maxdepth 2 -type f -executable -printf '%p\n' 2>/dev/null | sort > "$AFTER" || true
    while IFS= read -r EXE; do
      [[ -f "$EXE" ]] || continue
      if file "$EXE" 2>/dev/null | grep -q 'ELF 64-bit'; then
        NAME="$(basename "$EXE")"
        DEST_NAME="${NAME%.*}_64${NAME##$NAME*.}"
        # Linux normalmente não tem extensão; mantém nome limpo com _64.
        if [[ "$NAME" != *_64 ]]; then DEST_NAME="${NAME}_64"; else DEST_NAME="$NAME"; fi
        RELDIR="$(dirname "${EXE#$SAMPLES_DIR/}")"
        mkdir -p "$BIN_DIR/$RELDIR"
        cp -f "$EXE" "$BIN_DIR/$RELDIR/$DEST_NAME"
      fi
    done < "$AFTER"
  else
    FAIL=$((FAIL+1))
    echo "| \`$REL\` | FALHOU |" >> "$REPORT"
    tail -40 "$LOG" || true
  fi
done

{
  echo
  echo "## Resumo"
  echo
  echo "- Sucesso: $OK"
  echo "- Falha: $FAIL"
  echo "- Total: $TOTAL"
} >> "$REPORT"

echo
cat "$REPORT"

# Retorna erro quando algum sample falha, mas deixa relatório e logs disponíveis.
if [[ $FAIL -ne 0 ]]; then
  exit 1
fi
