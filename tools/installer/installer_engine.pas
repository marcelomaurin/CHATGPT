unit installer_engine;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, DOM, XMLRead, XMLWrite, Contnrs, FileUtil;

type
  TLogEvent = procedure(Sender: TObject; const AMsg: string) of object;

  TPackageInfo = class
  public
    Name: string;
    FileName: string;
    RequiredInternal: TStringList;
    RequiredExternal: TStringList;
    Selected: Boolean;
    CompileOK: Boolean;
    InstallOK: Boolean;
    IsRuntimeOnly: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

  TInstallerEngine = class
  private
    FRepoRoot: string;
    FLazBuild: string;
    FFPC: string;
    FGit: string;
    FPrimaryConfigPath: string;
    FLazarusVersion: string;
    FFPCVersion: string;
    FTargetCPU: string;
    FTargetOS: string;
    FTargetBits: Integer;
    FSupportedTargets: TStringList;
    FHasWin32: Boolean;
    FHasWin64: Boolean;
    FHasLinux32: Boolean;
    FHasLinux64: Boolean;
    FPackages: TObjectList;
    FAbort: Boolean;
    FOnLog: TLogEvent;
    procedure Log(const AMsg: string);
    function RunCapture(const AExe: string; const AArgs: array of string;
      out AOutput: string; out AExitCode: Integer): Boolean;
    function FindExecutable(const AName: string; const ACandidates: array of string): string;
    function DetectConfigPath: string;
    procedure DetectSupportedTargets;
    function GetAttr(AElement: TDOMElement; const AName: string): string;
    function PackageByName(const AName: string): TPackageInfo;
    function IsExternalPackageInstalled(const AName: string): Boolean;
    procedure RemoveOpenAIAutoInstallNodes(ANode: TDOMNode;
      AInsideAutoInstall: Boolean; var ARemoved: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Cancel;

    function DetectEnvironment: Boolean;
    function IsGitRepository: Boolean;
    function HasLocalChanges(out ADetails: string): Boolean;
    function CheckRemoteUpdate(out AAvailable: Boolean; out ADetails: string): Boolean;
    function UpdateRepository(out ADetails: string): Boolean;

    function ScanPackages: Boolean;
    function CheckPrerequisites(out AMissing: string): Boolean;
    function BuildInstallOrder(AOrder: TStrings; out AError: string): Boolean;
    function GetInstalledSuitePackages(AList: TStrings): Boolean;
    function BackupAndRemoveOldPackages(out ABackupFile: string): Boolean;
    function CleanSuiteBuildCaches: Boolean;
    function CompileSelected(AOrder: TStrings): Boolean;
    function RegisterSelected(AOrder: TStrings): Boolean;
    function RebuildIDE: Boolean;
    function VerifyInstalled(AOrder, AResult: TStrings): Boolean;

    function ScanSamples(AList: TStrings): Boolean;
    function CompileSamples(AList, AResult: TStrings): Boolean;
    function ValidateDocumentation(AResult: TStrings): Boolean;
    function CopyDocumentation(const ADestination: string; AResult: TStrings): Boolean;

    property RepoRoot: string read FRepoRoot write FRepoRoot;
    property LazBuild: string read FLazBuild write FLazBuild;
    property FPC: string read FFPC write FFPC;
    property Git: string read FGit write FGit;
    property PrimaryConfigPath: string read FPrimaryConfigPath write FPrimaryConfigPath;
    property LazarusVersion: string read FLazarusVersion;
    property FPCVersion: string read FFPCVersion;
    property TargetCPU: string read FTargetCPU;
    property TargetOS: string read FTargetOS;
    property TargetBits: Integer read FTargetBits;
    property HasWin32: Boolean read FHasWin32;
    property HasWin64: Boolean read FHasWin64;
    property HasLinux32: Boolean read FHasLinux32;
    property HasLinux64: Boolean read FHasLinux64;
    property SupportedTargets: TStringList read FSupportedTargets;
    property Packages: TObjectList read FPackages;
    property OnLog: TLogEvent read FOnLog write FOnLog;
  end;

implementation

constructor TPackageInfo.Create;
begin
  inherited Create;
  RequiredInternal := TStringList.Create;
  RequiredExternal := TStringList.Create;
  RequiredInternal.CaseSensitive := False;
  RequiredExternal.CaseSensitive := False;
  Selected := True;
end;

destructor TPackageInfo.Destroy;
begin
  RequiredExternal.Free;
  RequiredInternal.Free;
  inherited Destroy;
end;

constructor TInstallerEngine.Create;
begin
  inherited Create;
  FPackages := TObjectList.Create(True);
  FSupportedTargets := TStringList.Create;
  FSupportedTargets.CaseSensitive := False;
  FRepoRoot := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..' + DirectorySeparator + '..');
end;

destructor TInstallerEngine.Destroy;
begin
  FSupportedTargets.Free;
  FPackages.Free;
  inherited Destroy;
end;

procedure TInstallerEngine.Cancel;
begin
  FAbort := True;
end;

procedure TInstallerEngine.Log(const AMsg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, AMsg);
end;

function TInstallerEngine.RunCapture(const AExe: string;
  const AArgs: array of string; out AOutput: string;
  out AExitCode: Integer): Boolean;
var
  P: TProcess;
  S: TStringStream;
  B: array[0..4095] of Byte;
  N, I: Integer;
begin
  Result := False;
  AOutput := '';
  AExitCode := -1;
  P := TProcess.Create(nil);
  S := TStringStream.Create('');
  try
    P.Executable := AExe;
    for I := Low(AArgs) to High(AArgs) do
      if AArgs[I] <> '' then
        P.Parameters.Add(AArgs[I]);
    P.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    try
      P.Execute;
      while P.Running or (P.Output.NumBytesAvailable > 0) do
      begin
        if FAbort then
        begin
          try
            P.Terminate(1);
          except
          end;
          Break;
        end;
        while P.Output.NumBytesAvailable > 0 do
        begin
          N := P.Output.Read(B, SizeOf(B));
          if N > 0 then
            S.WriteBuffer(B, N);
        end;
        Sleep(20);
        CheckSynchronize(5);
      end;
      while P.Output.NumBytesAvailable > 0 do
      begin
        N := P.Output.Read(B, SizeOf(B));
        if N > 0 then
          S.WriteBuffer(B, N);
      end;
      AExitCode := P.ExitStatus;
      AOutput := S.DataString;
      Result := (AExitCode = 0) and not FAbort;
    except
      on E: Exception do
      begin
        AOutput := E.Message;
        AExitCode := -1;
      end;
    end;
  finally
    S.Free;
    P.Free;
  end;
end;

function TInstallerEngine.FindExecutable(const AName: string;
  const ACandidates: array of string): string;
var
  I: Integer;
  Paths: TStringList;
  P, C: string;
begin
  Result := '';
  Paths := TStringList.Create;
  try
    {$IFDEF Windows}
    Paths.Delimiter := ';';
    {$ELSE}
    Paths.Delimiter := ':';
    {$ENDIF}
    Paths.StrictDelimiter := True;
    Paths.DelimitedText := GetEnvironmentVariable('PATH');
    for I := 0 to Paths.Count - 1 do
    begin
      C := IncludeTrailingPathDelimiter(Paths[I]) + AName;
      if FileExists(C) then
        Exit(ExpandFileName(C));
    end;
  finally
    Paths.Free;
  end;

  for I := Low(ACandidates) to High(ACandidates) do
  begin
    P := ACandidates[I];
    if FileExists(P) then
      Exit(ExpandFileName(P));
  end;
end;

function TInstallerEngine.DetectConfigPath: string;
var
  P: string;
begin
  {$IFDEF Windows}
  P := GetEnvironmentVariable('LOCALAPPDATA');
  if P <> '' then
  begin
    Result := IncludeTrailingPathDelimiter(P) + 'lazarus';
    if DirectoryExists(Result) then Exit;
  end;
  P := GetEnvironmentVariable('APPDATA');
  if P <> '' then
  begin
    Result := IncludeTrailingPathDelimiter(P) + 'lazarus';
    if DirectoryExists(Result) then Exit;
  end;
  Result := IncludeTrailingPathDelimiter(GetUserDir) + 'AppData' +
    DirectorySeparator + 'Local' + DirectorySeparator + 'lazarus';
  {$ELSE}
  Result := IncludeTrailingPathDelimiter(GetUserDir) + '.lazarus';
  {$ENDIF}
end;

procedure TInstallerEngine.DetectSupportedTargets;
var
  LDir, FPCUnitsDir: string;
  SR: TSearchRec;
  TargetName: string;
begin
  FSupportedTargets.Clear;
  FHasWin32 := False;
  FHasWin64 := False;
  FHasLinux32 := False;
  FHasLinux64 := False;

  if FTargetOS = 'win32' then FHasWin32 := True;
  if FTargetOS = 'win64' then FHasWin64 := True;
  if (FTargetOS = 'linux') and (FTargetBits = 64) then FHasLinux64 := True;
  if (FTargetOS = 'linux') and (FTargetBits = 32) then FHasLinux32 := True;

  LDir := ExtractFilePath(FLazBuild);
  FPCUnitsDir := IncludeTrailingPathDelimiter(LDir) + 'fpc' + DirectorySeparator + FFPCVersion + DirectorySeparator + 'units';
  if not DirectoryExists(FPCUnitsDir) then
    FPCUnitsDir := IncludeTrailingPathDelimiter(ExtractFilePath(FFPC)) + '..' + DirectorySeparator + 'units';
  if not DirectoryExists(FPCUnitsDir) then
    FPCUnitsDir := IncludeTrailingPathDelimiter(ExtractFilePath(FFPC)) + 'units';

  if DirectoryExists(FPCUnitsDir) then
  begin
    if FindFirst(IncludeTrailingPathDelimiter(FPCUnitsDir) + '*', faDirectory, SR) = 0 then
    try
      repeat
        if (SR.Name = '.') or (SR.Name = '..') then Continue;
        if (SR.Attr and faDirectory) <> 0 then
        begin
          TargetName := LowerCase(SR.Name);
          if FSupportedTargets.IndexOf(SR.Name) < 0 then
            FSupportedTargets.Add(SR.Name);
          if Pos('win32', TargetName) > 0 then FHasWin32 := True;
          if Pos('win64', TargetName) > 0 then FHasWin64 := True;
          if Pos('linux', TargetName) > 0 then
          begin
            if (Pos('64', TargetName) > 0) or (Pos('x86_64', TargetName) > 0) or (Pos('aarch64', TargetName) > 0) then
              FHasLinux64 := True
            else
              FHasLinux32 := True;
          end;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

  if (FSupportedTargets.Count = 0) and (FTargetCPU <> '') and (FTargetOS <> '') then
    FSupportedTargets.Add(FTargetCPU + '-' + FTargetOS);
end;

function TInstallerEngine.DetectEnvironment: Boolean;
var
  S: string;
  RC: Integer;
  LDir: string;
begin
  Result := False;
  FAbort := False;

  if (FLazBuild = '') or not FileExists(FLazBuild) then
  begin
    {$IFDEF Windows}
    FLazBuild := FindExecutable('lazbuild.exe', [
      'C:\lazarus\lazbuild.exe',
      'C:\Lazarus\lazbuild.exe',
      'C:\Program Files\Lazarus\lazbuild.exe',
      'C:\Program Files (x86)\Lazarus\lazbuild.exe',
      'D:\lazarus\lazbuild.exe']);
    {$ELSE}
    FLazBuild := FindExecutable('lazbuild', [
      '/usr/bin/lazbuild', '/usr/local/bin/lazbuild', '/opt/lazarus/lazbuild']);
    {$ENDIF}
  end;
  if (FLazBuild = '') or not FileExists(FLazBuild) then
  begin
    Log('[ERRO] lazbuild não encontrado.');
    Exit;
  end;

  LDir := ExtractFilePath(FLazBuild);
  {$IFDEF Windows}
  FFPC := FindExecutable('fpc.exe', [
    LDir + 'fpc.exe',
    LDir + 'fpc\bin\x86_64-win64\fpc.exe',
    LDir + 'fpc\bin\i386-win32\fpc.exe',
    LDir + 'fpc\3.2.2\bin\i386-win32\fpc.exe',
    LDir + 'fpc\3.2.2\bin\x86_64-win64\fpc.exe']);
  FGit := FindExecutable('git.exe', [
    'C:\Program Files\Git\cmd\git.exe',
    'C:\Program Files\Git\bin\git.exe']);
  {$ELSE}
  FFPC := FindExecutable('fpc', ['/usr/bin/fpc', '/usr/local/bin/fpc']);
  FGit := FindExecutable('git', ['/usr/bin/git', '/usr/local/bin/git']);
  {$ENDIF}
  if FFPC = '' then
  begin
    Log('[ERRO] fpc não encontrado.');
    Exit;
  end;

  if RunCapture(FLazBuild, ['--version'], S, RC) then
    FLazarusVersion := Trim(S)
  else
    FLazarusVersion := 'desconhecida';
  if RunCapture(FFPC, ['-iV'], S, RC) then
    FFPCVersion := Trim(S)
  else
    FFPCVersion := 'desconhecida';
  if not RunCapture(FFPC, ['-iTP'], S, RC) then Exit;
  FTargetCPU := LowerCase(Trim(S));
  if not RunCapture(FFPC, ['-iTO'], S, RC) then Exit;
  FTargetOS := LowerCase(Trim(S));

  if (Pos('64', FTargetCPU) > 0) or (FTargetCPU = 'aarch64') then
    FTargetBits := 64
  else
    FTargetBits := 32;

  if (FPrimaryConfigPath = '') or not DirectoryExists(FPrimaryConfigPath) then
    FPrimaryConfigPath := DetectConfigPath;

  DetectSupportedTargets;

  Log('[OK] Lazarus: ' + FLazarusVersion);
  Log('[OK] FPC: ' + FFPCVersion);
  Log('[OK] Target Ativo: ' + FTargetCPU + '-' + FTargetOS +
    ' (' + IntToStr(FTargetBits) + ' bits)');
  if FGit <> '' then Log('[OK] Git: ' + FGit)
  else Log('[ATENÇÃO] Git não encontrado; atualização automática indisponível.');
  Result := True;
end;

function TInstallerEngine.IsGitRepository: Boolean;
begin
  Result := DirectoryExists(IncludeTrailingPathDelimiter(FRepoRoot) + '.git');
end;

function TInstallerEngine.HasLocalChanges(out ADetails: string): Boolean;
var
  RC: Integer;
  S: string;
begin
  ADetails := '';
  Result := False;
  if (FGit = '') or not IsGitRepository then Exit;
  RunCapture(FGit, ['-C', FRepoRoot, 'status', '--porcelain'], S, RC);
  ADetails := Trim(S);
  Result := (RC = 0) and (ADetails <> '');
end;

function TInstallerEngine.CheckRemoteUpdate(out AAvailable: Boolean;
  out ADetails: string): Boolean;
var
  RC: Integer;
  LocalSHA, RemoteSHA, S: string;
begin
  Result := False;
  AAvailable := False;
  ADetails := '';
  if FGit = '' then begin ADetails := 'Git não encontrado.'; Exit; end;
  if not IsGitRepository then begin ADetails := 'A pasta não é um clone Git.'; Exit; end;

  if not RunCapture(FGit, ['-C', FRepoRoot, 'fetch', '--quiet', 'origin', 'main'], S, RC) then
  begin
    ADetails := Trim(S);
    Exit;
  end;
  if not RunCapture(FGit, ['-C', FRepoRoot, 'rev-parse', 'HEAD'], S, RC) then Exit;
  LocalSHA := Trim(S);
  if not RunCapture(FGit, ['-C', FRepoRoot, 'rev-parse', 'origin/main'], S, RC) then Exit;
  RemoteSHA := Trim(S);
  AAvailable := LocalSHA <> RemoteSHA;
  if AAvailable then
    ADetails := 'Local: ' + LocalSHA + LineEnding + 'Remoto: ' + RemoteSHA
  else
    ADetails := 'Repositório já atualizado: ' + LocalSHA;
  Result := True;
end;

function TInstallerEngine.UpdateRepository(out ADetails: string): Boolean;
var
  RC: Integer;
  S, Dirty: string;
begin
  Result := False;
  if HasLocalChanges(Dirty) then
  begin
    ADetails := 'Existem alterações locais; atualização automática bloqueada.' +
      LineEnding + Dirty;
    Exit;
  end;
  Result := RunCapture(FGit,
    ['-C', FRepoRoot, 'pull', '--ff-only', 'origin', 'main'], S, RC);
  ADetails := Trim(S);
end;

function TInstallerEngine.GetAttr(AElement: TDOMElement;
  const AName: string): string;
begin
  Result := '';
  if Assigned(AElement) and AElement.HasAttribute(AName) then
    Result := AElement.GetAttribute(AName);
end;

function TInstallerEngine.PackageByName(const AName: string): TPackageInfo;
var
  I: Integer;
  P: TPackageInfo;
begin
  Result := nil;
  for I := 0 to FPackages.Count - 1 do
  begin
    P := TPackageInfo(FPackages[I]);
    if SameText(P.Name, AName) then Exit(P);
  end;
end;

function TInstallerEngine.ScanPackages: Boolean;
var
  SR: TSearchRec;
  Dir, FN, N: string;
  Doc: TXMLDocument;
  Nodes: TDOMNodeList;
  I: Integer;
  P: TPackageInfo;
begin
  FPackages.Clear;
  Dir := IncludeTrailingPathDelimiter(FRepoRoot) + 'pacote' +
    DirectorySeparator + 'packages';
  Result := DirectoryExists(Dir);
  if not Result then Exit;

  if FindFirst(IncludeTrailingPathDelimiter(Dir) + 'openai_*.lpk', faAnyFile, SR) = 0 then
  try
    repeat
      FN := IncludeTrailingPathDelimiter(Dir) + SR.Name;
      Doc := nil;
      try
        ReadXMLFile(Doc, FN);
        P := TPackageInfo.Create;
        P.Name := ChangeFileExt(SR.Name, '');
        P.FileName := FN;
        P.IsRuntimeOnly := False;
        Nodes := Doc.GetElementsByTagName('Type');
        for I := 0 to Nodes.Count - 1 do
          if Nodes.Item[I] is TDOMElement then
          begin
            N := GetAttr(TDOMElement(Nodes.Item[I]), 'Value');
            if SameText(N, 'RunTime') or SameText(N, 'RunTimeOnly') then
              P.IsRuntimeOnly := True;
          end;

        Nodes := Doc.GetElementsByTagName('PackageName');
        for I := 0 to Nodes.Count - 1 do
          if Nodes.Item[I] is TDOMElement then
          begin
            N := GetAttr(TDOMElement(Nodes.Item[I]), 'Value');
            if N = '' then Continue;
            if Pos('openai_', LowerCase(N)) = 1 then
              P.RequiredInternal.Add(N)
            else
              P.RequiredExternal.Add(N);
          end;
        FPackages.Add(P);
      except
        on E: Exception do
          Log('[ERRO] ' + SR.Name + ': ' + E.Message);
      end;
      Doc.Free;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
  Result := FPackages.Count > 0;
  Log('[OK] Packages encontrados: ' + IntToStr(FPackages.Count));
end;

function TInstallerEngine.IsExternalPackageInstalled(const AName: string): Boolean;
const
  BUILTIN_PACKAGES: array[0..11] of string = (
    'lcl', 'lclbase', 'lazutils', 'fcl', 'ideintf', 'codetools',
    'synedit', 'lazcontrols', 'imagesforlazarus', 'debuggerintf',
    'printer4lazarus', 'cthreads'
  );
var
  Files: array[0..2] of string;
  I: Integer;
  S: TStringList;
  OPMDir, SearchFile: string;
  SR: TSearchRec;
begin
  Result := False;
  for I := Low(BUILTIN_PACKAGES) to High(BUILTIN_PACKAGES) do
    if SameText(AName, BUILTIN_PACKAGES[I]) then Exit(True);

  Files[0] := IncludeTrailingPathDelimiter(FPrimaryConfigPath) + 'packagefiles.xml';
  Files[1] := IncludeTrailingPathDelimiter(FPrimaryConfigPath) + 'environmentoptions.xml';
  Files[2] := IncludeTrailingPathDelimiter(ExtractFilePath(FLazBuild)) + 'packagefiles.xml';
  S := TStringList.Create;
  try
    for I := Low(Files) to High(Files) do
      if FileExists(Files[I]) then
      begin
        S.LoadFromFile(Files[I]);
        if Pos(LowerCase(AName), LowerCase(S.Text)) > 0 then Exit(True);
      end;
  finally
    S.Free;
  end;

  {$IFDEF Windows}
  OPMDir := GetEnvironmentVariable('LOCALAPPDATA');
  if OPMDir <> '' then
  begin
    SearchFile := IncludeTrailingPathDelimiter(OPMDir) + 'lazarus' +
      DirectorySeparator + 'onlinepackagemanager' + DirectorySeparator + 'packages';
    if DirectoryExists(SearchFile) then
    begin
      if FindFirst(IncludeTrailingPathDelimiter(SearchFile) + '*' + AName + '*', faDirectory, SR) = 0 then
      begin
        FindClose(SR);
        Exit(True);
      end;
    end;
  end;
  {$ENDIF}
end;

function TInstallerEngine.CheckPrerequisites(out AMissing: string): Boolean;
var
  Missing: TStringList;
  I, J: Integer;
  P: TPackageInfo;
  D: string;
begin
  Missing := TStringList.Create;
  try
    for I := 0 to FPackages.Count - 1 do
    begin
      P := TPackageInfo(FPackages[I]);
      if not P.Selected then Continue;
      for J := 0 to P.RequiredInternal.Count - 1 do
      begin
        D := P.RequiredInternal[J];
        if PackageByName(D) = nil then
          Missing.Add(P.Name + ' -> dependência interna ausente: ' + D);
      end;
      for J := 0 to P.RequiredExternal.Count - 1 do
      begin
        D := P.RequiredExternal[J];
        if not IsExternalPackageInstalled(D) then
          Missing.Add(P.Name + ' -> pré-requisito não localizado: ' + D);
      end;
    end;
    AMissing := Missing.Text;
    Result := Missing.Count = 0;
  finally
    Missing.Free;
  end;
end;

function TInstallerEngine.BuildInstallOrder(AOrder: TStrings;
  out AError: string): Boolean;
var
  State: TStringList;
  I: Integer;

  function Visit(P: TPackageInfo): Boolean;
  var
    J: Integer;
    Dep: TPackageInfo;
    Key, V: string;
  begin
    Result := False;
    Key := LowerCase(P.Name);
    V := State.Values[Key];
    if V = '2' then Exit(True);
    if V = '1' then
    begin
      AError := 'Ciclo de dependência envolvendo ' + P.Name;
      Exit(False);
    end;
    State.Values[Key] := '1';
    for J := 0 to P.RequiredInternal.Count - 1 do
    begin
      Dep := PackageByName(P.RequiredInternal[J]);
      if Assigned(Dep) and Dep.Selected then
        if not Visit(Dep) then Exit(False);
    end;
    State.Values[Key] := '2';
    if AOrder.IndexOf(P.Name) < 0 then AOrder.Add(P.Name);
    Result := True;
  end;

begin
  AOrder.Clear;
  AError := '';
  State := TStringList.Create;
  try
    State.NameValueSeparator := '=';
    for I := 0 to FPackages.Count - 1 do
      if TPackageInfo(FPackages[I]).Selected then
        if not Visit(TPackageInfo(FPackages[I])) then Exit(False);
    Result := True;
  finally
    State.Free;
  end;
end;

function TInstallerEngine.GetInstalledSuitePackages(AList: TStrings): Boolean;
var
  FN: string;
  S: TStringList;
  I, P1, P2: Integer;
  L, N: string;
begin
  AList.Clear;
  FN := IncludeTrailingPathDelimiter(FPrimaryConfigPath) + 'environmentoptions.xml';
  Result := FileExists(FN);
  if not Result then Exit;
  S := TStringList.Create;
  try
    S.LoadFromFile(FN);
    for I := 0 to S.Count - 1 do
    begin
      L := S[I];
      P1 := Pos('openai_', LowerCase(L));
      if P1 = 0 then Continue;
      P2 := P1;
      while (P2 <= Length(L)) and (L[P2] in ['a'..'z','A'..'Z','0'..'9','_','-']) do Inc(P2);
      N := Copy(L, P1, P2-P1);
      if (N <> '') and (AList.IndexOf(N) < 0) then AList.Add(N);
    end;
  finally
    S.Free;
  end;
end;

procedure TInstallerEngine.RemoveOpenAIAutoInstallNodes(ANode: TDOMNode;
  AInsideAutoInstall: Boolean; var ARemoved: Integer);
var
  C, Next: TDOMNode;
  E: TDOMElement;
  Inside: Boolean;
  V: string;
begin
  if ANode = nil then Exit;
  Inside := AInsideAutoInstall or
    (Pos('staticautoinstallpackages', LowerCase(ANode.NodeName)) > 0);
  C := ANode.FirstChild;
  while Assigned(C) do
  begin
    Next := C.NextSibling;
    if Inside and (C is TDOMElement) then
    begin
      E := TDOMElement(C);
      if E.HasAttribute('Value') then
      begin
        V := LowerCase(E.GetAttribute('Value'));
        if Pos('openai_', V) = 1 then
        begin
          ANode.RemoveChild(C);
          C.Free;
          Inc(ARemoved);
          C := Next;
          Continue;
        end;
      end;
    end;
    RemoveOpenAIAutoInstallNodes(C, Inside, ARemoved);
    C := Next;
  end;
end;

function TInstallerEngine.BackupAndRemoveOldPackages(
  out ABackupFile: string): Boolean;
var
  FN: string;
  Doc: TXMLDocument;
  Removed: Integer;
begin
  Result := False;
  ABackupFile := '';
  FN := IncludeTrailingPathDelimiter(FPrimaryConfigPath) + 'environmentoptions.xml';
  if not FileExists(FN) then Exit(True);
  ABackupFile := FN + '.chatgpt_backup_' + FormatDateTime('yyyymmdd_hhnnss', Now);
  if not CopyFile(FN, ABackupFile, [cffOverwriteFile]) then Exit;
  Doc := nil;
  try
    ReadXMLFile(Doc, FN);
    Removed := 0;
    RemoveOpenAIAutoInstallNodes(Doc.DocumentElement, False, Removed);
    WriteXMLFile(Doc, FN);
    Log('[OK] Packages antigos removidos: ' + IntToStr(Removed));
    Result := True;
  except
    on E: Exception do
    begin
      Log('[ERRO] Falha removendo instalação antiga: ' + E.Message);
      CopyFile(ABackupFile, FN, [cffOverwriteFile]);
    end;
  end;
  Doc.Free;
end;

function TInstallerEngine.CleanSuiteBuildCaches: Boolean;
var
  SR: TSearchRec;
  Dir, FN: string;

  procedure DeleteTree(const ADir: string);
  var
    R: TSearchRec;
    X: string;
  begin
    if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, R) = 0 then
    try
      repeat
        if (R.Name = '.') or (R.Name = '..') then Continue;
        X := IncludeTrailingPathDelimiter(ADir) + R.Name;
        if (R.Attr and faDirectory) <> 0 then DeleteTree(X)
        else DeleteFile(X);
      until FindNext(R) <> 0;
    finally
      FindClose(R);
    end;
    RemoveDir(ADir);
  end;

