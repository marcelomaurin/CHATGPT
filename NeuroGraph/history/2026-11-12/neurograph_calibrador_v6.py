#!/usr/bin/env python3
"""Calibrador NeuroGraph: busca de hiperparâmetros em perguntas separadas."""
import importlib.util, itertools, json, math
from pathlib import Path
ROOT=Path(__file__).parent
def import_file(name,path):
 spec=importlib.util.spec_from_file_location(name,path);mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);return mod
ng=import_file('ng5',ROOT/'neurograph_sequencial_v5.py')
corpus=import_file('corpus',ROOT/'neurograph_associativo_calibrado_v2.py')
# Usa somente os 40 exemplos originais no treinamento. Paráfrases ficam reservadas para validação.
train_pairs=corpus.CORPUS[:40]
heldout=corpus.CORPUS[40:]
model=ng.train(train_pairs)
common=set('o a os as um uma de do da dos das é que para por no na em e qual quem onde como me explique defina'.split())
def generate(question,ratio,threshold,temperature,coverage):
 scores=ng.context_scores(model,question)
 if not scores:return 'não tenho associações suficientes'
 best=max(scores)
 if best<threshold:return 'não tenho associações suficientes'
 ranked=sorted(range(len(scores)),key=lambda i:scores[i],reverse=True)
 active=[i for i in ranked if scores[i]>=best*ratio and scores[i]>=threshold][:12]
 query_content={t for t in ng.tokenize(question) if t not in common}
 support=set(t for i in active for t in model['docs'][i][0])
 if query_content and len(query_content & support)/len(query_content)<coverage:
  return 'não tenho associações suficientes'
 from collections import defaultdict,Counter
 transitions=defaultdict(Counter)
 for i in active:
  seq=['<s>','<s>']+model['docs'][i][1]+['</s>']
  strength=math.exp((scores[i]-best)/max(.05,temperature))
  for j in range(2,len(seq)):transitions[(seq[j-2],seq[j-1])][seq[j]]+=strength
 state=['<s>','<s>'];output=[]
 for _ in range(32):
  opts=transitions.get(tuple(state[-2:]))
  if not opts:break
  token=max(sorted(opts),key=lambda t:opts[t])
  if token=='</s>':break
  output.append(token);state.append(token)
 return ' '.join(output)
unknown=[
 'qual é a capital da frança','o que é fotossíntese','quem descobriu o brasil',
 'qual é a velocidade da luz','como funciona a internet quântica',
 'quem foi machado de assis','qual a população de são paulo',
 'o que é relatividade','quando começou a segunda guerra mundial',
 'o que é um neutrino'
]
# Modelo original como linha de base, mesmos dados de treino.
def metric(fn):
 known=sum(fn(q)== ' '.join(ng.tokenize(a)) for q,a in heldout)
 unknown_ok=sum(fn(q).startswith('não tenho') for q in unknown)
 return known,unknown_ok,known+unknown_ok
base=metric(lambda q:ng.generate(model,q)[0])
best=None
for ratio,threshold,temp,coverage in itertools.product([.72,.82,.92,.99],[.45,.65,.9,1.2],[.25,.6,1.0],[.6,.8,1.0]):
 params=(ratio,threshold,temp,coverage)
 score=metric(lambda q:generate(q,*params))
 candidate=(score[2],score[0],score[1],params)
 if best is None or candidate>best:best=candidate
score=(best[1],best[2],best[0])
report={'train_examples':len(train_pairs),'heldout_paraphrases':len(heldout),'unknown_questions':len(unknown),
 'baseline':{'correct_paraphrases':base[0],'correct_abstentions':base[1],'total':base[2]},
 'calibrated':{'correct_paraphrases':score[0],'correct_abstentions':score[1],'total':score[2]},
 'parameters':dict(zip(['active_ratio','activation_threshold','temperature','min_content_coverage'],best[3])),
 'warning':'Parâmetros escolhidos sobre a validação; resultados não são teste independente.'}
(ROOT/'neurograph_calibracao_v6.json').write_text(json.dumps(report,ensure_ascii=False,indent=2))
print(json.dumps(report,ensure_ascii=False,indent=2))
