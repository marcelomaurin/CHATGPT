unit aigraphvisualizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aigraphmap, aioutput_docs, LazUTF8, fpjson, jsonparser;

type
  { TAIGraphVisualizer }

  TAIGraphVisualizer = class(TAIBaseComponent)
  private
    FGraphMap: TAIGraphMap;
    FOutputDocs: TAIOutputDocs;
    FCategoryFilter: string;
    FTokenFilter: string;
    FTopN: Integer;
    FMinWeight: Double;
    FIncludeTokenToken: Boolean;
    FIncludeTokenCategory: Boolean;

    procedure GetFilteredGraph(out AFilteredNodes: TList; out AFilteredEdges: TList);
    function EscapeLabel(const ALabel: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure ExportToDOT(const AFileName: string);
    procedure ExportToMermaid(const AFileName: string);
    procedure ExportToJSONVisual(const AFileName: string);
    procedure ExportSummary(const AFileName: string);
  published
    property GraphMap: TAIGraphMap read FGraphMap write FGraphMap;
    property OutputDocs: TAIOutputDocs read FOutputDocs write FOutputDocs;
    property CategoryFilter: string read FCategoryFilter write FCategoryFilter;
    property TokenFilter: string read FTokenFilter write FTokenFilter;
    property TopN: Integer read FTopN write FTopN default 0;
    property MinWeight: Double read FMinWeight write FMinWeight;
    property IncludeTokenToken: Boolean read FIncludeTokenToken write FIncludeTokenToken default True;
    property IncludeTokenCategory: Boolean read FIncludeTokenCategory write FIncludeTokenCategory default True;
    property Category default ccOther;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIGraphVisualizer]);
end;

{ TAIGraphVisualizer }

constructor TAIGraphVisualizer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIGraphVisualizer formats and filters the TAIGraphMap knowledge network of token-to-token and token-to-category associations. It exports subgraph structures into standard visualization formats including GraphViz DOT, Mermaid flowchart syntax, JSON objects, and flat text summaries.';
  
  FGraphMap := nil;
  FOutputDocs := nil;
  FCategoryFilter := '';
  FTokenFilter := '';
  FTopN := 50; // default to showing Top 50 relationships to prevent gigantic graphs
  FMinWeight := 0.0;
  FIncludeTokenToken := True;
  FIncludeTokenCategory := True;
  ClearError;
end;

destructor TAIGraphVisualizer.Destroy;
begin
  inherited Destroy;
end;

function TAIGraphVisualizer.EscapeLabel(const ALabel: string): string;
var
  s: string;
