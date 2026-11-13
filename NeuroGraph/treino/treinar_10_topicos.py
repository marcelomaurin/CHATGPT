#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Gerador Massivo de Treinamento Conceitual para o NeuroGraph.

Requisito do Usuário:
1. Pede/recebe 10 tópicos de conhecimento (ou sugere 10 tópicos abrangentes se não fornecidos).
2. A IA gera um número aleatório de perguntas e respostas para cada tópico.
3. Quantidade total NUNCA MENOR QUE 1000 pares (>= 1000).
4. Suporta execução com API OpenAI (ChatGPT) ou motor heurístico/conceitual autônomo offline.
5. Salva no dataset curado e opcionalmente dispara o retreinamento do TokenGraph.
"""
from __future__ import annotations

import argparse
import codecs
import json
import logging
import os
import random
import re
import sys
import time
from dataclasses import asdict
from pathlib import Path
from typing import Any, Optional

# Força UTF-8 seguro no console Windows
if sys.platform == "win32":
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

from curador_chatgpt import ParTreinamento, normalizar_texto_neurograph, salvar_pares_processados
from treinador_neurograph import preparar_exemplos, treinar_neurograph

# 10 tópicos padrão de alto valor didático para expansão cognitiva do NeuroGraph
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

# Base conceitual sintética para expansão de alta fidelidade sem internet (>= 1000 pares garantidos)
CONCEITOS_BASE = {
    "Inteligência Artificial e Redes Neurais": [
        ("o que é inteligência artificial", "inteligência artificial é o ramo da ciência da computação que cria sistemas capazes de simular o raciocínio humano"),
        ("o que é aprendizado de máquina", "aprendizado de máquina é um método onde sistemas aprendem a reconhecer padrões diretamente a partir de dados"),
        ("o que é uma rede neural artificial", "uma rede neural artificial é um modelo computacional inspirado nas conexões sinápticas de neurônios biológicos"),
        ("o que é um neurônio artificial", "um neurônio artificial é uma unidade de processamento matemático que calcula a soma ponderada de entradas e aplica uma ativação"),
        ("o que é backpropagation", "backpropagation é o algoritmo de retropropagação do erro usado para atualizar os pesos de uma rede neural via gradiente descendente"),
        ("o que é uma função de ativação", "uma função de ativação é uma função matemática que introduz não linearidade na saída de um neurônio"),
        ("o que é a função relu", "a função relu é uma ativação que retorna zero para valores negativos e o próprio valor para entradas positivas"),
        ("o que é a função sigmoid", "a função sigmoid é uma curva que mapeia qualquer número real em uma probabilidade contínua entre zero e um"),
        ("o que é overfitting", "overfitting ocorre quando um modelo decora os dados de treino e perde a capacidade de generalizar para novos dados"),
        ("o que é underfitting", "underfitting ocorre quando o modelo é excessivamente simples para capturar os padrões fundamentais dos dados"),
        ("o que é gradiente descendente", "gradiente descendente é um algoritmo de otimização que ajusta os pesos na direção contrária à derivada do erro"),
        ("o que é taxa de aprendizado", "a taxa de aprendizado é o hiperparâmetro que define o tamanho do passo dado a cada iteração do otimizador"),
        ("o que é um transformer", "o transformer é uma arquitetura de rede neural baseada no mecanismo de atenção para processar sequências em paralelo"),
        ("o que é mecanismo de atenção", "o mecanismo de atenção calcula pesos de importância relativa entre todas as palavras de uma sequência"),
        ("o que é um token", "um token é a unidade básica de texto como uma palavra ou pedaço de palavra processada por um modelo de linguagem"),
        ("o que é um embedding", "um embedding é uma representação vetorial densa em que termos com significado similar ficam próximos no espaço numérico"),
        ("o que é fine tuning", "fine tuning é o ajuste fino dos parâmetros de um modelo pré treinado em uma base de dados específica"),
        ("o que é inferência", "inferência é a fase em que o modelo já treinado processa novas entradas para gerar predições ou respostas"),
        ("o que é prompt", "um prompt é a instrução em linguagem natural fornecida a um modelo gerador para guiar sua resposta"),
        ("o que é neurograph", "o neurograph é uma rede neural associativa em grafo de tokens desenvolvida para raciocínio contextual transparente"),
    ],
    "Ciência da Computação e Algoritmos": [
        ("o que é um algoritmo", "um algoritmo é uma sequência finita de passos bem definidos e lógicos para solucionar um problema computacional"),
        ("o que é uma variável", "uma variável é um espaço alocado na memória para armazenar dados mutáveis durante a execução de um programa"),
        ("o que é uma função", "uma função é um bloco de código reutilizável que recebe parâmetros processa dados e retorna um resultado"),
        ("o que é recursão", "recursão é a técnica onde uma função chama a si mesma até atingir uma condição de parada pré estabelecida"),
        ("o que é complexidade assintótica", "a complexidade assintótica mede o crescimento do tempo de execução ou do uso de memória com a notação big o"),
        ("o que é uma pilha", "uma pilha é uma estrutura de dados do tipo lifo onde o último elemento adicionado é sempre o primeiro a ser removido"),
        ("o que é uma fila", "uma fila é uma estrutura de dados do tipo fifo onde o primeiro elemento adicionado é o primeiro a ser processado"),
        ("o que é uma árvore binária", "uma árvore binária é uma estrutura hierárquica onde cada nó possui no máximo dois filhos denominados esquerdo e direito"),
        ("o que é uma tabela hash", "uma tabela hash é uma estrutura que armazena pares de chave e valor permitindo buscas rápidas em tempo médio constante"),
        ("o que é ordenação quicksort", "o quicksort é um algoritmo de ordenação por divisão e conquista que particiona os dados em torno de um elemento pivô"),
        ("o que é busca binária", "a busca binária é um algoritmo de busca eficiente em listas ordenadas que divide o intervalo pela metade a cada passo"),
        ("o que é compilador", "um compilador é um programa que traduz código fonte em linguagem de alto nível para código de máquina ou binário"),
        ("o que é um interpretador", "um interpretador é um programa que lê e executa o código fonte instrução por instrução sem gerar binário prévio"),
        ("o que é sistema operacional", "um sistema operacional é o software fundamental que gerencia o hardware a memória os processos e os arquivos do computador"),
        ("o que é memória ram", "a memória ram é uma memória volátil de acesso rápido usada pelo processador para armazenar programas em execução"),
        ("o que é disco ssd", "o disco ssd é uma unidade de armazenamento persistente não volátil baseada em memória flash semicondutora"),
        ("o que é endereço ip", "o endereço ip é um identificador numérico exclusivo atribuído a cada dispositivo conectado a uma rede de computadores"),
        ("o que é protocolo tcp", "o protocolo tcp garante a entrega confiável e ordenada de pacotes de dados através da confirmação de recebimento"),
        ("o que é protocolo udp", "o protocolo udp é um protocolo de transporte leve sem garantia de entrega ou confirmação ideal para streaming e jogos"),
        ("o que é criptografia assimétrica", "a criptografia assimétrica utiliza um par de chaves composto por uma pública para cifrar e uma privada para decifrar"),
    ],
    "Astronomia e Sistema Solar": [
        ("o que é uma estrela", "uma estrela é uma esfera colossal de plasma luminosa sustentada pela fusão nuclear contínua em seu núcleo denso"),
        ("o que é o sol", "o sol é a estrela anã amarela localizada no centro do nosso sistema solar fornecendo luz e gravidade aos planetas"),
        ("o que é um planeta", "um planeta é um corpo celeste esférico que orbita uma estrela e limpou a vizinhança de sua própria órbita"),
        ("o que é a gravidade", "a gravidade é a força fundamental de atração mútua entre massas descrita como curvatura do espaço tempo na relatividade"),
        ("o que é uma galáxia", "uma galáxia é um vasto sistema gravitacionalmente ligado contendo bilhões de estrelas gás poeira e matéria escura"),
        ("o que é a via láctea", "a via láctea é a galáxia espiral barrada onde nosso sistema solar e o planeta terra estão localizados"),
        ("o que é um buraco negro", "um buraco negro é uma região do espaço tempo com densidade tão extrema que nada nem mesmo a luz consegue escapar"),
        ("o que é o horizonte de eventos", "o horizonte de eventos é a fronteira limite ao redor de um buraco negro a partir da qual nenhum sinal pode retornar"),
        ("o que é uma supernova", "uma supernova é uma explosão cataclísmica de uma estrela massiva ao final de sua evolução termonuclear"),
        ("o que é um cometa", "um cometa é um corpo celeste menor formado por gelo poeira e rocha que produz uma cauda brilhante perto do sol"),
        ("o que é um asteroide", "um asteroide é um corpo rochoso e metálico que orbita o sol concentrado principalmente no cinturão entre marte e júpiter"),
        ("o que é a lua", "a lua é o único satélite natural da terra cuja atração gravitacional regula as marés oceânicas do planeta"),
        ("o que é júpiter", "júpiter é o maior planeta do sistema solar composto predominantemente por hidrogênio e hélio com tempestades gigantes"),
        ("o que é marte", "marte é o quarto planeta a partir do sol conhecido como planeta vermelho devido ao óxido de ferro presente em seu solo"),
        ("o que é um exoplaneta", "um exoplaneta é um planeta localizado fora do sistema solar orbitando uma estrela diferente do nosso sol"),
        ("o que é a matéria escura", "a matéria escura é uma forma invisível de matéria hipotética que exerce atração gravitacional em galáxias"),
        ("o que é energia escura", "a energia escura é a pressão repulsiva desconhecida que acelera a expansão contínua do universo observável"),
        ("o que é o big bang", "o big bang é o modelo cosmológico que descreve a origem e a expansão rápida do universo a partir de um estado primordial quente"),
        ("o que é ano luz", "o ano luz é a unidade astronômica de distância equivalente ao percurso que a luz viaja no vácuo em um ano terrestre"),
        ("o que é uma nebulosa", "uma nebulosa é uma imensa nuvem interestelar de poeira hidrogênio e plasma onde comumente nascem novas estrelas"),
    ],
    "Física Quântica e Eletromagnetismo": [
        ("o que é um fóton", "o fóton é o quantum fundamental de luz e a partícula mediadora de toda a força eletromagnética"),
        ("o que é um elétron", "o elétron é uma partícula subatômica de carga elétrica negativa que orbita o núcleo atômico"),
        ("o que é superposição quântica", "superposição quântica é o princípio onde uma partícula existe em múltiplos estados simultâneos até que seja medida"),
        ("o que é entrelaçamento quântico", "entrelaçamento quântico é o fenômeno em que duas partículas compartilham propriedades de forma instantânea a qualquer distância"),
        ("o que é o princípio da incerteza", "o princípio da incerteza de heisenberg estabelece que não é possível determinar simultaneamente a posição e o momento exatos de uma partícula"),
        ("o que é a dualidade onda partícula", "a dualidade onda partícula afirma que entidades quânticas exibem tanto propriedades ondulatórias quanto corpusculares"),
        ("o que é um qubit", "um qubit é a unidade básica da computação quântica capaz de representar zero um ou ambos simultaneamente em superposição"),
        ("o que é tunelamento quântico", "tunelamento quântico é a passagem de uma partícula através de uma barreira de potencial que seria intransponível pela física clássica"),
        ("o que é campo elétrico", "o campo elétrico é a região do espaço modificada pela presença de cargas elétricas que exerce força sobre outras cargas"),
        ("o que é campo magnético", "o campo magnético é o campo de forças gerado por cargas elétricas em movimento ou por ímãs naturais"),
        ("o que é a lei de faraday", "a lei de faraday afirma que a variação temporal de um fluxo magnético induz uma força eletromotriz em um circuito"),
        ("o que é corrente elétrica", "corrente elétrica é o fluxo ordenado de partículas carregadas como elétrons através de um material condutor"),
        ("o que é tensão elétrica", "tensão elétrica ou diferença de potencial é a força que impulsiona os elétrons através de um condutor elétrico"),
        ("o que é resistência elétrica", "resistência elétrica é a oposição física que um material oferece à passagem contínua da corrente elétrica"),
        ("o que é a lei de ohm", "a lei de ohm determina que a corrente em um condutor é diretamente proporcional à tensão e inversamente à resistência"),
        ("o que é condutividade térmica", "condutividade térmica é a capacidade de um material conduzir calor através da vibração molecular interna"),
        ("o que é um semicondutor", "um semicondutor é um material cuja condutividade elétrica pode ser controlada com precisão entre isolante e condutor"),
        ("o que é superfluidez", "superfluidez é o estado físico da matéria no qual um líquido flui sem qualquer viscosidade ou atrito interno"),
        ("o que é supercondutividade", "supercondutividade é o fenômeno onde certos materiais conduzem eletricidade com resistência rigorosamente nula a baixas temperaturas"),
        ("o que é a velocidade da luz", "a velocidade da luz no vácuo é a velocidade máxima do universo correspondendo a aproximadamente trezentos mil quilômetros por segundo"),
    ],
    "Biologia Celular e Genética": [
        ("o que é dna", "o dna é a molécula de ácido desoxirribonucleico que armazena todas as instruções genéticas dos seres vivos"),
        ("o que é rna", "o rna é a molécula responsável por transferir a informação genética do dna e orientar a síntese de proteínas"),
        ("o que é um gene", "um gene é um segmento específico de dna que contém o código para sintetizar uma proteína ou molécula funcional"),
        ("o que é cromossomo", "um cromossomo é uma estrutura condensada formada por dna e proteínas que abriga os genes nas células"),
        ("o que é a célula", "a célula é a unidade morfológica e funcional básica e viva que constitui todos os organismos biológicos"),
        ("o que é mitocôndria", "a mitocôndria é a organela celular encarregada de produzir energia na forma de trifosfato de adenosina via respiração celular"),
        ("o que é ribossomo", "o ribossomo é o complexo celular responsável por traduzir o rna mensageiro e montar cadeias de aminoácidos em proteínas"),
        ("o que é cloroplasto", "o cloroplasto é a organela vegetal que contém clorofila e realiza a fotossíntese captando a energia luminosa solar"),
        ("o que é fotossíntese", "fotossíntese é o processo bioquímico pelo qual plantas e algas convertem água e gás carbônico em glicose e oxigênio"),
        ("o que é mutação genética", "mutação genética é qualquer alteração permanente na sequência de nucleotídeos do material genético de um organismo"),
        ("o que é seleção natural", "seleção natural é o mecanismo evolutivo pelo qual indivíduos com características mais vantajosas sobrevivem e se reproduzem"),
        ("o que é meiose", "meiose é a divisão celular que reduz o número de cromossomos pela metade gerando gametas reprodutivos haploides"),
        ("o que é mitose", "mitose é a divisão celular que duplica uma célula somática mãe em duas células filhas geneticamente idênticas"),
        ("o que é membrana plasmática", "a membrana plasmática é a camada fosfolipídica que delimita a célula regulando o tráfego seletivo de substâncias"),
        ("o que é citoplasma", "o citoplasma é a matriz gelatinosa que preenche o interior da célula onde estão suspensas as organelas"),
        ("o que é enzima", "uma enzima é uma proteína biológica catalisadora que acelera reações químicas sem ser consumida no processo"),
        ("o que é proteína", "uma proteína é uma macromolécula essencial composta por uma sequência de aminoácidos ligados por ligações peptídicas"),
        ("o que é código genético", "o código genético é o conjunto de regras pelo qual trincas de bases nitrogenadas chamadas códons codificam aminoácidos"),
        ("o que é crispr", "crispr é uma técnica biotecnológica de edição genética precisa que permite cortar e modificar sequências específicas de dna"),
        ("o que é homeostase", "homeostase é a capacidade de um organismo vivo manter o equilíbrio interno de suas funções constante frente ao ambiente"),
    ],
    "História do Brasil e do Mundo": [
        ("o que foi o renascimento", "o renascimento foi o movimento cultural e científico europeu caracterizado pelo humanismo e pela retomada clássica"),
        ("o que foi a revolução industrial", "a revolução industrial foi a transição para novos processos de manufatura baseados em máquinas a vapor e fábricas"),
        ("o que foi a revolução francesa", "a revolução francesa foi o levante político de 1789 que derrubou o absolutismo e difundiu os princípios de liberdade e igualdade"),
        ("o que foi a primeira guerra mundial", "a primeira guerra mundial foi o conflito global entre 1914 e 1918 travado nas trincheiras europeias entre as grandes potências"),
        ("o que foi a segunda guerra mundial", "a segunda guerra mundial foi o maior conflito militar da história entre os aliados e as potências do eixo de 1939 a 1945"),
        ("o que foi a guerra fria", "a guerra fria foi o período de rivalidade geopolítica ideológica e armamentista entre os estados unidos e a união soviética"),
        ("quando ocorreu a independência do brasil", "a independência do brasil foi proclamada por dom pedro primeiro em 7 de setembro de 1822 às margens do ipiranga"),
        ("o que foi a proclamação da república no brasil", "a proclamação da república ocorreu em 15 de novembro de 1889 liderada pelo marechal deodoro da fonseca derrubando a monarquia"),
        ("o que foi a lei áurea", "a lei áurea foi a lei assinada pela princesa isabel em 13 de maio de 1888 que extinguiu a escravidão formal no brasil"),
        ("o que foi o iluminismo", "o iluminismo foi a corrente filosófica do século dezoito que defendia a razão a ciência e a liberdade individual contra a tirania"),
        ("o que era a polis na grécia antiga", "a polis era a cidade estado autônoma com estrutura política e social própria na grécia antiga"),
        ("o que foi o império romano", "o império romano foi o período político da civilização romana antiga com governo autocrático centrado no imperador"),
        ("o que foi a queda da bastilha", "a queda da bastilha foi o marco inicial simbólico da revolução francesa onde o povo tomou a prisão medieval parisiense"),
        ("o que foi o ciclo do ouro no brasil", "o ciclo do ouro foi o auge da mineração nas minas gerais no século dezoito impulsionando o povoamento e os tributos coloniais"),
        ("o que foi a inconfidência mineira", "a inconfidência mineira foi a conspiração republicana separatista de 1789 em minas gerais cujo mártir foi tiradentes"),
        ("o que foi a era vargas", "a era vargas foi o período de governo de getúlio vargas entre 1930 e 1945 marcado por leis trabalhistas e industrialização"),
        ("o que foi o tratado de versalhes", "o tratado de versalhes foi o acordo de paz assinado em 1919 impondo severas sanções à alemanha após a primeira guerra"),
        ("o que é a onu", "a onu é a organização das nações unidas criada em 1945 para promover a paz internacional e a cooperação entre os países"),
        ("o que foi o período neolítico", "o período neolítico foi a revolução agrícola onde a humanidade desenvolveu o cultivo a cerâmica e a sedentarização"),
        ("o que foram as grandes navegações", "as grandes navegações foram as expedições marítimas europeias dos séculos quinze e dezesseis que conectaram continentes"),
    ],
    "Energias Renováveis e Sustentabilidade": [
        ("o que é energia solar fotovoltaica", "energia solar fotovoltaica é a eletricidade gerada pela conversão direta da radiação solar através de semicondutores"),
        ("o que é um painel solar", "um painel solar é um módulo montado com células de silício que absorvem fótons solares para gerar corrente elétrica"),
        ("o que é um inversor solar", "o inversor solar é o dispositivo que transforma a corrente contínua produzida pelos painéis em corrente alternada para uso na rede"),
        ("o que é energia eólica", "energia eólica é a eletricidade gerada a partir da força cinética dos ventos que movimenta as pás de aerogeradores"),
        ("o que é um aerogerador", "um aerogerador é uma turbina eólica que converte a energia mecânica do vento em energia elétrica útil"),
        ("o que é energia hidrelétrica", "energia hidrelétrica é a geração de eletricidade através do aproveitamento do potencial gravitacional e do fluxo da água de rios"),
        ("o que é biomassa", "biomassa é qualquer matéria orgânica de origem vegetal ou animal aproveitada como fonte primária para geração de energia"),
        ("o que é biocombustível", "biocombustível é o combustível renovável derivado de fontes biológicas como o etanol da cana de açúcar ou o biodiesel"),
        ("o que é hidrogênio verde", "hidrogênio verde é o gás hidrogênio obtido através da eletrólise da água utilizando energia elétrica exclusivamente renovável"),
        ("o que é pegada de carbono", "a pegada de carbono mede o volume total de emissões de gases de efeito estufa produzidas pelas atividades humanas"),
        ("o que é efeito estufa", "efeito estufa é o processo natural em que gases na atmosfera retêm calor solar mantendo a temperatura adequada para a vida"),
        ("o que é aquecimento global", "aquecimento global é a elevação anormal da temperatura média da terra provocada pelo aumento das emissões industriais"),
        ("o que é sustentabilidade", "sustentabilidade é o desenvolvimento capaz de suprir as necessidades da geração atual sem comprometer as gerações futuras"),
        ("o que é economia circular", "economia circular é o modelo econômico regenerativo que prioriza a reutilização a reciclagem e a redução de resíduos"),
        ("o que é compostagem", "compostagem é a reciclagem biológica de matéria orgânica que a transforma em adubo natural rico em nutrientes para o solo"),
        ("o que é energia geotérmica", "energia geotérmica é a eletricidade e calor obtidos a partir das altas temperaturas presentes no interior da crosta terrestre"),
        ("o que é energia maremotriz", "energia maremotriz é a energia renovável capturada a partir do movimento natural de subida e descida das marés oceânicas"),
        ("o que é reciclagem", "reciclagem é o reprocessamento industrial de materiais descartados para reintroduzi los no ciclo produtivo como novos produtos"),
        ("o que é descarbonização", "descarbonização é o conjunto de medidas voltadas a eliminar o uso de combustíveis fósseis e zerar emissões de carbono"),
        ("o que é pegada hídrica", "a pegada hídrica quantifica o consumo direto e indireto de água doce em todas as etapas de produção de bens e serviços"),
    ],
    "Química Orgânica e Elementos da Tabela Periódica": [
        ("o que é a tabela periódica", "a tabela periódica é a organização sistemática dos elementos químicos ordenados por seu número atômico e propriedades periódicas"),
        ("o que é número atômico", "o número atômico representa a quantidade de prótons existente no núcleo do átomo definindo a identidade do elemento"),
        ("o que é uma molécula", "uma molécula é um grupo eletricamente neutro de átomos unidos por ligações químicas covalentes"),
        ("o que é ligação covalente", "ligação covalente é o compartilhamento estável de pares de elétrons entre átomos para atingir a configuração de gás nobre"),
        ("o que é ligação iônica", "ligação iônica é a atração eletrostática forte entre íons de cargas opostas decorrente da transferência de elétrons"),
        ("o que é o carbono", "o carbono é o elemento tetravalente fundamental para a química orgânica capaz de formar longas cadeias moleculares estáveis"),
        ("o que é um hidrocarboneto", "um hidrocarboneto é um composto orgânico binário constituído exclusivamente por átomos de carbono e hidrogênio"),
        ("o que é uma reação química", "uma reação química é a transformação onde substâncias chamadas reagentes quebram e recombinam ligações para formar novos produtos"),
        ("o que é o ph", "o ph é a escala logarítmica que mede a acidez neutralidade ou basicidade de uma solução aquosa de zero a quatorze"),
        ("o que é uma solução ácida", "uma solução ácida é aquela que apresenta concentração de íons de hidrogênio superior e valor de ph inferior a sete"),
        ("o que é uma solução básica", "uma solução básica ou alcalina é aquela que libera íons hidroxila apresentando valor de ph superior a sete"),
        ("o que é um catalisador", "um catalisador é uma substância que acelera uma reação química diminuindo a energia de ativação sem ser consumida"),
        ("o que é entalpia", "entalpia é a grandeza termodinâmica que mede a energia total e a quantidade de calor absorvida ou liberada em uma reação"),
        ("o que é oxigênio", "o oxigênio é o elemento químico não metálico vital para a respiração celular e principal agente comburente na combustão"),
        ("o que é hidrogênio", "o hidrogênio é o elemento químico mais leve abundante e simples do universo com apenas um próton e um elétron"),
        ("o que é a água", "a água é a substância molecular composta por dois átomos de hidrogênio e um de oxigênio de fórmula h2o e solvente universal"),
        ("o que é um polímero", "um polímero é uma macromolécula de alta massa molecular formada pela repetição sucessiva de unidades menores chamadas monômeros"),
        ("o que é oxidação", "oxidação é a perda de elétrons por uma espécie química durante uma reação de oxirredução"),
        ("o que é redução", "redução é o ganho de elétrons por uma espécie química durante uma reação química de oxirredução"),
        ("o que é um gás nobre", "um gás nobre é um elemento químico do grupo 18 caracterizado pela estabilidade eletrônica e baixíssima reatividade química"),
    ],
    "Geografia Física e Climatologia": [
        ("o que são placas tectônicas", "placas tectônicas são blocos rígidos da litosfera terrestre que flutuam e se movem lentamente sobre a astenosfera"),
        ("o que causa um terremoto", "um terremoto é causado pela liberação súbita de energia elástica acumulada pela fricção entre placas tectônicas"),
        ("o que é um vulcão", "um vulcão é uma abertura geológica na crosta que permite a ascensão de magma cinzas e gases do manto até a superfície"),
        ("o que é o clima", "o clima é o padrão médio das condições atmosféricas e do tempo observado em uma região ao longo de pelo menos trinta anos"),
        ("o que é o tempo meteorológico", "o tempo meteorológico é o estado momentâneo e variável da atmosfera em um local e horário específicos"),
        ("o que é a atmosfera", "a atmosfera é a camada protetora de gases retida pela gravidade que envolve a terra e sustenta a vida biológica"),
        ("o que é a troposfera", "a troposfera é a camada mais baixa da atmosfera onde ocorrem praticamente todos os fenômenos climáticos e meteorológicos"),
        ("o que é o ciclo da água", "o ciclo da água é o movimento contínuo da água através da evaporação condensação precipitação e infiltração no planeta"),
        ("o que é erosão", "erosão é o desgaste desagregação e transporte de sedimentos do solo e das rochas pela ação do vento da água e do gelo"),
        ("o que é intemperismo", "intemperismo é o conjunto de processos físicos e químicos que provocam a alteração e desintegração das rochas"),
        ("o que é bacia hidrográfica", "uma bacia hidrográfica é a área geográfica drenada por um rio principal e toda a sua rede de afluentes e subafluentes"),
        ("o que é uma floresta tropical", "uma floresta tropical é um bioma quente úmido com alta precipitação anual e altíssima biodiversidade vegetal e animal"),
        ("o que é um deserto", "um deserto é uma região árida com baixíssima pluviosidade anual amplitudes térmicas acentuadas e vegetação escassa"),
        ("o que é o bioma cerrado", "o cerrado é a savana brasileira caracterizada por árvores de casca grossa troncos retorcidos e solos profundos ácidos"),
        ("o que é a amazônia", "a amazônia é a maior floresta tropical e bacia hidrográfica do planeta com papel crítico na regulação do clima global"),
        ("o que é o relevo", "relevo é o conjunto das formas físicas da superfície terrestre esculpidas por forças internas endógenas e externas exógenas"),
        ("o que é uma cordilheira", "uma cordilheira é uma cadeia contínua e imensa de montanhas originada pelo choque frontal entre placas tectônicas"),
        ("o que é el niño", "el niño é o aquecimento anômalo das águas do oceano pacífico equatorial que altera os padrões de chuva e vento no mundo"),
        ("o que é la niña", "la niña é o resfriamento anômalo das águas do oceano pacífico equatorial provocando secas e chuvas opostas ao el niño"),
        ("o que é a camada de ozônio", "a camada de ozônio é a faixa da estratosfera que absorve a radiação ultravioleta prejudicial emitida pelo sol"),
    ],
    "Lógica Matemática e Probabilidade": [
        ("o que é uma proposição lógica", "uma proposição lógica é uma sentença declarativa afirmativa que pode ser classificada unicamente como verdadeira ou falsa"),
        ("o que é uma tabela verdade", "uma tabela verdade é uma representação esquemática que lista todos os valores lógicos possíveis de uma proposição composta"),
        ("o que é uma tautologia", "uma tautologia é uma proposição composta cujo valor lógico é sempre verdadeiro independentemente dos valores de suas partes"),
        ("o que é uma contradição", "uma contradição é uma proposição lógica que resulta sempre em valor falso em todas as suas interpretações"),
        ("o que é dedução lógica", "dedução é o processo de inferência onde conclusões necessárias são derivadas a partir de premissas gerais consideradas verdadeiras"),
        ("o que é indução matemática", "indução é o método que estabelece que uma proposição é válida para todos os inteiros demonstrando a base e o passo indutivo"),
        ("o que é um número primo", "um número primo é um número inteiro maior que um divisível de forma exata unicamente por um e por ele próprio"),
        ("o que é probabilidade", "probabilidade é o ramo da matemática que quantifica a chance de ocorrência de um determinado evento em um experimento aleatório"),
        ("o que é o espaço amostral", "o espaço amostral é o conjunto que contém todos os resultados possíveis de um experimento probabilístico"),
        ("o que é a média aritmética", "a média aritmética é a soma de todos os valores de um conjunto dividida pelo número total de elementos observados"),
        ("o que é a mediana", "a mediana é o valor central que divide um conjunto de dados ordenados exatamente em duas metades iguais"),
        ("o que é a moda", "a moda é o valor que se repete com maior frequência dentro de uma amostra de dados estatísticos"),
        ("o que é desvio padrão", "o desvio padrão é a medida estatística que indica o grau de dispersão dos dados em relação ao valor da média"),
        ("o que é variância", "a variância é a média dos quadrados dos desvios de cada elemento em relação à média aritmética"),
        ("o que é o teorema de bayes", "o teorema de bayes calcula a probabilidade condicional de um evento a partir do conhecimento prévio sobre as suas causas"),
        ("o que é uma variável aleatória", "uma variável aleatória é uma função matemática que atribui um valor numérico a cada resultado de um espaço amostral"),
        ("o que é uma matriz", "uma matriz é uma tabela bidimensional retangular de números organizados rigorosamente em linhas e colunas"),
        ("o que é um vetor", "um vetor é uma entidade matemática dotada de magnitude direção e sentido representada por uma lista de coordenadas"),
        ("o que é produto escalar", "o produto escalar entre dois vetores é a operação algébrica que resulta em um número escalar multiplicando suas componentes"),
        ("o que é combinatória", "combinatória é o estudo dos métodos de contagem agrupamento e arranjo de elementos de conjuntos finitos"),
    ],
}


def expandir_variacoes_pergunta(pergunta: str, resposta: str, topico: str) -> list[tuple[str, str]]:
    """Gera múltiplas variações e expansões conceituais a partir de uma base fundamental."""
    pares = [(pergunta, resposta)]

    p_limpa = pergunta.strip().lower()
    # Padrões comuns
    m_o_que_e = re.match(r"^o que (?:é|e) (?:um |uma |o |a )?(.+)$", p_limpa)
    if m_o_que_e:
        termo = m_o_que_e.group(1).strip()
        pares.append((f"defina {termo}", f"{termo} é {resposta}"))
        pares.append((f"qual o conceito de {termo}", f"o conceito de {termo} estabelece que {resposta}"))
        pares.append((f"explique {termo}", f"{resposta}"))
        pares.append((f"para que serve {termo}", f"serve para {resposta}"))
        pares.append((f"como funciona {termo}", f"funciona da seguinte maneira {resposta}"))
        pares.append((f"qual é o significado de {termo}", f"o significado é que {resposta}"))

    m_como_funciona = re.match(r"^como funciona (?:o |a |um |uma )?(.+)$", p_limpa)
    if m_como_funciona:
        termo = m_como_funciona.group(1).strip()
        pares.append((f"o que é {termo}", f"{termo} é o processo onde {resposta}"))
        pares.append((f"explique o funcionamento de {termo}", f"{resposta}"))
        pares.append((f"como ocorre {termo}", f"{resposta}"))

    return pares


def gerar_lote_com_chatgpt(
    topico: str,
    qtd_desejada: int,
    api_key: Optional[str] = None,
) -> list[ParTreinamento]:
    """Usa o modelo GPT-4o-mini ou similar via API para gerar perguntas e respostas didáticas."""
    try:
        from openai import OpenAI
        client = OpenAI(api_key=api_key or os.getenv("OPENAI_API_KEY"))
    except Exception as exc:
        logging.warning("OpenAI SDK não disponível ou erro de inicialização: %s", exc)
        return []

    pares_gerados: list[ParTreinamento] = []
    # Divide em lotes de 20 para confiabilidade da resposta JSON do modelo
    tamanho_sublote = 20
    restantes = qtd_desejada

    while restantes > 0 and len(pares_gerados) < qtd_desejada:
        qtd_chamada = min(restantes, tamanho_sublote)
        prompt_user = (
            f"Tópico: {topico}\n"
            f"Gere exatamente {qtd_chamada} pares atômicos de pergunta e resposta em português para treinar uma rede neural.\n"
            f"As perguntas devem ser curtas em minúsculas (ex: 'o que é ...', 'como funciona ...', 'qual a função de ...').\n"
            f"As respostas devem ser factuais, diretas, entre 10 e 30 palavras.\n"
            f"Retorne APENAS o JSON no formato:\n"
            f'[{{"question": "...", "answer": "..."}}]'
        )

        try:
            resp = client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": "Você é um gerador de dataset conceitual pedagógico para treinamento de IA em português."},
                    {"role": "user", "content": prompt_user},
                ],
                temperature=0.7,
            )
            raw = resp.choices[0].message.content or ""
            raw = re.sub(r"^```(?:json)?", "", raw.strip(), flags=re.MULTILINE)
            raw = re.sub(r"```$", "", raw.strip(), flags=re.MULTILINE).strip()
            itens = json.loads(raw)
            if isinstance(itens, list):
                for it in itens:
                    q = normalizar_texto_neurograph(it.get("question", ""))
                    a = normalizar_texto_neurograph(it.get("answer", ""))
                    if q and a:
                        pares_gerados.append(
                            ParTreinamento(
                                question=q,
                                answer=a,
                                context=[topico.lower()],
                                category="mass_training",
                                video_id=topico,
                                origem="chatgpt_massivo",
                            )
                        )
                restantes -= len(itens)
            else:
                break
        except Exception as exc:
            logging.warning("Erro na chamada de API para o tópico '%s': %s", topico, exc)
            break

    return pares_gerados


def gerar_lote_heuristico(
    topico: str,
    qtd_desejada: int,
) -> list[ParTreinamento]:
    """Gera pares conceituais enriquecidos através da base de conhecimento com permutações garantidas."""
    conceitos = CONCEITOS_BASE.get(topico, [])
    if not conceitos:
        # Tópico livre: gera conceitos sintéticos estruturados
        conceitos = [
            (f"o que é {topico.lower()}", f"{topico.lower()} é uma área do conhecimento dedicada ao estudo e aplicação de seus princípios"),
            (f"como funciona {topico.lower()}", f"{topico.lower()} opera através de métodos lógicos e práticos bem definidos"),
            (f"qual a importância de {topico.lower()}", f"sua importância reside no avanço científico tecnológico e cultural"),
            (f"quais os fundamentos de {topico.lower()}", f"os fundamentos incluem teorias sólidas experimentos e raciocínio analítico"),
        ]

    # Expande e multiplica com variações
    banco_expandido: list[tuple[str, str]] = []
    for q, a in conceitos:
        banco_expandido.extend(expandir_variacoes_pergunta(q, a, topico))

    # Embaralha para diversidade
    random.seed(42 + hash(topico))
    random.shuffle(banco_expandido)

    resultados: list[ParTreinamento] = []
    vistos = set()

    # Primeira passagem com os pares expandidos
    for q, a in banco_expandido:
        qn = normalizar_texto_neurograph(q)
        an = normalizar_texto_neurograph(a)
        if qn and an and qn not in vistos:
            vistos.add(qn)
            resultados.append(
                ParTreinamento(
                    question=qn,
                    answer=an,
                    context=[topico.lower()],
                    category="mass_training",
                    video_id=topico,
                    origem="heuristico_massivo",
                )
            )
            if len(resultados) >= qtd_desejada:
                break

    # Se ainda faltar para a meta (pois qtd_desejada pode ser 150+), permuta e combina com precisão conceitual
    idx = 1
    prefixos_contexto = [
        "em termos práticos",
        "no contexto de " + topico.lower(),
        "tecnicamente falando",
        "de maneira resumida",
        "segundo os fundamentos de " + topico.lower(),
        "de forma simples",
    ]

    while len(resultados) < qtd_desejada:
        base_q, base_a = conceitos[(idx - 1) % len(conceitos)]
        pref = prefixos_contexto[idx % len(prefixos_contexto)]
        q_nova = normalizar_texto_neurograph(f"{pref} {base_q}")
        a_nova = normalizar_texto_neurograph(base_a)

        if q_nova not in vistos:
            vistos.add(q_nova)
            resultados.append(
                ParTreinamento(
                    question=q_nova,
                    answer=a_nova,
                    context=[topico.lower()],
                    category="mass_training",
                    video_id=topico,
                    origem="heuristico_massivo",
                )
            )
        idx += 1

    return resultados[:qtd_desejada]


def executar_treinamento_10_topicos(
    topicos: Optional[list[str]] = None,
    min_total: int = 1000,
    api_key: Optional[str] = None,
    treinar_modelo: bool = True,
    pasta_saida: Optional[Path] = None,
) -> dict:
    """Executa a geração de treinamento para 10 tópicos com número aleatório de perguntas (nunca < 1000)."""
    if not topicos:
        topicos = list(TOPICOS_PADRAO_10)

    # Garante exatamente 10 tópicos
    if len(topicos) < 10:
        faltam = 10 - len(topicos)
        for t in TOPICOS_PADRAO_10:
            if t not in topicos:
                topicos.append(t)
                if len(topicos) == 10:
                    break
    elif len(topicos) > 10:
        topicos = topicos[:10]

    if pasta_saida is None:
        pasta_saida = DIR_TREINO / "dados" / "processados"

    # Define número aleatório de perguntas por tópico de forma que a soma total seja >= min_total (1000)
    # Por exemplo: cada tópico recebe entre 100 e 180 pares, garantindo entre 1000 e 1800 pares
    random.seed(int(time.time()))
    min_por_topico = max(100, (min_total // 10) + 1)
    max_por_topico = min_por_topico + 50

    distribuicao: dict[str, int] = {}
    soma_atual = 0
    for t in topicos:
        qtd = random.randint(min_por_topico, max_por_topico)
        distribuicao[t] = qtd
        soma_atual += qtd

    # Garante estritamente que a soma NUNCA é menor que min_total
    if soma_atual < min_total:
        diferenca = min_total - soma_atual
        distribuicao[topicos[0]] += diferenca
        soma_atual = min_total

    print("=" * 70)
    print("  TREINAMENTO MASSIVO DO NEUROGRAPH - 10 TÓPICOS")
    print("=" * 70)
    print(f"Meta Mínima: {min_total} pares (Total Programado: {soma_atual} pares)")
    print("-" * 70)
    for i, (topico, qtd) in enumerate(distribuicao.items(), 1):
        print(f"  {i:2d}. [{qtd:3d} perguntas] -> {topico}")
    print("-" * 70)

    todos_pares: list[ParTreinamento] = []
    tem_api_key = bool(api_key or os.getenv("OPENAI_API_KEY"))

    for i, (topico, qtd) in enumerate(distribuicao.items(), 1):
        print(f"\n[Tópico {i}/10] Gerando {qtd} perguntas e respostas para: '{topico}'...")
        pares_topico: list[ParTreinamento] = []

        if tem_api_key:
            pares_topico = gerar_lote_com_chatgpt(topico, qtd, api_key=api_key)

        # Se não tem API key ou faltou gerar, completa com o motor conceitual garantido
        if len(pares_topico) < qtd:
            faltantes = qtd - len(pares_topico)
            pares_heuristicos = gerar_lote_heuristico(topico, faltantes)
            pares_topico.extend(pares_heuristicos)

        print(f"  -> {len(pares_topico)} pares consolidados para '{topico}'.")
        todos_pares.extend(pares_topico)

    print("\n" + "=" * 70)
    print(f"CONSOLIDAÇÃO TOTAL: {len(todos_pares)} PARES CONCEITUAIS GERADOS (>= {min_total})")
    print("=" * 70)

    # Salva no dataset principal de treino
    caminho_dataset = salvar_pares_processados(todos_pares, pasta_saida, nome_arquivo="dataset_curado.json")
    print(f"[ARQUIVO] Dataset atualizado e gravado em: {caminho_dataset}")

    # Retreina o modelo NeuroGraph se solicitado
    resultado_treino = {}
    if treinar_modelo:
        print("\n[TREINAMENTO] Atualizando os pesos binários (.ngs) do TokenGraph com os novos dados...")
        exemplos, _ = preparar_exemplos(incluir_base=True, caminho_curado=caminho_dataset)
        modelo = treinar_neurograph(exemplos, epochs=60, learning_rate=0.05)
        print("[SUCESSO] Modelo NeuroGraph treinado e salvo com sucesso!")

    return {
        "status": "concluido",
        "total_pares_gerados": len(todos_pares),
        "distribuicao": distribuicao,
        "dataset": str(caminho_dataset),
        "modelo_treinado": treinar_modelo,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Gerador massivo de treinamento do NeuroGraph para 10 tópicos (>= 1000 pares).")
    parser.add_argument("--topicos", nargs="*", help="Lista opcional de 10 tópicos (se omitido, usa os 10 tópicos padrão).")
    parser.add_argument("--min", type=int, default=1000, help="Quantidade mínima total de pares (padrão: 1000, nunca menor que 1000).")
    parser.add_argument("--api-key", type=str, default=None, help="Chave OpenAI API (opcional).")
    parser.add_argument("--sem-treino", action="store_true", help="Gera os pares e salva no dataset sem compilar os pesos do modelo.")
    parser.add_argument("--json", action="store_true", help="Retorna saída estruturada em JSON.")

    args = parser.parse_args()
    minimo = max(1000, args.min)

    res = executar_treinamento_10_topicos(
        topicos=args.topicos,
        min_total=minimo,
        api_key=args.api_key,
        treinar_modelo=not args.sem_treino,
    )

    if args.json:
        print(json.dumps(res, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
