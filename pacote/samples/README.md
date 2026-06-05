# Demonstration Projects — Samples

Esta pasta contém projetos de demonstração para validar componentes da **Lazarus AI Suite**.

Os samples agora devem ser documentados por **pacote modular**, não apenas pelo antigo pacote monolítico `openai.lpk`.

---

## Organização

Os samples podem ser:

| Tipo | Descrição |
|---|---|
| GUI | Aplicações visuais Lazarus com formulários, botões, imagens e logs |
| Console | Projetos `.lpr` simples para testes automatizados ou uso em linha de comando |

Cada sample deve conter, quando aplicável:

```text
sample_name.lpi
sample_name.lpr
main.pas
main.lfm
README.md
arquivos de entrada de teste
```

---

## Samples disponíveis

| Sample | Tipo | Pacote necessário | Dependência externa | Status |
|---|---|---|---|---|
| `AI Vision/opencv_filter_demo` | GUI | `openai_vision.lpk` | Python 3 + `opencv-python` + `numpy` | Funcional/Beta |

---

## Sample: TAIOpenCV Filter Demo

Caminho:

```text
samples/AI Vision/opencv_filter_demo/
```

Esse sample demonstra o componente `TAIOpenCV` em uma interface gráfica Lazarus.

Recursos demonstrados:

* SelfTest do OpenCV;
* carregamento de imagem;
* leitura de metadados da imagem;
* filtros `None`, `Gray`, `Blur`, `Canny`, `Threshold` e `Resize`;
* visualização da imagem original e processada;
* salvamento do resultado;
* log de execução.

Dependências:

```bash
pip install opencv-python numpy
```

Worker usado:

```text
../python/aiopencv_worker.py
```

---

## Regras para novos samples

Todo novo sample deve informar:

* pacote Lazarus necessário;
* componentes demonstrados;
* dependências externas;
* comandos de teste manual, quando houver;
* status do sample;
* se é GUI ou console;
* se exige API key, Python, OpenCV, hardware, banco ou serviço externo.

---

## Status dos samples

Use a mesma classificação da matriz de componentes:

| Status | Significado |
|---|---|
| Funcional | Abre, compila e demonstra recurso real |
| Beta | Funciona, mas ainda precisa validação ampla |
| Experimental | Demonstra API em evolução |
| Placeholder | Estrutura existe, mas não comprova função real |
| Pendente | Ainda precisa ser criado |
