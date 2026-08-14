unit aia2aserver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, LResources, aibase, aiagent,
  aiwebserver;

type
  TAIA2AServer = class(TAIBaseComponent)
  private
    FWebServer: TAIWebAPIServer;
    FAgent: TAIAgent;
    FPort: Integer;
    FPublicURL: string;
    FAgentName: string;
    FAgentDescription: string;
    FAgentVersion: string;
    FProtocolVersion: string;
    FSkillID: string;
    FSkillName: string;
    FActive: Boolean;
    procedure SetAgent(AValue: TAIAgent);
    procedure SetActive(AValue: Boolean);
    procedure HandleRequest(Sender: TObject; const ARoute, AMethod,
      AContent: string; out AResponse: string; out AResponseCode: Integer);
    function BuildAgentCard: string;
    function ExtractUserText(AData: TJSONData): string;
    function NewID: string;
    function BuildMessageResponse(const AText: string): TJSONObject;
    function HandleSendMessage(AParams: TJSONData; out AResult: TJSONObject;
      out AError: string): Boolean;
    function HandleJSONRPC(const AContent: string; out AResponse: string): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Start: Boolean;
    procedure Stop;
    property WebServer: TAIWebAPIServer read FWebServer;
  published
    property Agent: TAIAgent read FAgent write SetAgent;
    property Port: Integer read FPort write FPort default 8090;
    property PublicURL: string read FPublicURL write FPublicURL;
    property AgentName: string read FAgentName write FAgentName;
    property AgentDescription: string read FAgentDescription write FAgentDescription;
    property AgentVersion: string read FAgentVersion write FAgentVersion;
    property ProtocolVersion: string read FProtocolVersion write FProtocolVersion;
    property SkillID: string read FSkillID write FSkillID;
    property SkillName: string read FSkillName write FSkillName;
    property Active: Boolean read FActive write SetActive default False;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI A2A', [TAIA2AServer]);
end;

constructor TAIA2AServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FPort := 8090;
  FPublicURL := 'http://127.0.0.1:8090';
  FAgentName := 'Lazarus AI Agent';
  FAgentDescription := 'Agent published by the CHATGPT Lazarus AI Suite.';
  FAgentVersion := '1.0.0';
  FProtocolVersion := '1.0';
  FSkillID := 'chat';
  FSkillName := 'Chat';
  FWebServer := TAIWebAPIServer.Create(Self);
  FWebServer.Port := FPort;
  FWebServer.OnRequestReceived := @HandleRequest;
end;

destructor TAIA2AServer.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TAIA2AServer.SetAgent(AValue: TAIAgent);
begin
  if FAgent = AValue then Exit;
  if Assigned(FAgent) then FAgent.RemoveFreeNotification(Self);
  FAgent := AValue;
  if Assigned(FAgent) then FAgent.FreeNotification(Self);
end;

procedure TAIA2AServer.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FAgent) then FAgent := nil;
end;

procedure TAIA2AServer.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then Start else Stop;
end;

function TAIA2AServer.Start: Boolean;
begin
  ClearError;
  if FAgent = nil then
  begin
    SetError('TAIA2AServer precisa de um TAIAgent configurado.');
    Exit(False);
  end;
  FWebServer.Port := FPort;
  Result := FWebServer.StartServer;
  FActive := Result;
  FLastSuccess := Result;
  if not Result then SetError(FWebServer.LastError);
end;

procedure TAIA2AServer.Stop;
begin
  if Assigned(FWebServer) then FWebServer.StopServer;
  FActive := False;
end;

function TAIA2AServer.NewID: string;
var
  G: TGUID;
begin
  if CreateGUID(G) = 0 then Result := GUIDToString(G)
  else Result := IntToHex(Random(MaxInt), 8) + IntToHex(Random(MaxInt), 8);
  Result := StringReplace(Result, '{', '', [rfReplaceAll]);
  Result := StringReplace(Result, '}', '', [rfReplaceAll]);
end;

