#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""NeuroGraph Player (Play)

Permite carregar modelos compilados (.ngs) do NeuroGraph e interagir através de perguntas,
gerando respostas por raciocínio associativo contextual em grafo de tokens.

Pode ser executado:
1. Linha de comando com pergunta direta:
   python play.py --pergunta "o que e um computador"
2. Modo interativo REPL (chat):
   python play.py
3. Modo JSON para integração com interfaces e IDEs:
   python play.py --pergunta "o que e um computador" --json
"""
from __future__ import annotations

import argparse
import codecs
import json
import os
import sys
from pathlib import Path
from typing import Optional

# Configura codificação do console para UTF-8 seguro no Windows
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

DIR_PLAY = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_PLAY.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"

if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))

try:
    from model import Session, TokenGraph
except ImportError as exc:
    print(f"[ERRO] Nao foi possivel carregar o modulo 'model' de {DIR_CONTEXTUAL_V7}: {exc}", file=sys.stderr)
    sys.exit(1)


def encontrar_modelos_disponiveis() -> list[Path]:
    """Varre as pastas padrao do projeto em busca de modelos .ngs validos."""
    locais_busca = [
        DIR_NEUROGRAPH / "treino" / "modelos",
        DIR_CONTEXTUAL_V7 / "results",
        DIR_CONTEXTUAL_V7 / "baseline_v6",
        DIR_NEUROGRAPH / "history" / "2026-11-12",
        DIR_PLAY,
    ]
    modelos: list[Path] = []
    vistos = set()
    for pasta in locais_busca:
        if pasta.exists():
            for arquivo in pasta.glob("*.ngs"):
                if arquivo.name not in vistos and arquivo.stat().st_size > 0:
                    vistos.add(arquivo.name)
                    modelos.append(arquivo)
    return modelos


def obter_modelo_padrao() -> Path:
    """Retorna o modelo mais recente ou prioritario (treinado recentemente ou v7 nativo)."""
    modelo_treinado = DIR_NEUROGRAPH / "treino" / "modelos" / "neurograph_youtube.ngs"
    if modelo_treinado.exists() and modelo_treinado.stat().st_size > 0:
        return modelo_treinado

    modelo_v7 = DIR_CONTEXTUAL_V7 / "results" / "neurograph_contextual_v7.ngs"
    if modelo_v7.exists():
        return modelo_v7

    modelos = encontrar_modelos_disponiveis()
    if modelos:
        return modelos[0]

    return modelo_v7


class NeuroGraphPlayer:
    """Controlador para carregar o modelo e gerar respostas."""

    def __init__(self, caminho_modelo: Optional[Path] = None):
        self.caminho_modelo = caminho_modelo or obter_modelo_padrao()
        self.modelo: Optional[TokenGraph] = None
        self.sessao: Session = Session()
        self.carregar_modelo()

    def carregar_modelo(self) -> None:
        if not self.caminho_modelo.exists():
            raise FileNotFoundError(f"Arquivo de modelo nao encontrado: {self.caminho_modelo}")
        self.modelo = TokenGraph.load(self.caminho_modelo)

    def responder(self, pergunta: str, manter_contexto: bool = True) -> dict:
        """Gera resposta a partir da pergunta do usuario usando o grafo de tokens."""
        pergunta = pergunta.strip()
        if not pergunta:
            return {
                "pergunta": "",
                "resposta": "Por favor, digite uma pergunta valida.",
                "abstencao": True,
                "motivo": "pergunta_vazia",
                "tokens": [],
            }

        if self.modelo is None:
            self.carregar_modelo()

        if manter_contexto:
            resultado = self.modelo.respond(pergunta, self.sessao)
        else:
            resultado = self.modelo.generate(pergunta)

        texto_resposta = resultado.text if resultado.text else ""
        if resultado.abstained and not texto_resposta:
            texto_resposta = "(O modelo nao encontrou associacoes suficientes para responder com confianca)"

        return {
            "pergunta": pergunta,
            "resposta": texto_resposta,
            "abstencao": bool(resultado.abstained),
            "motivo": str(resultado.reason) if hasattr(resultado, "reason") else "",
            "tokens": list(resultado.tokens) if hasattr(resultado, "tokens") else [],
            "caminho_modelo": str(self.caminho_modelo),
        }

    def reiniciar_sessao(self) -> None:
        self.sessao = Session()


def modo_interativo(player: NeuroGraphPlayer) -> None:
    """Executa um chat interativo no terminal."""
    print("=" * 65)
    print(" NEUROGRAPH PLAYER - MODO INTERATIVO (PLAY)")
    print("=" * 65)
    print(f"Modelo carregado: {player.caminho_modelo.name}")
    print(f"Caminho: {player.caminho_modelo}")
    print("Comandos especiais:")
    print("  'sair' ou 'exit'   -> Encerra o chat")
    print("  'reset'            -> Reinicia o contexto da conversa")
    print("  'modelos'          -> Lista outros modelos disponiveis")
    print("-" * 65)

    while True:
        try:
            pergunta = input("\n[Pergunta] > ").strip()
            if not pergunta:
                continue

            cmd = pergunta.lower()
            if cmd in ("sair", "exit", "quit", ":q"):
                print("[Saindo do NeuroGraph Player...]")
                break
            elif cmd == "reset":
                player.reiniciar_sessao()
                print("[Contexto da sessao reiniciado com sucesso!]")
                continue
            elif cmd == "modelos":
                print("\nModelos encontrados:")
                for i, m in enumerate(encontrar_modelos_disponiveis(), 1):
                    marcador = " (ATUAL)" if m.resolve() == player.caminho_modelo.resolve() else ""
                    print(f"  {i}. {m.name} ({m.stat().st_size / 1024:.1f} KB){marcador}")
                continue

            resp = player.responder(pergunta)
            print(f"[Resposta] > {resp['resposta']}")
            if resp["abstencao"]:
                print(f"             (Abstencao: {resp['motivo']})")

        except (KeyboardInterrupt, EOFError):
            print("\n[Encerrando...]")
            break
        except Exception as exc:
            print(f"[Erro]: {exc}")


def main() -> None:
    parser = argparse.ArgumentParser(description="NeuroGraph Player - Executa inferencia e responde perguntas.")
    parser.add_argument("--pergunta", "-p", type=str, help="Pergunta direta a ser respondida pelo modelo.")
    parser.add_argument("--modelo", "-m", type=Path, default=None, help="Caminho do arquivo de modelo .ngs.")
    parser.add_argument("--listar-modelos", action="store_true", help="Lista todos os modelos .ngs encontrados.")
    parser.add_argument("--json", action="store_true", help="Formata a saida em JSON estruturado.")
    parser.add_argument("--sem-contexto", action="store_true", help="Nao mantem contexto entre chamadas (generate puro).")

    args = parser.parse_args()

    if args.listar_modelos:
        modelos = encontrar_modelos_disponiveis()
        if args.json:
            print(json.dumps([str(m) for m in modelos], ensure_ascii=False, indent=2))
        else:
            print("Modelos disponiveis:")
            for m in modelos:
                print(f" - {m.name}: {m}")
        return

    caminho_modelo = args.modelo or obter_modelo_padrao()
    try:
        player = NeuroGraphPlayer(caminho_modelo=caminho_modelo)
    except Exception as exc:
        msg = f"[ERRO] Falha ao carregar modelo '{caminho_modelo}': {exc}"
        if args.json:
            print(json.dumps({"erro": msg}, ensure_ascii=False))
        else:
            print(msg, file=sys.stderr)
        sys.exit(1)

    if args.pergunta:
        resp = player.responder(args.pergunta, manter_contexto=not args.sem_contexto)
        if args.json:
            print(json.dumps(resp, ensure_ascii=False, indent=2))
        else:
            print(f"Pergunta: {resp['pergunta']}")
            print(f"Resposta: {resp['resposta']}")
    else:
        modo_interativo(player)


if __name__ == "__main__":
    main()
