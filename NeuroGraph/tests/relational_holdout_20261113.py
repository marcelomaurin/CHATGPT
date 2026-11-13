"""NeuroGraph relational propagation benchmark; research baseline, not Lazarus runtime."""
from collections import defaultdict
import json

FACTS = [
 ("abelha","produz","mel"),("vaca","produz","leite"),
 ("galinha","produz","ovo"),("padeiro","prepara","pao"),
 ("cozinheiro","prepara","refeicao"),("medico","trabalha","hospital"),
 ("professor","trabalha","escola"),("bibliotecario","trabalha","biblioteca"),
 ("mecanico","trabalha","oficina"),("enfermeiro","trabalha","hospital"),
 ("motorista","conduz","onibus"),("piloto","conduz","aviao"),
 ("maquinista","conduz","trem"),("jardineiro","cuida","jardim"),
 ("veterinario","cuida","animais"),("agricultor","cultiva","milho"),
 ("horticultor","cultiva","alface"),("pintor","utiliza","pincel"),
 ("escritor","utiliza","caneta"),("carpinteiro","utiliza","serrote"),
]

def train(facts):
    graph = defaultdict(dict)
    for subject, relation, obj in facts:
        graph[("subject",subject)][("relation",subject,relation)] = 1.0
        graph[("relation",subject,relation)][("object",obj)] = 1.0
    return graph

def answer(graph, subject, relation, hops=2, threshold=.5):
    frontier = {("subject",subject):1.0}
    for _ in range(hops):
        next_frontier = defaultdict(float)
        for node, score in frontier.items():
            for target, weight in graph.get(node,{}).items():
                if target[0] == "relation" and target[2] != relation:
                    continue
                next_frontier[target] = max(next_frontier[target], score*weight*.9)
        frontier = next_frontier
    candidates = sorted(((score,node[1]) for node,score in frontier.items()
                         if node[0]=="object"),reverse=True)
    if not candidates or candidates[0][0] < threshold:
        return None
    if len(candidates)>1 and candidates[0][0]==candidates[1][0]:
        return None
    return candidates[0][1]

def evaluate():
    # Hold out complete subjects, not just paraphrases of seen answers.
    holdout = FACTS[::4]
    training = [fact for fact in FACTS if fact not in holdout]
    graph = train(training)
    negative = [(s,"inexistente") for s,_,_ in training[:10]]
    results = {}
    for hops in (1,2):
        results[str(hops)+"_hop"] = {
            "known_correct":sum(answer(graph,s,r,hops)==o for s,r,o in training),
            "known_total":len(training),
            "holdout_correct":sum(answer(graph,s,r,hops)==o for s,r,o in holdout),
            "holdout_total":len(holdout),
            "negative_abstentions":sum(answer(graph,s,r,hops) is None for s,r in negative),
            "negative_total":len(negative),
        }
    return results

if __name__=="__main__":
    print(json.dumps(evaluate(),ensure_ascii=False,indent=2))
