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
    tem_negativos = False
    for d in todos_dados:
        q = d.get("question", "").strip()
        a = d.get("answer")
        cat = d.get("category", "")
        raw_ctx = d.get("context", [])
        # Apenas itens de diálogo contextual explícito usam histórico de turno;
        # itens curados de tópicos/YouTube/PDF são perguntas diretas (contexto vazio).
        if cat in ("context", "composition", "paraphrase", "unknown"):
            ctx = tuple(raw_ctx) if isinstance(raw_ctx, list) else ()
        else:
            ctx = ()
        if not q:
            continue
        if a is None and "answer" in d:
            exemplos.append(Example(question=q, answer=None, context=ctx))
            tem_negativos = True
        elif a:
            palavras_a = tokenize(str(a))
            if palavras_a:
                if len(palavras_a) > 62:
                    a = " ".join(palavras_a[:60])
                exemplos.append(Example(question=q, answer=str(a), context=ctx))

    # Garante exemplos contrastivos de abstenção (<refuse>) para calibrar perguntas fora do domínio
    if not tem_negativos:
        negativos_calibracao = [
            "o que é um quasar",
            "qual é a capital da austrália",
            "quem inventou o rádio",
            "o que é um píon",
            "quem descobriu netuno",
        ]
        for q_neg in negativos_calibracao:
            if q_neg not in perguntas_existentes:
                exemplos.append(Example(question=q_neg, answer=None, context=()))

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

    # Carrega a rede existente se já houver, para preservar conexões anteriores e continuar o treinamento
    if caminho_saida.exists() and caminho_saida.stat().st_size > 0:
        try:
            modelo = TokenGraph.load(caminho_saida)
            print(f"[INFO] Rede pré-existente carregada ({len(modelo.tokens)} tokens, {len(modelo.features)} features). Continuando aprendizado...")
        except Exception:
            modelo = TokenGraph()
    else:
        modelo = TokenGraph()

    # Treina em blocos de épocas com salvamento periódico (checkpointing) e checagem de parada
    stop_file = DIR_TREINO / ".stop_training"
    epocas_restantes = epochs
    passo = max(45, (epochs + 1) // 2)
    epoca_atual = 0
    historico = []

    try:
        while epocas_restantes > 0:
            if stop_file.exists():
                print(f"\n[PARADA DETECTADA] Interrompendo épocas restantes na época {epoca_atual}/{epochs} e salvando estado atual da rede...")
                break

            lote_epocas = min(passo, epocas_restantes)
            epoca_atual += lote_epocas
            epocas_restantes -= lote_epocas

            print(f"  -> Treinando épocas {epoca_atual - lote_epocas + 1} a {epoca_atual}/{epochs}...")
            relatorio = modelo.fit(exemplos, epochs=lote_epocas, learning_rate=learning_rate)
            historico.extend(relatorio)

            # Salva checkpoint da rede a cada bloco de épocas
            modelo.save(caminho_saida)
    except KeyboardInterrupt:
        print("\n[INTERROMPIDO] Salvando estado parcial da rede antes de encerrar...")
    finally:
        # Garante que o modelo SEMPRE seja salvo em disco, mesmo após cancelamento
        try:
            modelo.save(caminho_saida)
            tamanho = caminho_saida.stat().st_size if caminho_saida.exists() else 0
            print(f"[REDE SALVA COM SUCESSO] Pesos associativos gravados em: {caminho_saida} ({tamanho} bytes)")
            logging.info("Pesos gravados com sucesso em: %s (%d bytes)", caminho_saida, tamanho)
        except Exception as exc:
            logging.error("Erro ao salvar modelo: %s", exc)

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
