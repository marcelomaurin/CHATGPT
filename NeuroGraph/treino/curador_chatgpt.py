#!/usr/bin/env python3
"""Módulo de Curadoria com IA do ChatGPT para o NeuroGraph.

Responsabilidades:
1. Utilizar o ChatGPT para sugerir termos de busca e referências em português de alto valor didático.
2. Analisar transcrições brutas do YouTube e extrair pares atômicos de pergunta/resposta (fatos conceituais).
3. Filtrar e formatar os dados respeitando os limites da arquitetura do NeuroGraph
   (respostas concisas <= 60 tokens, sem alucinações, sem jargões de canais de vídeo).
4. Fornecer modo híbrido: com chave OpenAI API ou modo heurístico local sem chave.
"""
from __future__ import annotations

import json
import logging
import os
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

PROMPT_SISTEMA_CURADOR = """Você é um curador pedagógico e linguístico encarregado de extrair dados de treinamento para o NeuroGraph, uma rede neural associativa em português.

Sua tarefa:
Leia a transcrição de um vídeo educativo do YouTube e extraia afirmações e conceitos atômicos verdadeiros.
Para cada conceito identificado, crie um par no formato JSON:
- "question": Pergunta conceitual direta em português minúsculo (ex: "o que é um painel solar", "como funciona a fotossíntese").
- "answer": Resposta direta, afirmativa e concisa (máximo de 25 a 35 palavras, sem rodeios ou saudações).
- "context": Lista vazia ou lista de palavras de contexto quando necessário.
- "category": "youtube_curated"

Regras estritas:
1. Extraia APENAS informações factuais e corretas presentes no texto.
2. Ignore totalmente saudações ("olá inscritos", "se inscreve no canal"), propagandas, piadas e opiniões subjetivas.
3. Mantenha as respostas em português gramaticalmente correto, direto e simples.
4. Responda ESTRITAMENTE em formato JSON com uma lista de objetos: [{"question": "...", "answer": "...", "context": [], "category": "youtube_curated"}]
"""

PROMPT_SISTEMA_CURADOR_PDF = """Você é um curador pedagógico e linguístico encarregado de extrair dados de treinamento para o NeuroGraph, uma rede neural associativa em português.

Sua tarefa:
Leia o trecho de um documento ou livro em PDF e extraia definições e conceitos atômicos verdadeiros.
Para cada conceito identificado, crie um par no formato JSON:
- "question": Pergunta conceitual direta em português minúsculo (ex: "o que é fotossíntese", "qual a função das mitocôndrias").
- "answer": Resposta direta, afirmativa e concisa (máximo de 25 a 35 palavras, sem rodeios).
- "context": Lista vazia ou lista de palavras de contexto quando necessário.
- "category": "pdf_curated"

Regras estritas:
1. Extraia APENAS informações factuais e corretas presentes no texto.
2. Ignore números de página, cabeçalhos, rodapés, sumários e referências bibliográficas.
3. Mantenha as respostas em português gramaticalmente correto, direto e simples.
4. Responda ESTRITAMENTE em formato JSON com uma lista de objetos: [{"question": "...", "answer": "...", "context": [], "category": "pdf_curated"}]
"""

PROMPT_SISTEMA_SUGESTOES = """Você é um especialista em educação e currículo científico em língua portuguesa.
O usuário fornecerá um tema geral (ex: "energia solar", "biologia celular", "computação").
Gere uma lista de 5 a 10 buscas em português ideais para encontrar vídeos didáticos no YouTube
com explicações conceituais claras de "o que é", "como funciona" ou "para que serve".
Retorne ESTRITAMENTE um array JSON de strings, por exemplo:
["o que é energia solar fotovoltaica", "como funciona o inversor solar", "o que são células fotovoltaicas"]
"""


@dataclass
class ParTreinamento:
    question: str
    answer: str
    context: list[str]
    category: str = "youtube_curated"
    video_id: str = ""
    origem: str = "chatgpt"


def normalizar_texto_neurograph(texto: str) -> str:
    """Normaliza o texto para o padrão de entrada do tokenizador do NeuroGraph."""
    t = texto.strip().casefold()
    # Remove pontuação excessiva nas extremidades
    t = re.sub(r"[?!.,;:]+$", "", t)
    t = re.sub(r"\s+", " ", t)
    return t


