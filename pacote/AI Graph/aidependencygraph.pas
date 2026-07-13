unit aidependencygraph;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, fpjson, jsonparser, aibase;

const
  AIDG_KIND_FACTUAL  = 'factual';
  AIDG_KIND_INFERRED = 'inferred';

  AIDG_NODE_REPOSITORY = 'repository';
  AIDG_NODE_PACKAGE = 'package';
  AIDG_NODE_UNIT = 'unit';
  AIDG_NODE_COMPONENT = 'component';
  AIDG_NODE_SAMPLE = 'sample';
  AIDG_NODE_EXTERNAL = 'external_dependency';

  AIDG_EDGE_CONTAINS = 'contains';
  AIDG_EDGE_DECLARES = 'declares';
  AIDG_EDGE_REGISTERS = 'registers';
  AIDG_EDGE_REQUIRES_PACKAGE = 'requires_package';
  AIDG_EDGE_USES_UNIT = 'uses_unit';
  AIDG_EDGE_DEMONSTRATED_BY = 'demonstrated_by';

type
  TAIDependencyEvidence = record
    SourceFile: string;
    Line: Integer;
    Parser: string;
  end;

  TAIDependencyNode = class
  public
    Id: string;
    NodeType: string;
    Name: string;
    Path: string;
    Attrs: TStringList;
    Evidence: TAIDependencyEvidence;
    constructor Create;
    destructor Destroy; override;
    function AsJSON: TJSONObject;
  end;

  TAIDependencyEdge = class
  public
    Id: string;
    FromId: string;
    ToId: string;
    EdgeType: string;
    Kind: string;
    Confidence: Double;
    Source: string;
    Evidence: TAIDependencyEvidence;
    function AsJSON: TJSONObject;
  end;

  TAIDependencyNodeList = specialize TFPGObjectList<TAIDependencyNode>;
  TAIDependencyEdgeList = specialize TFPGObjectList<TAIDependencyEdge>;

  TAIDependencyValidation = record
    BrokenEdges: Integer;
    NoEvidence: Integer;
    SelfEdges: Integer;
    OrphanNodes: Integer;
    Empty: Boolean;
    Passed: Boolean;
  end;

  { TAIDependencyGraph }

  TAIDependencyGraph = class(TAIBaseComponent)
  private
    FNodes: TAIDependencyNodeList;
    FEdges: TAIDependencyEdgeList;
    FInferredEdges: TAIDependencyEdgeList;
    FNodeIndex: TStringList;
    FEdgeIndex: TStringList;
    FInferredIndex: TStringList;
    FValidated: Boolean;
    function GetNodeCount: Integer;
    function GetEdgeCount: Integer;
    procedure IndexNode(const AId: string; ANode: TAIDependencyNode);
    procedure IndexEdge(const AId: string; AEdge: TAIDependencyEdge; AInferred: Boolean);
    function HasEvidence(const AEv: TAIDependencyEvidence): Boolean;
    function NodeTypeToDotStyle(const ANodeType: string): string;
    function EscapeText(const S: string): string;
    function LoadNodeEvidence(ANodeObj: TJSONObject; out ANode: TAIDependencyNode): Boolean;
    function LoadEdgeEvidence(AEdgeObj: TJSONObject; out AEdge: TAIDependencyEdge;
      const AExpectedKind: string): Boolean;
    function LoadInferredEdge(AEdgeObj: TJSONObject; out AEdge: TAIDependencyEdge): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AddNode(const AId, AType, AName, APath: string;
      const AEv: TAIDependencyEvidence): TAIDependencyNode;
    function AddEdge(const AFromId, AToId, AType: string;
      const AEv: TAIDependencyEvidence): TAIDependencyEdge;
    function AddInferredEdge(const AFromId, AToId, AType: string;
      AConfidence: Double; const ASource: string): TAIDependencyEdge;
    function FindNode(const AId: string): TAIDependencyNode;
    procedure Clear;

    function Validate: TAIDependencyValidation;
    function CountNodesOfType(const AType: string): Integer;
    function CountEdgesOfType(const AType: string): Integer;

    function SaveToJSON(const AFileName: string): Boolean;
    function LoadFromJSON(const AFileName: string): Boolean;
    function SaveToDOT(const AFileName: string): Boolean;
    function SaveToMermaid(const AFileName: string): Boolean;

    property Nodes: TAIDependencyNodeList read FNodes;
    property Edges: TAIDependencyEdgeList read FEdges;
    property InferredEdges: TAIDependencyEdgeList read FInferredEdges;
  published
    property NodeCount: Integer read GetNodeCount;
    property EdgeCount: Integer read GetEdgeCount;
    property Validated: Boolean read FValidated;
  end;

