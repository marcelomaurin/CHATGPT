unit yolodetect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pythonconnector, LResources, fpjson, jsonparser;

type
  { TYoloKeyPoint }
  TYoloKeyPoint = record
    X: Double;
    Y: Double;
    Confidence: Double;
  end;
  TYoloKeyPointArray = array of TYoloKeyPoint;

  { TYoloObject }
  TYoloObject = record
    ClassName: string;
    Confidence: Double;
    X1, Y1, X2, Y2: Integer;
    Polygon: string; // pares "x:y|x:y|..." na resolução original
    KeyPoints: TYoloKeyPointArray;
  end;
  TYoloObjectArray = array of TYoloObject;

  { TYoloLandmarkSemantic }
  TYoloLandmarkSemantic = (
    ylsUnknown,
    ylsLeftEye,
    ylsRightEye,
    ylsNose,
    ylsMouthLeft,
    ylsMouthRight,
    ylsLeftEar,
    ylsRightEar
  );

  { TYoloKeyPointMapping }
  TYoloKeyPointMapping = class(TPersistent)
  private
    FLeftEyeIndex: Integer;
    FRightEyeIndex: Integer;
    FNoseIndex: Integer;
    FMouthLeftIndex: Integer;
    FMouthRightIndex: Integer;
    FLeftEarIndex: Integer;
    FRightEarIndex: Integer;
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    procedure SetFivePointDefaults;
    procedure Clear;
    function GetIndex(const ASemantic: TYoloLandmarkSemantic): Integer;
    procedure SetIndex(const ASemantic: TYoloLandmarkSemantic; const AIndex: Integer);
  published
    property LeftEyeIndex: Integer read FLeftEyeIndex write FLeftEyeIndex default 0;
    property RightEyeIndex: Integer read FRightEyeIndex write FRightEyeIndex default 1;
    property NoseIndex: Integer read FNoseIndex write FNoseIndex default 2;
    property MouthLeftIndex: Integer read FMouthLeftIndex write FMouthLeftIndex default 3;
    property MouthRightIndex: Integer read FMouthRightIndex write FMouthRightIndex default 4;
    property LeftEarIndex: Integer read FLeftEarIndex write FLeftEarIndex default -1;
    property RightEarIndex: Integer read FRightEarIndex write FRightEarIndex default -1;
  end;

  { TYOLO }
  TYOLO = class(TComponent)
  private
    FPythonConnector: TPythonConnector;
    FLastError: string;
    FPreferProcessMode: Boolean;
    FModelPath: string;
    FConfidenceThreshold: Double;
    FDevice: string;
    FImageSize: Integer;
    FKeyPointMapping: TYoloKeyPointMapping;
    procedure SetPythonConnector(const AValue: TPythonConnector);
    procedure SetKeyPointMapping(const AValue: TYoloKeyPointMapping);
    procedure PrepareConnector;
    function ParseJsonResult(const AJsonStr: string; out AObjects: TYoloObjectArray): Boolean;
    function ParseDelimitedResult(const ATextStr: string; out AObjects: TYoloObjectArray): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function DetectObjects(const AImageFile: string; out AObjects: TYoloObjectArray): Boolean;
    function InstallDependencies: Boolean;
    function HasKeyPoints(const AObject: TYoloObject): Boolean;
    function KeyPointCount(const AObject: TYoloObject): Integer;
    function GetKeyPoint(const AObject: TYoloObject; const AIndex: Integer; out APoint: TYoloKeyPoint): Boolean;
    function FindLandmark(const AObject: TYoloObject; const ASemantic: TYoloLandmarkSemantic; out APoint: TYoloKeyPoint): Boolean;
  published
    property PythonConnector: TPythonConnector read FPythonConnector write SetPythonConnector;
    property LastError: string read FLastError;
    property PreferProcessMode: Boolean read FPreferProcessMode write FPreferProcessMode default True;
    property ModelPath: string read FModelPath write FModelPath;
    property ConfidenceThreshold: Double read FConfidenceThreshold write FConfidenceThreshold;
    property Device: string read FDevice write FDevice;
    property ImageSize: Integer read FImageSize write FImageSize default 0;
    property KeyPointMapping: TYoloKeyPointMapping read FKeyPointMapping write SetKeyPointMapping;
  end;

