#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gerador de Treinamento Conceitual por Tópicos para o NeuroGraph.

Responsabilidades:
1. Gerar pares conceituais precisos em português usando o LLM configurado no neurograph_studio.ini
   (OpenAI ou servidor local Ollama / llama.cpp) ou base conceitual pedagógica verificada.
2. Impedir tautologias ("X é X é...") e respostas genéricas vazias ("é uma área do conhecimento dedicada...").
3. Validar rigorosamente cada par antes de salvar no dataset e treinar o TokenGraph.
"""
from __future__ import annotations

import argparse
import json
import logging
import os
import re
import sys
from dataclasses import asdict
from pathlib import Path
from typing import Optional

if sys.platform == "win32" and hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

DIR_TREINO = Path(__file__).resolve().parent
DIR_NEUROGRAPH = DIR_TREINO.parent
DIR_CONTEXTUAL_V7 = DIR_NEUROGRAPH / "experiments" / "contextual_v7"

if str(DIR_CONTEXTUAL_V7) not in sys.path:
    sys.path.insert(0, str(DIR_CONTEXTUAL_V7))
if str(DIR_TREINO) not in sys.path:
    sys.path.insert(0, str(DIR_TREINO))

from curador_chatgpt import (
    ParTreinamento,
    carregar_config_llm_ini,
    eh_par_conceitual_valido,
    extrair_json_da_resposta,
    normalizar_texto_neurograph,
    requisitar_chat_llm,
    salvar_pares_processados,
    tem_ia_ativa,
)
from treinador_neurograph import preparar_exemplos

TOPICOS_PADRAO_10 = [
    "Inteligência Artificial e Redes Neurais",
    "Ciência da Computação e Algoritmos",
    "Astronomia e Sistema Solar",
    "Física Quântica e Eletromagnetismo",
    "Biologia Celular e Genética",
    "História do Brasil e do Mundo",
    "Energias Renováveis e Sustentabilidade",
    "Química Orgânica e Elementos da Tabela Periódica",
    "Geografia Física e Climatologia",
    "Lógica Matemática e Probabilidade",
]

# Base conceitual pedagógica verificada em português (cobrindo tópicos padrão e assuntos do studio)
CONCEITOS_BASE: dict[str, list[tuple[str, str]]] = {
    "Inteligência Artificial e Redes Neurais": [
        ("o que é inteligência artificial", "inteligência artificial é o ramo da ciência da computação que cria sistemas capazes de simular o raciocínio humano"),
        ("o que é aprendizado de máquina", "aprendizado de máquina é um método onde sistemas aprendem a reconhecer padrões diretamente a partir de dados"),
        ("o que é uma rede neural artificial", "uma rede neural artificial é um modelo computacional inspirado nas conexões sinápticas de neurônios biológicos"),
        ("o que é um neurônio artificial", "um neurônio artificial é uma unidade matemática que calcula a soma ponderada de entradas e aplica uma função de ativação"),
        ("o que é backpropagation", "backpropagation é o algoritmo de retropropagação do erro usado para ajustar os pesos de uma rede neural via gradiente"),
        ("o que é uma função de ativação", "uma função de ativação é uma operação matemática que introduz não linearidade na saída de um neurônio"),
        ("o que é overfitting", "overfitting ocorre quando um modelo decora os dados de treino e perde a capacidade de generalizar para novos exemplos"),
        ("o que é gradiente descendente", "gradiente descendente é um algoritmo de otimização que ajusta os pesos na direção oposta à derivada do erro"),
        ("o que é taxa de aprendizado", "a taxa de aprendizado é o hiperparâmetro que controla o tamanho do passo de ajuste dos pesos a cada iteração"),
        ("o que é um transformer", "o transformer é uma arquitetura de rede neural baseada no mecanismo de atenção para processar sequências em paralelo"),
        ("o que é um token", "um token é a unidade básica de texto como uma palavra ou subpalavra processada por um modelo de linguagem"),
        ("o que é neurograph", "o neurograph é uma rede neural associativa em grafo de tokens desenvolvida para raciocínio contextual transparente"),
    ],
    "Ciência da Computação e Algoritmos": [
        ("o que é um algoritmo", "um algoritmo é uma sequência finita de passos lógicos e bem definidos para solucionar um problema computacional"),
        ("o que é uma variável", "uma variável é um espaço nomeado na memória usado para armazenar dados durante a execução de um programa"),
        ("o que é recursão", "recursão é a técnica de programação onde uma função chama a si mesma até atingir uma condição de parada"),
        ("o que é uma pilha", "uma pilha é uma estrutura de dados do tipo lifo onde o último elemento inserido é o primeiro a ser removido"),
        ("o que é uma fila", "uma fila é uma estrutura de dados do tipo fifo onde o primeiro elemento inserido é o primeiro a ser atendido"),
        ("o que é uma árvore binária", "uma árvore binária é uma estrutura de dados hierárquica em que cada nó possui no máximo dois filhos"),
        ("o que é uma tabela hash", "uma tabela hash é uma estrutura que associa chaves a valores permitindo buscas rápidas em tempo médio constante"),
        ("o que é busca binária", "a busca binária é um algoritmo eficiente que localiza itens em listas ordenadas dividindo o intervalo pela metade"),
        ("o que é um compilador", "um compilador é um programa que traduz código fonte de alto nível para código de máquina executável"),
        ("o que é memória ram", "a memória ram é a memória volátil de acesso rápido usada pelo processador para manter programas e dados ativos"),
    ],
    "Sistema Operacional": [
        ("o que é sistema operacional", "um sistema operacional é o software base que gerencia o hardware a memória os processos e os arquivos do computador"),
        ("o que é o kernel", "o kernel é o núcleo do sistema operacional responsável pela comunicação direta entre o software e o hardware"),
        ("o que é um processo em computação", "um processo é uma instância de um programa em execução contendo seu próprio espaço de memória e estado"),
        ("o que é memória virtual", "memória virtual é a técnica do sistema operacional que utiliza parte do disco para expandir a memória ram disponível"),
        ("o que é um sistema de arquivos", "um sistema de arquivos é a estrutura lógica usada pelo sistema operacional para organizar e gravar dados em disco"),
        ("o que é escalonamento de processos", "o escalonamento de processos é o mecanismo que distribui o tempo de uso do processador entre várias tarefas ativas"),
    ],
    "Astronomia e Sistema Solar": [
        ("o que é uma estrela", "uma estrela é uma esfera massiva de plasma luminosa sustentada pela fusão nuclear em seu núcleo"),
        ("o que é o sol", "o sol é a estrela anã amarela situada no centro do sistema solar que fornece luz e calor para a terra"),
        ("o que é um planeta", "um planeta é um corpo celeste esférico que orbita uma estrela e possui gravidade dominante em sua órbita"),
        ("o que é uma galáxia", "uma galáxia é um imenso sistema ligado pela gravidade composto por bilhões de estrelas gás poeira e matéria escura"),
        ("o que é a via láctea", "a via láctea é a galáxia espiral barrada onde estão localizados o sistema solar e o planeta terra"),
        ("o que é uma supernova", "uma supernova é a explosão estelar energética que ocorre no estágio final da evolução de estrelas massivas"),
        ("o que é ano luz", "o ano luz é a unidade astronômica de distância correspondente ao percurso que a luz percorre no vácuo em um ano"),
        ("o que é uma nebulosa", "uma nebulosa é uma grande nuvem interestelar de gás e poeira onde frequentemente se formam novas estrelas"),
    ],
    "Buraco Negro": [
        ("o que é um buraco negro", "um buraco negro é uma região do espaço tempo com gravidade tão intensa que nem mesmo a luz consegue escapar"),
        ("o que é o horizonte de eventos", "o horizonte de eventos é a fronteira ao redor de um buraco negro a partir da qual nenhuma matéria ou luz retorna"),
        ("o que é singularidade gravitacional", "a singularidade gravitacional é o centro de um buraco negro onde a massa se concentra em densidade extrema"),
        ("como se forma um buraco negro estelar", "um buraco negro estelar forma se pelo colapso gravitacional do núcleo de uma estrela supermassiva após esgotar seu combustível"),
        ("o que é disco de acreção", "o disco de acreção é a estrutura giratória de gás e matéria superaquecida que orbita ao redor de um buraco negro"),
    ],
    "Física Quântica e Eletromagnetismo": [
        ("o que é um fóton", "o fóton é a partícula elementar mediadora da radiação eletromagnética e o quantum fundamental da luz"),
        ("o que é um elétron", "o elétron é uma partícula subatômica de carga elétrica negativa que compõe a eletrosfera dos átomos"),
        ("o que é superposição quântica", "superposição quântica é o fenômeno em que um sistema físico permanece em múltiplos estados até ser medido"),
        ("o que é corrente elétrica", "corrente elétrica é o movimento ordenado de cargas elétricas através de um material condutor"),
        ("o que é tensão elétrica", "tensão elétrica ou diferença de potencial é a grandeza física que impulsiona os elétrons por um circuito"),
        ("o que é resistência elétrica", "resistência elétrica é a oposição oferecida por um material à passagem da corrente elétrica"),
        ("o que é a lei de ohm", "a lei de ohm estabelece que a tensão elétrica em um resistor é igual ao produto da resistência pela corrente"),
        ("o que é a gravidade", "a gravidade é a força fundamental de atração mútua entre corpos dotados de massa e energia"),
        ("o que é velocidade da luz", "a velocidade da luz no vácuo é uma constante física universal de aproximadamente trezentos mil quilômetros por segundo"),
    ],
    "Biologia Celular e Genética": [
        ("o que é dna", "o dna é a molécula de ácido desoxirribonucleico que armazena as instruções genéticas de todos os seres vivos"),
        ("o que é rna", "o rna é o ácido ribonucleico responsável por transportar a informação genética e atuar na síntese de proteínas"),
        ("o que é um gene", "um gene é um segmento funcional de dna que contém a informação necessária para produzir uma proteína"),
        ("o que é a célula", "a célula é a menor unidade estrutural e funcional viva que compõe todos os organismos biológicos"),
        ("o que é mitocôndria", "a mitocôndria é a organela responsável pela respiração celular e pela produção de energia na forma de atp"),
        ("o que é fotossíntese", "fotossíntese é o processo pelo qual plantas e algas utilizam luz solar para converter água e gás carbônico em glicose"),
        ("o que é mitose", "mitose é o processo de divisão celular em que uma célula mãe origina duas células filhas geneticamente idênticas"),
        ("o que é meiose", "meiose é a divisão celular que reduz pela metade o número de cromossomos para formar gametas reprodutivos"),
    ],
    "História do Brasil e do Mundo": [
        ("o que é história", "história é a ciência humana que investiga e interpreta os acontecimentos e as transformações das sociedades ao longo do tempo"),
        ("o que são fontes históricas", "fontes históricas são documentos registros arqueológicos relatos e vestígios usados pelos historiadores para estudar o passado"),
        ("o que é historiografia", "historiografia é o estudo crítico dos métodos das interpretações e das obras produzidas pelos historiadores"),
        ("o que foi o iluminismo", "o iluminismo foi o movimento intelectual do século dezoito que defendia a razão a ciência e as liberdades individuais"),
        ("o que foi a revolução industrial", "a revolução industrial foi a transição produtiva iniciada no século dezoito com a mecanização e o surgimento das fábricas"),
        ("o que foi a revolução francesa", "a revolução francesa foi o movimento político e social de 1789 que pôs fim ao absolutismo monárquico na frança"),
        ("quando ocorreu a independência do brasil", "a independência do brasil foi proclamada em 7 de setembro de 1822 encerrando o domínio colonial português"),
        ("o que foi a lei áurea", "a lei áurea foi o decreto assinado em 13 de maio de 1888 que aboliu oficialmente a escravidão no brasil"),
        ("o que foi a era vargas", "a era vargas foi o período da história brasileira entre 1930 e 1945 marcado pela industrialização e leis trabalhistas"),
    ],
    "Gramática": [
        ("o que é gramática", "gramática é o conjunto de regras e estruturas que organizam o funcionamento os sons as palavras e as frases de uma língua"),
        ("o que é gramática normativa", "a gramática normativa estabelece as regras da norma padrão culta para o uso formal da fala e da escrita"),
        ("o que é gramática descritiva", "a gramática descritiva analisa e registra como uma língua é realmente falada e utilizada por seus falantes no cotidiano"),
        ("o que é morfologia na gramática", "morfologia é a parte da gramática que estuda a estrutura a formação e a classificação das palavras"),
        ("o que é sintaxe", "sintaxe é o ramo da gramática que analisa a disposição das palavras nas frases e as relações lógicas entre as orações"),
        ("o que é um substantivo", "substantivo é a classe gramatical de palavras variável que nomeia seres objetos lugares sentimentos e conceitos"),
        ("o que é um verbo", "verbo é a palavra variável que exprime ação estado fenômeno da natureza ou mudança de estado situada no tempo"),
        ("o que é concordância verbal", "concordância verbal é a regra gramatical em que o verbo se flexiona para concordar em número e pessoa com o sujeito"),
    ],
    "Português": [
        ("o que é a língua portuguesa", "a língua portuguesa é um idioma românico originado do latim vulgar e falado oficialmente no brasil em portugal e na cplp"),
        ("o que é semântica", "semântica é a área da linguística que estuda o significado e a interpretação das palavras e das sentenças"),
        ("o que é fonologia", "fonologia é o estudo dos fonemas e do sistema sonoro de uma língua em sua função distintiva de significado"),
        ("o que é coesão textual", "coesão textual é a conexão harmoniosa entre palavras e frases de um texto por meio de conectivos e pronomes"),
        ("o que é coerência textual", "coerência textual é a relação lógica e sem contradições entre as ideias apresentadas ao longo de um texto"),
        ("o que é crase", "crase é a fusão de duas vogais idênticas representada pelo acento grave na união da preposição com o artigo feminino"),
    ],
    "Literatura": [
        ("o que é literatura", "literatura é a arte da palavra que expressa ideias emoções e visões de mundo por meio de textos em prosa ou verso"),
        ("o que é texto literário", "o texto literário é uma produção artística com linguagem conotativa plurissignificativa e foco na expressão estética"),
        ("o que foi o romantismo na literatura", "o romantismo foi o movimento literário caracterizado pelo subjetivismo pela emoção e pela valorização da identidade nacional"),
        ("o que foi o realismo na literatura", "o realismo foi a escola literária do século dezenove voltada à análise objetiva e crítica da sociedade e da psicologia humana"),
        ("o que foi o modernismo no brasil", "o modernismo brasileiro foi o movimento cultural iniciado em 1922 que renovou a linguagem artística com liberdade estética"),
        ("o que é figura de linguagem", "figura de linguagem é um recurso expressivo usado para ampliar o sentido das palavras como a metáfora e a ironia"),
    ],
    "Redação": [
        ("o que é redação", "redação é o processo estruturado de escrita de um texto com início desenvolvimento e conclusão sobre determinado tema"),
        ("o que é dissertação argumentativa", "a dissertação argumentativa é o gênero textual em que o autor defende uma tese por meio de argumentos e repertório"),
        ("o que é a tese em uma redação", "a tese é o posicionamento central defendido pelo autor logo na introdução de um texto dissertativo argumentativo"),
        ("o que é proposta de intervenção na redação", "a proposta de intervenção é a conclusão da redação do enem que apresenta uma solução detalhada e viável para o problema discutido"),
        ("como estruturar uma redação dissertativa", "uma redação dissertativa estrutura se em introdução com a tese dois parágrafos de desenvolvimento e conclusão"),
    ],
    "Enem": [
        ("o que é o enem", "o enem é o exame nacional do ensino médio aplicado anualmente para avaliar estudantes e selecionar vagas no ensino superior"),
        ("como funciona a prova do enem", "o enem é aplicado em dois domingos com cento e oitenta questões objetivas divididas em quatro áreas do conhecimento e uma redação"),
        ("o que é a tri no enem", "a teoria de resposta ao item é o método estatístico do enem que calcula a nota considerando a coerência dos acertos e a dificuldade das questões"),
        ("para que serve a nota do enem", "a nota do enem serve para ingressar em universidades públicas pelo sisu obter bolsas no prouni e financiamento pelo fies"),
        ("quais são as áreas do conhecimento do enem", "as quatro áreas do enem são linguagens ciências humanas ciências da natureza e matemática além da redação dissertativa"),
    ],
    "Vestibular": [
        ("o que é o vestibular", "o vestibular é o processo seletivo composto por provas de conhecimentos gerais e específicos para ingresso em universidades"),
        ("como funciona o sisu", "o sistema de seleção unificada é a plataforma do ministério da educação que oferece vagas em universidades públicas usando a nota do enem"),
        ("o que é o prouni", "o programa universidade para todos concede bolsas de estudo integrais e parciais em faculdades privadas com base na nota do enem"),
    ],
    "Concurso": [
        ("o que é um concurso público", "concurso público é o processo seletivo oficial de provas ou títulos para preenchimento de cargos efetivos na administração pública"),
        ("o que é o edital de um concurso", "o edital é o documento oficial que estabelece todas as regras vagas disciplinas etapas e prazos de um concurso público"),
        ("o que é estabilidade no serviço público", "estabilidade é a garantia constitucional de permanência no cargo público adquirida pelo servidor concursado após o estágio probatório"),
    ],
    "Medicina": [
        ("o que é medicina", "medicina é a ciência da saúde dedicada à prevenção ao diagnóstico ao tratamento e à cura das doenças humanas"),
        ("o que é diagnóstico médico", "diagnóstico médico é a identificação de uma doença ou condição clínica a partir da análise de sintomas e exames"),
        ("o que é anamnese", "anamnese é a entrevista clínica detalhada realizada pelo médico para conhecer o histórico de saúde e os sintomas do paciente"),
        ("o que é farmacologia", "farmacologia é a ciência biomédica que estuda como os medicamentos interagem com os sistemas biológicos do organismo"),
    ],
    "Corpo Humano": [
        ("o que é o sistema circulatório", "o sistema circulatório é o conjunto formado pelo coração e pelos vasos sanguíneos que transporta oxigênio e nutrientes pelo corpo"),
        ("qual a função do coração", "o coração funciona como uma bomba muscular que impulsiona o sangue continuamente para os pulmões e todos os tecidos do corpo"),
        ("o que é o sistema nervoso", "o sistema nervoso é a rede de neurônios encarregada de coordenar as ações voluntárias involuntárias e os sentidos do corpo humano"),
        ("o que é homeostase no corpo humano", "homeostase é o equilíbrio fisiológico interno mantido pelo organismo como o controle da temperatura e da glicemia"),
    ],
    "SUS": [
        ("o que é o sus", "o sistema único de saúde é o sistema público e gratuito de saúde do brasil criado pela constituição de 1988"),
        ("quais são os princípios do sus", "os princípios doutrinários do sus são a universalidade de acesso a integralidade do cuidado e a equidade no atendimento"),
        ("o que é atenção primária no sus", "a atenção primária é a porta de entrada do sus realizada nas unidades básicas de saúde com foco em prevenção e saúde da família"),
    ],
    "Energias Renováveis e Sustentabilidade": [
        ("o que é energia solar fotovoltaica", "energia solar fotovoltaica é a eletricidade obtida pela conversão direta da radiação solar em células semicondutoras"),
        ("o que é um painel solar", "um painel solar é um módulo formado por células fotovoltaicas de silício que geram corrente elétrica contínua sob a luz do sol"),
        ("o que é um inversor solar", "o inversor solar é o equipamento que converte a corrente contínua dos painéis em corrente alternada para consumo elétrico"),
        ("o que é energia eólica", "energia eólica é a energia elétrica produzida a partir da força cinética dos ventos que gira as pás de aerogeradores"),
        ("o que é sustentabilidade", "sustentabilidade é a capacidade de suprir as necessidades humanas atuais preservando o meio ambiente para as próximas gerações"),
    ],
    "Química Orgânica e Elementos da Tabela Periódica": [
        ("o que é a tabela periódica", "a tabela periódica é o quadro que organiza os elementos químicos em ordem crescente de número atômico e propriedades químicas"),
        ("o que é número atômico", "o número atômico indica a quantidade de prótons presentes no núcleo de um átomo e define a identidade do elemento químico"),
        ("o que é ligação covalente", "ligação covalente é a união química entre átomos caracterizada pelo compartilhamento de um ou mais pares de elétrons"),
        ("o que é um hidrocarboneto", "um hidrocarboneto é um composto químico orgânico formado exclusivamente por átomos de carbono e de hidrogênio"),
        ("o que é o ph", "o ph é a escala numérica de zero a quatorze que mede o grau de acidez ou alcalinidade de uma solução aquosa"),
    ],
    "Geografia Física e Climatologia": [
        ("o que são placas tectônicas", "placas tectônicas são grandes blocos rochosos da litosfera que se deslocam lentamente sobre o manto terrestre"),
        ("o que é o clima", "o clima é a sucessão habitual das condições atmosféricas observada em uma região ao longo de várias décadas"),
        ("o que é uma bacia hidrográfica", "uma bacia hidrográfica é a área geográfica drenada por um rio principal e por todos os seus afluentes"),
        ("o que é o bioma cerrado", "o cerrado é a savana tropical brasileira caracterizada por estações bem definidas árvores tortuosas e grande biodiversidade"),
    ],
    "Lógica Matemática e Probabilidade": [
        ("o que é matemática", "matemática é a ciência formal que estuda quantidades estruturas variações espaço e relações lógicas abstratas"),
        ("o que é uma proposição lógica", "uma proposição lógica é uma sentença declarativa que pode ser avaliada de forma inequívoca como verdadeira ou falsa"),
        ("o que é um número primo", "um número primo é um número natural maior que um que possui exatamente dois divisores distintos o um e ele mesmo"),
        ("o que é probabilidade", "probabilidade é o ramo da matemática que calcula a chance numérica de ocorrência de um evento aleatório"),
        ("o que é média aritmética", "a média aritmética é o quociente obtido ao dividir a soma de todos os valores de um conjunto pela quantidade de elementos"),
        ("o que é uma matriz na matemática", "uma matriz é uma estrutura matemática retangular de números ou símbolos dispostos em linhas e colunas"),
    ],
    "Países da América Latina": [
        ("o que é a américa latina", "a américa latina é a região do continente americano composta pelos países cujo idioma oficial deriva do latim como português e espanhol"),
        ("qual é a capital do brasil", "a capital federal do brasil é brasília planejada por lúcio costa e oscar niemeyer e inaugurada em 1960"),
        ("qual é a capital da argentina", "a capital da argentina é buenos aires importante centro cultural econômico e portuário da américa do sul"),
        ("qual é a capital do chile", "a capital do chile é santiago localizada no vale central próximo à cordilheira dos andes"),
    ],
    "Cumprimentar Pessoa": [
        ("como cumprimentar uma pessoa", "você pode cumprimentar dizendo olá bom dia boa tarde ou boa noite de forma cordial e educada"),
        ("qual a importância de cumprimentar uma pessoa", "cumprimentar demonstra respeito educação e simpatia facilitando o início de uma comunicação positiva"),
    ],
}


def _resolver_conceitos_para_topico(topico: str) -> list[tuple[str, str]]:
    """Encontra os conceitos verificados mais aderentes ao tópico informado."""
    if topico in CONCEITOS_BASE:
        return list(CONCEITOS_BASE[topico])

    t_low = re.sub(r"\s+—\s+.*$", "", topico.strip().lower()).strip()

    # Busca correspondência direta ou por palavra-chave no dicionário
    mapa_chaves = [
        (("enem", "exame nacional"), "Enem"),
        (("redação", "redacao", "dissertação"), "Redação"),
        (("gramática", "gramatica", "sintaxe", "morfologia"), "Gramática"),
        (("português", "portugues", "língua portuguesa"), "Português"),
        (("literatura", "romantismo", "modernismo"), "Literatura"),
        (("história", "historia"), "História do Brasil e do Mundo"),
        (("vestibular", "sisu", "prouni"), "Vestibular"),
        (("concurso", "edital"), "Concurso"),
        (("medicina", "médico", "diagnóstico"), "Medicina"),
        (("corpo humano", "anatomia", "fisiologia", "circulatório"), "Corpo Humano"),
        (("sus", "sistema único de saúde", "saúde pública"), "SUS"),
        (("sistema operacional", "linux", "windows", "kernel"), "Sistema Operacional"),
        (("buraco negro", "horizonte de eventos"), "Buraco Negro"),
        (("espaço", "astronomia", "sistema solar", "astrofísica", "galáxia", "planeta"), "Astronomia e Sistema Solar"),
        (("física", "fisica", "eletromagnetismo", "elétrica", "quântica", "term"), "Física Quântica e Eletromagnetismo"),
        (("matemática", "matematica", "estatística", "probabilidade", "lógica"), "Lógica Matemática e Probabilidade"),
        (("biologia", "célula", "genética", "dna", "biotecnologia"), "Biologia Celular e Genética"),
        (("química", "quimica", "tabela periódica", "reações"), "Química Orgânica e Elementos da Tabela Periódica"),
        (("geografia", "clima", "meio ambiente", "relevo"), "Geografia Física e Climatologia"),
        (("energia solar", "fotovoltaica", "inversor", "renovável", "sustentabilidade"), "Energias Renováveis e Sustentabilidade"),
        (("inteligência artificial", "redes neurais", "machine learning", "aprendizado de máquina"), "Inteligência Artificial e Redes Neurais"),
        (("computação", "algoritmos", "estruturas de dados", "programação", "eletrônica", "microcontroladores", "automação", "robótica", "redes de computadores"), "Ciência da Computação e Algoritmos"),
        (("america latina", "américa latina", "paises"), "Países da América Latina"),
        (("cumpriment", "compriment", "sauda", "conversa"), "Cumprimentar Pessoa"),
    ]
    for termos, chave_alvo in mapa_chaves:
        if any(k in t_low for k in termos):
            return list(CONCEITOS_BASE[chave_alvo])

    # Fallback se for um termo específico novo: evita frases tautológicas
    return [
        # Templates genéricos removidos para evitar ruído no treinamento
    ]


def expandir_variacoes_pergunta(pergunta: str, resposta: str, topico: str) -> list[tuple[str, str]]:
    """Gera variações naturais de pergunta sem jamás duplicar o sujeito na resposta."""
    p_limpa = normalizar_texto_neurograph(pergunta)
    r_limpa = normalizar_texto_neurograph(resposta)
    pares = [(p_limpa, r_limpa)]

    m_o_que_e = re.match(r"^o que (?:é|e|são|foi) (?:um |uma |o |a |os |as )?(.+)$", p_limpa)
    if m_o_que_e:
        termo = m_o_que_e.group(1).strip()
        pares.append((f"explique {termo}", r_limpa))
        pares.append((f"defina {termo}", r_limpa))
        pares.append((f"qual o conceito de {termo}", r_limpa))

    return pares


def gerar_lote_com_chatgpt(
    topico: str,
    qtd_desejada: int,
    api_key: Optional[str] = None,
) -> list[ParTreinamento]:
    """Usa o provedor LLM configurado (OpenAI ou local via INI) para gerar perguntas e respostas didáticas."""
    if not tem_ia_ativa(api_key):
        return []

    cfg = carregar_config_llm_ini()
    pares_gerados: list[ParTreinamento] = []
    perguntas_vistas: set[str] = set()
    tamanho_sublote = 10
    restantes = qtd_desejada
    stop_file = DIR_TREINO / ".stop_training"
    tentativas_sem_avanco = 0

    while restantes > 0 and len(pares_gerados) < qtd_desejada and tentativas_sem_avanco < 2:
        if stop_file.exists():
            print("  [PARADA SOLICITADA] Interrompendo chamadas à IA para salvar o que já foi gerado...")
            break
        qtd_chamada = min(restantes, tamanho_sublote)
        prompt_user = (
            f"Tópico: {topico}\n"
            f"Gere {qtd_chamada} pares conceituais diretos de pergunta e resposta em português sobre '{topico}'.\n"
            f"Regras:\n"
            f"- 'question': pergunta curta e clara em minúsculas (ex: 'o que é ...', 'como funciona ...', 'qual a função de ...').\n"
            f"- 'answer': resposta factual completa e direta em português (entre 8 e 28 palavras, sem repetir o termo duas vezes).\n"
            f"Retorne APENAS um array JSON válido:\n"
            f'[{{"question": "...", "answer": "..."}}]'
        )
        raw = requisitar_chat_llm(
            messages=[
                {
                    "role": "system",
                    "content": "Você é um professor especialista brasileiro que cria perguntas e respostas factuais curtas em formato JSON.",
                },
                {"role": "user", "content": prompt_user},
            ],
            temperature=0.35,
            max_tokens=900,
            api_key=api_key,
        )
        itens = extrair_json_da_resposta(raw or "")
        if isinstance(itens, dict) and "question" in itens:
            itens = [itens]

        adicionados_nesta = 0
        if isinstance(itens, list):
            for it in itens:
                if not isinstance(it, dict):
                    continue
                q = normalizar_texto_neurograph(it.get("question", ""))
                a = normalizar_texto_neurograph(it.get("answer", ""))
                if q and a and q not in perguntas_vistas and eh_par_conceitual_valido(q, a):
                    perguntas_vistas.add(q)
                    pares_gerados.append(
                        ParTreinamento(
                            question=q,
                            answer=a,
                            context=[],
                            category="mass_training",
                            video_id=topico,
                            origem=cfg.get("model", "chatgpt_massivo"),
                        )
                    )
                    adicionados_nesta += 1

        if adicionados_nesta > 0:
            restantes -= adicionados_nesta
            tentativas_sem_avanco = 0
        else:
            tentativas_sem_avanco += 1

    return pares_gerados


def gerar_um_item_chatgpt(
    topico: str,
    indice_item: int,
    perguntas_ja_geradas: set[str],
    api_key: Optional[str] = None,
) -> Optional[ParTreinamento]:
    """Gera 1 único par de pergunta e resposta via LLM configurado (OpenAI ou local)."""
    if not tem_ia_ativa(api_key):
        return None

    cfg = carregar_config_llm_ini()
    evitar = [q for q in list(perguntas_ja_geradas)[-15:] if topico.lower()[:5] in q] or list(perguntas_ja_geradas)[-10:]
    str_evitar = ("\nNão repita estas perguntas já criadas: " + "; ".join(evitar)) if evitar else ""
    prompt_user = (
        f"Tópico: {topico} (Conceito #{indice_item})\n"
        f"Gere exatamente 1 par conceitual de pergunta e resposta em português sobre '{topico}'.{str_evitar}\n"
        f"A pergunta deve ser direta sobre um conceito específico de '{topico}' (ex: 'o que é ...', 'como funciona ...').\n"
        f"A resposta deve ser factual, clara e completa (entre 8 e 26 palavras, sem repetir palavras no início).\n"
        f"Retorne APENAS um objeto JSON:\n"
        f'{{"question": "...", "answer": "..."}}'
    )
    raw = requisitar_chat_llm(
        messages=[
            {
                "role": "system",
                "content": "Você é um professor brasileiro que gera pares pergunta-resposta conceituais em português. Retorne apenas JSON válido.",
            },
            {"role": "user", "content": prompt_user},
        ],
        temperature=0.45,
        max_tokens=300,
        api_key=api_key,
    )
    dados = extrair_json_da_resposta(raw or "")
    if isinstance(dados, list) and dados:
        dados = dados[0]
    if isinstance(dados, dict):
        q = normalizar_texto_neurograph(dados.get("question", ""))
        a = normalizar_texto_neurograph(dados.get("answer", ""))
        if q and a and q not in perguntas_ja_geradas and eh_par_conceitual_valido(q, a):
            return ParTreinamento(
                question=q,
                answer=a,
                context=[],
                category="incremental_training",
                video_id=topico,
                origem=cfg.get("model", "chatgpt_item"),
            )
    return None


def gerar_lote_heuristico(
    topico: str,
    qtd_desejada: int,
) -> list[ParTreinamento]:
    """Gera pares conceituais verificados a partir da base pedagógica sem tautologias."""
    conceitos = _resolver_conceitos_para_topico(topico)

    banco_expandido: list[tuple[str, str]] = []
    for q, a in conceitos:
        banco_expandido.extend(expandir_variacoes_pergunta(q, a, topico))

    resultados: list[ParTreinamento] = []
    vistos: set[str] = set()

    for q, a in banco_expandido:
        qn = normalizar_texto_neurograph(q)
        an = normalizar_texto_neurograph(a)
        if qn and an and qn not in vistos and eh_par_conceitual_valido(qn, an):
            vistos.add(qn)
            resultados.append(
                ParTreinamento(
                    question=qn,
                    answer=an,
                    context=[],
                    category="incremental_training",
                    video_id=topico,
                    origem="base_conceitual_ptbr",
                )
            )
            if len(resultados) >= qtd_desejada:
                break

    return resultados[:qtd_desejada]


def executar_treinamento_10_topicos(
    topicos: Optional[list[str]] = None,
    min_total: int = 10,
    api_key: Optional[str] = None,
    treinar_modelo: bool = True,
    caminho_modelo: Optional[Path] = None,
    pasta_saida: Optional[Path] = None,
) -> dict:
    """Executa o ciclo item a item: gera 1 item -> treina a rede e salva (.ngs) -> próximo item."""
    from model import Example, TokenGraph, tokenize

    if topicos:
        topicos = [t.strip() for t in topicos if t and t.strip()]
    if not topicos:
        topicos = list(TOPICOS_PADRAO_10)

    if pasta_saida is None:
        pasta_saida = DIR_TREINO / "dados" / "processados"
    pasta_saida.mkdir(parents=True, exist_ok=True)

    total_desejado = max(1, int(min_total))
    qtd_topicos = len(topicos)

    base_por_topico = total_desejado // qtd_topicos
    resto = total_desejado % qtd_topicos
    distribuicao: dict[str, int] = {}
    for idx_t, t in enumerate(topicos):
        distribuicao[t] = base_por_topico + (1 if idx_t < resto else 0)

    distribuicao = {t: q for t, q in distribuicao.items() if q > 0}
    soma_atual = sum(distribuicao.values())

    alvo_rede = (caminho_modelo or (DIR_TREINO / "modelos" / "neurograph_youtube.ngs")).resolve()
    alvo_rede.parent.mkdir(parents=True, exist_ok=True)

    print("=" * 72)
    print(f"  TREINAMENTO INCREMENTAL ITEM A ITEM - {len(distribuicao)} TÓPICO(S)")
    print("=" * 72)
    print(f"Rede Alvo (.ngs)    : {alvo_rede}")
    print(f"Quantidade Aceita   : {soma_atual} item(ns) (Gera 1 item -> Treina -> Salva -> Próximo)")
    print("-" * 72)
    for i, (topico, qtd) in enumerate(distribuicao.items(), 1):
        print(f"  {i:2d}. [{qtd:3d} item(ns)] -> {topico}")
    print("-" * 72)

    if alvo_rede.exists() and alvo_rede.stat().st_size > 0:
        try:
            modelo = TokenGraph.load(alvo_rede)
            print(f"[REDE CARREGADA] {alvo_rede.name} ({len(modelo.tokens)} tokens, {len(modelo.features)} features)")
        except Exception:
            modelo = TokenGraph()
    else:
        modelo = TokenGraph()

    caminho_dataset = pasta_saida / "dataset_curado.json"
    caminho_ultimo_treino = pasta_saida / "ultimo_treino_topicos.json"
    exemplos_base, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)

    todos_pares: list[ParTreinamento] = []
    perguntas_vistas: set[str] = {ex.question for ex in exemplos_base if ex.question}
    ia_disponivel = tem_ia_ativa(api_key)
    stop_file = DIR_TREINO / ".stop_training"
    if stop_file.exists():
        try:
            stop_file.unlink()
        except Exception:
            pass
    foi_cancelado = False
    contador_global = 0

    try:
        for i, (topico, qtd) in enumerate(distribuicao.items(), 1):
            if stop_file.exists():
                foi_cancelado = True
                break

            print(f"\n[Tópico {i}/{len(distribuicao)}] Iniciando '{topico}' ({qtd} item(ns))...")
            pool_heuristico = gerar_lote_heuristico(topico, qtd + 20)
            idx_heur = 0

            for num_no_topico in range(1, qtd + 1):
                if stop_file.exists():
                    print(f"\n[PARADA SOLICITADA] Interrompendo no item {contador_global + 1}/{soma_atual}...")
                    foi_cancelado = True
                    break

                contador_global += 1
                par_atual: Optional[ParTreinamento] = None

                if ia_disponivel:
                    par_atual = gerar_um_item_chatgpt(topico, num_no_topico, perguntas_vistas, api_key=api_key)

                while par_atual is None and idx_heur < len(pool_heuristico):
                    candidato = pool_heuristico[idx_heur]
                    idx_heur += 1
                    if candidato.question not in perguntas_vistas:
                        par_atual = candidato
                        break

                if par_atual is None:
                    continue

                perguntas_vistas.add(par_atual.question)
                todos_pares.append(par_atual)

                salvar_pares_processados([par_atual], pasta_saida, nome_arquivo="dataset_curado.json")
                with caminho_ultimo_treino.open("w", encoding="utf-8") as f_ult:
                    json.dump([asdict(p) for p in todos_pares], f_ult, ensure_ascii=False, indent=2)

                palavras_resp = tokenize(par_atual.answer)
                resp_limpa = " ".join(palavras_resp[:60]) if len(palavras_resp) > 62 else par_atual.answer
                novo_ex = Example(question=par_atual.question, answer=resp_limpa, context=())
                exemplos_base.append(novo_ex)

                if treinar_modelo:
                    amostra_replay = exemplos_base[-24:]
                    negativos = [e for e in exemplos_base if e.answer is None][:4]
                    lote_incremental = amostra_replay + [e for e in negativos if e not in amostra_replay]
                    modelo.fit(lote_incremental, epochs=18, learning_rate=0.05)
                    modelo.save(alvo_rede)

                print(f"  [{contador_global}/{soma_atual}] [TREINADO] P: {par_atual.question} | R: {par_atual.answer}")

            if foi_cancelado:
                break
    except KeyboardInterrupt:
        print("\n[INTERROMPIDO] Salvando estado atual da rede...")
        foi_cancelado = True

    if stop_file.exists():
        try:
            stop_file.unlink()
        except Exception:
            pass

    if treinar_modelo and exemplos_base:
        epocas_finais = 12 if len(todos_pares) <= 100 else (20 if foi_cancelado else 35)
        lote_final = exemplos_base[-80:] if len(todos_pares) <= 100 else exemplos_base
        print(f"\n[CONSOLIDAÇÃO FINAL] Ajustando sinapses em '{alvo_rede.name}' ({epocas_finais} épocas)...")
        modelo.fit(lote_final, epochs=epocas_finais, learning_rate=0.05)
        modelo.save(alvo_rede)
        tam_bytes = alvo_rede.stat().st_size if alvo_rede.exists() else 0
        print(f"[REDE SALVA COM SUCESSO] {alvo_rede} ({tam_bytes} bytes)")

    print("\n" + "=" * 72)
    status_str = "PARCIAL (INTERROMPIDO E SALVO)" if foi_cancelado else "CONCLUÍDO COM SUCESSO"
    print(f"STATUS {status_str}: {len(todos_pares)} ITEM(NS) GERADOS E TREINADOS UM A UM")
    print("=" * 72)

    return {
        "status": "cancelado_e_salvo" if foi_cancelado else "concluido",
        "total_pares_gerados": len(todos_pares),
        "distribuicao": distribuicao,
        "dataset": str(caminho_dataset),
        "ultimo_treino": str(caminho_ultimo_treino),
        "modelo_treinado": treinar_modelo,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Gerador e treinador incremental item a item do NeuroGraph.")
    parser.add_argument("--topicos", nargs="*", help="Lista de tópicos (se omitido, usa os 10 tópicos padrão).")
    parser.add_argument("--min", type=int, default=10, help="Quantidade de pares a gerar e treinar (aceita qualquer número >= 1).")
    parser.add_argument("--modelo", "-m", type=Path, default=None, help="Caminho do arquivo de pesos da rede alvo (.ngs).")
    parser.add_argument("--api-key", type=str, default=None, help="Chave OpenAI API (opcional).")
    parser.add_argument("--sem-treino", action="store_true", help="Apenas gera os pares sem treinar os pesos.")
    parser.add_argument("--json", action="store_true", help="Retorna saída estruturada em JSON.")

    args = parser.parse_args()
    qtd_aceita = max(1, args.min)

    res = executar_treinamento_10_topicos(
        topicos=args.topicos,
        min_total=qtd_aceita,
        api_key=args.api_key,
        treinar_modelo=not args.sem_treino,
        caminho_modelo=args.modelo,
    )

    if args.json:
        print(json.dumps(res, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
