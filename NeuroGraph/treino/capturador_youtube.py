#!/usr/bin/env python3
"""Módulo de captura de vídeos e transcrições do YouTube em português para o NeuroGraph.

Responsável por:
1. Buscar vídeos relevantes no YouTube por palavras-chave ou temas em PT-BR.
2. Extrair o ID de URLs do YouTube (formatos padrão e encurtados).
3. Obter legendas/transcrições oficiais e geradas automaticamente em português.
4. Limpar e estruturar o texto bruto para a fase de curadoria.
"""
from __future__ import annotations

import json
import logging
import re
import urllib.parse
import urllib.request
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")


@dataclass
class VideoInfo:
    video_id: str
    title: str
    url: str
    query: str = ""


@dataclass
class TranscricaoResult:
    video_id: str
    title: str
    url: str
    query: str
    raw_text: str
    num_trechos: int
    idioma: str
    sucesso: bool
    erro: str | None = None


STOPWORDS_PT = frozenset({
    "de", "da", "do", "das", "dos", "em", "no", "na", "nos", "nas",
    "por", "para", "com", "sem", "que", "não", "nao", "sim", "uma", "um",
    "como", "mais", "menos", "muito", "sobre", "entre", "até", "ate",
    "também", "tambem", "já", "ja", "são", "sao", "está", "esta", "estão",
    "foi", "ser", "ter", "pelo", "pela", "pelos", "pelas", "isso", "isto",
    "esse", "essa", "este", "esta", "qual", "quais", "quando", "onde",
    "porque", "porquê", "você", "voce", "nós", "nosso", "nossa", "seu", "sua",
})

STOPWORDS_ESTRANGEIRAS = frozenset({
    # Inglês
    "the", "and", "with", "from", "what", "which", "this", "that", "these",
    "those", "have", "has", "had", "will", "would", "could", "should", "about",
    "into", "your", "their", "there", "where", "when", "while", "because",
    # Espanhol exclusivo
    "el", "la", "los", "las", "del", "una", "unos", "unas", "pero", "como",
    "esto", "esta", "estos", "estas", "también", "tambien", "hacer", "puede",
    "tiene", "tienen", "nosotros", "ustedes", "elliptical", "hacia", "desde",
})


def eh_texto_em_portugues(texto: str, min_palavras: int = 4) -> bool:
    """Verifica de forma rigorosa se um título ou transcrição está em língua portuguesa (PT-BR/PT)."""
    if not texto or not texto.strip():
        return False

    palavras = re.findall(r"[a-zA-ZÀ-ÿ]+", texto.casefold())
    if len(palavras) < min_palavras:
        # Para títulos curtos, verifica ausência de stopwords inglesas/espanholas explícitas
        estrangeiras_curto = sum(1 for p in palavras if p in STOPWORDS_ESTRANGEIRAS - {"como", "esta", "pero"})
        return estrangeiras_curto == 0

    qtd_pt = sum(1 for p in palavras if p in STOPWORDS_PT)
    qtd_est = sum(1 for p in palavras if p in (STOPWORDS_ESTRANGEIRAS - STOPWORDS_PT))

    # Presença de morfemas/diacríticos típicos do português (ã, õ, ç, ção, ções, nh, lh)
    texto_lower = texto.casefold()
    marcadores_pt = len(re.findall(r"(?:ção|ções|ã|õ|ç|nh|lh|\bé\b|\bsão\b|\bnão\b)", texto_lower))

    score_pt = qtd_pt + (marcadores_pt * 1.5)
    if qtd_est > qtd_pt and marcadores_pt == 0:
        return False

    if len(palavras) >= 20:
        proporcao_pt = score_pt / max(1, len(palavras))
        return proporcao_pt >= 0.08 and (qtd_pt >= qtd_est)

    return (score_pt >= 1.0) and (qtd_est <= qtd_pt + 1)


