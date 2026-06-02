unit facedetection;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, pythonconnector, LResources;

type
  TFaceRect = record
    X, Y, Width, Height: Integer;
  end;
  TFaceRectArray = array of TFaceRect;

  { TFaceDetection }

  TFaceDetection = class(TComponent)
  private
    FPythonConnector: TPythonConnector;
    FLastError: string;
    procedure SetPythonConnector(const AValue: TPythonConnector);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function DetectFaces(const AImageFile: string; out AFaces: TFaceRectArray): Boolean;
    function InstallDependencies: Boolean;
  published
    property PythonConnector: TPythonConnector read FPythonConnector write SetPythonConnector;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TFaceDetection]);
end;

{ TFaceDetection }

constructor TFaceDetection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPythonConnector := nil;
  FLastError := '';
end;

procedure TFaceDetection.SetPythonConnector(const AValue: TPythonConnector);
begin
  if FPythonConnector = AValue then Exit;
  FPythonConnector := AValue;
  if FPythonConnector <> nil then
    FPythonConnector.FreeNotification(Self);
end;

procedure TFaceDetection.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FPythonConnector) then
    FPythonConnector := nil;
end;

function TFaceDetection.InstallDependencies: Boolean;
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
    '    subprocess.check_call([sys.executable, "-m", "pip", "install", "opencv-python"])' + sLineBreak +
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

function TFaceDetection.DetectFaces(const AImageFile: string; out AFaces: TFaceRectArray): Boolean;
var
  PyScript: string;
  ResultStr: string;
  Rows, Parts: TStringList;
  i: Integer;
  EscapedPath: string;
begin
  Result := False;
  SetLength(AFaces, 0);
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

  // Script para detecção de faces via OpenCV usando Haar Cascade padrão
  PyScript :=
    'import cv2' + sLineBreak +
    'try:' + sLineBreak +
    '    img = cv2.imread(r"' + EscapedPath + '")' + sLineBreak +
    '    if img is None:' + sLineBreak +
    '        raise Exception("Não foi possível carregar a imagem via OpenCV (imread).")' + sLineBreak +
    '    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)' + sLineBreak +
    '    face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + "haarcascade_frontalface_default.xml")' + sLineBreak +
    '    faces = face_cascade.detectMultiScale(gray, 1.1, 4)' + sLineBreak +
    '    face_list = [f"{f[0]},{f[1]},{f[2]},{f[3]}" for f in faces]' + sLineBreak +
    '    face_result = ";".join(face_list)' + sLineBreak +
    '    face_success = True' + sLineBreak +
    'except Exception as e:' + sLineBreak +
    '    face_result = str(e)' + sLineBreak +
    '    face_success = False';

  if not FPythonConnector.ExecString(PyScript) then
  begin
    FLastError := 'Erro na execução do script do Python: ' + FPythonConnector.LastError;
    Exit;
  end;

  if FPythonConnector.GetVar('face_success') <> 'True' then
  begin
    FLastError := 'Falha no processamento OpenCV: ' + FPythonConnector.GetVar('face_result');
    Exit;
  end;

  ResultStr := FPythonConnector.GetVar('face_result');
  if ResultStr = '' then
  begin
    Result := True; // Sucesso, mas 0 faces encontradas
    Exit;
  end;

  Rows := TStringList.Create;
  Parts := TStringList.Create;
  try
    ExtractStrings([';'], [], PChar(ResultStr), Rows);
    SetLength(AFaces, Rows.Count);
    for i := 0 to Rows.Count - 1 do
    begin
      Parts.Clear;
      ExtractStrings([','], [], PChar(Rows[i]), Parts);
      if Parts.Count >= 4 then
      begin
        AFaces[i].X := StrToIntDef(Parts[0], 0);
        AFaces[i].Y := StrToIntDef(Parts[1], 0);
        AFaces[i].Width := StrToIntDef(Parts[2], 0);
        AFaces[i].Height := StrToIntDef(Parts[3], 0);
      end;
    end;
    Result := True;
  finally
    Rows.Free;
    Parts.Free;
  end;
end;

initialization
  {$I facedetection_icon.lrs}

end.
