unit aiwhisperengine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiprocessrunner, aispeechtypes, LResources;

type
  TAIWhisperProcessEngine = class(TAIBaseComponent, IAISpeechRecognitionEngine)
  private
    FExecutablePath: string;
    FModelPath: string;
    FUseGPU: Boolean;
    FThreads: Integer;
    FTimeoutMs: Integer;
    FRunner: TAIProcessRunner;
    FLastStdOut: string;
    FLastStdErr: string;
    FLastExitCode: Integer;
    function CleanOutput(const AOutput: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function ValidateExecutable(out AError: string): Boolean;
    function ValidateModel(out AError: string): Boolean;
    procedure BuildCommandArguments(const AAudioFile, ALanguage: string;
      AUseGPU: Boolean; AThreads: Integer; AArgs: TStrings);
    function LoadModel(const AModelPath: string; AUseGPU: Boolean;
      AThreads: Integer; out AError: string): Boolean;
    function TranscribeFile(const AFileName, ALanguage: string;
      out AText, AError: string): Boolean;
    procedure Cancel;
    property LastStdOut: string read FLastStdOut;
    property LastStdErr: string read FLastStdErr;
    property LastExitCode: Integer read FLastExitCode;
  published
    property ExecutablePath: string read FExecutablePath write FExecutablePath;
    property ModelPath: string read FModelPath write FModelPath;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property Threads: Integer read FThreads write FThreads default 0;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 120000;
  end;

procedure Register;

implementation

procedure Register;
begin RegisterComponents('AI Voice', [TAIWhisperProcessEngine]); end;

constructor TAIWhisperProcessEngine.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FUseGPU := False;
  FThreads := 0;
  FTimeoutMs := 120000;
  FLastExitCode := -1;
  FRunner := TAIProcessRunner.Create(nil);
end;

destructor TAIWhisperProcessEngine.Destroy;
begin FRunner.Free; inherited Destroy; end;

function TAIWhisperProcessEngine.ValidateExecutable(out AError: string): Boolean;
begin
  AError := '';
  Result := (Trim(FExecutablePath) <> '') and FileExists(FExecutablePath);
  if not Result then AError := 'whisper-cli nao encontrado: ' + FExecutablePath;
end;

function TAIWhisperProcessEngine.ValidateModel(out AError: string): Boolean;
begin
  AError := '';
  Result := (Trim(FModelPath) <> '') and FileExists(FModelPath);
  if not Result then AError := 'Modelo Whisper nao encontrado: ' + FModelPath;
end;

procedure TAIWhisperProcessEngine.BuildCommandArguments(const AAudioFile,
  ALanguage: string; AUseGPU: Boolean; AThreads: Integer; AArgs: TStrings);
begin
  AArgs.Clear;
  AArgs.Add('-m'); AArgs.Add(FModelPath);
  AArgs.Add('-f'); AArgs.Add(AAudioFile);
  if Trim(ALanguage) <> '' then begin AArgs.Add('-l'); AArgs.Add(ALanguage); end;
  if AThreads > 0 then begin AArgs.Add('-t'); AArgs.Add(IntToStr(AThreads)); end;
  if not AUseGPU then AArgs.Add('--no-gpu');
  AArgs.Add('--no-timestamps');
end;

function TAIWhisperProcessEngine.LoadModel(const AModelPath: string;
  AUseGPU: Boolean; AThreads: Integer; out AError: string): Boolean;
begin
  if Trim(AModelPath) <> '' then FModelPath := AModelPath;
  FUseGPU := AUseGPU;
  FThreads := AThreads;
  Result := ValidateExecutable(AError) and ValidateModel(AError);
  if not Result then SetError(AError) else ClearError;
end;

function TAIWhisperProcessEngine.CleanOutput(const AOutput: string): string;
var
  Lines: TStringList;
  I, P: Integer;
  S: string;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    Lines.Text := AOutput;
    for I := 0 to Lines.Count - 1 do
    begin
      S := Trim(Lines[I]);
      if (S <> '') and (S[1] = '[') then
      begin P := Pos(']', S); if P > 0 then S := Trim(Copy(S, P + 1, MaxInt)); end;
      if (S = '') or (Pos('whisper_', LowerCase(S)) = 1) or
        (Pos('system_info', LowerCase(S)) = 1) then Continue;
      if Result <> '' then Result := Result + ' ';
      Result := Result + S;
    end;
  finally Lines.Free; end;
end;

function TAIWhisperProcessEngine.TranscribeFile(const AFileName,
  ALanguage: string; out AText, AError: string): Boolean;
var
  Args: TStringList;
  Params: array of string;
  I: Integer;
begin
  Result := False;
  AText := '';
  AError := '';
  if not ValidateExecutable(AError) then begin SetError(AError); Exit; end;
  if not ValidateModel(AError) then begin SetError(AError); Exit; end;
  if not FileExists(AFileName) then
  begin AError := 'Arquivo de audio nao encontrado: ' + AFileName; SetError(AError); Exit; end;
  Args := TStringList.Create;
  try
    BuildCommandArguments(AFileName, ALanguage, FUseGPU, FThreads, Args);
    SetLength(Params, Args.Count);
    for I := 0 to Args.Count - 1 do Params[I] := Args[I];
    FRunner.Executable := FExecutablePath;
    FRunner.WorkingDirectory := ExtractFilePath(FExecutablePath);
    FRunner.TimeoutMs := FTimeoutMs;
    Result := FRunner.Execute(Params);
    FLastStdOut := FRunner.StdOutText;
    FLastStdErr := FRunner.StdErrText;
    FLastExitCode := FRunner.LastExitCode;
    if not Result then
    begin
      AError := FRunner.LastError;
      if Trim(AError) = '' then AError := Trim(FLastStdErr);
      SetError(AError);
      Exit;
    end;
    AText := CleanOutput(FLastStdOut);
    Result := Trim(AText) <> '';
    if not Result then begin AError := 'whisper-cli terminou sem texto reconhecido.'; SetError(AError); end
    else begin FLastResult := AText; FLastSuccess := True; ClearError; end;
  finally Args.Free; end;
end;

procedure TAIWhisperProcessEngine.Cancel;
begin FRunner.Stop; end;

end.