begin
  s := ALabel;
  s := StringReplace(s, '"', '\"', [rfReplaceAll]);
  s := StringReplace(s, #13#10, ' ', [rfReplaceAll]);
  s := StringReplace(s, #10, ' ', [rfReplaceAll]);
  s := StringReplace(s, #13, ' ', [rfReplaceAll]);
  Result := s;
end;

procedure SortEdgesByWeight(AList: TList);
var
  i, j: Integer;
  Temp: TAIGraphEdge;
begin
  for i := 0 to AList.Count - 2 do
  begin
    for j := i + 1 to AList.Count - 1 do
    begin
      if TAIGraphEdge(AList[j]).Weight > TAIGraphEdge(AList[i]).Weight then
      begin
        Temp := TAIGraphEdge(AList[i]);
        AList[i] := AList[j];
        AList[j] := Temp;
      end;
    end;
  end;
end;

procedure TAIGraphVisualizer.GetFilteredGraph(out AFilteredNodes: TList; out AFilteredEdges: TList);
var
  i: Integer;
  LEdge: TAIGraphEdge;
  LFrom, LTo: TAIGraphNode;
  LPass: Boolean;
  LNodeIds: TList;
  LNode: TAIGraphNode;
  LTempEdges: TList;
  j: Integer;
begin
  AFilteredNodes := TList.Create;
  AFilteredEdges := TList.Create;
  LNodeIds := TList.Create;
  LTempEdges := TList.Create;
  
  try
    if not Assigned(FGraphMap) or (FGraphMap.EdgeCount = 0) then Exit;
    
    // 1. Filter edges first
    for i := 0 to FGraphMap.Edges.Count - 1 do
    begin
      LEdge := TAIGraphEdge(FGraphMap.Edges[i]);
      LFrom := FGraphMap.FindNodeById(LEdge.FromNodeId);
      LTo := FGraphMap.FindNodeById(LEdge.ToNodeId);
      
      if not Assigned(LFrom) or not Assigned(LTo) then Continue;
      
      // MinWeight filter
      if LEdge.Weight < FMinWeight then Continue;
      
      // IncludeTokenToken / IncludeTokenCategory checks
      if (LFrom.NodeType = ntToken) and (LTo.NodeType = ntToken) and not FIncludeTokenToken then Continue;
      if (LFrom.NodeType = ntToken) and (LTo.NodeType = ntCategory) and not FIncludeTokenCategory then Continue;
      
      LPass := True;
      
      // CategoryFilter
      if Trim(FCategoryFilter) <> '' then
      begin
        LPass := ((LFrom.NodeType = ntCategory) and SameText(LFrom.Text, FCategoryFilter)) or
                 ((LTo.NodeType = ntCategory) and SameText(LTo.Text, FCategoryFilter));
      end;
      
      // TokenFilter
      if LPass and (Trim(FTokenFilter) <> '') then
      begin
        LPass := ((LFrom.NodeType = ntToken) and (Pos(UTF8LowerCase(FTokenFilter), UTF8LowerCase(LFrom.Text)) > 0)) or
                 ((LTo.NodeType = ntToken) and (Pos(UTF8LowerCase(FTokenFilter), UTF8LowerCase(LTo.Text)) > 0));
      end;
      
      if LPass then
        LTempEdges.Add(LEdge);
    end;
    
    // Sort edges by weight to keep TopN
    SortEdgesByWeight(LTempEdges);
    
    j := LTempEdges.Count;
    if (FTopN > 0) and (j > FTopN) then j := FTopN;
    
    for i := 0 to j - 1 do
    begin
      LEdge := TAIGraphEdge(LTempEdges[i]);
      AFilteredEdges.Add(LEdge);
      
      // Collect referenced node IDs
      if LNodeIds.IndexOf(Pointer(LEdge.FromNodeId)) < 0 then LNodeIds.Add(Pointer(LEdge.FromNodeId));
      if LNodeIds.IndexOf(Pointer(LEdge.ToNodeId)) < 0 then LNodeIds.Add(Pointer(LEdge.ToNodeId));
    end;
    
    // 2. Add referenced nodes
    for i := 0 to LNodeIds.Count - 1 do
    begin
      LNode := FGraphMap.FindNodeById(Integer(LNodeIds[i]));
      if Assigned(LNode) then
        AFilteredNodes.Add(LNode);
    end;
    
  finally
    LTempEdges.Free;
    LNodeIds.Free;
  end;
end;

procedure TAIGraphVisualizer.ExportToDOT(const AFileName: string);
var
  LOut: TStringList;
  LNodes, LEdges: TList;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
  LStyle: string;
begin
  ClearError;
  if not Assigned(FGraphMap) then
  begin
    SetError('GraphMap não associado.');
    Exit;
  end;
  
  LOut := TStringList.Create;
  GetFilteredGraph(LNodes, LEdges);
  try
    try
      LOut.Add('digraph TAIGraphMapVisual {');
      LOut.Add('  rankdir=LR;');
      LOut.Add('  node [style=filled, fontname="Arial"];');
      LOut.Add('');
      
      // Write nodes
      for i := 0 to LNodes.Count - 1 do
      begin
        LNode := TAIGraphNode(LNodes[i]);
        if LNode.NodeType = ntCategory then
          LStyle := 'shape=doublecircle, fillcolor="#FFD6D6", color="#FF3333"'
        else
          LStyle := 'shape=box, fillcolor="#D6E4FF", color="#3377FF"';
          
        LOut.Add(Format('  n%d [%s, label="%s\n(Weight: %.2f)"];', [
          LNode.Id, LStyle, EscapeLabel(LNode.Text), LNode.Weight
        ]));
      end;
      
      LOut.Add('');
      
      // Write edges
      for i := 0 to LEdges.Count - 1 do
      begin
        LEdge := TAIGraphEdge(LEdges[i]);
        LOut.Add(Format('  n%d -> n%d [label="%.2f", weight="%.2f"];', [
          LEdge.FromNodeId, LEdge.ToNodeId, LEdge.Weight, LEdge.Weight
        ]));
      end;
      
      LOut.Add('}');
      LOut.SaveToFile(AFileName);
      
      FLastResult := Format('Grafo exportado para DOT: %s (Nós: %d, Arestas: %d)', [
        AFileName, LNodes.Count, LEdges.Count
      ]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    except
      on E: Exception do
        SetError('Erro ao exportar DOT: ' + E.Message);
    end;
  finally
    LEdges.Free;
    LNodes.Free;
    LOut.Free;
  end;
end;

procedure TAIGraphVisualizer.ExportToMermaid(const AFileName: string);
var
  LOut: TStringList;
  LNodes, LEdges: TList;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
begin
  ClearError;
  if not Assigned(FGraphMap) then
  begin
    SetError('GraphMap não associado.');
    Exit;
  end;
  
  LOut := TStringList.Create;
  GetFilteredGraph(LNodes, LEdges);
  try
    try
      LOut.Add('graph LR');
      
      // Nodes declarations with shapes
      for i := 0 to LNodes.Count - 1 do
      begin
        LNode := TAIGraphNode(LNodes[i]);
        if LNode.NodeType = ntCategory then
          LOut.Add(Format('  n%d(["%s"])', [LNode.Id, EscapeLabel(LNode.Text)]))
        else
          LOut.Add(Format('  n%d["%s"]', [LNode.Id, EscapeLabel(LNode.Text)]));
      end;
      
      // Edges with weight labels
      for i := 0 to LEdges.Count - 1 do
      begin
        LEdge := TAIGraphEdge(LEdges[i]);
        LOut.Add(Format('  n%d -->|%.2f| n%d', [
          LEdge.FromNodeId, LEdge.Weight, LEdge.ToNodeId
        ]));
      end;
      
      LOut.SaveToFile(AFileName);
      FLastResult := Format('Grafo exportado para Mermaid: %s (Nós: %d, Arestas: %d)', [
        AFileName, LNodes.Count, LEdges.Count
      ]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    except
      on E: Exception do
        SetError('Erro ao exportar Mermaid: ' + E.Message);
    end;
  finally
    LEdges.Free;
    LNodes.Free;
    LOut.Free;
  end;
end;

procedure TAIGraphVisualizer.ExportToJSONVisual(const AFileName: string);
var
  LOut: TStringList;
  LNodes, LEdges: TList;
  LRoot, LNodeObj, LEdgeObj: TJSONObject;
  LNodesArr, LEdgesArr: TJSONArray;
  i: Integer;
  LNode: TAIGraphNode;
  LEdge: TAIGraphEdge;
begin
  ClearError;
  if not Assigned(FGraphMap) then
  begin
    SetError('GraphMap não associado.');
    Exit;
  end;
  
  LOut := TStringList.Create;
  GetFilteredGraph(LNodes, LEdges);
  LRoot := TJSONObject.Create;
  LNodesArr := TJSONArray.Create;
  LEdgesArr := TJSONArray.Create;
  try
    try
      LRoot.Add('nodes', LNodesArr);
      LRoot.Add('edges', LEdgesArr);
      
      for i := 0 to LNodes.Count - 1 do
      begin
        LNode := TAIGraphNode(LNodes[i]);
        LNodeObj := TJSONObject.Create;
        LNodeObj.Add('id', LNode.Id);
        LNodeObj.Add('label', LNode.Text);
        if LNode.NodeType = ntCategory then
          LNodeObj.Add('group', 'category')
        else
          LNodeObj.Add('group', 'token');
        LNodeObj.Add('weight', LNode.Weight);
        LNodeObj.Add('value', LNode.HitCount);
        LNodesArr.Add(LNodeObj);
      end;
      
      for i := 0 to LEdges.Count - 1 do
      begin
        LEdge := TAIGraphEdge(LEdges[i]);
        LEdgeObj := TJSONObject.Create;
        LEdgeObj.Add('from', LEdge.FromNodeId);
        LEdgeObj.Add('to', LEdge.ToNodeId);
        LEdgeObj.Add('label', FormatFloat('0.00', LEdge.Weight));
        LEdgeObj.Add('weight', LEdge.Weight);
        LEdgesArr.Add(LEdgeObj);
      end;
      
      LOut.Text := LRoot.AsJSON;
      LOut.SaveToFile(AFileName);
      
      FLastResult := Format('Grafo exportado para JSON Visual: %s', [AFileName]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    except
      on E: Exception do
        SetError('Erro ao exportar JSON: ' + E.Message);
    end;
  finally
    LRoot.Free; // Freeing LRoot cleans all children in fpJSON
    LEdges.Free;
    LNodes.Free;
    LOut.Free;
  end;
end;

procedure TAIGraphVisualizer.ExportSummary(const AFileName: string);
var
  LOut: TStringList;
  LNodes, LEdges: TList;
  i: Integer;
  LFrom, LTo: TAIGraphNode;
  LEdge: TAIGraphEdge;
begin
  ClearError;
  if not Assigned(FGraphMap) then
  begin
    SetError('GraphMap não associado.');
    Exit;
  end;
  
  LOut := TStringList.Create;
  GetFilteredGraph(LNodes, LEdges);
  try
    try
      LOut.Add('================================================================================');
      LOut.Add('                          RESUMO E ESTRUTURA DO GRAFO                           ');
      LOut.Add('================================================================================');
      LOut.Add('Gerado em: ' + DateTimeToStr(Now));
      LOut.Add(Format('Filtros aplicados: Categoria="%s", Token="%s", TopN=%d, MinWeight=%.2f', [
        FCategoryFilter, FTokenFilter, FTopN, FMinWeight
      ]));
      LOut.Add('');
      LOut.Add(Format('Nós Filtrados: %d | Relações Filtradas: %d', [LNodes.Count, LEdges.Count]));
      LOut.Add('');
      LOut.Add('=== Relações de Maior Peso ===');
      for i := 0 to LEdges.Count - 1 do
      begin
        LEdge := TAIGraphEdge(LEdges[i]);
        LFrom := FGraphMap.FindNodeById(LEdge.FromNodeId);
        LTo := FGraphMap.FindNodeById(LEdge.ToNodeId);
        
        if Assigned(LFrom) and Assigned(LTo) then
        begin
          LOut.Add(Format('  - [%s] --(Peso: %.2f, Hits: %d)--> [%s]', [
            LFrom.Text, LEdge.Weight, LEdge.HitCount, LTo.Text
          ]));
        end;
      end;
      LOut.Add('================================================================================');
      
      LOut.SaveToFile(AFileName);
      
      // Feed to OutputDocs if present
      if Assigned(FOutputDocs) then
      begin
        FOutputDocs.Clear;
        FOutputDocs.Title := 'Resumo Estrutural do Grafo';
        FOutputDocs.AddHeading('Visualização Estrutural do Grafo', 1);
        for i := 0 to LOut.Count - 1 do
          FOutputDocs.AddParagraph(LOut[i]);
        FOutputDocs.SaveToTXT;
      end;
      
      FLastResult := Format('Resumo do grafo exportado para: %s', [AFileName]);
      FLastSuccess := True;
      Log(llInfo, FLastResult);
    except
      on E: Exception do
        SetError('Erro ao exportar resumo: ' + E.Message);
    end;
  finally
    LEdges.Free;
    LNodes.Free;
    LOut.Free;
  end;
end;

end.
