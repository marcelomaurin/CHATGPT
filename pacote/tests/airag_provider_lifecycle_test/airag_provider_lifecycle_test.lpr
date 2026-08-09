program airag_provider_lifecycle_test;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aiagent, airag, airagbridge;

procedure Check(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

procedure TestRAGDestroyedFirst;
var
  Agent: TAIAgent;
  RAG: TAIRAG;
  Provider: IAIRAGProvider;
begin
  Agent := TAIAgent.Create(nil);
  RAG := TAIRAG.Create(nil);
  try
    Agent.RAG := RAG;
    Check(Supports(RAG, IAIRAGProvider, Provider),
      'TAIRAG does not expose IAIRAGProvider');
    Provider := nil;
    Check(RAG.LastSources <> nil,
      'Releasing IAIRAGProvider destroyed the component');
    RAG.Free;
    RAG := nil;
    Check(Agent.RAG = nil,
      'TAIAgent kept a dangling RAG reference after notification');
  finally
    RAG.Free;
    Agent.Free;
  end;
end;

procedure TestAgentDestroyedFirst;
var
  Agent: TAIAgent;
  RAG: TAIRAG;
begin
  Agent := TAIAgent.Create(nil);
  RAG := TAIRAG.Create(nil);
  try
    Agent.RAG := RAG;
    Agent.Free;
    Agent := nil;
    Check(RAG.LastSources <> nil,
      'Destroying TAIAgent also destroyed the non-owned RAG component');
  finally
    Agent.Free;
    RAG.Free;
  end;
end;

procedure TestSharedOwner;
var
  Owner: TComponent;
  Agent: TAIAgent;
  RAG: TAIRAG;
begin
  Owner := TComponent.Create(nil);
  Agent := TAIAgent.Create(Owner);
  RAG := TAIRAG.Create(Owner);
  Agent.RAG := RAG;
  Owner.Free;
end;

var
  I: Integer;
begin
  try
    for I := 1 to 100 do
    begin
      TestRAGDestroyedFirst;
      TestAgentDestroyedFirst;
      TestSharedOwner;
    end;
    WriteLn('airag_provider_lifecycle_test: PASS (300 lifecycle scenarios)');
    ExitCode := 0;
  except
    on E: Exception do
    begin
      WriteLn('airag_provider_lifecycle_test: FAIL: ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
