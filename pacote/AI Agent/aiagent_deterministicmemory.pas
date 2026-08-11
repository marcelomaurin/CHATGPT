unit aiagent_deterministicmemory;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, md5;

type
  TAITaskQualification = record
    Domain: string;
    SubDomain: string;
    TaskType: string;
    Language: string;
    Framework: string;
    Complexity: Double;
    Risk: Double;
    Scope: string;
    RequiredCapabilities: string;
  end;

  TAIAgentTaskEvidence = record
    AgentId: string;
    ModelId: string;
    Fingerprint: string;
    Success: Boolean;
    BuildPassed: Boolean;
    TestsPassed: Boolean;
    ReviewerScore: Double;
    Retries: Integer;
    CorrectionsRequired: Integer;
    FailureKind: string;
    Timestamp: TDateTime;
  end;

  { Deterministic JSON memory. Each agent gets its own file; the strong
    supervisor gets a global file containing cross-agent evidence. }
  TAIDeterministicAgentMemory = class
  private
    FRootDirectory: string;
    FAgentId: string;
    FGlobalSupervisor: Boolean;
    function Normalize(const S: string): string;
    function MemoryFileName: string;
    function LoadRoot: TJSONObject;
    procedure SaveRoot(ARoot: TJSONObject);
  public
    constructor Create(const ARootDirectory, AAgentId: string;
      AGlobalSupervisor: Boolean = False);
    class function TaskFingerprint(const Q: TAITaskQualification): string;
    procedure RecordEvidence(const E: TAIAgentTaskEvidence);
    function ScoreForTask(const Q: TAITaskQualification;
      const AAgentId: string = ''): Double;
    function SimilarEvidenceCount(const Q: TAITaskQualification;
      const AAgentId: string = ''): Integer;
    property RootDirectory: string read FRootDirectory;
    property AgentId: string read FAgentId;
    property GlobalSupervisor: Boolean read FGlobalSupervisor;
  end;

  { Registry guarantees one deterministic memory namespace per specialist
    plus one global supervisor namespace. }
  TAIAgentMemoryRegistry = class
  private
    FRootDirectory: string;
  public
    constructor Create(const ARootDirectory: string);
    function AgentMemory(const AAgentId: string): TAIDeterministicAgentMemory;
    function GlobalMemory: TAIDeterministicAgentMemory;
    property RootDirectory: string read FRootDirectory;
  end;

implementation

function Clamp01(const V: Double): Double;
begin
  if V < 0 then Exit(0);
  if V > 1 then Exit(1);
  Result := V;
end;

constructor TAIDeterministicAgentMemory.Create(const ARootDirectory,
  AAgentId: string; AGlobalSupervisor: Boolean);
begin
  inherited Create;
  FRootDirectory := ExpandFileName(ARootDirectory);
  FAgentId := Trim(AAgentId);
  FGlobalSupervisor := AGlobalSupervisor;
  if FAgentId = '' then FAgentId := 'anonymous';
  ForceDirectories(FRootDirectory);
end;

function TAIDeterministicAgentMemory.Normalize(const S: string): string;
begin
  Result := LowerCase(Trim(S));
  Result := StringReplace(Result, '|', '_', [rfReplaceAll]);
  Result := StringReplace(Result, LineEnding, ' ', [rfReplaceAll]);
end;

class function TAIDeterministicAgentMemory.TaskFingerprint(
  const Q: TAITaskQualification): string;
var
  Raw: string;
begin
  Raw := LowerCase(Trim(Q.Domain)) + '|' + LowerCase(Trim(Q.SubDomain)) + '|' +
    LowerCase(Trim(Q.TaskType)) + '|' + LowerCase(Trim(Q.Language)) + '|' +
    LowerCase(Trim(Q.Framework)) + '|' + LowerCase(Trim(Q.Scope)) + '|' +
    LowerCase(Trim(Q.RequiredCapabilities)) + '|' +
    IntToStr(Round(Clamp01(Q.Complexity) * 10)) + '|' +
    IntToStr(Round(Clamp01(Q.Risk) * 10));
  Result := MD5Print(MD5String(Raw));
end;

function TAIDeterministicAgentMemory.MemoryFileName: string;
var
  N: string;
