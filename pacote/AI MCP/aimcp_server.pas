unit aimcp_server;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, aitools, aimcp_types;

type
  TAIMCPServer = class(TAIBaseComponent)
  private
    FToolRegistry: TAIToolRegistry;
    FResources: TAIMCPResourceList;
    FServerName: string;
    FServerVersion: string;
    FProtocolVersion: string;
    procedure SetToolRegistry(AValue: TAIToolRegistry);
    function SuccessResponse(const AID, AResultJSON: string): string;
    function ErrorResponse(const AID: string; ACode: Integer;
      const AMessage, ADataJSON: string): string;
    function ToolCallResult(ACall: TAIToolCall): string;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddTextResource(const AURI, AName, ADescription,
      AMimeType, AText: string): TAIMCPResource;
    function HandleRequest(const ARequestJSON: string): string;
    procedure HandleTransportRequest(Sender: TObject;
      const ARequestJSON: string; out AResponseJSON, AError: string);
    property Resources: TAIMCPResourceList read FResources;
  published
    property ToolRegistry: TAIToolRegistry read FToolRegistry write SetToolRegistry;
    property ServerName: string read FServerName write FServerName;
    property ServerVersion: string read FServerVersion write FServerVersion;
    property ProtocolVersion: string read FProtocolVersion write FProtocolVersion;
  end;

implementation

constructor TAIMCPServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FResources := TAIMCPResourceList.Create;
  FServerName := 'lazarus-ai-mcp';
  FServerVersion := '1.0';
  FProtocolVersion := AIMCP_PROTOCOL_VERSION;
end;

destructor TAIMCPServer.Destroy;
begin
  FResources.Free;
  inherited Destroy;
end;

procedure TAIMCPServer.SetToolRegistry(AValue: TAIToolRegistry);
begin
  if FToolRegistry = AValue then Exit;
  if FToolRegistry <> nil then FToolRegistry.RemoveFreeNotification(Self);
  FToolRegistry := AValue;
  if FToolRegistry <> nil then FToolRegistry.FreeNotification(Self);
end;

procedure TAIMCPServer.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FToolRegistry) then FToolRegistry := nil;
end;

function TAIMCPServer.AddTextResource(const AURI, AName, ADescription,
  AMimeType, AText: string): TAIMCPResource;
begin
  Result := FResources.FindURI(AURI);
  if Result = nil then Result := FResources.AddResource;
  Result.URI := AURI;
  Result.Name := AName;
  Result.Description := ADescription;
  Result.MimeType := AMimeType;
  Result.Text := AText;
  Result.Size := Length(AText);
end;

function TAIMCPServer.SuccessResponse(const AID, AResultJSON: string): string;
var Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('jsonrpc', '2.0'); Obj.Add('id', AID);
    Obj.Add('result', GetJSON(AResultJSON)); Result := Obj.AsJSON;
  finally Obj.Free; end;
end;

function TAIMCPServer.ErrorResponse(const AID: string; ACode: Integer;
  const AMessage, ADataJSON: string): string;
var Obj, Err: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('jsonrpc', '2.0'); Obj.Add('id', AID);
    Err := TJSONObject.Create; Err.Add('code', ACode); Err.Add('message', AMessage);
    if Trim(ADataJSON) <> '' then Err.Add('data', GetJSON(ADataJSON));
    Obj.Add('error', Err); Result := Obj.AsJSON;
  finally Obj.Free; end;
end;

function TAIMCPServer.ToolCallResult(ACall: TAIToolCall): string;
var
  R: TAIToolResult;
  Root, Content, TextItem, Structured: TJSONData;
  Obj: TJSONObject;
begin
  R := TAIToolResult.Create;
  Root := TJSONObject.Create;
  try
    Obj := TJSONObject(Root);
    if FToolRegistry = nil then
    begin R.Success := False; R.ErrorText := 'ToolRegistry nao associado ao servidor.'; end
    else FToolRegistry.Execute(ACall, R);
    Content := TJSONArray.Create;
    TextItem := TJSONObject.Create;
    TJSONObject(TextItem).Add('type', 'text');
    if R.Success then TJSONObject(TextItem).Add('text', R.Output)
    else TJSONObject(TextItem).Add('text', R.ErrorText);
    TJSONArray(Content).Add(TextItem);
    Obj.Add('content', Content);
    Obj.Add('isError', not R.Success);
    if R.Data <> nil then Structured := GetJSON(R.Data.AsJSON)
    else
    begin Structured := TJSONObject.Create; TJSONObject(Structured).Add('output', R.Output); end;
    Obj.Add('structuredContent', Structured);
    Result := Root.AsJSON;
  finally
    Root.Free;
    R.Free;
  end;
end;