function MakeAIDependencyEvidence(const ASourceFile: string; ALine: Integer;
  const AParser: string): TAIDependencyEvidence;
function MakeAIDependencyNodeId(const AType, AName: string): string;
function AIDependencyEvidenceToJSON(const AEv: TAIDependencyEvidence): TJSONObject;

procedure Register;

implementation

function MakeAIDependencyEvidence(const ASourceFile: string; ALine: Integer;
  const AParser: string): TAIDependencyEvidence;
begin
  Result.SourceFile := ASourceFile;
  Result.Line := ALine;
  Result.Parser := AParser;
end;

function MakeAIDependencyNodeId(const AType, AName: string): string;
begin
  Result := AType + ':' + LowerCase(Trim(AName));
end;

function AIDependencyEvidenceToJSON(const AEv: TAIDependencyEvidence): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.Add('file', AEv.SourceFile);
  Result.Add('line', AEv.Line);
  Result.Add('parser', AEv.Parser);
end;

procedure Register;
begin
  RegisterComponents('AI Graph', [TAIDependencyGraph]);
end;

constructor TAIDependencyNode.Create;
begin
  inherited Create;
  Attrs := TStringList.Create;
  Attrs.NameValueSeparator := '=';
end;

destructor TAIDependencyNode.Destroy;
begin
  Attrs.Free;
  inherited Destroy;
end;

function TAIDependencyNode.AsJSON: TJSONObject;
var
  A: TJSONObject;
  E: TJSONArray;
  I: Integer;
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

  E := TJSONArray.Create;
  if (Trim(Evidence.SourceFile) <> '') or (Trim(Evidence.Parser) <> '') then
    E.Add(AIDependencyEvidenceToJSON(Evidence));
  Result.Add('evidence', E);
end;

function TAIDependencyEdge.AsJSON: TJSONObject;
var
  E: TJSONArray;
begin
  Result := TJSONObject.Create;
  Result.Add('id', Id);
  Result.Add('from', FromId);
  Result.Add('to', ToId);
  Result.Add('type', EdgeType);
  Result.Add('kind', Kind);
  if Kind = AIDG_KIND_INFERRED then
  begin
    Result.Add('confidence', Confidence);
    Result.Add('source', Source);
  end;

  E := TJSONArray.Create;
  if (Trim(Evidence.SourceFile) <> '') or (Trim(Evidence.Parser) <> '') then
    E.Add(AIDependencyEvidenceToJSON(Evidence));
  Result.Add('evidence', E);
end;

constructor TAIDependencyGraph.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FNodes := TAIDependencyNodeList.Create(True);
  FEdges := TAIDependencyEdgeList.Create(True);
  FInferredEdges := TAIDependencyEdgeList.Create(True);

  FNodeIndex := TStringList.Create;
  FNodeIndex.Sorted := True;
  FNodeIndex.Duplicates := dupIgnore;
  FNodeIndex.CaseSensitive := False;

  FEdgeIndex := TStringList.Create;
  FEdgeIndex.Sorted := True;
  FEdgeIndex.Duplicates := dupIgnore;
  FEdgeIndex.CaseSensitive := False;

  FInferredIndex := TStringList.Create;
  FInferredIndex.Sorted := True;
  FInferredIndex.Duplicates := dupIgnore;
  FInferredIndex.CaseSensitive := False;

  FValidated := False;
  FPrompt := 'Component TAIDependencyGraph stores a factual dependency graph with mandatory evidence, stable IDs, deduplication, validation, and separated inferred edges.';
  ClearError;
end;

destructor TAIDependencyGraph.Destroy;
begin
  FInferredIndex.Free;
  FEdgeIndex.Free;
  FNodeIndex.Free;
  FInferredEdges.Free;
  FEdges.Free;
  FNodes.Free;
  inherited Destroy;
end;

