#!/usr/bin/env python3
"""Interface Gráfica Desktop para Treinamento e Curadoria do NeuroGraph.

Permite:
1. Buscar e capturar vídeos do YouTube por temas ou URLs.
2. Carregar e processar documentos PDF com seleção nativa de arquivos.
3. Curadoria de dados com a IA do ChatGPT (OpenAI) ou modo heurístico local.
4. Treinamento visual do modelo com logs e métricas em tempo real.
5. Painel de teste de inferência para conversar com o NeuroGraph treinado.
6. Gerenciamento e visualização do dataset acumulado em tabela.
"""
from __future__ import annotations

import json
import os
import queue
import sys
import threading
import time
import tkinter as tk
from pathlib import Path
from tkinter import filedialog, messagebox, ttk

# Configuração de caminhos
DIR_TREINO = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_TREINO.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"

if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))
if str(DIR_TREINO) not in sys.path:
    sys.path.insert(0, str(DIR_TREINO))

from capturador_youtube import buscar_videos_youtube, obter_transcricao, salvar_transcricao_raw
from curador_chatgpt import (
    curar_pdf_com_chatgpt,
    curar_transcricao_com_chatgpt,
    salvar_pares_processados,
    sugerir_referencias_em_portugues,
)
from leitor_pdf import extrair_texto_pdf
from treinador_neurograph import preparar_exemplos, treinar_neurograph

try:
    from model import TokenGraph
except ImportError:
    TokenGraph = None


