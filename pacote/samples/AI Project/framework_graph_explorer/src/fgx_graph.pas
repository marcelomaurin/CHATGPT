{
  fgx_graph.pas — Grafo estrutural generico (nucleo do futuro TAIDependencyGraph)

  Parte do AI Framework Graph Explorer / Lazarus AI Suite.

  PRINCIPIO: todo no e toda aresta carregam evidencia (arquivo + linha + parser).
  Um grafo sem evidencia e rejeitado pela validacao. A IA nunca escreve aqui.

  Dependencias: apenas FPC (Classes, SysUtils, fgl, fpjson). Sem LCL.
}
unit fgx_graph;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, fpjson;

const
  KIND_FACTUAL  = 'factual';
  KIND_INFERRED = 'inferred';

  // Tipos de no (secao 7.1 da especificacao)
  NT_REPOSITORY = 'repository';
  NT_PACKAGE    = 'package';
  NT_UNIT       = 'unit';
  NT_COMPONENT  = 'component';
  NT_SAMPLE     = 'sample';
  NT_EXTERNAL   = 'external_dependency';

  // Tipos de aresta (secao 7.2)
  ET_CONTAINS         = 'contains';
  ET_DECLARES         = 'declares';
  ET_REGISTERS        = 'registers';
  ET_REQUIRES_PACKAGE = 'requires_package';
  ET_USES_UNIT        = 'uses_unit';
  ET_DEMONSTRATED_BY  = 'demonstrated_by';

type
  TFGXEvidence = record
    SourceFile: string;
    Line: Integer;
    Parser: string;
  end;

  TFGXNode = class
  public
    Id: string;
    NodeType: string;
    Name: string;
    Path: string;
    Attrs: TStringList;
    Evidence: TFGXEvidence;
    constructor Create;
    destructor Destroy; override;
    function AsJSON: TJSONObject;
  end;

  TFGXEdge = class
  public
    Id: string;
    FromId: string;
    ToId: string;
    EdgeType: string;
    Kind: string;
    Evidence: TFGXEvidence;
    function AsJSON: TJSONObject;
  end;

  TFGXNodeList = specialize TFPGObjectList<TFGXNode>;
  TFGXEdgeList = specialize TFPGObjectList<TFGXEdge>;

  TFGXValidation = record
    BrokenEdges: Integer;   // aresta apontando para no inexistente
    NoEvidence: Integer;    // no ou aresta sem evidencia
    SelfEdges: Integer;     // auto-aresta invalida
    OrphanNodes: Integer;   // no sem nenhuma aresta
    Passed: Boolean;
  end;

  TFGXGraph = class
  private
    FNodes: TFGXNodeList;
    FEdges: TFGXEdgeList;
    FIndex: TStringList;          // id -> TFGXNode (sorted, dedupe)
    FEdgeIndex: TStringList;      // edge id (dedupe)
  public
    constructor Create;
    destructor Destroy; override;

    function AddNode(const AId, AType, AName, APath: string;
                     const AEv: TFGXEvidence): TFGXNode;
    function AddEdge(const AFromId, AToId, AType: string;
                     const AEv: TFGXEvidence): TFGXEdge;
    function FindNode(const AId: string): TFGXNode;

    function NodeCount: Integer;
    function EdgeCount: Integer;
    function CountNodesOfType(const AType: string): Integer;
    function CountEdgesOfType(const AType: string): Integer;

    function Validate: TFGXValidation;

    procedure SaveJSON(const AFileName: string);
    procedure SaveDOT(const AFileName: string);

    property Nodes: TFGXNodeList read FNodes;
    property Edges: TFGXEdgeList read FEdges;
  end;

function MakeEvidence(const ASourceFile: string; ALine: Integer;
                      const AParser: string): TFGXEvidence;
function MakeNodeId(const AType, AName: string): string;

implementation

function MakeEvidence(const ASourceFile: string; ALine: Integer;
                      const AParser: string): TFGXEvidence;
begin
  Result.SourceFile := ASourceFile;
  Result.Line := ALine;
  Result.Parser := AParser;
end;

function MakeNodeId(const AType, AName: string): string;
begin
  Result := AType + ':' + LowerCase(Trim(AName));
end;

function EvidenceJSON(const AEv: TFGXEvidence): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('file', AEv.SourceFile);
  Result.Add('line', AEv.Line);
  Result.Add('parser', AEv.Parser);
end;

function HasEvidence(const AEv: TFGXEvidence): Boolean;
begin
  Result := (Trim(AEv.SourceFile) <> '') and (Trim(AEv.Parser) <> '');