{ Funções auxiliares globais para consulta de keypoints }
function YoloHasKeyPoints(const AObject: TYoloObject): Boolean;
function YoloKeyPointCount(const AObject: TYoloObject): Integer;
function YoloGetKeyPoint(const AObject: TYoloObject; const AIndex: Integer; out APoint: TYoloKeyPoint): Boolean;
function YoloFindLandmark(const AObject: TYoloObject; const AMapping: TYoloKeyPointMapping;
  const ASemantic: TYoloLandmarkSemantic; out APoint: TYoloKeyPoint): Boolean;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TYOLO]);
end;

{ TYoloKeyPointMapping }

constructor TYoloKeyPointMapping.Create;
begin
  inherited Create;
  SetFivePointDefaults;
end;

procedure TYoloKeyPointMapping.Assign(Source: TPersistent);
var
  Src: TYoloKeyPointMapping;
begin
  if Source is TYoloKeyPointMapping then
  begin
    Src := TYoloKeyPointMapping(Source);
    FLeftEyeIndex := Src.LeftEyeIndex;
    FRightEyeIndex := Src.RightEyeIndex;
    FNoseIndex := Src.NoseIndex;
    FMouthLeftIndex := Src.MouthLeftIndex;
    FMouthRightIndex := Src.MouthRightIndex;
    FLeftEarIndex := Src.LeftEarIndex;
    FRightEarIndex := Src.RightEarIndex;
  end
  else
    inherited Assign(Source);
end;

procedure TYoloKeyPointMapping.SetFivePointDefaults;
begin
  FLeftEyeIndex := 0;
  FRightEyeIndex := 1;
  FNoseIndex := 2;
  FMouthLeftIndex := 3;
  FMouthRightIndex := 4;
  FLeftEarIndex := -1;
  FRightEarIndex := -1;
end;

procedure TYoloKeyPointMapping.Clear;
begin
  FLeftEyeIndex := -1;
  FRightEyeIndex := -1;
  FNoseIndex := -1;
  FMouthLeftIndex := -1;
  FMouthRightIndex := -1;
  FLeftEarIndex := -1;
  FRightEarIndex := -1;
end;

function TYoloKeyPointMapping.GetIndex(const ASemantic: TYoloLandmarkSemantic): Integer;
begin
  case ASemantic of
    ylsLeftEye: Result := FLeftEyeIndex;
    ylsRightEye: Result := FRightEyeIndex;
    ylsNose: Result := FNoseIndex;
    ylsMouthLeft: Result := FMouthLeftIndex;
    ylsMouthRight: Result := FMouthRightIndex;
    ylsLeftEar: Result := FLeftEarIndex;
    ylsRightEar: Result := FRightEarIndex;
    else Result := -1;
  end;
end;

procedure TYoloKeyPointMapping.SetIndex(const ASemantic: TYoloLandmarkSemantic; const AIndex: Integer);
begin
  case ASemantic of
    ylsLeftEye: FLeftEyeIndex := AIndex;
    ylsRightEye: FRightEyeIndex := AIndex;
    ylsNose: FNoseIndex := AIndex;
    ylsMouthLeft: FMouthLeftIndex := AIndex;
    ylsMouthRight: FMouthRightIndex := AIndex;
    ylsLeftEar: FLeftEarIndex := AIndex;
    ylsRightEar: FRightEarIndex := AIndex;
    else ;
  end;
end;

{ Funções auxiliares globais }

function YoloHasKeyPoints(const AObject: TYoloObject): Boolean;
begin
  Result := Length(AObject.KeyPoints) > 0;
end;

function YoloKeyPointCount(const AObject: TYoloObject): Integer;
begin
  Result := Length(AObject.KeyPoints);
end;

function YoloGetKeyPoint(const AObject: TYoloObject; const AIndex: Integer; out APoint: TYoloKeyPoint): Boolean;
begin
  if (AIndex >= 0) and (AIndex < Length(AObject.KeyPoints)) then
  begin
    APoint := AObject.KeyPoints[AIndex];
    Result := True;
  end
  else
  begin
    APoint.X := 0.0;
    APoint.Y := 0.0;
    APoint.Confidence := 0.0;
    Result := False;
  end;
end;

function YoloFindLandmark(const AObject: TYoloObject; const AMapping: TYoloKeyPointMapping;
  const ASemantic: TYoloLandmarkSemantic; out APoint: TYoloKeyPoint): Boolean;
var
  Idx: Integer;
begin
  Result := False;
  APoint.X := 0.0;
  APoint.Y := 0.0;
  APoint.Confidence := 0.0;
  if AMapping = nil then Exit;
  Idx := AMapping.GetIndex(ASemantic);
  if Idx < 0 then Exit;
  Result := YoloGetKeyPoint(AObject, Idx, APoint);
