# Cnn Classifier Complete Demo (cnnclassifier)

Este projeto é um **demo completo de classificação de imagem com CNN no Lazarus**, usando um componente visual `TCNNClassifier` ligado a um `TPythonConnector`. A ideia principal é permitir que uma aplicação Lazarus carregue uma imagem, inicialize um runtime Python por DLL/SO, carregue um modelo TensorFlow e devolva o rótulo identificado com a classificação. A tela principal já nasce com os dois componentes conectados: `CNNClassifier1.PythonConnector := PythonConnector1`, com preferência por execução direta via DLL/SO, sem chamar `python.exe` externo.

> [!WARNING]
> **Compatibilidade (Apenas 64-bits)**: Este projeto **não funciona em ambiente de 32-bits (x86)**. O backend TensorFlow utilizado para a classificação de imagens não possui suporte ou builds oficiais para a plataforma Windows de 32-bits. O projeto deve ser compilado e executado obrigatoriamente como um aplicativo de 64-bits (`x86_64-win64`).

## Visão geral do projeto

O projeto é organizado em três partes principais:

1. **`main.pas`**
   É a aplicação visual. Ela controla a tela, os botões, a seleção de imagem, o preview, os logs, a configuração da DLL/SO do Python e o botão de execução.

2. **`cnnclassifier.pas`**
   É o componente de alto nível de IA. Ele sabe verificar dependências, carregar o modelo CNN, classificar a imagem e guardar os resultados em `LastLabel`, `LastConfidence` e `LastError`. 

3. **`pythonconnector.pas`**
   É a ponte entre Lazarus e Python. Ele carrega a DLL/SO, resolve as funções da API C do Python, executa código Python, lê variáveis Python e gera diagnóstico detalhado quando algo falha. 

Na prática, o usuário não precisa lidar diretamente com TensorFlow no formulário. Ele escolhe uma imagem, clica em executar, e o formulário usa os componentes para fazer o trabalho pesado.

## Tela principal: `TfrmMain`

A tela principal funciona como uma bancada de teste. Ela tem botões para aplicar o caminho da DLL/SO, procurar manualmente a biblioteca Python, testar a configuração, limpar logs e executar a classificação. Também possui um `TComboBox` para selecionar imagens, um `TImage` para preview, dois `TMemo` para logs e labels para mostrar status da execução. Esses elementos aparecem declarados no formulário junto com `CNNClassifier1` e `PythonConnector1`. 

Quando o formulário é criado, ele faz três coisas importantes. Primeiro, liga o classificador ao conector Python. Depois, configura o conector para trabalhar em modo `pemDLL` e `plmManualPath`, ou seja, usando uma DLL/SO indicada manualmente. Por fim, procura imagens `.jpg`, `.jpeg` e `.png` dentro da pasta `imagem`, preenchendo o combo de seleção automaticamente. 

Esse desenho é bom porque torna o demo didático: a tela mostra o que está acontecendo, permite trocar a DLL/SO, permite testar o Python separadamente e só depois executar a CNN.

## `TPythonConnector`: a ponte Lazarus ↔ Python

O `TPythonConnector` é o componente mais estrutural do projeto. Ele encapsula a comunicação com o interpretador Python. Internamente, ele conhece as funções essenciais da API C do Python, como `Py_Initialize`, `Py_Finalize`, `Py_IsInitialized`, `PyRun_SimpleString`, `Py_GetVersion`, `PyImport_AddModule`, `PyModule_GetDict` e outras usadas para executar scripts e recuperar variáveis. 

Ele também foi pensado para multiplataforma. O código prevê Windows 32/64 bits, Linux 32/64 bits, Linux ARM, Linux ARM64 e macOS 64 bits. Essa parte é importante para o seu projeto CHATGPT porque mantém a ideia de rodar em Windows, Linux e Raspberry Pi. 

O conector tem dois modos conceituais:

**`pemDLL`**
Carrega o Python diretamente pela DLL/SO. É o modo usado neste demo. A vantagem é que não abre processo externo. A desvantagem é que a DLL/SO precisa ser compatível com a arquitetura do executável.

**`pemProcess`**
Executa Python como processo separado. O componente possui suporte para isso, mas neste exemplo o formulário força `PreferProcessMode := False` e trabalha com DLL/SO pura. 

Outro ponto forte é o diagnóstico. O componente consegue gerar relatório com sistema operacional, arquitetura, DLL carregada, versão do Python, métodos obrigatórios encontrados e compatibilidade. Isso é essencial porque erros com Python embarcado normalmente não são óbvios: pode ser DLL errada, arquitetura errada, versão incompatível, função ausente ou dependência quebrada. 

## Localização automática da DLL/SO do Python

O formulário tenta encontrar a biblioteca Python dentro da estrutura do projeto em `runtime/python/libs`, escolhendo subpastas conforme sistema operacional e arquitetura. No Windows, ele diferencia `windows\x86_64` e `windows\x86`; no Linux, diferencia `linux\x86_64`, `linux\x86`, `linux\arm` e `linux\arm64`; e no macOS usa a estrutura correspondente. 

A biblioteca preferida é o Python 3.12: `python312.dll` no Windows, `libpython3.12.so` no Linux e `libpython3.12.dylib` no macOS. O código ainda tenta outras versões, como 3.14, 3.13, 3.11, 3.10, 3.9 e 3.8, caso a 3.12 não exista. 

Isso mostra uma preocupação real com distribuição: o demo não depende simplesmente do Python instalado no sistema. Ele tenta usar um runtime empacotado dentro do próprio projeto.

## Teste de configuração do Python

