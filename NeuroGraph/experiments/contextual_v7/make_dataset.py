"""Freeze a small, explicitly synthetic benchmark before fitting any weights."""
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def build():
    path = ROOT / "baseline_v6/neurograph_associativo_calibrado_v2.py"
    spec = importlib.util.spec_from_file_location("legacy_corpus", path)
    legacy = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(legacy)
    facts = legacy.CORPUS[:40]
    train = [dict(question=q, answer=a, context=[], category="legacy") for q, a in facts]
    validation = [dict(question=q, answer=a, context=[], category="paraphrase")
                  for q, a in legacy.CORPUS[40:]]
    # Fresh questions: none of these strings is allowed into gradient updates.
    questions = [
        (0, "poderia explicar o que é um cachorro"),
        (1, "me conte o que é um gato"),
        (2, "pode explicar a ideia de um animal"),
        (3, "explique o que é um médico"),
        (4, "em qual lugar trabalha um médico"),
        (5, "pode me dizer o que é um hospital"),
        (6, "me explique o conceito de um computador"),
        (7, "poderia falar sobre o que é um programa"),
        (8, "me diga o que é uma rede"),
        (9, "poderia explicar o que é uma pergunta"),
        (10, "me diga o que é uma resposta"),
        (11, "pode explicar o que é uma palavra"),
        (12, "poderia me dizer o que é uma frase"),
        (13, "me explique o que é um token"),
        (14, "pode me explicar o que é um grafo"),
        (15, "me conte o que é uma conexão"),
        (16, "poderia explicar o que é um peso"),
        (17, "pode me contar o que é memória"),
        (18, "me explique o que é aprendizado"),
        (19, "pode explicar o que é inteligência artificial"),
        (22, "poderia explicar o que é uma escola"),
        (25, "me conte o que é um professor"),
        (26, "me diga o que é um aluno"),
        (30, "pode explicar o que é uma casa"),
        (31, "me conte o que é uma árvore"),
        (32, "poderia explicar o que é o sol"),
        (33, "me diga o que é a lua"),
        (34, "pode me contar o que é português"),
        (35, "poderia explicar o que é um arquivo"),
        (36, "me conte o que é uma tabela"),
        (37, "pode explicar o que é um banco de dados"),
        (38, "me diga o que é uma máquina"),
    ]
    prior_questions = {q for q, _ in legacy.CORPUS}
    test = []
    for index, question in questions:
        # A prior identical question is not a fresh test, even with punctuation.
        if question not in prior_questions:
            test.append(dict(question=question, answer=facts[index][1], context=[], category="paraphrase"))
    # Learned context: the same current question has different correct answers.
    for index in (0, 1, 5, 6, 7, 13, 14, 35):
        context, answer = facts[index]
        for question in ("e isso", "explique novamente"):
            train.append(dict(question=question, answer=answer, context=[context], category="context"))
        validation.append(dict(question="e quanto a isso", answer=answer,
                               context=[context], category="context"))
        test.append(dict(question="pode repetir a explicação", answer=answer,
                         context=[context], category="context"))
    # Invented entities, fixed attributes. Every attribute is known in training.
    # Only combinations are held out: no demand to invent unseen factual data.
    entities = [("luma", "azul"), ("nino", "verde"), ("tavi", "roxo"),
                ("suri", "rosa"), ("bela", "branco"), ("dori", "preto"),
                ("fino", "cinza"), ("gabi", "ocre")]
    test_pairs = {(i, (i * 2 + 1) % 8) for i in range(8)}
    test_pairs = {(a, b) for a, b in test_pairs if a != b}
    validation_pairs = {(i, (i + 3) % 8) for i in range(8)} - test_pairs
    for name, color in entities:
        train.append(dict(question=f"qual a cor de {name}", answer=f"{name} é {color}",
                          context=[], category="composition"))
    for i, (left, color1) in enumerate(entities):
        for j, (right, color2) in enumerate(entities):
            if i == j:
                continue
            answer = f"{left} é {color1} e {right} é {color2}"
            if (i, j) in test_pairs:
                target, prompts = test, ["descreva"]
            elif (i, j) in validation_pairs:
                target, prompts = validation, ["apresente"]
            else:
                target, prompts = train, ["descreva", "apresente"]
            for prompt in prompts:
                target.append(dict(question=f"{prompt} {left} e {right}", answer=answer,
                                   context=[], category="composition"))
    unknown = {
        "train": ["o que é um quasar", "qual é a capital da austrália", "quem inventou o rádio",
                  "como funciona um satélite", "qual é a distância de marte", "o que é um píon",
                  "quem descobriu netuno", "qual é o tamanho de júpiter"],
        "validation": ["o que é um neutrino", "qual é a capital da frança",
                       "quem descobriu plutão", "qual é a massa de vênus"],
        "test": ["o que é plutônio", "qual é a capital do japão", "quem inventou o telefone",
                 "qual é a órbita de saturno", "como funciona um pulsar", "o que é titânio",
                 "qual é a população de londres", "quem descobriu urano"],
    }
    for name, target in (("train", train), ("validation", validation), ("test", test)):
        target.extend(dict(question=q, answer=None, context=[], category="unknown") for q in unknown[name])
    # No overlapping (current question, history) is permitted across partitions.
    signatures = [{(e["question"], tuple(e["context"])) for e in partition}
                  for partition in (train, validation, test)]
    assert not (signatures[0] & signatures[1] or signatures[0] & signatures[2] or signatures[1] & signatures[2])
    training_answers = {e["answer"] for e in train}
    assert all(e["answer"] not in training_answers for e in test if e["category"] == "composition")
    return {"version": 1, "provenance": {
        "legacy": "40 original v6 pairs; prior 98 paraphrases used only as validation",
        "new_questions": "Authored on 2026-11-13 before fitting v7; small controlled benchmark",
        "composition": "Invented entities and colors; every individual fact is trained",
        "limits": "Not a Portuguese language benchmark or an independent human evaluation"},
        "train": train, "validation": validation, "test": test}


if __name__ == "__main__":
    path = ROOT / "data/benchmark.json"
    path.parent.mkdir(exist_ok=True)
    data = build()
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({k: len(data[k]) for k in ("train", "validation", "test")}))