function TAIA2AServer.BuildAgentCard: string;
var
  Root, Caps, IntfHTTP, IntfRPC, Skill: TJSONObject;
  Interfaces, Skills, Modes: TJSONArray;
  Base: string;
begin
  Base := FPublicURL;
  while (Base <> '') and (Base[Length(Base)] = '/') do Delete(Base, Length(Base), 1);
  Root := TJSONObject.Create;
  try
    Root.Add('name', FAgentName);
    Root.Add('description', FAgentDescription);
    Root.Add('version', FAgentVersion);

    Interfaces := TJSONArray.Create;
    Root.Add('supportedInterfaces', Interfaces);
    IntfHTTP := TJSONObject.Create;
    IntfHTTP.Add('url', Base);
    IntfHTTP.Add('protocolBinding', 'HTTP+JSON');
    IntfHTTP.Add('protocolVersion', FProtocolVersion);
    Interfaces.Add(IntfHTTP);
    IntfRPC := TJSONObject.Create;
    IntfRPC.Add('url', Base + '/rpc');
    IntfRPC.Add('protocolBinding', 'JSONRPC');
    IntfRPC.Add('protocolVersion', FProtocolVersion);
    Interfaces.Add(IntfRPC);

    Caps := TJSONObject.Create;
    Caps.Add('streaming', False);
    Caps.Add('pushNotifications', False);
    Caps.Add('extendedAgentCard', False);
    Root.Add('capabilities', Caps);

    Modes := TJSONArray.Create;
    Modes.Add('text/plain');
    Root.Add('defaultInputModes', Modes);
    Modes := TJSONArray.Create;
    Modes.Add('text/plain');
    Root.Add('defaultOutputModes', Modes);

    Skills := TJSONArray.Create;
    Root.Add('skills', Skills);
    Skill := TJSONObject.Create;
    Skill.Add('id', FSkillID);
    Skill.Add('name', FSkillName);
    Skill.Add('description', FAgentDescription);
    Modes := TJSONArray.Create;
    Modes.Add('text/plain');
    Skill.Add('inputModes', Modes);
    Modes := TJSONArray.Create;
    Modes.Add('text/plain');
    Skill.Add('outputModes', Modes);
    Skills.Add(Skill);

    Result := Root.AsJSON;
  finally
    Root.Free;
  end;
end;

function TAIA2AServer.ExtractUserText(AData: TJSONData): string;
var
  Parts: TJSONData;
  I: Integer;
  S: string;
begin
  Result := '';
  if AData = nil then Exit;
  Parts := AData.FindPath('message.parts');
  if (Parts = nil) or (Parts.JSONType <> jtArray) then Exit;
  for I := 0 to TJSONArray(Parts).Count - 1 do
  begin
    S := '';
    if TJSONArray(Parts).Items[I].FindPath('text') <> nil then
      S := TJSONArray(Parts).Items[I].FindPath('text').AsString;
    if S <> '' then
    begin
      if Result <> '' then Result := Result + LineEnding;
      Result := Result + S;
    end;
  end;
end;

function TAIA2AServer.BuildMessageResponse(const AText: string): TJSONObject;
var
  Msg, Part: TJSONObject;
  Parts: TJSONArray;
begin
  Result := TJSONObject.Create;
  Msg := TJSONObject.Create;
  Result.Add('message', Msg);
  Msg.Add('messageId', NewID);
  Msg.Add('role', 'ROLE_AGENT');
  Parts := TJSONArray.Create;
  Msg.Add('parts', Parts);
  Part := TJSONObject.Create;
  Part.Add('text', AText);
  Parts.Add(Part);
end;

function TAIA2AServer.HandleSendMessage(AParams: TJSONData;
  out AResult: TJSONObject; out AError: string): Boolean;
var
  InputText: string;
begin
  Result := False;
  AResult := nil;
  AError := '';
  if FAgent = nil then
  begin
    AError := 'Agent nao configurado.';
    Exit;
  end;
  InputText := ExtractUserText(AParams);
  if Trim(InputText) = '' then
  begin
    AError := 'message.parts precisa conter texto.';
    Exit;
  end;
  if not FAgent.Execute(InputText) then
  begin
    AError := FAgent.LastError;
    if AError = '' then AError := 'Falha ao executar agente.';
    Exit;
  end;
  AResult := BuildMessageResponse(FAgent.LastResult);
  Result := True;
