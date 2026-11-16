#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Motor de Treino Contínuo (IA + YouTube em Português) e Regeneração de Matrizes (.ngm / .ngs).

Responsabilidades:
1. Pesquisar continuamente assuntos educativos em português usando IA + YouTube.
2. Utilizar o provedor LLM configurado no neurograph_studio.ini (Local Ollama/llama.cpp ou OpenAI).
3. Filtrar rigorosamente APENAS conteúdo válido e gramaticalmente íntegro em língua portuguesa.
4. Higienizar automaticamente o dataset contra pares truncados ou tautológicos ("X é X é...").
5. Treinar a rede alvo (.ngs) e regerar a matriz binária (.ngm) a cada ciclo sem duplicações.
"""
from __future__ import annotations

import json
import logging
import os
import struct
import subprocess
import sys
import time
from pathlib import Path
from typing import Any

if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

DIR_TREINO = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_TREINO.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"

if str(DIR_NEUROGRAPH) not in sys.path:
    sys.path.insert(0, str(DIR_NEUROGRAPH))
if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))
if str(DIR_TREINO) not in sys.path:
    sys.path.insert(0, str(DIR_TREINO))

from capturador_youtube import (
    buscar_videos_youtube,
    eh_texto_em_portugues,
    obter_transcricao,
    salvar_transcricao_raw,
)
from curador_chatgpt import (
    ParTreinamento,
    carregar_config_llm_ini,
    curar_transcricao_com_chatgpt,
    eh_par_conceitual_valido,
    extrair_pares_heuristicos,
    normalizar_texto_neurograph,
    requisitar_chat_llm,
    salvar_pares_processados,
    sugerir_referencias_em_portugues,
    tem_ia_ativa,
)
from gerar_memoria_inibida import GROUPS as GRUPOS_VOCABULARIO_BASE
from treinar_10_topicos import (
    gerar_lote_com_chatgpt,
    gerar_lote_heuristico,
    gerar_um_item_chatgpt,
)
from treinador_neurograph import SAUDACOES_PERMITIDAS, preparar_exemplos, treinar_neurograph

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

SUBTEMAS_EXPANSAO_PT = [
    "fundamentos e princípios básicos",
    "aplicações práticas no cotidiano",
    "funcionamento técnico e componentes",
    "história e evolução tecnológica",
    "eficiência segurança e manutenção",
    "conceitos avançados e inovação",
    "arquitetura de sistemas e sensores",
    "diagnóstico e resolução de problemas",
]

CATALOGO_ASSUNTOS_CONTINUOS_PT = [
    "Inteligência Artificial e Redes Neurais Profundas",
    "Energia Solar Fotovoltaica e Inversores",
    "Eletrônica Digital e Microcontroladores",
    "Automação Industrial e Sensores Embarcados",
    "Ciência da Computação e Estruturas de Dados",
    "Redes de Computadores e Protocolos de Internet",
    "Biologia Celular Genética e Biotecnologia",
    "Física Elétrica Magnetismo e Termodinâmica",
    "Astronomia Sistema Solar e Astrofísica",
    "Química Geral Materiais e Reações Químicas",
    "Geografia do Brasil Clima e Meio Ambiente",
    "História do Brasil Ciência e Sociedade",
    "Matemática Aplicada Estatística e Lógica",
    "Robótica Móvel Visão Computacional e Controle",
    "Sistemas Operacionais Linux e Programação",
    "Engenharia Biomédica e Equipamentos Médicos",
]
ASSUNTOS_SEMENTE_PT = CATALOGO_ASSUNTOS_CONTINUOS_PT


def higienizar_datasets_processados() -> dict[str, int]:
    """Remove pares corrompidos, truncados ou tautológicos ('X é X é...') de dataset_curado.json
    e ultimo_treino_topicos.json, preservando apenas fatos conceituais válidos.
    """
    pasta_proc = DIR_TREINO / "dados" / "processados"
    resumo = {"removidos_curado": 0, "mantidos_curado": 0, "removidos_topicos": 0, "mantidos_topicos": 0}
    if not pasta_proc.exists():
        return resumo

    for chave_rem, chave_mant, nome_arq in (
        ("removidos_curado", "mantidos_curado", "dataset_curado.json"),
        ("removidos_topicos", "mantidos_topicos", "ultimo_treino_topicos.json"),
    ):
        caminho = pasta_proc / nome_arq
        if not caminho.exists():
            continue
        try:
            itens = json.loads(caminho.read_text(encoding="utf-8", errors="replace"))
            if not isinstance(itens, list):
                continue
            limpos = []
            vistos: set[str] = set()
            removidos = 0
            for it in itens:
                if not isinstance(it, dict):
                    removidos += 1
                    continue
                q = normalizar_texto_neurograph(it.get("question", ""))
                a = normalizar_texto_neurograph(it.get("answer", ""))
                if not q or not a or q in vistos:
                    removidos += 1
                    continue
                if q in SAUDACOES_PERMITIDAS or eh_par_conceitual_valido(q, a):
                    it_novo = dict(it)
                    it_novo["question"] = q
                    it_novo["answer"] = a
                    limpos.append(it_novo)
                    vistos.add(q)
                else:
                    removidos += 1

            resumo[chave_rem] = removidos
            resumo[chave_mant] = len(limpos)
            if removidos > 0:
                caminho.write_text(json.dumps(limpos, ensure_ascii=False, indent=2), encoding="utf-8")
                logging.info(
                    "Dataset '%s' higienizado: %d pares inválidos removidos, %d pares válidos preservados.",
                    nome_arq,
                    removidos,
                    len(limpos),
                )
        except Exception as exc:
            logging.warning("Aviso ao higienizar %s: %s", nome_arq, exc)

    return resumo


def gerar_pares_para_topico(
    topico: str,
    qtd_alvo: int = 6,
    api_key: str | None = None,
    perguntas_globais: set[str] | None = None,
) -> list[ParTreinamento]:
    """Gera pares conceituais em português para um tópico usando a IA configurada no INI ou base verificada."""
    vistos = set(perguntas_globais or set())
    resultados: list[ParTreinamento] = []
    ia_disponivel = tem_ia_ativa(api_key)

    # 1. Tenta geração em lote via LLM configurado (OpenAI ou servidor local do INI)
    if ia_disponivel:
        lote_ia = gerar_lote_com_chatgpt(topico, qtd_desejada=max(4, qtd_alvo), api_key=api_key)
        for p in lote_ia:
            if p.question not in vistos and eh_par_conceitual_valido(p.question, p.answer):
                vistos.add(p.question)
                resultados.append(p)
                if len(resultados) >= qtd_alvo:
                    return resultados

    # 2. Complementa com a base conceitual verificada (ou itens unitários da IA)
    pool_heur = gerar_lote_heuristico(topico, max(12, qtd_alvo + 15))
    idx_h = 0

    for num_item in range(len(resultados) + 1, max(1, qtd_alvo) + 1):
        par: ParTreinamento | None = None
        if ia_disponivel and len(resultados) == 0:
            par = gerar_um_item_chatgpt(topico, num_item, vistos, api_key=api_key)
            if par and not eh_par_conceitual_valido(par.question, par.answer):
                par = None

        while par is None and idx_h < len(pool_heur):
            cand = pool_heur[idx_h]
            idx_h += 1
            if cand.question not in vistos and eh_par_conceitual_valido(cand.question, cand.answer):
                par = cand
                break

        if par is not None:
            vistos.add(par.question)
            resultados.append(par)

    return resultados


def exportar_matriz_ngm_de_modelo(
    modelo: Any,
    caminho_ngm: Path,
    incluir_vocab_base: bool = True,
) -> dict[str, int]:
    """Gera o arquivo de matriz binária (.ngm - formato NGMAP001 + extensão de pesos)
    compatível com NeuroGraphStore.pas, NeuroGraphEngine.pas e o equipamento alvo.
    """
    caminho_ngm = Path(caminho_ngm).resolve()
    caminho_ngm.parent.mkdir(parents=True, exist_ok=True)

    tokens_unicos: list[str] = []
    vistos: set[str] = set()

    if incluir_vocab_base:
        for grupo in GRUPOS_VOCABULARIO_BASE:
            for tok in grupo.split():
                t_norm = tok.strip()
                if t_norm and t_norm not in vistos:
                    vistos.add(t_norm)
                    tokens_unicos.append(t_norm)

    for tok in getattr(modelo, "tokens", []):
        if tok and tok not in vistos:
            vistos.add(tok)
            tokens_unicos.append(tok)

    mapa_tok_id = {t: idx for idx, t in enumerate(tokens_unicos)}
    id_mod_para_ngm = {
        idx_m: mapa_tok_id[tok]
        for idx_m, tok in enumerate(getattr(modelo, "tokens", []))
        if tok in mapa_tok_id
    }

    arestas_dict: dict[tuple[int, int], float] = {}
    features = getattr(modelo, "features", [])
    edges = getattr(modelo, "edges", {})

    for feat_id, lista_adj in edges.items():
        if feat_id < 0 or feat_id >= len(features):
            continue
        feat = features[feat_id]
        if not feat or len(feat) < 2:
            continue
        tipo = feat[0]
        if tipo not in ("q", "prev", "context", "memory"):
            continue
        tok_origem = feat[1]
        if tok_origem not in mapa_tok_id:
            continue
        src_id = mapa_tok_id[tok_origem]
        fator = 1.0 if tipo in ("q", "prev") else 0.65

        for tgt_mod_id, peso in lista_adj:
            tgt_id = id_mod_para_ngm.get(tgt_mod_id, -1)
            if tgt_id < 0 or tgt_id == src_id:
                continue
            chave = (src_id, tgt_id)
            novo_peso = arestas_dict.get(chave, 0.0) + float(peso) * fator
            if novo_peso > 16.0:
                novo_peso = 16.0
            elif novo_peso < -16.0:
                novo_peso = -16.0
            arestas_dict[chave] = novo_peso

    arestas_lista = [
        (s, t, w) for (s, t), w in sorted(arestas_dict.items()) if abs(w) >= 0.005
    ]

    n_tokens = len(tokens_unicos)
    n_edges = len(arestas_lista)

    tmp_path = caminho_ngm.with_suffix(".ngm.tmp")
    with tmp_path.open("wb") as f:
        f.write(b"NGMAP001")
        f.write(struct.pack("<II", n_tokens, n_edges))
        for tok in tokens_unicos:
            raw_tok = tok.encode("utf-8")
            f.write(struct.pack("<I", len(raw_tok)))
            f.write(raw_tok)
        for src_id, tgt_id, peso in arestas_lista:
            f.write(struct.pack("<IIf", src_id, tgt_id, float(peso)))

        if hasattr(modelo, "_bytes"):
            try:
                f.write(modelo._bytes())
            except Exception:
                pass

    os.replace(tmp_path, caminho_ngm)
    tamanho = caminho_ngm.stat().st_size if caminho_ngm.exists() else 0
    print(
        f"[MATRIZ NGM ATUALIZADA] {caminho_ngm.name} -> {n_tokens} tokens, "
        f"{n_edges} conexões sinápticas ativas ({tamanho} bytes)"
    )
    return {
        "tokens": n_tokens,
        "edges": n_edges,
        "bytes": tamanho,
    }


def consolidar_arquivos_raw_em_portugues() -> int:
    """Varre os arquivos brutos em dados/raw e extrai apenas definições conceituais válidas."""
    pasta_raw = DIR_TREINO / "dados" / "raw"
    pasta_proc = DIR_TREINO / "dados" / "processados"
    if not pasta_raw.exists():
        return 0

    novos_pares: list[ParTreinamento] = []
    for arq in sorted(pasta_raw.glob("*.json")):
        try:
            dados = json.loads(arq.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            continue

        texto = dados.get("raw_text") or dados.get("texto") or ""
        if not texto or not eh_texto_em_portugues(texto, min_palavras=10):
            continue

        origem_id = dados.get("video_id") or dados.get("arquivo") or arq.stem
        titulo = dados.get("title") or dados.get("query") or ""
        cat = "youtube_curated" if arq.name.startswith("transcricao_") else "pdf_curated"
        extraidos = extrair_pares_heuristicos(texto, max_pares=6, titulo_video=str(titulo))
        for item in extraidos:
            q = normalizar_texto_neurograph(item.get("question", ""))
            a = normalizar_texto_neurograph(item.get("answer", ""))
            if q and a and eh_par_conceitual_valido(q, a):
                novos_pares.append(
                    ParTreinamento(
                        question=q,
                        answer=a,
                        context=[],
                        category=cat,
                        video_id=str(origem_id),
                        origem="acervo_raw_ptbr",
                    )
                )

    if novos_pares:
        salvar_pares_processados(novos_pares, pasta_proc)
    return len(novos_pares)


def regerar_matrizes_ngm_existentes(
    epochs: int = 120,
    learning_rate: float = 0.05,
) -> dict[str, Any]:
    """Higieniza os datasets e regera todas as matrizes (.ngm) e modelos (.ngs) do projeto."""
    stop_file = DIR_TREINO / ".stop_training"
    if stop_file.exists():
        try:
            stop_file.unlink()
        except Exception:
            pass

    print("\n" + "=" * 72)
    print("=== REGERANDO MATRIZES DA IA (.NGM / .NGS) DOS ARQUIVOS EXISTENTES ===")
    print("=" * 72)

    # 0. Higieniza datasets removendo ruídos e pares corrompidos
    info_hig = higienizar_datasets_processados()
    if info_hig["removidos_curado"] > 0 or info_hig["removidos_topicos"] > 0:
        print(
            f"[0/4] Higienização concluída: -{info_hig['removidos_curado']} pares inválidos do dataset_curado "
            f"({info_hig['mantidos_curado']} válidos preservados)."
        )

    # 1. Garante que todos os assuntos configurados no INI tenham pares conceituais limpos no dataset
    pasta_proc = DIR_TREINO / "dados" / "processados"
    assuntos_ini = carregar_assuntos_do_ini() or list(CATALOGO_ASSUNTOS_CONTINUOS_PT)
    pares_base_assuntos: list[ParTreinamento] = []
    for assunto in assuntos_ini:
        pares_base_assuntos.extend(gerar_lote_heuristico(assunto, qtd_desejada=8))
    if pares_base_assuntos:
        salvar_pares_processados(pares_base_assuntos, pasta_proc, nome_arquivo="dataset_curado.json")
        salvar_pares_processados(pares_base_assuntos, pasta_proc, nome_arquivo="ultimo_treino_topicos.json")

    # 2. Consolida quaisquer transcrições/PDFs em português da pasta dados/raw
    extra_raw = consolidar_arquivos_raw_em_portugues()
    print(f"[1/4] Acervo bruto (dados/raw) verificado em PT-BR (+{extra_raw} definições válidas).")

    # 3. Mescla ultimo_treino_topicos.json no dataset_curado.json (filtrando apenas válidos)
    arq_topicos = pasta_proc / "ultimo_treino_topicos.json"
    arq_curado = pasta_proc / "dataset_curado.json"

    if arq_topicos.exists():
        try:
            itens_top = json.loads(arq_topicos.read_text(encoding="utf-8"))
            pares_top = []
            for it in itens_top:
                q = normalizar_texto_neurograph(it.get("question", ""))
                a = normalizar_texto_neurograph(it.get("answer", ""))
                if q and a and eh_par_conceitual_valido(q, a):
                    pares_top.append(
                        ParTreinamento(
                            question=q,
                            answer=a,
                            context=it.get("context", []),
                            category=it.get("category", "topic_generated"),
                            video_id=it.get("video_id", "topicos_ptbr"),
                            origem=it.get("origem", "acervo_existente"),
                        )
                    )
            if pares_top:
                salvar_pares_processados(pares_top, pasta_proc)
        except Exception as exc:
            logging.warning("Aviso ao mesclar ultimo_treino_topicos.json: %s", exc)

    # 4. Prepara todos os exemplos consolidados e treina o modelo principal do zero limpo
    exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=arq_curado)
    print(f"[2/4] Total de exemplos em português preparados para treino: {len(exemplos)}")

    caminho_ngs_youtube = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
    modelo = treinar_neurograph(
        exemplos,
        epochs=epochs,
        learning_rate=learning_rate,
        caminho_saida=caminho_ngs_youtube,
        regerar_limpo=True,
        exportar_ngm=False,
    )

    # 5. Exporta as matrizes .ngm em todos os pontos padrão do projeto
    print("\n[3/4] Exportando matrizes binárias (.ngm) atualizadas...")
    caminho_ngm_raiz = DIR_NEUROGRAPH / "neurograph_memoria_ptbr_inibida_completa.ngm"
    caminho_ngm_youtube = DIR_TREINO / "modelos" / "neurograph_youtube.ngm"
    caminho_ngm_ia = DIR_TREINO / "modelos" / "neurograph_matriz_ia.ngm"

    info_raiz = exportar_matriz_ngm_de_modelo(modelo, caminho_ngm_raiz, incluir_vocab_base=True)
    exportar_matriz_ngm_de_modelo(modelo, caminho_ngm_youtube, incluir_vocab_base=True)
    exportar_matriz_ngm_de_modelo(modelo, caminho_ngm_ia, incluir_vocab_base=True)

    print("\n" + "=" * 72)
    print("[SUCESSO] Todas as matrizes (.ngm) e redes (.ngs) foram regeradas!")
    print(f"  -> Matriz Raiz (.ngm)  : {caminho_ngm_raiz}")
    print(f"  -> Matriz Treino (.ngm): {caminho_ngm_ia}")
    print(f"  -> Rede Treinada (.ngs): {caminho_ngs_youtube}")
    print("=" * 72)
    info_raiz["ngm_principal"] = str(caminho_ngm_raiz)
    info_raiz["ngm_treino"] = str(caminho_ngm_ia)
    return info_raiz


def carregar_assuntos_do_ini() -> list[str]:
    """Lê dinamicamente a lista atual de AssuntosContinuoLista do INI mais recente."""
    candidatos = [
        DIR_NEUROGRAPH / "bin" / "neurograph_studio.ini",
        DIR_NEUROGRAPH / "bin" / "neurograph_native.ini",
        DIR_TREINO / "lazarus" / "neurograph_studio.ini",
        DIR_NEUROGRAPH / "lazarus_pure" / "neurograph_native.ini",
    ]
    existentes = [p for p in candidatos if p.exists()]
    if not existentes:
        return []
    caminho_ini = max(existentes, key=lambda p: p.stat().st_mtime)
    try:
        linhas = caminho_ini.read_text(encoding="utf-8", errors="ignore").splitlines()
        na_secao = False
        itens: list[tuple[int, str]] = []
        for linha in linhas:
            s = linha.strip()
            if not s or s.startswith(";") or s.startswith("#"):
                continue
            if s.startswith("[") and s.endswith("]"):
                na_secao = s.lower() == "[assuntoscontinuolista]"
                continue
            if na_secao and "=" in s:
                k, v = s.split("=", 1)
                k = k.strip().lower()
                v = v.strip()
                if k.startswith("item_") and v:
                    try:
                        idx = int(k.split("_", 1)[1])
                    except ValueError:
                        idx = len(itens)
                    itens.append((idx, v))
        itens.sort(key=lambda x: x[0])
        return [val for _, val in itens if val]
    except Exception:
        return []


def sugerir_proximo_assunto_pt(
    assuntos_base: list[str],
    historico_visitados: list[str],
    ciclo: int,
    api_key: str | None = None,
) -> str:
    """Seleciona ou expande o próximo assunto didático estritamente em português."""
    visitados_lower = {h.lower() for h in historico_visitados}
    for a in assuntos_base:
        a_limpo = a.strip()
        if a_limpo and a_limpo.lower() not in visitados_lower:
            return a_limpo

    base_efetiva = [a.strip() for a in assuntos_base if a and a.strip()] or list(CATALOGO_ASSUNTOS_CONTINUOS_PT)
    semente = base_efetiva[(ciclo - 1) % len(base_efetiva)]

    for offset in range(len(SUBTEMAS_EXPANSAO_PT)):
        sub = SUBTEMAS_EXPANSAO_PT[(ciclo - 1 + offset) % len(SUBTEMAS_EXPANSAO_PT)]
        candidato = f"{semente} — {sub}"
        if candidato.lower() not in visitados_lower:
            return candidato
    return f"{semente} — ciclo {ciclo}"


def executar_treino_continuo(
    assuntos_iniciais: list[str] | None = None,
    videos_por_ciclo: int = 2,
    pares_por_ciclo: int = 12,
    intervalo_segundos: int = 3,
    max_ciclos: int = 0,
    api_key: str | None = None,
    caminho_modelo: Path | None = None,
) -> None:
    """Executa o loop de Treino Contínuo:
    Pesquisa no YouTube (PT-BR) + Curadoria e Síntese com IA configurada no INI (PT-BR)
    + Validação de integridade + Treinamento (.ngs) + Regeneração da Matriz (.ngm).
    """
    stop_file = DIR_TREINO / ".stop_training"
    if stop_file.exists():
        try:
            stop_file.unlink()
        except Exception:
            pass

    # Higieniza antes de iniciar a sessão para garantir que nenhum dado inválido anterior contamine o treino
    higienizar_datasets_processados()

    lista_assuntos = [a.strip() for a in (assuntos_iniciais or []) if a and a.strip()]
    if not lista_assuntos:
        lista_assuntos = carregar_assuntos_do_ini() or list(CATALOGO_ASSUNTOS_CONTINUOS_PT)

    alvo_ngs = Path(caminho_modelo).resolve() if caminho_modelo else (DIR_TREINO / "modelos" / "neurograph_youtube.ngs").resolve()
    alvo_ngm_raiz = (DIR_NEUROGRAPH / "neurograph_memoria_ptbr_inibida_completa.ngm").resolve()
    alvo_ngm_mod = alvo_ngs.with_suffix(".ngm")

    pasta_raw = DIR_TREINO / "dados" / "raw"
    pasta_proc = DIR_TREINO / "dados" / "processados"
    pasta_proc.mkdir(parents=True, exist_ok=True)
    arq_estado = pasta_proc / "estado_treino_continuo.json"

    historico_visitados: list[str] = []
    total_ciclos_acumulados = 0
    total_pares_gerados = 0
    total_videos_pt = 0

    if arq_estado.exists():
        try:
            est = json.loads(arq_estado.read_text(encoding="utf-8"))
            historico_visitados = est.get("assuntos_visitados", [])[-200:]
            total_ciclos_acumulados = int(est.get("total_ciclos", 0))
        except Exception:
            pass

    cfg_llm = carregar_config_llm_ini()
    print("\n" + "=" * 72)
    print("=== MODO DE TREINO CONTÍNUO INICIADO (IA + YOUTUBE — 100% PORTUGUÊS) ===")
    print(f"Rede Alvo (.ngs)       : {alvo_ngs}")
    print(f"Matriz Alvo (.ngm)     : {alvo_ngm_raiz}")
    print(f"Provedor IA Ativo      : {cfg_llm.get('provider')} | Modelo: {cfg_llm.get('model')} ({cfg_llm.get('endpoint')})")
    print(f"Filtro de Idioma       : ESTRITAMENTE PORTUGUÊS (PT-BR / PT)")
    print(f"Vídeos/Ciclo: {videos_por_ciclo} | Pares IA/Ciclo: {pares_por_ciclo} | Intervalo: {intervalo_segundos}s")
    print("=" * 72, flush=True)

    ciclo_sessao = 0
    pares_existentes: set[str] = set()
    arq_curado = pasta_proc / "dataset_curado.json"
    if arq_curado.exists():
        try:
            for d in json.loads(arq_curado.read_text(encoding="utf-8")):
                if d.get("question"):
                    pares_existentes.add(d["question"])
        except Exception:
            pass

    try:
        while True:
            if stop_file.exists():
                print("\n[PARADA DETECTADA] Encerrando Treino Contínuo com segurança...", flush=True)
                break

            if max_ciclos > 0 and ciclo_sessao >= max_ciclos:
                print(f"\n[META ATINGIDA] {ciclo_sessao} ciclo(s) de treino contínuo concluídos!", flush=True)
                break

            ciclo_sessao += 1
            total_ciclos_acumulados += 1

            assuntos_ini = carregar_assuntos_do_ini()
            if assuntos_ini:
                lista_assuntos = assuntos_ini

            assunto_atual = sugerir_proximo_assunto_pt(
                lista_assuntos,
                historico_visitados,
                ciclo_sessao,
                api_key=api_key,
            )
            historico_visitados.append(assunto_atual)

            print("\n" + "-" * 72)
            print(f"[CICLO #{ciclo_sessao}] Pesquisando Assunto em Português: '{assunto_atual}'", flush=True)
            print("-" * 72, flush=True)

            pares_ciclo: list[ParTreinamento] = []

            # 1. Busca e Curadoria no YouTube (Apenas em Português)
            if videos_por_ciclo > 0:
                buscas_yt = sugerir_referencias_em_portugues(
                    assunto_atual,
                    n_sugestoes=max(1, videos_por_ciclo),
                    api_key=api_key,
                )
                for q_yt in buscas_yt:
                    if stop_file.exists():
                        break
                    if not eh_texto_em_portugues(q_yt, min_palavras=2):
                        continue
                    print(f"  [YOUTUBE-PT] Buscando vídeos em português para: '{q_yt}'...", flush=True)
                    videos = buscar_videos_youtube(q_yt, max_resultados=2, apenas_portugues=True)
                    capturou_nesta_query = False
                    for v in videos:
                        if stop_file.exists() or capturou_nesta_query:
                            break
                        res = obter_transcricao(
                            v.video_id,
                            query=q_yt,
                            title=v.title,
                            idiomas=("pt-BR", "pt", "pt-PT"),
                        )
                        if res.sucesso and eh_texto_em_portugues(res.raw_text, min_palavras=12):
                            salvar_transcricao_raw(res, pasta_raw)
                            total_videos_pt += 1
                            capturou_nesta_query = True
                            print(
                                f"  [YOUTUBE-PT] Transcrição PT-BR validada: '{v.title}' ({res.num_trechos} trechos)",
                                flush=True,
                            )
                            extraidos_yt = curar_transcricao_com_chatgpt(
                                texto_transcricao=res.raw_text,
                                titulo_video=v.title,
                                video_id=v.video_id,
                                max_pares=max(4, pares_por_ciclo // 2),
                                api_key=api_key,
                            )
                            for p in extraidos_yt:
                                if p.question not in pares_existentes and eh_par_conceitual_valido(p.question, p.answer):
                                    pares_ciclo.append(p)
                                    pares_existentes.add(p.question)
                                    print(f"    -> [YT] P: {p.question} | R: {p.answer}", flush=True)

            if stop_file.exists():
                break

            # 2. Geração e Expansão Conceitual via IA em Português
            faltam_pares = max(4, pares_por_ciclo - len(pares_ciclo))
            print(f"  [IA-PT] Gerando {faltam_pares} pares conceituais em português sobre '{assunto_atual}'...", flush=True)
            gerados_ia = gerar_pares_para_topico(
                topico=assunto_atual,
                qtd_alvo=faltam_pares,
                api_key=api_key,
                perguntas_globais=pares_existentes,
            )
            for p in gerados_ia:
                if eh_par_conceitual_valido(p.question, p.answer):
                    pares_ciclo.append(p)
                    pares_existentes.add(p.question)
                    print(f"    -> [IA] P: {p.question} | R: {p.answer}", flush=True)

            if not pares_ciclo:
                print("  [AVISO] Nenhum par inédito em português gerado neste ciclo. Avançando...", flush=True)
                continue

            # 3. Persiste pares nos arquivos JSON e treina imediatamente a rede (.ngs) + matriz (.ngm)
            salvar_pares_processados(pares_ciclo, pasta_proc, nome_arquivo="dataset_curado.json")
            salvar_pares_processados(pares_ciclo, pasta_proc, nome_arquivo="ultimo_treino_topicos.json")
            total_pares_gerados += len(pares_ciclo)

            exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=arq_curado)
            epocas_ciclo = 65 if len(exemplos) > 250 else 85
            modelo = treinar_neurograph(
                exemplos,
                epochs=epocas_ciclo,
                learning_rate=0.05,
                caminho_saida=alvo_ngs,
                exportar_ngm=False,
            )

            # 4. Atualiza as matrizes binárias (.ngm) para o equipamento (1 única vez por arquivo)
            if alvo_ngm_mod != alvo_ngm_raiz:
                exportar_matriz_ngm_de_modelo(modelo, alvo_ngm_mod, incluir_vocab_base=True)
            info_ngm = exportar_matriz_ngm_de_modelo(modelo, alvo_ngm_raiz, incluir_vocab_base=True)

            try:
                arq_estado.write_text(
                    json.dumps(
                        {
                            "ultimo_ciclo_sessao": ciclo_sessao,
                            "total_ciclos": total_ciclos_acumulados,
                            "ultimo_assunto": assunto_atual,
                            "pares_gerados_sessao": total_pares_gerados,
                            "videos_pt_processados": total_videos_pt,
                            "total_dataset_acumulado": len(exemplos),
                            "tokens_matriz_ngm": info_ngm["tokens"],
                            "arestas_matriz_ngm": info_ngm["edges"],
                            "assuntos_visitados": historico_visitados[-200:],
                        },
                        ensure_ascii=False,
                        indent=2,
                    ),
                    encoding="utf-8",
                )
            except Exception:
                pass

            print(
                f"[TREINADO] Ciclo #{ciclo_sessao} concluído | Assunto: '{assunto_atual}' | "
                f"+{len(pares_ciclo)} pares PT-BR (Sessão: {total_pares_gerados} | Acervo: {len(exemplos)}) | "
                f"Matriz NGM: {info_ngm['tokens']} tokens, {info_ngm['edges']} conexões",
                flush=True,
            )

            passos_espera = max(1, int(intervalo_segundos * 2))
            for _ in range(passos_espera):
                if stop_file.exists():
                    break
                time.sleep(0.5)

    except KeyboardInterrupt:
        print("\n[INTERROMPIDO] Salvando estado final do Treino Contínuo...", flush=True)

    print("\n" + "=" * 72)
    print(
        f"=== TREINO CONTÍNUO FINALIZADO: {ciclo_sessao} ciclo(s), "
        f"+{total_pares_gerados} novos pares em português, {total_videos_pt} vídeos PT-BR ==="
    )
    print("=" * 72, flush=True)


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="Treino Contínuo e Regeneração de Matrizes NGM do NeuroGraph")
    parser.add_argument("--regerar-ngm", action="store_true", help="Regera todas as matrizes .ngm e redes .ngs dos arquivos existentes")
    parser.add_argument("--continuo", action="store_true", help="Inicia o loop de Treino Contínuo (IA + YouTube em PT-BR)")
    parser.add_argument("--assuntos", nargs="*", help="Lista de assuntos base em português para o treino contínuo")
    parser.add_argument("--videos-ciclo", type=int, default=2, help="Vídeos do YouTube em português por ciclo")
    parser.add_argument("--pares-ciclo", type=int, default=12, help="Pares de perguntas/respostas por ciclo")
    parser.add_argument("--intervalo", type=int, default=3, help="Intervalo em segundos entre ciclos")
    parser.add_argument("--max-ciclos", type=int, default=0, help="Máximo de ciclos (0 = contínuo até parar)")
    parser.add_argument("--api-key", type=str, default=None, help="Chave da API OpenAI")
    parser.add_argument("--modelo", type=str, default=None, help="Caminho do modelo alvo (.ngs)")

    args = parser.parse_args()
    if args.regerar_ngm:
        regerar_matrizes_ngm_existentes()
    elif args.continuo:
        executar_treino_continuo(
            assuntos_iniciais=args.assuntos,
            videos_por_ciclo=args.videos_ciclo,
            pares_por_ciclo=args.pares_ciclo,
            intervalo_segundos=args.intervalo,
            max_ciclos=args.max_ciclos,
            api_key=args.api_key,
            caminho_modelo=Path(args.modelo) if args.modelo else None,
        )
    else:
        regerar_matrizes_ngm_existentes()