def extrair_video_id(url_ou_id: str) -> str:
    """Extrai o ID de 11 caracteres de URLs do YouTube ou retorna o próprio ID."""
    url_ou_id = url_ou_id.strip()
    if len(url_ou_id) == 11 and re.match(r"^[a-zA-Z0-9_-]{11}$", url_ou_id):
        return url_ou_id

    # Padrões comuns: youtube.com/watch?v=ID, youtu.be/ID, youtube.com/embed/ID, youtube.com/shorts/ID
    padroes = [
        r"(?:v=|\/v\/|youtu\.be\/|\/embed\/|\/shorts\/)([a-zA-Z0-9_-]{11})",
        r"^([a-zA-Z0-9_-]{11})$",
    ]
    for padrao in padroes:
        match = re.search(padrao, url_ou_id)
        if match:
            return match.group(1)

    raise ValueError(f"Não foi possível extrair um Video ID válido de: '{url_ou_id}'")


def buscar_videos_youtube(
    query: str,
    max_resultados: int = 5,
    apenas_portugues: bool = True,
) -> list[VideoInfo]:
    """Busca vídeos no YouTube com base na query informada sem exigir chave de API externa.

    Força parâmetros regionais (hl=pt, gl=BR) e filtra títulos em português.
    """
    query_pt = query.strip()
    q_encoded = urllib.parse.quote(query_pt)
    url = f"https://www.youtube.com/results?search_query={q_encoded}&hl=pt&gl=BR"
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            ),
            "Accept-Language": "pt-BR,pt;q=0.95",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=12) as response:
            html = response.read().decode("utf-8", errors="replace")
    except Exception as exc:
        logging.warning("Erro ao consultar YouTube para a query '%s': %s", query, exc)
        return []

    # Extrai IDs e títulos do HTML renderizado inicial
    ids_encontrados: list[str] = []
    titulos: dict[str, str] = {}

    matches_ids = re.findall(r"/watch\?v=([a-zA-Z0-9_-]{11})", html)
    for vid in matches_ids:
        if vid not in ids_encontrados and len(vid) == 11:
            ids_encontrados.append(vid)
        if len(ids_encontrados) >= max_resultados * 4:
            break

    for vid in ids_encontrados:
        padrao_titulo = rf'"{vid}".*?"title":\{{"runs":\[\{{"text":"([^"]+)"\}}'
        m = re.search(padrao_titulo, html)
        if m:
            titulos[vid] = m.group(1)
        else:
            titulos[vid] = f"Vídeo YouTube ({vid})"

    resultados: list[VideoInfo] = []
    for vid in ids_encontrados:
        titulo = titulos.get(vid, f"Vídeo {vid}")
        if apenas_portugues and not titulo.startswith("Vídeo YouTube ("):
            if not eh_texto_em_portugues(titulo, min_palavras=3):
                logging.info("Vídeo ignorado (título fora do filtro PT-BR): '%s'", titulo)
                continue
        resultados.append(
            VideoInfo(
                video_id=vid,
                title=titulo,
                url=f"https://www.youtube.com/watch?v={vid}",
                query=query,
            )
        )
        if len(resultados) >= max_resultados:
            break

    logging.info("Encontrados %d vídeos em português para o termo: '%s'", len(resultados), query)
    return resultados


def limpar_texto_transcricao(snippets: list[Any]) -> tuple[str, int]:
    """Limpa e formata trechos de transcrição:

    - Remove marcadores como [Música], [Aplausos], [Risos].
    - Normaliza espaçamentos e quebras de linha.
    - Concatena em texto contínuo fluído.
    """
    linhas: list[str] = []
    for s in snippets:
        if hasattr(s, "text"):
            txt = s.text
        elif isinstance(s, dict):
            txt = s.get("text", "")
        else:
            txt = str(s)

        txt = txt.strip()
        # Filtra marcadores de áudio entre colchetes
        if not txt or (txt.startswith("[") and txt.endswith("]")):
            continue
        # Remove marcadores inline
        txt = re.sub(r"\[[^\]]+\]", "", txt).strip()
        if txt:
            linhas.append(txt)

    texto_completo = " ".join(linhas)
    # Normaliza múltiplos espaços
    texto_completo = re.sub(r"\s+", " ", texto_completo).strip()
    return texto_completo, len(linhas)


