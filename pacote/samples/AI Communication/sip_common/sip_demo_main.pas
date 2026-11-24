unit sip_demo_main;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls,
  aisip_types, aisip_base, aisip_client, aisip_server, aisip_native;
type
  TSIPDemoForm = class(TForm)
  private
    FServerMode: Boolean;
    FServer: TAISIPServer;
    FClient: TAISIPClient;
    FEndpoint: TAISIPBase;
    FCallID: TAISIPCallID;
    FTimer: TTimer;
    FLog: TMemo;
    FLibrary, FHost, FUser, FPassword, FRealm, FDestination, FPort: TEdit;
    FSound: TCheckBox;
    procedure AddLog(const S: string);
    function EditRow(const Title, Value: string; Y: Integer): TEdit;
    procedure ButtonAt(const Title: string; X, Y: Integer; Handler: TNotifyEvent);
    procedure StartClick(Sender: TObject);
    procedure StopClick(Sender: TObject);
    procedure CallClick(Sender: TObject);
    procedure AnswerClick(Sender: TObject);
    procedure RejectClick(Sender: TObject);
    procedure HangupClick(Sender: TObject);
    procedure DTMFClick(Sender: TObject);
    procedure Tick(Sender: TObject);
    procedure Authenticate(Sender: TObject; const UserName, Realm, Remote: string;
      var Secret: string; var Kind: TAISIPCredentialKind; var Found: Boolean);
    procedure Authorize(Sender: TObject; const UserName, Target, Remote: string;
      var Allow: Boolean);
    procedure Route(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string;
      var Destination: string; var AAction: TAISIPRouteAction);
    procedure Incoming(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string);
    procedure CallState(Sender: TObject; CallID: TAISIPCallID; State: TAISIPCallState;
      Status: Integer; const Reason: string);
    procedure Registration(Sender: TObject; const UserName, Contact: string;
      Expires, StatusCode: Integer);
    procedure RegistrationState(Sender: TObject; Status, Expires: Integer; const Reason: string);
    procedure Error(Sender: TObject; Status: Integer; const Message: string);
    procedure Digit(Sender: TObject; CallID: TAISIPCallID; const Value: string; Duration: Integer);
  public
    constructor CreateDemo(AOwner: TComponent; ServerMode: Boolean);
    destructor Destroy; override;
  end;
implementation

constructor TSIPDemoForm.CreateDemo(AOwner: TComponent; ServerMode: Boolean);
begin
  inherited CreateNew(AOwner, 0); FServerMode := ServerMode;
  Width := 760; Height := 650; Position := poScreenCenter;
  if ServerMode then Caption := 'SIP Server — eventos de autenticacao e roteamento'
  else Caption := 'SIP Client — ramal Lazarus';
  FLibrary := EditRow('Runtime DLL / SO', DefaultSIPLibraryName, 12);
  FHost := EditRow('Servidor SIP / bind IP', 'sip:127.0.0.1:5060', 45);
  FRealm := EditRow('Dominio / realm', 'maurin.local', 78);
  FUser := EditRow('Ramal / ramais permitidos', '1001', 111);
  FPassword := EditRow('Senha (somente em memoria)', '', 144); FPassword.PasswordChar := '*';
  FPort := EditRow('Porta SIP local (0 = livre)', '0', 177);
  FDestination := EditRow('Destino / digitos DTMF', '1002', 210);
  FSound := TCheckBox.Create(Self); FSound.Parent := Self;
  FSound.SetBounds(190, 244, 470, 24); FSound.Caption := 'Usar microfone e alto-falante do computador';
  FSound.Checked := not ServerMode;
  if ServerMode then begin
    FHost.Text := '0.0.0.0'; FPort.Text := '5060'; FUser.Text := '1001,1002';
    FServer := TAISIPServer.Create(Self); FEndpoint := FServer;
    FServer.OnAuthenticate := @Authenticate;
    FServer.OnAuthorizeRegistration := @Authorize; FServer.OnAuthorizeCall := @Authorize;
    FServer.OnRouteCall := @Route; FServer.OnRegistration := @Registration;
  end else begin
    FClient := TAISIPClient.Create(Self); FEndpoint := FClient;
    FClient.OnRegistrationState := @RegistrationState;
  end;
  FEndpoint.OnIncomingCall := @Incoming; FEndpoint.OnCallStateChanged := @CallState;
  FEndpoint.OnError := @Error; FEndpoint.OnDTMF := @Digit;
  ButtonAt('Iniciar', 12, 280, @StartClick); ButtonAt('Parar', 116, 280, @StopClick);
  ButtonAt('Ligar', 220, 280, @CallClick); ButtonAt('Atender', 324, 280, @AnswerClick);
  ButtonAt('Recusar', 428, 280, @RejectClick); ButtonAt('Encerrar', 532, 280, @HangupClick);
  ButtonAt('DTMF', 636, 280, @DTMFClick);
  FLog := TMemo.Create(Self); FLog.Parent := Self; FLog.ReadOnly := True;
  FLog.ScrollBars := ssAutoVertical; FLog.SetBounds(12, 322, 720, 280);
  FLog.Anchors := [akTop, akBottom, akLeft, akRight];
  FTimer := TTimer.Create(Self); FTimer.Interval := 10; FTimer.OnTimer := @Tick;
  FTimer.Enabled := False;
  AddLog('Informe uma senha. O exemplo nao grava credenciais nem inicia chamadas automaticamente.');
end;

destructor TSIPDemoForm.Destroy;
begin
  FTimer.Enabled := False; FEndpoint.Stop;
  inherited Destroy;
end;

