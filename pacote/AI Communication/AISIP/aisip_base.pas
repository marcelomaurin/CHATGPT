unit aisip_base;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, ctypes, aibase, aisip_types, aisip_native;

type
  { Networking is explicitly pumped by Poll, so authentication and all public
    events run on the application's thread, including in console services. }
  TAISIPBase = class(TAIBaseComponent)
  private
    FNative: TAISIPNative;
    FContext: Pointer;
    FActive, FStopPending: Boolean;
    FDispatchDepth: Integer;
    FRuntimeLibrary, FBindAddress, FPublicAddress, FRealm: string;
    FSIPPort, FRTPPort: Integer;
    FUseSoundDevice: Boolean;
    FOnIncomingCall: TAISIPIncomingCallEvent;
    FOnCallStateChanged: TAISIPCallStateEvent;
    FOnDTMF: TAISIPDTMFEvent;
    FOnAudio: TAISIPAudioEvent;
    FOnAudioOverflow: TAISIPAudioOverflowEvent;
    FOnError: TAISIPErrorEvent;
    procedure SetActive(Value: Boolean);
    function GetLocalPort: Integer;
  protected
    procedure FillConfig(var Config: TASIPConfig); virtual;
    function LookupCredential(const UserName, Realm, Remote: string;
      out Secret: string; out Kind: TAISIPCredentialKind): Boolean; virtual;
    function Authorize(const Operation, UserName, Target,
      Remote: string): Boolean; virtual;
    function Route(CallID: TAISIPCallID; const Caller, Target: string;
      out Destination: string): TAISIPRouteAction; virtual;
    procedure HandleEvent(Event: Integer; CallID: TAISIPCallID;
      Status, Value: Integer; const Detail, Remote: string); virtual;
    procedure ReportError(Code: Integer; const Message: string);
    function CheckResult(Code: Integer; const Operation: string): Boolean;
    function RequireActive: Boolean;
    function DoRegistration(Enable: Boolean): Boolean;
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Start: Boolean;
    procedure Stop;
    function Poll(TimeoutMs: Integer = 0): Boolean;
    function Call(const Destination: string; out CallID: TAISIPCallID): Boolean; virtual;
    function Answer(CallID: TAISIPCallID): Boolean;
    function Ring(CallID: TAISIPCallID): Boolean;
    function Reject(CallID: TAISIPCallID; StatusCode: Integer = 486): Boolean;
    function Hangup(CallID: TAISIPCallID): Boolean;
    function SendDTMF(CallID: TAISIPCallID; const Digits: string): Boolean;
    function WriteAudio(CallID: TAISIPCallID;
      const Samples: TAISIPAudioSamples): Integer;
    property LocalPort: Integer read GetLocalPort;
  published
    property RuntimeLibrary: string read FRuntimeLibrary write FRuntimeLibrary;
    property BindAddress: string read FBindAddress write FBindAddress;
    property PublicAddress: string read FPublicAddress write FPublicAddress;
    property Realm: string read FRealm write FRealm;
    property SIPPort: Integer read FSIPPort write FSIPPort default 0;
    property RTPPort: Integer read FRTPPort write FRTPPort default 40000;
    property UseSoundDevice: Boolean read FUseSoundDevice write FUseSoundDevice default False;
    property Active: Boolean read FActive write SetActive default False;
    property OnIncomingCall: TAISIPIncomingCallEvent read FOnIncomingCall write FOnIncomingCall;
    property OnCallStateChanged: TAISIPCallStateEvent read FOnCallStateChanged write FOnCallStateChanged;
    property OnDTMF: TAISIPDTMFEvent read FOnDTMF write FOnDTMF;
    property OnAudio: TAISIPAudioEvent read FOnAudio write FOnAudio;
    property OnAudioOverflow: TAISIPAudioOverflowEvent read FOnAudioOverflow write FOnAudioOverflow;
    property OnError: TAISIPErrorEvent read FOnError write FOnError;
  end;

implementation

function TextOf(P: PAnsiChar): string;
begin
  if P = nil then Result := '' else Result := string(P);
end;

function CopyToBuffer(const S: string; Buffer: PAnsiChar; Capacity: Integer): Boolean;
begin
  Result := (Buffer <> nil) and (Capacity > Length(S)) and (Pos(#0, S) = 0);
  if not Result then Exit;
  if S <> '' then Move(S[1], Buffer^, Length(S));
  Buffer[Length(S)] := #0;
end;

procedure CallbackError(C: TAISIPBase; E: Exception);
begin
  { Exceptions must never cross the C ABI, including exceptions from OnError. }
  try C.ReportError(-1, 'SIP event: ' + E.Message); except end;
end;

function CredentialCB(Data: Pointer; UserName, Realm, Remote, Secret: PAnsiChar;
  Capacity: cint; Kind: Pcint): cint; cdecl;
var C: TAISIPBase; S: string; K: TAISIPCredentialKind;
begin
  Result := 0; C := TAISIPBase(Data);
  Inc(C.FDispatchDepth);
  try
    try
      if C.LookupCredential(TextOf(UserName), TextOf(Realm), TextOf(Remote), S, K)
        and CopyToBuffer(S, Secret, Capacity) then
      begin Kind^ := Ord(K); Result := 1; end;
    except on E: Exception do CallbackError(C, E); end;
  finally
    if S <> '' then begin UniqueString(S); FillChar(S[1], Length(S), 0); end;
    Dec(C.FDispatchDepth);
  end;
end;

function AuthorizeCB(Data: Pointer; Operation, UserName, Target,
  Remote: PAnsiChar): cint; cdecl;
var C: TAISIPBase;
begin
  Result := 0; C := TAISIPBase(Data); Inc(C.FDispatchDepth);
  try
    try Result := Ord(C.Authorize(TextOf(Operation), TextOf(UserName),
      TextOf(Target), TextOf(Remote)));
    except on E: Exception do CallbackError(C, E); end;
  finally Dec(C.FDispatchDepth); end;
end;

function RouteCB(Data: Pointer; CallID: cuint64; Caller, Target,
  Destination: PAnsiChar; Capacity: cint): cint; cdecl;
var C: TAISIPBase; S: string; A: TAISIPRouteAction;
begin
  Result := 0; C := TAISIPBase(Data); Inc(C.FDispatchDepth);
  try
    try
      A := C.Route(CallID, TextOf(Caller), TextOf(Target), S);
      if CopyToBuffer(S, Destination, Capacity) then Result := Ord(A);
    except on E: Exception do CallbackError(C, E); end;
  finally Dec(C.FDispatchDepth); end;
end;

procedure EventCB(Data: Pointer; Event: cint; CallID: cuint64;
  Status, Value: cint; Detail, Remote: PAnsiChar); cdecl;
var C: TAISIPBase;
begin
  C := TAISIPBase(Data); Inc(C.FDispatchDepth);
  try
    try C.HandleEvent(Event, CallID, Status, Value, TextOf(Detail), TextOf(Remote));
    except on E: Exception do CallbackError(C, E); end;
  finally Dec(C.FDispatchDepth); end;
end;

procedure AudioCB(Data: Pointer; CallID: cuint64; Samples: PSmallInt;
  Count, SampleRate: cint); cdecl;
var C: TAISIPBase; A: TAISIPAudioSamples;
begin
  C := TAISIPBase(Data);
  if (Count <= 0) or (Count > 8000) or (Samples = nil) then Exit;
  Inc(C.FDispatchDepth);
  try
    try
      if Assigned(C.FOnAudio) then
      begin
        SetLength(A, Count); Move(Samples^, A[0], Count * SizeOf(SmallInt));
        C.FOnAudio(C, CallID, A, SampleRate);
      end;
    except on E: Exception do CallbackError(C, E); end;
  finally Dec(C.FDispatchDepth); end;
end;

constructor TAISIPBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBindAddress := '0.0.0.0'; FRealm := 'maurin.local'; FRTPPort := 40000;
  FCategory := ccInput;
end;

destructor TAISIPBase.Destroy;
begin
  Stop;
  inherited Destroy;
end;

procedure TAISIPBase.FillConfig(var Config: TASIPConfig);
begin
  FillChar(Config, SizeOf(Config), 0);
  Config.Size := SizeOf(Config); Config.ABIVersion := ASIP_ABI_VERSION;
  Config.BindAddress := PAnsiChar(FBindAddress);
  Config.PublicAddress := PAnsiChar(FPublicAddress);
  Config.Realm := PAnsiChar(FRealm);
  Config.SIPPort := FSIPPort; Config.RTPPort := FRTPPort;
  Config.UseSoundDevice := Ord(FUseSoundDevice);
  Config.Expires := 300; Config.DigestAlgorithm := 2;
end;

function TAISIPBase.Start: Boolean;
var Config: TASIPConfig; CB: TASIPCallbacks;
    Error: array[0..1023] of AnsiChar; Code: Integer;
begin
  Result := False;
  if FContext <> nil then Exit(True);
  ClearError;
  if (FSIPPort < 0) or (FSIPPort > 65535) or
    (FRTPPort < 1024) or (FRTPPort > 65000) or (FRealm = '') then
  begin ReportError(-1, 'Invalid SIP/RTP port or empty realm'); Exit; end;
  try
    FillConfig(Config);
    if FStopPending then begin FStopPending := False; Exit; end;
    FNative := TAISIPNative.Create(FRuntimeLibrary);
    FillChar(CB, SizeOf(CB), 0); FillChar(Error, SizeOf(Error), 0);
    CB.Credential := @CredentialCB; CB.Authorize := @AuthorizeCB;
    CB.Route := @RouteCB; CB.Event := @EventCB; CB.Audio := @AudioCB;
    Inc(FDispatchDepth);
    try Code := FNative.CreateContext(@Config, @CB, Self, FContext, @Error[0], SizeOf(Error));
    finally Dec(FDispatchDepth); end;
    if Code <> 0 then
    begin
      FreeAndNil(FNative); FContext := nil;
      ReportError(Code, TextOf(@Error[0])); Exit;
    end;
    FActive := True; Result := True;
    Log(llInfo, 'SIP started on port ' + IntToStr(LocalPort));
    if FStopPending then begin Stop; Result := False; end;
  except
    on E: Exception do
    begin
      if FContext <> nil then FNative.DestroyContext(FContext);
      FContext := nil; FreeAndNil(FNative); FActive := False;
      ReportError(-1, E.Message);
    end;
  end;
end;

procedure TAISIPBase.Stop;
begin
  if FDispatchDepth > 0 then begin FStopPending := True; Exit; end;
  FStopPending := False;
  if FContext <> nil then
  begin FNative.DestroyContext(FContext); FContext := nil; end;
  FreeAndNil(FNative); FActive := False;
end;

function TAISIPBase.Poll(TimeoutMs: Integer): Boolean;
var Code: Integer;
begin
  if FStopPending then begin Stop; Exit(False); end;
  if not RequireActive then Exit(False);
  if (TimeoutMs < 0) or (TimeoutMs > 1000) then
  begin ReportError(-1, 'Poll timeout must be between 0 and 1000 ms'); Exit(False); end;
  Inc(FDispatchDepth);
  try Code := FNative.Poll(TimeoutMs); finally Dec(FDispatchDepth); end;
  Result := Code >= 0;
  if not Result then ReportError(Code, 'SIP Poll failed');
  if FStopPending then Stop;
end;

procedure TAISIPBase.SetActive(Value: Boolean);
begin
  if csDesigning in ComponentState then begin FActive := Value; Exit; end;
  if csLoading in ComponentState then begin FActive := Value; Exit; end;
  if Value then Start else Stop;
end;

procedure TAISIPBase.Loaded;
begin
  inherited Loaded;
  if FActive and not (csDesigning in ComponentState) then
  begin FActive := False; Start; end;
end;

function TAISIPBase.GetLocalPort: Integer;
begin
  Result := 0;
  if FContext <> nil then Result := FNative.LocalPort(FContext);
end;

procedure TAISIPBase.ReportError(Code: Integer; const Message: string);
begin
  SetError(Message);
  if Assigned(FOnError) then FOnError(Self, Code, Message);
end;

function TAISIPBase.CheckResult(Code: Integer; const Operation: string): Boolean;
begin
  Result := Code = 0;
  if Result then ClearError
  else ReportError(Code, Operation + ' failed (' + IntToStr(Code) + ')');
end;

function TAISIPBase.RequireActive: Boolean;
begin
  Result := FContext <> nil;
  if not Result then ReportError(-1, 'SIP component is not active');
end;

function TAISIPBase.DoRegistration(Enable: Boolean): Boolean;
begin
  Result := CheckResult(FNative.RegisterAccount(FContext, Ord(Enable)), 'Registration');
end;

function TAISIPBase.Call(const Destination: string; out CallID: TAISIPCallID): Boolean;
begin
  CallID := 0; Result := False;
  if RequireActive then
    Result := CheckResult(FNative.MakeCall(FContext, PAnsiChar(Destination), CallID), 'Call');
end;

function TAISIPBase.Answer(CallID: TAISIPCallID): Boolean;
begin
  Result := RequireActive;
  if Result then Result := CheckResult(FNative.Answer(FContext, CallID, 200), 'Answer');
end;

function TAISIPBase.Ring(CallID: TAISIPCallID): Boolean;
begin
  Result := RequireActive;
  if Result then Result := CheckResult(FNative.Answer(FContext, CallID, 180), 'Ring');
end;

function TAISIPBase.Reject(CallID: TAISIPCallID; StatusCode: Integer): Boolean;
begin
  Result := False;
  if (StatusCode < 400) or (StatusCode > 699) then
  begin ReportError(-1, 'Rejection status must be 400..699'); Exit; end;
  if RequireActive then
    Result := CheckResult(FNative.Hangup(FContext, CallID, StatusCode), 'Reject');
end;

function TAISIPBase.Hangup(CallID: TAISIPCallID): Boolean;
begin
  Result := RequireActive;
  if Result then Result := CheckResult(FNative.Hangup(FContext, CallID, 0), 'Hangup');
end;

function TAISIPBase.SendDTMF(CallID: TAISIPCallID; const Digits: string): Boolean;
begin
  Result := RequireActive;
  if Result then Result := CheckResult(FNative.SendDTMF(FContext, CallID,
    PAnsiChar(Digits)), 'SendDTMF');
end;

function TAISIPBase.WriteAudio(CallID: TAISIPCallID;
  const Samples: TAISIPAudioSamples): Integer;
begin
  Result := -1;
  if not RequireActive then Exit;
  if Length(Samples) = 0 then Exit(0);
  Result := FNative.WriteAudio(FContext, CallID, @Samples[0], Length(Samples));
  if Result < 0 then ReportError(Result, 'PCM audio queue is full or call has no media');
end;

function TAISIPBase.LookupCredential(const UserName, Realm, Remote: string;
  out Secret: string; out Kind: TAISIPCredentialKind): Boolean;
begin Secret := ''; Kind := skPassword; Result := False; end;

function TAISIPBase.Authorize(const Operation, UserName, Target, Remote: string): Boolean;
begin Result := False; end;

function TAISIPBase.Route(CallID: TAISIPCallID; const Caller, Target: string;
  out Destination: string): TAISIPRouteAction;
begin Destination := ''; Result := srDeny; end;

procedure TAISIPBase.HandleEvent(Event: Integer; CallID: TAISIPCallID;
  Status, Value: Integer; const Detail, Remote: string);
begin
  case Event of
    ASIP_INCOMING:
      if Assigned(FOnIncomingCall) then FOnIncomingCall(Self, CallID, Detail, Remote);
    ASIP_CALL_STATE:
      if (Value >= 1) and (Value <= 6) and Assigned(FOnCallStateChanged) then
        FOnCallStateChanged(Self, CallID, TAISIPCallState(Value - 1), Status, Detail);
    ASIP_DTMF:
      if Assigned(FOnDTMF) then FOnDTMF(Self, CallID, Detail, Value);
    ASIP_AUDIO_DROPPED:
      if Assigned(FOnAudioOverflow) then FOnAudioOverflow(Self, CallID, Value);
    ASIP_ERROR: ReportError(Status, Detail);
  end;
end;
end.
