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


def buscar_videos_youtube(query: str, max_resultados: int = 5) -> list[VideoInfo]:
    """Busca vídeos no YouTube com base na query informada sem exigir chave de API externa.

    Analisa o HTML de resultados de busca pública do YouTube.
    """
    q_encoded = urllib.parse.quote(query)
    url = f"https://www.youtube.com/results?search_query={q_encoded}"
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
            ),
            "Accept-Language": "pt-BR,pt;q=0.9",
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

    # Padrão de extração de blocos de vídeo do JSON inicial embutido (ytInitialData)
    matches_ids = re.findall(r"/watch\?v=([a-zA-Z0-9_-]{11})", html)
    for vid in matches_ids:
        if vid not in ids_encontrados and len(vid) == 11:
            ids_encontrados.append(vid)
        if len(ids_encontrados) >= max_resultados * 2:
            break

    # Tentativa de extrair títulos associados via regex no JSON embutido
    for vid in ids_encontrados:
        padrao_titulo = rf'"{vid}".*?"title":\{{"runs":\[\{{"text":"([^"]+)"\}}'
        m = re.search(padrao_titulo, html)
        if m:
            titulos[vid] = m.group(1)
        else:
            titulos[vid] = f"Vídeo YouTube ({vid})"

    resultados: list[VideoInfo] = []
    for vid in ids_encontrados[:max_resultados]:
        resultados.append(
            VideoInfo(
                video_id=vid,
                title=titulos.get(vid, f"Vídeo {vid}"),
                url=f"https://www.youtube.com/watch?v={vid}",
                query=query,
            )
        )

    logging.info("Encontrados %d vídeos para o termo: '%s'", len(resultados), query)
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

        logging.info("Transcrição obtida com sucesso (%d palavras, %d trechos) para [%s]",
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
