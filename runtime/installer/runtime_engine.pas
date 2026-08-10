unit runtime_engine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Process, fphttpclient, opensslsockets, zipper,
  FileUtil;

type
  TRuntimeLogEvent = procedure(Sender: TObject; const AMsg: string) of object;

  TRuntimePackage = class
  public
    PlatformID: string;
    Enabled: Boolean;
    ArchiveName: string;
    URL: string;
    SHA256URL: string;
    DefaultDir: string;
  end;

  TRuntimeInstallerEngine = class
  private
    FManifestURL: string;
    FManifestFile: string;
    FPlatformID: string;
    FInstallDir: string;
    FTempDir: string;
    FPackage: TRuntimePackage;
    FOnLog: TRuntimeLogEvent;
    FCancelled: Boolean;
    procedure Log(const S: string);
    function RunCapture(const Exe: string; const Args: array of string;
      out AOutput: string; out AExitCode: Integer): Boolean;
    function FindOnPath(const AExe: string): string;
    function ExpandHome(const APath: string): string;
    function DownloadFile(const AURL, ADest: string): Boolean;
    function LoadPackageFromINI(const AFileName: string): Boolean;
    function ExtractExpectedHash(const ASumsFile, AArchiveName: string;
      out AHash: string): Boolean;
    function CalculateSHA256(const AFileName: string; out AHash: string): Boolean;
    function WriteRuntimeINI: Boolean;
    function LocateRuntimeFile(const ARelativeCandidates: array of string): string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Cancel;
    function DetectPlatform: string;
    function LoadManifest: Boolean;
    function RuntimeAlreadyInstalled: Boolean;
    function DownloadAndInstall: Boolean;
    function ValidateInstallation(out AReport: string): Boolean;
    property ManifestURL: string read FManifestURL write FManifestURL;
    property ManifestFile: string read FManifestFile;
    property PlatformID: string read FPlatformID;
    property InstallDir: string read FInstallDir write FInstallDir;
    property RuntimePackage: TRuntimePackage read FPackage;
    property OnLog: TRuntimeLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor TRuntimeInstallerEngine.Create;
begin
  inherited Create;
  FPackage := TRuntimePackage.Create;
  FManifestURL := 'https://raw.githubusercontent.com/marcelomaurin/CHATGPT/main/runtime/runtime_manifest.ini';
  FPlatformID := DetectPlatform;
  FTempDir := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'chatgpt-ai-runtime';
end;

destructor TRuntimeInstallerEngine.Destroy;
begin
  FPackage.Free;
  inherited Destroy;
end;

procedure TRuntimeInstallerEngine.Log(const S: string);
begin
  if Assigned(FOnLog) then FOnLog(Self, S);
end;

procedure TRuntimeInstallerEngine.Cancel;
begin
  FCancelled := True;
end;

function TRuntimeInstallerEngine.DetectPlatform: string;
begin
  {$IFDEF Windows}
    {$IFDEF CPU64}
    Result := 'windows-x64';
    {$ELSE}
    Result := 'windows-x86';
    {$ENDIF}
  {$ELSEIF Defined(Linux)}
    {$IF Defined(CPUAARCH64)}
    Result := 'linux-arm64';
    {$ELSEIF Defined(CPUARM)}
    Result := 'linux-armhf';
    {$ELSEIF Defined(CPU64)}
    Result := 'linux-x64';
    {$ELSE}
    Result := 'linux-x86';
    {$ENDIF}
  {$ELSE}
  Result := 'unsupported';
  {$ENDIF}
end;

function TRuntimeInstallerEngine.FindOnPath(const AExe: string): string;
begin
  Result := FileSearch(AExe, GetEnvironmentVariable('PATH'));
end;

function TRuntimeInstallerEngine.ExpandHome(const APath: string): string;
var H: string;
begin
  Result := APath;
  if Pos('~', Result) = 1 then
  begin
    H := GetUserDir;
    Result := IncludeTrailingPathDelimiter(H) + Copy(Result, 2, MaxInt);
  end;
  Result := ExpandFileName(Result);
end;

function TRuntimeInstallerEngine.RunCapture(const Exe: string;
  const Args: array of string; out AOutput: string; out AExitCode: Integer): Boolean;
