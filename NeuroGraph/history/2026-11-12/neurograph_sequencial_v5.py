#!/usr/bin/env python3
"""NeuroGraph v5: gerador associativo sequencial, sem modelos de frases fixas.
Treina pesos de ativacao pergunta->memoria e transicoes de tokens de resposta.
Modelo experimental; corpus pequeno, nao e um LLM.
"""
import argparse,collections,importlib.util,json,math,re,struct
from pathlib import Path

def tokenize(s): return re.findall(r'[^\W_]+',s.lower(),flags=re.UNICODE)
def train(pairs):
    docs=[]; df=collections.Counter()
    for q,a in pairs:
        qt=tokenize(q);at=tokenize(a)
        docs.append((qt,at));df.update(set(qt))
    # TF-IDF-like learned association: token -> training contexts
    n=len(docs)
    weights={t:math.log(1+(n+1)/(count+1)) for t,count in df.items()}
    return {'docs':docs,'idf':weights,'version':5}
def context_scores(model,query):
    qt=set(tokenize(query));scores=[]
    for q,a in model['docs']:
        shared=qt.intersection(q)
        val=sum(model['idf'][t] for t in shared)
        val/=max(1.0,(len(qt)*len(set(q)))**.35)
        scores.append(val)
    return scores

def generate(model,question,max_tokens=32,temperature=0.6):
    scores=context_scores(model,question)
    if not scores:return 'não tenho associações suficientes',0
    best=max(scores)
    if best<.65:return 'não tenho associações suficientes',best
    ranked=sorted(range(len(scores)),key=lambda i:scores[i],reverse=True)
    # Sparse context activation, only strongly related memories can contribute.
    active=[i for i in ranked if scores[i]>=best*.82 and scores[i]>=.65][:12]
    # If an unfamiliar content token has no support, abstain rather than hallucinate.
    common=set('o a os as um uma de do da dos das é que para por no na em e qual quem onde como me explique defina'.split())
    query_content={t for t in tokenize(question) if t not in common}
    support=set(t for i in active for t in model['docs'][i][0])
    if query_content and len(query_content & support)/len(query_content)<.8:
        return 'não tenho associações suficientes',best
    # Conditional distribution P(next token | previous two tokens, active memories).
    transitions=collections.defaultdict(lambda:collections.Counter())
    for i in active:
        seq=['<s>','<s>']+model['docs'][i][1]+['</s>']
        strength=math.exp((scores[i]-best)/max(.05,temperature))
        for j in range(2,len(seq)):
            transitions[(seq[j-2],seq[j-1])][seq[j]]+=strength
    state=['<s>','<s>'];output=[]
    for _ in range(max_tokens):
        options=transitions.get(tuple(state[-2:]))
        if not options:break
        # Deterministic max activation; context weights break ties.
        next_token=max(sorted(options),key=lambda t:options[t])
        if next_token=='</s>':break
        output.append(next_token);state.append(next_token)
    return ' '.join(output),best

def save(model,path):
    raw=json.dumps(model,ensure_ascii=False,separators=(',',':')).encode('utf8')
    Path(path).write_bytes(struct.pack('<8sI',b'NGSEQ005',len(raw))+raw)
def load(path):
    with open(path,'rb') as f:
        magic,size=struct.unpack('<8sI',f.read(12))
        if magic!=b'NGSEQ005':raise ValueError('Arquivo NGSEQ005 esperado')
        raw=f.read(size)
        if len(raw)!=size:raise ValueError('Arquivo truncado')
    return json.loads(raw)

def evaluate(model):
    tests=[('explique um cachorro','um cachorro é um animal'),
           ('defina um computador','um computador é uma máquina que executa programas'),
           ('em que lugar trabalha um médico','um médico trabalha no hospital'),
           ('o que é um grafo','um grafo contém nós e conexões'),
           ('qual é a capital da frança',None),
           ('o que é fotossíntese',None)]
    passed=0
    for q,expected in tests:
        ans,_=generate(model,q)
        ok=(ans==expected if expected else ans.startswith('não tenho'))
        passed+=ok
        print(('OK' if ok else 'FALHOU'),q,'=>',ans)
    print(f'Resultado: {passed}/{len(tests)}')

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--train',action='store_true');ap.add_argument('--test',action='store_true');ap.add_argument('--model',default='neurograph_sequencial_v5.ngs');ap.add_argument('question',nargs='*');a=ap.parse_args()
    if a.train:
        # Corpus from prior version, imported without running its CLI.
        source=Path(__file__).with_name('neurograph_associativo_calibrado_v2.py')
        spec=importlib.util.spec_from_file_location('ngcorpus',source)
        module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
        model=train(module.CORPUS);save(model,a.model)
        print(f'Treinado: {len(model["docs"])} pares, {len(model["idf"])} tokens de entrada')
    model=load(a.model)
    if a.test:evaluate(model)
    if a.question:print(generate(model,' '.join(a.question))[0])
if __name__=='__main__':main()
