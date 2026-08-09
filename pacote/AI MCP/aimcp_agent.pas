unit aimcp_agent;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aitools, aimcp_types, aimcp_client;

type
  TAIMCPToolRegistryBridge = class(TAIBaseComponent)
  private
    FClient: TAIMCPClient;
    FRegistry: TAIToolRegistry;
    FRegisteredNames: TStringList;
    procedure SetClient(AValue: TAIMCPClient);
    procedure SetRegistry(AValue: TAIToolRegistry);
    procedure ExecuteRemote(Sender: TObject; ACall: TAIToolCall;
      AResult: TAIToolResult);
    procedure DetachTools;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Refresh: Boolean;
  published
    property Client: TAIMCPClient read FClient write SetClient;
    property Registry: TAIToolRegistry read FRegistry write SetRegistry;
  end;

implementation

constructor TAIMCPToolRegistryBridge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FRegisteredNames := TStringList.Create;
  FRegisteredNames.CaseSensitive := False;
end;

destructor TAIMCPToolRegistryBridge.Destroy;
begin
  DetachTools;
  FRegisteredNames.Free;
  inherited Destroy;
end;

procedure TAIMCPToolRegistryBridge.SetClient(AValue: TAIMCPClient);
begin
  if FClient = AValue then Exit;
  if FClient <> nil then FClient.RemoveFreeNotification(Self);
  FClient := AValue;
  if FClient <> nil then FClient.FreeNotification(Self);
end;

procedure TAIMCPToolRegistryBridge.SetRegistry(AValue: TAIToolRegistry);
begin
  if FRegistry = AValue then Exit;
  DetachTools;
  if FRegistry <> nil then FRegistry.RemoveFreeNotification(Self);
  FRegistry := AValue;
  if FRegistry <> nil then FRegistry.FreeNotification(Self);
end;

procedure TAIMCPToolRegistryBridge.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FClient then FClient := nil;
    if AComponent = FRegistry then begin FRegistry := nil; FRegisteredNames.Clear; end;
  end;
end;

procedure TAIMCPToolRegistryBridge.DetachTools;
var I: Integer;
begin
  if FRegistry <> nil then
    for I := 0 to FRegisteredNames.Count - 1 do FRegistry.RemoveTool(FRegisteredNames[I]);
  FRegisteredNames.Clear;
end;

procedure TAIMCPToolRegistryBridge.ExecuteRemote(Sender: TObject;
  ACall: TAIToolCall; AResult: TAIToolResult);
var Output, Structured: string; IsError: Boolean;
begin
  if FClient = nil then begin AResult.ErrorText := 'Cliente MCP indisponivel.'; Exit; end;
  AResult.Success := FClient.CallTool(ACall.ToolName, ACall.ArgumentsJSON,
    Output, Structured, IsError);
  AResult.Output := Output;
  if Structured <> '' then AResult.SetDataJSON(Structured);
  if not AResult.Success then AResult.ErrorText := FClient.LastError;
end;

function TAIMCPToolRegistryBridge.Refresh: Boolean;
var
  RemoteTools: TAIMCPToolList;
  I: Integer;
  Remote: TAIMCPTool;
  Local: TAITool;
  Risk: TAIToolRisk;
begin
  Result := False;
  ClearError;
  if (FClient = nil) or (FRegistry = nil) then
  begin SetError('Client/Registry nao associados ao bridge MCP.'); Exit; end;
  RemoteTools := TAIMCPToolList.Create;
  try
    if not FClient.ListTools(RemoteTools) then begin SetError(FClient.LastError); Exit; end;
    DetachTools;
    for I := 0 to RemoteTools.Count - 1 do
    begin
      Remote := RemoteTools.ToolAt(I);
      if Remote.DestructiveHint then Risk := toolRiskDelete
      else if Remote.ReadOnlyHint then Risk := toolRiskRead
      else Risk := toolRiskExecute;
      Local := FRegistry.RegisterTool(Remote.Name, Remote.Description,
        Remote.InputSchema, Risk, @ExecuteRemote);
      if Local = nil then begin SetError(FRegistry.LastError); DetachTools; Exit; end;
      FRegisteredNames.Add(Local.Name);
    end;
    Result := True;
    FLastSuccess := True;
  finally RemoteTools.Free; end;
end;

end.