end;

{ TYOLO }

constructor TYOLO.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPythonConnector := nil;
  FLastError := '';
  FPreferProcessMode := True;
  FModelPath := 'yolov8n.pt';
  FConfidenceThreshold := 0.25;
  FDevice := '';
  FImageSize := 0;
  FKeyPointMapping := TYoloKeyPointMapping.Create;
  FKeyPointMapping.SetFivePointDefaults;
end;

destructor TYOLO.Destroy;
begin
  FreeAndNil(FKeyPointMapping);
  inherited Destroy;
end;

procedure TYOLO.SetKeyPointMapping(const AValue: TYoloKeyPointMapping);
begin
  if FKeyPointMapping <> nil then
    FKeyPointMapping.Assign(AValue);
end;

function TYOLO.HasKeyPoints(const AObject: TYoloObject): Boolean;
begin
  Result := YoloHasKeyPoints(AObject);
end;

function TYOLO.KeyPointCount(const AObject: TYoloObject): Integer;
begin
  Result := YoloKeyPointCount(AObject);
end;

function TYOLO.GetKeyPoint(const AObject: TYoloObject; const AIndex: Integer; out APoint: TYoloKeyPoint): Boolean;
begin
  Result := YoloGetKeyPoint(AObject, AIndex, APoint);
end;

function TYOLO.FindLandmark(const AObject: TYoloObject; const ASemantic: TYoloLandmarkSemantic; out APoint: TYoloKeyPoint): Boolean;
begin
  Result := YoloFindLandmark(AObject, FKeyPointMapping, ASemantic, APoint);
end;

procedure TYOLO.PrepareConnector;
begin
  if (FPythonConnector <> nil) and not FPythonConnector.Active and FPreferProcessMode then
  begin
    FPythonConnector.ExecutionMode := pemProcess;
  end;
end;

procedure TYOLO.SetPythonConnector(const AValue: TPythonConnector);
begin
  if FPythonConnector = AValue then Exit;
  FPythonConnector := AValue;
  if FPythonConnector <> nil then
  begin
    FPythonConnector.FreeNotification(Self);
    PrepareConnector;
  end;
end;

procedure TYOLO.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPythonConnector) then
    FPythonConnector := nil;
end;

function TYOLO.InstallDependencies: Boolean;
begin
  Result := False;
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  PrepareConnector;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError := 'O interpretador Python não está ativo/inicializado.';
    Exit;
  end;

  Result := FPythonConnector.ExecString(
    'import subprocess, sys' + sLineBreak +
    'try:' + sLineBreak +
    '    subprocess.check_call([sys.executable, "-m", "pip", "install", "ultralytics"])' + sLineBreak +
    '    dep_success = True' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    dep_success = False' + sLineBreak +
    '    dep_error = str(e)'
  );

  if not Result then
    FLastError := FPythonConnector.LastError
  else
  begin
    if FPythonConnector.GetVar('dep_success') <> 'True' then
    begin
      FLastError := FPythonConnector.GetVar('dep_error');
      Result := False;
    end
    else
      Result := True;
  end;
end;

function TYOLO.ParseJsonResult(const AJsonStr: string; out AObjects: TYoloObjectArray): Boolean;
var
  Data: TJSONData;
  Arr: TJSONArray;
  ItemObj: TJSONObject;
  BBoxArr, KPArr: TJSONArray;
  KpItem: TJSONObject;
  i, j: Integer;