procedure TAIDependencyGraph.IndexNode(const AId: string; ANode: TAIDependencyNode);
begin
  FNodeIndex.AddObject(AId, ANode);
end;

procedure TAIDependencyGraph.IndexEdge(const AId: string; AEdge: TAIDependencyEdge; AInferred: Boolean);
begin
  if AInferred then
    FInferredIndex.AddObject(AId, AEdge)
  else
    FEdgeIndex.AddObject(AId, AEdge);
end;

function TAIDependencyGraph.HasEvidence(const AEv: TAIDependencyEvidence): Boolean;
begin
  Result := (Trim(AEv.SourceFile) <> '') and (Trim(AEv.Parser) <> '');
end;

function TAIDependencyGraph.NodeTypeToDotStyle(const ANodeType: string): string;
begin
  if ANodeType = AIDG_NODE_REPOSITORY then
    Result := 'shape=folder, fillcolor="#e8eaf6"'
  else if ANodeType = AIDG_NODE_PACKAGE then
    Result := 'shape=box3d, fillcolor="#c8e6c9"'
  else if ANodeType = AIDG_NODE_UNIT then
    Result := 'shape=note, fillcolor="#fff9c4"'
  else if ANodeType = AIDG_NODE_COMPONENT then
    Result := 'shape=component, fillcolor="#bbdefb"'
  else if ANodeType = AIDG_NODE_SAMPLE then
    Result := 'shape=tab, fillcolor="#f8bbd0"'
  else if ANodeType = AIDG_NODE_EXTERNAL then
    Result := 'shape=box, style="filled,dashed", fillcolor="#eeeeee"'
  else
    Result := 'shape=ellipse, fillcolor="#ffffff"';
end;

