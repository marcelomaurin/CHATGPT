unit aia2a;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, fpjson, jsonparser, fphttpclient,
  opensslsockets, LResources, aibase;

type
  TAIA2ABinding = (a2abJSONRPC, a2abHTTPJSON);

  TAIA2AInterface = class
  public
    URL: string;
    ProtocolBinding: string;
    ProtocolVersion: string;
    Tenant: string;
  end;

  TAIA2AAgentCard = class
  private
    FName: string;
    FDescription: string;
    FVersion: string;
    FInterfaces: TList;
    FStreaming: Boolean;
    FPushNotifications: Boolean;
    FExtendedAgentCard: Boolean;
    function GetInterfaceCount: Integer;
    function GetInterface(AIndex: Integer): TAIA2AInterface;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function LoadJSON(const AJSON: string): Boolean;
    function SelectInterface(ABinding: TAIA2ABinding): TAIA2AInterface;
    property Name: string read FName;
    property Description: string read FDescription;
    property Version: string read FVersion;
    property Streaming: Boolean read FStreaming;
    property PushNotifications: Boolean read FPushNotifications;
    property ExtendedAgentCard: Boolean read FExtendedAgentCard;
    property InterfaceCount: Integer read GetInterfaceCount;
    property Interfaces[AIndex: Integer]: TAIA2AInterface read GetInterface;
  end;

  TAIA2AClient = class(TAIBaseComponent)
  private
    FBaseURL: string;
    FAgentCardURL: string;
    FToken: string;
    FProtocolVersion: string;
    FBinding: TAIA2ABinding;
    FTimeout: Integer;
    FAutoDiscover: Boolean;
    FAgentCard: TAIA2AAgentCard;
    FLastRawResponse: string;
    FLastTaskID: string;
    FLastContextID: string;
    FSelectedURL: string;
    FTenant: string;
    function NormalizeBaseURL(const AURL: string): string;
    function NewID: string;
    function DoRequest(const AMethod, AURL: string; ABody: TStream;
      const AContentType: string; out AResponse: string): Boolean;
    function DoGet(const AURL: string; out AResponse: string): Boolean;
    function BuildMessageParams(const AText, ATaskID: string): TJSONObject;
    function SendJSONRPC(const AMethod: string; AParams: TJSONObject;
      out AResponse: string): Boolean;
    function SendHTTPJSON(const APath: string; ABody: TJSONObject;
      out AResponse: string): Boolean;
    function ExtractTextAndTask(const ARaw: string; out AText: string): Boolean;
    procedure SelectDiscoveredInterface;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Discover: Boolean;
    function SendText(const AText: string; out AAnswer: string): Boolean;
    function ContinueTask(const ATaskID, AText: string;
      out AAnswer: string): Boolean;
    function GetTask(const ATaskID: string; out ATaskJSON: string;
      AHistoryLength: Integer = -1): Boolean;
    function CancelTask(const ATaskID: string; out ATaskJSON: string): Boolean;
    property AgentCard: TAIA2AAgentCard read FAgentCard;
    property LastRawResponse: string read FLastRawResponse;
    property LastTaskID: string read FLastTaskID;
    property LastContextID: string read FLastContextID;
    property SelectedURL: string read FSelectedURL;
  published
    property BaseURL: string read FBaseURL write FBaseURL;
    property AgentCardURL: string read FAgentCardURL write FAgentCardURL;
    property Token: string read FToken write FToken;
    property ProtocolVersion: string read FProtocolVersion write FProtocolVersion;
    property Binding: TAIA2ABinding read FBinding write FBinding default a2abHTTPJSON;
    property Timeout: Integer read FTimeout write FTimeout default 120000;
    property AutoDiscover: Boolean read FAutoDiscover write FAutoDiscover default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI A2A', [TAIA2AClient]);
end;

function JSONString(AData: TJSONData; const APath: string): string;
var
  D: TJSONData;
