"""Diagnostic threshold sweep for the structured NeuroGraph relational prototype.

Run: python3 NeuroGraph/tests/relational_threshold_sweep_20261113.py
No natural-language claims: queries are structured (subject, relation) pairs.
This test does not tune on the reserved subjects.
"""
from relational_holdout_20261113 import FACTS, train, answer
import json

holdout = FACTS[::4]
training = [fact for fact in FACTS if fact not in holdout]
graph = train(training)
relations = sorted({r for _, r, _ in training})
swapped = [(s, other) for s, r, _ in training
           for other in relations if other != r]
thresholds = [0.4, 0.5, 0.7, 0.8, 0.81, 0.82]
results = []
for threshold in thresholds:
    results.append({
        "threshold": threshold,
        "trained_correct": sum(answer(graph, s, r, threshold=threshold) == o
                               for s, r, o in training),
        "trained_total": len(training),
        "heldout_correct": sum(answer(graph, s, r, threshold=threshold) == o
                               for s, r, o in holdout),
        "heldout_total": len(holdout),
        "swapped_relation_abstentions": sum(
            answer(graph, s, r, threshold=threshold) is None for s, r in swapped),
        "swapped_relation_total": len(swapped),
    })
print(json.dumps({"evaluation": "structured_only", "results": results},
                 ensure_ascii=False, indent=2))