begin
  Result := True;
  Dir := IncludeTrailingPathDelimiter(FRepoRoot) + 'pacote';
  if FindFirst(IncludeTrailingPathDelimiter(Dir) + '*', faDirectory, SR) = 0 then
  try
    repeat
      if (SR.Name = '.') or (SR.Name = '..') then Continue;
      if (SR.Attr and faDirectory) = 0 then Continue;
      FN := IncludeTrailingPathDelimiter(Dir) + SR.Name + DirectorySeparator + 'lib';
      if DirectoryExists(FN) then DeleteTree(FN);
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

function TInstallerEngine.CompileSelected(AOrder: TStrings): Boolean;
var
  I, RC: Integer;
  P: TPackageInfo;
  OutText: string;
begin
  Result := True;
  for I := 0 to AOrder.Count - 1 do
  begin
    P := PackageByName(AOrder[I]);
    if not Assigned(P) then Continue;
    Log('[COMPILANDO] ' + P.Name);
    P.CompileOK := RunCapture(FLazBuild,
      ['--build-all', '--cpu=' + FTargetCPU, '--os=' + FTargetOS,
       '--primary-config-path=' + FPrimaryConfigPath, P.FileName], OutText, RC);
    if not P.CompileOK then
    begin
      Log(OutText);
      Exit(False);
    end;
  end;
