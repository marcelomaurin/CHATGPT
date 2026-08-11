unit aiagent_supervisor;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, aiagent_deterministicmemory, aiagent_capabilityrouter;

type
  TAISupervisorReview = record
    Approved: Boolean;
    ReviewerScore: Double;
    FailureKind: string;
    CorrectionsRequired: Integer;
    ShouldEscalate: Boolean;
    ShouldTrain: Boolean;
    Notes: string;
  end;

  { Deterministic bookkeeping around the strong model. The LLM produces the
    review; this class records facts and makes routing/training consequences
    reproducible. }
  TAIStrongSupervisor = class
  private
    FRegistry: TAIAgentMemoryRegistry;
    FRouter: TAIAgentCapabilityRouter;
  public
    constructor Create(ARegistry: TAIAgentMemoryRegistry;
      ARouter: TAIAgentCapabilityRouter);
    procedure RecordReviewedExecution(const Q: TAITaskQualification;
      const AAgentId, AModelId: string; ASuccess, ABuildPassed,
      ATestsPassed: Boolean; ARetries: Integer; const R: TAISupervisorReview);
    function ChooseAgent(const Q: TAITaskQualification;
      AMinimumScore: Double): TAIAgentRouteDecision;
  end;

implementation

constructor TAIStrongSupervisor.Create(ARegistry: TAIAgentMemoryRegistry;
  ARouter: TAIAgentCapabilityRouter);
begin
  inherited Create;
  FRegistry := ARegistry;
  FRouter := ARouter;
end;

procedure TAIStrongSupervisor.RecordReviewedExecution(
  const Q: TAITaskQualification; const AAgentId, AModelId: string;
  ASuccess, ABuildPassed, ATestsPassed: Boolean; ARetries: Integer;
  const R: TAISupervisorReview);
var
  E: TAIAgentTaskEvidence;
  M: TAIDeterministicAgentMemory;
begin
  FillChar(E, SizeOf(E), 0);
  E.AgentId := AAgentId;
  E.ModelId := AModelId;
  E.Fingerprint := TAIDeterministicAgentMemory.TaskFingerprint(Q);
  E.Success := ASuccess and R.Approved;
  E.BuildPassed := ABuildPassed;
  E.TestsPassed := ATestsPassed;
  E.ReviewerScore := R.ReviewerScore;
  E.Retries := ARetries;
  E.CorrectionsRequired := R.CorrectionsRequired;
  E.FailureKind := R.FailureKind;
  E.Timestamp := Now;

  M := FRegistry.AgentMemory(AAgentId);
  try
    M.RecordEvidence(E);
  finally
    M.Free;
  end;

  { Strong/global memory receives the same immutable evidence so it can
    compare specialists across domains without specialists sharing memory. }
  M := FRegistry.GlobalMemory;
  try
    M.RecordEvidence(E);
  finally
    M.Free;
  end;
end;

function TAIStrongSupervisor.ChooseAgent(const Q: TAITaskQualification;
  AMinimumScore: Double): TAIAgentRouteDecision;
begin
  Result := FRouter.SelectBest(Q, AMinimumScore);
end;

end.
