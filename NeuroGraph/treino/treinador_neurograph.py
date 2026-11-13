#!/usr/bin/env python3
"""Módulo de Treinamento e Integração do NeuroGraph com dados curados do YouTube.

Responsabilidades:
1. Carregar pares curados gerados pelo capturador/curador.
2. Mesclar de forma segura com a base de conhecimento existente do NeuroGraph.
3. Instanciar o TokenGraph (modelo autoregressivo em Python) e treinar novos pesos.
4. Salvar os pesos gerados no formato binário NGCTX007 (.ngs).
5. Executar validação imediata respondendo a perguntas sobre os conceitos recém-aprendidos.
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path
from typing import Any

# Adiciona o caminho do contextual_v7 ao sys.path para importar o modelo nativo do NeuroGraph
DIR_TREINO = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_TREINO.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"

if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))

try:
    from model import Example, TokenGraph, tokenize
except ImportError as exc:
    logging.error("Não foi possível importar 'model' de %s: %s", DIR_CONTEXTUAL_V7, exc)
    raise

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")


def carregar_dados_base() -> list[dict]:
    """Carrega o benchmark ou conjunto de treino inicial do NeuroGraph para manter o conhecimento prévio."""
    caminho_benchmark = DIR_CONTEXTUAL_V7 / "data" / "benchmark.json"
    if not caminho_benchmark.exists():
        logging.warning("Benchmark base não encontrado em %s", caminho_benchmark)
        return []
    try:
        with caminho_benchmark.open("r", encoding="utf-8") as f:
            dados = json.load(f)
            return dados.get("train", [])
    except Exception as exc:
        logging.warning("Erro ao ler benchmark base: %s", exc)
        return []


def carregar_dados_curados_youtube(caminho_curado: Path | None = None) -> list[dict]:
    """Carrega os pares extraídos e curados do YouTube."""
    if caminho_curado is None:
        caminho_curado = DIR_TREINO / "dados" / "processados" / "dataset_curado.json"

    if not caminho_curado.exists():
        logging.warning("Nenhum dado curado encontrado em %s", caminho_curado)
        return []

    try:
        with caminho_curado.open("r", encoding="utf-8") as f:
            return json.load(f)
    except Exception as exc:
        logging.error("Erro ao carregar dados curados: %s", exc)
        return []


def preparar_exemplos(
    incluir_base: bool = True,
    caminho_curado: Path | None = None,
) -> tuple[list[Example], list[dict]]:
    """Combina a base pré-existente e os novos fatos do YouTube em objetos Example."""
    todos_dados: list[dict] = []
    
    if incluir_base:
        base = carregar_dados_base()
        todos_dados.extend(base)
        logging.info("Carregados %d exemplos da base pré-existente.", len(base))

    novos = carregar_dados_curados_youtube(caminho_curado)
    # Evita duplicatas exatas de pergunta
    perguntas_existentes = {d.get("question") for d in todos_dados}
    adicionados = 0
    for item in novos:
        q = item.get("question")
        if q and q not in perguntas_existentes:
            todos_dados.append(item)
            perguntas_existentes.add(q)
            adicionados += 1

    logging.info("Adicionados %d novos exemplos curados do YouTube (Total: %d).", adicionados, len(todos_dados))

    exemplos: list[Example] = []
    for d in todos_dados:
        q = d.get("question", "").strip()
        a = d.get("answer")
        ctx = tuple(d.get("context", []))
        if q and a:
            exemplos.append(Example(question=q, answer=a, context=ctx))

    return exemplos, todos_dados


def treinar_neurograph(
    exemplos: list[Example],
    epochs: int = 140,
    learning_rate: float = 0.05,
    caminho_saida: Path | None = None,
) -> TokenGraph:
    """Treina os pesos associativos do TokenGraph com o conjunto consolidado de dados."""
    if not exemplos:
        raise ValueError("Nenhum exemplo fornecido para treinamento.")

    if caminho_saida is None:
        caminho_saida = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"

    caminho_saida = Path(caminho_saida).resolve()
    caminho_saida.parent.mkdir(parents=True, exist_ok=True)

    print("\n" + "=" * 65)
    print(f"REDE ALVO EM TREINAMENTO: {caminho_saida.name}")
    print(f"CAMINHO DE DESTINO: {caminho_saida}")
    print("=" * 65)

    logging.info("Iniciando treinamento do NeuroGraph...")
    logging.info("Arquivo de Rede Alvo: %s", caminho_saida)
    logging.info("Total de exemplos: %d | Épocas: %d | Taxa de Aprendizado: %.4f",
                 len(exemplos), epochs, learning_rate)

    modelo = TokenGraph()
    historico = modelo.fit(exemplos, epochs=epochs, learning_rate=learning_rate)

    if historico:
        perda_final = historico[-1].get("loss", 0.0)
        logging.info("Treinamento concluído com sucesso. Perda final: %.4f", perda_final)

    # Salva o arquivo de pesos binário (.ngs)
    modelo.save(caminho_saida)
    print(f"[REDE SALVA] Pesos associativos gravados em: {caminho_saida} ({caminho_saida.stat().st_size} bytes)")
    logging.info("Pesos gravados com sucesso em: %s (%d bytes)",
                 caminho_saida, caminho_saida.stat().st_size)

    return modelo


def testar_inferencia(modelo: TokenGraph, perguntas: list[str]) -> list[dict]:
    """Testa a geração de respostas do modelo treinado para uma lista de perguntas."""
    resultados = []
    print("\n" + "=" * 60)
    print("TESTE DE INFERÊNCIA DO NEUROGRAPH")
    print("=" * 60)

    for q in perguntas:
        gen = modelo.generate(q)
        print(f"Pergunta: {q}")
        print(f"Resposta: {gen.text}")
        print(f"Abstenção: {gen.abstained} | Motivo: {gen.reason}")
        print("-" * 60)
        resultados.append({
            "pergunta": q,
            "resposta": gen.text,
            "abstencao": gen.abstained,
            "motivo": gen.reason,
            "tokens": gen.tokens,
        })

    return resultados


if __name__ == "__main__":
    exemplos, dados = preparar_exemplos(incluir_base=True)
    if exemplos:
        # Treino rápido de demonstração
        modelo = treinar_neurograph(exemplos[:60], epochs=50)
        testar_inferencia(modelo, [
            "o que é um computador",
            "o que é um cachorro",
            "o que é um painel solar"
        ])
    else:
        print("Nenhum exemplo disponível para treino.")
