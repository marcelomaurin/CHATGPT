unit fgx_history;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aidependencygraph, fgx_findings;

function SaveAndCompareHistory(AGraph: TAIDependencyGraph; const ARoot: string;
  AFindings: TFGXFindingList; ASummary: TStrings; out AHistoryFile: string;
  out ARegressions: Integer): Boolean;

implementation

function RelativeHistoryFile(const ARoot, AFile: string): string;
var
  RootPath, FullPath: string;
begin
  RootPath := IncludeTrailingPathDelimiter(ExpandFileName(ARoot));
  FullPath := ExpandFileName(AFile);
  if CompareText(Copy(FullPath, 1, Length(RootPath)), RootPath) = 0 then
    Result := Copy(FullPath, Length(RootPath) + 1, MaxInt)
  else
    Result := ExtractFileName(AFile);
  Result := StringReplace(Result, '\', '/', [rfReplaceAll]);
end;

function LatestSnapshot(const AHistoryDir: string): string;
var
  SR: TSearchRec;
  Candidate: string;
begin
  Result := '';
  if FindFirst(IncludeTrailingPathDelimiter(AHistoryDir) + '*.json', faAnyFile, SR) = 0 then
  try
    repeat
      Candidate := IncludeTrailingPathDelimiter(AHistoryDir) + SR.Name;
      if (Result = '') or
         (CompareText(ExtractFileName(Candidate), ExtractFileName(Result)) > 0) then
        Result := Candidate;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

function UniqueSnapshotName(const AHistoryDir: string): string;
var
  BaseName: string;
  Counter: Integer;
begin
  BaseName := FormatDateTime('yyyy-mm-dd"T"hh-nn-ss-zzz', Now);
  Result := IncludeTrailingPathDelimiter(AHistoryDir) + BaseName + '.json';
  Counter := 1;
  while FileExists(Result) do
  begin
    Result := IncludeTrailingPathDelimiter(AHistoryDir) + BaseName + '-' +
      IntToStr(Counter) + '.json';
    Inc(Counter);
  end;
end;

function NodeWhere(ANode: TAIDependencyNode): string;
begin
  Result := Format('%s:%d [%s]', [ANode.Evidence.SourceFile,
    ANode.Evidence.Line, ANode.Evidence.Parser]);
end;

function SaveAndCompareHistory(AGraph: TAIDependencyGraph; const ARoot: string;
  AFindings: TFGXFindingList; ASummary: TStrings; out AHistoryFile: string;
  out ARegressions: Integer): Boolean;
var
  HistoryDir, PreviousFile: string;
  Previous: TAIDependencyGraph;
  I, Missing, Added, BuildRegressions: Integer;
  PreviousNode, CurrentNode: TAIDependencyNode;
begin
  Result := False;
  ARegressions := 0;
  AHistoryFile := '';
  if Assigned(ASummary) then ASummary.Clear;
  HistoryDir := IncludeTrailingPathDelimiter(ARoot) + 'DOC' + PathDelim +
    'fgx' + PathDelim + 'history';
  if not ForceDirectories(HistoryDir) then Exit;
  PreviousFile := LatestSnapshot(HistoryDir);
  Missing := 0;
  Added := 0;
  BuildRegressions := 0;

  if PreviousFile <> '' then
  begin
    Previous := TAIDependencyGraph.Create(nil);
    try
      if Previous.LoadFromJSON(PreviousFile) then
      begin
        for I := 0 to Previous.Nodes.Count - 1 do
        begin
          PreviousNode := Previous.Nodes[I];
          CurrentNode := AGraph.FindNode(PreviousNode.Id);
          if not Assigned(CurrentNode) then
          begin
            Inc(Missing);
            AFindings.AddFinding('disappeared', fsError, NodeWhere(PreviousNode),
              Format('Disappeared: %s (%s)',
                [PreviousNode.Name, PreviousNode.NodeType]), PreviousNode.Id);
          end
          else if (PreviousNode.NodeType = AIDG_NODE_SAMPLE) and
                  (PreviousNode.Attrs.Values['build_status'] = 'PASS') and
                  (CurrentNode.Attrs.Values['build_status'] = 'FAIL') then
          begin
            Inc(BuildRegressions);
            AFindings.AddFinding('sample_regression', fsError,
              NodeWhere(CurrentNode),
              Format('Sample regressed from PASS to FAIL: %s', [CurrentNode.Name]),
              CurrentNode.Id);
          end;
        end;
        for I := 0 to AGraph.Nodes.Count - 1 do
        begin
          CurrentNode := AGraph.Nodes[I];
          if not Assigned(Previous.FindNode(CurrentNode.Id)) then
          begin
            Inc(Added);
            AFindings.AddFinding('new_node', fsInfo, NodeWhere(CurrentNode),
              Format('New: %s (%s)', [CurrentNode.Name, CurrentNode.NodeType]),
              CurrentNode.Id);
          end;
        end;
      end
      else
        AFindings.AddFinding('history_read_failure', fsWarning,
          RelativeHistoryFile(ARoot, PreviousFile) + ':0 [fgx_history]',
          'Previous history snapshot could not be loaded.',
          'history:' + ExtractFileName(PreviousFile));
    finally
      Previous.Free;
    end;
  end;

  ARegressions := Missing + BuildRegressions;
  if Assigned(ASummary) then
  begin
    if PreviousFile = '' then
      ASummary.Add('No previous snapshot. This execution is the baseline.')
    else
      ASummary.Add('Compared with: ' + RelativeHistoryFile(ARoot, PreviousFile));
    ASummary.Add(Format('Disappeared: %d | New: %d | Build regressions: %d',
      [Missing, Added, BuildRegressions]));
  end;

  AHistoryFile := UniqueSnapshotName(HistoryDir);
  Result := AGraph.SaveToJSON(AHistoryFile);
  if Result and Assigned(ASummary) then
    ASummary.Add('Snapshot: ' + RelativeHistoryFile(ARoot, AHistoryFile));
end;

end.
