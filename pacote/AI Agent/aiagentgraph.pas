unit aiagentgraph;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, fpjson, jsonparser, TypInfo, aibase, aiagent,
  LResources;

type
  TAIAgentNode = class;

  TAIAgentNodeKind = (agnAction, agnApproval, agnDelegation, agnEnd);
  TAIAgentNodeStatus = (ansPending, ansRunning, ansCompleted, ansFailed,
    ansNeedsApproval, ansRejected, ansSkipped, ansSimulated);
  TAIAgentGraphState = (agsIdle, agsRunning, agsNeedsApproval, agsCompleted,
    agsFailed);
  TAIAgentExecutionMode = (aemReal, aemSimulation, aemDryRun);
  TAIAgentEdgeCondition = (aecAlways, aecOnSuccess, aecOnFailure,
    aecOnApproved, aecOnRejected);

  TAIAgentNodeExecuteEvent = procedure(Sender: TObject; ANode: TAIAgentNode;
    const AInput: string; AMode: TAIAgentExecutionMode; out AOutput: string;
    var ASuccess: Boolean) of object;

  TAIAgentNode = class(TPersistent)
  private
    FID: string;
    FName: string;
    FKind: TAIAgentNodeKind;
    FStatus: TAIAgentNodeStatus;
    FAgentID: string;
    FAgent: TAIAgent;
    FExecutor: TComponent;
    FLastInput: string;
    FLastOutput: string;
    FLastError: string;
    FOnExecute: TAIAgentNodeExecuteEvent;
  published
    property ID: string read FID write FID;
    property Name: string read FName write FName;
    property Kind: TAIAgentNodeKind read FKind write FKind default agnAction;
    property Status: TAIAgentNodeStatus read FStatus write FStatus default ansPending;
    property AgentID: string read FAgentID write FAgentID;
    property Agent: TAIAgent read FAgent write FAgent;
    property Executor: TComponent read FExecutor write FExecutor;
    property LastInput: string read FLastInput;
    property LastOutput: string read FLastOutput;
    property LastError: string read FLastError;
    property OnExecute: TAIAgentNodeExecuteEvent read FOnExecute write FOnExecute;
  end;

  TAIAgentEdge = class(TPersistent)
  private
    FFromID: string;
    FToID: string;
    FCondition: TAIAgentEdgeCondition;
    FLabelText: string;
  published
    property FromID: string read FFromID write FFromID;
    property ToID: string read FToID write FToID;
    property Condition: TAIAgentEdgeCondition read FCondition write FCondition default aecAlways;
    property LabelText: string read FLabelText write FLabelText;
  end;

  TAIAgentCheckpoint = class
  public
    class function Version: Integer; static;
  end;

  TAIAgentGraph = class(TAIBaseComponent)
  private
    FNodes: TObjectList;
    FEdges: TObjectList;
    FAgents: TStringList;
    FMemory: TStringList;
    FStartNodeID: string;
    FCurrentNodeID: string;
    FPreviousResult: string;
    FInput: string;
    FState: TAIAgentGraphState;
    FMode: TAIAgentExecutionMode;
    FMaxSteps: Integer;
    FStepCount: Integer;
    function GetNodeCount: Integer;
    function GetEdgeCount: Integer;
    function GetNode(AIndex: Integer): TAIAgentNode;
    function GetEdge(AIndex: Integer): TAIAgentEdge;
    function EdgeMatches(AEdge: TAIAgentEdge; ASuccess: Boolean;
      AApproval: Integer): Boolean;
    function SelectNext(const AFromID: string; ASuccess: Boolean;
      AApproval: Integer): string;
    function ExecuteCurrent: Boolean;
    function ContinueExecution: Boolean;
    procedure ResetRunState;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function AddNode(const AID, AName: string;
      AKind: TAIAgentNodeKind): TAIAgentNode;
    function AddEdge(const AFromID, AToID: string;
      ACondition: TAIAgentEdgeCondition; const ALabel: string = ''): TAIAgentEdge;
    function FindNode(const AID: string): TAIAgentNode;
    procedure RegisterAgent(const AID: string; AAgent: TAIAgent);
    function FindAgent(const AID: string): TAIAgent;
    function Run(const AInput: string): Boolean;
    function SaveCheckpoint(const AFileName: string): Boolean;
    function LoadCheckpoint(const AFileName: string): Boolean;
    function Resume: Boolean;
    function AcceptApproval: Boolean;
    function RejectApproval: Boolean;
    property NodeCount: Integer read GetNodeCount;
    property EdgeCount: Integer read GetEdgeCount;
    property Nodes[AIndex: Integer]: TAIAgentNode read GetNode;
    property Edges[AIndex: Integer]: TAIAgentEdge read GetEdge;
    property CurrentNodeID: string read FCurrentNodeID;
    property PreviousResult: string read FPreviousResult;
    property State: TAIAgentGraphState read FState;
    property Memory: TStringList read FMemory;
  published
    property StartNodeID: string read FStartNodeID write FStartNodeID;
    property ExecutionMode: TAIAgentExecutionMode read FMode write FMode default aemReal;
    property MaxSteps: Integer read FMaxSteps write FMaxSteps default 100;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIAgentGraph]);
