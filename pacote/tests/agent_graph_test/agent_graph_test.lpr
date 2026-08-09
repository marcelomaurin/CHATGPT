program agent_graph_test;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, aiagent, aiagentgraph;

type
  TFlowHost = class
  public
    PrepareExecutions: Integer;
    CommitExecutions: Integer;
    RejectExecutions: Integer;
    procedure Prepare(Sender: TObject; ANode: TAIAgentNode;
      const AInput: string; AMode: TAIAgentExecutionMode;
      out AOutput: string; var ASuccess: Boolean);
    procedure Commit(Sender: TObject; ANode: TAIAgentNode;
      const AInput: string; AMode: TAIAgentExecutionMode;
      out AOutput: string; var ASuccess: Boolean);
    procedure Rejected(Sender: TObject; ANode: TAIAgentNode;
      const AInput: string; AMode: TAIAgentExecutionMode;
      out AOutput: string; var ASuccess: Boolean);
  end;

procedure Fail(const AMessage: string);
begin Writeln(StdErr, 'FAIL: ', AMessage); Halt(1); end;

procedure Check(ACondition: Boolean; const AMessage: string);
begin if not ACondition then Fail(AMessage); end;

procedure TFlowHost.Prepare(Sender: TObject; ANode: TAIAgentNode;
  const AInput: string; AMode: TAIAgentExecutionMode;
  out AOutput: string; var ASuccess: Boolean);
begin
  Inc(PrepareExecutions);
  AOutput := 'preparado:' + AInput;
  ASuccess := True;
end;

procedure TFlowHost.Commit(Sender: TObject; ANode: TAIAgentNode;
  const AInput: string; AMode: TAIAgentExecutionMode;
  out AOutput: string; var ASuccess: Boolean);
begin
  Inc(CommitExecutions);
  AOutput := 'efeito real confirmado';
  ASuccess := True;
end;

procedure TFlowHost.Rejected(Sender: TObject; ANode: TAIAgentNode;
  const AInput: string; AMode: TAIAgentExecutionMode;
  out AOutput: string; var ASuccess: Boolean);
begin
  Inc(RejectExecutions);
  AOutput := 'fluxo de rejeicao concluido';
  ASuccess := True;
end;

procedure BuildGraph(AGraph: TAIAgentGraph; AHost: TFlowHost);
begin
  AGraph.AddNode('prepare', 'Preparar', agnAction).OnExecute := @AHost.Prepare;
  AGraph.AddNode('approval', 'Aprovar', agnApproval);
  AGraph.AddNode('commit', 'Executar', agnAction).OnExecute := @AHost.Commit;
  AGraph.AddNode('rejected', 'Rejeitado', agnAction).OnExecute := @AHost.Rejected;
  AGraph.AddNode('end', 'Fim', agnEnd);
  AGraph.AddEdge('prepare', 'approval', aecOnSuccess);
  AGraph.AddEdge('approval', 'commit', aecOnApproved);
  AGraph.AddEdge('approval', 'rejected', aecOnRejected);
  AGraph.AddEdge('commit', 'end', aecOnSuccess);
  AGraph.AddEdge('rejected', 'end', aecOnSuccess);
  AGraph.StartNodeID := 'prepare';
end;

function ContainsText(AList: TStrings; const AText: string): Boolean;
var I: Integer;
begin
  for I := 0 to AList.Count - 1 do
    if Pos(AText, AList[I]) > 0 then Exit(True);
  Result := False;
end;

var
  Host: TFlowHost;
  Graph, Resumed, RejectedGraph, SimulationGraph, DryRunGraph,
    DelegationGraph: TAIAgentGraph;
  DelegateAgent: TAIAgent;
  TempCheckpoint, InvalidCheckpoint: string;
  InvalidFile: TStringList;