function TAIDependencyGraph.EscapeText(const S: string): string;
begin
  Result := StringReplace(S, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #10, ' ', [rfReplaceAll]);
  Result := StringReplace(Result, #13, ' ', [rfReplaceAll]);
end;

function TAIDependencyGraph.LoadNodeEvidence(ANodeObj: TJSONObject; out ANode: TAIDependencyNode): Boolean;
var
  Attrs: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  EvObj: TJSONObject;
begin
  Result := False;
  ANode := TAIDependencyNode.Create;
  if (ANodeObj.Find('id') = nil) or
     (ANodeObj.Find('type') = nil) or
     (ANodeObj.Find('name') = nil) then
  begin
    ANode.Free;
    Exit;
  end;

  try
    ANode.Id := ANodeObj.Strings['id'];
    ANode.NodeType := ANodeObj.Strings['type'];
    ANode.Name := ANodeObj.Strings['name'];
    if ANodeObj.Find('path') <> nil then
      ANode.Path := ANodeObj.Strings['path'];

    if ANodeObj.Find('attributes') <> nil then
    begin
      Attrs := ANodeObj.Objects['attributes'];
      if Assigned(Attrs) then
        for I := 0 to Attrs.Count - 1 do
          ANode.Attrs.Values[Attrs.Names[I]] := Attrs.Items[I].AsString;
    end;

    if ANodeObj.Find('evidence') <> nil then
    begin
      Arr := ANodeObj.Arrays['evidence'];
      if (Arr <> nil) and (Arr.Count > 0) then
      begin
        EvObj := Arr.Objects[0];
        if Assigned(EvObj) then
        begin
          if EvObj.Find('file') <> nil then
            ANode.Evidence.SourceFile := EvObj.Strings['file'];
          if EvObj.Find('line') <> nil then
            ANode.Evidence.Line := EvObj.Integers['line'];
          if EvObj.Find('parser') <> nil then
            ANode.Evidence.Parser := EvObj.Strings['parser'];
        end;
      end;
    end;

    Result := True;
  except
    ANode.Free;
    raise;
  end;
end;

function TAIDependencyGraph.LoadEdgeEvidence(AEdgeObj: TJSONObject; out AEdge: TAIDependencyEdge;
  const AExpectedKind: string): Boolean;
var
  Arr: TJSONArray;
  EvObj: TJSONObject;
begin
  Result := False;
  AEdge := TAIDependencyEdge.Create;
  if (AEdgeObj.Find('id') = nil) or
     (AEdgeObj.Find('from') = nil) or
     (AEdgeObj.Find('to') = nil) or
     (AEdgeObj.Find('type') = nil) then
  begin
    AEdge.Free;
    Exit;
  end;

  try
    AEdge.Id := AEdgeObj.Strings['id'];
    AEdge.FromId := AEdgeObj.Strings['from'];
    AEdge.ToId := AEdgeObj.Strings['to'];
    AEdge.EdgeType := AEdgeObj.Strings['type'];
    if AEdgeObj.Find('kind') <> nil then
      AEdge.Kind := AEdgeObj.Strings['kind']
    else
      AEdge.Kind := AExpectedKind;

    if not SameText(AEdge.Kind, AExpectedKind) then
    begin
      AEdge.Free;
      Exit;
    end;

    if AEdgeObj.Find('confidence') <> nil then
      AEdge.Confidence := AEdgeObj.Floats['confidence']
    else
      AEdge.Confidence := 1.0;

    if AEdgeObj.Find('source') <> nil then
      AEdge.Source := AEdgeObj.Strings['source'];

    if AEdgeObj.Find('evidence') <> nil then
    begin
      Arr := AEdgeObj.Arrays['evidence'];
      if (Arr <> nil) and (Arr.Count > 0) then
      begin
        EvObj := Arr.Objects[0];
        if Assigned(EvObj) then
        begin
          if EvObj.Find('file') <> nil then
            AEdge.Evidence.SourceFile := EvObj.Strings['file'];
          if EvObj.Find('line') <> nil then
            AEdge.Evidence.Line := EvObj.Integers['line'];
          if EvObj.Find('parser') <> nil then
            AEdge.Evidence.Parser := EvObj.Strings['parser'];
        end;
      end;
    end;

    Result := True;
  except
    AEdge.Free;
    raise;
  end;
end;

function TAIDependencyGraph.LoadInferredEdge(AEdgeObj: TJSONObject; out AEdge: TAIDependencyEdge): Boolean;
begin
  Result := LoadEdgeEvidence(AEdgeObj, AEdge, AIDG_KIND_INFERRED);
  if Result then
    AEdge.Kind := AIDG_KIND_INFERRED;
end;

function TAIDependencyGraph.AddNode(const AId, AType, AName, APath: string;
  const AEv: TAIDependencyEvidence): TAIDependencyNode;
begin
  ClearError;
  Result := FindNode(AId);
  if Assigned(Result) then
    Exit;

  if (Trim(AId) = '') or (Trim(AType) = '') or (Trim(AName) = '') then
  begin
    SetError('Invalid node data.');
    Exit(nil);
  end;

  if not HasEvidence(AEv) then
  begin
    SetError('Node evidence is required.');
    Exit(nil);
  end;

  Result := TAIDependencyNode.Create;
  Result.Id := AId;
  Result.NodeType := AType;
  Result.Name := AName;
  Result.Path := APath;
  Result.Evidence := AEv;
  FNodes.Add(Result);
  IndexNode(AId, Result);
  FValidated := False;
end;

function TAIDependencyGraph.AddEdge(const AFromId, AToId, AType: string;
  const AEv: TAIDependencyEvidence): TAIDependencyEdge;
var
  EId: string;
  Idx: Integer;
begin
  ClearError;
  EId := Format('edge:%s|%s|%s', [AFromId, AType, AToId]);
  Idx := FEdgeIndex.IndexOf(EId);
  if Idx >= 0 then
    Exit(TAIDependencyEdge(FEdgeIndex.Objects[Idx]));

  if (Trim(AFromId) = '') or (Trim(AToId) = '') or (Trim(AType) = '') then
  begin
    SetError('Invalid edge data.');
    Exit(nil);
  end;

  if not HasEvidence(AEv) then
  begin
    SetError('Edge evidence is required.');
    Exit(nil);
  end;

  Result := TAIDependencyEdge.Create;
  Result.Id := EId;
  Result.FromId := AFromId;
  Result.ToId := AToId;
  Result.EdgeType := AType;
  Result.Kind := AIDG_KIND_FACTUAL;
  Result.Confidence := 1.0;
  Result.Source := '';
  Result.Evidence := AEv;
  FEdges.Add(Result);
  IndexEdge(EId, Result, False);
  FValidated := False;
end;

function TAIDependencyGraph.AddInferredEdge(const AFromId, AToId, AType: string;
  AConfidence: Double; const ASource: string): TAIDependencyEdge;
var
  EId: string;
  Idx: Integer;
begin
  ClearError;
  EId := Format('inferred:%s|%s|%s', [AFromId, AType, AToId]);
  Idx := FInferredIndex.IndexOf(EId);
  if Idx >= 0 then
    Exit(TAIDependencyEdge(FInferredIndex.Objects[Idx]));

  if (Trim(AFromId) = '') or (Trim(AToId) = '') or (Trim(AType) = '') then
  begin
    SetError('Invalid inferred edge data.');
    Exit(nil);
  end;

  Result := TAIDependencyEdge.Create;
  Result.Id := EId;
  Result.FromId := AFromId;
  Result.ToId := AToId;
  Result.EdgeType := AType;
  Result.Kind := AIDG_KIND_INFERRED;
  Result.Confidence := AConfidence;
  Result.Source := ASource;
  Result.Evidence.SourceFile := '';
  Result.Evidence.Line := 0;
  Result.Evidence.Parser := '';
  FInferredEdges.Add(Result);
  IndexEdge(EId, Result, True);
  FValidated := False;
end;

function TAIDependencyGraph.FindNode(const AId: string): TAIDependencyNode;
var
  Idx: Integer;
begin
  Result := nil;
  Idx := FNodeIndex.IndexOf(AId);
  if Idx >= 0 then
    Result := TAIDependencyNode(FNodeIndex.Objects[Idx]);
end;

procedure TAIDependencyGraph.Clear;
begin
  ClearError;
  FNodes.Clear;
  FEdges.Clear;
  FInferredEdges.Clear;
  FNodeIndex.Clear;
  FEdgeIndex.Clear;
  FInferredIndex.Clear;
  FValidated := False;
end;

function TAIDependencyGraph.CountNodesOfType(const AType: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FNodes.Count - 1 do
    if SameText(FNodes[I].NodeType, AType) then
      Inc(Result);
end;

function TAIDependencyGraph.CountEdgesOfType(const AType: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FEdges.Count - 1 do
    if SameText(FEdges[I].EdgeType, AType) then
      Inc(Result);
end;

function TAIDependencyGraph.GetNodeCount: Integer;
begin
  Result := FNodes.Count;
end;

function TAIDependencyGraph.GetEdgeCount: Integer;
begin
  Result := FEdges.Count;
end;

function TAIDependencyGraph.Validate: TAIDependencyValidation;
var
  I: Integer;
  Degree: TStringList;
  Node: TAIDependencyNode;
  Edge: TAIDependencyEdge;
begin
  Result.BrokenEdges := 0;
  Result.NoEvidence := 0;
  Result.SelfEdges := 0;
  Result.OrphanNodes := 0;
  Result.Empty := (FNodes.Count = 0) and (FEdges.Count = 0);

  Degree := TStringList.Create;
  Degree.Sorted := True;
  Degree.Duplicates := dupIgnore;
  Degree.CaseSensitive := False;
  try
    for I := 0 to FEdges.Count - 1 do
    begin
      Edge := FEdges[I];
      if (FindNode(Edge.FromId) = nil) or (FindNode(Edge.ToId) = nil) then
        Inc(Result.BrokenEdges);
      if Edge.FromId = Edge.ToId then
        Inc(Result.SelfEdges);
      if not HasEvidence(Edge.Evidence) then
        Inc(Result.NoEvidence);
      Degree.Add(Edge.FromId);
      Degree.Add(Edge.ToId);
    end;

    for I := 0 to FNodes.Count - 1 do
    begin
      Node := FNodes[I];
      if not HasEvidence(Node.Evidence) then
        Inc(Result.NoEvidence);
      if Degree.IndexOf(Node.Id) < 0 then
        Inc(Result.OrphanNodes);
    end;
  finally
    Degree.Free;
  end;

  Result.Passed := not Result.Empty and
                   (Result.BrokenEdges = 0) and
                   (Result.NoEvidence = 0) and
                   (Result.SelfEdges = 0);
  FValidated := Result.Passed;
end;

function TAIDependencyGraph.SaveToJSON(const AFileName: string): Boolean;
var
  Root: TJSONObject;
  NodesArr, EdgesArr, InferredArr: TJSONArray;
  I: Integer;
  SL: TStringList;
begin
  Result := False;
  ClearError;
  Root := TJSONObject.Create;
  try
    Root.Add('schema', 'fgx-dependency-graph-v1');
    Root.Add('kind', AIDG_KIND_FACTUAL);
    Root.Add('generated_at', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));

    NodesArr := TJSONArray.Create;
    for I := 0 to FNodes.Count - 1 do
      NodesArr.Add(FNodes[I].AsJSON);
    Root.Add('nodes', NodesArr);

    EdgesArr := TJSONArray.Create;
    for I := 0 to FEdges.Count - 1 do
      EdgesArr.Add(FEdges[I].AsJSON);
    Root.Add('edges', EdgesArr);

    InferredArr := TJSONArray.Create;
    for I := 0 to FInferredEdges.Count - 1 do
      InferredArr.Add(FInferredEdges[I].AsJSON);
    Root.Add('inferred_edges', InferredArr);

    SL := TStringList.Create;
    try
      SL.Text := Root.FormatJSON();
      SL.SaveToFile(AFileName);
      Result := True;
    finally
      SL.Free;
    end;
  except
    on E: Exception do
      SetError('SaveToJSON failed: ' + E.Message);
  end;
  Root.Free;
end;

function TAIDependencyGraph.LoadFromJSON(const AFileName: string): Boolean;
var
  SL: TStringList;
  Data: TJSONData;
  Root: TJSONObject;
  NodesArr, EdgesArr, InferredArr: TJSONArray;
  I: Integer;
  NodeObj: TJSONObject;
  EdgeObj: TJSONObject;
  Node: TAIDependencyNode;
  Edge: TAIDependencyEdge;
begin
  Result := False;
  Clear;
  ClearError;
  Data := nil;

  if not FileExists(AFileName) then
  begin
    SetError('File does not exist: ' + AFileName);
    Exit;
  end;

  SL := TStringList.Create;
  try
    try
      SL.LoadFromFile(AFileName);
      Data := GetJSON(SL.Text);

      if Data.JSONType <> jtObject then
        raise Exception.Create('JSON root is not an object.');

      Root := TJSONObject(Data);
      if Root.Find('nodes') = nil then
        raise Exception.Create('JSON missing nodes.');
      if Root.Find('edges') = nil then
        raise Exception.Create('JSON missing edges.');

      NodesArr := Root.Arrays['nodes'];
      for I := 0 to NodesArr.Count - 1 do
      begin
        NodeObj := NodesArr.Objects[I];
        if not LoadNodeEvidence(NodeObj, Node) then
          raise Exception.Create('Invalid node entry.');
        FNodes.Add(Node);
        IndexNode(Node.Id, Node);
      end;

      EdgesArr := Root.Arrays['edges'];
      for I := 0 to EdgesArr.Count - 1 do
      begin
        EdgeObj := EdgesArr.Objects[I];
        if not LoadEdgeEvidence(EdgeObj, Edge, AIDG_KIND_FACTUAL) then
          raise Exception.Create('Invalid edge entry.');
        FEdges.Add(Edge);
        IndexEdge(Edge.Id, Edge, False);
      end;

      if Root.Find('inferred_edges') <> nil then
      begin
        InferredArr := Root.Arrays['inferred_edges'];
        for I := 0 to InferredArr.Count - 1 do
        begin
          EdgeObj := InferredArr.Objects[I];
          if not LoadInferredEdge(EdgeObj, Edge) then
            raise Exception.Create('Invalid inferred edge entry.');
          FInferredEdges.Add(Edge);
          IndexEdge(Edge.Id, Edge, True);
        end;
      end;

      Result := True;
    except
      on E: Exception do
      begin
        Clear;
        SetError('LoadFromJSON failed: ' + E.Message);
      end;
    end;
  finally
    if Assigned(Data) then
      Data.Free;
    SL.Free;
  end;

  FValidated := False;
end;

function TAIDependencyGraph.SaveToDOT(const AFileName: string): Boolean;
var
  SL: TStringList;
  I: Integer;
  Node: TAIDependencyNode;
  Edge: TAIDependencyEdge;
begin
  Result := False;
  ClearError;
  SL := TStringList.Create;
  try
    try
      SL.Add('digraph TAIDependencyGraph {');
      SL.Add('  rankdir=LR;');
      SL.Add('  node [style=filled, fontname="Helvetica", fontsize=10];');
      SL.Add('  edge [fontname="Helvetica", fontsize=8, color="#555555"];');
      SL.Add('');

      for I := 0 to FNodes.Count - 1 do
      begin
        Node := FNodes[I];
        SL.Add(Format('  "%s" [label="%s", %s];',
          [EscapeText(Node.Id), EscapeText(Node.Name), NodeTypeToDotStyle(Node.NodeType)]));
      end;

      SL.Add('');

      for I := 0 to FEdges.Count - 1 do
      begin
        Edge := FEdges[I];
        SL.Add(Format('  "%s" -> "%s" [label="%s"];',
          [EscapeText(Edge.FromId), EscapeText(Edge.ToId), EscapeText(Edge.EdgeType)]));
      end;

      for I := 0 to FInferredEdges.Count - 1 do
      begin
        Edge := FInferredEdges[I];
        SL.Add(Format('  "%s" -> "%s" [style=dashed, color="#999999", label="%s (%.2f)"];',
          [EscapeText(Edge.FromId), EscapeText(Edge.ToId), EscapeText(Edge.EdgeType), Edge.Confidence]));
      end;

      SL.Add('}');
      SL.SaveToFile(AFileName);
      Result := True;
    except
      on E: Exception do
        SetError('SaveToDOT failed: ' + E.Message);
    end;
  finally
    SL.Free;
  end;
end;

function TAIDependencyGraph.SaveToMermaid(const AFileName: string): Boolean;
var
  SL: TStringList;
  Map: TStringList;
  I: Integer;
  Node: TAIDependencyNode;
  Edge: TAIDependencyEdge;
  AliasFrom: string;
  AliasTo: string;
begin
  Result := False;
  ClearError;
  SL := TStringList.Create;
  Map := TStringList.Create;
  try
    Map.Sorted := True;
    Map.Duplicates := dupIgnore;
    Map.CaseSensitive := False;
    Map.NameValueSeparator := '=';
    for I := 0 to FNodes.Count - 1 do
      Map.Values[FNodes[I].Id] := 'n' + IntToStr(I + 1);

    try
      SL.Add('graph LR');
      SL.Add('');
      for I := 0 to FNodes.Count - 1 do
      begin
        Node := FNodes[I];
        AliasFrom := Map.Values[Node.Id];
        if Node.NodeType = AIDG_NODE_PACKAGE then
          SL.Add(Format('  %s["%s"]', [AliasFrom, EscapeText(Node.Name)]))
        else if Node.NodeType = AIDG_NODE_REPOSITORY then
          SL.Add(Format('  %s(["%s"])', [AliasFrom, EscapeText(Node.Name)]))
        else if Node.NodeType = AIDG_NODE_EXTERNAL then
          SL.Add(Format('  %s["%s"]', [AliasFrom, EscapeText(Node.Name)]))
        else
          SL.Add(Format('  %s["%s"]', [AliasFrom, EscapeText(Node.Name)]));
      end;

      SL.Add('');

      for I := 0 to FEdges.Count - 1 do
      begin
        Edge := FEdges[I];
        AliasFrom := Map.Values[Edge.FromId];
        AliasTo := Map.Values[Edge.ToId];
        if (AliasFrom = '') or (AliasTo = '') then
          Continue;
        SL.Add(Format('  %s -->|%s| %s', [
          AliasFrom,
          EscapeText(Edge.EdgeType),
          AliasTo
        ]));
      end;

      for I := 0 to FInferredEdges.Count - 1 do
      begin
        Edge := FInferredEdges[I];
        AliasFrom := Map.Values[Edge.FromId];
        AliasTo := Map.Values[Edge.ToId];
        if (AliasFrom = '') or (AliasTo = '') then
          Continue;
        SL.Add(Format('  %s -. "%s %.2f" .-> %s', [
          AliasFrom,
          EscapeText(Edge.EdgeType),
          Edge.Confidence,
          AliasTo
        ]));
      end;

      SL.SaveToFile(AFileName);
      Result := True;
    except
      on E: Exception do
        SetError('SaveToMermaid failed: ' + E.Message);
    end;
  finally
    Map.Free;
    SL.Free;
  end;
end;

end.
