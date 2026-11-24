unit aisip_server;

{$mode objfpc}{$H+}

interface

uses Classes, aisip_base, aisip_native, aisip_types;

type
  TAISIPServer = class(TAISIPBase)
  private
    FOnAuthenticate: TAISIPAuthenticateEvent;
    FOnAuthorizeRegistration, FOnAuthorizeCall: TAISIPAuthorizeEvent;
    FOnRouteCall: TAISIPRouteEvent;
    FOnRegistration: TAISIPRegistrationEvent;
    FOnAuthenticationResult: TAISIPAuthenticationResultEvent;
    FDigestAlgorithm: TAISIPDigestAlgorithm;
  protected
    procedure FillConfig(var Config: TASIPConfig); override;
    function LookupCredential(const UserName, ARealm, Remote: string;
      out Secret: string; out Kind: TAISIPCredentialKind): Boolean; override;
    function Authorize(const Operation, UserName, Target, Remote: string): Boolean; override;
    function Route(CallID: TAISIPCallID; const Caller, Target: string;
      out Destination: string): TAISIPRouteAction; override;
    procedure HandleEvent(Event: Integer; CallID: TAISIPCallID;
      Status, Value: Integer; const Detail, Remote: string); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property SIPPort default 5060;
    property RTPPort default 42000;
    property DigestAlgorithm: TAISIPDigestAlgorithm read FDigestAlgorithm write FDigestAlgorithm default sdSHA256;
    property OnAuthenticate: TAISIPAuthenticateEvent read FOnAuthenticate write FOnAuthenticate;
    property OnAuthorizeRegistration: TAISIPAuthorizeEvent read FOnAuthorizeRegistration write FOnAuthorizeRegistration;
    property OnAuthorizeCall: TAISIPAuthorizeEvent read FOnAuthorizeCall write FOnAuthorizeCall;
    property OnRouteCall: TAISIPRouteEvent read FOnRouteCall write FOnRouteCall;
    property OnRegistration: TAISIPRegistrationEvent read FOnRegistration write FOnRegistration;
    property OnAuthenticationResult: TAISIPAuthenticationResultEvent read FOnAuthenticationResult write FOnAuthenticationResult;
  end;

implementation

constructor TAISIPServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); SIPPort := 5060; RTPPort := 42000;
  FDigestAlgorithm := sdSHA256;
  FPrompt := 'Embedded SIP registrar and call server. Authentication, registration authorization, call authorization and routing default to deny; implement their events. Call Poll regularly.';
end;

procedure TAISIPServer.FillConfig(var Config: TASIPConfig);
begin
  inherited FillConfig(Config); Config.Role := 1;
  Config.DigestAlgorithm := Ord(FDigestAlgorithm) + 1;
end;

function TAISIPServer.LookupCredential(const UserName, ARealm, Remote: string;
  out Secret: string; out Kind: TAISIPCredentialKind): Boolean;
begin
  Secret := ''; Kind := skPassword; Result := False;
  if Assigned(FOnAuthenticate) then FOnAuthenticate(Self, UserName, ARealm,
    Remote, Secret, Kind, Result);
end;

function TAISIPServer.Authorize(const Operation, UserName, Target, Remote: string): Boolean;
begin
  Result := False;
  if (Operation = 'REGISTER') and Assigned(FOnAuthorizeRegistration) then
    FOnAuthorizeRegistration(Self, UserName, Target, Remote, Result)
  else if (Operation = 'INVITE') and Assigned(FOnAuthorizeCall) then
    FOnAuthorizeCall(Self, UserName, Target, Remote, Result);
end;

function TAISIPServer.Route(CallID: TAISIPCallID; const Caller, Target: string;
  out Destination: string): TAISIPRouteAction;
begin
  Destination := Target; Result := srDeny;
  if Assigned(FOnRouteCall) then
    FOnRouteCall(Self, CallID, Caller, Target, Destination, Result);
end;

procedure TAISIPServer.HandleEvent(Event: Integer; CallID: TAISIPCallID;
  Status, Value: Integer; const Detail, Remote: string);
begin
  inherited HandleEvent(Event, CallID, Status, Value, Detail, Remote);
  if (Event = ASIP_REGISTRATION) and Assigned(FOnRegistration) then
    FOnRegistration(Self, Detail, Remote, Value, Status)
  else if (Event = ASIP_AUTH_RESULT) and Assigned(FOnAuthenticationResult) then
    FOnAuthenticationResult(Self, Detail, Remote, Value <> 0, Status);
end;
end.
