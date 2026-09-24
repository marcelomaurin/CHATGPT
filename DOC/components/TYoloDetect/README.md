# TYoloDetect

## Finalidade

`TYoloDetect` integra detecção de objetos baseada em YOLO ao projeto Lazarus.

No estado atual, deve ser tratado como componente experimental dependente de Python, modelos externos e arquivos de configuração/pesos.

## Unit

```pascal
pacote/AI/yolodetect.pas
```

## Pacote

```text
openai_core.lpk
```

## Status

```text
Experimental
```

## Propriedades principais

| Propriedade | Descrição |
|---|---|
| `ModelPath` | Caminho/nome do modelo Ultralytics (`.pt`) |
| `ConfidenceThreshold` | Confiança mínima entre 0 e 1 |
| `Device` | Dispositivo Ultralytics, por exemplo `0` ou `cpu`; vazio = automático |
| `ImageSize` | `imgsz` usado na inferência; 0 = padrão do backend |
| `PreferProcessMode` | Prefere o TPythonConnector em modo processo |
| `LastError` | Último erro |

## Métodos principais

| Método | Descrição |
|---|---|
| `Detect` | Executa detecção de objetos conforme backend disponível |
| `SelfTest` | Deve validar dependências, quando implementado |

## Exemplo

```pascal
procedure TForm1.Button1Click(Sender: TObject);
begin
  Yolo1.ModelPath := 'models/blood-seg-v1.pt';
  Yolo1.ConfidenceThreshold := 0.25;
  Yolo1.ImageSize := 1024;
  Yolo1.Device := '0';

  if Yolo1.DetectObjects('lamina.png', Objects) then
    ShowMessage(IntToStr(Length(Objects)) + ' objetos detectados')
  else
    ShowMessage(Yolo1.LastError);
end;
```

## Limitações

* Depende de Python, Ultralytics e modelo externo.
* Retorna classe, confiança e bounding box. Máscaras de segmentação ainda não são expostas pelo record `TYoloObject`.
* Modelos de segmentação funcionam para contagem porque o Ultralytics também fornece `boxes`.
* Ainda deve ser tratado como componente experimental até validação dos backends e modelos.


## Máscaras de segmentação

`TYoloObject` também possui:

```pascal
Polygon: string;
```

Para modelos YOLO Segmentation, o valor é uma sequência de coordenadas na resolução original:

```text
x:y|x:y|x:y|...
```

Para modelos sem máscara, `Polygon` permanece vazio e o consumidor pode usar `X1,Y1,X2,Y2` como fallback.


## Suporte Opcional a Keypoints / Landmarks

`TYoloObject` foi estendido com o campo:

```pascal
KeyPoints: TYoloKeyPointArray;
```

Onde cada elemento do array é um `TYoloKeyPoint`:

```pascal
type
  TYoloKeyPoint = record
    X: Double;
    Y: Double;
    Confidence: Double;
  end;
```

### Compatibilidade e Funcionamento

* Modelos tradicionais de detecção de objetos (ex: `yolov8n.pt`, `yolov8s-seg.pt`) continuam funcionando normalmente; quando o modelo não possui keypoints, o array `KeyPoints` é retornado vazio (`Length = 0`), sem lançar erro.
* Em modelos com pose ou landmarks faciais (ex: `yolov8n-face.pt` ou pose models), o script Python do componente serializa automaticamente os pontos em JSON de alta performance com fallback para formato delimitado.
* **Mapeamento de Landmarks**: A propriedade `KeyPointMapping: TYoloKeyPointMapping` permite configurar índices semânticos (ex.: `LeftEyeIndex=0`, `RightEyeIndex=1`, `NoseIndex=2`, `MouthLeftIndex=3`, `MouthRightIndex=4`), suportando modelos de 5 pontos ou customizados.
* **Funções auxiliares seguras**:
  * `HasKeyPoints(const AObject: TYoloObject): Boolean`
  * `KeyPointCount(const AObject: TYoloObject): Integer`
  * `GetKeyPoint(const AObject: TYoloObject; const AIndex: Integer; out APoint: TYoloKeyPoint): Boolean`
  * `FindLandmark(const AObject: TYoloObject; const ASemantic: TYoloLandmarkSemantic; out APoint: TYoloKeyPoint): Boolean`