def obter_cliente_openai(api_key: str | None = None) -> Any:
    """Instancia o cliente OpenAI caso a chave esteja disponível via argumento ou env."""
    key = api_key or os.environ.get("OPENAI_API_KEY")
    if not key:
        return None
    try:
        from openai import OpenAI
        return OpenAI(api_key=key)
    except Exception as exc:
        logging.warning("Não foi possível inicializar cliente OpenAI: %s", exc)
        return None


def sugerir_referencias_em_portugues(
    tema: str,
    n_sugestoes: int = 5,
    api_key: str | None = None,
) -> list[str]:
    """Usa a IA do ChatGPT para gerar buscas de alta qualidade no YouTube em português.

    Caso não haja chave de API, recorre a um catálogo de termos didáticos pré-configurados.
    """
    client = obter_cliente_openai(api_key)
    if client:
        try:
            logging.info("Consultando ChatGPT para sugerir termos de busca sobre '%s'...", tema)
            resp = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": PROMPT_SISTEMA_SUGESTOES},
                    {"role": "user", "content": f"Tema: {tema}\nQuantidade: {n_sugestoes}"},
                ],
                temperature=0.3,
            )
            conteudo = resp.choices[0].message.content or ""
            # Limpa possíveis blocos markdown ```json ... ```
            conteudo = re.sub(r"^```(?:json)?", "", conteudo.strip(), flags=re.MULTILINE)
            conteudo = re.sub(r"```$", "", conteudo.strip(), flags=re.MULTILINE).strip()
            lista = json.loads(conteudo)
            if isinstance(lista, list) and all(isinstance(x, str) for x in lista):
                return lista[:n_sugestoes]
        except Exception as exc:
            logging.warning("Falha na consulta ao ChatGPT para sugestões: %s. Usando fallback.", exc)

    # Fallback heurístico inteligente em PT-BR
    tema_clean = tema.lower().strip()
    sugestoes_base = [
        f"o que é {tema_clean}",
        f"como funciona {tema_clean}",
        f"principais conceitos de {tema_clean}",
        f"para que serve {tema_clean}",
        f"explicação simples de {tema_clean}",
    ]
    return sugestoes_base[:n_sugestoes]


def extrair_pares_heuristicos(texto: str, max_pares: int = 10) -> list[dict]:
    """Extrai fatos conceituais básicos em português quando a API OpenAI não estiver disponível.
    
    Lida com transcrições automáticas que podem não possuir pontuação formal (. , ?).
    """
    if not texto:
        return []

    # Normaliza variantes comuns de ASR (" ea " -> " é a ", " sao " -> " são ")
    t_norm = re.sub(r"\b(e|eh)\s+a\b", "é a", texto.lower())
    t_norm = re.sub(r"\b(e|eh)\s+o\b", "é o", t_norm)
    t_norm = re.sub(r"\b(e|eh)\s+um\b", "é um", t_norm)
    t_norm = re.sub(r"\b(e|eh)\s+uma\b", "é uma", t_norm)

    pares = []
    perguntas_vistas = set()

    # 1. Padrões de definições explícitas (ex: "energia solar é...", "fotossíntese é...")
    padrao_conceito = re.compile(
        r"\b([a-zà-ú]{3,25}(?:\s+[a-zà-ú]{2,15}){0,3})\s+(é|são|consiste em|funciona como|chama-se)\s+([^,.;]{10,90})",
        re.IGNORECASE,
    )

    termos_proibidos = {"que", "quando", "onde", "porque", "se", "como", "mas", "aqui", "então", "agora", "gente", "canal"}

    for match in padrao_conceito.finditer(t_norm):
        termo = match.group(1).strip()
        verbo = match.group(2).strip()
        definicao = match.group(3).strip()

        # Limpa introduções indesejadas
        primeira_palavra = termo.split()[0]
        if primeira_palavra in termos_proibidos:
            continue
        if len(termo.split()) > 4 or len(definicao.split()) < 3:
            continue
        if any(ign in definicao for ign in ["canal", "vídeo", "inscreva", "link", "clique", "comente"]):
            continue

        # Corta a definição na primeira conjunção longa para manter atomicidade
        definicao_curta = re.split(r"\b(além disso|por outro lado|e também|portanto|mas)\b", definicao)[0].strip()
        if len(definicao_curta.split()) > 25:
            definicao_curta = " ".join(definicao_curta.split()[:20])

        q = normalizar_texto_neurograph(f"o que é {termo}")
        a = normalizar_texto_neurograph(f"{termo} {verbo} {definicao_curta}")

        if q not in perguntas_vistas and len(a.split()) <= 45:
            perguntas_vistas.add(q)
            pares.append({
                "question": q,
                "answer": a,
                "context": [],
                "category": "youtube_curated",
            })
            if len(pares) >= max_pares:
                break

    return pares


