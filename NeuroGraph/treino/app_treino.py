#!/usr/bin/env python3
"""Aplicativo Integrador: Captura do YouTube, Curadoria com ChatGPT e Treino do NeuroGraph."""
from __future__ import annotations

import sys

# Força codificação UTF-8 com substituição segura para evitar UnicodeEncodeError em pipes Windows
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

import argparse
import json
import logging
import os
from pathlib import Path

DIR_TREINO = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_TREINO.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"

if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))

from capturador_youtube import buscar_videos_youtube, obter_transcricao, salvar_transcricao_raw
from curador_chatgpt import (
    curar_pdf_com_chatgpt,
    curar_transcricao_com_chatgpt,
    salvar_pares_processados,
    sugerir_referencias_em_portugues,
)
from leitor_pdf import extrair_texto_pdf
from treinador_neurograph import preparar_exemplos, testar_inferencia, treinar_neurograph

try:
    from model import TokenGraph
except ImportError:
    TokenGraph = None


def carregar_config() -> dict:
    caminho = DIR_TREINO / "config.json"
    if caminho.exists():
        try:
            with caminho.open("r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def processar_tema_completo(
    tema: str,
    max_videos: int = 3,
    max_pares_por_video: int = 8,
    api_key: str | None = None,
    executar_treino: bool = True,
    caminho_modelo: Path | None = None,
) -> Path:
    """Executa o ciclo completo:

    1. Busca termos de referência com ChatGPT em PT-BR.
    2. Captura vídeos e transcrições do YouTube.
    3. Cura e extrai fatos conceituais.
    4. Atualiza o dataset e treina o NeuroGraph.
    """
    print("\n" + "=" * 65)
    print(f"=== INICIANDO PIPELINE DE TREINAMENTO: '{tema.upper()}' ===")
    print("=" * 65)

    # 1. Sugestões de referências com ChatGPT
    print(f"\n[1/4] Consultando referências em português para: '{tema}'...")
    sugestoes = sugerir_referencias_em_portugues(tema, n_sugestoes=max_videos, api_key=api_key)
    print("Termos de busca selecionados:")
    for i, s in enumerate(sugestoes, 1):
        print(f"  {i}. {s}")

    # 2. Captura de transcrições do YouTube
    print("\n[2/4] Buscando vídeos e baixando transcrições...")
    pasta_raw = DIR_TREINO / "dados" / "raw"
    transcricoes_validas = []

    for query in sugestoes:
        videos = buscar_videos_youtube(query, max_resultados=1)
        for v in videos:
            print(f"  -> Coletando '{v.title}' ({v.video_id})...")
            resultado = obter_transcricao(v.video_id, query=query, title=v.title)
            if resultado.sucesso:
                salvar_transcricao_raw(resultado, pasta_raw)
                transcricoes_validas.append(resultado)
                print(f"     [OK] {resultado.num_trechos} trechos capturados.")
            else:
                print(f"     [AVISO] {resultado.erro}")

    if not transcricoes_validas:
        print("\n[ERRO] Nenhuma transcrição em português pôde ser obtida para os vídeos buscados.")
        return DIR_TREINO / "dados" / "processados" / "dataset_curado.json"

    # 3. Curadoria com ChatGPT
    print("\n[3/4] Curando transcrições com IA (extração de fatos conceituais)...")
    todos_pares = []
    for t in transcricoes_validas:
        pares = curar_transcricao_com_chatgpt(
            texto_transcricao=t.raw_text,
            titulo_video=t.title,
            video_id=t.video_id,
            max_pares=max_pares_por_video,
            api_key=api_key,
        )
        todos_pares.extend(pares)
        print(f"  -> Extraídos {len(pares)} fatos de [{t.video_id}].")

    pasta_processados = DIR_TREINO / "dados" / "processados"
    caminho_dataset = salvar_pares_processados(todos_pares, pasta_processados)
    print(f"\n[OK] Dataset consolidado com {len(todos_pares)} novos fatos em: {caminho_dataset}")

    # 4. Treinamento
    if executar_treino:
        print("\n[4/4] Treinando e atualizando o NeuroGraph...")
        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        alvo_modelo = caminho_modelo or (DIR_TREINO / "modelos" / "neurograph_youtube.ngs")
        modelo = treinar_neurograph(exemplos, epochs=120, caminho_saida=alvo_modelo)

        # Validação automática com os conceitos recém-aprendidos
        perguntas_teste = [p.question for p in todos_pares[:3]]
        if perguntas_teste:
            print("\n[TESTE] Respostas do NeuroGraph sobre o novo conteúdo:")
            testar_inferencia(modelo, perguntas_teste)

    print("\n[CONCLUIDO] Ciclo finalizado com sucesso!")
    return caminho_dataset