var
  P: TProcess;
  S: TStringStream;
  I: Integer;
  B: array[0..4095] of Byte;
  N: Integer;
begin
  Result := False;
  AOutput := '';
  AExitCode := -1;
  P := TProcess.Create(nil);
  S := TStringStream.Create('');
  try
    P.Executable := Exe;
    for I := Low(Args) to High(Args) do P.Parameters.Add(Args[I]);
    P.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    try
      P.Execute;
      while P.Running or (P.Output.NumBytesAvailable > 0) do
      begin
        if FCancelled then
        begin
          try P.Terminate(1); except end;
          Break;
        end;
        while P.Output.NumBytesAvailable > 0 do
        begin
          N := P.Output.Read(B, SizeOf(B));
          if N > 0 then S.WriteBuffer(B, N);
        end;
        Sleep(20);
      end;
      while P.Output.NumBytesAvailable > 0 do
      begin
        N := P.Output.Read(B, SizeOf(B));
        if N > 0 then S.WriteBuffer(B, N);
      end;
      AExitCode := P.ExitStatus;
      AOutput := S.DataString;
      Result := (AExitCode = 0) and not FCancelled;
    except
      on E: Exception do AOutput := E.Message;
    end;
  finally
    S.Free;
    P.Free;
  end;
end;

function TRuntimeInstallerEngine.DownloadFile(const AURL, ADest: string): Boolean;
var
  C: TFPHTTPClient;
  S: TFileStream;
begin
  Result := False;
  if FCancelled then Exit;
  ForceDirectories(ExtractFileDir(ADest));
  Log('[DOWNLOAD] ' + AURL);
  C := TFPHTTPClient.Create(nil);
  try
    C.AllowRedirect := True;
    C.AddHeader('User-Agent', 'CHATGPT-AI-Runtime-Installer/1.0');
    S := TFileStream.Create(ADest, fmCreate);
    try
      try
        C.Get(AURL, S);
        Result := (C.ResponseStatusCode >= 200) and (C.ResponseStatusCode < 300) and
          (S.Size > 0);
        if not Result then Log('[ERRO] HTTP ' + IntToStr(C.ResponseStatusCode));
      except
        on E: Exception do Log('[ERRO] Download: ' + E.Message);
      end;
    finally
      S.Free;
    end;
  finally
    C.Free;
  end;
end;

function TRuntimeInstallerEngine.LoadPackageFromINI(const AFileName: string): Boolean;
var I: TIniFile;
begin
  Result := False;
  I := TIniFile.Create(AFileName);
  try
    if not I.SectionExists(FPlatformID) then
    begin
      Log('[ERRO] Plataforma não existe no manifesto: ' + FPlatformID);
      Exit;
    end;
    FPackage.PlatformID := FPlatformID;
    FPackage.Enabled := I.ReadBool(FPlatformID, 'enabled', False);
    FPackage.ArchiveName := I.ReadString(FPlatformID, 'archive', '');
    FPackage.URL := I.ReadString(FPlatformID, 'url', '');
    FPackage.SHA256URL := I.ReadString(FPlatformID, 'sha256_url', '');
    FPackage.DefaultDir := ExpandHome(I.ReadString(FPlatformID, 'default_dir', ''));
    if FInstallDir = '' then FInstallDir := FPackage.DefaultDir;
    Result := FPackage.Enabled and (FPackage.ArchiveName <> '') and
      (FPackage.URL <> '') and (FInstallDir <> '');
    if not FPackage.Enabled then
      Log('[ERRO] Runtime ainda não publicado para ' + FPlatformID);
  finally
    I.Free;
  end;
end;

function TRuntimeInstallerEngine.LoadManifest: Boolean;
var
  Local1, Local2, RemoteTemp: string;
begin
  Result := False;
  FManifestFile := '';
  ForceDirectories(FTempDir);
  RemoteTemp := IncludeTrailingPathDelimiter(FTempDir) + 'runtime_manifest.ini';
  if DownloadFile(FManifestURL, RemoteTemp) then
    FManifestFile := RemoteTemp
  else
  begin
    Local1 := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'runtime_manifest.ini';
    Local2 := ExpandFileName(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + '..' + DirectorySeparator + 'runtime_manifest.ini');
    if FileExists(Local1) then FManifestFile := Local1
    else if FileExists(Local2) then FManifestFile := Local2;
  end;
  if FManifestFile = '' then
  begin
    Log('[ERRO] Manifesto de runtime não disponível.');
    Exit;
  end;
  Log('[OK] Manifesto: ' + FManifestFile);
  Result := LoadPackageFromINI(FManifestFile);
