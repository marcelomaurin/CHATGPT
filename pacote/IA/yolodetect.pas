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
  end;
  TYoloObjectArray = array of TYoloObject;

  { TYOLO }

  TYOLO = class(TComponent)
  private
    FPythonConnector: TPythonConnector;
    FLastError: string;
    procedure SetPythonConnector(const AValue: TPythonConnector);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function DetectObjects(const AImageFile: string; out AObjects: TYoloObjectArray): Boolean;
    function InstallDependencies: Boolean;
  published
    property PythonConnector: TPythonConnector read FPythonConnector write SetPythonConnector;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TYOLO]);
end;

{ TYOLO }

constructor TYOLO.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPythonConnector := nil;
  FLastError := '';
end;

procedure TYOLO.SetPythonConnector(const AValue: TPythonConnector);
begin
  if FPythonConnector = AValue then Exit;
  FPythonConnector := AValue;
  if FPythonConnector <> nil then
    FPythonConnector.FreeNotification(Self);
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
  EscapedPath: string;
begin
  Result := False;
  SetLength(AObjects, 0);
  FLastError := '';

  if FPythonConnector = nil then
  begin
    FLastError := 'PythonConnector não associado ao componente.';
    Exit;
  end;

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

  // Escapa barras invertidas no caminho do arquivo para o Python
  EscapedPath := StringReplace(AImageFile, '\', '\\', [rfReplaceAll]);

  // Script para detecção de objetos via ultralytics YOLOv8
  PyScript :=
    'from ultralytics import YOLO' + sLineBreak +
    'try:' + sLineBreak +
    '    model = YOLO("yolov8n.pt")' + sLineBreak +
    '    results = model(r"' + EscapedPath + '")' + sLineBreak +
    '    obj_list = []' + sLineBreak +
    '    for r in results:' + sLineBreak +
    '        for box in r.boxes:' + sLineBreak +
    '            cls_id = int(box.cls[0])' + sLineBreak +
    '            cls_name = model.names[cls_id]' + sLineBreak +
    '            conf = float(box.conf[0])' + sLineBreak +
    '            xyxy = box.xyxy[0]' + sLineBreak +
    '            obj_list.append(f"{cls_name},{conf:.4f},{int(xyxy[0])},{int(xyxy[1])},{int(xyxy[2])},{int(xyxy[3])}")' + sLineBreak +
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
    Result := True; // Sucesso, mas 0 objetos encontrados
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
        AObjects[i].Confidence := StrToFloatDef(Parts[1], 0.0);
        AObjects[i].X1 := StrToIntDef(Parts[2], 0);
        AObjects[i].Y1 := StrToIntDef(Parts[3], 0);
        AObjects[i].X2 := StrToIntDef(Parts[4], 0);
        AObjects[i].Y2 := StrToIntDef(Parts[5], 0);
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