Antes de classificar uma imagem, o usuário pode testar a DLL/SO. O botão de teste aplica o caminho configurado, verifica se o arquivo existe, ativa o `PythonConnector1`, confirma se ele foi inicializado e executa um pequeno script Python para obter versão, plataforma, executável, arquitetura e `sys.path`. 

Esse teste é muito útil porque separa dois problemas diferentes:

* “O Python carregou?”
* “A CNN funcionou?”

Sem esse teste, qualquer falha pareceria ser erro da IA, quando muitas vezes o problema está antes: DLL inexistente, Python incompatível, arquitetura 32/64 errada ou dependência ausente.

## `TCNNClassifier`: o componente de IA

O `TCNNClassifier` é o componente que transforma o Python em uma funcionalidade de alto nível para Lazarus. Ele expõe propriedades simples:

* `PythonConnector`
* `WeightsFile`
* `Threshold`
* `BackendMode`
* `LastLabel`
* `LastConfidence`
* `LastError`
* `AutoInstallDependencies`
* `PreferProcessMode`

Essas propriedades escondem bastante complexidade. Em vez de o formulário montar todo o código TensorFlow, ele apenas configura o classificador e chama `LoadWeights` e `ClassifyFrame`. 

O componente verifica se o `PythonConnector` está associado, ativo e inicializado. Se não estiver, tenta ativá-lo e registra erros claros em `LastError`. Ele também mascara exceções de ponto flutuante para evitar problemas de inicialização com HDF5/TensorFlow, algo comum em bibliotecas científicas carregadas dentro de aplicações nativas. 

## Dependências da CNN

A CNN depende de três bibliotecas Python principais:

* `numpy`
* `pillow/PIL`
* `tensorflow`

O método de verificação tenta importar essas bibliotecas dentro do Python carregado e registra quais falharam. Se algo estiver ausente, ele monta uma mensagem com detalhes da falha e informações do runtime. 

O componente também tem uma função de instalação automática, usando `pip` via `runpy.run_module("pip")` dentro do próprio Python carregado, sem chamar `python.exe` externo. Isso combina com a proposta do projeto: manter o fluxo controlado pelo runtime embarcado. 

## Carregamento do modelo

No botão de execução, o formulário configura:

```pascal
CNNClassifier1.WeightsFile := 'weights.h5';
CNNClassifier1.Threshold := 0.75;
CNNClassifier1.BackendMode := 'TensorFlow';
CNNClassifier1.AutoInstallDependencies := True;
```

Depois chama `CNNClassifier1.LoadWeights`. Se o arquivo `weights.h5` existir, o componente tenta carregar esse modelo personalizado. Se não existir, o comportamento do componente é usar um fallback baseado em `MobileNetV2` com pesos ImageNet. Isso torna o demo mais amigável, porque ele pode funcionar mesmo sem um modelo treinado próprio, desde que TensorFlow consiga baixar ou acessar os pesos necessários. 

## Execução da classificação

O fluxo do botão `btnRunClick` é bem organizado. Ele começa aplicando o caminho da DLL/SO, verifica se há imagem selecionada, monta o caminho completo da imagem, configura o classificador, valida se a DLL/SO existe, valida se a imagem existe, ativa o Python e só então tenta carregar o modelo e classificar. 

A classificação em si chama `ClassifyFrame`. Esse método garante que o modelo esteja carregado, chama `ClassifyImage`, grava `LastLabel` e `LastConfidence`, e compara a confiança com o `Threshold`. Se a confiança for menor que o limite, retorna erro informando que a confiança ficou abaixo do aceitável. 

Dentro de `ClassifyImage`, o componente monta um script Python que carrega a imagem, ajusta o tamanho conforme o modelo, transforma em array NumPy, aplica o pré-processamento adequado, executa `cnn_model.predict` e interpreta o resultado. Se o modelo for MobileNetV2, ele usa `decode_predictions`; se for modelo customizado, ele pega o índice com maior probabilidade e retorna algo como `class_0`, `class_1`, etc. 

## Preview e logs

O projeto também cuida da experiência visual. Quando o usuário muda a imagem no combo, o evento `cbImageSelectChange` carrega o arquivo no `imgPreview`, permitindo ver o que será classificado antes de executar. 

Os logs são divididos em dois memos:

* `memoLog`: log funcional da execução da CNN.
* `melog`: log técnico de conexão/configuração do Python.

Essa separação é boa porque evita misturar mensagens para usuário com mensagens de diagnóstico. O usuário vê o processo geral; o desenvolvedor, quando necessário, consulta detalhes do conector.

## Resumo do funcionamento

Em termos simples, o projeto funciona assim:

1. A tela procura imagens na pasta `imagem`.
2. O usuário escolhe uma imagem.
3. O sistema localiza ou recebe o caminho da DLL/SO do Python.
4. O `TPythonConnector` carrega e inicializa o Python.
5. O `TCNNClassifier` verifica TensorFlow, NumPy e Pillow.
6. O modelo CNN é carregado.
7. A imagem é processada.
8. O resultado aparece como rótulo e confiança.
9. Em caso de erro, o projeto registra diagnóstico técnico suficiente para descobrir onde falhou.

## Avaliação geral

Este demo está bem mais maduro do que um exemplo simples de “chamar Python pelo Lazarus”. Ele já trata seleção de runtime, arquitetura, logs, diagnóstico, preview, validação de arquivos, dependências, carregamento de modelo e retorno estruturado de resultado. O maior valor dele é transformar uma operação complexa — rodar TensorFlow dentro de uma aplicação Lazarus — em dois componentes reutilizáveis: `TPythonConnector`, que resolve a ponte com Python, e `TCNNClassifier`, que entrega a funcionalidade prática de classificação de imagem.