end;

function TRuntimeInstallerEngine.ExtractExpectedHash(const ASumsFile,
  AArchiveName: string; out AHash: string): Boolean;
var
  L: TStringList;
  I, P: Integer;
  S: string;
begin
  Result := False;
  AHash := '';
  if not FileExists(ASumsFile) then Exit;
  L := TStringList.Create;
  try
    L.LoadFromFile(ASumsFile);
    for I := 0 to L.Count - 1 do
    begin
      S := Trim(L[I]);
      if Pos(LowerCase(AArchiveName), LowerCase(S)) > 0 then
      begin
        P := Pos(' ', S);
        if P > 1 then AHash := LowerCase(Copy(S, 1, P - 1));
        Result := Length(AHash) = 64;
        Exit;
      end;
    end;
  finally
    L.Free;
  end;
end;

function TRuntimeInstallerEngine.CalculateSHA256(const AFileName: string;
  out AHash: string): Boolean;
var
  Exe, OutText, S: string;
  RC, I: Integer;
  L: TStringList;
begin
  Result := False;
  AHash := '';
  {$IFDEF Windows}
  Exe := FindOnPath('certutil.exe');
  if Exe = '' then Exe := 'certutil.exe';
  if not RunCapture(Exe, ['-hashfile', AFileName, 'SHA256'], OutText, RC) then Exit;
  L := TStringList.Create;
  try
    L.Text := OutText;
    for I := 0 to L.Count - 1 do
    begin
      S := StringReplace(Trim(L[I]), ' ', '', [rfReplaceAll]);
      if Length(S) = 64 then begin AHash := LowerCase(S); Exit(True); end;
    end;
  finally L.Free; end;
  {$ELSE}
  Exe := FindOnPath('sha256sum');
  if Exe = '' then Exit;
  if not RunCapture(Exe, [AFileName], OutText, RC) then Exit;
  S := Trim(OutText);
  I := Pos(' ', S);
  if I > 1 then AHash := LowerCase(Copy(S, 1, I - 1));
  Result := Length(AHash) = 64;
  {$ENDIF}
end;

function TRuntimeInstallerEngine.LocateRuntimeFile(
  const ARelativeCandidates: array of string): string;
var I: Integer; P: string;
begin
  Result := '';
  for I := Low(ARelativeCandidates) to High(ARelativeCandidates) do
  begin
    P := IncludeTrailingPathDelimiter(FInstallDir) + ARelativeCandidates[I];
    if FileExists(P) then Exit(ExpandFileName(P));
  end;
end;

function TRuntimeInstallerEngine.WriteRuntimeINI: Boolean;
var
  I: TIniFile;
  FN: string;