end;

{ TFGXNode }

constructor TFGXNode.Create;
begin
  inherited Create;
  Attrs := TStringList.Create;
end;

destructor TFGXNode.Destroy;
begin
  Attrs.Free;
  inherited Destroy;
end;

function TFGXNode.AsJSON: TJSONObject;
var
  A: TJSONObject;
  I: Integer;
  Ev: TJSONArray;
begin
  Result := TJSONObject.Create;
  Result.Add('id', Id);
  Result.Add('type', NodeType);
  Result.Add('name', Name);
  Result.Add('path', Path);

  A := TJSONObject.Create;
  for I := 0 to Attrs.Count - 1 do
    A.Add(Attrs.Names[I], Attrs.ValueFromIndex[I]);
  Result.Add('attributes', A);

  Ev := TJSONArray.Create;
  if HasEvidence(Evidence) then
    Ev.Add(EvidenceJSON(Evidence));
  Result.Add('evidence', Ev);
end;

{ TFGXEdge }

function TFGXEdge.AsJSON: TJSONObject;
var
  Ev: TJSONArray;
begin
  Result := TJSONObject.Create;
  Result.Add('id', Id);
  Result.Add('from', FromId);
  Result.Add('to', ToId);
  Result.Add('type', EdgeType);
  Result.Add('kind', Kind);

  Ev := TJSONArray.Create;
  if HasEvidence(Evidence) then
    Ev.Add(EvidenceJSON(Evidence));
  Result.Add('evidence', Ev);
end;

{ TFGXGraph }

constructor TFGXGraph.Create;
begin
  inherited Create;
  FNodes := TFGXNodeList.Create(True);
  FEdges := TFGXEdgeList.Create(True);

  FIndex := TStringList.Create;
  FIndex.Sorted := True;
  FIndex.Duplicates := dupIgnore;
  FIndex.CaseSensitive := False;

  FEdgeIndex := TStringList.Create;
  FEdgeIndex.Sorted := True;
  FEdgeIndex.Duplicates := dupIgnore;
  FEdgeIndex.CaseSensitive := False;
end;

destructor TFGXGraph.Destroy;
begin
  FEdgeIndex.Free;
  FIndex.Free;
  FEdges.Free;
  FNodes.Free;
  inherited Destroy;
end;

function TFGXGraph.FindNode(const AId: string): TFGXNode;
var
  I: Integer;
begin
  Result := nil;
  I := FIndex.IndexOf(AId);
  if I >= 0 then
    Result := TFGXNode(FIndex.Objects[I]);
end;

{ G029: IDs estaveis. Duas insercoes iguais nao duplicam o grafo. }
function TFGXGraph.AddNode(const AId, AType, AName, APath: string;
                           const AEv: TFGXEvidence): TFGXNode;
begin
  Result := FindNode(AId);
  if Result <> nil then
    Exit;

  Result := TFGXNode.Create;
  Result.Id := AId;
  Result.NodeType := AType;
  Result.Name := AName;
  Result.Path := APath;
  Result.Evidence := AEv;

  FNodes.Add(Result);
  FIndex.AddObject(AId, Result);
end;

function TFGXGraph.AddEdge(const AFromId, AToId, AType: string;
                           const AEv: TFGXEvidence): TFGXEdge;
var
  EId: string;
begin
  EId := Format('edge:%s|%s|%s', [AFromId, AType, AToId]);

  if FEdgeIndex.IndexOf(EId) >= 0 then
  begin
    Result := nil;
    Exit;
  end;

  Result := TFGXEdge.Create;
  Result.Id := EId;
  Result.FromId := AFromId;
  Result.ToId := AToId;
  Result.EdgeType := AType;
  Result.Kind := KIND_FACTUAL;   // este grafo so aceita fatos
  Result.Evidence := AEv;

  FEdges.Add(Result);
  FEdgeIndex.Add(EId);
end;

function TFGXGraph.NodeCount: Integer;
begin
  Result := FNodes.Count;
end;

function TFGXGraph.EdgeCount: Integer;
begin
  Result := FEdges.Count;
end;

