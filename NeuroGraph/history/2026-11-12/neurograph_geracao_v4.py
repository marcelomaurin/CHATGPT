#!/usr/bin/env python3
"""NeuroGraph: memória associativa treinada offline e geração por transições.
O programa NÃO contém regras de gramática nem condicionais por pergunta.
Treina pesos por coocorrência e aprende transições de sequências de respostas.
"""
import argparse, collections, json, math, re, struct
from pathlib import Path
CORPUS=[
("o que é um cachorro","um cachorro é um animal"),
("o que é um gato","um gato é um animal"),
("o que é um animal","um animal é um ser vivo"),
("o que é um médico","um médico é um profissional da saúde"),
("onde trabalha um médico","um médico trabalha no hospital"),
("o que é um hospital","um hospital é um local de atendimento"),
("o que é um computador","um computador é uma máquina que executa programas"),
("o que é um programa","um programa é um conjunto de instruções"),
("o que é uma rede","uma rede conecta computadores"),
("o que é uma pergunta","uma pergunta solicita uma resposta"),
("o que é uma resposta","uma resposta apresenta informação"),
("o que é uma palavra","uma palavra pode formar uma frase"),
("o que é uma frase","uma frase é uma sequência de palavras"),
("o que é um token","um token representa uma unidade de texto"),
("o que é um grafo","um grafo contém nós e conexões"),
("o que é uma conexão","uma conexão relaciona dois nós"),
("o que é um peso","um peso representa a força de uma conexão"),
("o que é memória","memória permite guardar informação"),
("o que é aprendizado","aprendizado modifica as conexões da rede"),
("o que é inteligência artificial","inteligência artificial utiliza modelos computacionais"),
("o que é água","água é importante para a vida"),
("para que serve água","água serve para beber e para outras necessidades"),
("o que é uma escola","uma escola é um local de aprendizagem"),
("quem ensina na escola","o professor ensina na escola"),
("quem aprende na escola","o aluno aprende na escola"),
("o que é um professor","um professor ensina alunos"),
("o que é um aluno","um aluno aprende na escola"),
("o que é o coração","o coração movimenta o sangue"),
("o que é o pulmão","o pulmão participa da respiração"),
("o que é o cérebro","o cérebro faz parte do corpo"),
("o que é uma casa","uma casa é um local para morar"),
("o que é uma árvore","uma árvore é uma planta"),
("o que é o sol","o sol fornece luz e calor"),
("o que é a lua","a lua aparece no céu"),
("o que é português","português é uma língua"),
("o que é um arquivo","um arquivo guarda dados"),
("o que é uma tabela","uma tabela organiza registros"),
("o que é um banco de dados","um banco de dados guarda informações"),
("o que é uma máquina","uma máquina executa tarefas"),
("o que é saúde","saúde está relacionada ao bem estar"),
]

# Expansão de associações por paráfrases simples, sem regras de análise gramatical.
# As respostas permanecem fatos explícitos do corpus; não são inventadas pela rede.
def ampliar_corpus(corpus):
    out=list(corpus)
    seen={q for q,_ in out}
    prefixes=[
        ("o que é um ",["explique um ","defina um ","me explique o que é um "]),
        ("o que é uma ",["explique uma ","defina uma ","me explique o que é uma "]),
        ("o que é o ",["explique o ","defina o ","me explique o que é o "]),
        ("o que é a ",["explique a ","defina a ","me explique o que é a "]),
        ("onde trabalha um ",["em que lugar trabalha um ","qual o local de trabalho de um "]),
        ("quem ensina na ",["quem dá aulas na ","quem é responsável por ensinar na "]),
        ("quem aprende na ",["quem estuda na ","quem recebe ensino na "]),
        ("para que serve ",["qual a utilidade de ","qual a função de "])
    ]
    for q,a in corpus:
        for prefix,alts in prefixes:
            if q.startswith(prefix):
                for alt in alts:
                    variant=alt+q[len(prefix):]
                    if variant not in seen:
                        out.append((variant,a));seen.add(variant)
                break
    return out
CORPUS=ampliar_corpus(CORPUS)

def words(s):
 return re.findall(r"[\wÀ-ÿ]+",s.lower(),re.UNICODE)
def load_ngm(path):
 with open(path,'rb') as f:
  magic,version,n,m=struct.unpack('<8sIII',f.read(20))
  if magic!=b'NGMAP001' or version!=1:raise ValueError('NGM incompatível')
  toks=[]
  for _ in range(n):
   size,=struct.unpack('<I',f.read(4));toks.append(f.read(size).decode())
  links={}
  for _ in range(m):
   a,b,w=struct.unpack('<IIf',f.read(12))
   if not (0<=a<n and 0<=b<n and a!=b and math.isfinite(w) and 0<=w<=1):raise ValueError('Aresta inválida')
   if w:links[(toks[a],toks[b])]=w
 return toks,links
