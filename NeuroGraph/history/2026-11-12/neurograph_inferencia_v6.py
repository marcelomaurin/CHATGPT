#!/usr/bin/env python3
"""NeuroGraph v6 - geração com parâmetros calibrados, sem treinamento do usuário."""
import argparse,importlib.util,json,math
from pathlib import Path
ROOT=Path(__file__).parent
spec=importlib.util.spec_from_file_location('ng5',ROOT/'neurograph_sequencial_v5.py')
ng=importlib.util.module_from_spec(spec);spec.loader.exec_module(ng)
model=ng.load(ROOT/'neurograph_sequencial_v6.ngs')
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

if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('pergunta',nargs='+');a=p.parse_args()
 params=json.loads((ROOT/'neurograph_calibracao_v6.json').read_text())['parameters']
 print(generate(' '.join(a.pergunta),params['active_ratio'],params['activation_threshold'],params['temperature'],params['min_content_coverage']))