end;

class function TAIAgentCheckpoint.Version: Integer;
begin
  Result := 1;
end;

constructor TAIAgentGraph.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FNodes := TObjectList.Create(True);
  FEdges := TObjectList.Create(True);
  FAgents := TStringList.Create;
  FAgents.CaseSensitive := False;
  FAgents.Sorted := True;
  FAgents.Duplicates := dupIgnore;
  FMemory := TStringList.Create;
  FState := agsIdle;
  FMode := aemReal;
  FMaxSteps := 100;
end;

destructor TAIAgentGraph.Destroy;
begin
  FMemory.Free;
  FAgents.Free;
  FEdges.Free;
  FNodes.Free;
  inherited Destroy;
end;

procedure TAIAgentGraph.Clear;
begin
  FNodes.Clear;
  FEdges.Clear;
  FMemory.Clear;
  FStartNodeID := '';
  FCurrentNodeID := '';
  FPreviousResult := '';
  FInput := '';
  FState := agsIdle;
  FStepCount := 0;
  ClearError;
end;

function TAIAgentGraph.GetNodeCount: Integer;
begin Result := FNodes.Count; end;

function TAIAgentGraph.GetEdgeCount: Integer;
begin Result := FEdges.Count; end;

function TAIAgentGraph.GetNode(AIndex: Integer): TAIAgentNode;
begin Result := TAIAgentNode(FNodes[AIndex]); end;

function TAIAgentGraph.GetEdge(AIndex: Integer): TAIAgentEdge;
begin Result := TAIAgentEdge(FEdges[AIndex]); end;

function TAIAgentGraph.FindNode(const AID: string): TAIAgentNode;
var I: Integer;
begin
  for I := 0 to FNodes.Count - 1 do
    if SameText(GetNode(I).ID, AID) then Exit(GetNode(I));
  Result := nil;
end;

function TAIAgentGraph.AddNode(const AID, AName: string;
  AKind: TAIAgentNodeKind): TAIAgentNode;
begin
  ClearError;
  if Trim(AID) = '' then begin SetError('Node ID vazio.'); Exit(nil); end;
  if FindNode(AID) <> nil then begin SetError('Node duplicado: ' + AID); Exit(nil); end;
  Result := TAIAgentNode.Create;
  Result.ID := AID;
  Result.Name := AName;
  Result.Kind := AKind;
  Result.Status := ansPending;
  FNodes.Add(Result);
  if FStartNodeID = '' then FStartNodeID := AID;
end;

function TAIAgentGraph.AddEdge(const AFromID, AToID: string;
  ACondition: TAIAgentEdgeCondition; const ALabel: string): TAIAgentEdge;