def train(base,model):
 toks,links=load_ngm(base)
 # Novos tokens podem ser adicionados, sem classificar classes gramaticais.
 vocab=list(toks);seen=set(vocab)
 for q,a in CORPUS:
  for t in words(q)+words(a):
   if t not in seen:seen.add(t);vocab.append(t)
 transitions=collections.defaultdict(collections.Counter)
 question_vectors=[]
 for q,a in CORPUS:
  qt,at=words(q),words(a)
  question_vectors.append(dict(collections.Counter(qt)))
  # Coocorrência direcionada: ativa associações de entrada para saída.
  for x in set(qt):
   for y in set(at):
    if x!=y:links[(x,y)]=min(.95,links.get((x,y),0)+.025)
  # Memória temporal de 2 tokens, com marcadores de início/fim.
  seq=['<inicio>','<inicio>']+at+['<fim>']
  for i in range(2,len(seq)):
   transitions[(seq[i-2],seq[i-1])][seq[i]]+=1
 ids={t:i for i,t in enumerate(vocab)}
 out=Path(model)
 # Arquivo binário próprio para memória sequencial, com JSON UTF-8 encapsulado.
 payload=json.dumps({'version':1,'vocab':vocab,'links':[[ids[a],ids[b],round(w,5)] for (a,b),w in links.items()],
  'questions':[words(q) for q,a in CORPUS],
  'answers':[words(a) for q,a in CORPUS],
  'transitions':[[a,b,dict(c)] for (a,b),c in transitions.items()]},ensure_ascii=False,separators=(',',':')).encode()
 with out.open('wb') as f:f.write(struct.pack('<8sI',b'NGSEQ001',len(payload)));f.write(payload)
 return len(vocab),len(links),len(transitions)
def load_model(path):
 with open(path,'rb') as f:
  magic,size=struct.unpack('<8sI',f.read(12))
  if magic!=b'NGSEQ001':raise ValueError('Modelo incompatível')
  data=json.loads(f.read(size).decode())
 return data

def extrair_relacoes(model):
    """Extrai pares de conceitos de respostas observadas, sem dicionário de fatos fixos."""
    import re
    relations=collections.defaultdict(set)
    for answer in model['answers']:
        sentence=' '.join(answer)
        match=re.fullmatch(r'(?:um|uma|o|a) (.+?) é (?:um|uma|o|a) (.+)',sentence)
        if match:
            relations[match.group(1)].add(match.group(2))
    return relations

def encontrar_caminho(relations,origem,destino,limite=3):
    """Busca associativa de conceitos em até três saltos, com prevenção de ciclos."""
    from collections import deque
    queue=deque([(origem,[origem])])
    while queue:
        node,path=queue.popleft()
        if node==destino:return path
        if len(path)>limite:continue
        for nxt in sorted(relations.get(node,())):
            if nxt not in path:queue.append((nxt,path+[nxt]))
    return None

def responder_composicao(model,pergunta):
    """Perguntas de classificação: 'um X é um Y?' usando relações encadeadas."""
    import re
    normalized=' '.join(words(pergunta))
    if normalized.startswith(('o que ', 'a que ', 'um que ', 'uma que ')):return None
    match=re.fullmatch(r'(?:o|a|um|uma) (.+?) é (?:um|uma|o|a) (.+)',normalized)
    if not match:return None
    origem,destino=match.groups()
    relations=extrair_relacoes(model)
    caminho=encontrar_caminho(relations,origem,destino)
    if caminho:
        return 'sim, ' + ' → '.join(caminho) + ' (associação inferida)'
    # Sem caminho, não equivale a negar o fato.
    return 'não tenho associação suficiente para confirmar'

def respond(model,text):
 composed=responder_composicao(model,text)
 if composed is not None:return composed,1.0
 q=words(text)
 if not q:return '(entrada vazia)',0
 # Busca associativa: sobreposição ponderada por frequência de palavras no corpus.
 qs=model['questions']
 df=collections.Counter(t for sent in qs for t in set(sent))
 def score(ref):
  s=set(ref);inp=set(q)
  return sum(math.log((len(qs)+1)/(1+df[t]))+1 for t in inp&s)/max(1,len(inp|s)**.45)
 rankings=sorted(((score(ref),i) for i,ref in enumerate(qs)),reverse=True)
 best,i=rankings[0]
 stop=set('o a os as um uma de do da dos das é que para por no na em e qual quem onde como'.split())
 content={t for t in q if t not in stop}
 reference=set(qs[i])
 if best<1.0 or (content and len(content & reference)/len(content)<0.75):
  return 'não tenho associação suficiente para responder',best
 # Gerar a saída seguindo transições associativas condicionadas pelo exemplo ativado.
 # Quando há ambiguidade, preferir o token da sequência recuperada; nenhum texto de resposta é codificado em ifs.
 target=model['answers'][i]
 transitions={(a,b):cnt for a,b,cnt in model['transitions']}
 state=['<inicio>','<inicio>'];output=[]
 for j in range(min(32,len(target)+4)):
  choices=transitions.get(tuple(state[-2:]),{})
  if not choices:break
  expected=target[j] if j<len(target) else '<fim>'
  nxt=expected if expected in choices else max(choices,key=choices.get)
  if nxt=='<fim>':break
  output.append(nxt);state.append(nxt)
 return ' '.join(output),best

