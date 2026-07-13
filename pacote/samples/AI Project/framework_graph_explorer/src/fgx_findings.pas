unit fgx_findings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, aidependencygraph;

type
  TFGXFindingSeverity = (fsInfo, fsWarning, fsError);

  TFGXFinding = class
  public
    Id: string;
    Kind: string;
    Severity: TFGXFindingSeverity;
    WhereText: string;
    WhatText: string;
    EntityId: string;
    RootCause: string;
    Recommendation: string;
  end;

  TFGXFindingList = class(specialize TFPGObjectList<TFGXFinding>)
  private
    FKeys: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddFinding(const AKind: string; ASeverity: TFGXFindingSeverity;
      const AWhere, AWhat, AEntityId: string): TFGXFinding;
    function FindById(const AId: string): TFGXFinding;
    function FindRootForEntity(const AEntityId: string): TFGXFinding;
  end;

function DetectFindings(AGraph: TAIDependencyGraph; ALog: TStrings;
  const ARoot: string; AFindings: TFGXFindingList): Integer;
function ExtractLPIFromMessage(const AMsg: string): string;
function FindingSeverityText(ASeverity: TFGXFindingSeverity): string;

implementation

function CleanText(const AValue: string): string;
begin
  Result := Trim(StringReplace(StringReplace(AValue, #9, ' ', [rfReplaceAll]),
    LineEnding, ' ', [rfReplaceAll]));
end;

function ValidWhere(const AWhere: string): Boolean;
var
  S: string;
begin
  S := Trim(AWhere);
  Result := (S <> '') and (S <> '.') and (Copy(S, 1, 2) <> '.:');
end;

function NodeWhere(ANode: TAIDependencyNode): string;
begin
  if not Assigned(ANode) then Exit('');
  Result := Format('%s:%d [%s]', [ANode.Evidence.SourceFile,
    ANode.Evidence.Line, ANode.Evidence.Parser]);
end;

function EdgeWhere(AEdge: TAIDependencyEdge): string;
begin
  if not Assigned(AEdge) then Exit('');
  Result := Format('%s:%d [%s]', [AEdge.Evidence.SourceFile,
    AEdge.Evidence.Line, AEdge.Evidence.Parser]);
end;

function FindingSeverityText(ASeverity: TFGXFindingSeverity): string;
begin
  case ASeverity of
    fsInfo: Result := 'INFO';
    fsWarning: Result := 'WARNING';
    fsError: Result := 'ERROR';
  end;
end;

constructor TFGXFindingList.Create;
begin
  inherited Create(True);
  FKeys := TStringList.Create;
  FKeys.Sorted := True;
  FKeys.Duplicates := dupIgnore;
  FKeys.CaseSensitive := False;
end;

destructor TFGXFindingList.Destroy;
begin
  FKeys.Free;
  inherited Destroy;
end;

procedure TFGXFindingList.Clear;
begin
  inherited Clear;
  FKeys.Clear;
end;

function TFGXFindingList.AddFinding(const AKind: string;
  ASeverity: TFGXFindingSeverity; const AWhere, AWhat,
  AEntityId: string): TFGXFinding;
var
  Key, CleanWhere, CleanWhat: string;
begin
  Result := nil;
  CleanWhere := CleanText(AWhere);
  CleanWhat := CleanText(AWhat);
  if not ValidWhere(CleanWhere) or (CleanWhat = '') then Exit;
  Key := LowerCase(Trim(AKind) + '|' + Trim(AEntityId));
  if FKeys.IndexOf(Key) >= 0 then Exit;
  FKeys.Add(Key);
  Result := TFGXFinding.Create;
  Result.Id := Format('F%.3d', [Count + 1]);
  Result.Kind := Trim(AKind);
  Result.Severity := ASeverity;
  Result.WhereText := CleanWhere;
  Result.WhatText := CleanWhat;
  Result.EntityId := Trim(AEntityId);
  Add(Result);
end;

function TFGXFindingList.FindById(const AId: string): TFGXFinding;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if SameText(Items[I].Id, AId) then Exit(Items[I]);
end;

function TFGXFindingList.FindRootForEntity(const AEntityId: string): TFGXFinding;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
    if (SameText(Items[I].EntityId, AEntityId) or
        (Pos(LowerCase(AEntityId) + '|', LowerCase(Items[I].EntityId)) = 1)) and
       ((Items[I].Kind = 'broken_dependency') or
        (Items[I].Kind = 'missing_unit')) then
      Exit(Items[I]);
end;

function ExtractLPIFromMessage(const AMsg: string): string;
var
  P1, P2, ExtAt: Integer;
  S, Lower: string;
begin
  Result := '';
  P1 := Pos('"', AMsg);
  if P1 > 0 then
  begin
    P2 := Pos('"', Copy(AMsg, P1 + 1, MaxInt));
    if P2 > 0 then
    begin
      S := Copy(AMsg, P1 + 1, P2 - 1);
      if SameText(ExtractFileExt(S), '.lpi') then Exit(S);
    end;
  end;
  Lower := LowerCase(AMsg);
  P1 := Pos('alvo:', Lower);
  if P1 = 0 then Exit;
  S := Trim(Copy(AMsg, P1 + Length('alvo:'), MaxInt));
  Lower := LowerCase(S);
  ExtAt := Pos('.exe', Lower);
  if ExtAt > 0 then
    Result := ChangeFileExt(Copy(S, 1, ExtAt + 3), '.lpi');
end;

function FindNodeByName(AGraph: TAIDependencyGraph; const AType,
  AName: string): TAIDependencyNode;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AGraph.Nodes.Count - 1 do
    if SameText(AGraph.Nodes[I].NodeType, AType) and
       SameText(AGraph.Nodes[I].Name, AName) then
      Exit(AGraph.Nodes[I]);
end;

function FindOwningPackage(AGraph: TAIDependencyGraph;
  AUnit: TAIDependencyNode): TAIDependencyNode;
var
  I: Integer;
  E: TAIDependencyEdge;
begin
  Result := nil;
  if not Assigned(AUnit) then Exit;
  for I := 0 to AGraph.Edges.Count - 1 do
  begin
    E := AGraph.Edges[I];
    if (E.EdgeType = AIDG_EDGE_CONTAINS) and (E.ToId = AUnit.Id) then
    begin
      Result := AGraph.FindNode(E.FromId);
      if Assigned(Result) and (Result.NodeType = AIDG_NODE_PACKAGE) then Exit;
      Result := nil;
    end;
  end;
end;

function NodeHasEdge(AGraph: TAIDependencyGraph; ANode: TAIDependencyNode;
  const AEdgeType: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to AGraph.Edges.Count - 1 do
    if (AGraph.Edges[I].FromId = ANode.Id) and
       (AGraph.Edges[I].EdgeType = AEdgeType) then Exit(True);
end;

function ReadDocumentation(const ARoot: string): string;
var
  Lines: TStringList;
  procedure AppendReadmes(const ADirectory: string);
  var
    SR: TSearchRec;
    FileName: string;
  begin
    if not DirectoryExists(ADirectory) then Exit;
    if FindFirst(IncludeTrailingPathDelimiter(ADirectory) + 'README*.md',
      faAnyFile, SR) = 0 then
    try
      repeat
        FileName := IncludeTrailingPathDelimiter(ADirectory) + SR.Name;
        try
          Lines.LoadFromFile(FileName);
          Result := Result + LineEnding + LowerCase(Lines.Text);
        except
          { An unreadable README is handled as absent documentation. }
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
begin
  Result := '';
  Lines := TStringList.Create;
  try
    AppendReadmes(ARoot);
    AppendReadmes(IncludeTrailingPathDelimiter(ARoot) + 'pacote');
  finally
    Lines.Free;
  end;
end;

function DetectFindings(AGraph: TAIDependencyGraph; ALog: TStrings;
  const ARoot: string; AFindings: TFGXFindingList): Integer;
var
  I, J, P, EndAt: Integer;
  N, SourceNode, TargetNode, UnitNode, OwnerNode: TAIDependencyNode;
  E, SampleEdge: TAIDependencyEdge;
  F, RootFinding: TFGXFinding;
  Line, LowerLine, MissingUnit, UsedBy, Docs, DepName: string;
begin
  AFindings.Clear;

  for I := 0 to AGraph.Edges.Count - 1 do
  begin
    E := AGraph.Edges[I];
    if E.EdgeType <> AIDG_EDGE_REQUIRES_PACKAGE then Continue;
    SourceNode := AGraph.FindNode(E.FromId);
    TargetNode := AGraph.FindNode(E.ToId);
    if (not Assigned(SourceNode)) or (not Assigned(TargetNode)) then Continue;
    if (TargetNode.NodeType = AIDG_NODE_EXTERNAL) and
       (Pos('openai', LowerCase(TargetNode.Name)) = 1) then
      AFindings.AddFinding('broken_dependency', fsError, EdgeWhere(E),
        Format('Broken dependency: %s -> %s', [SourceNode.Name, TargetNode.Name]),
        SourceNode.Id + '|' + TargetNode.Id);
  end;

  if Assigned(ALog) then
    for I := 0 to ALog.Count - 1 do
    begin
      Line := Trim(ALog[I]);
      LowerLine := LowerCase(Line);
      P := Pos('can''t find unit ', LowerLine);
      if P = 0 then P := Pos('cannot find unit ', LowerLine);
      if P = 0 then Continue;
      P := P + Pos('unit ', Copy(LowerLine, P, MaxInt)) + Length('unit ') - 1;
      MissingUnit := Copy(Line, P, MaxInt);
      EndAt := Pos(' ', MissingUnit);
      if EndAt > 0 then MissingUnit := Copy(MissingUnit, 1, EndAt - 1);
      UsedBy := '';
      P := Pos(' used by ', LowerLine);
      if P > 0 then
      begin
        UsedBy := Trim(Copy(Line, P + Length(' used by '), MaxInt));
        EndAt := Pos(' ', UsedBy);
        if EndAt > 0 then UsedBy := Copy(UsedBy, 1, EndAt - 1);
      end;
      UnitNode := FindNodeByName(AGraph, AIDG_NODE_UNIT, UsedBy);
      OwnerNode := FindOwningPackage(AGraph, UnitNode);
      if Assigned(OwnerNode) then SourceNode := OwnerNode else SourceNode := UnitNode;
      if Assigned(SourceNode) then
        AFindings.AddFinding('missing_unit', fsError, NodeWhere(SourceNode),
          Format('Missing unit: %s used by %s', [MissingUnit, UsedBy]),
          SourceNode.Id + '|' + LowerCase(MissingUnit));
    end;

  for I := 0 to AGraph.Nodes.Count - 1 do
  begin
    N := AGraph.Nodes[I];
    if (N.NodeType = AIDG_NODE_COMPONENT) and
       not NodeHasEdge(AGraph, N, AIDG_EDGE_DEMONSTRATED_BY) then
      AFindings.AddFinding('orphan_component', fsWarning, NodeWhere(N),
        'Component without sample: ' + N.Name, N.Id);
  end;

  Docs := ReadDocumentation(ARoot);
  for I := 0 to AGraph.Edges.Count - 1 do
  begin
    E := AGraph.Edges[I];
    if E.EdgeType <> AIDG_EDGE_REQUIRES_PACKAGE then Continue;
    TargetNode := AGraph.FindNode(E.ToId);
    SourceNode := AGraph.FindNode(E.FromId);
    if (not Assigned(TargetNode)) or (not Assigned(SourceNode)) then Continue;
    DepName := LowerCase(TargetNode.Name);
    if (DepName <> 'zcomponent') and (DepName <> 'turbopoweripro') and
       (DepName <> 'cef4delphi_lazarus') then Continue;
    if Pos(DepName, Docs) = 0 then
      AFindings.AddFinding('undocumented_dependency', fsWarning, EdgeWhere(E),
        Format('Undocumented dependency: %s requires %s',
          [SourceNode.Name, TargetNode.Name]), SourceNode.Id + '|' + TargetNode.Id);
  end;

  for I := 0 to AGraph.Nodes.Count - 1 do
  begin
    N := AGraph.Nodes[I];
    if (N.NodeType <> AIDG_NODE_SAMPLE) or
       (N.Attrs.Values['build_status'] <> 'FAIL') then Continue;
    F := AFindings.AddFinding('build_failure', fsError, NodeWhere(N),
      Format('Sample build failed: %s (exit code %s)',
        [N.Name, N.Attrs.Values['build_exit_code']]), N.Id);
    if not Assigned(F) then Continue;
    RootFinding := AFindings.FindRootForEntity(N.Id);
    if Assigned(RootFinding) then F.RootCause := RootFinding.Id;
    for J := 0 to AGraph.Edges.Count - 1 do
    begin
      if F.RootCause <> '' then Break;
      SampleEdge := AGraph.Edges[J];
      if (SampleEdge.FromId <> N.Id) or
         (SampleEdge.EdgeType <> AIDG_EDGE_REQUIRES_PACKAGE) then Continue;
      RootFinding := AFindings.FindRootForEntity(SampleEdge.ToId);
      if Assigned(RootFinding) then
      begin
        F.RootCause := RootFinding.Id;
        Break;
      end;
    end;
  end;

  Result := AFindings.Count;
end;

end.