end;

function TInstallerEngine.RegisterSelected(AOrder: TStrings): Boolean;
var
  I, RC: Integer;
  P: TPackageInfo;
  OutText: string;
begin
  Result := True;
  for I := 0 to AOrder.Count - 1 do
  begin
    P := PackageByName(AOrder[I]);
    if not Assigned(P) or not P.CompileOK then Continue;
    if P.IsRuntimeOnly then
    begin
      Log('[REGISTRANDO LINK RUNTIME] ' + P.Name);
      P.InstallOK := RunCapture(FLazBuild,
        ['--primary-config-path=' + FPrimaryConfigPath,
         '--add-package-link', P.FileName], OutText, RC);
    end
    else
    begin
      Log('[INSTALANDO] ' + P.Name);
      P.InstallOK := RunCapture(FLazBuild,
        ['--primary-config-path=' + FPrimaryConfigPath,
         '--add-package', P.FileName], OutText, RC);
    end;
    if not P.InstallOK then
    begin
      Log(OutText);
      Exit(False);
    end;
  end;
end;

function TInstallerEngine.RebuildIDE: Boolean;
var
  RC: Integer;
  OutText: string;
begin
  Log('[IDE] Recompilando IDE...');
  Result := RunCapture(FLazBuild,
    ['--cpu=' + FTargetCPU, '--os=' + FTargetOS,
     '--primary-config-path=' + FPrimaryConfigPath, '--build-ide='], OutText, RC);
  if not Result then Log(OutText);