begin
  Result := '';
  if AData = nil then Exit;
  D := AData.FindPath(APath);
  if D <> nil then Result := D.AsString;
end;

function JSONBool(AData: TJSONData; const APath: string): Boolean;
var
  D: TJSONData;
begin
  Result := False;
  if AData = nil then Exit;
  D := AData.FindPath(APath);
  if D <> nil then Result := D.AsBoolean;
end;

constructor TAIA2AAgentCard.Create;
begin
  inherited Create;
  FInterfaces := TList.Create;
end;

destructor TAIA2AAgentCard.Destroy;
begin
  Clear;
  FInterfaces.Free;
  inherited Destroy;
end;

procedure TAIA2AAgentCard.Clear;
var
  I: Integer;
begin
  for I := FInterfaces.Count - 1 downto 0 do TObject(FInterfaces[I]).Free;
  FInterfaces.Clear;
  FName := '';
  FDescription := '';
  FVersion := '';
  FStreaming := False;
  FPushNotifications := False;
  FExtendedAgentCard := False;
end;

function TAIA2AAgentCard.GetInterfaceCount: Integer;
begin
  Result := FInterfaces.Count;
end;

function TAIA2AAgentCard.GetInterface(AIndex: Integer): TAIA2AInterface;
begin
  Result := TAIA2AInterface(FInterfaces[AIndex]);
end;

function TAIA2AAgentCard.LoadJSON(const AJSON: string): Boolean;
var
  Root, Item: TJSONData;
  Arr: TJSONArray;
  I: Integer;
  Intf: TAIA2AInterface;
begin
  Result := False;
  Clear;
  try
    Root := GetJSON(AJSON);
    try
      FName := JSONString(Root, 'name');
      FDescription := JSONString(Root, 'description');
      FVersion := JSONString(Root, 'version');
      FStreaming := JSONBool(Root, 'capabilities.streaming');
      FPushNotifications := JSONBool(Root, 'capabilities.pushNotifications');
      FExtendedAgentCard := JSONBool(Root, 'capabilities.extendedAgentCard');
      Item := Root.FindPath('supportedInterfaces');
      if (Item <> nil) and (Item.JSONType = jtArray) then
      begin
        Arr := TJSONArray(Item);
        for I := 0 to Arr.Count - 1 do
        begin
          Intf := TAIA2AInterface.Create;
          Intf.URL := JSONString(Arr.Items[I], 'url');
          Intf.ProtocolBinding := JSONString(Arr.Items[I], 'protocolBinding');
          Intf.ProtocolVersion := JSONString(Arr.Items[I], 'protocolVersion');
          Intf.Tenant := JSONString(Arr.Items[I], 'tenant');
          if Intf.URL <> '' then FInterfaces.Add(Intf) else Intf.Free;
        end;
      end;
      Result := FName <> '';
    finally
      Root.Free;
    end;
  except
    Result := False;
  end;
end;

function TAIA2AAgentCard.SelectInterface(ABinding: TAIA2ABinding): TAIA2AInterface;
var
  I: Integer;
  S: string;
begin
  Result := nil;
  for I := 0 to FInterfaces.Count - 1 do
  begin
    S := UpperCase(Trim(Interfaces[I].ProtocolBinding));
    case ABinding of
      a2abJSONRPC:
        if (S = 'JSONRPC') or (S = 'JSON-RPC') then Exit(Interfaces[I]);
      a2abHTTPJSON:
        if (S = 'HTTP+JSON') or (S = 'HTTPJSON') or (S = 'REST') then
          Exit(Interfaces[I]);
    end;
  end;
end;

constructor TAIA2AClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FProtocolVersion := '1.0';
  FBinding := a2abHTTPJSON;
  FTimeout := 120000;
  FAutoDiscover := True;
  FAgentCard := TAIA2AAgentCard.Create;
end;

destructor TAIA2AClient.Destroy;
begin
  FAgentCard.Free;
  inherited Destroy;
