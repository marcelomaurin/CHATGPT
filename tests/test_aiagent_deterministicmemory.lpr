program test_aiagent_deterministicmemory;

{$mode objfpc}{$H+}

uses
  SysUtils, aiagent_deterministicmemory, aiagent_capabilityrouter,
  aiagent_supervisor;

procedure AssertTrue(V: Boolean; const M: string);
begin
  if not V then raise Exception.Create(M);
end;

var
  Root: string;
  Reg: TAIAgentMemoryRegistry;
  Router: TAIAgentCapabilityRouter;
  Supervisor: TAIStrongSupervisor;
  Q: TAITaskQualification;
  R: TAISupervisorReview;
  D: TAIAgentRouteDecision;
  I: Integer;
  M: TAIDeterministicAgentMemory;
  ID: TGUID;
begin
  CreateGUID(ID);
  Root := IncludeTrailingPathDelimiter(GetTempDir) + 'aiagent-memory-test-' + GUIDToString(ID);
  ForceDirectories(Root);
  Reg := TAIAgentMemoryRegistry.Create(Root);
  Router := TAIAgentCapabilityRouter.Create(Reg);
  Supervisor := TAIStrongSupervisor.Create(Reg, Router);
  try
    Router.RegisterAgent('source-light', 'local-small', 'source', 'bug_fix',
      'pascal', 'lazarus', 0.70, 0.60, 0.10, False);
    Router.RegisterAgent('source-strong', 'large', 'source', 'bug_fix',
      'pascal', 'lazarus', 1.0, 1.0, 0.90, True);

    FillChar(Q, SizeOf(Q), 0);
    Q.Domain := 'source'; Q.TaskType := 'bug_fix'; Q.Language := 'pascal';
    Q.Framework := 'lazarus'; Q.Scope := 'multi_file'; Q.Complexity := 0.55;
    Q.Risk := 0.40; Q.RequiredCapabilities := 'source_edit,build';

    M := Reg.AgentMemory('source-light');
    try
      AssertTrue(M.SimilarEvidenceCount(Q) = 0, 'New task must have no evidence.');
      AssertTrue(M.ScoreForTask(Q) = 0, 'New task must have zero score.');
    finally
      M.Free;
    end;

    FillChar(R, SizeOf(R), 0);
    R.Approved := True; R.ReviewerScore := 96;
    for I := 1 to 3 do
      Supervisor.RecordReviewedExecution(Q, 'source-light', 'local-small',
        True, True, True, 0, R);

    D := Supervisor.ChooseAgent(Q, 50);
    AssertTrue(D.AgentId = 'source-light', 'Histórico por tipo de questão não favoreceu o modelo leve competente.');

    M := Reg.AgentMemory('source-light');
    try
      AssertTrue(M.SimilarEvidenceCount(Q) = 3, 'Evidence must survive reopening.');
      AssertTrue(Abs(M.ScoreForTask(Q) - 100) < 0.001,
        'Perfect evidence must score 100 regardless of evidence count.');
      Q.SubDomain := 'previously-unseen';
      AssertTrue(M.SimilarEvidenceCount(Q) = 0, 'Unseen task must have no evidence.');
      AssertTrue(M.ScoreForTask(Q) = 0, 'Unseen task must have zero score.');
      Q.SubDomain := '';
    finally
      M.Free;
    end;

    Q.Complexity := 0.95; Q.Risk := 0.90;
    D := Supervisor.ChooseAgent(Q, 50);
    AssertTrue(D.AgentId = 'source-strong', 'Questão acima da capacidade não escalou para modelo forte.');

    AssertTrue(FileExists(IncludeTrailingPathDelimiter(Root) + 'source-light.json'),
      'Mapa determinístico individual não foi persistido.');
    AssertTrue(FileExists(IncludeTrailingPathDelimiter(Root) + 'global-supervisor.json'),
      'Mapa global do supervisor não foi persistido.');
    WriteLn('PASS');
  finally
    Supervisor.Free;
    Router.Free;
    Reg.Free;
    DeleteFile(IncludeTrailingPathDelimiter(Root) + 'source-light.json');
    DeleteFile(IncludeTrailingPathDelimiter(Root) + 'global-supervisor.json');
    RemoveDir(Root);
  end;
end.