def curar_transcricao_com_chatgpt(
    texto_transcricao: str,
    titulo_video: str,
    video_id: str = "",
    max_pares: int = 8,
    api_key: str | None = None,
) -> list[ParTreinamento]:
    """Processa o texto da transcrição usando o ChatGPT para criar pares de treino de alta fidelidade."""
    if not texto_transcricao or len(texto_transcricao.split()) < 15:
        logging.warning("Transcrição muito curta para curadoria.")
        return []

    client = obter_cliente_openai(api_key)
    pares_extraidos: list[dict] = []

    if client:
        try:
            logging.info("Enviando transcrição de [%s] para curadoria do ChatGPT...", video_id or titulo_video)
            # Envia trecho seguro de até 4000 caracteres para evitar exceder limites de contexto
            trecho = texto_transcricao[:4500]
            prompt_usuario = (
                f"Título do Vídeo: {titulo_video}\n\n"
                f"Transcrição do vídeo:\n{trecho}\n\n"
                f"Por favor, extraia até {max_pares} pares conceituais precisos em português seguindo as regras."
            )

            resp = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": PROMPT_SISTEMA_CURADOR},
                    {"role": "user", "content": prompt_usuario},
                ],
                temperature=0.2,
            )
            raw_out = resp.choices[0].message.content or ""
            raw_out = re.sub(r"^```(?:json)?", "", raw_out.strip(), flags=re.MULTILINE)
            raw_out = re.sub(r"```$", "", raw_out.strip(), flags=re.MULTILINE).strip()
            dados = json.loads(raw_out)
            if isinstance(dados, list):
                pares_extraidos = dados
                logging.info("ChatGPT extraiu %d pares com sucesso.", len(pares_extraidos))
        except Exception as exc:
            logging.warning("Erro ao curar com ChatGPT (%s). Recorrendo a extração heurística.", exc)
            pares_extraidos = extrair_pares_heuristicos(texto_transcricao, max_pares=max_pares)
    else:
        logging.info("OPENAI_API_KEY não detectada. Executando curadoria heurística local.")
        pares_extraidos = extrair_pares_heuristicos(texto_transcricao, max_pares=max_pares)

    resultados: list[ParTreinamento] = []
    for item in pares_extraidos:
        q = normalizar_texto_neurograph(item.get("question", ""))
        a = normalizar_texto_neurograph(item.get("answer", ""))
        if not q or not a:
            continue
        # Validação de comprimento do NeuroGraph (respostas de até 60 tokens)
        if len(a.split()) > 60:
            a = " ".join(a.split()[:55])
        
        resultados.append(
            ParTreinamento(
                question=q,
                answer=a,
                context=item.get("context", []),
                category="youtube_curated",
                video_id=video_id,
                origem="chatgpt" if client else "heuristica_local",
            )
        )

    return resultados