end;

function TAIA2AClient.NormalizeBaseURL(const AURL: string): string;
begin
  Result := Trim(AURL);
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function TAIA2AClient.NewID: string;
var
  G: TGUID;
begin
  if CreateGUID(G) = 0 then
    Result := GUIDToString(G)
  else
    Result := IntToHex(Random(MaxInt), 8) + IntToHex(Random(MaxInt), 8);
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
end;

function TAIA2AClient.DoRequest(const AMethod, AURL: string; ABody: TStream;
  const AContentType: string; out AResponse: string): Boolean;
var
  HTTP: TFPHttpClient;
  ResponseStream: TStringStream;
begin
  Result := False;
  AResponse := '';
  HTTP := TFPHttpClient.Create(nil);
  ResponseStream := TStringStream.Create('');
  try
    HTTP.ConnectTimeout := FTimeout;
    HTTP.IOTimeout := FTimeout;
    HTTP.AddHeader('Accept', AContentType);
    HTTP.AddHeader('Content-Type', AContentType);
    HTTP.AddHeader('A2A-Version', FProtocolVersion);
    if FToken <> '' then HTTP.AddHeader('Authorization', 'Bearer ' + FToken);
    HTTP.RequestBody := ABody;
    try
      HTTP.HTTPMethod(AMethod, AURL, ResponseStream, [200, 201, 202]);
      AResponse := ResponseStream.DataString;
      FLastRawResponse := AResponse;
      Result := True;
    except
      on E: Exception do
      begin
        FLastRawResponse := ResponseStream.DataString;
        SetError(E.Message + IfThen(FLastRawResponse <> '', ': ' + FLastRawResponse, ''));
      end;
    end;
    HTTP.RequestBody := nil;
  finally
    ResponseStream.Free;
    HTTP.Free;
  end;
end;

function TAIA2AClient.DoGet(const AURL: string; out AResponse: string): Boolean;
var
  HTTP: TFPHttpClient;
begin
  Result := False;
  AResponse := '';
  HTTP := TFPHttpClient.Create(nil);
  try
    HTTP.ConnectTimeout := FTimeout;
    HTTP.IOTimeout := FTimeout;
    HTTP.AddHeader('Accept', 'application/a2a+json, application/json');
    HTTP.AddHeader('A2A-Version', FProtocolVersion);
    if FToken <> '' then HTTP.AddHeader('Authorization', 'Bearer ' + FToken);
    try
      AResponse := HTTP.Get(AURL);
      FLastRawResponse := AResponse;
      Result := True;
    except
      on E: Exception do SetError(E.Message);
    end;
  finally
    HTTP.Free;
  end;
end;

procedure TAIA2AClient.SelectDiscoveredInterface;
var
  Intf: TAIA2AInterface;
begin
  Intf := FAgentCard.SelectInterface(FBinding);
  if Intf = nil then Exit;
  FSelectedURL := NormalizeBaseURL(Intf.URL);
  FTenant := Intf.Tenant;
  if Intf.ProtocolVersion <> '' then FProtocolVersion := Intf.ProtocolVersion;
end;

function TAIA2AClient.Discover: Boolean;
var
  URL, Raw: string;
begin
  ClearError;
  URL := Trim(FAgentCardURL);
  if URL = '' then
  begin
    if FBaseURL = '' then
    begin
      SetError('BaseURL ou AgentCardURL deve ser informado.');
      Exit(False);
    end;
    URL := NormalizeBaseURL(FBaseURL) + '/.well-known/agent-card.json';
  end;
  Result := DoGet(URL, Raw) and FAgentCard.LoadJSON(Raw);
  if not Result then
  begin
    if FLastError = '' then SetError('Agent Card A2A invalido.');
    Exit;
  end;
  SelectDiscoveredInterface;
  if FSelectedURL = '' then FSelectedURL := NormalizeBaseURL(FBaseURL);
  FLastResult := FAgentCard.Name;
  FLastSuccess := True;