def obter_transcricao(
    video_ou_url: str,
    query: str = "",
    title: str = "",
    idiomas: tuple[str, ...] = ("pt", "pt-BR", "pt-PT"),
) -> TranscricaoResult:
    """Busca e extrai a transcrição de um vídeo específico em português."""
    vid = extrair_video_id(video_ou_url)
    if not title:
        title = f"Vídeo {vid}"

    try:
        from youtube_transcript_api import YouTubeTranscriptApi

        snippets = None
        # Suporta tanto api.fetch (versão recente 1.2+) quanto get_transcript (versões antigas)
        if hasattr(YouTubeTranscriptApi, "get_transcript"):
            snippets = YouTubeTranscriptApi.get_transcript(vid, languages=list(idiomas))
        else:
            api = YouTubeTranscriptApi()
            snippets = api.fetch(vid, languages=list(idiomas))

        texto, total_trechos = limpar_texto_transcricao(list(snippets))
        if not texto:
            return TranscricaoResult(
                video_id=vid,
                title=title,
                url=f"https://www.youtube.com/watch?v={vid}",
                query=query,
                raw_text="",
                num_trechos=0,
                idioma="pt",
                sucesso=False,
                erro="Transcrição vazia após filtragem",
            )

        if not eh_texto_em_portugues(texto, min_palavras=10):
            return TranscricaoResult(
                video_id=vid,
                title=title,
                url=f"https://www.youtube.com/watch?v={vid}",
                query=query,
                raw_text="",
                num_trechos=0,
                idioma="outro",
                sucesso=False,
                erro="Conteúdo descartado: transcrição não está em língua portuguesa",
            )

        logging.info("Transcrição em português obtida com sucesso (%d palavras, %d trechos) para [%s]",
                     len(texto.split()), total_trechos, vid)

        return TranscricaoResult(
            video_id=vid,
            title=title,
            url=f"https://www.youtube.com/watch?v={vid}",
            query=query,
            raw_text=texto,
            num_trechos=total_trechos,
            idioma="pt",
            sucesso=True,
        )

    except Exception as exc:
        logging.warning("Falha ao obter transcrição para o vídeo [%s]: %s", vid, exc)
        return TranscricaoResult(
            video_id=vid,
            title=title,
            url=f"https://www.youtube.com/watch?v={vid}",
            query=query,
            raw_text="",
            num_trechos=0,
            idioma="pt",
            sucesso=False,
            erro=str(exc),
        )


def salvar_transcricao_raw(resultado: TranscricaoResult, pasta_saida: Path) -> Path:
    """Persiste a transcrição bruta capturada em formato JSON estruturado."""
    pasta_saida.mkdir(parents=True, exist_ok=True)
    arquivo = pasta_saida / f"transcricao_{resultado.video_id}.json"
    with arquivo.open("w", encoding="utf-8") as f:
        json.dump(asdict(resultado), f, ensure_ascii=False, indent=2)
    logging.info("Arquivo gravado em: %s", arquivo)
    return arquivo


if __name__ == "__main__":
    import sys
    termo = sys.argv[1] if len(sys.argv) > 1 else "o que e fotossintese"
    print(f"Buscando vídeos para: {termo}")
    videos = buscar_videos_youtube(termo, max_resultados=2)
    for v in videos:
        print(f"Vídeo: {v.title} -> {v.url}")
        res = obter_transcricao(v.video_id, query=termo, title=v.title)
        if res.sucesso:
            print(f"Amostra ({len(res.raw_text)} chars): {res.raw_text[:200]}...\n")
        else:
            print(f"Erro: {res.erro}\n")
