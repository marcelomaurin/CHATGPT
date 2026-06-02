unit aiwebserver;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpserver;

type
  TAPIRequestEvent = procedure(Sender: TObject; const ARoute, AMethod, AContent: string;
    out AResponse: string; out AResponseCode: Integer) of object;

  { TServerThread }

  TServerThread = class(TThread)
  private
    FServer: TFPHTTPServer;
  protected
    procedure Execute; override;
  public
    constructor Create(AServer: TFPHTTPServer);
  end;

  { TAIWebAPIServer }

  TAIWebAPIServer = class(TComponent)
  private
    FPrompt: string;
    FPort: Integer;
    FActive: Boolean;
    FAllowedRoutes: TStrings;
    FOnRequestReceived: TAPIRequestEvent;
    FServer: TFPHTTPServer;
    FThread: TServerThread;
    procedure SetActive(AValue: Boolean);
    procedure SetAllowedRoutes(AValue: TStrings);
    procedure HandleRequest(Sender: TObject; var ARequest: TFPHTTPConnectionRequest;
      var AResponse: TFPHTTPConnectionResponse);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure StartServer;
    procedure StopServer;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Port: Integer read FPort write FPort default 8080;
    property Active: Boolean read FActive write SetActive default False;
    property AllowedRoutes: TStrings read FAllowedRoutes write SetAllowedRoutes;
    property OnRequestReceived: TAPIRequestEvent read FOnRequestReceived write FOnRequestReceived;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Input', [TAIWebAPIServer]);
end;

{ TServerThread }

constructor TServerThread.Create(AServer: TFPHTTPServer);
begin
  inherited Create(True);
  FServer := AServer;
  FreeOnTerminate := False;
end;

procedure TServerThread.Execute;
begin
  try
    FServer.Active := True;
  except
    // Log or handle server thread crash gracefully
  end;
end;

{ TAIWebAPIServer }

constructor TAIWebAPIServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIWebAPIServer is an embedded Web REST API Server. Properties: Port: Integer (default 8080), Active: Boolean (triggers server start/stop), OnRequestReceived: TWebRouteEvent. Methods: StartServer: Boolean, StopServer. AI Agent: Use this to expose predictions, metrics, or accept remote control commands via HTTP REST endpoints.';
  FPort := 8080;
  FActive := False;
  FAllowedRoutes := TStringList.Create;
  FServer := nil;
  FThread := nil;
end;

destructor TAIWebAPIServer.Destroy;
begin
  StopServer;
  FAllowedRoutes.Free;
  inherited Destroy;
end;

procedure TAIWebAPIServer.SetAllowedRoutes(AValue: TStrings);
begin
  FAllowedRoutes.Assign(AValue);
end;

procedure TAIWebAPIServer.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    StartServer
  else
    StopServer;
end;

procedure TAIWebAPIServer.StartServer;
begin
  if FActive then Exit;
  
  FServer := TFPHTTPServer.Create(Self);
  FServer.Port := FPort;
  FServer.OnRequest := @HandleRequest;
  
  FThread := TServerThread.Create(FServer);
  FThread.Start;
  
  FActive := True;
end;

procedure TAIWebAPIServer.StopServer;
begin
  if not FActive then Exit;
  
  if Assigned(FServer) then
  begin
    FServer.Active := False;
  end;
  
  if Assigned(FThread) then
  begin
    FThread.Terminate;
    FThread.WaitFor;
    FreeAndNil(FThread);
  end;
  
  FreeAndNil(FServer);
  FActive := False;
end;

procedure TAIWebAPIServer.HandleRequest(Sender: TObject; var ARequest: TFPHTTPConnectionRequest;
  var AResponse: TFPHTTPConnectionResponse);
var
  RouteMatched: Boolean;
  I: Integer;
  ResponseText: string;
  ResponseCode: Integer;
  RequestContent: string;
begin
  RouteMatched := False;
  
  // Validate route
  if FAllowedRoutes.Count = 0 then
    RouteMatched := True
  else
  begin
    for I := 0 to FAllowedRoutes.Count - 1 do
    begin
      if CompareText(ARequest.PathInfo, FAllowedRoutes[I]) = 0 then
      begin
        RouteMatched := True;
        Break;
      end;
    end;
  end;
  
  if not RouteMatched then
  begin
    AResponse.Code := 404;
    AResponse.Content := '{"error": "Route Not Found"}';
    AResponse.ContentType := 'application/json';
    Exit;
  end;
  
  ResponseText := '';
  ResponseCode := 200;
  
  if (ARequest.ContentLength > 0) then
    RequestContent := ARequest.Content;
  
  if Assigned(FOnRequestReceived) then
  begin
    try
      FOnRequestReceived(Self, ARequest.PathInfo, ARequest.Method, RequestContent, ResponseText, ResponseCode);
    except
      on E: Exception do
      begin
        ResponseText := '{"error": "Internal Callback Error: ' + E.Message + '"}';
        ResponseCode := 500;
      end;
    end;
  end
  else
  begin
    ResponseText := '{"status": "AI Web API Server Active", "route": "' + ARequest.PathInfo + '"}';
  end;
  
  AResponse.Code := ResponseCode;
  AResponse.Content := ResponseText;
  AResponse.ContentType := 'application/json';
end;

end.