end;

function TInstallerEngine.VerifyInstalled(AOrder, AResult: TStrings): Boolean;
var
  Installed: TStringList;
  I: Integer;
  P: TPackageInfo;
begin
  Installed := TStringList.Create;
  try
    GetInstalledSuitePackages(Installed);
    AResult.Clear;
    Result := True;
    for I := 0 to AOrder.Count - 1 do
    begin
      P := PackageByName(AOrder[I]);
      if (Installed.IndexOf(AOrder[I]) >= 0) or (Assigned(P) and P.IsRuntimeOnly) then
        AResult.Add('[OK] ' + AOrder[I])
      else
      begin
        AResult.Add('[FALTA] ' + AOrder[I]);
        Result := False;
      end;
    end;
  finally
    Installed.Free;
  end;
end;

function TInstallerEngine.ScanSamples(AList: TStrings): Boolean;
var
  Base: string;
  procedure Walk(const ADir: string);
  var
    SR: TSearchRec;
    FN: string;
  begin
    if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, SR) = 0 then
    try
      repeat
        if (SR.Name = '.') or (SR.Name = '..') then Continue;
        FN := IncludeTrailingPathDelimiter(ADir) + SR.Name;
        if (SR.Attr and faDirectory) <> 0 then Walk(FN)
        else if SameText(ExtractFileExt(SR.Name), '.lpi') then AList.Add(FN);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
