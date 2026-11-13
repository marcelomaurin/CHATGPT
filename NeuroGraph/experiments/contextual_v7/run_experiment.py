"""Train, select on validation only, freeze, then compare on untouched test rows."""
import argparse
from collections import defaultdict
import hashlib
import importlib.util
import json
import itertools
from pathlib import Path
import platform
try:
    import resource
except ImportError:
    resource = None
import statistics
import time

from model import TokenGraph, Example, tokenize

ROOT = Path(__file__).resolve().parent


def legacy_generator(training, validation):
    path = ROOT / "baseline_v6/neurograph_inferencia_v6.py"
    spec = importlib.util.spec_from_file_location("legacy_v6", path)
    legacy = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(legacy)
    pairs = [(" ".join(e.get("context", []) + [e["question"]]),
              e["answer"] if e["answer"] is not None else "não tenho associações suficientes")
             for e in training]
    legacy.model = legacy.ng.train(pairs)
    params = json.loads((ROOT / "baseline_v6/neurograph_calibracao_v6.json").read_text())["parameters"]
    original_scores = legacy.ng.context_scores
    score_cache = {}
    def cached_scores(model, question):
        if question not in score_cache:
            score_cache[question] = original_scores(model, question)
        return score_cache[question]
    legacy.ng.context_scores = cached_scores
    def generate(example):
        question = " ".join(example.get("context", []) + [example["question"]])
        return legacy.generate(question, params["active_ratio"], params["activation_threshold"],
                               params["temperature"], params["min_content_coverage"])
    # Give the baseline its own validation calibration on the same data.
    # This is the v6 search space plus lower coverage/activation candidates.
    best, best_params = None, None
    for ratio, threshold, temperature, coverage in itertools.product(
            (0.72, 0.82, 0.92, 0.99), (0.0, 0.45, 0.65, 0.9, 1.2),
            (0.25, 0.6, 1.0), (0.0, 0.3, 0.6, 0.8, 1.0)):
        params.update(active_ratio=ratio, activation_threshold=threshold,
                      temperature=temperature, min_content_coverage=coverage)
        correct = wrong = 0
        for row in validation:
            prediction = generate(row)
            refused = prediction.startswith("não tenho associações suficientes")
            ok = refused if row["answer"] is None else tokenize(prediction) == tokenize(row["answer"])
            correct += int(ok)
            wrong += int(not ok and not refused)
        score = (correct, -wrong, coverage, threshold, ratio, temperature)
        if best is None or score > best:
            best, best_params = score, params.copy()
    params.update(best_params)
    return generate, {"parameters": best_params, "validation_correct": best[0],
                      "validation_wrong_answers": -best[1], "candidates": 300}


def evaluate(partition, generate):
    counts = defaultdict(lambda: {"correct": 0, "total": 0, "abstentions": 0, "wrong_answers": 0})
    details, timings = [], []
    for row in partition:
        start = time.perf_counter()
        prediction = generate(row)
        timings.append((time.perf_counter() - start) * 1000)
        refused = prediction.startswith("não tenho associações suficientes")
        correct = refused if row["answer"] is None else tokenize(prediction) == tokenize(row["answer"])
        for key in ("all", row["category"]):
            counts[key]["total"] += 1
            counts[key]["correct"] += int(correct)
            counts[key]["abstentions"] += int(refused)
            counts[key]["wrong_answers"] += int(not correct and not refused)
        details.append({**row, "prediction": prediction, "correct": correct})
    return {"metrics": dict(counts), "latency_ms_median": statistics.median(timings),
            "latency_ms_max": max(timings), "details": details}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--epochs", type=int, default=180)
    args = parser.parse_args()
    dataset_path = ROOT / "data/benchmark.json"
    data_bytes = dataset_path.read_bytes()
    data = json.loads(data_bytes)
    train = [Example(e["question"], e["answer"], tuple(e["context"])) for e in data["train"]]
    model = TokenGraph()
    start = time.perf_counter()
    learning = model.fit(train, epochs=args.epochs)
    elapsed = time.perf_counter() - start
    # Tune only the confidence policy on validation; all token weights are fixed.
    candidates = []
    for threshold in (0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6):
        model.confidence = threshold
        result = evaluate(data["validation"], lambda e: model.generate(
            e["question"], context=tuple(e["context"])).text)
        score = result["metrics"]["all"]
        candidates.append({"threshold": threshold, "correct": score["correct"],
                           "wrong_answers": score["wrong_answers"]})
    chosen = max(candidates, key=lambda c: (c["correct"], -c["wrong_answers"], c["threshold"]))
    model.confidence = chosen["threshold"]
    model_path = ROOT / "results/neurograph_contextual_v7.ngs"
    model.save(model_path)
    frozen_hash = hashlib.sha256(model_path.read_bytes()).hexdigest()
    # Test starts only after the exact model bytes and policy have been frozen.
    restored = TokenGraph.load(model_path)
    baseline, baseline_calibration = legacy_generator(data["train"], data["validation"])
    report = {"dataset_sha256": hashlib.sha256(data_bytes).hexdigest(),
              "model_sha256": frozen_hash,
              "configuration": {"epochs": args.epochs, "learning_rate": 0.05,
                  "regularization": 0.0001, "recurrent_decay": model.decay},
              "split_sizes": {k: len(data[k]) for k in ("train", "validation", "test")},
              "training_seconds": elapsed, "learning": learning,
              "validation_policy_candidates": candidates, "chosen_policy": chosen,
              "baseline_validation_calibration": baseline_calibration,
              "validation_v7": evaluate(data["validation"], lambda e: restored.generate(
                  e["question"], context=tuple(e["context"])).text),
              "test_v6_same_training": evaluate(data["test"], baseline),
              "test_v7": evaluate(data["test"], lambda e: restored.generate(
                  e["question"], context=tuple(e["context"])).text),
              "model_bytes": model_path.stat().st_size,
              "peak_training_rss_kib": resource.getrusage(resource.RUSAGE_SELF).ru_maxrss if resource else None,
              "runtime": {"python": platform.python_version(), "machine": platform.machine(),
                          "platform": platform.system()},
              "limitations": ["Small authored corpus, not general Portuguese comprehension",
                  "Prior 98 v6 paraphrases are validation, not independent test",
                  "All facts needed by compositional tests occur in training",
                  "v6 retrained on exactly the same pairs; context flattened for v6",
                  "Linear recurrent feature graph, not a deep RNN or pretrained LLM",
                  "Memory/latency measured on this host, not Raspberry Pi; no Lazarus port"]}
    assert hashlib.sha256(model_path.read_bytes()).hexdigest() == frozen_hash
    out = ROOT / "results/evaluation.json"
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"training_seconds": elapsed, "learning": learning,
        "policy": chosen, "v6_test": report["test_v6_same_training"]["metrics"],
        "v7_test": report["test_v7"]["metrics"], "model_bytes": report["model_bytes"]},
        ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