end;

function TAIA2AClient.BuildMessageParams(const AText, ATaskID: string): TJSONObject;
var
  Msg, Part: TJSONObject;
  Parts: TJSONArray;
begin
  Result := TJSONObject.Create;
  Msg := TJSONObject.Create;
  Result.Add('message', Msg);
  Msg.Add('messageId', NewID);
  Msg.Add('role', 'ROLE_USER');
  if ATaskID <> '' then Msg.Add('taskId', ATaskID);
  Parts := TJSONArray.Create;
  Msg.Add('parts', Parts);
  Part := TJSONObject.Create;
  Part.Add('text', AText);
  Parts.Add(Part);
  if FTenant <> '' then Result.Add('tenant', FTenant);
end;

function TAIA2AClient.SendJSONRPC(const AMethod: string; AParams: TJSONObject;
  out AResponse: string): Boolean;
var
  Root: TJSONObject;
  Body: TStringStream;
  URL: string;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('jsonrpc', '2.0');
    Root.Add('id', NewID);
    Root.Add('method', AMethod);
    Root.Add('params', AParams);
    AParams := nil;
    Body := TStringStream.Create(Root.AsJSON);
    try
      URL := NormalizeBaseURL(FSelectedURL);
      Result := DoRequest('POST', URL, Body, 'application/json', AResponse);
    finally
      Body.Free;
    end;
  finally
    AParams.Free;
    Root.Free;
  end;
end;

function TAIA2AClient.SendHTTPJSON(const APath: string; ABody: TJSONObject;
  out AResponse: string): Boolean;
var
  Body: TStringStream;
  URL: string;
begin
  try
    Body := TStringStream.Create(ABody.AsJSON);
    try
      URL := NormalizeBaseURL(FSelectedURL) + APath;
      Result := DoRequest('POST', URL, Body, 'application/a2a+json', AResponse);
    finally
      Body.Free;
    end;
  finally
    ABody.Free;
  end;
end;

function TAIA2AClient.ExtractTextAndTask(const ARaw: string;
  out AText: string): Boolean;
var
  Root, Base, Data, PartsData: TJSONData;
  Arr: TJSONArray;
  I, J: Integer;
  S: string;
begin
  Result := False;
  AText := '';
  FLastTaskID := '';
  FLastContextID := '';
  try
    Root := GetJSON(ARaw);
    try
      Base := Root;
      Data := Root.FindPath('result');
      if Data <> nil then Base := Data;
      FLastTaskID := JSONString(Base, 'task.id');
      FLastContextID := JSONString(Base, 'task.contextId');
      PartsData := Base.FindPath('message.parts');
      if (PartsData <> nil) and (PartsData.JSONType = jtArray) then
      begin
        Arr := TJSONArray(PartsData);
        for I := 0 to Arr.Count - 1 do
        begin
          S := JSONString(Arr.Items[I], 'text');
          if S <> '' then
          begin
            if AText <> '' then AText := AText + LineEnding;
            AText := AText + S;
          end;
        end;
      end;
      if AText = '' then
      begin
        Data := Base.FindPath('task.artifacts');
        if (Data <> nil) and (Data.JSONType = jtArray) then
          for I := 0 to TJSONArray(Data).Count - 1 do
          begin
            PartsData := TJSONArray(Data).Items[I].FindPath('parts');
            if (PartsData <> nil) and (PartsData.JSONType = jtArray) then
              for J := 0 to TJSONArray(PartsData).Count - 1 do
              begin
                S := JSONString(TJSONArray(PartsData).Items[J], 'text');
                if S <> '' then
                begin
                  if AText <> '' then AText := AText + LineEnding;
                  AText := AText + S;
                end;
              end;
          end;
      end;
      if AText = '' then AText := JSONString(Base, 'task.status.message.parts[0].text');
      Result := (FLastTaskID <> '') or (AText <> '');
    finally
      Root.Free;
    end;
  except
    on E: Exception do SetError('Resposta A2A invalida: ' + E.Message);
  end;
