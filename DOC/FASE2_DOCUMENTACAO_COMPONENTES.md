# Fase 2 - Documentacao dos Componentes

A Fase 2 tem como objetivo transformar a documentacao tecnica em uma referencia confiavel para programadores.

## Regra principal

Cada componente deve possuir um README individual em:

```text
DOC/components/<NomeDoComponente>/README.md
```

Cada README deve conter:

- finalidade;
- pacote Lazarus;
- unit de origem;
- status de maturidade;
- propriedades principais;
- metodos principais;
- eventos, quando existirem;
- dependencias;
- exemplo minimo;
- sample relacionado, quando existir;
- limitacoes;
- compatibilidade por plataforma.

## Pendencias principais

### 1. Sincronizar status

O status em `DOC/components/README.md`, `pacote/COMPONENT_STATUS.md` e nos READMEs individuais deve ser igual.

Exemplo de divergencia atual:

- o README individual informa Beta parcial;
- a matriz oficial informa Experimental.

### 2. Atualizar componentes Vision

A documentacao da area Vision precisa refletir os novos componentes nativos:

- TAIImageInfo;
- TAIFrameBuffer;
- TAINativeImageFilter;
- TAIFrameDiff;
- TAIFaceTracker;
- TAIMotionTracker.

### 3. Incluir runtime por plataforma nos componentes Python

Componentes que dependem de Python devem documentar:

- uso futuro/esperado de `TAIPythonRuntime`;
- Windows moderno;
- Windows 7 x86/x64;
- Linux x64;
- Linux ARM64/ARMHF;
- dependencias por perfil;
- limitacoes de versao.

Componentes afetados:

- TPythonConnector;
- TAIOpenCV;
- TYoloDetect;
- TFaceDetection;
- TCNNClassifier;
- TLSTMPredictor.

### 4. Marcar claramente o que e real, beta, experimental ou placeholder

Quando a funcao existir apenas como estrutura, o README deve dizer isso explicitamente.

Quando a funcao estiver funcional somente em uma plataforma, o README deve dizer em qual plataforma foi validada.

### 5. Melhorar documentacao de samples

Cada sample relevante deve ter:

- README.md;
- objetivo;
- componentes usados;
- dependencias;
- como compilar;
- como executar;
- screenshot, quando possivel;
- executavel demo, quando fizer sentido.

### 6. Documentar saidas reais

Componentes de Output devem informar claramente se geram:

- PDF real;
- TXT real;
- HTML compativel com Word/Excel;
- DOCX/XLSX real, se um dia existir.

### 7. Criar matriz de compatibilidade

Criar documento com suporte por plataforma:

```text
DOC/COMPATIBILIDADE.md
```

Com colunas:

- componente;
- Windows x64;
- Windows 7 x86;
- Windows 7 x64;
- Linux x64;
- Linux ARM64;
- Linux ARMHF;
- dependencias;
- status.

## Prioridade recomendada

1. Corrigir divergencias de status.
2. Atualizar indice `DOC/components/README.md`.
3. Atualizar READMEs dos componentes Python.
4. Atualizar READMEs dos componentes Vision.
5. Revisar Output.
6. Criar `DOC/COMPATIBILIDADE.md`.
7. Revisar samples e incluir executaveis somente onde for util.