def processar_video_individual(
    url_ou_id: str,
    api_key: str | None = None,
    executar_treino: bool = True,
    caminho_modelo: Path | None = None,
) -> None:
    """Captura e cura um único vídeo informado diretamente pelo usuário."""
    print(f"\nObtendo transcrição para o vídeo: {url_ou_id}...")
    resultado = obter_transcricao(url_ou_id)
    if not resultado.sucesso:
        print(f"[ERRO] Falha ao obter transcrição: {resultado.erro}")
        return

    pasta_raw = DIR_TREINO / "dados" / "raw"
    salvar_transcricao_raw(resultado, pasta_raw)

    print("Curando texto do vídeo com a IA...")
    pares = curar_transcricao_com_chatgpt(
        texto_transcricao=resultado.raw_text,
        titulo_video=resultado.title,
        video_id=resultado.video_id,
        api_key=api_key,
    )

    caminho_dataset = salvar_pares_processados(pares, DIR_TREINO / "dados" / "processados")
    print(f"Extraídos {len(pares)} pares gravados em {caminho_dataset}.")

    if executar_treino:
        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        alvo_modelo = caminho_modelo or (DIR_TREINO / "modelos" / "neurograph_youtube.ngs")
        modelo = treinar_neurograph(exemplos, epochs=120, caminho_saida=alvo_modelo)
        if pares:
            testar_inferencia(modelo, [pares[0].question])


def processar_pdf_completo(
    caminho_pdf: str,
    max_pares: int = 15,
    api_key: str | None = None,
    executar_treino: bool = True,
    caminho_modelo: Path | None = None,
) -> Path | None:
    """Extrai texto de um documento PDF, gera perguntas e respostas usando IA e treina o NeuroGraph."""
    caminho = Path(caminho_pdf).resolve()
    print("\n" + "=" * 65)
    print(f"=== PROCESSANDO DOCUMENTO PDF: '{caminho.name}' ===")
    print("=" * 65)

    # 1. Leitura e extração do PDF
    print(f"\n[1/3] Extraindo texto do PDF '{caminho.name}'...")
    pdf_info = extrair_texto_pdf(caminho)
    if not pdf_info.sucesso:
        print(f"[ERRO] Falha ao ler PDF: {pdf_info.erro}")
        return None

    print(f"  -> Total de páginas: {pdf_info.total_paginas}")
    print(f"  -> Total de palavras extraídas: {pdf_info.num_palavras}")

    # Salva cópia do texto bruto para auditoria
    pasta_raw = DIR_TREINO / "dados" / "raw"
    pasta_raw.mkdir(parents=True, exist_ok=True)
    arquivo_raw = pasta_raw / f"pdf_{caminho.stem}.json"
    with arquivo_raw.open("w", encoding="utf-8") as f:
        json.dump({
            "arquivo": caminho.name,
            "caminho_origem": str(caminho),
            "total_paginas": pdf_info.total_paginas,
            "num_palavras": pdf_info.num_palavras,
            "texto": pdf_info.texto_extraido,
        }, f, ensure_ascii=False, indent=2)

    # 2. Curadoria com ChatGPT (geração de perguntas e respostas)
    print("\n[2/3] Gerando perguntas e respostas conceituais com a IA...")
    pares = curar_pdf_com_chatgpt(
        texto_pdf=pdf_info.texto_extraido,
        nome_arquivo=caminho.name,
        max_pares_total=max_pares,
        api_key=api_key,
    )

    if not pares:
        print("[AVISO] Nenhum par de perguntas e respostas pôde ser extraído do PDF.")
        return None

    pasta_processados = DIR_TREINO / "dados" / "processados"
    caminho_dataset = salvar_pares_processados(pares, pasta_processados)
    print(f"  -> {len(pares)} fatos conceituais extraídos e adicionados a '{caminho_dataset.name}'.")

    # Exibe amostra dos pares gerados
    print("\nAmostra de Perguntas e Respostas geradas:")
    for p in pares[:3]:
        print(f"  P: {p.question}")
        print(f"  R: {p.answer}\n")

    # 3. Treinamento
    if executar_treino:
        print("[3/3] Treinando e atualizando os pesos do NeuroGraph...")
        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        alvo_modelo = caminho_modelo or (DIR_TREINO / "modelos" / "neurograph_youtube.ngs")
        modelo = treinar_neurograph(exemplos, epochs=120, caminho_saida=alvo_modelo)

        # Validação do aprendizado
        perguntas_teste = [p.question for p in pares[:3]]
        if perguntas_teste:
            print("\n[TESTE] Inferência do NeuroGraph sobre o conteúdo do PDF:")
            testar_inferencia(modelo, perguntas_teste)

    print("\n[CONCLUIDO] Processamento do PDF finalizado com sucesso!")
    return caminho_dataset


