unit aimcp_client;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, aimcp_types, aimcp_transport;

type
  TAIMCPClient = class(TAIBaseComponent)
  private
    FTransport: IAIMCPTransport;
    FProtocolVersion: string;
    FServerName: string;
    FRequestCounter: QWord;
    FConnected: Boolean;
    FLastMCPError: TAIMCPError;
    procedure SetTransport(const AValue: IAIMCPTransport);
    function CallMethod(const AMethod, AParamsJSON: string;
      out AResultJSON: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Connect: Boolean;
    procedure Disconnect;
    function Initialize: Boolean;
    function ListTools(AList: TAIMCPToolList): Boolean;
    function CallTool(const AName, AArgumentsJSON: string;
      out AOutput, AStructuredJSON: string; out AIsError: Boolean): Boolean;
    function ListResources(AList: TAIMCPResourceList): Boolean;
    function ReadResource(const AURI: string; out AText, AMimeType: string): Boolean;
    property Transport: IAIMCPTransport read FTransport write SetTransport;
    property Connected: Boolean read FConnected;
    property ServerName: string read FServerName;
    property LastMCPError: TAIMCPError read FLastMCPError;
  published
    property ProtocolVersion: string read FProtocolVersion write FProtocolVersion;
  end;

implementation

constructor TAIMCPClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FProtocolVersion := AIMCP_PROTOCOL_VERSION;
  FLastMCPError := TAIMCPError.Create;
end;

destructor TAIMCPClient.Destroy;
begin
  Disconnect;
  FTransport := nil;
  FLastMCPError.Free;
  inherited Destroy;
end;

procedure TAIMCPClient.SetTransport(const AValue: IAIMCPTransport);
begin
  Disconnect;
  FTransport := AValue;
end;

function TAIMCPClient.Connect: Boolean;
var Err: string;
begin
  ClearError;
  if FTransport = nil then begin SetError('Transporte MCP nao associado.'); Exit(False); end;
  Result := FTransport.Connect(Err);
  FConnected := Result;
  if not Result then SetError(Err);
end;

procedure TAIMCPClient.Disconnect;
begin
  if FTransport <> nil then FTransport.Disconnect;
  FConnected := False;
  FServerName := '';
end;

function TAIMCPClient.CallMethod(const AMethod, AParamsJSON: string;
  out AResultJSON: string): Boolean;
var
  Request: TAIMCPRequest;
  Response: TAIMCPResponse;
  Raw, Err: string;
begin
  Result := False;
  AResultJSON := '';
  FLastMCPError.Clear;
  if not FConnected then begin SetError('Cliente MCP desconectado.'); Exit; end;
  Inc(FRequestCounter);
  Request := TAIMCPRequest.Create;
  Response := TAIMCPResponse.Create;
  try
    Request.ID := IntToStr(FRequestCounter);
    Request.Method := AMethod;
    Request.ParamsJSON := AParamsJSON;
    if not FTransport.SendRequest(Request.ToJSON, Raw, Err) then
    begin SetError(Err); Exit; end;
    if not Response.Parse(Raw, Err) then begin SetError('Response MCP invalido: ' + Err); Exit; end;
    if Response.Error.Code <> 0 then
    begin
      FLastMCPError.Code := Response.Error.Code;
      FLastMCPError.MessageText := Response.Error.MessageText;
      FLastMCPError.DataJSON := Response.Error.DataJSON;
      SetError(Format('MCP %d: %s', [Response.Error.Code, Response.Error.MessageText]));
      Exit;
    end;
    AResultJSON := Response.ResultJSON;
    Result := True;
    FLastSuccess := True;
  finally
    Response.Free;
    Request.Free;
  end;
end;

function TAIMCPClient.Initialize: Boolean;
var
  Params, Data: TJSONData;
  Obj, Info: TJSONObject;
  Raw, Negotiated: string;
begin
  Params := TJSONObject.Create;
  Obj := TJSONObject(Params);
  Obj.Add('protocolVersion', FProtocolVersion);
  Obj.Add('capabilities', TJSONObject.Create);
  Info := TJSONObject.Create;
  Info.Add('name', 'lazarus-ai-suite');
  Info.Add('version', '1.0');
  Obj.Add('clientInfo', Info);
  try Result := CallMethod('initialize', Obj.AsJSON, Raw);
  finally Params.Free; end;
  if not Result then Exit;
  Data := GetJSON(Raw);
  try
    Negotiated := TJSONObject(Data).Get('protocolVersion', '');
    if Negotiated <> FProtocolVersion then
    begin SetError('Versao MCP nao suportada pelo servidor: ' + Negotiated); Disconnect; Exit(False); end;
    Info := TJSONObject(Data).Objects['serverInfo'];
    if Assigned(Info) then FServerName := Info.Get('name', '');
  finally Data.Free; end;
end;

function TAIMCPClient.ListTools(AList: TAIMCPToolList): Boolean;
var
  Data, ListData, ItemData, Schema, Annotations: TJSONData;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Tool: TAIMCPTool;
  Raw: string;
  I: Integer;
begin
  if AList = nil then begin SetError('Lista de tools nula.'); Exit(False); end;
  AList.Clear;
  Result := CallMethod('tools/list', '{}', Raw);
  if not Result then Exit;
  Data := GetJSON(Raw);
  try
    ListData := Data.FindPath('tools');
    if not (ListData is TJSONArray) then begin SetError('tools/list sem array tools.'); Exit(False); end;
    Arr := TJSONArray(ListData);
    for I := 0 to Arr.Count - 1 do
    begin
      ItemData := Arr.Items[I];
      if not (ItemData is TJSONObject) then Continue;
      Obj := TJSONObject(ItemData);
      Tool := AList.AddTool;
      Tool.Name := Obj.Get('name', '');
      Tool.Title := Obj.Get('title', '');
      Tool.Description := Obj.Get('description', '');
      Schema := Obj.Find('inputSchema');
      if Schema = nil then Tool.InputSchema := '{}' else Tool.InputSchema := Schema.AsJSON;
      Annotations := Obj.Find('annotations');
      if Annotations is TJSONObject then
      begin
        Tool.ReadOnlyHint := TJSONObject(Annotations).Get('readOnlyHint', False);
        Tool.DestructiveHint := TJSONObject(Annotations).Get('destructiveHint', False);
      end;
    end;
    Result := True;
  finally Data.Free; end;
end;

function TAIMCPClient.CallTool(const AName, AArgumentsJSON: string;
  out AOutput, AStructuredJSON: string; out AIsError: Boolean): Boolean;
var
  Params, Data, ContentData, Item, Structured: TJSONData;
  Obj: TJSONObject;
  Arr: TJSONArray;
  Raw: string;
  I: Integer;
begin
  AOutput := '';
  AStructuredJSON := '';
  AIsError := False;
  Params := TJSONObject.Create;
  Obj := TJSONObject(Params);
  Obj.Add('name', AName);
  if Trim(AArgumentsJSON) = '' then Obj.Add('arguments', TJSONObject.Create)
  else Obj.Add('arguments', GetJSON(AArgumentsJSON));
  try Result := CallMethod('tools/call', Obj.AsJSON, Raw);
  finally Params.Free; end;
  if not Result then Exit;
  Data := GetJSON(Raw);
  try
    AIsError := TJSONObject(Data).Get('isError', False);
    ContentData := Data.FindPath('content');
    if ContentData is TJSONArray then
    begin
      Arr := TJSONArray(ContentData);
      for I := 0 to Arr.Count - 1 do
      begin
        Item := Arr.Items[I];
        if (Item is TJSONObject) and (TJSONObject(Item).Get('type', '') = 'text') then
        begin
          if AOutput <> '' then AOutput := AOutput + LineEnding;
          AOutput := AOutput + TJSONObject(Item).Get('text', '');
        end;
      end;
    end;
    Structured := Data.FindPath('structuredContent');
    if Structured <> nil then AStructuredJSON := Structured.AsJSON;
    Result := not AIsError;
    if AIsError then SetError(AOutput);
  finally Data.Free; end;
end;

function TAIMCPClient.ListResources(AList: TAIMCPResourceList): Boolean;
var
  Data, ListData, Item: TJSONData;
  Arr: TJSONArray;
  Obj: TJSONObject;
  R: TAIMCPResource;
  Raw: string;
  I: Integer;
begin
  if AList = nil then begin SetError('Lista de resources nula.'); Exit(False); end;
  AList.Clear;
  Result := CallMethod('resources/list', '{}', Raw);
  if not Result then Exit;
  Data := GetJSON(Raw);
  try
    ListData := Data.FindPath('resources');
    if not (ListData is TJSONArray) then begin SetError('resources/list sem array.'); Exit(False); end;
    Arr := TJSONArray(ListData);
    for I := 0 to Arr.Count - 1 do
    begin
      Item := Arr.Items[I]; if not (Item is TJSONObject) then Continue;
      Obj := TJSONObject(Item); R := AList.AddResource;
      R.URI := Obj.Get('uri', ''); R.Name := Obj.Get('name', '');
      R.Title := Obj.Get('title', ''); R.Description := Obj.Get('description', '');
      R.MimeType := Obj.Get('mimeType', ''); R.Size := Obj.Get('size', Int64(0));
    end;
    Result := True;
  finally Data.Free; end;
end;

function TAIMCPClient.ReadResource(const AURI: string; out AText,
  AMimeType: string): Boolean;
var
  Params, Data, Contents, Item: TJSONData;
  Obj: TJSONObject;
  Raw: string;
begin
  AText := ''; AMimeType := '';
  Params := TJSONObject.Create;
  TJSONObject(Params).Add('uri', AURI);
  try Result := CallMethod('resources/read', Params.AsJSON, Raw);
  finally Params.Free; end;
  if not Result then Exit;
  Data := GetJSON(Raw);
  try
    Contents := Data.FindPath('contents');
    if not (Contents is TJSONArray) or (TJSONArray(Contents).Count = 0) then
    begin SetError('resources/read sem contents.'); Exit(False); end;
    Item := TJSONArray(Contents).Items[0];
    if not (Item is TJSONObject) then begin SetError('Conteudo MCP invalido.'); Exit(False); end;
    Obj := TJSONObject(Item); AText := Obj.Get('text', ''); AMimeType := Obj.Get('mimeType', '');
    Result := True;
  finally Data.Free; end;
end;

end.
