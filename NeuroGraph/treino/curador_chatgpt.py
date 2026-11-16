#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Módulo de Curadoria com IA (OpenAI / LLM Local via INI) para o NeuroGraph.

Responsabilidades:
1. Ler automaticamente a configuração de IA (Provedor, Modelo, Endpoint, Token) do neurograph_studio.ini.
2. Utilizar o LLM configurado (local Ollama/llama.cpp ou OpenAI) para sugerir buscas e extrair pares P&R.
3. Validar rigorosamente a qualidade gramatical e conceitual de cada par pergunta/resposta,
   bloqueando fragmentos truncados, pronomes soltos, jargões de vídeos ou repetições ("X é X é...").
4. Fornecer fallback heurístico limpo e seguro caso nenhum servidor de IA esteja acessível.
"""
from __future__ import annotations

import configparser
import json
import logging
import os
import re
import urllib.error
import urllib.request
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any

from capturador_youtube import eh_texto_em_portugues

logging.basicConfig(level=logging.INFO, format="[%(levelname)s] %(message)s")

DIR_TREINO = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_TREINO.parent

PROMPT_SISTEMA_CURADOR = """Você é um curador pedagógico e linguístico encarregado de extrair dados de treinamento para o NeuroGraph, uma rede neural associativa em português.

Sua tarefa:
Leia a transcrição de um vídeo educativo do YouTube e extraia afirmações e conceitos atômicos verdadeiros sobre o tema central do vídeo.
Para cada conceito identificado, crie um par no formato JSON:
- "question": Pergunta conceitual direta e completa em português minúsculo sobre um substantivo ou conceito claro (ex: "o que é história", "o que é gramática normativa", "como funciona o enem"). NUNCA crie perguntas com pronomes soltos ("o que é ele", "o que é elas", "o que é essa") nem fragmentos de frase ("o que é sabendo direitinho como", "o que é muito pequena").
- "answer": Resposta direta, afirmativa, factual e concisa (entre 8 e 30 palavras, frase completa sem cortar palavras no final e sem repetir o termo duas vezes como "história é história é").
- "context": Lista vazia [].
- "category": "youtube_curated"

Regras estritas:
1. Extraia APENAS definições e fatos conceituais reais e completos presentes no texto.
2. Ignore totalmente saudações ("olá", "meu nome é", "professora liz"), propagandas, avisos do canal, inscrições, comentários e frases coloquiais ("né", "tá", "galera", "gente").
3. Nunca corte palavras no meio nem termine respostas em preposições ou conjunções ("de", "que", "e", "para", "com").
4. Responda ESTRITAMENTE em formato JSON com uma lista de objetos: [{"question": "...", "answer": "...", "context": [], "category": "youtube_curated"}]
"""

PROMPT_SISTEMA_CURADOR_PDF = """Você é um curador pedagógico e linguístico encarregado de extrair dados de treinamento para o NeuroGraph, uma rede neural associativa em português.

Sua tarefa:
Leia o trecho de um documento ou livro em PDF e extraia definições e conceitos atômicos verdadeiros.
Para cada conceito identificado, crie um par no formato JSON:
- "question": Pergunta conceitual direta em português minúsculo sobre um termo ou conceito claro (ex: "o que é fotossíntese", "qual a função das mitocôndrias").
- "answer": Resposta direta, afirmativa e concisa (entre 8 e 30 palavras, frase completa e gramaticalmente correta).
- "context": Lista vazia [].
- "category": "pdf_curated"

