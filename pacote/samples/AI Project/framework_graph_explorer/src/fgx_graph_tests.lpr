program fgx_graph_tests;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, jsonparser, aidependencygraph;

type
  TTestProc = procedure;

var
  GRootDir: string;

function RepoFile(const ARelativePath: string): string;
begin
  Result := ExpandFileName(IncludeTrailingPathDelimiter(GRootDir) + ARelativePath);
end;

function TempFile(const AName: string): string;
begin
  Result := IncludeTrailingPathDelimiter(GetTempDir(False)) + AName;
end;

procedure AssertTrue(ACondition: Boolean; const AMsg: string);
begin
  if not ACondition then
    raise Exception.Create(AMsg);
end;

procedure AssertFalse(ACondition: Boolean; const AMsg: string);
begin
  if ACondition then
    raise Exception.Create(AMsg);
end;

procedure AssertEqualInt(const AExpected, AActual: Integer; const AMsg: string);
begin
  if AExpected <> AActual then
    raise Exception.CreateFmt('%s (expected %d, got %d)', [AMsg, AExpected, AActual]);
end;

procedure AssertEqualStr(const AExpected, AActual, AMsg: string);
begin
  if not SameText(AExpected, AActual) then
    raise Exception.CreateFmt('%s (expected "%s", got "%s")', [AMsg, AExpected, AActual]);
end;

procedure RunTest(const AName: string; AProc: TTestProc; var AFailures: Integer);
begin
  try
    AProc;
    Writeln(AName, ': PASS');
  except
    on E: Exception do
    begin
      Inc(AFailures);
      Writeln(AName, ': FAIL - ', E.Message);
    end;
  end;
end;

function MakeEv: TAIDependencyEvidence;
begin
  Result := MakeAIDependencyEvidence('tests/fgx_graph_tests.lpr', 1, 'fgx_graph_tests');
end;

procedure CreateSampleGraph(AGraph: TAIDependencyGraph);
var
  Ev: TAIDependencyEvidence;
begin
  Ev := MakeEv;
  AGraph.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', Ev);
  AGraph.AddNode('unit:sample', AIDG_NODE_UNIT, 'sample', 'sample.pas', Ev);
  AGraph.AddNode('component:demo', AIDG_NODE_COMPONENT, 'demo', 'sample.pas', Ev);
  AGraph.AddEdge('package:core', 'unit:sample', AIDG_EDGE_CONTAINS, Ev);
  AGraph.AddEdge('unit:sample', 'component:demo', AIDG_EDGE_DECLARES, Ev);
  AGraph.AddInferredEdge('component:demo', 'package:core', 'relates_to', 0.75, 'rule:demo');
end;

procedure T01_AddNodeFindNode;
var
  G: TAIDependencyGraph;
  N: TAIDependencyNode;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    N := G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', MakeEv);
    AssertTrue(Assigned(N), 'node should be created');
    AssertTrue(Assigned(G.FindNode('package:core')), 'node should be found');
    AssertEqualStr('core', G.FindNode('package:core').Name, 'node name');
  finally
    G.Free;
  end;
end;