begin
  Result := False;
  SetLength(AObjects, 0);
  try
    Data := GetJSON(AJsonStr);
    if Data = nil then Exit;
    try
      if Data.JSONType <> jtArray then Exit;
      Arr := TJSONArray(Data);
      SetLength(AObjects, Arr.Count);
      for i := 0 to Arr.Count - 1 do
      begin
        if Arr.Types[i] = jtObject then
        begin
          ItemObj := TJSONObject(Arr.Items[i]);
          AObjects[i].ClassName := ItemObj.Get('class', '');
          AObjects[i].Confidence := ItemObj.Get('confidence', 0.0);
          AObjects[i].Polygon := ItemObj.Get('polygon', '');

          if ItemObj.Find('bbox') <> nil then
          begin
            BBoxArr := ItemObj.Arrays['bbox'];
            if BBoxArr.Count >= 4 then
            begin
              AObjects[i].X1 := BBoxArr.Integers[0];
              AObjects[i].Y1 := BBoxArr.Integers[1];
              AObjects[i].X2 := BBoxArr.Integers[2];
              AObjects[i].Y2 := BBoxArr.Integers[3];
            end;
          end;

          SetLength(AObjects[i].KeyPoints, 0);
          if ItemObj.Find('keypoints') <> nil then
          begin
            KPArr := ItemObj.Arrays['keypoints'];
            SetLength(AObjects[i].KeyPoints, KPArr.Count);
            for j := 0 to KPArr.Count - 1 do
            begin
              if KPArr.Types[j] = jtObject then
              begin
                KpItem := TJSONObject(KPArr.Items[j]);
                AObjects[i].KeyPoints[j].X := KpItem.Get('x', 0.0);
                AObjects[i].KeyPoints[j].Y := KpItem.Get('y', 0.0);
                AObjects[i].KeyPoints[j].Confidence := KpItem.Get('conf', 1.0);
              end;
            end;
          end;
        end;
      end;
      Result := True;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Erro ao interpretar JSON YOLO: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TYOLO.ParseDelimitedResult(const ATextStr: string; out AObjects: TYoloObjectArray): Boolean;
var
  Rows, Parts: TStringList;
  i: Integer;
  FS: TFormatSettings;
begin
  Result := False;
  SetLength(AObjects, 0);
  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';

  Rows := TStringList.Create;
  Parts := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(ATextStr), Rows);
    SetLength(AObjects, Rows.Count);
    for i := 0 to Rows.Count - 1 do
    begin
      Parts.Clear;
      ExtractStrings([','], [], PChar(Rows[i]), Parts);
      if Parts.Count >= 6 then
      begin
        AObjects[i].ClassName := Parts[0];
        AObjects[i].Confidence := StrToFloatDef(Parts[1], 0.0, FS);
        AObjects[i].X1 := StrToIntDef(Parts[2], 0);
        AObjects[i].Y1 := StrToIntDef(Parts[3], 0);
        AObjects[i].X2 := StrToIntDef(Parts[4], 0);
        AObjects[i].Y2 := StrToIntDef(Parts[5], 0);
        if Parts.Count >= 7 then
          AObjects[i].Polygon := Parts[6]
        else
          AObjects[i].Polygon := '';
        SetLength(AObjects[i].KeyPoints, 0);
      end;
    end;
    Result := True;
  finally
    Rows.Free;
    Parts.Free;
  end;
end;

function TYOLO.DetectObjects(const AImageFile: string; out AObjects: TYoloObjectArray): Boolean;
var
  PyScript: string;
  ResultStr: string;
  EscapedPath, EscapedModel, EscapedDevice: string;
  FS: TFormatSettings;
  ConfidenceText: string;
  TrimmedResult: string;