Regras estritas:
1. Extraia APENAS informações factuais e conceitos completos presentes no texto.
2. Ignore números de página, cabeçalhos, rodapés, sumários, cláusulas jurídicas truncadas e referências bibliográficas.
3. Nunca crie perguntas sobre pronomes ("o que é ela") ou fragmentos incompletos.
4. Responda ESTRITAMENTE em formato JSON com uma lista de objetos: [{"question": "...", "answer": "...", "context": [], "category": "pdf_curated"}]
"""

PROMPT_SISTEMA_SUGESTOES = """Você é um especialista em educação e currículo científico em língua portuguesa.
O usuário fornecerá um tema geral (ex: "história", "gramática", "enem", "energia solar").
Gere uma lista de buscas curtas em português ideais para encontrar vídeos didáticos no YouTube
com explicações conceituais claras de "o que é", "como funciona" ou "resumo de".
Retorne ESTRITAMENTE um array JSON de strings, por exemplo:
["o que é energia solar fotovoltaica", "como funciona o inversor solar"]
"""

# Palavras proibidas no início ou fim do sujeito de uma pergunta ("o que é <sujeito>")
PALAVRAS_INVALIDAS_INICIO_SUJEITO = frozenset({
    # Pronomes e demonstrativos soltos
    "ele", "ela", "eles", "elas", "isso", "isto", "aquilo", "essa", "esse",
    "este", "esta", "essas", "esses", "estes", "estas", "aquele", "aquela",
    "aqueles", "aquelas", "você", "vocês", "nós", "gente", "meu", "minha",
    "meus", "minhas", "seu", "sua", "seus", "suas", "nosso", "nossa",
    "quem", "qual", "quais", "algo", "tudo", "nada", "alguém", "ninguém",
    "outro", "outra", "outros", "outras", "mesmo", "mesma", "cada", "todo",
    "toda", "todos", "todas", "algum", "alguma", "alguns", "algumas",
    "nenhum", "nenhuma", "tal", "tais", "certo", "certa", "qualquer",
    # Advérbios, conjunções, preposições e partículas coloquiais
    "também", "não", "sim", "muito", "muita", "muitos", "muitas", "pouco",
    "pouca", "poucos", "poucas", "mais", "menos", "ainda", "já", "então",
    "assim", "aqui", "ali", "lá", "cá", "hoje", "ontem", "amanhã", "agora",
    "sempre", "nunca", "jamais", "vezes", "para", "pra", "por", "pelo",
    "pela", "pelos", "pelas", "com", "sem", "como", "quando", "onde",
    "porque", "porquê", "mas", "porém", "contudo", "todavia", "entretanto",
    "ou", "se", "que", "de", "do", "da", "dos", "das", "em", "no", "na",
    "nos", "nas", "num", "numa", "ao", "aos", "à", "às", "entre", "sobre",
    "sob", "perante", "segundo", "conforme", "mediante", "salvo", "exceto",
    "além", "aquém", "abaixo", "acima", "dentro", "fora", "perto", "longe",
    "atrás", "frente", "depois", "antes", "durante", "apenas", "somente",
    "só", "quase", "talvez", "acaso", "inclusive", "aliás", "afinal",
    "enfim", "pronto", "claro", "lógico", "óbvio", "simplesmente",
    "exatamente", "justamente", "realmente", "basicamente", "normalmente",
    "geralmente", "principalmente", "efetivamente", "necessariamente",
    "especialmente", "inicialmente", "atualmente", "antigamente",
    # Saudações, interjeições e jargões de aula/vídeo
    "olá", "oi", "bom", "boa", "bem", "mal", "eh", "né", "tá", "ah", "oh",
    "opa", "cara", "galera", "pessoal", "professor", "professora", "aula",
    "vídeo", "canal", "inscrito", "inscreva", "minicurso", "link", "card",
    # Verbos e fragmentos comuns de ASR
    "sabendo", "inscreve", "mostrar", "preparando", "chegar", "fazendo",
    "exibir", "ensinar", "apagar", "saber", "pisa", "usa", "vem", "preste",
    "pode", "podem", "tem", "têm", "vai", "vão", "fazer", "ter", "ser",
    "estar", "está", "estão", "foi", "foram", "era", "eram", "seria",
    "seriam", "olhada", "falando", "dizendo", "vendo", "lembrando",
    "estudando", "pensando", "olhando", "usando", "buscando", "tentando",
    "começando", "entrando", "saindo", "assistindo", "acompanhando",
    "deixou", "encontrou", "apagaria", "abre", "acontece", "existe",
    "existem", "parece", "precisa", "precisam", "quero", "quer", "querem",
    "posso", "consegue", "deve", "devem", "vamos", "vou", "sei", "sabe",
    "sabia", "acha", "acho", "disse", "fala", "falou", "explica", "explicou",
    "enfatizamos", "previstas", "seguinte", "importantes", "importante",
    "verdadeiro", "verdadeira", "grande", "pequeno", "pequena", "ilimitada",
    "completa", "vista", "abertura", "redução",
})

PALAVRAS_INVALIDAS_FIM_SUJEITO = frozenset({
    "não", "sim", "eh", "né", "tá", "que", "como", "quando", "onde",
    "porque", "porquê", "mas", "ou", "e", "de", "do", "da", "dos", "das",
    "em", "no", "na", "nos", "nas", "para", "pra", "por", "pelo", "pela",
    "com", "sem", "se", "ele", "ela", "eles", "elas", "isso", "isto",
    "essa", "esse", "este", "esta", "aqui", "ali", "lá", "então", "assim",
    "também", "ainda", "já", "muito", "muita", "mais", "menos", "um", "uma",
    "uns", "umas", "o", "a", "os", "as", "ao", "à", "gente", "galera",
    "pessoal", "cara", "tipo", "você", "vocês", "seu", "sua", "meu", "minha",
    "qual", "quais", "quem", "cujo", "cuja", "estão", "está", "são", "é",
    "foi", "vai", "tem", "pode", "deve", "quer", "acha", "disse",
})

PALAVRAS_PROIBIDAS_NO_SUJEITO = frozenset({
    "que", "como", "quando", "onde", "porque", "porquê", "mas", "porém",
    "então", "né", "tá", "eh", "ah", "galera", "gente", "pessoal", "cara",
    "você", "vocês", "inscreve", "inscreva", "canal", "vídeo", "minicurso",
    "professora", "professor", "olá", "sabia", "direitinho", "alguém",
    "ninguém", "apagaria", "trovão", "estômago", "chorar", "surtada",
})

PALAVRAS_TRUNCADAS_FIM_RESPOSTA = frozenset({
    # Preposições, artigos, conjunções e pronomes que jamais encerram uma definição válida
    "de", "do", "da", "dos", "das", "em", "no", "na", "nos", "nas", "num",
    "numa", "que", "e", "ou", "mas", "por", "para", "pra", "pelo", "pela",
    "pelos", "pelas", "com", "sem", "se", "como", "quando", "onde", "porque",
    "um", "uma", "uns", "umas", "o", "a", "os", "as", "ao", "aos", "à", "às",
    "seu", "sua", "seus", "suas", "meu", "minha", "nosso", "nossa", "este",
    "esta", "esse", "essa", "isso", "isto", "ele", "ela", "eles", "elas",
    "não", "sim", "muito", "mais", "menos", "tão", "qual", "quais", "quem",
    "foi", "são", "é", "está", "estão", "ser", "ter", "vai", "ir", "até",
    "sobre", "entre", "perante", "após", "ante", "contra", "desde", "já",
    "ainda", "também", "só", "apenas", "então", "assim", "tipo", "lá", "aqui",
    "ali", "né", "tá", "eh", "ah", "ó", "vê", "ver", "sei",
    # Radicais cortados ao meio por truncamento antigo de 90 caracteres
    "relaç", "mane", "jul", "melho", "cl", "plur", "di", "explora", "bras",
    "acontec", "gent", "ac", "estuda", "administr", "cadastr", "superi",
    "insc", "pu", "vincul", "escalon", "important", "merca", "co", "public",
    "modific", "subjet", "sentid", "ene", "pl", "te", "to", "ma", "v", "d",
    "m", "p", "c", "s", "r", "l", "n", "f", "b", "g", "t",
})

PADROES_RUIDO_RESPOSTA = (
    "é uma área do conhecimento dedicada ao estudo e aplicação prática de seus princípios",
    "opera através de métodos lógicos processos estruturados e boas práticas",
    "está no desenvolvimento prático científico e na solução de problemas",
    "incluem conceitos básicos regras claras e aplicação consistente",
    "serve para orientar ações organizar processos e alcançar resultados eficientes",
    "se inscreve no canal",
    "inscreva-se no canal",
    "ativa o sininho",
    "deixe o like",
    "curte o vídeo",
    "aqui no card",
    "deixei no card",
    "aqui na descrição",
    "aqui embaixo",
    "meu objetivo é ajudar você",
    "eu sou o professor",
    "eu sou a professora",
    "meu nome é",
    "sejam bem-vindos",
    "olá você sabia",
    "código do minicurso",
    "lady tal",
    "compreende os fundamentos teóricos e os métodos práticos",
    "permite compreender processos resolver problemas técnicos",
    "canal de vídeo focado",
    "programa de aprendizado de inglês",
    "plataforma de saúde masculina",
    "queda de cabelo no couro cabeludo",
    "peixe que vive em águas salgadas",
    "não há manutenção necessária, pois os buracos negros",
    "medida da qualidade e produtividade em operações de construção",
)


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
    if not texto:
        return ""
    t = str(texto).strip().casefold()
    # Remove quebras de linha e listas numeradas longas
    t = re.sub(r"[\r\n]+", " ", t)
    t = re.sub(r"[?!.,;:]+$", "", t)
    t = re.sub(r"\s+", " ", t).strip()
    return t


def extrair_sujeito_pergunta(pergunta: str) -> str:
    """Extrai o termo/conceito alvo de uma pergunta conceitual."""
    q = normalizar_texto_neurograph(pergunta)
    prefixos = (
        "qual é o significado de ",
        "qual o significado de ",
        "qual é o conceito de ",
        "qual o conceito de ",
        "qual é a função do ",
        "qual é a função da ",
        "qual é a função de ",
        "qual a função do ",
        "qual a função da ",
        "qual a função de ",
        "qual é a importância de ",
        "qual a importância de ",
        "qual é a capital do ",
        "qual é a capital da ",
        "qual é a capital de ",
        "qual a capital do ",
        "qual a capital da ",
        "qual a capital de ",
        "explique o funcionamento de ",
        "quais são os fundamentos de ",
        "quais os fundamentos de ",
        "quais são as áreas do ",
        "quais são os princípios do ",
        "quais são os princípios da ",
        "quais são os ",
        "quais são as ",
        "quando ocorreu a ",
        "quando ocorreu o ",
        "como se forma um ",
        "como se forma uma ",
        "como estruturar uma ",
        "como estruturar um ",
        "como cumprimentar ",
        "para que serve ",
        "como funciona ",
        "como ocorre ",
        "o que são ",
        "o que é ",
        "o que foi ",
        "o que eram ",
        "o que era ",
        "defina ",
        "explique ",
    )
    sujeito = q
    for pref in prefixos:
        if sujeito.startswith(pref):
            sujeito = sujeito[len(pref):].strip()
            break
    # Remove artigo inicial opcional para avaliar o núcleo do sujeito
    sujeito_sem_artigo = re.sub(r"^(?:o|a|os|as|um|uma|uns|umas)\s+", "", sujeito).strip()
    return sujeito_sem_artigo or sujeito


def eh_par_conceitual_valido(question: str, answer: str, tema: str = "") -> bool:
    """Valida rigorosamente se o par (question, answer) é um fato conceitual limpo,
    gramaticalmente íntegro e adequado para treinar o NeuroGraph.
    """
    q = normalizar_texto_neurograph(question)
    a = normalizar_texto_neurograph(answer)
    if not q or not a:
        return False

    palavras_q = re.findall(r"[^\W_]+", q, flags=re.UNICODE)
    palavras_a = re.findall(r"[^\W_]+", a, flags=re.UNICODE)

    if len(palavras_q) < 2 or len(palavras_q) > 12:
        return False
    if len(palavras_a) < 5 or len(palavras_a) > 58:
        return False

    # Rejeita placeholders genéricos e ruídos de YouTube
    for padrao in PADROES_RUIDO_RESPOSTA:
        if padrao in a or padrao in q:
            return False

    # Rejeita duplicação tautológica ("enem é enem é...", "história é história é...")
    if re.search(r"\b([a-zà-ú0-9]{2,25}(?:\s+[a-zà-ú0-9]{2,25})?)\s+(?:é|são)\s+\1\s+(?:é|são)\b", a):
        return False

    # Rejeita marcadores coloquiais de fala/transcrição na pergunta ou resposta
    marcadores_coloquiais = {"né", "tá", "eh", "ah", "uh", "opa", "galera", "cara", "tim-tim", "tals"}
    if any(p in marcadores_coloquiais for p in palavras_q) or any(p in marcadores_coloquiais for p in palavras_a):
        return False

    # Rejeita respostas que terminam com palavra truncada ou conectivo solto
    ultima_palavra_a = palavras_a[-1]
    if ultima_palavra_a in PALAVRAS_TRUNCADAS_FIM_RESPOSTA:
        return False
    if len(ultima_palavra_a) <= 2 and ultima_palavra_a not in {"ar", "ir", "sol", "lua", "luz", "mar", "rio", "sul", "ip", "ia", "ph", "ti", "3d", "v7", "v8"}:
        return False

    # Valida a estrutura do sujeito da pergunta
    sujeito = extrair_sujeito_pergunta(q)
    palavras_suj = re.findall(r"[^\W_]+", sujeito, flags=re.UNICODE)
    if not palavras_suj or len(palavras_suj) > 5:
        return False

    # Sujeito de 1 única palavra precisa ter ao menos 3 caracteres e não ser palavra vazia/pronome
    if len(palavras_suj) == 1 and len(palavras_suj[0]) < 3 and palavras_suj[0] not in {"ia", "ip", "ph", "ti"}:
        return False

    if palavras_suj[0] in PALAVRAS_INVALIDAS_INICIO_SUJEITO and not (
        palavras_suj[0] == "era" and len(palavras_suj) >= 2
    ):
        return False
    if palavras_suj[-1] in PALAVRAS_INVALIDAS_FIM_SUJEITO:
        return False
    if any(p in PALAVRAS_PROIBIDAS_NO_SUJEITO for p in palavras_suj):
        return False

    # Rejeita gerúndios no sujeito da pergunta ("sabendo", "preparando", "fazendo", "mostrando")
    if any(len(p) > 5 and p.endswith("ndo") for p in palavras_suj):
        return False

    # Rejeita verbos no futuro do pretérito sem acento antes de -ria (ex: "apagaria", "faria")
    if any(p.endswith(("aria", "eria", "iria", "ariam", "eriam", "iriam")) and len(p) > 5 for p in palavras_suj):
        return False

    # Verifica se está em português
    if not eh_texto_em_portugues(f"{q} {a}", min_palavras=5):
        return False

    # Se um tema foi informado, exige algum vínculo léxico mínimo (evita propagandas/off-topic do YouTube)
    if tema and tema.strip():
        stopwords_tema = {
            "sobre", "como", "para", "conceitos", "avançados", "inovação",
            "aplicações", "práticas", "cotidiano", "funcionamento", "técnico",
            "componentes", "história", "evolução", "tecnológica", "eficiência",
            "segurança", "manutenção", "arquitetura", "sistemas", "sensores",
            "diagnóstico", "resolução", "problemas", "fundamentos", "princípios",
            "básicos",
        }
        palavras_tema = [
            w for w in re.findall(r"[^\W_]+", tema.casefold(), flags=re.UNICODE)
            if len(w) >= 4 and w not in stopwords_tema
        ]
        if palavras_tema:
            texto_qa = f"{q} {a}".casefold()
            if not any((pt in texto_qa) or (len(pt) >= 5 and pt[:5] in texto_qa) for pt in palavras_tema):
                return False

    return True


def carregar_config_llm_ini() -> dict[str, Any]:
    """Lê a configuração de provedor, modelo, endpoint e chave do neurograph_studio.ini."""
    candidatos = [
        DIR_NEUROGRAPH / "bin" / "neurograph_studio.ini",
        DIR_TREINO / "lazarus" / "neurograph_studio.ini",
        DIR_NEUROGRAPH / "bin" / "neurograph_native.ini",
        DIR_NEUROGRAPH / "lazarus_pure" / "neurograph_native.ini",
    ]
    existentes = [p for p in candidatos if p.exists()]
    cfg: dict[str, Any] = {
        "provider": "OpenAI",
        "model": "gpt-4o-mini",
        "endpoint": "https://api.openai.com/v1/chat/completions",
        "api_key": os.environ.get("OPENAI_API_KEY", "").strip(),
        "temperature": 0.2,
        "max_tokens": 1024,
    }
    if not existentes:
        return cfg

    caminho_ini = max(existentes, key=lambda p: p.stat().st_mtime)
    try:
        parser = configparser.ConfigParser(interpolation=None)
        parser.read(caminho_ini, encoding="utf-8")

        geral_key = parser.get("Geral", "ApiKey", fallback="").strip()
        chat_token = parser.get("ChatGPT", "Token", fallback="").strip()
        provider = parser.get("ChatGPT", "Provider", fallback="OpenAI").strip()
        model = parser.get("ChatGPT", "Model", fallback="gpt-4o-mini").strip()
        endpoint = parser.get("ChatGPT", "Endpoint", fallback="").strip()
        temp_str = parser.get("ChatGPT", "Temperature", fallback="0.2").strip().replace(",", ".")
        max_tok_str = parser.get("ChatGPT", "MaxTokens", fallback="1024").strip()

        if provider:
            cfg["provider"] = provider
        if model:
            cfg["model"] = model
        if endpoint:
            cfg["endpoint"] = endpoint
        if chat_token or geral_key:
            cfg["api_key"] = chat_token or geral_key
        try:
            cfg["temperature"] = max(0.0, min(1.5, float(temp_str)))
        except ValueError:
            pass
        try:
            cfg["max_tokens"] = max(128, int(max_tok_str))
        except ValueError:
            pass
    except Exception as exc:
        logging.debug("Aviso ao ler INI %s: %s", caminho_ini, exc)

    return cfg


def _eh_endpoint_local_ou_customizado(endpoint: str, provider: str) -> bool:
    """Verifica se o provedor/endpoint é um servidor local (Ollama / llama.cpp / vLLM) que não exige chave OpenAI."""
    prov_low = (provider or "").lower()
    ep_low = (endpoint or "").lower()
    if any(k in prov_low for k in ("local", "ollama", "llama", "lm studio", "vllm", "custom")):
        return True
    if ep_low and "api.openai.com" not in ep_low:
        return True
    return False


def tem_ia_ativa(api_key: str | None = None) -> bool:
    """Retorna True se houver chave da OpenAI configurada OU endpoint LLM local/customizado no INI."""
    if api_key and api_key.strip():
        return True
    if os.environ.get("OPENAI_API_KEY", "").strip():
        return True
    cfg = carregar_config_llm_ini()
    if cfg.get("api_key"):
        return True
    if _eh_endpoint_local_ou_customizado(cfg.get("endpoint", ""), cfg.get("provider", "")):
        return True
    return False


def _normalizar_url_chat_completions(endpoint: str) -> str:
    """Garante que a URL aponte para a rota de chat completions compatível com OpenAI/llama.cpp."""
    ep = (endpoint or "").strip().rstrip("/")
    if not ep:
        return "https://api.openai.com/v1/chat/completions"
    if ep.endswith("/v1/chat/completions") or ep.endswith("/api/chat") or ep.endswith("/chat/completions"):
        return ep
    if ep.endswith("/v1"):
        return f"{ep}/chat/completions"
    return f"{ep}/v1/chat/completions"


def requisitar_chat_llm(
    messages: list[dict[str, str]],
    temperature: float = 0.2,
    max_tokens: int = 1024,
    api_key: str | None = None,
    timeout: int = 35,
) -> str | None:
    """Envia uma requisição de chat para o LLM configurado no neurograph_studio.ini (ou OpenAI API)."""
    cfg = carregar_config_llm_ini()
    chave = (api_key or os.environ.get("OPENAI_API_KEY") or cfg.get("api_key") or "").strip()
    endpoint = cfg.get("endpoint", "").strip()
    provider = cfg.get("provider", "OpenAI")
    model = cfg.get("model", "gpt-4o-mini") or "gpt-4o-mini"

    eh_local = _eh_endpoint_local_ou_customizado(endpoint, provider)
    if not chave and not eh_local:
        return None

    url = _normalizar_url_chat_completions(endpoint if eh_local or endpoint else "https://api.openai.com/v1/chat/completions")
    payload = {
        "model": model,
        "messages": messages,
        "temperature": float(temperature),
        "max_tokens": int(max_tokens),
        "stream": False,
    }
    headers = {
        "Content-Type": "application/json",
    }
    if chave:
        headers["Authorization"] = f"Bearer {chave}"

    try:
        dados_bytes = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        req = urllib.request.Request(url, data=dados_bytes, headers=headers, method="POST")
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            corpo = resp.read().decode("utf-8", errors="replace")
            dados_resp = json.loads(corpo)
            # Formato OpenAI / llama.cpp (/v1/chat/completions)
            choices = dados_resp.get("choices")
            if isinstance(choices, list) and choices:
                msg = choices[0].get("message") or {}
                conteudo = msg.get("content")
                if conteudo:
                    return str(conteudo).strip()
            # Formato nativo Ollama (/api/chat)
            if isinstance(dados_resp.get("message"), dict):
                conteudo = dados_resp["message"].get("content")
                if conteudo:
                    return str(conteudo).strip()
    except Exception as exc:
        logging.warning("Aviso na chamada ao LLM (%s em %s): %s", model, url, exc)
    return None


def extrair_json_da_resposta(raw_text: str) -> Any:
    """Extrai de forma resiliente um array ou objeto JSON da resposta textual de um LLM."""
    if not raw_text:
        return None
    limpo = raw_text.strip()
    limpo = re.sub(r"^```(?:json)?", "", limpo, flags=re.MULTILINE)
    limpo = re.sub(r"```$", "", limpo, flags=re.MULTILINE).strip()
    try:
        return json.loads(limpo)
    except Exception:
        pass

    # Procura primeiro bloco [...] ou {...}
    m_arr = re.search(r"\[[\s\S]*\]", limpo)
    if m_arr:
        try:
            return json.loads(m_arr.group(0))
        except Exception:
            pass
    m_obj = re.search(r"\{[\s\S]*\}", limpo)
    if m_obj:
        try:
            return json.loads(m_obj.group(0))
        except Exception:
            pass
    return None


def obter_cliente_openai(api_key: str | None = None) -> Any:
    """Mantido por compatibilidade: retorna um cliente compatível ou adaptador para o LLM configurado no INI."""
    if not tem_ia_ativa(api_key):
        return None

    class _AdaptadorChatCompletions:
        def __init__(self, key: str | None):
            self._key = key

        def create(self, model: str = "", messages: list[dict[str, str]] | None = None, temperature: float = 0.2, **kwargs) -> Any:
            texto = requisitar_chat_llm(
                messages=messages or [],
                temperature=temperature,
                api_key=self._key,
            )
            if texto is None:
                raise RuntimeError("Sem resposta do provedor LLM")

            class _Msg:
                content = texto

            class _Choice:
                message = _Msg()

            class _Resp:
                choices = [_Choice()]

            return _Resp()

    class _AdaptadorClient:
        def __init__(self, key: str | None):
            self.chat = type("_Chat", (), {"completions": _AdaptadorChatCompletions(key)})()

    return _AdaptadorClient(api_key)


def sugerir_referencias_em_portugues(
    tema: str,
    n_sugestoes: int = 5,
    api_key: str | None = None,
) -> list[str]:
    """Gera buscas didáticas em português para encontrar vídeos conceituais no YouTube."""
    tema_clean = re.sub(r"\s+—\s+.*$", "", tema.lower().strip()).strip()
    sugestoes_base = [
        f"o que é {tema_clean}",
        f"como funciona {tema_clean}",
        f"resumo sobre {tema_clean}",
        f"principais conceitos de {tema_clean}",
        f"explicação simples de {tema_clean}",
    ]
    return sugestoes_base[:max(1, n_sugestoes)]


def _limpar_definicao_heuristica(definicao: str, max_palavras: int = 24) -> str:
    """Corta a definição em limites seguros de cláusula sem jamais truncar palavras ao meio."""
    d = re.sub(r"\s+", " ", definicao).strip()
    # Corta antes de conjunções coloquiais ou marcadores de fala
    d = re.split(
        r"\b(?:mas|porém|entretanto|além disso|por outro lado|inclusive|ou seja|por exemplo|então|porque|já que|quando|onde|como diz|eu sou|meu nome|se você|clique|inscreva|aqui no canal|tá|né)\b",
        d,
        maxsplit=1,
    )[0].strip()

    palavras = d.split()
    if len(palavras) > max_palavras:
        palavras = palavras[:max_palavras]

    # Remove palavras finais que sejam conectivos ou artigos pendurados
    while palavras:
        ult = re.sub(r"[?!.,;:]+$", "", palavras[-1].lower())
        if ult in PALAVRAS_TRUNCADAS_FIM_RESPOSTA or len(ult) <= 1:
            palavras.pop()
        else:
            break

    return " ".join(palavras)


def extrair_pares_heuristicos(texto: str, max_pares: int = 10, titulo_video: str = "") -> list[dict]:
    """Extrai fatos conceituais limpos e validados quando o servidor LLM não estiver acessível."""
    if not texto:
        return []

    # Normaliza espaços preservando pontuação de fim de frase
    t_norm = re.sub(r"\s+", " ", texto.lower()).strip()

    pares: list[dict] = []
    perguntas_vistas: set[str] = set()

    # Divide em sentenças ou segmentos naturais para nunca capturar fragmentos do meio de outra oração
    sentencas = re.split(r"[.!?;\n]+", t_norm)

    padrao_definicao = re.compile(
        r"(?:^|\b(?:em suma|resumindo|portanto|assim)\s*,?\s*)"
        r"(?:o\s+|a\s+|os\s+|as\s+|um\s+|uma\s+)?"
        r"([a-zà-ú]{3,22}(?:\s+(?:de|da|do|das|dos|em|para|por)?\s*[a-zà-ú]{3,22}){0,2})\s+"
        r"(é\s+(?:um|uma|o|a|definido como|considerado|considerada)|são\s+(?:os|as|definidos como)|consiste\s+em|significa|corresponde\s+a|define-se\s+como)\s+"
        r"([^.!?;]{15,180})",
        re.IGNORECASE,
    )

    for sent in sentencas:
        sent_limpa = sent.strip(" ,:-")
        if len(sent_limpa.split()) < 6:
            continue

        for match in padrao_definicao.finditer(sent_limpa):
            termo = match.group(1).strip()
            verbo = re.sub(r"\s+", " ", match.group(2).strip())
            resto = match.group(3).strip()

            definicao_curta = _limpar_definicao_heuristica(resto, max_palavras=22)
            if len(definicao_curta.split()) < 4:
                continue

            q = normalizar_texto_neurograph(f"o que é {termo}")
            a = normalizar_texto_neurograph(f"{termo} {verbo} {definicao_curta}")

            if q not in perguntas_vistas and eh_par_conceitual_valido(q, a):
                perguntas_vistas.add(q)
                pares.append({
                    "question": q,
                    "answer": a,
                    "context": [],
                    "category": "youtube_curated",
                })
                if len(pares) >= max_pares:
                    return pares

    return pares


def curar_transcricao_com_chatgpt(
    texto_transcricao: str,
    titulo_video: str,
    video_id: str = "",
    max_pares: int = 6,
    api_key: str | None = None,
) -> list[ParTreinamento]:
    """Processa o texto da transcrição usando o LLM configurado (local ou OpenAI) e valida rigorosamente os pares."""
    if not texto_transcricao or len(texto_transcricao.split()) < 15:
        logging.warning("Transcrição muito curta para curadoria.")
        return []

    cfg = carregar_config_llm_ini()
    usou_llm = False
    pares_extraidos: list[dict] = []

    if tem_ia_ativa(api_key):
        logging.info(
            "Curando transcrição de [%s] com IA (%s)...",
            video_id or titulo_video,
            cfg.get("model", "LLM"),
        )
        trecho = texto_transcricao[:3500]
        prompt_usuario = (
            f"Título do Vídeo: {titulo_video}\n\n"
            f"Transcrição do vídeo:\n{trecho}\n\n"
            f"Extraia até {max_pares} pares conceituais diretos e factuais em português sobre o tema deste vídeo.\n"
            f"Retorne APENAS um array JSON válido no formato:\n"
            f'[{{"question": "o que é ...", "answer": "..."}}]'
        )
        raw_out = requisitar_chat_llm(
            messages=[
                {"role": "system", "content": PROMPT_SISTEMA_CURADOR},
                {"role": "user", "content": prompt_usuario},
            ],
            temperature=0.2,
            max_tokens=900,
            api_key=api_key,
        )
        dados = extrair_json_da_resposta(raw_out or "")
        if isinstance(dados, dict) and "question" in dados:
            dados = [dados]
        if isinstance(dados, list) and dados:
            pares_extraidos = [d for d in dados if isinstance(d, dict)]
            usou_llm = True

    if not pares_extraidos:
        logging.info("Extraindo definições conceituais estruturadas localmente para [%s]...", video_id or titulo_video)
        pares_extraidos = extrair_pares_heuristicos(texto_transcricao, max_pares=max_pares, titulo_video=titulo_video)

    resultados: list[ParTreinamento] = []
    perguntas_vistas: set[str] = set()

    for item in pares_extraidos:
        if not isinstance(item, dict):
            continue
        q = normalizar_texto_neurograph(item.get("question", ""))
        a = normalizar_texto_neurograph(item.get("answer", ""))
        if not q or not a or q in perguntas_vistas:
            continue
        if len(a.split()) > 55:
            a = _limpar_definicao_heuristica(a, max_palavras=45)
        if not eh_par_conceitual_valido(q, a):
            continue

        perguntas_vistas.add(q)
        resultados.append(
            ParTreinamento(
                question=q,
                answer=a,
                context=[],
                category="youtube_curated",
                video_id=video_id,
                origem=cfg.get("model", "chatgpt") if usou_llm else "heuristica_local",
            )
        )

    return resultados


def curar_pdf_com_chatgpt(
    texto_pdf: str,
    nome_arquivo: str,
    max_pares_total: int = 20,
    api_key: str | None = None,
) -> list[ParTreinamento]:
    """Processa o texto extraído de um arquivo PDF e extrai pares conceituais validados."""
    if not texto_pdf or len(texto_pdf.split()) < 20:
        logging.warning("Texto do PDF muito curto ou vazio para curadoria.")
        return []

    cfg = carregar_config_llm_ini()
    pares_extraidos: list[dict] = []
    usou_llm = False

    tamanho_bloco = 3500
    blocos = [texto_pdf[i:i + tamanho_bloco] for i in range(0, min(len(texto_pdf), 17500), tamanho_bloco)]
    max_por_bloco = max(3, max_pares_total // max(1, len(blocos)))

    if tem_ia_ativa(api_key):
        logging.info("Enviando %d bloco(s) do PDF '%s' para curadoria da IA (%s)...", len(blocos), nome_arquivo, cfg.get("model", "LLM"))
        for idx, bloco in enumerate(blocos):
            raw_out = requisitar_chat_llm(
                messages=[
                    {"role": "system", "content": PROMPT_SISTEMA_CURADOR_PDF},
                    {
                        "role": "user",
                        "content": (
                            f"Documento: {nome_arquivo} (Parte {idx + 1}/{len(blocos)})\n\n"
                            f"Texto:\n{bloco}\n\n"
                            f"Extraia até {max_por_bloco} pares conceituais em formato JSON."
                        ),
                    },
                ],
                temperature=0.2,
                max_tokens=900,
                api_key=api_key,
            )
            dados = extrair_json_da_resposta(raw_out or "")
            if isinstance(dados, dict) and "question" in dados:
                dados = [dados]
            if isinstance(dados, list) and dados:
                pares_extraidos.extend(d for d in dados if isinstance(d, dict))
                usou_llm = True
            else:
                pares_extraidos.extend(extrair_pares_heuristicos(bloco, max_pares=max_por_bloco))

            if len(pares_extraidos) >= max_pares_total:
                break
    else:
        logging.info("Executando curadoria conceitual local no PDF '%s'.", nome_arquivo)
        for bloco in blocos:
            pares_extraidos.extend(extrair_pares_heuristicos(bloco, max_pares=max_por_bloco))
            if len(pares_extraidos) >= max_pares_total:
                break

    resultados: list[ParTreinamento] = []
    perguntas_vistas: set[str] = set()

    for item in pares_extraidos:
        if not isinstance(item, dict):
            continue
        q = normalizar_texto_neurograph(item.get("question", ""))
        a = normalizar_texto_neurograph(item.get("answer", ""))
        if not q or not a or q in perguntas_vistas:
            continue
        if len(a.split()) > 55:
            a = _limpar_definicao_heuristica(a, max_palavras=45)
        if not eh_par_conceitual_valido(q, a):
            continue
        perguntas_vistas.add(q)

        resultados.append(
            ParTreinamento(
                question=q,
                answer=a,
                context=[],
                category="pdf_curated",
                video_id=nome_arquivo,
                origem=cfg.get("model", "chatgpt_pdf") if usou_llm else "heuristica_pdf",
            )
        )
        if len(resultados) >= max_pares_total:
            break

    logging.info("Curadoria do PDF '%s' concluída: %d pares atômicos válidos gerados.", nome_arquivo, len(resultados))
    return resultados


def salvar_pares_processados(
    pares: list[ParTreinamento],
    pasta_saida: Path,
    nome_arquivo: str = "dataset_curado.json",
) -> Path:
    """Grava os pares processados em JSON, filtrando entradas inválidas e evitando duplicatas."""
    pasta_saida.mkdir(parents=True, exist_ok=True)
    caminho = pasta_saida / nome_arquivo

    existentes = []
    if caminho.exists():
        try:
            with caminho.open("r", encoding="utf-8") as f:
                existentes = json.load(f)
        except Exception:
            existentes = []

    novos_dicts = [
        asdict(p)
        for p in pares
        if eh_par_conceitual_valido(p.question, p.answer)
    ]
    mapa_idx = {
        item.get("question"): idx
        for idx, item in enumerate(existentes)
        if isinstance(item, dict) and item.get("question")
    }
    adicionados = 0
    for n in novos_dicts:
        q = n["question"]
        if q not in mapa_idx:
            mapa_idx[q] = len(existentes)
            existentes.append(n)
            adicionados += 1
        else:
            idx_ex = mapa_idx[q]
            antigo = existentes[idx_ex]
            resp_antiga = str(antigo.get("answer", ""))
            # Atualiza se a definição antiga era excessivamente curta (< 7 palavras) ou se a nova vem da base conceitual verificada
            if n.get("origem") == "base_conceitual_ptbr" or (
                len(resp_antiga.split()) < 7 and len(str(n.get("answer", "")).split()) >= 8
            ):
                if antigo.get("answer") != n.get("answer"):
                    existentes[idx_ex] = n
                    adicionados += 1

    with caminho.open("w", encoding="utf-8") as f:
        json.dump(existentes, f, ensure_ascii=False, indent=2)

    logging.info("Dataset atualizado em %s (+%d novos pares válidos, total %d).", caminho, adicionados, len(existentes))
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
