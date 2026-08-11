unit aiagent_capabilityrouter;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Contnrs, aiagent_deterministicmemory;

type
  TAIAgentCapability = class
  public
    AgentId: string;
    ModelId: string;
    Domains: string;
    TaskTypes: string;
    Languages: string;
    Frameworks: string;
    MaxComplexity: Double;
    MaxRisk: Double;
    CostWeight: Double;
    IsStrongModel: Boolean;
  end;

  TAIAgentRouteDecision = record
    AgentId: string;
    ModelId: string;
    Score: Double;
    HistoricalScore: Double;
    QualificationScore: Double;
    Reason: string;
  end;

  { Scores an agent for THIS task, not by a single global reputation. }
  TAIAgentCapabilityRouter = class
  private
    FCapabilities: TObjectList;
    FRegistry: TAIAgentMemoryRegistry;
    function ContainsToken(const AList, AValue: string): Boolean;
    function QualificationFit(C: TAIAgentCapability;
      const Q: TAITaskQualification): Double;
  public
    constructor Create(ARegistry: TAIAgentMemoryRegistry);
    destructor Destroy; override;
    function RegisterAgent(const AAgentId, AModelId, ADomains, ATaskTypes,
      ALanguages, AFrameworks: string; AMaxComplexity, AMaxRisk,
      ACostWeight: Double; AIsStrongModel: Boolean = False): TAIAgentCapability;
    function SelectBest(const Q: TAITaskQualification;
      AMinimumScore: Double = 0): TAIAgentRouteDecision;
    function CanPerform(const AAgentId: string; const Q: TAITaskQualification;
      AMinimumScore: Double; out AScore: Double): Boolean;
  end;

implementation

constructor TAIAgentCapabilityRouter.Create(ARegistry: TAIAgentMemoryRegistry);
begin
  inherited Create;
  FRegistry := ARegistry;
  FCapabilities := TObjectList.Create(True);
end;

destructor TAIAgentCapabilityRouter.Destroy;
begin
  FCapabilities.Free;
  inherited Destroy;
end;

function TAIAgentCapabilityRouter.ContainsToken(const AList, AValue: string): Boolean;
var
  L, V: string;
begin
  V := LowerCase(Trim(AValue));
  if V = '' then Exit(True);
  L := ',' + LowerCase(StringReplace(AList, ' ', '', [rfReplaceAll])) + ',';
  Result := (Pos(',' + V + ',', L) > 0) or (Pos(',*,', L) > 0);
end;

function TAIAgentCapabilityRouter.QualificationFit(C: TAIAgentCapability;
  const Q: TAITaskQualification): Double;
var
  P: Double;
begin
  P := 0;
  if ContainsToken(C.Domains, Q.Domain) then P := P + 25;
  if ContainsToken(C.TaskTypes, Q.TaskType) then P := P + 20;
  if ContainsToken(C.Languages, Q.Language) then P := P + 15;
  if ContainsToken(C.Frameworks, Q.Framework) then P := P + 15;
  if Q.Complexity <= C.MaxComplexity then P := P + 12 else P := P - 20;
  if Q.Risk <= C.MaxRisk then P := P + 8 else P := P - 25;
  P := P + (5 * (1 - C.CostWeight));
  if P < 0 then P := 0;
  if P > 100 then P := 100;
  Result := P;
end;

function TAIAgentCapabilityRouter.RegisterAgent(const AAgentId, AModelId,
  ADomains, ATaskTypes, ALanguages, AFrameworks: string; AMaxComplexity,
  AMaxRisk, ACostWeight: Double; AIsStrongModel: Boolean): TAIAgentCapability;
begin
  Result := TAIAgentCapability.Create;
  Result.AgentId := AAgentId;
  Result.ModelId := AModelId;
  Result.Domains := ADomains;
  Result.TaskTypes := ATaskTypes;
  Result.Languages := ALanguages;
  Result.Frameworks := AFrameworks;
  Result.MaxComplexity := AMaxComplexity;
  Result.MaxRisk := AMaxRisk;
  Result.CostWeight := ACostWeight;
  Result.IsStrongModel := AIsStrongModel;
  FCapabilities.Add(Result);
end;

function TAIAgentCapabilityRouter.SelectBest(const Q: TAITaskQualification;
  AMinimumScore: Double): TAIAgentRouteDecision;
var
  I, Count: Integer;
  C: TAIAgentCapability;
  M: TAIDeterministicAgentMemory;
  H, F, S: Double;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Score := -1;
  for I := 0 to FCapabilities.Count - 1 do
  begin
    C := TAIAgentCapability(FCapabilities[I]);
    F := QualificationFit(C, Q);
    M := FRegistry.AgentMemory(C.AgentId);
    try
      Count := M.SimilarEvidenceCount(Q);
      H := M.ScoreForTask(Q);
    finally
      M.Free;
    end;
    if Count = 0 then
      S := F
    else
      S := (F * 0.45) + (H * 0.55);
    if S > Result.Score then
    begin
      Result.AgentId := C.AgentId;
      Result.ModelId := C.ModelId;
      Result.Score := S;
      Result.HistoricalScore := H;
      Result.QualificationScore := F;
      Result.Reason := Format('task-fit=%.1f history=%.1f similar=%d', [F, H, Count]);
    end;
  end;
  if Result.Score < AMinimumScore then
  begin
    Result.AgentId := '';
    Result.ModelId := '';
    Result.Reason := 'Nenhum agente atingiu o score mínimo para esta questão.';
  end;
end;

function TAIAgentCapabilityRouter.CanPerform(const AAgentId: string;
  const Q: TAITaskQualification; AMinimumScore: Double; out AScore: Double): Boolean;
var
  I, Count: Integer;
  C: TAIAgentCapability;
  M: TAIDeterministicAgentMemory;
  F, H: Double;
begin
  AScore := 0;
  for I := 0 to FCapabilities.Count - 1 do
  begin
    C := TAIAgentCapability(FCapabilities[I]);
    if not SameText(C.AgentId, AAgentId) then Continue;
    F := QualificationFit(C, Q);
    M := FRegistry.AgentMemory(C.AgentId);
    try
      Count := M.SimilarEvidenceCount(Q);
      H := M.ScoreForTask(Q);
    finally
      M.Free;
    end;
    if Count = 0 then AScore := F else AScore := F * 0.45 + H * 0.55;
    Exit(AScore >= AMinimumScore);
  end;
  Result := False;
end;

end.
