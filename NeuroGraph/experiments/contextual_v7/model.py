"""Experimental, learned autoregressive token graph. Inference uses the stdlib.

Input and prefix features are activation nodes; signed edges predict the next
token. A leaky recurrent state retains earlier emitted tokens. Training updates
the edges by cross-entropy, not by choosing a stored answer or grammar rule.
This is a linear recurrent feature model, not a deep RNN or a pretrained LLM.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
import hashlib
import json
import math
import os
import re
import struct
import tempfile

BOS, EOS, REFUSE = "<bos>", "<eos>", "<refuse>"
MAGIC = b"NGCTX007"
HEADER = struct.Struct("<8sIII")
EDGE = struct.Struct("<IIf")
MAX_FILE_BYTES = 256 * 1024 * 1024

ARTICLES_PREPS = frozenset({
    "o", "a", "os", "as", "um", "uma", "uns", "umas",
    "de", "do", "da", "dos", "das", "ao", "à",
})

CONNECTORS = ARTICLES_PREPS | frozenset({
    "em", "no", "na", "nos", "nas",
    "por", "para", "com", "sem", "que", "e", "ou", "se",
})

QUESTION_FRAMES = CONNECTORS | frozenset({
    "qual", "quais", "como", "quando", "onde", "quem", "quanto", "quantos",
    "é", "são", "foi", "foram", "era", "ser", "está", "estão",
    "explique", "descreva", "apresente", "fale", "diga", "defina",
    "resuma", "conte", "mostre", "novo", "novamente", "sobre",
    "funciona", "serve", "significa", "conceito", "importância",
    "significado", "função", "objetivo", "causa", "descobriu",
    "inventou", "criou", "existe", "ocorreu", "aconteceu",
})


def tokenize(text: str) -> list[str]:
    return re.findall(r"[^\W_]+", text.casefold(), flags=re.UNICODE)


@dataclass(frozen=True)
class Example:
    question: str
    answer: str | None
    context: tuple[str, ...] = ()


@dataclass
class Generation:
    text: str
    tokens: list[str]
    probabilities: list[float]
    abstained: bool
    reason: str


@dataclass
class Session:
    """Explicit, bounded conversation context. Generation never trains itself."""
    history: list[str] = field(default_factory=list)
    max_turns: int = 3

    def remember(self, question: str) -> None:
        self.history = (self.history + [" ".join(tokenize(question)[:64])])[-self.max_turns:]

    def save(self, path: str | Path, model: "TokenGraph") -> None:
        data = {"version": 1, "model": model.fingerprint(),
                "history": self.history, "max_turns": self.max_turns}
        _atomic_write(Path(path), json.dumps(data, ensure_ascii=False).encode("utf-8"))

    @classmethod
    def load(cls, path: str | Path, model: "TokenGraph") -> "Session":
        raw = Path(path).read_bytes()
        if len(raw) > 65536:
            raise ValueError("Session exceeds the size budget")
        data = json.loads(raw)
        if data.get("version") != 1 or data.get("model") != model.fingerprint():
            raise ValueError("Session version or model mismatch")
        limit = data.get("max_turns")
        history = data.get("history")
        if type(limit) is not int or not 1 <= limit <= 8:
            raise ValueError("Invalid context budget")
        if not isinstance(history, list) or len(history) > limit or any(
                not isinstance(q, str) or len(tokenize(q)) > 64 for q in history):
            raise ValueError("Invalid context history")
        return cls(history, limit)


def _atomic_write(path: Path, payload: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    name = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as stream:
            name = stream.name
            stream.write(payload)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if name and os.path.exists(name):
            os.unlink(name)


class TokenGraph:
    def __init__(self, decay: float = 0.65, confidence: float = 0.10):
        if not 0 <= decay < 1 or not 0 <= confidence <= 1:
            raise ValueError("Invalid decay or confidence")
        self.decay = decay
        self.confidence = confidence
        self.tokens = [EOS, REFUSE]
        self.token_ids = {t: i for i, t in enumerate(self.tokens)}
        self.features: list[tuple[str, ...]] = []
        self.feature_ids: dict[tuple[str, ...], int] = {}
        self.edges: dict[int, list[tuple[int, float]]] = {}
        self.training_log: list[dict] = []

    def _input(self, question: str, context: tuple[str, ...] = ()) -> dict:
        words = tokenize(question)[:64]
        active = {
            ("q", t): (0.25 if t in ARTICLES_PREPS else (1.0 if t in QUESTION_FRAMES else 1.25))
            for t in words
        }
        for t in words:
            if len(t) >= 5 and t not in QUESTION_FRAMES:
                active[("stem", t[:5])] = 0.20
        for i, token in enumerate(words):
            active[("pos", str(i), token)] = 0.15 if token in ARTICLES_PREPS else 0.35
        for left, right in zip(words, words[1:]):
            active[("pair", left, right)] = 0.5
        for age, previous in enumerate(reversed(context[-3:])):
            for token in set(tokenize(previous)[:64]):
                active[("context", token)] = active.get(("context", token), 0.0) + 0.5 ** age
        return active

    def _step(self, source: dict, prefix: list[str], memory: dict) -> dict:
        last = prefix[-1] if prefix else BOS
        before = prefix[-2] if len(prefix) > 1 else BOS
        active = {("bias",): 1.0, ("prev", last): 1.0,
                  ("prev2", before, last): 1.0, ("step", str(len(prefix))): 0.5}
        for feature, strength in source.items():
            active[feature] = strength
            if feature[0] != "stem":
                active[("with_prev", *feature, last)] = strength
        for token, strength in memory.items():
            active[("memory", token)] = strength
        return active

    def _advance(self, memory: dict, token: str) -> dict:
        result = {t: v * self.decay for t, v in memory.items() if v * self.decay >= 0.001}
        result[token] = result.get(token, 0.0) + 1.0
        return result

    def _has_known_concept(self, question: str, context: tuple[str, ...] = ()) -> bool:
        """Gate against hallucinating answers when the question asks about unseen concepts."""
        if not self.feature_ids:
            return False
        for prev in context[-3:]:
            for t in tokenize(prev)[:64]:
                if t not in CONNECTORS and (("context", t) in self.feature_ids or ("q", t) in self.feature_ids):
                    return True
        words = tokenize(question)[:64]
        if not words:
            return False
        # The target concept at the end of a non-contextual question must be known (exact or stem)
        focus = words[-1]
        if focus not in QUESTION_FRAMES:
            if ("q", focus) not in self.feature_ids and (len(focus) < 5 or ("stem", focus[:5]) not in self.feature_ids):
                return False
        concepts = [w for w in words if w not in QUESTION_FRAMES]
        if concepts:
            return any(
                ("q", c) in self.feature_ids or (len(c) >= 5 and ("stem", c[:5]) in self.feature_ids)
                for c in concepts
            )
        return any(("q", w) in self.feature_ids for w in words)

    def fit(self, examples: list[Example], *, epochs: int = 180,
            learning_rate: float = 0.05, regularization: float = 0.0001,
            batch_size: int = 4096) -> list[dict]:
        """Update learned edges, retaining existing edges when adding examples.

        Only training examples enter this method. Validation/test sets must stay
        outside it. NumPy and SciPy are needed here, but not for generation.
        """
        import numpy as np
        from scipy.sparse import csr_matrix
        if not examples or epochs < 1 or learning_rate <= 0 or regularization < 0:
            raise ValueError("Invalid training configuration")
        samples, targets = [], []
        for example in examples:
            answer = tokenize(example.answer) if example.answer is not None else [REFUSE]
            if not tokenize(example.question) or not answer or len(answer) > 63:
                raise ValueError("Training examples must have nonempty, bounded sequences")
            for token in answer + [EOS]:
                if token not in self.token_ids:
                    self.token_ids[token] = len(self.tokens)
                    self.tokens.append(token)
            source, prefix, memory = self._input(example.question, example.context), [], {}
            for token in answer + [EOS]:
                features = self._step(source, prefix, memory)
                for feature in features:
                    if feature not in self.feature_ids:
                        self.feature_ids[feature] = len(self.features)
                        self.features.append(feature)
                samples.append(features)
                targets.append(self.token_ids[token])
                prefix.append(token)
                memory = self._advance(memory, token)
        rows, cols, values = [], [], []
        for row, sample in enumerate(samples):
            for feature, value in sample.items():
                rows.append(row); cols.append(self.feature_ids[feature]); values.append(value)
        cols_arr = np.asarray(cols, dtype=np.int32)
        active_features = np.unique(cols_arr)
        local_cols = np.searchsorted(active_features, cols_arr)
        n_active = len(active_features)
        inputs = csr_matrix((np.array(values, dtype=np.float32), (rows, local_cols)),
                            shape=(len(samples), n_active))
        weights = np.zeros((n_active, len(self.tokens)), dtype=np.float32)
        for local_idx, feat_id in enumerate(active_features):
            for target, value in self.edges.get(int(feat_id), ()):
                weights[local_idx, target] = value
        initial = weights.copy()
        first_moment, second_moment = np.zeros_like(weights), np.zeros_like(weights)
        target_ids = np.asarray(targets, dtype=np.int32)
        n_samples = len(samples)
        report = []
        step_num = 0
        rng = np.random.default_rng(42)

        for epoch in range(1, epochs + 1):
            if n_samples <= batch_size:
                step_num += 1
                logits = inputs @ weights
                logits -= logits.max(axis=1, keepdims=True)
                np.exp(logits, out=logits)
                probabilities = logits
                probabilities /= probabilities.sum(axis=1, keepdims=True)
                if epoch == 1 or epoch == epochs or epoch % 30 == 0:
                    loss = float(-np.log(np.maximum(probabilities[np.arange(n_samples), target_ids], 1e-12)).mean())
                    acc = float((probabilities.argmax(axis=1) == target_ids).mean())
                    report.append({"epoch": epoch, "cross_entropy": loss,
                                   "teacher_forced_token_accuracy": acc})
                probabilities[np.arange(n_samples), target_ids] -= 1.0
                gradient = np.asarray(inputs.T @ probabilities, dtype=np.float32) / n_samples
                if regularization > 0:
                    gradient += regularization * weights
                first_moment *= 0.9
                first_moment += 0.1 * gradient
                second_moment *= 0.999
                second_moment += 0.001 * (gradient * gradient)
                bias_corr1 = 1.0 - 0.9 ** step_num
                bias_corr2 = math.sqrt(1.0 - 0.999 ** step_num)
                step_scale = learning_rate * (bias_corr2 / bias_corr1)
                weights -= step_scale * first_moment / (np.sqrt(second_moment) + 1e-8)
            else:
                perm = rng.permutation(n_samples)
                epoch_loss_sum = 0.0
                epoch_correct = 0
                eval_epoch = (epoch == 1 or epoch == epochs or epoch % 30 == 0)
                for start_idx in range(0, n_samples, batch_size):
                    step_num += 1
                    batch_idx = perm[start_idx:start_idx + batch_size]
                    b_len = len(batch_idx)
                    b_inputs = inputs[batch_idx]
                    b_targets = target_ids[batch_idx]
                    logits = b_inputs @ weights
                    logits -= logits.max(axis=1, keepdims=True)
                    np.exp(logits, out=logits)
                    probabilities = logits
                    probabilities /= probabilities.sum(axis=1, keepdims=True)
                    if eval_epoch:
                        epoch_loss_sum += float(-np.log(np.maximum(probabilities[np.arange(b_len), b_targets], 1e-12)).sum())
                        epoch_correct += int((probabilities.argmax(axis=1) == b_targets).sum())
                    probabilities[np.arange(b_len), b_targets] -= 1.0
                    active_rows = np.unique(b_inputs.indices)
                    b_inputs_sub = b_inputs[:, active_rows]
                    grad_sub = np.asarray(b_inputs_sub.T @ probabilities, dtype=np.float32) / b_len
                    if regularization > 0:
                        grad_sub += regularization * weights[active_rows]
                    m_sub = first_moment[active_rows] * 0.9 + 0.1 * grad_sub
                    v_sub = second_moment[active_rows] * 0.999 + 0.001 * (grad_sub * grad_sub)
                    first_moment[active_rows] = m_sub
                    second_moment[active_rows] = v_sub
                    bias_corr1 = 1.0 - 0.9 ** step_num
                    bias_corr2 = math.sqrt(1.0 - 0.999 ** step_num)
                    step_scale = learning_rate * (bias_corr2 / bias_corr1)
                    weights[active_rows] -= step_scale * m_sub / (np.sqrt(v_sub) + 1e-8)
                if eval_epoch:
                    report.append({
                        "epoch": epoch,
                        "cross_entropy": epoch_loss_sum / n_samples,
                        "teacher_forced_token_accuracy": epoch_correct / n_samples,
                    })

        if not np.isfinite(weights).all():
            raise ValueError("Non-finite training weights")
        # Omit tiny edges; serialization/inference share the same float32 values.
        prune_threshold = 0.025 if len(self.tokens) > 200 else 0.005
        for local_idx, feat_id in enumerate(active_features):
            fid = int(feat_id)
            indices = np.flatnonzero(np.abs(weights[local_idx]) >= prune_threshold)
            if len(indices):
                self.edges[fid] = [(int(t), float(weights[local_idx, t])) for t in indices]
            else:
                self.edges.pop(fid, None)
        report.append({"changed_weights": int((np.abs(weights - initial) > 1e-6).sum()),
                       "features": len(self.features), "tokens": len(self.tokens),
                       "stored_edges": sum(map(len, self.edges.values()))})
        self.training_log.extend(report)
        return report

    def next_token(self, question: str, prefix: list[str], *, context: tuple[str, ...] = ()) -> tuple[str, float]:
        memory = {}
        for token in prefix:
            memory = self._advance(memory, token)
        return self._predict(self._step(self._input(question, context), prefix, memory), prefix)

    def _predict(self, active: dict, prefix: list[str] | None = None) -> tuple[str, float]:
        scores = [0.0] * len(self.tokens)
        for feature, activation in active.items():
            for target, weight in self.edges.get(self.feature_ids.get(feature, -1), ()):
                scores[target] += activation * weight
        if prefix:
            last_tok = prefix[-1]
            last_id = self.token_ids.get(last_tok, -1)
            if last_id >= 0:
                scores[last_id] -= 2.5
            # Penalize repeated bigrams to prevent decoding loops
            if len(prefix) >= 2:
                seen_next = {prefix[i + 1] for i in range(len(prefix) - 1) if prefix[i] == last_tok}
                for tok in seen_next:
                    tid = self.token_ids.get(tok, -1)
                    if tid >= 0:
                        scores[tid] -= 1.5
        target = max(range(len(scores)), key=scores.__getitem__)
        best = scores[target]
        probability = 1 / sum(math.exp(value - best) for value in scores)
        return self.tokens[target], probability

    def generate(self, question: str, *, context: tuple[str, ...] = (), max_tokens: int = 64) -> Generation:
        if not 1 <= max_tokens <= 256:
            raise ValueError("Invalid output budget")
        if not tokenize(question):
            return Generation("não tenho associações suficientes", [], [], True, "empty_input")
        if not self._has_known_concept(question, context):
            return Generation("não tenho associações suficientes", [], [], True, "unknown_concept")
        source, prefix, memory, probabilities = self._input(question, context), [], {}, []
        for _ in range(max_tokens):
            token, probability = self._predict(self._step(source, prefix, memory), prefix)
            probabilities.append(probability)
            if token == REFUSE or probability < self.confidence:
                return Generation("não tenho associações suficientes", [], probabilities, True, "refused_or_low_confidence")
            if token == EOS:
                if not prefix:
                    return Generation("não tenho associações suficientes", [], probabilities, True, "empty_generation")
                return Generation(" ".join(prefix), prefix, probabilities, False, "eos")
            prefix.append(token)
            memory = self._advance(memory, token)
        return Generation("não tenho associações suficientes", [], probabilities, True, "token_budget")

    def respond(self, question: str, session: Session) -> Generation:
        result = self.generate(question, context=tuple(session.history))
        session.remember(question)
        return result

    def _bytes(self) -> bytes:
        metadata = json.dumps({"version": 7, "architecture": "recurrent-loglinear-token-graph",
            "decay": self.decay, "confidence": self.confidence, "tokens": self.tokens,
            "features": self.features}, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
        edges = b"".join(EDGE.pack(source, target, weight)
                         for source, row in sorted(self.edges.items()) for target, weight in row)
        payload = HEADER.pack(MAGIC, 1, len(metadata), len(edges) // EDGE.size) + metadata + edges
        return payload + hashlib.sha256(payload).digest()

    def fingerprint(self) -> str:
        return hashlib.sha256(self._bytes()).hexdigest()

    def save(self, path: str | Path) -> None:
        _atomic_write(Path(path), self._bytes())

    @classmethod
    def load(cls, path: str | Path) -> "TokenGraph":
        path = Path(path)
        if not HEADER.size + 32 <= path.stat().st_size <= MAX_FILE_BYTES:
            raise ValueError("Invalid model size")
        raw = path.read_bytes()
        payload, digest = raw[:-32], raw[-32:]
        if hashlib.sha256(payload).digest() != digest:
            raise ValueError("Model checksum mismatch")
        magic, schema, metadata_size, count = HEADER.unpack_from(payload)
        if magic != MAGIC or schema != 1 or HEADER.size + metadata_size + count * EDGE.size != len(payload):
            raise ValueError("Invalid model format")
        metadata = json.loads(payload[HEADER.size:HEADER.size + metadata_size])
        if metadata.get("version") != 7 or metadata.get("architecture") != "recurrent-loglinear-token-graph":
            raise ValueError("Unsupported architecture")
        model = cls(metadata["decay"], metadata["confidence"])
        model.tokens = metadata["tokens"]
        model.features = [tuple(f) for f in metadata["features"]]
        if (len(set(model.tokens)) != len(model.tokens) or
                not all(isinstance(t, str) for t in model.tokens) or
                EOS not in model.tokens or REFUSE not in model.tokens or
                len(set(model.features)) != len(model.features) or
                any(not f or not all(isinstance(t, str) for t in f) for f in model.features)):
            raise ValueError("Invalid vocabulary or features")
        model.token_ids = {t: i for i, t in enumerate(model.tokens)}
        model.feature_ids = {f: i for i, f in enumerate(model.features)}
        seen = set()
        for offset in range(HEADER.size + metadata_size, len(payload), EDGE.size):
            source, target, weight = EDGE.unpack_from(payload, offset)
            if (source >= len(model.features) or target >= len(model.tokens) or
                    not math.isfinite(weight) or (source, target) in seen):
                raise ValueError("Invalid edge")
            seen.add((source, target))
            model.edges.setdefault(source, []).append((target, weight))
        return model