begin
  if FGlobalSupervisor then
    N := 'global-supervisor'
  else
    N := Normalize(FAgentId);
  N := StringReplace(N, '/', '_', [rfReplaceAll]);
  N := StringReplace(N, '\', '_', [rfReplaceAll]);
  Result := IncludeTrailingPathDelimiter(FRootDirectory) + N + '.json';
end;

function TAIDeterministicAgentMemory.LoadRoot: TJSONObject;
var
  S: TStringList;
  D: TJSONData;
begin
  Result := TJSONObject.Create;
  if not FileExists(MemoryFileName) then Exit;
  S := TStringList.Create;
  try
    S.LoadFromFile(MemoryFileName);
    if Trim(S.Text) = '' then Exit;
    D := GetJSON(S.Text);
    if D.JSONType = jtObject then
    begin
      Result.Free;
      Result := TJSONObject(D);
    end
    else
      D.Free;
  finally
    S.Free;
  end;
end;

procedure TAIDeterministicAgentMemory.SaveRoot(ARoot: TJSONObject);
var
  S: TStringList;
  Tmp: string;
begin
  ForceDirectories(FRootDirectory);
  Tmp := MemoryFileName + '.tmp';
  S := TStringList.Create;
  try
    S.Text := ARoot.FormatJSON;
    S.SaveToFile(Tmp);
    if FileExists(MemoryFileName) then DeleteFile(MemoryFileName);
    if not RenameFile(Tmp, MemoryFileName) then
      raise Exception.Create('Não foi possível persistir o mapa determinístico.');
  finally
    S.Free;
    if FileExists(Tmp) then DeleteFile(Tmp);
  end;
end;

procedure TAIDeterministicAgentMemory.RecordEvidence(
  const E: TAIAgentTaskEvidence);
var
  Root, Bucket, Item: TJSONObject;
  Arr: TJSONArray;
  Key, EffectiveAgent: string;
begin
  Root := LoadRoot;
  try
    Key := E.Fingerprint;
    if Key = '' then raise Exception.Create('Fingerprint da tarefa não informado.');
    Bucket := Root.Objects[Key];
    if Bucket = nil then
    begin
      Bucket := TJSONObject.Create;
      Root.Add(Key, Bucket);
      Bucket.Add('evidence', TJSONArray.Create);
    end;
    Arr := Bucket.Arrays['evidence'];
    EffectiveAgent := Trim(E.AgentId);
    if EffectiveAgent = '' then EffectiveAgent := FAgentId;
    Item := TJSONObject.Create;
    Item.Add('agent_id', EffectiveAgent);
    Item.Add('model_id', E.ModelId);
    Item.Add('success', E.Success);
    Item.Add('build_passed', E.BuildPassed);
    Item.Add('tests_passed', E.TestsPassed);
    Item.Add('reviewer_score', E.ReviewerScore);
    Item.Add('retries', E.Retries);
    Item.Add('corrections_required', E.CorrectionsRequired);
    Item.Add('failure_kind', E.FailureKind);
    Item.Add('timestamp', DateTimeToStr(E.Timestamp));
    Arr.Add(Item);
    SaveRoot(Root);
  finally
    Root.Free;
  end;
end;

function TAIDeterministicAgentMemory.SimilarEvidenceCount(
  const Q: TAITaskQualification; const AAgentId: string): Integer;
var
  Root, Bucket: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  Filter: string;
begin
  Result := 0;
  Root := LoadRoot;
  try
    Bucket := Root.Objects[TaskFingerprint(Q)];
    if Bucket = nil then Exit;
    Arr := Bucket.Arrays['evidence'];
    if Arr = nil then Exit;
    Filter := Trim(AAgentId);
    for I := 0 to Arr.Count - 1 do
      if (Filter = '') or SameText(Arr.Objects[I].Get('agent_id', ''), Filter) then
        Inc(Result);
  finally
    Root.Free;
  end;
end;

function TAIDeterministicAgentMemory.ScoreForTask(
  const Q: TAITaskQualification; const AAgentId: string): Double;
var
  Root, Bucket: TJSONObject;
  Arr: TJSONArray;
  I, N: Integer;
  O: TJSONObject;
  Filter: string;
  V, Sum, Weight: Double;
begin
  Result := 0;
  Root := LoadRoot;
  try
    Bucket := Root.Objects[TaskFingerprint(Q)];
    if Bucket = nil then Exit;
    Arr := Bucket.Arrays['evidence'];
    if Arr = nil then Exit;
    Filter := Trim(AAgentId);
    Sum := 0;
    N := 0;
    for I := 0 to Arr.Count - 1 do
    begin
      O := Arr.Objects[I];
      if (Filter <> '') and not SameText(O.Get('agent_id', ''), Filter) then Continue;
      V := O.Get('reviewer_score', 0.0) / 100.0;
      if O.Get('success', False) then V := V + 0.20 else V := V - 0.25;
      if O.Get('build_passed', False) then V := V + 0.10;
      if O.Get('tests_passed', False) then V := V + 0.10;
      V := V - (O.Get('retries', 0) * 0.04);
      V := V - (O.Get('corrections_required', 0) * 0.05);
      if O.Get('failure_kind', '') <> '' then V := V - 0.08;
      Weight := 1.0 + (I / (Arr.Count + 1)); { recent evidence weighs slightly more }
      Sum := Sum + Clamp01(V) * Weight;
      Inc(N);
    end;
    if N > 0 then Result := 100.0 * Sum / N / 1.5;
    if Result > 100 then Result := 100;
  finally
    Root.Free;
  end;
end;

constructor TAIAgentMemoryRegistry.Create(const ARootDirectory: string);
begin
  inherited Create;
  FRootDirectory := ExpandFileName(ARootDirectory);
  ForceDirectories(FRootDirectory);
end;

function TAIAgentMemoryRegistry.AgentMemory(
  const AAgentId: string): TAIDeterministicAgentMemory;
begin
  Result := TAIDeterministicAgentMemory.Create(FRootDirectory, AAgentId, False);
end;

function TAIAgentMemoryRegistry.GlobalMemory: TAIDeterministicAgentMemory;
begin
  Result := TAIDeterministicAgentMemory.Create(FRootDirectory, 'strong-supervisor', True);
end;

end.