class NeuroGraphDesktopApp:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("NeuroGraph Studio — Treinamento & Curadoria")
        self.root.geometry("980x720")
        self.root.minsize(860, 600)

        # Configura estilo
        self.style = ttk.Style()
        try:
            self.style.theme_use("clam")
        except Exception:
            pass

        self.log_queue: queue.Queue[str] = queue.Queue()
        self.is_busy = False

        self._criar_layout()
        self._verificar_status_inicial()
        self.root.after(100, self._processar_logs_queue)

    def _criar_layout(self):
        # 1. Top Bar com Status e Chave API
        top_frame = ttk.LabelFrame(self.root, text=" Configurações & Status ", padding=10)
        top_frame.pack(fill="x", padx=12, pady=6)

        lbl_api = ttk.Label(top_frame, text="Chave OpenAI (Opcional):")
        lbl_api.grid(row=0, column=0, sticky="w", padx=4, pady=2)

        self.var_api_key = tk.StringVar(value=os.environ.get("OPENAI_API_KEY", ""))
        self.ent_api_key = ttk.Entry(top_frame, textvariable=self.var_api_key, show="*", width=38)
        self.ent_api_key.grid(row=0, column=1, sticky="w", padx=4, pady=2)

        self.lbl_status_api = ttk.Label(top_frame, text="Verificando...", font=("Segoe UI", 9, "bold"))
        self.lbl_status_api.grid(row=0, column=2, sticky="w", padx=10, pady=2)

        self.lbl_status_modelo = ttk.Label(top_frame, text="Modelo: Verificando...", foreground="#333")
        self.lbl_status_modelo.grid(row=0, column=3, sticky="e", padx=10, pady=2)
        top_frame.columnconfigure(3, weight=1)

        # 2. Notebook com Abas
        self.notebook = ttk.Notebook(self.root)
        self.notebook.pack(fill="both", expand=True, padx=12, pady=6)

        # Abas
        self.tab_youtube = ttk.Frame(self.notebook, padding=12)
        self.tab_pdf = ttk.Frame(self.notebook, padding=12)
        self.tab_chat = ttk.Frame(self.notebook, padding=12)
        self.tab_dataset = ttk.Frame(self.notebook, padding=12)

        self.notebook.add(self.tab_youtube, text="  🎥 Treinar via YouTube  ")
        self.notebook.add(self.tab_pdf, text="  📄 Treinar via PDF  ")
        self.notebook.add(self.tab_chat, text="  💬 Conversar / Testar NeuroGraph  ")
        self.notebook.add(self.tab_dataset, text="  📊 Visualizar Dataset  ")

        self._construir_aba_youtube()
        self._construir_aba_pdf()
        self._construir_aba_chat()
        self._construir_aba_dataset()

        # 3. Painel de Log em Tempo Real
        log_frame = ttk.LabelFrame(self.root, text=" Console de Operações em Tempo Real ", padding=8)
        log_frame.pack(fill="both", expand=False, padx=12, pady=6)

        self.progress_bar = ttk.Progressbar(log_frame, mode="indeterminate")
        self.progress_bar.pack(fill="x", padx=4, pady=2)

        self.txt_log = tk.Text(log_frame, height=9, bg="#1e1e1e", fg="#dcdcdc", font=("Consolas", 9))
        self.txt_log.pack(side="left", fill="both", expand=True, padx=4, pady=4)

        scroll_log = ttk.Scrollbar(log_frame, orient="vertical", command=self.txt_log.yview)
        scroll_log.pack(side="right", fill="y")
        self.txt_log.config(yscrollcommand=scroll_log.set)

    # -------------------------------------------------------------
    # ABA YOUTUBE
    # -------------------------------------------------------------
    def _construir_aba_youtube(self):
        # Grupo Busca por Tema
        grp_busca = ttk.LabelFrame(self.tab_youtube, text=" Modo 1: Busca por Tema Educativo no YouTube ", padding=10)
        grp_busca.pack(fill="x", pady=6)

        ttk.Label(grp_busca, text="Tema ou Conceito (ex: energia solar, fotossíntese, física):").grid(row=0, column=0, sticky="w", pady=4)
        self.var_tema = tk.StringVar(value="energia solar fotovoltaica")
        ttk.Entry(grp_busca, textvariable=self.var_tema, width=45).grid(row=0, column=1, sticky="w", padx=6, pady=4)

        ttk.Label(grp_busca, text="Qtd. Vídeos:").grid(row=0, column=2, sticky="e", padx=4, pady=4)
        self.var_qtd_videos = tk.IntVar(value=2)
        ttk.Spinbox(grp_busca, from_=1, to=5, textvariable=self.var_qtd_videos, width=5).grid(row=0, column=3, sticky="w", padx=4, pady=4)

        btn_busca = ttk.Button(grp_busca, text="🔍 Buscar, Curar e Treinar", command=self._acao_buscar_youtube)
        btn_busca.grid(row=0, column=4, sticky="e", padx=8, pady=4)
        grp_busca.columnconfigure(4, weight=1)

        # Grupo URL Específica
        grp_url = ttk.LabelFrame(self.tab_youtube, text=" Modo 2: Processar Vídeo Específico ", padding=10)
        grp_url.pack(fill="x", pady=6)

        ttk.Label(grp_url, text="URL ou ID do Vídeo do YouTube:").grid(row=0, column=0, sticky="w", pady=4)
        self.var_url_video = tk.StringVar()
        ttk.Entry(grp_url, textvariable=self.var_url_video, width=55).grid(row=0, column=1, sticky="w", padx=6, pady=4)

        btn_url = ttk.Button(grp_url, text="▶️ Processar Vídeo e Treinar", command=self._acao_video_direto)
        btn_url.grid(row=0, column=2, sticky="e", padx=8, pady=4)
        grp_url.columnconfigure(2, weight=1)

        # Informações didáticas
        lbl_info = ttk.Label(
            self.tab_youtube,
            text="O algoritmo localiza legendas em português (oficiais ou automáticas), remove ruídos e vinhetas,\n"
                 "envia para a IA do ChatGPT estruturar afirmações conceituais concisas e treina os pesos do NeuroGraph.",
            foreground="#555",
            justify="left",
        )
        lbl_info.pack(anchor="w", pady=10)

    # -------------------------------------------------------------
    # ABA PDF
    # -------------------------------------------------------------
    def _construir_aba_pdf(self):
        grp_pdf = ttk.LabelFrame(self.tab_pdf, text=" Seleção de Documento PDF para Treinamento ", padding=12)
        grp_pdf.pack(fill="x", pady=8)

        ttk.Label(grp_pdf, text="Arquivo PDF Local:").grid(row=0, column=0, sticky="w", pady=4)
        self.var_caminho_pdf = tk.StringVar()
        ttk.Entry(grp_pdf, textvariable=self.var_caminho_pdf, width=60).grid(row=0, column=1, sticky="w", padx=6, pady=4)

        btn_procurar = ttk.Button(grp_pdf, text="📁 Selecionar PDF...", command=self._acao_selecionar_pdf)
        btn_procurar.grid(row=0, column=2, sticky="w", padx=6, pady=4)

        ttk.Label(grp_pdf, text="Máximo de Fatos/Perguntas a Extrair:").grid(row=1, column=0, sticky="w", pady=8)
        self.var_max_pares_pdf = tk.IntVar(value=15)
        ttk.Spinbox(grp_pdf, from_=5, to=50, textvariable=self.var_max_pares_pdf, width=6).grid(row=1, column=1, sticky="w", padx=6, pady=8)

        btn_treinar_pdf = ttk.Button(grp_pdf, text="🚀 Processar PDF e Treinar NeuroGraph", command=self._acao_treinar_pdf)
        btn_treinar_pdf.grid(row=1, column=2, sticky="e", padx=6, pady=8)

        lbl_pdf_info = ttk.Label(
            self.tab_pdf,
            text="Ideal para apostilas, artigos, livros e resumos didáticos em formato PDF.\n"
                 "O texto é extraído preservando sentenças e enviado para a IA formular perguntas e respostas atômicas.",
            foreground="#555",
            justify="left",
        )
        lbl_pdf_info.pack(anchor="w", pady=10)

    # -------------------------------------------------------------
    # ABA CHAT / TESTE
    # -------------------------------------------------------------
    def _construir_aba_chat(self):
        ttk.Label(self.tab_chat, text="Faça perguntas em português para testar as associações aprendidas pelo NeuroGraph:").pack(anchor="w", pady=2)

        input_frame = ttk.Frame(self.tab_chat)
        input_frame.pack(fill="x", pady=6)

        self.var_pergunta = tk.StringVar()
        self.ent_pergunta = ttk.Entry(input_frame, textvariable=self.var_pergunta, font=("Segoe UI", 10))
        self.ent_pergunta.pack(side="left", fill="x", expand=True, padx=(0, 6))
        self.ent_pergunta.bind("<Return>", lambda e: self._acao_perguntar())

        btn_perguntar = ttk.Button(input_frame, text="Perguntar", command=self._acao_perguntar)
        btn_perguntar.pack(side="right")

        # Histórico de Respostas
        self.txt_chat = tk.Text(self.tab_chat, height=14, bg="#ffffff", fg="#222222", font=("Segoe UI", 10), wrap="word")
        self.txt_chat.pack(fill="both", expand=True, pady=6)

        scroll_chat = ttk.Scrollbar(self.txt_chat, orient="vertical", command=self.txt_chat.yview)
        scroll_chat.pack(side="right", fill="y")
        self.txt_chat.config(yscrollcommand=scroll_chat.set)

    # -------------------------------------------------------------
    # ABA DATASET
    # -------------------------------------------------------------
    def _construir_aba_dataset(self):
        btn_frame = ttk.Frame(self.tab_dataset)
        btn_frame.pack(fill="x", pady=4)

        btn_recarr = ttk.Button(btn_frame, text="🔄 Atualizar Lista", command=self._carregar_tabela_dataset)
        btn_recarr.pack(side="left", padx=4)

        btn_retreinar = ttk.Button(btn_frame, text="⚡ Retreinar Modelo com Todo o Dataset", command=self._acao_retreinar_tudo)
        btn_retreinar.pack(side="left", padx=6)

        self.lbl_total_dataset = ttk.Label(btn_frame, text="Total: 0 fatos", font=("Segoe UI", 9, "bold"))
        self.lbl_total_dataset.pack(side="right", padx=6)

        # Tabela Treeview
        cols = ("question", "answer", "category", "origem")
        self.tree = ttk.Treeview(self.tab_dataset, columns=cols, show="headings", height=12)
        self.tree.heading("question", text="Pergunta Conceitual")
        self.tree.heading("answer", text="Resposta Extraída")
        self.tree.heading("category", text="Categoria")
        self.tree.heading("origem", text="Origem")

        self.tree.column("question", width=260)
        self.tree.column("answer", width=420)
        self.tree.column("category", width=110)
        self.tree.column("origem", width=120)

        self.tree.pack(fill="both", expand=True, pady=6)
        scroll_tree = ttk.Scrollbar(self.tree, orient="vertical", command=self.tree.yview)
        scroll_tree.pack(side="right", fill="y")
        self.tree.config(yscrollcommand=scroll_tree.set)

        self._carregar_tabela_dataset()

    # -------------------------------------------------------------
    # FUNÇÕES DE EXECUÇÃO EM SEGUNDO PLANO
    # -------------------------------------------------------------
    def log(self, mensagem: str):
        self.log_queue.put(mensagem)

    def _processar_logs_queue(self):
        while not self.log_queue.empty():
            msg = self.log_queue.get_nowait()
            self.txt_log.insert(tk.END, msg + "\n")
            self.txt_log.see(tk.END)
        self.root.after(100, self._processar_logs_queue)

    def _verificar_status_inicial(self):
        key = self.var_api_key.get().strip()
        if key:
            self.lbl_status_api.config(text="● OpenAI Ativa", foreground="#2e7d32")
        else:
            self.lbl_status_api.config(text="○ Modo Heurístico Local", foreground="#b26a00")

        caminho_mod = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        if caminho_mod.exists():
            tam_mb = caminho_mod.stat().st_size / (1024 * 1024)
            self.lbl_status_modelo.config(text=f"Modelo: {caminho_mod.name} ({tam_mb:.1f} MB)")
        else:
            self.lbl_status_modelo.config(text="Modelo: Não treinado ainda")

    def _iniciar_tarefa(self, func, *args):
        if self.is_busy:
            messagebox.showwarning("Ocupado", "Um treinamento ou processamento já está em andamento. Aguarde a conclusão.")
            return
        self.is_busy = True
        self.progress_bar.start(10)

        # Atualiza a chave no ambiente se tiver sido digitada
        api_key = self.var_api_key.get().strip()
        if api_key:
            os.environ["OPENAI_API_KEY"] = api_key
            self.lbl_status_api.config(text="● OpenAI Ativa", foreground="#2e7d32")

        def wrapper():
            try:
                func(*args)
            except Exception as e:
                self.log(f"\n[ERRO FATAL] {e}")
            finally:
                self.is_busy = False
                self.root.after(0, self.progress_bar.stop)
                self.root.after(0, self._verificar_status_inicial)
                self.root.after(0, self._carregar_tabela_dataset)

        t = threading.Thread(target=wrapper, daemon=True)
        t.start()

    # -------------------------------------------------------------
    # AÇÕES DOS BOTÕES
    # -------------------------------------------------------------
    def _acao_buscar_youtube(self):
        tema = self.var_tema.get().strip()
        if not tema:
            messagebox.showwarning("Campo vazio", "Digite um tema para pesquisar.")
            return
        qtd = self.var_qtd_videos.get()
        self._iniciar_tarefa(self._tarefa_buscar_youtube, tema, qtd)

    def _tarefa_buscar_youtube(self, tema: str, qtd: int):
        self.log(f"\n{'='*50}\nIniciando busca no YouTube para: '{tema}'\n{'='*50}")
        sugestoes = sugerir_referencias_em_portugues(tema, n_sugestoes=qtd, api_key=self.var_api_key.get().strip())
        self.log(f"Sugestões de busca obtidas: {sugestoes}")

        pasta_raw = DIR_TREINO / "dados" / "raw"
        transcricoes_validas = []

        for query in sugestoes:
            videos = buscar_videos_youtube(query, max_resultados=1)
            for v in videos:
                self.log(f"Baixando transcrição de: '{v.title}' ({v.video_id})...")
                res = obter_transcricao(v.video_id, query=query, title=v.title)
                if res.sucesso:
                    salvar_transcricao_raw(res, pasta_raw)
                    transcricoes_validas.append(res)
                    self.log(f"  -> Sucesso: {res.num_trechos} trechos capturados.")
                else:
                    self.log(f"  -> Falha: {res.erro}")

        if not transcricoes_validas:
            self.log("[AVISO] Nenhuma transcrição em português pôde ser obtida.")
            return

        self.log("\nCurando transcrições com a IA...")
        todos_pares = []
        for t in transcricoes_validas:
            pares = curar_transcricao_com_chatgpt(
                texto_transcricao=t.raw_text,
                titulo_video=t.title,
                video_id=t.video_id,
                api_key=self.var_api_key.get().strip(),
            )
            todos_pares.extend(pares)
            self.log(f"  -> {len(pares)} fatos extraídos de [{t.video_id}].")

        pasta_proc = DIR_TREINO / "dados" / "processados"
        caminho_dataset = salvar_pares_processados(todos_pares, pasta_proc)
        self.log(f"Dataset salvo em: {caminho_dataset}")

        self.log("\nTreinando NeuroGraph com novos dados...")
        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        caminho_modelo = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        treinar_neurograph(exemplos, epochs=120, caminho_saida=caminho_modelo)
        self.log("\n✅ Concluído com sucesso!")

    def _acao_video_direto(self):
        url = self.var_url_video.get().strip()
        if not url:
            messagebox.showwarning("Campo vazio", "Cole a URL ou ID do vídeo.")
            return
        self._iniciar_tarefa(self._tarefa_video_direto, url)

    def _tarefa_video_direto(self, url: str):
        self.log(f"\n{'='*50}\nProcessando vídeo: {url}\n{'='*50}")
        res = obter_transcricao(url)
        if not res.sucesso:
            self.log(f"[ERRO] Falha ao obter transcrição: {res.erro}")
            return

        pasta_raw = DIR_TREINO / "dados" / "raw"
        salvar_transcricao_raw(res, pasta_raw)
        self.log(f"Transcrição capturada ({res.num_trechos} trechos). Curando com IA...")

        pares = curar_transcricao_com_chatgpt(
            texto_transcricao=res.raw_text,
            titulo_video=res.title,
            video_id=res.video_id,
            api_key=self.var_api_key.get().strip(),
        )
        self.log(f"Extraídos {len(pares)} fatos conceituais.")

        caminho_dataset = salvar_pares_processados(pares, DIR_TREINO / "dados" / "processados")
        self.log(f"Dataset atualizado em {caminho_dataset}. Treinando NeuroGraph...")

        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        caminho_modelo = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        treinar_neurograph(exemplos, epochs=120, caminho_saida=caminho_modelo)
        self.log("\n✅ Concluído com sucesso!")

    def _acao_selecionar_pdf(self):
        caminho = filedialog.askopenfilename(
            title="Selecione um Documento PDF",
            filetypes=[("Arquivos PDF", "*.pdf"), ("Todos os Arquivos", "*.*")],
        )
        if caminho:
            self.var_caminho_pdf.set(caminho)

    def _acao_treinar_pdf(self):
        caminho = self.var_caminho_pdf.get().strip().strip('"\'')
        if not caminho or not Path(caminho).exists():
            messagebox.showwarning("PDF não selecionado", "Selecione um arquivo PDF válido antes de iniciar.")
            return
        max_p = self.var_max_pares_pdf.get()
        self._iniciar_tarefa(self._tarefa_treinar_pdf, caminho, max_p)

    def _tarefa_treinar_pdf(self, caminho_pdf: str, max_pares: int):
        p = Path(caminho_pdf)
        self.log(f"\n{'='*50}\nProcessando Documento PDF: '{p.name}'\n{'='*50}")
        info = extrair_texto_pdf(p)
        if not info.sucesso:
            self.log(f"[ERRO] Falha ao extrair texto do PDF: {info.erro}")
            return

        self.log(f"PDF extraído: {info.total_paginas} páginas, {info.num_palavras} palavras.")
        self.log("Curando com a IA para gerar perguntas e respostas conceituais...")

        pares = curar_pdf_com_chatgpt(
            texto_pdf=info.texto_extraido,
            nome_arquivo=p.name,
            max_pares_total=max_pares,
            api_key=self.var_api_key.get().strip(),
        )
        self.log(f"Gerados {len(pares)} pares de pergunta e resposta a partir do PDF.")

        caminho_dataset = salvar_pares_processados(pares, DIR_TREINO / "dados" / "processados")
        self.log("Treinando o NeuroGraph com o dataset consolidado...")

        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        caminho_modelo = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        treinar_neurograph(exemplos, epochs=120, caminho_saida=caminho_modelo)
        self.log("\n✅ Treinamento a partir do PDF concluído com sucesso!")

    def _acao_perguntar(self):
        pergunta = self.var_pergunta.get().strip()
        if not pergunta:
            return

        caminho_modelo = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        if not caminho_modelo.exists():
            caminho_modelo = DIR_CONTEXTUAL_V7 / "results" / "neurograph_contextual_v7.ngs"

        if not caminho_modelo.exists():
            messagebox.showerror("Modelo Ausente", "Nenhum arquivo de modelo (.ngs) encontrado.")
            return

        try:
            modelo = TokenGraph.load(caminho_modelo)
            gen = modelo.generate(pergunta)

            self.txt_chat.insert(tk.END, f"Você: {pergunta}\n", "user")
            self.txt_chat.insert(tk.END, f"NeuroGraph: {gen.text}\n", "bot")
            if gen.abstained:
                self.txt_chat.insert(tk.END, f"  (Abstenção pelo motivo: {gen.reason})\n", "info")
            self.txt_chat.insert(tk.END, "\n")
            self.txt_chat.see(tk.END)
            self.var_pergunta.set("")

        except Exception as exc:
            messagebox.showerror("Erro de Inferência", str(exc))

    def _acao_retreinar_tudo(self):
        self._iniciar_tarefa(self._tarefa_retreinar_tudo)

    def _tarefa_retreinar_tudo(self):
        self.log(f"\n{'='*50}\nRetreinando modelo com todo o acervo consolidado...\n{'='*50}")
        caminho_dataset = DIR_TREINO / "dados" / "processados" / "dataset_curado.json"
        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        caminho_modelo = DIR_TREINO / "modelos" / "neurograph_youtube.ngs"
        treinar_neurograph(exemplos, epochs=140, caminho_saida=caminho_modelo)
        self.log("\n✅ Modelo retreinado e pronto!")

    def _carregar_tabela_dataset(self):
        for item in self.tree.get_children():
            self.tree.delete(item)

        caminho_dataset = DIR_TREINO / "dados" / "processados" / "dataset_curado.json"
        if caminho_dataset.exists():
            try:
                with caminho_dataset.open("r", encoding="utf-8") as f:
                    dados = json.load(f)
                self.lbl_total_dataset.config(text=f"Total: {len(dados)} fatos")
                for d in dados:
                    self.tree.insert(
                        "",
                        tk.END,
                        values=(
                            d.get("question", ""),
                            d.get("answer", ""),
                            d.get("category", ""),
                            d.get("origem", d.get("video_id", "")),
                        ),
                    )
            except Exception as e:
                self.log(f"Erro ao ler dataset na tabela: {e}")
        else:
            self.lbl_total_dataset.config(text="Total: 0 fatos")


def main():
    root = tk.Tk()
    app = NeuroGraphDesktopApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