function TSIPDemoForm.EditRow(const Title, Value: string; Y: Integer): TEdit;
var L: TLabel;
begin
  L := TLabel.Create(Self); L.Parent := Self; L.Caption := Title; L.SetBounds(12, Y+5, 175, 24);
  Result := TEdit.Create(Self); Result.Parent := Self; Result.Text := Value;
  Result.SetBounds(190, Y, 530, 28); Result.Anchors := [akTop, akLeft, akRight];
end;

procedure TSIPDemoForm.ButtonAt(const Title: string; X, Y: Integer; Handler: TNotifyEvent);
var B: TButton;
begin
  B := TButton.Create(Self); B.Parent := Self; B.Caption := Title;
  B.SetBounds(X, Y, 96, 30); B.OnClick := Handler;
end;

procedure TSIPDemoForm.AddLog(const S: string);
begin
  if FLog.Lines.Count > 500 then FLog.Lines.Delete(0);
  FLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + S);
end;

procedure TSIPDemoForm.StartClick(Sender: TObject);
begin
  if FEndpoint.Active then Exit;
  if FPassword.Text = '' then begin AddLog('Informe uma senha antes de iniciar.'); Exit; end;
  FEndpoint.RuntimeLibrary := FLibrary.Text; FEndpoint.Realm := FRealm.Text;
  FEndpoint.SIPPort := StrToIntDef(FPort.Text, -1);
  FEndpoint.UseSoundDevice := FSound.Checked;
  if FServerMode then FServer.BindAddress := FHost.Text
  else begin
    FClient.ServerURI := FHost.Text; FClient.UserName := FUser.Text;
    FClient.Password := FPassword.Text;
  end;
  if not FEndpoint.Start then Exit;
  FTimer.Enabled := True; AddLog('Ativo na porta ' + IntToStr(FEndpoint.LocalPort));
  if not FServerMode then FClient.RegisterAccount;
end;
procedure TSIPDemoForm.StopClick(Sender: TObject);
begin FTimer.Enabled := False; FEndpoint.Stop; FCallID := 0; AddLog('Parado'); end;
procedure TSIPDemoForm.CallClick(Sender: TObject);
begin FEndpoint.Call(FDestination.Text, FCallID); end;
procedure TSIPDemoForm.AnswerClick(Sender: TObject);
begin FEndpoint.Answer(FCallID); end;
procedure TSIPDemoForm.RejectClick(Sender: TObject);
begin FEndpoint.Reject(FCallID); end;
procedure TSIPDemoForm.HangupClick(Sender: TObject);
begin FEndpoint.Hangup(FCallID); end;
procedure TSIPDemoForm.DTMFClick(Sender: TObject);
begin FEndpoint.SendDTMF(FCallID, FDestination.Text); end;
procedure TSIPDemoForm.Tick(Sender: TObject);
begin if FEndpoint.Active then FEndpoint.Poll(0); end;

procedure TSIPDemoForm.Authenticate(Sender: TObject; const UserName, Realm, Remote: string;
  var Secret: string; var Kind: TAISIPCredentialKind; var Found: Boolean);
var Users: TStringList;
begin
  { Replace this lookup with your database. The SIP device sends Digest,
    not its plaintext password. This demo shares the entered password. }
  Users := TStringList.Create;
  try
    Users.StrictDelimiter := True; Users.Delimiter := ','; Users.DelimitedText := FUser.Text;
    Found := (Users.IndexOf(UserName) >= 0) and (Realm = FRealm.Text) and (FPassword.Text <> '');
    Kind := skPassword; if Found then Secret := FPassword.Text;
  finally Users.Free; end;
end;
procedure TSIPDemoForm.Authorize(Sender: TObject; const UserName, Target, Remote: string;
  var Allow: Boolean);
begin
  Allow := True; { Invoked only after the component has verified Digest. }
  AddLog('Autorizado ' + UserName + ' de ' + Remote);
end;
procedure TSIPDemoForm.Route(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string;
  var Destination: string; var AAction: TAISIPRouteAction);
begin
  Destination := Target;
  if Target = '9000' then AAction := srAnswerLocally else AAction := srRoute;
  AddLog('Rota ' + Caller + ' -> ' + Target + ' chamada=' + UIntToStr(CallID));
end;
procedure TSIPDemoForm.Incoming(Sender: TObject; CallID: TAISIPCallID; const Caller, Target: string);
begin FCallID := CallID; FEndpoint.Ring(CallID); AddLog('Chamada recebida de ' + Caller + '. Use Atender ou Recusar.'); end;
procedure TSIPDemoForm.CallState(Sender: TObject; CallID: TAISIPCallID;
  State: TAISIPCallState; Status: Integer; const Reason: string);
begin
  AddLog('Chamada ' + UIntToStr(CallID) + ' estado=' + IntToStr(Ord(State)) + ' SIP=' + IntToStr(Status) + ' ' + Reason);
  if (State = scDisconnected) and (FCallID = CallID) then FCallID := 0;
end;
procedure TSIPDemoForm.Registration(Sender: TObject; const UserName, Contact: string;
  Expires, StatusCode: Integer);
begin AddLog('Ramal ' + UserName + ' contato=' + Contact + ' validade=' + IntToStr(Expires)); end;
procedure TSIPDemoForm.RegistrationState(Sender: TObject; Status, Expires: Integer; const Reason: string);
begin AddLog('Registro SIP=' + IntToStr(Status) + ' validade=' + IntToStr(Expires) + ' ' + Reason); end;
procedure TSIPDemoForm.Error(Sender: TObject; Status: Integer; const Message: string);
begin AddLog('Erro ' + IntToStr(Status) + ': ' + Message); end;
procedure TSIPDemoForm.Digit(Sender: TObject; CallID: TAISIPCallID; const Value: string; Duration: Integer);
begin AddLog('DTMF ' + Value + ' chamada=' + UIntToStr(CallID)); end;
end.