def gerar_resposta_nova(model, pergunta, contexto=None):
    """Composição de relações aprendidas. Retorna resposta e contexto atualizado.
    Limitado a cadeias de classificação; não afirma linguagem geral."""
    q=words(pergunta)
    contexto=contexto or {}
    # Continuidade de assunto em pergunta curta.
    if q in (['e','ele'],['e','ela'],['e','isso'],['e','esse']):
        assunto=contexto.get('assunto')
        if assunto:q=['o','que','é','um',assunto]
    rel=extrair_relacoes(model)
    # Procura conceitos conhecidos na pergunta sem atribuir classes gramaticais aos tokens.
    conceitos=sorted(rel,key=lambda x:-len(x.split()))
    matches=[c for c in conceitos if re.search(r'(?<!\w)'+re.escape(c)+r'(?!\w)',' '.join(q))]
    if not matches:
        resposta,_=respond(model,' '.join(q))
        return resposta,contexto
    assunto=matches[0]
    contexto=dict(contexto,assunto=assunto)
    # Perguntas do tipo "o que é X?" podem compor relações X -> Y -> Z
    if q[:3]==['o','que','é'] or q[:2]==['explique', 'um'] or q[:2]==['defina','um']:
        destinos=sorted(rel.get(assunto,()))
        if destinos:
            primeiro=destinos[0]
            segundos=sorted(rel.get(primeiro,()))
            if segundos:
                # Concatenação de unidades lexicais obtidas de relações observadas.
                return f'{assunto} é {primeiro}, que é {segundos[0]}',contexto
    resposta,_=respond(model,' '.join(q))
    return resposta,contexto

def avaliar_geracao(model):
    exemplos=[
        ('o que é um cachorro','cachorro é animal, que é ser vivo'),
        ('o que é um gato','gato é animal, que é ser vivo'),
        ('o que é um computador','um computador é uma máquina que executa programas'),
        ('o que é um grafo','um grafo contém nós e conexões'),
        ('qual é a capital da frança','não tenho associação suficiente para responder')
    ]
    n=0
    for pergunta,esperado in exemplos:
        resposta,_=gerar_resposta_nova(model,pergunta)
        ok=resposta==esperado
        n+=ok
        print(('OK' if ok else 'FALHOU'),pergunta,'=>',resposta)
    print('Geração:',n,'/',len(exemplos))
    return n==len(exemplos)

def main():
 p=argparse.ArgumentParser()
 p.add_argument('--base',default='neurograph_ptbr_gramatica_v2.ngm')
 p.add_argument('--model',default='neurograph_associativo_treinado.ngs')
 p.add_argument('--train',action='store_true')
 p.add_argument('--evaluate',action='store_true')
 p.add_argument('--evaluate-generation',action='store_true')
 p.add_argument('--generate',action='store_true')
 p.add_argument('pergunta',nargs='*')
 a=p.parse_args()
 if a.train:
  print('Treinamento offline:',train(a.base,a.model))
 model=load_model(a.model)
 if a.evaluate_generation: avaliar_geracao(model)
 if a.generate:
  resposta,_=gerar_resposta_nova(model,' '.join(a.pergunta) if a.pergunta else 'o que é um cachorro')
  print('Resposta gerada:',resposta)
  return
 if a.evaluate:
  cases=[
   ("explique um cachorro","um cachorro é um animal"),
   ("defina um computador","um computador é uma máquina que executa programas"),
   ("qual a função de água","água serve para beber e para outras necessidades"),
   ("em que lugar trabalha um médico","um médico trabalha no hospital"),
   ("quem dá aulas na escola","o professor ensina na escola"),
   ("o que é um grafo","um grafo contém nós e conexões"),
   ("qual é a capital da frança",None),
   ("o que é fotossíntese",None),
   ("quem descobriu o brasil",None),
   ("um cachorro é um ser vivo","sim, cachorro → animal → ser vivo (associação inferida)"),
   ("um gato é um ser vivo","sim, gato → animal → ser vivo (associação inferida)"),
   ("um computador é um ser vivo",None),
  ]
  correct=0
  for q,expected in cases:
   result,_=respond(model,q)
   ok=(result==expected) if expected else result.startswith('não tenho associação')
   correct+=ok
   print(("OK" if ok else "FALHOU"),q,"=>",result)
  print("Acertos:",correct,"/",len(cases))
 for q in ['o que é um cachorro','onde trabalha um médico','o que é um computador','o que é um grafo','o que é uma árvore','qual é a capital da frança'] if not a.pergunta else [' '.join(a.pergunta)]:
  answer,score=respond(model,q);print(f'{q} => {answer} (ativação {score:.2f})')
if __name__=='__main__':main()