begin
  Result := False;
  SetLength(AObjects, 0);
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

  PrepareConnector;

  if not FPythonConnector.IsInitialized then
  begin
    FLastError := 'O interpretador Python não está ativo/inicializado.';
    Exit;
  end;

  if not FileExists(AImageFile) then
  begin
    FLastError := 'Arquivo de imagem não encontrado: ' + AImageFile;
    Exit;
  end;

  if Trim(FModelPath) = '' then
  begin
    FLastError := 'ModelPath não foi informado.';
    Exit;
  end;

  if (FConfidenceThreshold < 0.0) or (FConfidenceThreshold > 1.0) then
  begin
    FLastError := 'ConfidenceThreshold deve estar entre 0 e 1.';
    Exit;
  end;

  EscapedPath := StringReplace(AImageFile, '\', '\\', [rfReplaceAll]);
  EscapedPath := StringReplace(EscapedPath, '"', '\"', [rfReplaceAll]);
  EscapedModel := StringReplace(FModelPath, '\', '\\', [rfReplaceAll]);
  EscapedModel := StringReplace(EscapedModel, '"', '\"', [rfReplaceAll]);
  EscapedDevice := StringReplace(FDevice, '\', '\\', [rfReplaceAll]);
  EscapedDevice := StringReplace(EscapedDevice, '"', '\"', [rfReplaceAll]);

  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  ConfidenceText := FloatToStr(FConfidenceThreshold, FS);

  PyScript :=
    'import json' + sLineBreak +
    'from ultralytics import YOLO' + sLineBreak +
    'try:' + sLineBreak +
    '    model = YOLO(r"' + EscapedModel + '")' + sLineBreak +
    '    predict_args = {"source": r"' + EscapedPath + '", "conf": ' +
      ConfidenceText + ', "verbose": False}' + sLineBreak;

  if Trim(FDevice) <> '' then
    PyScript := PyScript +
      '    predict_args["device"] = r"' + EscapedDevice + '"' + sLineBreak;

  if FImageSize > 0 then
    PyScript := PyScript +
      '    predict_args["imgsz"] = ' + IntToStr(FImageSize) + sLineBreak;

  PyScript := PyScript +
    '    results = model.predict(**predict_args)' + sLineBreak +
    '    obj_list = []' + sLineBreak +
    '    for r in results:' + sLineBreak +
    '        if r.boxes is None:' + sLineBreak +
    '            continue' + sLineBreak +
    '        mask_xy = r.masks.xy if (getattr(r, "masks", None) is not None and r.masks is not None) else []' + sLineBreak +
    '        kpts_xy = None' + sLineBreak +
    '        kpts_conf = None' + sLineBreak +
    '        if getattr(r, "keypoints", None) is not None and r.keypoints is not None:' + sLineBreak +
    '            if getattr(r.keypoints, "xy", None) is not None:' + sLineBreak +
    '                kpts_xy = r.keypoints.xy.tolist()' + sLineBreak +
    '            if getattr(r.keypoints, "conf", None) is not None and r.keypoints.conf is not None:' + sLineBreak +
    '                kpts_conf = r.keypoints.conf.tolist()' + sLineBreak +
    '        for idx, box in enumerate(r.boxes):' + sLineBreak +
    '            cls_id = int(box.cls[0])' + sLineBreak +
    '            cls_name = model.names[cls_id]' + sLineBreak +
    '            conf = float(box.conf[0])' + sLineBreak +
    '            xyxy = box.xyxy[0].tolist() if hasattr(box.xyxy[0], "tolist") else list(box.xyxy[0])' + sLineBreak +
    '            polygon = ""' + sLineBreak +
    '            if idx < len(mask_xy):' + sLineBreak +
    '                polygon = "|".join(f"{int(p[0])}:{int(p[1])}" for p in mask_xy[idx])' + sLineBreak +
    '            kpts = []' + sLineBreak +
    '            if kpts_xy is not None and idx < len(kpts_xy):' + sLineBreak +
    '                for k_idx, pt in enumerate(kpts_xy[idx]):' + sLineBreak +
    '                    k_conf = 1.0' + sLineBreak +
    '                    if kpts_conf is not None and idx < len(kpts_conf) and k_idx < len(kpts_conf[idx]):' + sLineBreak +
    '                        k_conf = float(kpts_conf[idx][k_idx])' + sLineBreak +
    '                    kpts.append({"x": float(pt[0]), "y": float(pt[1]), "conf": round(k_conf, 4)})' + sLineBreak +
    '            obj_list.append({' + sLineBreak +
    '                "class": cls_name,' + sLineBreak +
    '                "confidence": round(conf, 4),' + sLineBreak +
    '                "bbox": [int(xyxy[0]), int(xyxy[1]), int(xyxy[2]), int(xyxy[3])],' + sLineBreak +
    '                "polygon": polygon,' + sLineBreak +
    '                "keypoints": kpts' + sLineBreak +
    '            })' + sLineBreak +
    '    yolo_result = json.dumps(obj_list)' + sLineBreak +
    '    yolo_success = True' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    yolo_result = str(e)' + sLineBreak +
    '    yolo_success = False';

  if not FPythonConnector.ExecString(PyScript) then
  begin
    FLastError := 'Erro na execução do script do Python: ' + FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('yolo_success') <> 'True' then
  begin
    FLastError := 'Falha no processamento YOLO: ' + FPythonConnector.GetVar('yolo_result');
    Exit;
  end;

  ResultStr := FPythonConnector.GetVar('yolo_result');
  TrimmedResult := Trim(ResultStr);
  if (TrimmedResult = '') or (TrimmedResult = '[]') then
  begin
    Result := True;
    Exit;
  end;

  // Tenta parsear formato JSON moderno
  if (Length(TrimmedResult) > 0) and (TrimmedResult[1] = '[') then
  begin
    if ParseJsonResult(TrimmedResult, AObjects) then
    begin
      Result := True;
      Exit;
    end;
  end;

  // Fallback para delimitado clássico caso JSON falhe ou seja legado
  Result := ParseDelimitedResult(TrimmedResult, AObjects);
end;

initialization
  {$I yolodetect_icon.lrs}

end.