begin
  ClearError;
  if (FindNode(AFromID) = nil) or (FindNode(AToID) = nil) then
  begin SetError('Edge referencia node inexistente.'); Exit(nil); end;
  Result := TAIAgentEdge.Create;
  Result.FromID := AFromID;
  Result.ToID := AToID;
  Result.Condition := ACondition;
  Result.LabelText := ALabel;
  FEdges.Add(Result);
end;

procedure TAIAgentGraph.RegisterAgent(const AID: string; AAgent: TAIAgent);
var Index: Integer;
begin
  if (Trim(AID) = '') or (AAgent = nil) then Exit;
  if FAgents.Find(AID, Index) then FAgents.Objects[Index] := AAgent
  else FAgents.AddObject(AID, AAgent);
  AAgent.FreeNotification(Self);
end;

function TAIAgentGraph.FindAgent(const AID: string): TAIAgent;
var Index: Integer;
begin
  if FAgents.Find(AID, Index) then Result := TAIAgent(FAgents.Objects[Index])
  else Result := nil;
end;

procedure TAIAgentGraph.Notification(AComponent: TComponent; Operation: TOperation);
var I: Integer;
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then Exit;
  for I := FAgents.Count - 1 downto 0 do
    if FAgents.Objects[I] = AComponent then FAgents.Delete(I);
  for I := 0 to FNodes.Count - 1 do
  begin
    if GetNode(I).Agent = AComponent then GetNode(I).Agent := nil;
    if GetNode(I).Executor = AComponent then GetNode(I).Executor := nil;
  end;
end;

procedure TAIAgentGraph.ResetRunState;
var I: Integer;
begin
  for I := 0 to FNodes.Count - 1 do
  begin
    GetNode(I).FStatus := ansPending;
    GetNode(I).FLastInput := '';
    GetNode(I).FLastOutput := '';
    GetNode(I).FLastError := '';
  end;
  FMemory.Clear;
  FPreviousResult := '';
  FStepCount := 0;
end;

function TAIAgentGraph.EdgeMatches(AEdge: TAIAgentEdge; ASuccess: Boolean;
  AApproval: Integer): Boolean;
begin
  case AEdge.Condition of
    aecAlways: Result := True;
    aecOnSuccess: Result := ASuccess;
    aecOnFailure: Result := not ASuccess;
    aecOnApproved: Result := AApproval = 1;
    aecOnRejected: Result := AApproval = 0;
  else Result := False;
  end;
end;

function TAIAgentGraph.SelectNext(const AFromID: string; ASuccess: Boolean;
  AApproval: Integer): string;
var I: Integer; Edge: TAIAgentEdge;
begin
  Result := '';
  for I := 0 to FEdges.Count - 1 do
  begin
    Edge := GetEdge(I);
    if SameText(Edge.FromID, AFromID) and EdgeMatches(Edge, ASuccess, AApproval) then
      Exit(Edge.ToID);
  end;
end;

function TAIAgentGraph.ExecuteCurrent: Boolean;
var
  Node: TAIAgentNode;
  TargetAgent: TAIAgent;
  Output: string;
  Success: Boolean;