end;

function TAIA2AClient.SendText(const AText: string; out AAnswer: string): Boolean;
var
  Raw: string;
begin
  ClearError;
  if FAutoDiscover and (FAgentCard.InterfaceCount = 0) then
    if not Discover then Exit(False);
  if FSelectedURL = '' then FSelectedURL := NormalizeBaseURL(FBaseURL);
  if FSelectedURL = '' then
  begin
    SetError('URL A2A nao configurada.');
    Exit(False);
  end;
  if FBinding = a2abJSONRPC then
    Result := SendJSONRPC('SendMessage', BuildMessageParams(AText, ''), Raw)
  else
    Result := SendHTTPJSON('/message:send', BuildMessageParams(AText, ''), Raw);
  if Result then Result := ExtractTextAndTask(Raw, AAnswer);
  FLastSuccess := Result;
  if Result then FLastResult := AAnswer;
end;

function TAIA2AClient.ContinueTask(const ATaskID, AText: string;
  out AAnswer: string): Boolean;
var
  Raw: string;
begin
  ClearError;
  if FSelectedURL = '' then
    if FAutoDiscover then
    begin
      if not Discover then Exit(False);
    end
    else
      FSelectedURL := NormalizeBaseURL(FBaseURL);
  if FBinding = a2abJSONRPC then
    Result := SendJSONRPC('SendMessage', BuildMessageParams(AText, ATaskID), Raw)
  else
    Result := SendHTTPJSON('/message:send', BuildMessageParams(AText, ATaskID), Raw);
  if Result then Result := ExtractTextAndTask(Raw, AAnswer);
  FLastSuccess := Result;
  if Result then FLastResult := AAnswer;
end;

function TAIA2AClient.GetTask(const ATaskID: string; out ATaskJSON: string;
  AHistoryLength: Integer): Boolean;
var
  Params: TJSONObject;
  URL: string;
begin
  ClearError;
  if FSelectedURL = '' then FSelectedURL := NormalizeBaseURL(FBaseURL);
  if FBinding = a2abJSONRPC then
  begin
    Params := TJSONObject.Create;
    Params.Add('id', ATaskID);
    if AHistoryLength >= 0 then Params.Add('historyLength', AHistoryLength);
    if FTenant <> '' then Params.Add('tenant', FTenant);
    Result := SendJSONRPC('GetTask', Params, ATaskJSON);
  end
  else
  begin
    URL := NormalizeBaseURL(FSelectedURL) + '/tasks/' + ATaskID;
    if AHistoryLength >= 0 then URL := URL + '?historyLength=' + IntToStr(AHistoryLength);
    Result := DoGet(URL, ATaskJSON);
  end;
  FLastSuccess := Result;
  if Result then FLastResult := ATaskJSON;
end;

function TAIA2AClient.CancelTask(const ATaskID: string;
  out ATaskJSON: string): Boolean;
var
  Params, EmptyBody: TJSONObject;
begin
  ClearError;
  if FSelectedURL = '' then FSelectedURL := NormalizeBaseURL(FBaseURL);
  if FBinding = a2abJSONRPC then
  begin
    Params := TJSONObject.Create;
    Params.Add('id', ATaskID);
    if FTenant <> '' then Params.Add('tenant', FTenant);
    Result := SendJSONRPC('CancelTask', Params, ATaskJSON);
  end
  else
  begin
    EmptyBody := TJSONObject.Create;
    if FTenant <> '' then EmptyBody.Add('tenant', FTenant);
    Result := SendHTTPJSON('/tasks/' + ATaskID + ':cancel', EmptyBody, ATaskJSON);
  end;
  FLastSuccess := Result;
  if Result then FLastResult := ATaskJSON;
end;

initialization
  {$I aia2a_icon.lrs}

end.