begin
  ForceDirectories(FInstallDir);
  FN := IncludeTrailingPathDelimiter(FInstallDir) + 'chatgpt_ai_runtime.ini';
  I := TIniFile.Create(FN);
  try
    I.WriteString('runtime', 'platform', FPlatformID);
    I.WriteString('runtime', 'root', FInstallDir);
    I.WriteString('runtime', 'installed_at', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    I.WriteString('tools', 'python', LocateRuntimeFile(['python\python.exe','python/bin/python3','bin/python3']));
    I.WriteString('tools', 'whisper', LocateRuntimeFile(['whisper\whisper-cli.exe','whisper/whisper-cli','bin/whisper-cli.exe','bin/whisper-cli']));
    I.WriteString('tools', 'llama_server', LocateRuntimeFile(['llama.cpp\llama-server.exe','llama.cpp/llama-server','bin/llama-server.exe','bin/llama-server']));
    I.WriteString('tools', 'pdftotext', LocateRuntimeFile(['poppler\Library\bin\pdftotext.exe','poppler/bin/pdftotext','bin/pdftotext.exe','bin/pdftotext']));
    I.WriteString('tools', 'f5tts', LocateRuntimeFile(['f5-tts\src\f5_tts\infer\infer_cli.py','f5-tts/src/f5_tts/infer/infer_cli.py']));
    I.UpdateFile;
    Result := FileExists(FN);
  finally
    I.Free;
  end;
end;

function TRuntimeInstallerEngine.RuntimeAlreadyInstalled: Boolean;
begin
  Result := (FInstallDir <> '') and FileExists(
    IncludeTrailingPathDelimiter(FInstallDir) + 'chatgpt_ai_runtime.ini');
end;

function TRuntimeInstallerEngine.DownloadAndInstall: Boolean;
var
  ArchiveFile, SumsFile, Expected, Actual: string;
  U: TUnZipper;
begin
  Result := False;
  FCancelled := False;
  if (FPackage.URL = '') and not LoadManifest then Exit;
  if not FPackage.Enabled then Exit;
  ForceDirectories(FTempDir);
  ArchiveFile := IncludeTrailingPathDelimiter(FTempDir) + FPackage.ArchiveName;
  SumsFile := IncludeTrailingPathDelimiter(FTempDir) + 'SHA256SUMS.txt';
  if FileExists(ArchiveFile) then DeleteFile(ArchiveFile);
  if not DownloadFile(FPackage.URL, ArchiveFile) then Exit;
  if FCancelled then Exit;

  if FPackage.SHA256URL <> '' then
  begin
    if not DownloadFile(FPackage.SHA256URL, SumsFile) then Exit;
    if not ExtractExpectedHash(SumsFile, FPackage.ArchiveName, Expected) then
    begin Log('[ERRO] Hash esperado não encontrado em SHA256SUMS.txt'); Exit; end;
    if not CalculateSHA256(ArchiveFile, Actual) then
    begin Log('[ERRO] Não foi possível calcular SHA256 local.'); Exit; end;
    if not SameText(Expected, Actual) then
    begin Log('[ERRO] SHA256 inválido. Download descartado.'); DeleteFile(ArchiveFile); Exit; end;
    Log('[OK] SHA256 validado.');
  end;

  if DirectoryExists(FInstallDir) then
    Log('[INFO] Runtime existente será atualizado no mesmo diretório.');
  ForceDirectories(FInstallDir);
  U := TUnZipper.Create;
  try
    U.FileName := ArchiveFile;
    U.OutputPath := IncludeTrailingPathDelimiter(FInstallDir);
    try
      Log('[EXTRACT] ' + FInstallDir);
      U.Examine;
      U.UnZipAllFiles;
    except
      on E: Exception do begin Log('[ERRO] Extração: ' + E.Message); Exit; end;
    end;
  finally U.Free; end;
  if not WriteRuntimeINI then
  begin Log('[ERRO] Falha ao gerar chatgpt_ai_runtime.ini'); Exit; end;
  Log('[OK] Runtime instalado em ' + FInstallDir);
  Result := True;
end;

function TRuntimeInstallerEngine.ValidateInstallation(out AReport: string): Boolean;
var
  FN: string;
  L: TStringList;
  I: TIniFile;
  V: string;
  procedure CheckTool(const Key: string; Required: Boolean);
  begin
    V := I.ReadString('tools', Key, '');
    if (V <> '') and FileExists(V) then L.Add('[OK] ' + Key + ': ' + V)
    else if Required then begin L.Add('[FALTA] ' + Key); Result := False; end
    else L.Add('[OPCIONAL] ' + Key + ' não encontrado');
  end;
begin
  Result := True;
  L := TStringList.Create;
  try
    FN := IncludeTrailingPathDelimiter(FInstallDir) + 'chatgpt_ai_runtime.ini';
    if not FileExists(FN) then
    begin AReport := '[FALTA] chatgpt_ai_runtime.ini'; Exit(False); end;
    I := TIniFile.Create(FN);
    try
      L.Add('[OK] runtime.ini: ' + FN);
      CheckTool('python', False);
      CheckTool('whisper', False);
      CheckTool('llama_server', False);
      CheckTool('pdftotext', False);
      CheckTool('f5tts', False);
    finally I.Free; end;
    AReport := L.Text;
  finally L.Free; end;
end;

end.