begin
  Result := False;
  Node := FindNode(FCurrentNodeID);
  if Node = nil then begin SetError('Node atual inexistente: ' + FCurrentNodeID); FState := agsFailed; Exit; end;
  Inc(FStepCount);
  if FStepCount > FMaxSteps then begin SetError('MaxSteps excedido; possivel ciclo.'); FState := agsFailed; Exit; end;
  Node.FLastInput := FInput;
  Node.FStatus := ansRunning;

  if Node.Kind = agnApproval then
  begin
    Node.FStatus := ansNeedsApproval;
    Node.FLastOutput := 'Aguardando aprovacao humana.';
    FPreviousResult := Node.FLastOutput;
    FMemory.Add(Node.ID + '=NEEDS_APPROVAL');
    FState := agsNeedsApproval;
    Exit(False);
  end;

  if Node.Kind = agnEnd then
  begin
    Node.FStatus := ansCompleted;
    Node.FLastOutput := FPreviousResult;
    FMemory.Add(Node.ID + '=END');
    FCurrentNodeID := '';
    FState := agsCompleted;
    Exit(True);
  end;

  if FMode <> aemReal then
  begin
    Node.FStatus := ansSimulated;
    if FMode = aemSimulation then Output := 'SIMULATION: node "' + Node.ID + '" nao executou efeito real.'
    else Output := 'DRY-RUN: node "' + Node.ID + '" validado sem executar efeito real.';
    Success := True;
  end
  else
  begin
    Output := '';
    Success := False;
    try
      if Assigned(Node.OnExecute) then
        Node.OnExecute(Self, Node, FInput, FMode, Output, Success)
      else
      begin
        TargetAgent := Node.Agent;
        if (TargetAgent = nil) and (Node.AgentID <> '') then TargetAgent := FindAgent(Node.AgentID);
        if Assigned(TargetAgent) then
        begin
          Success := TargetAgent.Execute(FInput);
          if Success then Output := TargetAgent.LastResult else Output := TargetAgent.LastError;
        end
        else
          Output := 'Node sem handler/agent: ' + Node.ID;
      end;
    except
      on E: Exception do begin Output := E.Message; Success := False; end;
    end;
    if Success then Node.FStatus := ansCompleted else Node.FStatus := ansFailed;
  end;

  Node.FLastOutput := Output;
  if not Success then Node.FLastError := Output;
  FPreviousResult := Output;
  FMemory.Add(Node.ID + '=' + GetEnumName(TypeInfo(TAIAgentNodeStatus), Ord(Node.Status)) + ':' + Output);
  FCurrentNodeID := SelectNext(Node.ID, Success, -1);
  if FCurrentNodeID = '' then
  begin
    if Success then FState := agsCompleted else begin FState := agsFailed; SetError(Output); end;
  end;
  Result := Success;
end;

function TAIAgentGraph.ContinueExecution: Boolean;
var StepSuccess: Boolean;
begin
  while (FCurrentNodeID <> '') and (FState = agsRunning) do
  begin
    StepSuccess := ExecuteCurrent;
    if FState in [agsNeedsApproval, agsFailed] then Break;
    if not StepSuccess and (FCurrentNodeID = '') then Break;
  end;
  Result := FState = agsCompleted;
  FLastSuccess := Result;
  if Result then FLastResult := FPreviousResult;
end;

function TAIAgentGraph.Run(const AInput: string): Boolean;
begin
  ClearError;
  ResetRunState;
  FInput := AInput;
  FCurrentNodeID := FStartNodeID;
  if FindNode(FCurrentNodeID) = nil then begin SetError('StartNodeID invalido.'); FState := agsFailed; Exit(False); end;
  FState := agsRunning;
  Result := ContinueExecution;
end;

function TAIAgentGraph.AcceptApproval: Boolean;
var Node: TAIAgentNode;
begin
  if FState <> agsNeedsApproval then begin SetError('Grafo nao aguarda aprovacao.'); Exit(False); end;
  Node := FindNode(FCurrentNodeID);
  if (Node = nil) or (Node.Status <> ansNeedsApproval) then begin SetError('Node de aprovacao invalido.'); Exit(False); end;
  Node.FStatus := ansCompleted;
  Node.FLastOutput := 'Aprovado pelo usuario.';
  FPreviousResult := Node.FLastOutput;
  FMemory.Add(Node.ID + '=APPROVED');
  FCurrentNodeID := SelectNext(Node.ID, True, 1);
  FState := agsRunning;
  if FCurrentNodeID = '' then FState := agsCompleted;
  Result := ContinueExecution;
end;

