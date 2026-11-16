import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import treino_professora as tp


def dataset():
    return {"train": [{"question": "treino um", "answer": "luz"},
                      {"question": "treino dois", "answer": "calor"}],
            "validation": [{"question": "teste um", "answer": "luz"},
                           {"question": "teste dois", "answer": "calor"}]}


class Modelo:
    melhorar = True
    regredir = False

    def __init__(self):
        self.treinado = False

    @classmethod
    def load(cls, path):
        return cls()

    def fit(self, exemplos, **kwargs):
        assert not any(ex.question.startswith("teste") for ex in exemplos)
        self.treinado = True

    def generate(self, pergunta, **kwargs):
        if pergunta == "base":
            resposta = "erro" if self.treinado and self.regredir else "base"
        elif self.treinado and self.melhorar:
            resposta = "luz" if pergunta == "teste um" else "calor"
        else:
            resposta = "erro"
        return SimpleNamespace(text=resposta, abstained=False)

    def save(self, path):
        Path(path).write_bytes(b"novo")


class TreinoProfessoraTests(unittest.TestCase):
    def test_rejeita_pergunta_repetida_entre_grupos(self):
        dados = dataset()
        dados["validation"][0]["question"] = "TREINO UM!"
        with self.assertRaises(ValueError):
            tp.validar_dataset(dados)

    def test_rejeita_resposta_vazia(self):
        dados = dataset()
        dados["train"][0]["answer"] = ""
        with self.assertRaises(ValueError):
            tp.validar_dataset(dados)

    def executar(self, melhorar=True, regredir=False, parar=False):
        with tempfile.TemporaryDirectory() as pasta:
            pasta = Path(pasta)
            arquivo = pasta / "dados.json"
            arquivo.write_text(json.dumps(dataset()), encoding="utf-8")
            alvo = pasta / "modelo.ngs"
            alvo.write_bytes(b"original")
            if parar:
                (pasta / ".stop_training").touch()
            Modelo.melhorar, Modelo.regredir = melhorar, regredir
            base = [tp.Example(question="base", answer="base", context=())]
            with patch.object(tp, "TokenGraph", Modelo), patch.object(tp, "DIR_TREINO", pasta), patch.object(tp, "preparar_exemplos", return_value=(base, [])):
                resultado = tp.executar_treino_professora(arquivo, alvo, epochs=1)
            sessao = Path(resultado["sessao"])
            return resultado, alvo.read_bytes(), (sessao / "anterior.ngs").read_bytes() if (sessao / "anterior.ngs").exists() else None

    def test_promove_com_backup_e_sem_vazar_validacao(self):
        resultado, atual, backup = self.executar()
        self.assertEqual(resultado["status"], "aprovado")
        self.assertEqual(atual, b"novo")
        self.assertEqual(backup, b"original")

    def test_sem_melhoria_preserva_pesos(self):
        resultado, atual, _ = self.executar(melhorar=False)
        self.assertEqual(resultado["status"], "sem_melhoria")
        self.assertEqual(atual, b"original")

    def test_regressao_preserva_pesos(self):
        resultado, atual, _ = self.executar(regredir=True)
        self.assertEqual(resultado["status"], "sem_melhoria")
        self.assertEqual(atual, b"original")

    def test_parada_preserva_pesos(self):
        resultado, atual, _ = self.executar(parar=True)
        self.assertEqual(resultado["status"], "interrompido")
        self.assertEqual(atual, b"original")


if __name__ == "__main__":
    unittest.main()
