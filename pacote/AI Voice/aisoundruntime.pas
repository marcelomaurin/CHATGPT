unit aisoundruntime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, airuntimepaths, aiprocessrunner;

type
  TAISoundServerProbe = record
    Name: string;
    Endpoint: string;
    HealthUrl: string;
    Online: Boolean;
    SupportsVoiceCloning: Boolean;
    SupportsSFX: Boolean;
    RunsOnCPU: Boolean;
    StatusText: string;
  end;

function ProbeSoundHttpServer(const AHealthUrl: string; ATimeoutMs: Integer = 1200): Boolean;
procedure DiscoverLocalSoundServers(AList: TStrings);
function ResolveAISoundCpuWorkerPath(const ACustomRuntimeRoot: string = ''): string;
function CheckAISoundCpuRuntimeHealth(const APythonExe, AWorkerPath: string;
  out AOutputText, AErrorText: string): Boolean;
function PrepareParakeetRuntime(const ACustomRuntimeRoot: string;
  out AOutputText, AErrorText: string): Boolean;

implementation

function ProbeSoundHttpServer(const AHealthUrl: string; ATimeoutMs: Integer): Boolean;
var
  C: TFPHTTPClient;
  S: TStringStream;
begin
  Result := False;
  C := TFPHTTPClient.Create(nil);
  S := TStringStream.Create('');
  try
    C.ConnectTimeout := ATimeoutMs;
    C.IOTimeout := ATimeoutMs;
    C.AllowRedirect := True;
    try
      C.Get(AHealthUrl, S);
      Result := (C.ResponseStatusCode >= 200) and (C.ResponseStatusCode < 500);
    except
      Result := False;
    end;
  finally
    S.Free;
    C.Free;
  end;
end;

procedure DiscoverLocalSoundServers(AList: TStrings);
const
  ProbeUrls: array[0..9] of record
    Name: string;
    HealthUrl: string;
    Endpoint: string;
    Flags: string;
  end = (
    (Name: 'Parakeet-TTS';    HealthUrl: 'http://127.0.0.1:8090/health';         Endpoint: 'http://127.0.0.1:8090/v1/audio/speech'; Flags: 'Parakeet Texto-para-Voz CPU/GPU'),
    (Name: 'Kokoro-FastAPI';  HealthUrl: 'http://127.0.0.1:8880/health';         Endpoint: 'http://127.0.0.1:8880/v1/audio/speech'; Flags: 'TTS CPU/GPU'),
    (Name: 'OpenedAI-Speech'; HealthUrl: 'http://127.0.0.1:8000/v1/models';      Endpoint: 'http://127.0.0.1:8000/v1/audio/speech'; Flags: 'Piper+XTTS CPU'),
    (Name: 'Piper-HTTP';      HealthUrl: 'http://127.0.0.1:5000/';               Endpoint: 'http://127.0.0.1:5000/';               Flags: 'TTS ONNX CPU'),
    (Name: 'Coqui-XTTS';      HealthUrl: 'http://127.0.0.1:8020/languages';      Endpoint: 'http://127.0.0.1:8020/tts_to_audio/';   Flags: 'Clonagem CPU/GPU'),
    (Name: 'AllTalk-TTS';     HealthUrl: 'http://127.0.0.1:7851/api/ready';      Endpoint: 'http://127.0.0.1:7851/api/tts-generate'; Flags: 'XTTS/Piper/F5'),
    (Name: 'OpenVoice-v2';    HealthUrl: 'http://127.0.0.1:8030/health';         Endpoint: 'http://127.0.0.1:8030/synthesize';     Flags: 'Clonagem CPU'),
    (Name: 'F5-TTS-Server';   HealthUrl: 'http://127.0.0.1:7860/';               Endpoint: 'http://127.0.0.1:7860/api/predict';    Flags: 'Clonagem Zero-Shot'),
    (Name: 'Chatterbox';      HealthUrl: 'http://127.0.0.1:8080/health';         Endpoint: 'http://127.0.0.1:8080/v1/tts';         Flags: 'Clonagem Expressiva'),
    (Name: 'AudioCraft-Bark'; HealthUrl: 'http://127.0.0.1:8040/health';         Endpoint: 'http://127.0.0.1:8040/generate';       Flags: 'SFX/Musica')
  );