procedure T02_AddNodeDuplicate;
var
  G: TAIDependencyGraph;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    AssertTrue(Assigned(G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', MakeEv)), 'first add');
    AssertTrue(Assigned(G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', MakeEv)), 'duplicate should return existing node');
    AssertEqualInt(1, G.NodeCount, 'duplicate node count');
  finally
    G.Free;
  end;
end;

procedure T03_AddEdgeBetweenTwoNodes;
var
  G: TAIDependencyGraph;
  E: TAIDependencyEdge;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', MakeEv);
    G.AddNode('unit:sample', AIDG_NODE_UNIT, 'sample', 'sample.pas', MakeEv);
    E := G.AddEdge('package:core', 'unit:sample', AIDG_EDGE_CONTAINS, MakeEv);
    AssertTrue(Assigned(E), 'edge should be created');
    AssertEqualStr(AIDG_KIND_FACTUAL, E.Kind, 'edge kind');
    AssertEqualInt(1, G.EdgeCount, 'edge count');
  finally
    G.Free;
  end;
end;

procedure T04_AddEdgeDuplicate;
var
  G: TAIDependencyGraph;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', MakeEv);
    G.AddNode('unit:sample', AIDG_NODE_UNIT, 'sample', 'sample.pas', MakeEv);
    AssertTrue(Assigned(G.AddEdge('package:core', 'unit:sample', AIDG_EDGE_CONTAINS, MakeEv)), 'first edge');
    AssertTrue(Assigned(G.AddEdge('package:core', 'unit:sample', AIDG_EDGE_CONTAINS, MakeEv)), 'duplicate should return existing edge');
    AssertEqualInt(1, G.EdgeCount, 'duplicate edge count');
  finally
    G.Free;
  end;
end;

procedure T05_ValidateIntactGraph;
var
  G: TAIDependencyGraph;
  V: TAIDependencyValidation;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    CreateSampleGraph(G);
    V := G.Validate;
    AssertTrue(V.Passed, 'graph should validate');
    AssertFalse(V.Empty, 'graph should not be empty');
    AssertEqualInt(0, V.BrokenEdges, 'broken edges');
    AssertEqualInt(0, V.NoEvidence, 'missing evidence');
    AssertEqualInt(0, V.SelfEdges, 'self edges');
  finally
    G.Free;
  end;
end;

procedure T06_RoundTripJSON;
var
  G1, G2: TAIDependencyGraph;
  FileName: string;
  N: TAIDependencyNode;
  E: TAIDependencyEdge;
begin
  G1 := TAIDependencyGraph.Create(nil);
  G2 := TAIDependencyGraph.Create(nil);
  FileName := TempFile('fgx_roundtrip.json');
  try
    CreateSampleGraph(G1);
    AssertTrue(G1.SaveToJSON(FileName), 'save json');
    AssertTrue(FileExists(FileName), 'roundtrip file should exist');
    AssertTrue(G2.LoadFromJSON(FileName), 'load json');
    AssertEqualInt(G1.NodeCount, G2.NodeCount, 'node count roundtrip');
    AssertEqualInt(G1.EdgeCount, G2.EdgeCount, 'edge count roundtrip');
    AssertEqualInt(G1.InferredEdges.Count, G2.InferredEdges.Count, 'inferred count roundtrip');
    N := G2.FindNode('component:demo');
    AssertTrue(Assigned(N), 'node after roundtrip');
    AssertEqualStr('demo', N.Name, 'roundtrip node name');
    E := G2.Edges[0];
    AssertEqualStr(AIDG_EDGE_CONTAINS, E.EdgeType, 'roundtrip edge type');
    AssertEqualStr(AIDG_KIND_FACTUAL, E.Kind, 'roundtrip edge kind');
  finally
    DeleteFile(FileName);
    G2.Free;
    G1.Free;
  end;
end;

procedure T07_SaveToDOT;
var
  G: TAIDependencyGraph;
  FileName: string;
  SL: TStringList;
begin
  G := TAIDependencyGraph.Create(nil);
  FileName := TempFile('fgx_graph.dot');
  SL := TStringList.Create;
  try
    CreateSampleGraph(G);
    AssertTrue(G.SaveToDOT(FileName), 'save dot');
    SL.LoadFromFile(FileName);
    AssertTrue(Pos('digraph TAIDependencyGraph', SL.Text) > 0, 'dot header');
    AssertTrue(Pos('package:core', SL.Text) > 0, 'dot node label');
  finally
    SL.Free;
    DeleteFile(FileName);
    G.Free;
  end;
end;

procedure T08_AddNodeWithoutEvidence;
var
  G: TAIDependencyGraph;
  N: TAIDependencyNode;
  Ev: TAIDependencyEvidence;
begin
  G := TAIDependencyGraph.Create(nil);
  FillChar(Ev, SizeOf(Ev), 0);
  try
    N := G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', Ev);
    AssertFalse(Assigned(N), 'node without evidence should be rejected');
    AssertTrue(G.LastError <> '', 'last error should be populated');
  finally
    G.Free;
  end;
end;

procedure T09_AddEdgeMissingNode;
var
  G: TAIDependencyGraph;
  V: TAIDependencyValidation;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', MakeEv);
    AssertTrue(Assigned(G.AddEdge('package:core', 'unit:missing', AIDG_EDGE_CONTAINS, MakeEv)), 'broken edge is still stored');
    V := G.Validate;
    AssertFalse(V.Passed, 'broken edge must fail validation');
    AssertEqualInt(1, V.BrokenEdges, 'broken edges count');
  finally
    G.Free;
  end;
end;

procedure T10_SelfEdgeFailsValidate;
var
  G: TAIDependencyGraph;
  V: TAIDependencyValidation;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    G.AddNode('package:core', AIDG_NODE_PACKAGE, 'core', 'core.lpk', MakeEv);
    AssertTrue(Assigned(G.AddEdge('package:core', 'package:core', AIDG_EDGE_CONTAINS, MakeEv)), 'self edge stored');
    V := G.Validate;
    AssertFalse(V.Passed, 'self edge must fail validation');
    AssertEqualInt(1, V.SelfEdges, 'self edges count');
  finally
    G.Free;
  end;
end;

procedure T11_LoadMissingFile;
var
  G: TAIDependencyGraph;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    AssertFalse(G.LoadFromJSON(TempFile('fgx_missing_' + IntToStr(Random(100000)) + '.json')), 'missing file must fail');
    AssertTrue(G.LastError <> '', 'missing file should set last error');
  finally
    G.Free;
  end;
end;

procedure T12_LoadCorruptedJSON;
var
  G: TAIDependencyGraph;
  FileName: string;
  SL: TStringList;
begin
  G := TAIDependencyGraph.Create(nil);
  FileName := TempFile('fgx_corrupted.json');
  SL := TStringList.Create;
  try
    SL.Text := '{ this is not json';
    SL.SaveToFile(FileName);
    AssertFalse(G.LoadFromJSON(FileName), 'corrupted json must fail');
    AssertTrue(G.LastError <> '', 'corrupted json should set last error');
  finally
    SL.Free;
    DeleteFile(FileName);
    G.Free;
  end;
end;

procedure T13_LoadJsonWithoutNodes;
var
  G: TAIDependencyGraph;
  FileName: string;
  SL: TStringList;
begin
  G := TAIDependencyGraph.Create(nil);
  FileName := TempFile('fgx_missing_nodes.json');
  SL := TStringList.Create;
  try
    SL.Text := '{"edges":[]}';
    SL.SaveToFile(FileName);
    AssertFalse(G.LoadFromJSON(FileName), 'json without nodes must fail');
    AssertTrue(G.LastError <> '', 'missing nodes should set last error');
  finally
    SL.Free;
    DeleteFile(FileName);
    G.Free;
  end;
end;

procedure T14_InferredEdgeRejectedFromFactualEdges;
var
  G: TAIDependencyGraph;
  FileName: string;
  SL: TStringList;
begin
  G := TAIDependencyGraph.Create(nil);
  FileName := TempFile('fgx_inferred_in_edges.json');
  SL := TStringList.Create;
  try
    SL.Text :=
      '{' +
      '"nodes":[{"id":"package:core","type":"package","name":"core","path":"core.lpk","attributes":{},"evidence":[{"file":"x.pas","line":1,"parser":"test"}]},' +
      '{"id":"unit:sample","type":"unit","name":"sample","path":"sample.pas","attributes":{},"evidence":[{"file":"x.pas","line":1,"parser":"test"}]}],' +
      '"edges":[{"id":"edge:package:core|contains|unit:sample","from":"package:core","to":"unit:sample","type":"contains","kind":"inferred","confidence":0.9,"source":"rule","evidence":[{"file":"x.pas","line":1,"parser":"test"}]}]' +
      '}';
    SL.SaveToFile(FileName);
    AssertFalse(G.LoadFromJSON(FileName), 'inferred edge inside factual section must fail');
    AssertTrue(G.LastError <> '', 'inferred edge rejection should set last error');
  finally
    SL.Free;
    DeleteFile(FileName);
    G.Free;
  end;
end;

procedure T15_ValidateEmptyGraph;
var
  G: TAIDependencyGraph;
  V: TAIDependencyValidation;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    V := G.Validate;
    AssertTrue(V.Empty, 'empty graph must be marked empty');
    AssertFalse(V.Passed, 'empty graph cannot pass');
  finally
    G.Free;
  end;
end;

procedure T16_SaveToDOTUnwritable;
var
  G: TAIDependencyGraph;
  Target: string;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    CreateSampleGraph(G);
    Target := GetTempDir(False);
    AssertFalse(G.SaveToDOT(Target), 'saving to a directory must fail');
    AssertTrue(G.LastError <> '', 'save failure should set last error');
  finally
    G.Free;
  end;
end;

procedure T17_RealGraphIntegration;
var
  G: TAIDependencyGraph;
  FileName: string;
  V: TAIDependencyValidation;
begin
  G := TAIDependencyGraph.Create(nil);
  try
    FileName := RepoFile('DOC/fgx/factual_graph.json');
    AssertTrue(FileExists(FileName), 'real graph json should exist');
    AssertTrue(G.LoadFromJSON(FileName), 'real graph should load');
    AssertEqualInt(517, G.NodeCount, 'real node count');
    AssertEqualInt(2081, G.EdgeCount, 'real edge count');
    AssertEqualInt(188, G.CountNodesOfType(AIDG_NODE_UNIT), 'unit count');
    AssertEqualInt(139, G.CountNodesOfType(AIDG_NODE_COMPONENT), 'component count');
    AssertEqualInt(97, G.CountNodesOfType(AIDG_NODE_SAMPLE), 'sample count');
    AssertEqualInt(76, G.CountNodesOfType(AIDG_NODE_EXTERNAL), 'external count');
    AssertEqualInt(16, G.CountNodesOfType(AIDG_NODE_PACKAGE), 'package count');
    AssertEqualInt(1, G.CountNodesOfType(AIDG_NODE_REPOSITORY), 'repository count');
    AssertEqualInt(1153, G.CountEdgesOfType(AIDG_EDGE_USES_UNIT), 'uses_unit count');
    AssertEqualInt(301, G.CountEdgesOfType(AIDG_EDGE_CONTAINS), 'contains count');
    AssertEqualInt(287, G.CountEdgesOfType(AIDG_EDGE_DEMONSTRATED_BY), 'demonstrated_by count');
    AssertEqualInt(139, G.CountEdgesOfType(AIDG_EDGE_DECLARES), 'declares count');
    AssertEqualInt(139, G.CountEdgesOfType(AIDG_EDGE_REGISTERS), 'registers count');
    AssertEqualInt(62, G.CountEdgesOfType(AIDG_EDGE_REQUIRES_PACKAGE), 'requires_package count');
    V := G.Validate;
    AssertTrue(V.Passed, 'real graph should validate');
    AssertFalse(V.Empty, 'real graph is not empty');
  finally
    G.Free;
  end;
end;

var
  Failures: Integer = 0;

begin
  Randomize;
  if ParamCount >= 1 then
    GRootDir := ExpandFileName(ParamStr(1))
  else
    GRootDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '../../../../..');

  RunTest('T01 AddNode + FindNode', @T01_AddNodeFindNode, Failures);
  RunTest('T02 AddNode duplicated', @T02_AddNodeDuplicate, Failures);
  RunTest('T03 AddEdge factual', @T03_AddEdgeBetweenTwoNodes, Failures);
  RunTest('T04 AddEdge duplicated', @T04_AddEdgeDuplicate, Failures);
  RunTest('T05 Validate intact graph', @T05_ValidateIntactGraph, Failures);
  RunTest('T06 SaveToJSON -> LoadFromJSON', @T06_RoundTripJSON, Failures);
  RunTest('T07 SaveToDOT', @T07_SaveToDOT, Failures);
  RunTest('T08 AddNode without evidence', @T08_AddNodeWithoutEvidence, Failures);
  RunTest('T09 Broken edge validation', @T09_AddEdgeMissingNode, Failures);
  RunTest('T10 Self-edge validation', @T10_SelfEdgeFailsValidate, Failures);
  RunTest('T11 Load missing file', @T11_LoadMissingFile, Failures);
  RunTest('T12 Load corrupted JSON', @T12_LoadCorruptedJSON, Failures);
  RunTest('T13 Load JSON without nodes', @T13_LoadJsonWithoutNodes, Failures);
  RunTest('T14 Reject inferred in factual edges', @T14_InferredEdgeRejectedFromFactualEdges, Failures);
  RunTest('T15 Validate empty graph', @T15_ValidateEmptyGraph, Failures);
  RunTest('T16 SaveToDOT unwritable path', @T16_SaveToDOTUnwritable, Failures);
  RunTest('T17 Real graph integration', @T17_RealGraphIntegration, Failures);

  if Failures = 0 then
    Writeln('ALL TESTS PASS')
  else
  begin
    Writeln('FAILURES: ', Failures);
    Halt(1);
  end;
end.