function TAIMCPServer.HandleRequest(const ARequestJSON: string): string;
var
  Request: TAIMCPRequest;
  ParamsData, ItemData: TJSONData;
  Params, Root, Info, Caps, ToolObj, ResourceObj, ContentObj: TJSONObject;
  ToolsArray, ResourcesArray, ContentsArray: TJSONArray;
  ToolCall: TAIToolCall;
  Resource: TAIMCPResource;
  I: Integer;
  Err, ToolName, URI: string;
begin
  Request := TAIMCPRequest.Create;
  ParamsData := nil;
  try
    if not Request.Parse(ARequestJSON, Err) then
      Exit(ErrorResponse('', -32600, 'Invalid Request: ' + Err, ''));
    try ParamsData := GetJSON(Request.ParamsJSON);
    except Exit(ErrorResponse(Request.ID, -32602, 'Invalid params', '')); end;
    if not (ParamsData is TJSONObject) then
      Exit(ErrorResponse(Request.ID, -32602, 'Params must be an object', ''));
    Params := TJSONObject(ParamsData);

    if Request.Method = 'initialize' then
    begin
      Root := TJSONObject.Create;
      try
        Root.Add('protocolVersion', FProtocolVersion);
        Caps := TJSONObject.Create;
        Caps.Add('tools', TJSONObject.Create(['listChanged', False]));
        Caps.Add('resources', TJSONObject.Create(['subscribe', False, 'listChanged', False]));
        Root.Add('capabilities', Caps);
        Info := TJSONObject.Create; Info.Add('name', FServerName); Info.Add('version', FServerVersion);
        Root.Add('serverInfo', Info);
        Exit(SuccessResponse(Request.ID, Root.AsJSON));
      finally Root.Free; end;
    end;

    if Request.Method = 'tools/list' then
    begin
      if FToolRegistry = nil then Exit(ErrorResponse(Request.ID, -32603, 'ToolRegistry unavailable', ''));
      Root := TJSONObject.Create;
      try Root.Add('tools', GetJSON(FToolRegistry.ToolsJSON)); Exit(SuccessResponse(Request.ID, Root.AsJSON));
      finally Root.Free; end;
    end;

    if Request.Method = 'tools/call' then
    begin
      ToolName := Params.Get('name', '');
      if ToolName = '' then Exit(ErrorResponse(Request.ID, -32602, 'Tool name is required', ''));
      ToolCall := TAIToolCall.Create;
      try
        ToolCall.CallID := Request.ID; ToolCall.ToolName := ToolName;
        ItemData := Params.Find('arguments');
        if ItemData = nil then ToolCall.SetArgumentsJSON('{}')
        else ToolCall.SetArgumentsJSON(ItemData.AsJSON);
        Exit(SuccessResponse(Request.ID, ToolCallResult(ToolCall)));
      finally ToolCall.Free; end;
    end;

    if Request.Method = 'resources/list' then
    begin
      ResourcesArray := TJSONArray.Create;
      Root := TJSONObject.Create;
      try
        for I := 0 to FResources.Count - 1 do
        begin
          Resource := FResources.ResourceAt(I); ResourceObj := TJSONObject.Create;
          ResourceObj.Add('uri', Resource.URI); ResourceObj.Add('name', Resource.Name);
          if Resource.Title <> '' then ResourceObj.Add('title', Resource.Title);
          ResourceObj.Add('description', Resource.Description);
          ResourceObj.Add('mimeType', Resource.MimeType); ResourceObj.Add('size', Resource.Size);
          ResourcesArray.Add(ResourceObj);
        end;
        Root.Add('resources', ResourcesArray); ResourcesArray := nil;
        Exit(SuccessResponse(Request.ID, Root.AsJSON));
      finally ResourcesArray.Free; Root.Free; end;
    end;

    if Request.Method = 'resources/read' then
    begin
      URI := Params.Get('uri', ''); Resource := FResources.FindURI(URI);
      if Resource = nil then Exit(ErrorResponse(Request.ID, -32002, 'Resource not found', ''));
      Root := TJSONObject.Create; ContentsArray := TJSONArray.Create;
      try
        ContentObj := TJSONObject.Create; ContentObj.Add('uri', Resource.URI);
        ContentObj.Add('mimeType', Resource.MimeType); ContentObj.Add('text', Resource.Text);
        ContentsArray.Add(ContentObj); Root.Add('contents', ContentsArray); ContentsArray := nil;
        Exit(SuccessResponse(Request.ID, Root.AsJSON));
      finally ContentsArray.Free; Root.Free; end;
    end;

    Result := ErrorResponse(Request.ID, -32601, 'Method not found', '');
  finally
    ParamsData.Free;
    Request.Free;
  end;
end;

procedure TAIMCPServer.HandleTransportRequest(Sender: TObject;
  const ARequestJSON: string; out AResponseJSON, AError: string);
begin
  AError := '';
  try AResponseJSON := HandleRequest(ARequestJSON);
  except on E: Exception do begin AResponseJSON := ''; AError := E.Message; end; end;
end;

end.
