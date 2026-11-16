#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Módulo de Treinamento e Integração do NeuroGraph com dados curados do YouTube e IA.

Responsabilidades:
1. Carregar pares curados e validar rigorosamente sua integridade conceitual.
2. Mesclar de forma segura com a base de conhecimento fundamental do NeuroGraph.
3. Instanciar o TokenGraph (modelo autoregressivo em Python) e treinar novos pesos.
4. Descartar tokens órfãos/corrompidos caso o dataset tenha sido higienizado.
5. Salvar os pesos gerados no formato binário NGCTX007 (.ngs) e sincronizar a matriz (.ngm).
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path
from typing import Any

DIR_TREINO = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_TREINO.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"

if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))
if str(DIR_TREINO) not in sys.path:
    sys.path.insert(0, str(DIR_TREINO))

try:
    from model import EOS, REFUSE, Example, TokenGraph, tokenize
except ImportError as exc:
    logging.error("Não foi possível importar 'model' de %s: %s", DIR_CONTEXTUAL_V7, exc)
    raise

from curador_chatgpt import eh_par_conceitual_valido, normalizar_texto_neurograph

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

SAUDACOES_PERMITIDAS = frozenset({
    "oi", "olá", "ola", "bom dia", "boa tarde", "boa noite",
    "olá tudo bem", "oi como vai você", "como cumprimentar uma pessoa",
})


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
    """Carrega os pares extraídos e curados do YouTube/IA."""
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
    """Combina a base pré-existente e os novos fatos validados em objetos Example."""
    todos_dados: list[dict] = []
    perguntas_existentes: set[str] = set()

    if incluir_base:
        base = carregar_dados_base()
        for d in base:
            todos_dados.append(d)
            if d.get("question"):
                perguntas_existentes.add(d["question"].strip().lower())
        logging.info("Carregados %d exemplos da base pré-existente.", len(base))

    novos = carregar_dados_curados_youtube(caminho_curado)
    adicionados = 0
    ignorados_ruido = 0

    for item in novos:
        if not isinstance(item, dict):
            continue
        q = normalizar_texto_neurograph(item.get("question", ""))
        a = normalizar_texto_neurograph(item.get("answer", ""))
        if not q or not a or q in perguntas_existentes:
            continue

        # Permite saudações curtas ou pares conceituais que passam na validação rigorosa
        if q not in SAUDACOES_PERMITIDAS and not eh_par_conceitual_valido(q, a):
            ignorados_ruido += 1
            continue

        item_limpo = dict(item)
        item_limpo["question"] = q
        item_limpo["answer"] = a
        todos_dados.append(item_limpo)
        perguntas_existentes.add(q)
        adicionados += 1

    if ignorados_ruido > 0:
        logging.info("Filtrados %d pares com ruído/truncamento do dataset.", ignorados_ruido)
    logging.info("Adicionados %d novos exemplos curados válidos (Total: %d).", adicionados, len(todos_dados))

    exemplos: list[Example] = []
    tem_negativos = False
    for d in todos_dados:
        q = d.get("question", "").strip()
        a = d.get("answer")
        cat = d.get("category", "")
        raw_ctx = d.get("context", [])
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


def _calcular_tokens_ativos_exemplos(exemplos: list[Example]) -> set[str]:
    """Conjunto de todos os tokens de resposta legítimos presentes nos exemplos atuais."""
    ativos = {EOS, REFUSE}
    for ex in exemplos:
        if ex.answer is not None:
            ativos.update(tokenize(ex.answer))
    return ativos


def treinar_neurograph(
    exemplos: list[Example],
    epochs: int = 120,
    learning_rate: float = 0.05,
    caminho_saida: Path | None = None,
    regerar_limpo: bool = False,
    exportar_ngm: bool = True,
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
    logging.info(
        "Total de exemplos: %d | Épocas: %d | Taxa de Aprendizado: %.4f",
        len(exemplos),
        epochs,
        learning_rate,
    )

    tokens_validos = _calcular_tokens_ativos_exemplos(exemplos)
    modelo = TokenGraph()

    if not regerar_limpo and caminho_saida.exists() and caminho_saida.stat().st_size > 0:
        try:
            modelo_antigo = TokenGraph.load(caminho_saida)
            tokens_orfaos = set(modelo_antigo.tokens) - tokens_validos
            if tokens_orfaos:
                print(
                    f"[INFO] Removendo {len(tokens_orfaos)} tokens obsoletos/corrompidos da rede anterior "
                    f"e reconstruindo grafo limpo..."
                )
            else:
                modelo = modelo_antigo
                print(
                    f"[INFO] Rede pré-existente carregada ({len(modelo.tokens)} tokens, "
                    f"{len(modelo.features)} features). Continuando aprendizado..."
                )
        except Exception:
            modelo = TokenGraph()

    stop_file = DIR_TREINO / ".stop_training"
    epocas_restantes = epochs
    passo = max(45, (epochs + 1) // 2)
    epoca_atual = 0
    historico = []

    try:
        while epocas_restantes > 0:
            if stop_file.exists():
                print(
                    f"\n[PARADA DETECTADA] Interrompendo épocas restantes na época {epoca_atual}/{epochs} "
                    f"e salvando estado atual da rede..."
                )
                break

            lote_epocas = min(passo, epocas_restantes)
            epoca_atual += lote_epocas
            epocas_restantes -= lote_epocas

            print(f"  -> Treinando épocas {epoca_atual - lote_epocas + 1} a {epoca_atual}/{epochs}...")
            relatorio = modelo.fit(exemplos, epochs=lote_epocas, learning_rate=learning_rate)
            historico.extend(relatorio)

            modelo.save(caminho_saida)
    except KeyboardInterrupt:
        print("\n[INTERROMPIDO] Salvando estado parcial da rede antes de encerrar...")
    finally:
        try:
            if not modelo.edges:
                logging.warning("Modelo sem arestas treinadas; salvamento ignorado para não sobrescrever arquivo anterior.")
                return modelo
            modelo.save(caminho_saida)
            tamanho = caminho_saida.stat().st_size if caminho_saida.exists() else 0
            print(f"[REDE SALVA COM SUCESSO] Pesos associativos gravados em: {caminho_saida} ({tamanho} bytes)")
            logging.info("Pesos gravados com sucesso em: %s (%d bytes)", caminho_saida, tamanho)

            if exportar_ngm:
                try:
                    from treino_continuo import exportar_matriz_ngm_de_modelo

                    exportar_matriz_ngm_de_modelo(modelo, caminho_saida.with_suffix(".ngm"), incluir_vocab_base=True)
                    caminho_ngm_raiz = DIR_NEUROGRAPH / "neurograph_memoria_ptbr_inibida_completa.ngm"
                    if caminho_ngm_raiz.resolve() != caminho_saida.with_suffix(".ngm").resolve():
                        exportar_matriz_ngm_de_modelo(modelo, caminho_ngm_raiz, incluir_vocab_base=True)
                except Exception as exc_ngm:
                    logging.warning("Aviso ao exportar matriz .ngm companheira: %s", exc_ngm)
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
        modelo = treinar_neurograph(exemplos[:60], epochs=50)
        testar_inferencia(modelo, [
            "o que é um computador",
            "o que é um cachorro",
            "o que é um painel solar",
        ])
    else:
        print("Nenhum exemplo disponível para treino.")