function TFGXGraph.CountNodesOfType(const AType: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FNodes.Count - 1 do
    if FNodes[I].NodeType = AType then
      Inc(Result);
end;

function TFGXGraph.CountEdgesOfType(const AType: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FEdges.Count - 1 do
    if FEdges[I].EdgeType = AType then
      Inc(Result);
end;

{ G040: validacao do grafo factual }
function TFGXGraph.Validate: TFGXValidation;
var
  I: Integer;
  Degree: TStringList;
  Idx: Integer;
  E: TFGXEdge;
begin
  Result.BrokenEdges := 0;
  Result.NoEvidence := 0;
  Result.SelfEdges := 0;
  Result.OrphanNodes := 0;

  Degree := TStringList.Create;
  try
    Degree.Sorted := True;
    Degree.Duplicates := dupIgnore;
    Degree.CaseSensitive := False;

    for I := 0 to FEdges.Count - 1 do
    begin
      E := FEdges[I];

      if (FindNode(E.FromId) = nil) or (FindNode(E.ToId) = nil) then
        Inc(Result.BrokenEdges);

      if E.FromId = E.ToId then
        Inc(Result.SelfEdges);

      if not HasEvidence(E.Evidence) then
        Inc(Result.NoEvidence);

      Degree.Add(E.FromId);
      Degree.Add(E.ToId);
    end;

    for I := 0 to FNodes.Count - 1 do
    begin
      if not HasEvidence(FNodes[I].Evidence) then
        Inc(Result.NoEvidence);

      Idx := Degree.IndexOf(FNodes[I].Id);
      if Idx < 0 then
        Inc(Result.OrphanNodes);
    end;
  finally
    Degree.Free;
  end;

  Result.Passed := (Result.BrokenEdges = 0) and
                   (Result.NoEvidence = 0) and
                   (Result.SelfEdges = 0);
end;

procedure TFGXGraph.SaveJSON(const AFileName: string);
var
  Root: TJSONObject;
  ArrN, ArrE: TJSONArray;
  I: Integer;
  SL: TStringList;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('schema', 'fgx-factual-graph-v1');
    Root.Add('kind', KIND_FACTUAL);
    Root.Add('generated_at', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));

    ArrN := TJSONArray.Create;
    for I := 0 to FNodes.Count - 1 do
      ArrN.Add(FNodes[I].AsJSON);
    Root.Add('nodes', ArrN);

    ArrE := TJSONArray.Create;
    for I := 0 to FEdges.Count - 1 do
      ArrE.Add(FEdges[I].AsJSON);
    Root.Add('edges', ArrE);

    SL := TStringList.Create;
    try
      SL.Text := Root.FormatJSON();
      SL.SaveToFile(AFileName);
    finally
      SL.Free;
    end;
  finally
    Root.Free;
  end;
end;

function DotStyleFor(const ANodeType: string): string;
begin
  if ANodeType = NT_REPOSITORY then
    Result := 'shape=folder, fillcolor="#e8eaf6"'
  else if ANodeType = NT_PACKAGE then
    Result := 'shape=box3d, fillcolor="#c8e6c9"'
  else if ANodeType = NT_UNIT then
    Result := 'shape=note, fillcolor="#fff9c4"'
  else if ANodeType = NT_COMPONENT then
    Result := 'shape=component, fillcolor="#bbdefb"'
  else if ANodeType = NT_SAMPLE then
    Result := 'shape=tab, fillcolor="#f8bbd0"'
  else if ANodeType = NT_EXTERNAL then
    Result := 'shape=box, style="filled,dashed", fillcolor="#eeeeee"'
  else
    Result := 'shape=ellipse, fillcolor="#ffffff"';
end;

function DotEscape(const S: string): string;
begin
  Result := StringReplace(S, '"', '\"', [rfReplaceAll]);
end;

procedure TFGXGraph.SaveDOT(const AFileName: string);
var
  SL: TStringList;
  I: Integer;
  N: TFGXNode;
  E: TFGXEdge;
begin
  SL := TStringList.Create;
  try
    SL.Add('digraph FrameworkGraph {');
    SL.Add('  rankdir=LR;');
    SL.Add('  node [style=filled, fontname="Helvetica", fontsize=10];');
    SL.Add('  edge [fontname="Helvetica", fontsize=8, color="#555555"];');
    SL.Add('');

    for I := 0 to FNodes.Count - 1 do
    begin
      N := FNodes[I];
      SL.Add(Format('  "%s" [label="%s", %s];',
        [DotEscape(N.Id), DotEscape(N.Name), DotStyleFor(N.NodeType)]));
    end;

    SL.Add('');

    for I := 0 to FEdges.Count - 1 do
    begin
      E := FEdges[I];
      SL.Add(Format('  "%s" -> "%s" [label="%s"];',
        [DotEscape(E.FromId), DotEscape(E.ToId), DotEscape(E.EdgeType)]));
    end;

    SL.Add('}');
    SL.SaveToFile(AFileName);
  finally
    SL.Free;
  end;
end;

end.
