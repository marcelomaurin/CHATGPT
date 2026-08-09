program agent_graph_demo;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, TypInfo, aiagentgraph;

type
  TDemo = class
    procedure Execute(Sender: TObject; ANode: TAIAgentNode;
      const AInput: string; AMode: TAIAgentExecutionMode;
      out AOutput: string; var ASuccess: Boolean);
  end;

procedure TDemo.Execute(Sender: TObject; ANode: TAIAgentNode;
  const AInput: string; AMode: TAIAgentExecutionMode;
  out AOutput: string; var ASuccess: Boolean);
begin
  AOutput := 'Processado de verdade: ' + AInput;
  ASuccess := True;
end;

var
  Demo: TDemo;
  Graph, Resumed: TAIAgentGraph;
  Checkpoint: string;
  I: Integer;
begin
  Demo := TDemo.Create;
  Graph := TAIAgentGraph.Create(nil);
  Resumed := TAIAgentGraph.Create(nil);
  Checkpoint := IncludeTrailingPathDelimiter(GetTempDir(False)) + 'agent_graph_demo.json';
  try
    Graph.AddNode('plan', 'Planejar', agnAction).OnExecute := @Demo.Execute;
    Graph.AddNode('approve', 'Confirmar', agnApproval);
    Graph.AddNode('finish', 'Finalizar', agnEnd);
    Graph.AddEdge('plan', 'approve', aecOnSuccess);
    Graph.AddEdge('approve', 'finish', aecOnApproved);
    Graph.StartNodeID := 'plan';
    Graph.Run('publicar relatorio');
    Writeln('Estado apos Run: ', GetEnumName(TypeInfo(TAIAgentGraphState), Ord(Graph.State)));
    Graph.SaveCheckpoint(Checkpoint);
    Writeln('Checkpoint: ', Checkpoint);

    Resumed.AddNode('plan', 'Planejar', agnAction).OnExecute := @Demo.Execute;
    Resumed.AddNode('approve', 'Confirmar', agnApproval);
    Resumed.AddNode('finish', 'Finalizar', agnEnd);
    Resumed.AddEdge('plan', 'approve', aecOnSuccess);
    Resumed.AddEdge('approve', 'finish', aecOnApproved);
    Resumed.StartNodeID := 'plan';
    Resumed.LoadCheckpoint(Checkpoint);
    Resumed.AcceptApproval;
    Writeln('Estado apos aprovacao: ', GetEnumName(TypeInfo(TAIAgentGraphState), Ord(Resumed.State)));
    for I := 0 to Resumed.Memory.Count - 1 do Writeln('  ', Resumed.Memory[I]);
  finally
    if FileExists(Checkpoint) then DeleteFile(Checkpoint);
    Resumed.Free;
    Graph.Free;
    Demo.Free;
  end;
end.
