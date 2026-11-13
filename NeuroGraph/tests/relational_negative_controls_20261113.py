"""Additional negative-control evaluation for relational_holdout_20261113.py.

Run: python3 NeuroGraph/tests/relational_negative_controls_20261113.py
Structured triples only; this is not a natural-language benchmark.
"""
from relational_holdout_20261113 import FACTS, train, answer
import json

holdout = FACTS[::4]
training = [f for f in FACTS if f not in holdout]
graph = train(training)
relations = sorted({r for _, r, _ in training})
swapped = [(s, other) for s, r, _ in training
           for other in relations if other != r][:30]
absent = [(s, "inexistente") for s, _, _ in training[:10]]
results = {
    "trained_correct": sum(answer(graph, s, r) == o for s, r, o in training),
    "trained_total": len(training),
    "heldout_correct": sum(answer(graph, s, r) == o for s, r, o in holdout),
    "heldout_total": len(holdout),
    "swapped_relation_abstentions": sum(answer(graph, s, r) is None for s, r in swapped),
    "swapped_relation_total": len(swapped),
    "absent_relation_abstentions": sum(answer(graph, s, r) is None for s, r in absent),
    "absent_relation_total": len(absent),
}
print(json.dumps(results, ensure_ascii=False, indent=2))
