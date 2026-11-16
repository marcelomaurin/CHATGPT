"""Treino supervisionado do TokenGraph com exemplos revisados da IA professora."""
from __future__ import annotations

import copy
import json
import os
from pathlib import Path
import shutil
import tempfile

from treinador_neurograph import DIR_TREINO, Example, TokenGraph, preparar_exemplos, tokenize


def chave(texto: str) -> tuple[str, ...]:
    return tuple(tokenize(texto))


def validar_dataset(dados: dict) -> tuple[list[Example], list[Example]]:
    if not isinstance(dados, dict):
        raise ValueError('Informe um objeto JSON com listas "train" e "validation".')
    vistos = set()
    grupos = []
    for nome, minimo in (("train", 2), ("validation", 2)):
        itens = dados.get(nome)
        if not isinstance(itens, list) or len(itens) < minimo:
            raise ValueError(f"{nome}: informe pelo menos {minimo} pares.")
        exemplos = []
        for item in itens:
            if not isinstance(item, dict):
                raise ValueError(f"{nome}: cada par deve ser um objeto.")
            q, a = item.get("question"), item.get("answer")
            if not isinstance(q, str) or not isinstance(a, str):
                raise ValueError("Pergunta e resposta devem ser textos.")
            if not chave(q) or not chave(a) or len(chave(a)) > 60:
                raise ValueError("Pergunta/resposta vazia ou resposta com mais de 60 tokens.")
            if chave(q) in vistos:
                raise ValueError("Pergunta repetida entre exemplos de treino e validação.")
            vistos.add(chave(q))
            exemplos.append(Example(question=q.strip(), answer=a.strip(), context=()))
        grupos.append(exemplos)
    return grupos[0], grupos[1]


def avaliar(modelo, exemplos):
    resultados = []
    for ex in exemplos:
        geracao = modelo.generate(ex.question, context=ex.context)
        correto = (geracao.abstained if ex.answer is None else
                   not geracao.abstained and chave(geracao.text) == chave(ex.answer))
        resultados.append(dict(pergunta=ex.question, esperada=ex.answer,
                               resposta=geracao.text, correto=correto))
    return {"acertos": sum(r["correto"] for r in resultados),
            "total": len(resultados), "respostas": resultados}


def executar_treino_professora(dataset: Path, alvo: Path, epochs: int = 60) -> dict:
    alvo = Path(alvo).resolve()
    if alvo.suffix.lower() != ".ngs":
        raise ValueError("Selecione pesos TokenGraph .ngs; matrizes .ngm não são treináveis nesta aba.")
    if not 1 <= epochs <= 1000:
        raise ValueError("Épocas devem estar entre 1 e 1000.")
    treino, validacao = validar_dataset(json.loads(Path(dataset).read_text(encoding="utf-8-sig")))
    anteriores, _ = preparar_exemplos(incluir_base=True)
    conhecidos = {chave(ex.question) for ex in anteriores}
    if any(chave(ex.question) in conhecidos for ex in validacao):
        raise ValueError("A validação contém perguntas do dataset anterior; substitua essas perguntas.")
    novas = {chave(ex.question) for ex in treino}
    retencao = [ex for ex in anteriores if chave(ex.question) not in novas]
    modelo = TokenGraph.load(alvo) if alvo.exists() else TokenGraph()
    antes = avaliar(modelo, validacao)
    base_antes = avaliar(modelo, retencao)
    candidato = copy.deepcopy(modelo)
    alvo.parent.mkdir(parents=True, exist_ok=True)
    sessao = Path(tempfile.mkdtemp(prefix="professora_", dir=alvo.parent))
    shutil.copy2(dataset, sessao / "dataset.json")
    print(f"Sessão: {sessao}", flush=True)
    print(f"Treino: {len(treino)} novos pares; validação separada: {len(validacao)}.", flush=True)
    for epoca in range(epochs):
        if (DIR_TREINO / ".stop_training").exists():
            print("Treino interrompido. Pesos originais preservados.", flush=True)
            return {"status": "interrompido", "sessao": str(sessao)}
        candidato.fit(retencao + treino, epochs=1)
        if (epoca + 1) % 10 == 0 or epoca + 1 == epochs:
            print(f"Época {epoca + 1}/{epochs}", flush=True)
    depois = avaliar(candidato, validacao)
    base_depois = avaliar(candidato, retencao)
    promover = (depois["acertos"] > antes["acertos"] and
                base_depois["acertos"] >= base_antes["acertos"])
    candidato_path = sessao / "candidato.ngs"
    candidato.save(candidato_path)
    relatorio = dict(status="aprovado" if promover else "sem_melhoria",
                     metrica="Correspondência exata de tokens; não é avaliação semântica.",
                     antes=antes, depois=depois, retencao_antes=base_antes,
                     retencao_depois=base_depois, alvo=str(alvo), sessao=str(sessao))
    (sessao / "relatorio.json").write_text(json.dumps(relatorio, ensure_ascii=False, indent=2), encoding="utf-8")
    if promover:
        if alvo.exists():
            shutil.copy2(alvo, sessao / "anterior.ngs")
        # Substituição atômica: uma interrupção não deixa o arquivo alvo incompleto.
        temporario = sessao / "promover.ngs"
        shutil.copy2(candidato_path, temporario)
        os.replace(temporario, alvo)
    print(f"Validação: {antes['acertos']}/{antes['total']} → {depois['acertos']}/{depois['total']}", flush=True)
    print("Pesos .ngs atualizados com backup." if promover else "Sem melhoria comprovada; pesos originais preservados.", flush=True)
    print(f"Relatório: {sessao / 'relatorio.json'}", flush=True)
    return relatorio