begin
  Host := TFlowHost.Create;
  Graph := TAIAgentGraph.Create(nil);
  Resumed := TAIAgentGraph.Create(nil);
  RejectedGraph := TAIAgentGraph.Create(nil);
  SimulationGraph := TAIAgentGraph.Create(nil);
  DryRunGraph := TAIAgentGraph.Create(nil);
  DelegationGraph := TAIAgentGraph.Create(nil);
  DelegateAgent := TAIAgent.Create(nil);
  TempCheckpoint := IncludeTrailingPathDelimiter(GetTempDir(False)) +
    'agent_graph_' + IntToStr(GetTickCount64) + '.json';
  InvalidCheckpoint := TempCheckpoint + '.invalid';
  try
    BuildGraph(Graph, Host);
    Check(Graph.NodeCount = 5, 'quantidade de nodes incorreta');
    Check(Graph.EdgeCount = 5, 'quantidade de edges incorreta');
    Check(not Graph.Run('pedido-1'), 'Run deveria pausar para aprovacao');
    Check(Graph.State = agsNeedsApproval, 'estado NeedsApproval nao aplicado');
    Check(Graph.CurrentNodeID = 'approval', 'node atual de aprovacao incorreto');
    Check(Host.PrepareExecutions = 1, 'prepare real nao executou uma vez');
    Check(Host.CommitExecutions = 0, 'commit executou antes da aprovacao');
    Check(Graph.SaveCheckpoint(TempCheckpoint), 'SaveCheckpoint falhou');

    BuildGraph(Resumed, Host);
    Check(Resumed.LoadCheckpoint(TempCheckpoint), 'LoadCheckpoint falhou: ' + Resumed.LastError);
    Check(Resumed.State = agsNeedsApproval, 'checkpoint nao preservou estado');
    Check(not Resumed.Resume, 'Resume ignorou aprovacao pendente');
    Check(Resumed.AcceptApproval, 'AcceptApproval/Resume falhou: ' + Resumed.LastError);
    Check(Resumed.State = agsCompleted, 'fluxo aprovado nao completou');
    Check(Host.CommitExecutions = 1, 'commit real nao executou exatamente uma vez');
    Check(Pos('efeito real', Resumed.PreviousResult) > 0,
      'resultado anterior nao preservado ate o fim');

    BuildGraph(RejectedGraph, Host);
    Check(not RejectedGraph.Run('pedido-2'), 'fluxo rejeitado nao pausou');
    Check(RejectedGraph.RejectApproval, 'RejectApproval nao continuou o fluxo');
    Check(RejectedGraph.State = agsCompleted, 'ramo rejeitado nao completou');
    Check(Host.RejectExecutions = 1, 'handler do ramo rejeitado nao executou');
    Check(Host.CommitExecutions = 1, 'ramo rejeitado executou commit');

    BuildGraph(SimulationGraph, Host);
    SimulationGraph.ExecutionMode := aemSimulation;
    Check(not SimulationGraph.Run('simular'), 'simulacao deveria pausar em aprovacao');
    Check(Host.PrepareExecutions = 2, 'simulacao executou handler real de prepare');
    Check(SimulationGraph.AcceptApproval, 'simulacao aprovada nao completou');
    Check(Host.CommitExecutions = 1, 'simulacao executou efeito real');
    Check(ContainsText(SimulationGraph.Memory, 'SIMULATION:'),
      'memoria da simulacao nao explicita ausencia de efeito');

    BuildGraph(DryRunGraph, Host);
    DryRunGraph.ExecutionMode := aemDryRun;
    Check(not DryRunGraph.Run('dry'), 'dry-run deveria pausar em aprovacao');
    Check(DryRunGraph.AcceptApproval, 'dry-run aprovado nao completou');
    Check(Host.CommitExecutions = 1, 'dry-run executou efeito real');
    Check(ContainsText(DryRunGraph.Memory, 'DRY-RUN:'),
      'memoria do dry-run nao esta identificada');

    DelegationGraph.AddNode('delegate', 'Delegar', agnDelegation).AgentID := 'worker-1';
    DelegationGraph.RegisterAgent('worker-1', DelegateAgent);
    Check(DelegationGraph.FindAgent('WORKER-1') = DelegateAgent,
      'delegacao direta por nome/ID falhou');
    DelegateAgent.Free;
    DelegateAgent := nil;
    Check(DelegationGraph.FindAgent('worker-1') = nil,
      'FreeNotification da delegacao falhou');

    InvalidFile := TStringList.Create;
    try InvalidFile.Text := '{"version":999,"currentNodeID":"prepare"}';
      InvalidFile.SaveToFile(InvalidCheckpoint);
    finally InvalidFile.Free; end;
    Check(not Resumed.LoadCheckpoint(InvalidCheckpoint),
      'checkpoint com versao desconhecida foi aceito');
  finally
    DelegateAgent.Free;
    DelegationGraph.Free;
    DryRunGraph.Free;
    SimulationGraph.Free;
    RejectedGraph.Free;
    Resumed.Free;
    Graph.Free;
    Host.Free;
    if FileExists(TempCheckpoint) then DeleteFile(TempCheckpoint);
    if FileExists(InvalidCheckpoint) then DeleteFile(InvalidCheckpoint);
  end;
  Writeln('PASS: agent graph sequencing, checkpoint/resume, approval/rejection, delegation and safe modes');
end.
