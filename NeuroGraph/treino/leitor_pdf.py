#!/usr/bin/env python3
"""Módulo de extração e processamento de documentos PDF para treinamento do NeuroGraph.

Responsabilidades:
1. Ler arquivos PDF (locais ou passados via CLI/App) usando pypdf/PyPDF2.
2. Limpar e estruturar o texto (remoção de quebras artificiais de linha, cabeçalhos e rodapés).
3. Segmentar documentos longos em blocos semânticos para envio ao ChatGPT.
4. Integrar com o módulo de curadoria para gerar pares atômicos de pergunta e resposta.
"""
from __future__ import annotations

import json
import logging
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")


@dataclass
class PDFInfo:
    caminho: str
    nome_arquivo: str
    total_paginas: int
    tamanho_bytes: int
    texto_extraido: str
    num_palavras: int
    sucesso: bool
    erro: str | None = None


def extrair_texto_pdf(caminho_pdf: Path | str, max_paginas: int = 100) -> PDFInfo:
    """Extrai o texto integral de um arquivo PDF preservando a integridade das frases."""
    caminho = Path(caminho_pdf).resolve()

    if not caminho.exists():
        return PDFInfo(
            caminho=str(caminho),
            nome_arquivo=caminho.name,
            total_paginas=0,
            tamanho_bytes=0,
            texto_extraido="",
            num_palavras=0,
            sucesso=False,
            erro=f"Arquivo não encontrado: {caminho}",
        )

    try:
        try:
            import pypdf
            leitor = pypdf.PdfReader(str(caminho))
        except ImportError:
            import PyPDF2 as pypdf  # type: ignore
            leitor = pypdf.PdfReader(str(caminho))

        num_paginas = len(leitor.pages)
        if num_paginas == 0:
            return PDFInfo(
                caminho=str(caminho),
                nome_arquivo=caminho.name,
                total_paginas=0,
                tamanho_bytes=caminho.stat().st_size,
                texto_extraido="",
                num_palavras=0,
                sucesso=False,
                erro="O PDF não contém páginas legíveis.",
            )

        paginas_a_ler = min(num_paginas, max_paginas)
        textos_paginas: list[str] = []

        for idx in range(paginas_a_ler):
            pag = leitor.pages[idx]
            txt = pag.extract_text() or ""
            # Normaliza quebras de linha que dividem palavras ("pa-\nlavra" -> "palavra")
            txt = re.sub(r"(\w+)-\s*\n\s*(\w+)", r"\1\2", txt)
            # Remove quebras de linha soltas no meio de frases
            txt = re.sub(r"(?<!\n)\n(?!\n)", " ", txt)
            txt = re.sub(r"\s+", " ", txt).strip()
            if txt:
                textos_paginas.append(txt)

        texto_final = "\n\n".join(textos_paginas).strip()
        num_palavras = len(texto_final.split())

        logging.info("PDF lido com sucesso: '%s' (%d páginas processadas, %d palavras)",
                     caminho.name, paginas_a_ler, num_palavras)

        return PDFInfo(
            caminho=str(caminho),
            nome_arquivo=caminho.name,
            total_paginas=num_paginas,
            tamanho_bytes=caminho.stat().st_size,
            texto_extraido=texto_final,
            num_palavras=num_palavras,
            sucesso=True,
        )

    except Exception as exc:
        logging.error("Erro ao ler PDF '%s': %s", caminho.name, exc)
        return PDFInfo(
            caminho=str(caminho),
            nome_arquivo=caminho.name,
            total_paginas=0,
            tamanho_bytes=caminho.stat().st_size if caminho.exists() else 0,
            texto_extraido="",
            num_palavras=0,
            sucesso=False,
            erro=str(exc),
        )


def dividir_em_blocos_semanticos(texto: str, tamanho_max_palavras: int = 600) -> list[str]:
    """Divide um texto longo de PDF em blocos de tamanho adequado para envio à IA sem cortar sentenças."""
    if not texto:
        return []

    # Divide por parágrafos duplos ou por pontuação final forte
    paragrafos = [p.strip() for p in re.split(r"\n\s*\n", texto) if p.strip()]
    blocos: list[str] = []
    bloco_atual: list[str] = []
    palavras_atuais = 0

    for p in paragrafos:
        num_palavras_p = len(p.split())
        if palavras_atuais + num_palavras_p > tamanho_max_palavras and bloco_atual:
            blocos.append(" ".join(bloco_atual))
            bloco_atual = [p]
            palavras_atuais = num_palavras_p
        else:
            bloco_atual.append(p)
            palavras_atuais += num_palavras_p

    if bloco_atual:
        blocos.append(" ".join(bloco_atual))

    return blocos


if __name__ == "__main__":
    import sys
    caminho = sys.argv[1] if len(sys.argv) > 1 else "exemplo.pdf"
    info = extrair_texto_pdf(caminho)
    if info.sucesso:
        print(f"Sucesso: {info.nome_arquivo} ({info.total_paginas} páginas)")
        print(f"Amostra:\n{info.texto_extraido[:300]}...")
    else:
        print(f"Falha: {info.erro}")