var
  I: Integer;
  Ok: Boolean;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to High(ProbeUrls) do
  begin
    Ok := ProbeSoundHttpServer(ProbeUrls[I].HealthUrl, 700);
    if Ok then
      AList.Add(Format('[ONLINE] %s (%s) -> %s',
        [ProbeUrls[I].Name, ProbeUrls[I].Flags, ProbeUrls[I].Endpoint]))
    else
      AList.Add(Format('[offline] %s (%s) -> %s',
        [ProbeUrls[I].Name, ProbeUrls[I].Flags, ProbeUrls[I].Endpoint]));
  end;
end;

function ResolveAISoundCpuWorkerPath(const ACustomRuntimeRoot: string): string;
var
  ExeDir, Candidate: string;
begin
  if ACustomRuntimeRoot <> '' then
  begin
    Candidate := AIResolveWorkerPath(ACustomRuntimeRoot, 'aisound_cpu_worker.py');
    if FileExists(Candidate) then Exit(Candidate);
  end;

  Candidate := AIResolveWorkerPath(AIGetDefaultRuntimeRoot, 'aisound_cpu_worker.py');
  if FileExists(Candidate) then Exit(Candidate);

  ExeDir := ExtractFileDir(ExpandFileName(ParamStr(0)));
  Candidate := ExpandFileName(ExeDir + PathDelim + '..' + PathDelim + '..' + PathDelim +
    'CHATGPT' + PathDelim + 'pacote' + PathDelim + 'python' + PathDelim + 'aisound_cpu_worker.py');
  if FileExists(Candidate) then Exit(Candidate);

  Candidate := 'C:\projetos\maurinsoft\CHATGPT\pacote\python\aisound_cpu_worker.py';
  if FileExists(Candidate) then Exit(Candidate);

  Result := '';
end;

function CheckAISoundCpuRuntimeHealth(const APythonExe, AWorkerPath: string;
  out AOutputText, AErrorText: string): Boolean;
var
  Runner: TAIProcessRunner;
  PyExe, Worker: string;
begin
  Result := False;
  AOutputText := '';
  AErrorText := '';
  PyExe := Trim(APythonExe);
  if PyExe = '' then
    PyExe := AIResolvePythonExecutable(AIGetDefaultRuntimeRoot);
  Worker := Trim(AWorkerPath);
  if Worker = '' then
    Worker := ResolveAISoundCpuWorkerPath('');
  if Worker = '' then
  begin
    AErrorText := 'Worker aisound_cpu_worker.py nao encontrado.';
    Exit;
  end;

  Runner := TAIProcessRunner.Create(nil);
  try
    Runner.Executable := PyExe;
    Runner.TimeoutMs := 15000;
    Result := Runner.Execute([Worker, '--health']);
    AOutputText := Trim(Runner.StdOutText);
    AErrorText := Trim(Runner.LastError + ' ' + Runner.StdErrText);
  finally
    Runner.Free;
  end;
end;

function PrepareParakeetRuntime(const ACustomRuntimeRoot: string;
  out AOutputText, AErrorText: string): Boolean;
var
  Runner: TAIProcessRunner;
  PyExe, Worker, RtRoot: string;
begin
  Result := False;
  AOutputText := '';
  AErrorText := '';
  RtRoot := Trim(ACustomRuntimeRoot);
  if RtRoot = '' then RtRoot := AIGetDefaultRuntimeRoot;
  PyExe := AIResolvePythonExecutable(RtRoot);
  Worker := ResolveAISoundCpuWorkerPath(RtRoot);
  if Worker = '' then
  begin
    AErrorText := 'Worker aisound_cpu_worker.py nao encontrado para preparar Parakeet.';
    Exit;
  end;

  Runner := TAIProcessRunner.Create(nil);
  try
    Runner.Executable := PyExe;
    Runner.TimeoutMs := 30000;
    if RtRoot <> '' then
      Result := Runner.Execute([Worker, '--prepare-parakeet', '--runtime-dir', RtRoot])
    else
      Result := Runner.Execute([Worker, '--prepare-parakeet']);
    AOutputText := Trim(Runner.StdOutText);
    AErrorText := Trim(Runner.LastError + ' ' + Runner.StdErrText);
  finally
    Runner.Free;
  end;
end;

end.