begin
  AList.Clear;
  Base := IncludeTrailingPathDelimiter(FRepoRoot) + 'pacote' + DirectorySeparator + 'samples';
  Result := DirectoryExists(Base);
  if Result then Walk(Base);
end;

function TInstallerEngine.CompileSamples(AList, AResult: TStrings): Boolean;
var
  I, RC: Integer;
  S: string;
begin
  Result := True;
  AResult.Clear;
  for I := 0 to AList.Count - 1 do
    if RunCapture(FLazBuild,
      ['--build-all', '--cpu=' + FTargetCPU, '--os=' + FTargetOS,
       '--primary-config-path=' + FPrimaryConfigPath, AList[I]], S, RC) then
      AResult.Add('[OK] ' + AList[I] + ' [' + IntToStr(FTargetBits) + ' bits]')
    else
    begin
      AResult.Add('[ERRO] ' + AList[I]);
      Log(S);
      Result := False;
    end;
end;

function TInstallerEngine.ValidateDocumentation(AResult: TStrings): Boolean;
const
  DOCS: array[0..4] of string = (
    'README.md', 'INSTALL.md', 'ReadMe.txt', 'pacote/COMPONENT_STATUS.md', 'pacote/DOC');
var
  I: Integer;
  FN: string;
begin
  AResult.Clear;
  Result := True;
  for I := Low(DOCS) to High(DOCS) do
  begin
    FN := IncludeTrailingPathDelimiter(FRepoRoot) + DOCS[I];
    if FileExists(FN) or DirectoryExists(FN) then AResult.Add('[OK] ' + DOCS[I])
    else
    begin
      AResult.Add('[FALTA] ' + DOCS[I]);
      Result := False;
    end;
  end;
