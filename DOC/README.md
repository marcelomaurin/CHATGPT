# Documentação Técnica — Lazarus AI Suite

Esta pasta contém documentação técnica orientada ao programador para os componentes da **Lazarus AI Suite / TCHATGPT**.

A documentação aqui complementa os READMEs principais do projeto e deve ser usada por quem vai instalar, testar, manter ou evoluir os componentes.

---

## Índice

| Área | Caminho | Descrição |
|---|---|---|
| Componentes | [`components/`](components/) | READMEs individuais por componente |
| Status oficial | [`../pacote/COMPONENT_STATUS.md`](../pacote/COMPONENT_STATUS.md) | Matriz de maturidade dos componentes |
| Pacotes Lazarus | [`../pacote/packages/`](../pacote/packages/) | Pacotes modulares `.lpk` |
| Samples | [`../pacote/samples/`](../pacote/samples/) | Projetos de demonstração |
| Workers Python | [`../pacote/python/`](../pacote/python/) | Scripts usados por componentes externos |

---

## Regra desta documentação

Cada componente deve ter seu próprio arquivo:

```text
DOC/components/<NomeDoComponente>/README.md
```

Cada README de componente deve conter:

* finalidade;
* pacote Lazarus;
* unit de origem;
* status de maturidade;
* propriedades principais;
* métodos principais;
* exemplo de uso;
* observações e limitações.

---

## Pacotes modulares

A instalação recomendada é feita por pacotes modulares em:

```text
pacote/packages/
```

O pacote `pacote/openai.lpk` é apenas um wrapper legado.

---

## Status

Use a matriz oficial em:

```text
pacote/COMPONENT_STATUS.md
```

para saber se um componente está `Stable`, `Beta`, `Experimental`, `Placeholder` ou `Deprecated`.
