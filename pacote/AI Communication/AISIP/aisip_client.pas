unit aisip_client;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, aisip_base, aisip_native, aisip_types;

type
  TAISIPClient = class(TAISIPBase)
  private
    FUserName, FPassword, FServerURI: string;
    FConfigUser, FConfigRealm, FConfigPassword: string;
    FExpires: Integer;
    FOnRegistrationState: TAISIPRegistrationStateEvent;
    FOnCredentialsRequired: TAISIPCredentialsEvent;
  protected
    procedure FillConfig(var Config: TASIPConfig); override;
    procedure HandleEvent(Event: Integer; CallID: TAISIPCallID;
      Status, Value: Integer; const Detail, Remote: string); override;
  public
    constructor Create(AOwner: TComponent); override;
    function RegisterAccount: Boolean;
    function UnregisterAccount: Boolean;
  published
    property UserName: string read FUserName write FUserName;
    property Password: string read FPassword write FPassword stored False;
    property ServerURI: string read FServerURI write FServerURI;
    property Expires: Integer read FExpires write FExpires default 300;
    property OnRegistrationState: TAISIPRegistrationStateEvent read FOnRegistrationState write FOnRegistrationState;
    property OnCredentialsRequired: TAISIPCredentialsEvent read FOnCredentialsRequired write FOnCredentialsRequired;
  end;

implementation

constructor TAISIPClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FExpires := 300;
  FPrompt := 'SIP client: Start, RegisterAccount, Poll, Call, Answer, Reject, Hangup, SendDTMF, WriteAudio. Events control incoming calls and provide PCM audio.';
end;

procedure TAISIPClient.FillConfig(var Config: TASIPConfig);
begin
  inherited FillConfig(Config);
  FConfigUser := FUserName; FConfigRealm := Realm; FConfigPassword := FPassword;
  if Assigned(FOnCredentialsRequired) then
    FOnCredentialsRequired(Self, FConfigUser, FConfigRealm, FConfigPassword);
  if (FConfigUser = '') or (FServerURI = '') or (FExpires < 60) or (FExpires > 3600) then
    raise Exception.Create('UserName, ServerURI and Expires (60..3600) are required');
  Config.Role := 0; Config.UserName := PAnsiChar(FConfigUser);
  Config.Realm := PAnsiChar(FConfigRealm); Config.Password := PAnsiChar(FConfigPassword);
  Config.Registrar := PAnsiChar(FServerURI); Config.Expires := FExpires;
end;

function TAISIPClient.RegisterAccount: Boolean;
begin
  { The native context registers explicitly, never implicitly during creation. }
  Result := RequireActive;
  if Result then Result := DoRegistration(True);
end;

function TAISIPClient.UnregisterAccount: Boolean;
begin
  Result := RequireActive;
  if Result then Result := DoRegistration(False);
end;

procedure TAISIPClient.HandleEvent(Event: Integer; CallID: TAISIPCallID;
  Status, Value: Integer; const Detail, Remote: string);
begin
  inherited HandleEvent(Event, CallID, Status, Value, Detail, Remote);
  if (Event = ASIP_REG_STATE) and Assigned(FOnRegistrationState) then
    FOnRegistrationState(Self, Status, Value, Detail);
end;
end.
