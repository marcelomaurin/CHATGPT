import hashlib
import json
from pathlib import Path
import struct
import tempfile
import unittest

from model import Example, HEADER, Session, TokenGraph


class LearnedGenerationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.examples = [
            Example("descreva luma", "luma é azul"),
            Example("descreva nino", "nino é verde"),
            Example("explique de novo", "luma é azul", ("descreva luma",)),
            Example("explique de novo", "nino é verde", ("descreva nino",)),
            Example("o que é quasar", None),
        ]
        cls.model = TokenGraph()
        cls.learning = cls.model.fit(cls.examples, epochs=120)

    def test_error_updates_weights_and_reduces_loss(self):
        self.assertGreater(self.learning[-1]["changed_weights"], 0)
        self.assertLess(self.learning[-2]["cross_entropy"], self.learning[0]["cross_entropy"] / 10)
        self.assertTrue(any(w < 0 for edges in self.model.edges.values() for _, w in edges))

    def test_new_question_and_prefix_select_different_tokens(self):
        self.assertEqual(self.model.generate("apresente luma").text, "luma é azul")
        self.assertEqual(self.model.generate("apresente nino").text, "nino é verde")
        self.assertEqual(self.model.next_token("apresente luma", ["luma"])[0], "é")
        self.assertEqual(self.model.next_token("apresente luma", ["luma", "é"])[0], "azul")

    def test_same_question_uses_different_context(self):
        for name, color in (("luma", "azul"), ("nino", "verde")):
            result = self.model.generate("explique de novo", context=(f"descreva {name}",))
            self.assertEqual(result.text, f"{name} é {color}")

    def test_explicit_refusal_and_empty_input(self):
        self.assertTrue(self.model.generate("o que é quasar").abstained)
        self.assertTrue(self.model.generate("").abstained)

    def test_roundtrip_needs_no_training_answers(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "weights.ngs"
            self.model.save(path)
            restored = TokenGraph.load(path)
            self.assertEqual(restored.fingerprint(), self.model.fingerprint())
            self.assertEqual(restored.generate("apresente nino").text, "nino é verde")
            raw = path.read_bytes()
            metadata_size = HEADER.unpack_from(raw)[2]
            metadata = json.loads(raw[HEADER.size:HEADER.size + metadata_size])
            self.assertNotIn("docs", metadata)
            self.assertNotIn("answers", metadata)

    def test_corrupt_truncated_and_wrong_schema_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "weights.ngs"
            raw = bytearray(self.model._bytes())
            for changed in (raw[:9], raw[:-1], raw[:30] + bytearray([raw[30] ^ 1]) + raw[31:]):
                path.write_bytes(changed)
                with self.assertRaises(ValueError):
                    TokenGraph.load(path)
            struct.pack_into("<I", raw, 8, 99)
            raw[-32:] = hashlib.sha256(raw[:-32]).digest()
            path.write_bytes(raw)
            with self.assertRaises(ValueError):
                TokenGraph.load(path)

    def test_session_persists_and_does_not_change_weights(self):
        before = self.model.fingerprint()
        with tempfile.TemporaryDirectory() as directory:
            session = Session(max_turns=2)
            self.model.respond("descreva nino", session)
            path = Path(directory) / "session.json"
            session.save(path, self.model)
            restored = Session.load(path, self.model)
            self.assertEqual(self.model.respond("explique de novo", restored).text, "nino é verde")
            self.assertEqual(self.model.fingerprint(), before)
            with self.assertRaises(ValueError):
                Session.load(path, TokenGraph())

    def test_incremental_update_learns_new_tokens_with_replay(self):
        model = TokenGraph()
        model.fit(self.examples, epochs=90)
        model.fit(self.examples + [Example("descreva suri", "suri é rosa")], epochs=120)
        self.assertEqual(model.generate("apresente suri").text, "suri é rosa")
        self.assertEqual(model.generate("apresente luma").text, "luma é azul")


class BenchmarkIntegrityTests(unittest.TestCase):
    def test_disjoint_questions_and_unseen_composed_answers(self):
        data = json.loads((Path(__file__).parent / "data/benchmark.json").read_text())
        sets = [{(r["question"], tuple(r["context"])) for r in data[k]}
                for k in ("train", "validation", "test")]
        self.assertFalse(sets[0] & sets[1] or sets[0] & sets[2] or sets[1] & sets[2])
        training_answers = {r["answer"] for r in data["train"]}
        for row in data["test"]:
            if row["category"] == "composition":
                self.assertNotIn(row["answer"], training_answers)


if __name__ == "__main__":
    unittest.main()
