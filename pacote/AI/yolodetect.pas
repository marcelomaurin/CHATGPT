unit yolodetect;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pythonconnector, LResources;

type
  TYoloObject = record
    ClassName: string;
    Confidence: Double;
    X1, Y1, X2, Y2: Integer;
    Polygon: string; // pares "x:y|x:y|..." na resolução original
  end;
  TYoloObjectArray = array of TYoloObject;

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
    procedure SetPythonConnector(const AValue: TPythonConnector);
    procedure PrepareConnector;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function DetectObjects(const AImageFile: string; out AObjects: TYoloObjectArray): Boolean;
    function InstallDependencies: Boolean;
  published
    property PythonConnector: TPythonConnector read FPythonConnector write SetPythonConnector;
    property LastError: string read FLastError;
    property PreferProcessMode: Boolean read FPreferProcessMode write FPreferProcessMode default True;
    property ModelPath: string read FModelPath write FModelPath;
    property ConfidenceThreshold: Double read FConfidenceThreshold write FConfidenceThreshold;
    property Device: string read FDevice write FDevice;
    property ImageSize: Integer read FImageSize write FImageSize default 0;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TYOLO]);
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

  // Executa pip install de dentro do Python utilizando subprocess
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

function TYOLO.DetectObjects(const AImageFile: string; out AObjects: TYoloObjectArray): Boolean;
var
  PyScript: string;
  ResultStr: string;
  Rows, Parts: TStringList;
  i: Integer;
  EscapedPath, EscapedModel, EscapedDevice: string;
  FS: TFormatSettings;
  ConfidenceText: string;
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
    '        mask_xy = r.masks.xy if r.masks is not None else []' + sLineBreak +
    '        for idx, box in enumerate(r.boxes):' + sLineBreak +
    '            cls_id = int(box.cls[0])' + sLineBreak +
    '            cls_name = model.names[cls_id]' + sLineBreak +
    '            conf = float(box.conf[0])' + sLineBreak +
    '            xyxy = box.xyxy[0]' + sLineBreak +
    '            polygon = ""' + sLineBreak +
    '            if idx < len(mask_xy):' + sLineBreak +
    '                polygon = "|".join(f"{int(p[0])}:{int(p[1])}" for p in mask_xy[idx])' + sLineBreak +
    '            obj_list.append(f"{cls_name},{conf:.4f},{int(xyxy[0])},{int(xyxy[1])},{int(xyxy[2])},{int(xyxy[3])},{polygon}")' + sLineBreak +
    '    yolo_result = ";".join(obj_list)' + sLineBreak +
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
  if ResultStr = '' then
  begin
    Result := True;
    Exit;
  end;

  Rows := TStringList.Create;
  Parts := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(ResultStr), Rows);
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
      end;
    end;
    Result := True;
  finally
    Rows.Free;
    Parts.Free;
  end;
end;

initialization
  {$I yolodetect_icon.lrs}

end.