def consultar_modelo(pergunta: str, caminho_modelo: Path | None = None) -> None:
    """Faz uma pergunta ao modelo NeuroGraph treinado (.ngs)."""
    if caminho_modelo is None:
        caminho_modelo = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        if not caminho_modelo.exists():
            caminho_modelo = DIR_CONTEXTUAL_V7 / "results" / "neurograph_contextual_v7.ngs"

    if not caminho_modelo.exists():
        print(f"[ERRO] Arquivo de modelo não encontrado em {caminho_modelo}")
        return

    modelo = TokenGraph.load(caminho_modelo)
    gen = modelo.generate(pergunta)
    print("\n" + "=" * 50)
    print(f"Modelo: {caminho_modelo.name}")
    print(f"Pergunta: {pergunta}")
    print(f"Resposta: {gen.text}")
    print(f"Absteve?: {gen.abstained} (motivo: {gen.reason})")
    print("=" * 50)


def menu_interativo() -> None:
    """Interface de console interativa com menu amigável."""
    cfg = carregar_config()
    temas = cfg.get("temas_padrao_sugeridos", [
        "energia solar e renovável",
        "biologia celular e fotossíntese",
        "computação e algoritmos",
    ])

    while True:
        print("\n" + "=" * 60)
        print("=== TREINADOR DO NEUROGRAPH VIA YOUTUBE, PDF & CHATGPT ===")
        print("=" * 60)
        print("1. Buscar tema educativo no YouTube, curar e treinar")
        print("2. Processar URL ou ID específico de vídeo do YouTube")
        print("3. Processar documento PDF local (extrair texto e curar com IA)")
        print("4. Retreinar NeuroGraph com todo o dataset curado acumulado")
        print("5. Fazer uma pergunta ao NeuroGraph treinado")
        print("6. Ver estatísticas do dataset atual")
        print("0. Sair")
        print("=" * 60)
        opcao = input("Escolha uma opção: ").strip()

        if opcao == "1":
            print("\nTemas sugeridos:")
            for i, t in enumerate(temas, 1):
                print(f"  {i}. {t}")
            escolha = input("\nDigite o número do tema ou escreva um novo tema: ").strip()
            if escolha.isdigit() and 1 <= int(escolha) <= len(temas):
                tema_escolhido = temas[int(escolha) - 1]
            else:
                tema_escolhido = escolha if escolha else temas[0]

            qtd = input("Quantidade de vídeos para buscar (padrão 2): ").strip()
            max_v = int(qtd) if qtd.isdigit() and int(qtd) > 0 else 2
            processar_tema_completo(tema_escolhido, max_videos=max_v, executar_treino=True)

        elif opcao == "2":
            url = input("\nCole a URL ou ID do vídeo do YouTube: ").strip()
            if url:
                processar_video_individual(url, executar_treino=True)

        elif opcao == "3":
            caminho_pdf = input("\nDigite o caminho para o arquivo PDF: ").strip()
            # Remove aspas caso o usuário tenha colado com aspas
            caminho_pdf = caminho_pdf.strip('"\'')
            if caminho_pdf:
                max_p = input("Máximo de perguntas a extrair (padrão 15): ").strip()
                n_pares = int(max_p) if max_p.isdigit() and int(max_p) > 0 else 15
                processar_pdf_completo(caminho_pdf, max_pares=n_pares, executar_treino=True)

        elif opcao == "4":
            print("\nCarregando dataset e preparando treinamento...")
            exemplos, _ = preparar_exemplos(incluir_base=True)
            caminho_modelo = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
            modelo = treinar_neurograph(exemplos, epochs=140, caminho_saida=caminho_modelo)
            print(f"Treinamento finalizado. Modelo salvo em {caminho_modelo}.")

        elif opcao == "5":
            perg = input("\nDigite sua pergunta para o NeuroGraph: ").strip()
            if perg:
                consultar_modelo(perg)

        elif opcao == "6":
            caminho_dataset = DIR_TREINO / "dados" / "processados" / "dataset_curado.json"
            if caminho_dataset.exists():
                with caminho_dataset.open("r", encoding="utf-8") as f:
                    dados = json.load(f)
                print(f"\nTotal de pares curados acumulados: {len(dados)}")
                print("Últimos 3 pares:")
                for p in dados[-3:]:
                    print(f"  P: {p.get('question')}")
                    print(f"  R: {p.get('answer')}\n")
            else:
                print("\nNenhum dataset processado ainda.")

        elif opcao in ("0", "sair", "exit", "q"):
            print("\nEncerrando o aplicativo. Até breve!")
            break
        else:
            print("Opção inválida. Tente novamente.")


