# Documentação Técnica — Lazarus AI Suite

Esta pasta contém documentação técnica orientada ao programador para os componentes da **Lazarus AI Suite / TCHATGPT**.

A documentação aqui complementa os READMEs principais do projeto e deve ser usada por quem vai instalar, testar, manter ou evoluir os componentes.

---

## Índice geral

| Área | Caminho | Descrição |
|---|---|---|
| Componentes | [`components/`](components/) | READMEs individuais por componente |
| Status oficial | [`../pacote/COMPONENT_STATUS.md`](../pacote/COMPONENT_STATUS.md) | Matriz de maturidade dos componentes |
| Pacotes Lazarus | [`../pacote/packages/`](../pacote/packages/) | Pacotes modulares `.lpk` |
| Samples | [`../pacote/samples/`](../pacote/samples/) | Projetos de demonstração |
| Workers Python | [`../pacote/python/`](../pacote/python/) | Scripts usados por componentes externos |

---

## Componentes documentados

### Core

* [TAIBaseComponent](components/TAIBaseComponent/README.md)
* [TCHATGPT](components/TCHATGPT/README.md)
* [TTokenList](components/TTokenList/README.md)
* [TAICodeAssistant](components/TAICodeAssistant/README.md)
* [TAIPromptBuilder](components/TAIPromptBuilder/README.md)
* [TAIModelRegistry](components/TAIModelRegistry/README.md)
* [TAIWizardConfig](components/TAIWizardConfig/README.md)
* [TAIProject](components/TAIProject/README.md)
* [TAIPipeline](components/TAIPipeline/README.md)

### Machine Learning / Math

* [TNeuralNetwork](components/TNeuralNetwork/README.md)
* [TPerceptron](components/TPerceptron/README.md)
* [TSOMMap](components/TSOMMap/README.md)
* [TAIDatasetGenerator](components/TAIDatasetGenerator/README.md)
* [TAMatrizComponent](components/TAMatrizComponent/README.md)
* [TNumPS](components/TNumPS/README.md)

### Graph

* [TAIGraphMap](components/TAIGraphMap/README.md)
* [TAITrainingExporter](components/TAITrainingExporter/README.md)
* [TAIDatasetAnalyzer](components/TAIDatasetAnalyzer/README.md)
* [TAITrainingReport](components/TAITrainingReport/README.md)
* [TAIGraphVisualizer](components/TAIGraphVisualizer/README.md)

### Python

* [TPythonConnector](components/TPythonConnector/README.md)
* [TYoloDetect](components/TYoloDetect/README.md)
* [TFaceDetection](components/TFaceDetection/README.md)
* [TCNNClassifier](components/TCNNClassifier/README.md)
* [TLSTMPredictor](components/TLSTMPredictor/README.md)

### Vision

* [TAIOpenCV](components/TAIOpenCV/README.md)
* [TAICameraCapture](components/TAICameraCapture/README.md)
* [TAIFrameProcessor](components/TAIFrameProcessor/README.md)
* [TAIFaceTracker](components/TAIFaceTracker/README.md)
* [TAIMotionTracker](components/TAIMotionTracker/README.md)

### Output

* [TAIOutputData](components/TAIOutputData/README.md)
* [TAIOutputDocs](components/TAIOutputDocs/README.md)
* [TAIPDFOutput](components/TAIPDFOutput/README.md)
* [TAIWordOutput](components/TAIWordOutput/README.md)
* [TAIExcelOutput](components/TAIExcelOutput/README.md)
* [TAITXTOutput](components/TAITXTOutput/README.md)

### Agent

* [TAIAgent](components/TAIAgent/README.md)
* [TAIAgentSafety](components/TAIAgentSafety/README.md)
* [TAIAgentExecutor](components/TAIAgentExecutor/README.md)

### Graphic / 3D

* [TAI3DModelViewer](components/TAI3DModelViewer/README.md)
* [TAIModel3D](components/TAIModel3D/README.md)
* [TAITripo3DClient](components/TAITripo3DClient/README.md)
* [TAIAvatar3D](components/TAIAvatar3D/README.md)
* [TAIScene3D](components/TAIScene3D/README.md)

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

## Observação

Quando um componente estiver marcado como `Placeholder`, a documentação deve explicar claramente que a estrutura existe, mas a função real ainda não está completa.
