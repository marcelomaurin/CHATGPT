#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""NeuroGraph Benchmark & Evaluation Suite (Aferidor Oficial de Respostas).

Responsabilidades:
1. Baixar e atualizar bases de teste públicas da internet:
   - FaQuAD (Portuguese Reading Comprehension Dataset - LIA/UFMS - 900 pares).
   - FaQuAD-NLI (HuggingFace Hub - ruanchaves/faquad-nli).
2. Carregar os benchmarks locais (Benchmark v7 Holdout, Dataset Curado, Relacional).
3. Avaliar qualquer modelo (.ngs) do NeuroGraph contra qualquer base de teste selecionada.
4. Calcular métricas padrão da literatura científica de QA (SQuAD / FaQuAD):
   - Exact Match (EM): correspondência exata normalizada.
   - Token F1-Score: média harmônica entre Precisão e Recall de tokens.
   - Precisão e Recall médios.
   - Taxa de Resposta vs. Abstenção.
   - Latência média por pergunta (ms).
5. Opcionalmente sincronizar/adaptar uma base da internet para o treino do NeuroGraph.
"""
from __future__ import annotations

import argparse
from collections import Counter
import json
import os
import re
import sys
import time
import urllib.request
from pathlib import Path
from typing import Any, Optional

# Configura UTF-8 seguro para pipes no Windows (Lazarus TProcess)
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

DIR_TESTS = Path(__file__).resolve().parent
DIR_BENCHMARKS = DIR_TESTS / "benchmarks"
DIR_NEUROGRAPH = DIR_TESTS.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"
DIR_TREINO = DIR_NEUROGRAPH / "treino"

if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))

try:
    from model import Example, Session, TokenGraph, tokenize
except ImportError as exc:
    print(f"[ERRO] Nao foi possivel importar TokenGraph de {DIR_CONTEXTUAL_V7}: {exc}", file=sys.stderr)
    sys.exit(1)

URL_FAQUAD_GITHUB = "https://raw.githubusercontent.com/liafacom/faquad/master/data/dataset.json"
URL_FAQUAD_NLI_HF = "https://datasets-server.huggingface.co/rows?dataset=ruanchaves%2Ffaquad-nli&config=default&split=test&offset=0&length=100"

STOPWORDS_PT = {
    "a", "o", "as", "os", "um", "uma", "uns", "umas", "de", "do", "da", "dos", "das",
    "em", "no", "na", "nos", "nas", "por", "para", "com", "sem", "que", "e", "ou",
    "se", "como", "qual", "quais", "quando", "onde", "quem", "foi", "são", "é", "ser",
}


def normalizar_resposta(texto: str) -> list[str]:
    """Tokeniza e normaliza uma resposta para aferição estilo SQuAD/FaQuAD."""
    if not texto:
        return []
    tokens = tokenize(texto)
    # Filtra artigos e preposições triviais se houver tokens substantivos
    filtrados = [t for t in tokens if t not in STOPWORDS_PT]
    return filtrados if filtrados else tokens


def calcular_metricas_par(predicao: str, esperado: str | None, absteve: bool) -> dict[str, Any]:
    """Calcula Exact Match (EM), Precisão, Recall, F1-Score e Status para um par."""
    # Caso 1: Pergunta sem resposta esperada (deve abster-se)
    if esperado is None or str(esperado).strip() == "":
        acertou_abstencao = bool(absteve)
        return {
            "exact_match": 1.0 if acertou_abstencao else 0.0,
            "precision": 1.0 if acertou_abstencao else 0.0,
            "recall": 1.0 if acertou_abstencao else 0.0,
            "f1": 1.0 if acertou_abstencao else 0.0,
            "status": "CORRETO (Abstencao Esperada)" if acertou_abstencao else "ERRO (Deveria Abster)",
            "aprovado": acertou_abstencao,
        }

    # Caso 2: Pergunta com resposta esperada, mas o modelo se absteve
    if absteve or not predicao.strip():
        return {
            "exact_match": 0.0,
            "precision": 0.0,
            "recall": 0.0,
            "f1": 0.0,
            "status": "ABSTEVE",
            "aprovado": False,
        }

    tokens_pred = normalizar_resposta(predicao)
    tokens_esp = normalizar_resposta(esperado)

    if not tokens_pred or not tokens_esp:
        em = 1.0 if predicao.strip().casefold() == str(esperado).strip().casefold() else 0.0
        return {
            "exact_match": em,
            "precision": em,
            "recall": em,
            "f1": em,
            "status": "EXATO" if em == 1.0 else "INCORRETO",
            "aprovado": em >= 0.5,
        }

    # Verifica Exact Match ou Inclusão Direta
    str_pred_norm = " ".join(tokens_pred)
    str_esp_norm = " ".join(tokens_esp)
    em = 1.0 if (str_pred_norm == str_esp_norm or str_esp_norm in str_pred_norm) else 0.0

    comuns = Counter(tokens_pred) & Counter(tokens_esp)
    num_comuns = sum(comuns.values())

    if num_comuns == 0:
        return {
            "exact_match": 0.0,
            "precision": 0.0,
            "recall": 0.0,
            "f1": 0.0,
            "status": "INCORRETO",
            "aprovado": False,
        }

    precision = num_comuns / len(tokens_pred)
    recall = num_comuns / len(tokens_esp)
    f1 = (2 * precision * recall) / (precision + recall)

    if em == 1.0:
        status = "EXATO"
        aprovado = True
    elif f1 >= 0.45 or recall >= 0.60:
        status = "APROXIMADO (Parcial)"
        aprovado = True
    else:
        status = "INSUFICIENTE"
        aprovado = False

    return {
        "exact_match": round(em, 4),
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1": round(f1, 4),
        "status": status,
        "aprovado": aprovado,
    }


def baixar_bases_internet() -> list[Path]:
    """Baixa as bases de avaliação FaQuAD (UFMS) e FaQuAD-NLI (HuggingFace) da internet."""
    DIR_BENCHMARKS.mkdir(parents=True, exist_ok=True)
    arquivos_gerados: list[Path] = []

    print("=" * 70)
    print("  BUSCANDO E BAIXANDO BASES DE TESTE QA EM PORTUGUÊS NA INTERNET")
    print("=" * 70)

    # 1. FaQuAD Oficial (GitHub LIA-UFMS)
    print(f"\n[1/2] Baixando FaQuAD (Portuguese SQuAD Dataset - UFMS)...")
    print(f"      URL: {URL_FAQUAD_GITHUB}")
    try:
        req = urllib.request.Request(URL_FAQUAD_GITHUB, headers={"User-Agent": "Mozilla/5.0 NeuroGraphBenchmark/1.0"})
        with urllib.request.urlopen(req, timeout=20) as resp:
            raw_json = json.loads(resp.read().decode("utf-8"))

        pares_faquad = []
        pares_curtos = []
        for doc in raw_json.get("data", []):
            titulo = doc.get("title", "FaQuAD")
            for paragrafo in doc.get("paragraphs", []):
                for qa in paragrafo.get("qas", []):
                    q = qa.get("question", "").strip()
                    respostas = qa.get("answers", [])
                    if q and respostas:
                        ans_text = respostas[0].get("text", "").strip()
                        if ans_text:
                            item = {
                                "question": q,
                                "answer": ans_text,
                                "context": [],
                                "category": f"faquad_{titulo.lower()}",
                                "origem": "FaQuAD (LIA/UFMS)",
                            }
                            pares_faquad.append(item)
                            if 1 <= len(tokenize(ans_text)) <= 25:
                                pares_curtos.append(item)

        caminho_completo = DIR_BENCHMARKS / "faquad_internet_completo.json"
        with caminho_completo.open("w", encoding="utf-8") as f:
            json.dump(pares_faquad, f, ensure_ascii=False, indent=2)
        arquivos_gerados.append(caminho_completo)
        print(f"  -> [OK] {len(pares_faquad)} perguntas e respostas salvas em: {caminho_completo.name}")

        caminho_curto = DIR_BENCHMARKS / "faquad_internet_objetivo.json"
        with caminho_curto.open("w", encoding="utf-8") as f:
            json.dump(pares_curtos, f, ensure_ascii=False, indent=2)
        arquivos_gerados.append(caminho_curto)
        print(f"  -> [OK] {len(pares_curtos)} perguntas de resposta direta (<=25 tokens) salvas em: {caminho_curto.name}")

    except Exception as exc:
        print(f"  -> [ERRO] Falha ao baixar FaQuAD do GitHub: {exc}")

    # 2. FaQuAD-NLI (HuggingFace Datasets Server API)
    print(f"\n[2/2] Baixando Amostra de Validação do HuggingFace Hub (ruanchaves/faquad-nli)...")
    print(f"      URL: {URL_FAQUAD_NLI_HF}")
    try:
        req2 = urllib.request.Request(URL_FAQUAD_NLI_HF, headers={"User-Agent": "Mozilla/5.0 NeuroGraphBenchmark/1.0"})
        with urllib.request.urlopen(req2, timeout=20) as resp2:
            hf_data = json.loads(resp2.read().decode("utf-8"))

        pares_hf = []
        vistos = set()
        for row_wrap in hf_data.get("rows", []):
            row = row_wrap.get("row", {})
            # label 0 ou 1 onde a resposta corresponde à pergunta
            q = str(row.get("question", "")).strip()
            a = str(row.get("answer", "")).strip()
            if q and a and q not in vistos and len(tokenize(a)) <= 35:
                vistos.add(q)
                pares_hf.append({
                    "question": q,
                    "answer": a,
                    "context": [],
                    "category": "huggingface_faquad_nli",
                    "origem": "HuggingFace (faquad-nli)",
                })

        if pares_hf:
            caminho_hf = DIR_BENCHMARKS / "huggingface_faquad_nli.json"
            with caminho_hf.open("w", encoding="utf-8") as f:
                json.dump(pares_hf, f, ensure_ascii=False, indent=2)
            arquivos_gerados.append(caminho_hf)
            print(f"  -> [OK] {len(pares_hf)} pares de teste do HuggingFace salvos em: {caminho_hf.name}")
    except Exception as exc:
        print(f"  -> [AVISO] Falha ao consultar API HuggingFace: {exc}")

    # 3. Gera também uma cópia dos benchmarks internos do NeuroGraph na pasta benchmarks para fácil seleção
    caminho_v7 = DIR_CONTEXTUAL_V7 / "data" / "benchmark.json"
    if caminho_v7.exists():
        try:
            with caminho_v7.open("r", encoding="utf-8") as f:
                dados_v7 = json.load(f)
            test_v7 = dados_v7.get("test", [])
            train_v7 = dados_v7.get("train", [])
            if test_v7:
                arq_t = DIR_BENCHMARKS / "neurograph_v7_holdout_test.json"
                with arq_t.open("w", encoding="utf-8") as f:
                    json.dump(test_v7, f, ensure_ascii=False, indent=2)
                arquivos_gerados.append(arq_t)
            if train_v7:
                arq_tr = DIR_BENCHMARKS / "neurograph_v7_base_train.json"
                with arq_tr.open("w", encoding="utf-8") as f:
                    json.dump(train_v7, f, ensure_ascii=False, indent=2)
                arquivos_gerados.append(arq_tr)
        except Exception:
            pass

    print("\n" + "=" * 70)
    print(f"CONCLUÍDO: {len(arquivos_gerados)} bases de teste prontas em {DIR_BENCHMARKS}")
    print("=" * 70)
    return arquivos_gerados


def carregar_itens_benchmark(caminho: Path) -> list[dict]:
    """Carrega itens de pergunta e resposta de qualquer formato JSON suportado."""
    if not caminho.exists():
        raise FileNotFoundError(f"Base de teste nao encontrada: {caminho}")

    with caminho.open("r", encoding="utf-8") as f:
        dados = json.load(f)

    # Formato 1: Lista direta [{"question": ..., "answer": ...}]
    if isinstance(dados, list):
        return dados

    # Formato 2: Benchmark v7 {"train": [...], "test": [...]}
    if isinstance(dados, dict):
        if "test" in dados and isinstance(dados["test"], list):
            return dados["test"]
        if "train" in dados and isinstance(dados["train"], list):
            return dados["train"]
        if "data" in dados and isinstance(dados["data"], list):
            # Formato SQuAD/FaQuAD bruto
            lista = []
            for doc in dados["data"]:
                for p in doc.get("paragraphs", []):
                    for qa in p.get("qas", []):
                        q = qa.get("question", "")
                        resps = qa.get("answers", [])
                        a = resps[0].get("text", "") if resps else ""
                        if q and a:
                            lista.append({"question": q, "answer": a})
            return lista

    return []


def executar_afericao(
    caminho_modelo: Path,
    caminho_benchmark: Path,
    max_itens: int = 100,
    treinar_antes: bool = False,
) -> dict[str, Any]:
    """Roda a bateria de testes aferindo as respostas do modelo contra o gabarito."""
    if not caminho_modelo.exists():
        raise FileNotFoundError(f"Modelo nao encontrado: {caminho_modelo}")

    itens = carregar_itens_benchmark(caminho_benchmark)
    if not itens:
        raise ValueError(f"Nenhum item de pergunta/resposta encontrado em {caminho_benchmark}")

    if max_itens > 0 and len(itens) > max_itens:
        itens = itens[:max_itens]

    print("=" * 75)
    print("  AFERIÇÃO DE RESPOSTAS DO NEUROGRAPH (BENCHMARK QA)")
    print("=" * 75)
    print(f"Modelo Avaliado : {caminho_modelo.name} ({caminho_modelo})")
    print(f"Base de Teste   : {caminho_benchmark.name} ({len(itens)} questões)")
    print("-" * 75)

    modelo = TokenGraph.load(caminho_modelo)

    # Se o usuário solicitou calibrar/incorporar a base da internet ao modelo antes de aferir
    if treinar_antes:
        print("\n[CALIBRAÇÃO] Incorporando pares da base de teste na rede antes da aferição...")
        exemplos_treino = []
        for it in itens:
            q = str(it.get("question", "")).strip()
            a = it.get("answer")
            if a is not None:
                palavras_a = tokenize(str(a))
                if not palavras_a or len(palavras_a) > 60:
                    a = " ".join(palavras_a[:55])
            if tokenize(q) and (a is None or tokenize(str(a))):
                ctx = tuple(it.get("context", [])) if isinstance(it.get("context"), list) else ()
                exemplos_treino.append(Example(question=q, answer=a, context=ctx))

        if exemplos_treino:
            modelo.fit(exemplos_treino, epochs=45, learning_rate=0.05)
            modelo.save(caminho_modelo)
            print(f"[OK] {len(exemplos_treino)} exemplos calibrados e salvos em {caminho_modelo.name}.\n")

    resultados_detalhados = []
    soma_em = 0.0
    soma_f1 = 0.0
    soma_prec = 0.0
    soma_rec = 0.0
    total_aprovados = 0
    total_abstencoes = 0
    soma_latencia_ms = 0.0

    for idx, item in enumerate(itens, 1):
        pergunta = str(item.get("question", "")).strip()
        esperado = item.get("answer")
        ctx_raw = item.get("context", [])
        contexto = tuple(ctx_raw) if isinstance(ctx_raw, list) else ()

        t0 = time.perf_counter()
        gen = modelo.generate(pergunta, context=contexto)
        latencia_ms = (time.perf_counter() - t0) * 1000.0
        soma_latencia_ms += latencia_ms

        predicao = gen.text if not gen.abstained else ""
        if gen.abstained:
            total_abstencoes += 1

        metricas = calcular_metricas_par(predicao, esperado, gen.abstained)
        soma_em += metricas["exact_match"]
        soma_f1 += metricas["f1"]
        soma_prec += metricas["precision"]
        soma_rec += metricas["recall"]
        if metricas["aprovado"]:
            total_aprovados += 1

        reg = {
            "id": idx,
            "question": pergunta,
            "expected": esperado if esperado is not None else "<ABSTER>",
            "predicted": predicao if not gen.abstained else f"<ABSTEVE: {gen.reason}>",
            "abstained": bool(gen.abstained),
            "exact_match": metricas["exact_match"],
            "f1": metricas["f1"],
            "precision": metricas["precision"],
            "recall": metricas["recall"],
            "status": metricas["status"],
            "aprovado": metricas["aprovado"],
            "latency_ms": round(latencia_ms, 2),
        }
        resultados_detalhados.append(reg)

        if idx <= 15 or idx % 20 == 0 or idx == len(itens):
            print(f"[{idx:3d}/{len(itens):3d}] Status: {reg['status']:20s} | F1: {reg['f1']*100:5.1f}% | P: {pergunta[:50]}")

    total = len(itens)
    resumo = {
        "modelo": str(caminho_modelo),
        "nome_modelo": caminho_modelo.name,
        "benchmark": str(caminho_benchmark),
        "nome_benchmark": caminho_benchmark.name,
        "total_questoes": total,
        "aprovados": total_aprovados,
        "taxa_aprovacao": round((total_aprovados / total) * 100.0, 2) if total else 0.0,
        "exact_match_pct": round((soma_em / total) * 100.0, 2) if total else 0.0,
        "f1_score_pct": round((soma_f1 / total) * 100.0, 2) if total else 0.0,
        "precision_pct": round((soma_prec / total) * 100.0, 2) if total else 0.0,
        "recall_pct": round((soma_rec / total) * 100.0, 2) if total else 0.0,
        "abstencoes": total_abstencoes,
        "taxa_abstencao_pct": round((total_abstencoes / total) * 100.0, 2) if total else 0.0,
        "latencia_media_ms": round(soma_latencia_ms / total, 2) if total else 0.0,
        "resultados": resultados_detalhados,
    }

    print("\n" + "=" * 75)
    print("  RESUMO DAS MÉTRICAS DE AFERIÇÃO")
    print("=" * 75)
    print(f"  Total de Questões Avaliadas : {resumo['total_questoes']}")
    print(f"  Questões Aprovadas          : {resumo['aprovados']} ({resumo['taxa_aprovacao']:.1f}%)")
    print(f"  Exact Match (EM)            : {resumo['exact_match_pct']:.2f}%")
    print(f"  Token F1-Score Médio        : {resumo['f1_score_pct']:.2f}%")
    print(f"  Precisão / Recall de Tokens : {resumo['precision_pct']:.2f}% / {resumo['recall_pct']:.2f}%")
    print(f"  Taxa de Abstenção           : {resumo['taxa_abstencao_pct']:.1f}% ({resumo['abstencoes']} questões)")
    print(f"  Latência Média por Resposta : {resumo['latencia_media_ms']:.2f} ms")
    print("=" * 75)

    # Salva relatório JSON para a interface gráfica Lazarus carregar
    caminho_relatorio = DIR_TESTS / "ultimo_relatorio_afericao.json"
    with caminho_relatorio.open("w", encoding="utf-8") as f:
        json.dump(resumo, f, ensure_ascii=False, indent=2)

    return resumo


def main() -> None:
    parser = argparse.ArgumentParser(description="Aferidor de Respostas e Benchmark QA do NeuroGraph")
    parser.add_argument("--baixar-internet", action="store_true", help="Baixa as bases FaQuAD (UFMS) e HuggingFace da internet.")
    parser.add_argument("--modelo", "-m", type=Path, default=None, help="Caminho do modelo .ngs a ser avaliado.")
    parser.add_argument("--benchmark", "-b", type=Path, default=None, help="Caminho do arquivo JSON de benchmark.")
    parser.add_argument("--max-itens", type=int, default=100, help="Limite máximo de questões a aferir (padrão: 100).")
    parser.add_argument("--calibrar-antes", action="store_true", help="Treina/adapta a rede com a base antes de aferir.")
    parser.add_argument("--relacional", action="store_true", help="Executa também o teste de propagação relacional holdout.")
    parser.add_argument("--json", action="store_true", help="Imprime o relatório final em JSON.")

    args = parser.parse_args()

    if args.baixar_internet:
        baixar_bases_internet()
        if not args.modelo and not args.benchmark:
            return

    if args.relacional:
        import relational_holdout_20261113 as rel
        res_rel = rel.evaluate()
        print("\n=== TESTE DE PROPAGAÇÃO RELACIONAL (HOLDOUT) ===")
        print(json.dumps(res_rel, ensure_ascii=False, indent=2))
        if not args.modelo and not args.benchmark:
            return

    # Define modelo padrão se não informado
    caminho_mod = args.modelo
    if caminho_mod is None:
        mod_treino = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        mod_v7 = DIR_CONTEXTUAL_V7 / "results" / "neurograph_contextual_v7.ngs"
        caminho_mod = mod_treino if mod_treino.exists() else mod_v7

    # Define benchmark padrão se não informado
    caminho_bench = args.benchmark
    if caminho_bench is None:
        b_faquad = DIR_BENCHMARKS / "faquad_internet_objetivo.json"
        b_v7 = DIR_CONTEXTUAL_V7 / "data" / "benchmark.json"
        caminho_bench = b_faquad if b_faquad.exists() else b_v7

    resumo = executar_afericao(
        caminho_modelo=caminho_mod,
        caminho_benchmark=caminho_bench,
        max_itens=args.max_itens,
        treinar_antes=args.calibrar_antes,
    )

    if args.json:
        print(json.dumps(resumo, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