def main():
    parser = argparse.ArgumentParser(description="Capturador de textos do YouTube, PDF e Treinador do NeuroGraph")
    parser.add_argument("--tema", type=str, help="Tema educativo em português para pesquisar no YouTube, curar e treinar")
    parser.add_argument("--video", type=str, help="URL ou ID de vídeo específico do YouTube")
    parser.add_argument("--pdf", type=str, help="Caminho para documento PDF local para extrair texto, curar e treinar")
    parser.add_argument("--max-pares", type=int, default=15, help="Máximo de pares de perguntas e respostas a extrair do PDF")
    parser.add_argument("--max-videos", type=int, default=2, help="Máximo de vídeos para processar no tema")
    parser.add_argument("--api-key", type=str, help="Chave da API OpenAI (ou use a env OPENAI_API_KEY)")
    parser.add_argument("--topicos-10", action="store_true", help="Dispara o gerador de 10 tópicos com número aleatório de perguntas (nunca < 1000) e treina a rede")
    parser.add_argument("--lista-topicos", nargs="*", help="Lista opcional de 10 tópicos específicos")
    parser.add_argument("--min-pares", type=int, default=1000, help="Quantidade mínima de pares para o gerador de tópicos (padrão: 1000)")
    parser.add_argument("--treinar", action="store_true", help="Dispara o retreino com os dados já acumulados")
    parser.add_argument("--perguntar", type=str, help="Envia uma pergunta para o modelo treinado")
    parser.add_argument("--modelo", type=str, help="Caminho opcional para arquivo de pesos (.ngs)")

    args = parser.parse_args()

    if args.perguntar:
        caminho_mod = Path(args.modelo) if args.modelo else None
        consultar_modelo(args.perguntar, caminho_modelo=caminho_mod)
    elif args.topicos_10:
        from treinar_10_topicos import executar_treinamento_10_topicos
        caminho_mod = Path(args.modelo) if args.modelo else None
        executar_treinamento_10_topicos(
            topicos=args.lista_topicos,
            min_total=max(1, args.min_pares),
            api_key=args.api_key,
            treinar_modelo=True,
            caminho_modelo=caminho_mod,
        )
    elif args.treinar:
        exemplos, _ = preparar_exemplos(incluir_base=True)
        caminho_saida = Path(args.modelo) if args.modelo else (DIR_TREINO / "modelos" / "neurograph_youtube.ngs")
        treinar_neurograph(exemplos, epochs=140, caminho_saida=caminho_saida)
    elif args.pdf:
        caminho_mod = Path(args.modelo) if args.modelo else None
        processar_pdf_completo(args.pdf, max_pares=args.max_pares, api_key=args.api_key, executar_treino=True, caminho_modelo=caminho_mod)
    elif args.video:
        caminho_mod = Path(args.modelo) if args.modelo else None
        processar_video_individual(args.video, api_key=args.api_key, executar_treino=True, caminho_modelo=caminho_mod)
    elif args.tema:
        caminho_mod = Path(args.modelo) if args.modelo else None
        processar_tema_completo(args.tema, max_videos=args.max_videos, api_key=args.api_key, executar_treino=True, caminho_modelo=caminho_mod)
    else:
        menu_interativo()


if __name__ == "__main__":
    main()