end;

function TInstallerEngine.CopyDocumentation(const ADestination: string;
  AResult: TStrings): Boolean;
var
  Dst: string;
  procedure CopyTree(const Src, DstDir: string);
  var
    SR: TSearchRec;
    S, D: string;
  begin
    ForceDirectories(DstDir);
    if FindFirst(IncludeTrailingPathDelimiter(Src) + '*', faAnyFile, SR) = 0 then
    try
      repeat
        if (SR.Name = '.') or (SR.Name = '..') then Continue;
        S := IncludeTrailingPathDelimiter(Src) + SR.Name;
        D := IncludeTrailingPathDelimiter(DstDir) + SR.Name;
        if (SR.Attr and faDirectory) <> 0 then CopyTree(S, D)
        else CopyFile(S, D, [cffOverwriteFile]);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
  procedure CopyOne(const Rel: string);
  var
    S, D: string;
  begin
    S := IncludeTrailingPathDelimiter(FRepoRoot) + Rel;
    D := IncludeTrailingPathDelimiter(Dst) + ExtractFileName(Rel);
    if FileExists(S) then CopyFile(S, D, [cffOverwriteFile]);
  end;
begin
  Dst := IncludeTrailingPathDelimiter(ADestination) + 'docs';
  ForceDirectories(Dst);
  CopyOne('README.md');
  CopyOne('INSTALL.md');
  CopyOne('ReadMe.txt');
  CopyOne('pacote' + DirectorySeparator + 'COMPONENT_STATUS.md');
  if DirectoryExists(IncludeTrailingPathDelimiter(FRepoRoot) + 'pacote' + DirectorySeparator + 'DOC') then
    CopyTree(IncludeTrailingPathDelimiter(FRepoRoot) + 'pacote' + DirectorySeparator + 'DOC',
      IncludeTrailingPathDelimiter(Dst) + 'components');
  AResult.Add('[OK] Documentação copiada para ' + Dst);
  Result := True;
end;

end.