function TAIAgentGraph.RejectApproval: Boolean;
var Node: TAIAgentNode;
begin
  if FState <> agsNeedsApproval then begin SetError('Grafo nao aguarda aprovacao.'); Exit(False); end;
  Node := FindNode(FCurrentNodeID);
  if (Node = nil) or (Node.Status <> ansNeedsApproval) then begin SetError('Node de aprovacao invalido.'); Exit(False); end;
  Node.FStatus := ansRejected;
  Node.FLastOutput := 'Rejeitado pelo usuario.';
  FPreviousResult := Node.FLastOutput;
  FMemory.Add(Node.ID + '=REJECTED');
  FCurrentNodeID := SelectNext(Node.ID, False, 0);
  FState := agsRunning;
  if FCurrentNodeID = '' then FState := agsCompleted;
  Result := ContinueExecution;
end;

function TAIAgentGraph.SaveCheckpoint(const AFileName: string): Boolean;
var Root: TJSONObject; Mem: TJSONArray; List: TStringList; I: Integer;
begin
  Result := False;
  Root := TJSONObject.Create;
  List := TStringList.Create;
  try
    Root.Add('version', TAIAgentCheckpoint.Version);
    Root.Add('currentNodeID', FCurrentNodeID);
    Root.Add('state', Ord(FState));
    Root.Add('mode', Ord(FMode));
    Root.Add('input', FInput);
    Root.Add('previousResult', FPreviousResult);
    Root.Add('stepCount', FStepCount);
    Mem := TJSONArray.Create;
    for I := 0 to FMemory.Count - 1 do Mem.Add(FMemory[I]);
    Root.Add('memory', Mem);
    List.Text := Root.FormatJSON;
    List.SaveToFile(AFileName);
    Result := True;
  except on E: Exception do SetError(E.Message); end;
  List.Free;
  Root.Free;
end;

function TAIAgentGraph.LoadCheckpoint(const AFileName: string): Boolean;
var List: TStringList; Data, Mem: TJSONData; Root: TJSONObject; I, V: Integer;
begin
  Result := False;
  ClearError;
  if not FileExists(AFileName) then begin SetError('Checkpoint nao encontrado.'); Exit; end;
  List := TStringList.Create;
  Data := nil;
  try
    try
      List.LoadFromFile(AFileName);
      Data := GetJSON(List.Text);
      if not (Data is TJSONObject) then begin SetError('Checkpoint nao e objeto JSON.'); Exit; end;
      Root := TJSONObject(Data);
      V := Root.Get('version', 0);
      if V <> TAIAgentCheckpoint.Version then begin SetError('Versao de checkpoint nao suportada.'); Exit; end;
      FCurrentNodeID := Root.Get('currentNodeID', '');
      if (FCurrentNodeID <> '') and (FindNode(FCurrentNodeID) = nil) then begin SetError('Node do checkpoint nao existe no grafo.'); Exit; end;
      FState := TAIAgentGraphState(Root.Get('state', Ord(agsIdle)));
      FMode := TAIAgentExecutionMode(Root.Get('mode', Ord(aemReal)));
      FInput := Root.Get('input', '');
      FPreviousResult := Root.Get('previousResult', '');
      FStepCount := Root.Get('stepCount', 0);
      FMemory.Clear;
      Mem := Root.Find('memory');
      if Mem is TJSONArray then for I := 0 to TJSONArray(Mem).Count - 1 do FMemory.Add(TJSONArray(Mem).Strings[I]);
      if FState = agsNeedsApproval then FindNode(FCurrentNodeID).FStatus := ansNeedsApproval;
      Result := True;
    except
      on E: Exception do SetError(E.Message);
    end;
  finally
    Data.Free;
    List.Free;
  end;
end;

function TAIAgentGraph.Resume: Boolean;
begin
  ClearError;
  if FState = agsNeedsApproval then begin SetError('Checkpoint aguarda AcceptApproval/RejectApproval.'); Exit(False); end;
  if FState in [agsCompleted, agsFailed] then Exit(FState = agsCompleted);
  if FCurrentNodeID = '' then begin SetError('Checkpoint sem node atual.'); Exit(False); end;
  FState := agsRunning;
  Result := ContinueExecution;
end;

end.