def curar_pdf_com_chatgpt(
    texto_pdf: str,
    nome_arquivo: str,
    max_pares_total: int = 20,
    api_key: str | None = None,
) -> list[ParTreinamento]:
    """Processa o texto extraído de um arquivo PDF e extrai pares conceituais de pergunta e resposta."""
    if not texto_pdf or len(texto_pdf.split()) < 20:
        logging.warning("Texto do PDF muito curto ou vazio para curadoria.")
        return []

    client = obter_cliente_openai(api_key)
    pares_extraidos: list[dict] = []

    # Se o texto for longo, processa em blocos de até ~4000 caracteres
    tamanho_bloco = 4000
    blocos = [texto_pdf[i:i + tamanho_bloco] for i in range(0, min(len(texto_pdf), 20000), tamanho_bloco)]
    max_por_bloco = max(3, max_pares_total // max(1, len(blocos)))

    if client:
        logging.info("Enviando %d bloco(s) do PDF '%s' para curadoria do ChatGPT...", len(blocos), nome_arquivo)
        for idx, bloco in enumerate(blocos):
            try:
                resp = client.chat.completions.create(
                    model="gpt-4o-mini",
                    messages=[
                        {"role": "system", "content": PROMPT_SISTEMA_CURADOR_PDF},
                        {"role": "user", "content": f"Documento: {nome_arquivo} (Parte {idx+1}/{len(blocos)})\n\nTexto:\n{bloco}\n\nExtraia até {max_por_bloco} pares conceituais."},
                    ],
                    temperature=0.2,
                )
                raw_out = resp.choices[0].message.content or ""
                raw_out = re.sub(r"^```(?:json)?", "", raw_out.strip(), flags=re.MULTILINE)
                raw_out = re.sub(r"```$", "", raw_out.strip(), flags=re.MULTILINE).strip()
                dados = json.loads(raw_out)
                if isinstance(dados, list):
                    pares_extraidos.extend(dados)
            except Exception as exc:
                logging.warning("Erro no bloco %d do PDF com ChatGPT: %s. Usando heurística.", idx+1, exc)
                pares_extraidos.extend(extrair_pares_heuristicos(bloco, max_pares=max_por_bloco))

            if len(pares_extraidos) >= max_pares_total:
                break
    else:
        logging.info("OPENAI_API_KEY não detectada. Executando curadoria heurística local no PDF.")
        for bloco in blocos:
            pares_extraidos.extend(extrair_pares_heuristicos(bloco, max_pares=max_por_bloco))
            if len(pares_extraidos) >= max_pares_total:
                break

    resultados: list[ParTreinamento] = []
    perguntas_vistas = set()

    for item in pares_extraidos[:max_pares_total]:
        q = normalizar_texto_neurograph(item.get("question", ""))
        a = normalizar_texto_neurograph(item.get("answer", ""))
        if not q or not a or q in perguntas_vistas:
            continue
        perguntas_vistas.add(q)
        if len(a.split()) > 60:
            a = " ".join(a.split()[:55])

        resultados.append(
            ParTreinamento(
                question=q,
                answer=a,
                context=item.get("context", []),
                category="pdf_curated",
                video_id=nome_arquivo,
                origem="chatgpt_pdf" if client else "heuristica_pdf",
            )
        )

    logging.info("Curadoria do PDF '%s' concluída: %d pares atômicos gerados.", nome_arquivo, len(resultados))
    return resultados


def salvar_pares_processados(pares: list[ParTreinamento], pasta_saida: Path, nome_arquivo: str = "dataset_curado.json") -> Path:
    """Grava os pares processados em JSON pronto para alimentar o treinador do NeuroGraph."""
    pasta_saida.mkdir(parents=True, exist_ok=True)
    caminho = pasta_saida / nome_arquivo
    
    existentes = []
    if caminho.exists():
        try:
            with caminho.open("r", encoding="utf-8") as f:
                existentes = json.load(f)
        except Exception:
            existentes = []

    novos_dicts = [asdict(p) for p in pares]
    # Evita duplicatas pela pergunta
    perguntas_existentes = {item.get("question") for item in existentes}
    adicionados = 0
    for n in novos_dicts:
        if n["question"] not in perguntas_existentes:
            existentes.append(n)
            perguntas_existentes.add(n["question"])
            adicionados += 1

    with caminho.open("w", encoding="utf-8") as f:
        json.dump(existentes, f, ensure_ascii=False, indent=2)

    logging.info("Dataset atualizado em %s (+%d novos pares, total %d).", caminho, adicionados, len(existentes))
    return caminho


if __name__ == "__main__":
    sugestoes = sugerir_referencias_em_portugues("energia solar", n_sugestoes=3)
    print("Sugestões de busca:", sugestoes)
    
    exemplo_texto = (
        "A energia solar fotovoltaica é a energia obtida através da conversão direta da luz em eletricidade. "
        "Um painel solar é um dispositivo composto por células fotovoltaicas que absorvem fótons de luz. "
        "O inversor solar é o equipamento responsável por converter corrente contínua em corrente alternada."
    )
    pares = curar_transcricao_com_chatgpt(exemplo_texto, "Introdução à Energia Solar", video_id="demo123")
    print(f"\nPares extraídos ({len(pares)}):")
    for p in pares:
        print(f"  P: {p.question}\n  R: {p.answer}\n")
