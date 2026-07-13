program fgx_findings_tests;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aidependencygraph, fgx_findings;

var
  Passed, Failed: Integer;

procedure Check(const AName: string; ACondition: Boolean);
begin
  if ACondition then
  begin
    Inc(Passed);
    WriteLn(AName, ': PASS');
  end
  else
  begin
    Inc(Failed);
    WriteLn(AName, ': FAIL');
  end;
end;

function FindKind(AFindings: TFGXFindingList; const AKind: string): TFGXFinding;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AFindings.Count - 1 do
    if AFindings[I].Kind = AKind then Exit(AFindings[I]);
end;

procedure RunTests;
var
  Graph: TAIDependencyGraph;
  Findings: TFGXFindingList;
  Log: TStringList;
  Ev: TAIDependencyEvidence;
  SampleNode: TAIDependencyNode;
  BeforeCount: Integer;
  BuildFinding, BrokenFinding: TFGXFinding;
begin
  Check('T01_QuotedLPI', SameText(ExtractLPIFromMessage(
    'Failed compiling of project "D:\repo\sample.lpi"'),
    'D:\repo\sample.lpi'));
  Check('T02_TargetLPI', SameText(ExtractLPIFromMessage(
    'Compilar projeto, Alvo: D:\repo\sample.exe: stopped with exit code 1'),
    'D:\repo\sample.lpi'));

  Findings := TFGXFindingList.Create;
  try
    Check('T03_RejectEmptyWhere', not Assigned(Findings.AddFinding(
      'noise', fsError, '.:0 [scanner]', 'Noise', 'entity')));
    Check('T04_AcceptLocatedFinding', Assigned(Findings.AddFinding(
      'located', fsWarning, 'file.pas:1 [test]', 'Located', 'entity')));
    BeforeCount := Findings.Count;
    Findings.AddFinding('located', fsWarning, 'other.pas:2 [test]',
      'Different text', 'entity');
    Check('T05_SemanticDedup', Findings.Count = BeforeCount);
  finally
    Findings.Free;
  end;

  Graph := TAIDependencyGraph.Create(nil);
  Findings := TFGXFindingList.Create;
  Log := TStringList.Create;
  try
    Ev := MakeAIDependencyEvidence('pacote/packages/openai_core.lpk', 1, 'test');
    Graph.AddNode('repository:test', AIDG_NODE_REPOSITORY, 'test', '.', Ev);
    Graph.AddNode('package:openai_core', AIDG_NODE_PACKAGE,
      'openai_core', 'pacote/packages/openai_core.lpk', Ev);
    Graph.AddNode('external_dependency:openai', AIDG_NODE_EXTERNAL,
      'openai', '', Ev);
    SampleNode := Graph.AddNode('sample:demo', AIDG_NODE_SAMPLE,
      'demo', 'pacote/samples/demo/demo.lpi',
      MakeAIDependencyEvidence('pacote/samples/demo/demo.lpi', 0, 'test'));
    SampleNode.Attrs.Values['build_status'] := 'FAIL';
    SampleNode.Attrs.Values['build_exit_code'] := '1';
    Graph.AddNode('component:orphan', AIDG_NODE_COMPONENT, 'TOrphan',
      'pacote/orphan.pas', MakeAIDependencyEvidence('pacote/orphan.pas', 5, 'test'));
    Graph.AddEdge(SampleNode.Id, 'external_dependency:openai',
      AIDG_EDGE_REQUIRES_PACKAGE,
      MakeAIDependencyEvidence('pacote/samples/demo/demo.lpi', 3, 'test'));

    DetectFindings(Graph, Log, GetCurrentDir, Findings);
    BrokenFinding := FindKind(Findings, 'broken_dependency');
    BuildFinding := FindKind(Findings, 'build_failure');
    Check('T06_BrokenDependency', Assigned(BrokenFinding));
    Check('T07_OrphanComponent', Assigned(FindKind(Findings,
      'orphan_component')));
    Check('T08_SingleBuildFailure', Assigned(BuildFinding));
    Check('T09_RootCauseLinked', Assigned(BuildFinding) and
      Assigned(BrokenFinding) and (BuildFinding.RootCause = BrokenFinding.Id));
  finally
    Log.Free;
    Findings.Free;
    Graph.Free;
  end;
end;

begin
  Passed := 0;
  Failed := 0;
  RunTests;
  WriteLn(Format('TOTAL: PASS=%d FAIL=%d', [Passed, Failed]));
  if Failed > 0 then Halt(1);
end.