end;

function TAIA2AServer.HandleJSONRPC(const AContent: string;
  out AResponse: string): Boolean;
var
  Root, Params: TJSONData;
  OutRoot, ResultObj, ErrObj: TJSONObject;
  LMethodName, RequestID, ErrText: string;
begin
  Result := False;
  AResponse := '';
  try
    Root := GetJSON(AContent);
    try
      LMethodName := '';
      RequestID := '';
      if Root.FindPath('method') <> nil then LMethodName := Root.FindPath('method').AsString;
      if Root.FindPath('id') <> nil then RequestID := Root.FindPath('id').AsString;
      Params := Root.FindPath('params');
      OutRoot := TJSONObject.Create;
      try
        OutRoot.Add('jsonrpc', '2.0');
        OutRoot.Add('id', RequestID);
        if SameText(LMethodName, 'SendMessage') then
        begin
          if HandleSendMessage(Params, ResultObj, ErrText) then
          begin
            OutRoot.Add('result', ResultObj);
            Result := True;
          end
          else
          begin
            ErrObj := TJSONObject.Create;
            ErrObj.Add('code', -32602);
            ErrObj.Add('message', ErrText);
            OutRoot.Add('error', ErrObj);
          end;
        end
        else
        begin
          ErrObj := TJSONObject.Create;
          ErrObj.Add('code', -32601);
          ErrObj.Add('message', 'Method not found');
          OutRoot.Add('error', ErrObj);
        end;
        AResponse := OutRoot.AsJSON;
      finally
        OutRoot.Free;
      end;
    finally
      Root.Free;
    end;
  except
    on E: Exception do
    begin
      OutRoot := TJSONObject.Create;
      try
        OutRoot.Add('jsonrpc', '2.0');
        OutRoot.Add('id', TJSONNull.Create);
        ErrObj := TJSONObject.Create;
        ErrObj.Add('code', -32700);
        ErrObj.Add('message', 'Invalid JSON payload: ' + E.Message);
        OutRoot.Add('error', ErrObj);
        AResponse := OutRoot.AsJSON;
      finally
        OutRoot.Free;
      end;
    end;
  end;
end;

procedure TAIA2AServer.HandleRequest(Sender: TObject; const ARoute, AMethod,
  AContent: string; out AResponse: string; out AResponseCode: Integer);
var
  Data: TJSONData;
  ResultObj: TJSONObject;
  ErrText: string;
begin
  AResponseCode := 200;
  if SameText(AMethod, 'GET') and
     SameText(ARoute, '/.well-known/agent-card.json') then
  begin
    AResponse := BuildAgentCard;
    Exit;
  end;

  if SameText(AMethod, 'POST') and SameText(ARoute, '/rpc') then
  begin
    if not HandleJSONRPC(AContent, AResponse) then
      AResponseCode := 400;
    Exit;
  end;

  if SameText(AMethod, 'POST') and SameText(ARoute, '/message:send') then
  begin
    try
      Data := GetJSON(AContent);
      try
        if HandleSendMessage(Data, ResultObj, ErrText) then
        begin
          try
            AResponse := ResultObj.AsJSON;
          finally
            ResultObj.Free;
          end;
        end
        else
        begin
          AResponseCode := 400;
          ResultObj := TJSONObject.Create;
          try
            ResultObj.Add('error', ErrText);
            AResponse := ResultObj.AsJSON;
          finally
            ResultObj.Free;
          end;
        end;
      finally
        Data.Free;
      end;
    except
      on E: Exception do
      begin
        AResponseCode := 400;
        AResponse := '{"error":"' + StringReplace(E.Message, '"', '\"', [rfReplaceAll]) + '"}';
      end;
    end;
    Exit;
  end;

  AResponseCode := 404;
  AResponse := '{"error":"A2A route not found"}';
end;

end.
