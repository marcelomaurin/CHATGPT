unit aif5ttsengine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiprocessrunner, aivoiceclonetypes, LResources;

type
  TAIF5TTSProcessEngine = class(TAIBaseComponent, IAIVoiceCloneEngine)
  private
    FPythonPath: string;
    FF5TTSPath: string;
    FModelPath: string;
    FUseGPU: Boolean;
    FTimeoutMs: Integer;
    FRunner: TAIProcessRunner;
    FLastStdOut: string;
    FLastStdErr: string;
    FLastExitCode: Integer;
    function ResolveExecutable: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ValidatePython(out AError: string): Boolean;
    function ValidateF5TTS(out AError: string): Boolean;
    procedure BuildSynthesisArguments(AProfile: TAIVoiceProfile;
      const AText, AOutputFile: string; AArgs: TStrings);
    function CreateVoice(AProfile: TAIVoiceProfile; out AError: string): Boolean;
    function Synthesize(AProfile: TAIVoiceProfile; const AText,
      AOutputFile: string; out ARealOutputFile, AError: string): Boolean;
    procedure Cancel;
    property LastStdOut: string read FLastStdOut;
    property LastStdErr: string read FLastStdErr;
    property LastExitCode: Integer read FLastExitCode;
  published
    property PythonPath: string read FPythonPath write FPythonPath;
    property F5TTSPath: string read FF5TTSPath write FF5TTSPath;
    property ModelPath: string read FModelPath write FModelPath;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 300000;
  end;

procedure Register;

implementation

procedure Register;
begin RegisterComponents('AI Voice', [TAIF5TTSProcessEngine]); end;

constructor TAIF5TTSProcessEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FUseGPU := False;
  FTimeoutMs := 300000;
  FLastExitCode := -1;
  FRunner := TAIProcessRunner.Create(nil);
end;

destructor TAIF5TTSProcessEngine.Destroy;
begin FRunner.Free; inherited Destroy; end;

function FindExecutable(const AValue: string): Boolean;
begin
  Result := FileExists(AValue) or
    ((ExtractFilePath(AValue) = '') and (FileSearch(AValue,
      GetEnvironmentVariable('PATH')) <> ''));
end;

function SizeOfFile(const AFileName: string): Int64;
var S: TFileStream;
begin
  Result := -1;
  if not FileExists(AFileName) then Exit;
  S := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try Result := S.Size; finally S.Free; end;
end;

function TAIF5TTSProcessEngine.ValidatePython(out AError: string): Boolean;
begin
  AError := '';
  Result := (Trim(FPythonPath) <> '') and FindExecutable(FPythonPath);
  if not Result then AError := 'Executavel Python nao encontrado: ' + FPythonPath;
end;

function TAIF5TTSProcessEngine.ValidateF5TTS(out AError: string): Boolean;
begin
  AError := '';
  Result := (Trim(FF5TTSPath) <> '') and FileExists(FF5TTSPath);
  if not Result then AError := 'Entrypoint F5-TTS nao encontrado: ' + FF5TTSPath;
end;

function TAIF5TTSProcessEngine.ResolveExecutable: string;
begin
  if SameText(ExtractFileExt(FF5TTSPath), '.py') then Result := FPythonPath
  else Result := FF5TTSPath;
end;

procedure TAIF5TTSProcessEngine.BuildSynthesisArguments(
  AProfile: TAIVoiceProfile; const AText, AOutputFile: string; AArgs: TStrings);
var ModelValue: string;
begin
  AArgs.Clear;
  if SameText(ExtractFileExt(FF5TTSPath), '.py') then AArgs.Add(FF5TTSPath);
  AArgs.Add('--ref_audio'); AArgs.Add(AProfile.ReferenceAudio);
  AArgs.Add('--gen_text'); AArgs.Add(AText);
  AArgs.Add('--output_file'); AArgs.Add(ExpandFileName(AOutputFile));
  ModelValue := AProfile.Model;
  if ModelValue = '' then ModelValue := FModelPath;
  if ModelValue <> '' then begin AArgs.Add('--model'); AArgs.Add(ModelValue); end;
  if AProfile.Language <> '' then begin AArgs.Add('--language'); AArgs.Add(AProfile.Language); end;
  AArgs.Add('--device'); if FUseGPU then AArgs.Add('cuda') else AArgs.Add('cpu');
end;

function TAIF5TTSProcessEngine.CreateVoice(AProfile: TAIVoiceProfile;
  out AError: string): Boolean;
begin
  Result := False; AError := '';
  if AProfile = nil then begin AError := 'Perfil de voz nulo.'; Exit; end;
  if not ValidatePython(AError) then begin SetError(AError); Exit; end;
  if not ValidateF5TTS(AError) then begin SetError(AError); Exit; end;
  if not FileExists(AProfile.ReferenceAudio) then
  begin AError := 'Audio de referencia nao encontrado: ' + AProfile.ReferenceAudio; SetError(AError); Exit; end;
  if (AProfile.Model <> '') and (ExtractFilePath(AProfile.Model) <> '') and
    not FileExists(AProfile.Model) then
  begin AError := 'Modelo F5-TTS nao encontrado: ' + AProfile.Model; SetError(AError); Exit; end;
  ClearError;
  Result := True;
end;

function TAIF5TTSProcessEngine.Synthesize(AProfile: TAIVoiceProfile;
  const AText, AOutputFile: string; out ARealOutputFile, AError: string): Boolean;
var
  Args: TStringList;
  Params: array of string;
  I: Integer;
begin
  Result := False; ARealOutputFile := ''; AError := '';
  if not CreateVoice(AProfile, AError) then Exit;
  if Trim(AText) = '' then begin AError := 'Texto para sintese esta vazio.'; SetError(AError); Exit; end;
  if Trim(AOutputFile) = '' then begin AError := 'OutputFile esta vazio.'; SetError(AError); Exit; end;
  ForceDirectories(ExtractFileDir(ExpandFileName(AOutputFile)));
  Args := TStringList.Create;
  try
    BuildSynthesisArguments(AProfile, AText, AOutputFile, Args);
    SetLength(Params, Args.Count);
    for I := 0 to Args.Count - 1 do Params[I] := Args[I];
    FRunner.Executable := ResolveExecutable;
    FRunner.WorkingDirectory := ExtractFilePath(FF5TTSPath);
    FRunner.TimeoutMs := FTimeoutMs;
    Result := FRunner.Execute(Params);
    FLastStdOut := FRunner.StdOutText;
    FLastStdErr := FRunner.StdErrText;
    FLastExitCode := FRunner.LastExitCode;
    if not Result then
    begin AError := FRunner.LastError; if AError = '' then AError := Trim(FLastStdErr); SetError(AError); Exit; end;
    ARealOutputFile := ExpandFileName(AOutputFile);
    Result := FileExists(ARealOutputFile) and (SizeOfFile(ARealOutputFile) > 44);
    if not Result then
    begin AError := 'F5-TTS terminou sem gerar WAV valido: ' + ARealOutputFile; SetError(AError); ARealOutputFile := ''; Exit; end;
    FLastResult := ARealOutputFile;
    FLastSuccess := True;
    ClearError;
  finally Args.Free; end;
end;

procedure TAIF5TTSProcessEngine.Cancel;
begin FRunner.Stop; end;

end.
