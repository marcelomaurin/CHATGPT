unit aiwebrtc_client;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiwebrtc_libdatachannel;

type
  TAIWebRTCDescriptionEvent = procedure(Sender: TObject; const SDP, DescriptionType: string) of object;
  TAIWebRTCCandidateEvent = procedure(Sender: TObject; const Candidate, Mid: string) of object;
  TAIWebRTCMessageEvent = procedure(Sender: TObject; const Message: RawByteString) of object;
  TAIWebRTCStateEvent = procedure(Sender: TObject; State: TrtcState) of object;
  TAIWebRTCNotifyEvent = procedure(Sender: TObject) of object;

  TAIWebRTCClient = class(TComponent)
  private
    FPeer: Integer;
    FDataChannel: Integer;
    FRuntimeLibrary: string;
    FStunServer: string;
    FLastError: string;
    FOnLocalDescription: TAIWebRTCDescriptionEvent;
    FOnLocalCandidate: TAIWebRTCCandidateEvent;
    FOnMessage: TAIWebRTCMessageEvent;
    FOnState: TAIWebRTCStateEvent;
    FOnDataChannelOpen: TAIWebRTCNotifyEvent;
    FOnDataChannelClosed: TAIWebRTCNotifyEvent;
    FOnError: TAIWebRTCMessageEvent;
    FDestroying: Boolean;
    procedure QueueDescription(const SDP, DescriptionType: string);
    procedure QueueCandidate(const Candidate, Mid: string);
    procedure QueueState(AState: TrtcState);
    procedure QueueMessage(const S: RawByteString);
    procedure QueueOpen;
    procedure QueueClosed;
    procedure QueueError(const S: RawByteString);
    procedure SetError(const S: string);
    procedure ConfigureDataChannel(AId: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CheckDependencies: Boolean;
    function Connect: Boolean;
    procedure Disconnect;
    function CreateDataChannel(const ALabel: string = 'chatgpt'): Boolean;
    function CreateOffer: Boolean;
    function CreateAnswer: Boolean;
    function SetRemoteDescription(const SDP, DescriptionType: string): Boolean;
    function AddRemoteCandidate(const Candidate, Mid: string): Boolean;
    function SendText(const S: RawByteString): Boolean;
    property LastError: string read FLastError;
    property PeerId: Integer read FPeer;
    property DataChannelId: Integer read FDataChannel;
  published
    property RuntimeLibrary: string read FRuntimeLibrary write FRuntimeLibrary;
    property StunServer: string read FStunServer write FStunServer;
    property OnLocalDescription: TAIWebRTCDescriptionEvent read FOnLocalDescription write FOnLocalDescription;
    property OnLocalCandidate: TAIWebRTCCandidateEvent read FOnLocalCandidate write FOnLocalCandidate;
    property OnMessage: TAIWebRTCMessageEvent read FOnMessage write FOnMessage;
    property OnState: TAIWebRTCStateEvent read FOnState write FOnState;
    property OnDataChannelOpen: TAIWebRTCNotifyEvent read FOnDataChannelOpen write FOnDataChannelOpen;
    property OnDataChannelClosed: TAIWebRTCNotifyEvent read FOnDataChannelClosed write FOnDataChannelClosed;
    property OnError: TAIWebRTCMessageEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

procedure DescriptionCB(pc: Integer; sdp, descType: PAnsiChar; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueDescription(string(sdp), string(descType));
end;

procedure CandidateCB(pc: Integer; candidate, mid: PAnsiChar; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueCandidate(string(candidate), string(mid));
end;

procedure StateCB(pc: Integer; state: TrtcState; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueState(state);
end;

procedure OpenCB(id: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueOpen;
end;

procedure MessageCB(id: Integer; message: PAnsiChar; size: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient; S: RawByteString;
begin
  O := TAIWebRTCClient(userPtr);
  if not Assigned(O) then Exit;
  { libdatachannel: size >= 0 is binary payload; size < 0 is NUL-terminated text. }
  if size < 0 then
    S := RawByteString(StrPas(message))
  else begin
    SetLength(S, size);
    if size > 0 then Move(message^, S[1], size);
  end;
  O.QueueMessage(S);
end;

procedure ClosedCB(id: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin O := TAIWebRTCClient(userPtr); if Assigned(O) then O.QueueClosed; end;

procedure ErrorCB(id: Integer; error: PAnsiChar; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin O := TAIWebRTCClient(userPtr); if Assigned(O) then O.QueueError(RawByteString(StrPas(error))); end;

procedure DataChannelCB(pc, dc: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then begin
    O.FDataChannel := dc;
    O.ConfigureDataChannel(dc);
  end;
end;

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIWebRTCClient]);
end;

constructor TAIWebRTCClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPeer := -1;
  FDataChannel := -1;
  FStunServer := 'stun:stun.l.google.com:19302';
end;

destructor TAIWebRTCClient.Destroy;
begin
  FDestroying := True;
  Disconnect;
  TThread.RemoveQueuedEvents(Self);
  inherited Destroy;
end;


procedure TAIWebRTCClient.QueueDescription(const SDP, DescriptionType: string);
begin
  TThread.Queue(Self, procedure begin if (not FDestroying) and Assigned(FOnLocalDescription) then FOnLocalDescription(Self, SDP, DescriptionType); end);
end;
procedure TAIWebRTCClient.QueueCandidate(const Candidate, Mid: string);
begin
  TThread.Queue(Self, procedure begin if (not FDestroying) and Assigned(FOnLocalCandidate) then FOnLocalCandidate(Self, Candidate, Mid); end);
end;
procedure TAIWebRTCClient.QueueState(AState: TrtcState);
begin
  TThread.Queue(Self, procedure begin if (not FDestroying) and Assigned(FOnState) then FOnState(Self, AState); end);
end;
procedure TAIWebRTCClient.QueueMessage(const S: RawByteString);
begin
  TThread.Queue(Self, procedure begin if (not FDestroying) and Assigned(FOnMessage) then FOnMessage(Self, S); end);
end;
procedure TAIWebRTCClient.QueueOpen;
begin
  TThread.Queue(Self, procedure begin if (not FDestroying) and Assigned(FOnDataChannelOpen) then FOnDataChannelOpen(Self); end);
end;
procedure TAIWebRTCClient.QueueClosed;
begin
  TThread.Queue(Self, procedure begin if (not FDestroying) and Assigned(FOnDataChannelClosed) then FOnDataChannelClosed(Self); end);
end;
procedure TAIWebRTCClient.QueueError(const S: RawByteString);
begin
  TThread.Queue(Self, procedure begin if not FDestroying then begin SetError(string(S)); if Assigned(FOnError) then FOnError(Self, S); end; end);
end;

procedure TAIWebRTCClient.SetError(const S: string);
begin
  FLastError := S;
end;

function TAIWebRTCClient.CheckDependencies: Boolean;
begin
  Result := LibDataChannelLoaded or LoadLibDataChannel(FRuntimeLibrary);
  if not Result then SetError('libdatachannel runtime not found: ' + FRuntimeLibrary);
end;

function TAIWebRTCClient.Connect: Boolean;
var C: TrtcConfiguration; Server: AnsiString; Servers: array[0..0] of PAnsiChar;
begin
  Result := False;
  FLastError := '';
  if not CheckDependencies then Exit;
  FillChar(C, SizeOf(C), 0);
  Server := AnsiString(FStunServer);
  if Server <> '' then begin
    Servers[0] := PAnsiChar(Server);
    C.iceServers := @Servers[0];
    C.iceServersCount := 1;
  end;
  C.certificateType := RTC_CERTIFICATE_DEFAULT;
  C.iceTransportPolicy := RTC_TRANSPORT_POLICY_ALL;
  FPeer := rtcCreatePeerConnection(@C);
  if FPeer < 0 then begin SetError('rtcCreatePeerConnection failed: ' + IntToStr(FPeer)); Exit; end;
  rtcSetUserPointer(FPeer, Self);
  rtcSetLocalDescriptionCallback(FPeer, @DescriptionCB);
  rtcSetLocalCandidateCallback(FPeer, @CandidateCB);
  rtcSetStateChangeCallback(FPeer, @StateCB);
  rtcSetDataChannelCallback(FPeer, @DataChannelCB);
  Result := True;
end;

procedure TAIWebRTCClient.Disconnect;
begin
  if FDataChannel >= 0 then begin
    rtcClose(FDataChannel);
    rtcDelete(FDataChannel);
    FDataChannel := -1;
  end;
  if FPeer >= 0 then begin
    rtcClosePeerConnection(FPeer);
    rtcDeletePeerConnection(FPeer);
    FPeer := -1;
  end;
end;

procedure TAIWebRTCClient.ConfigureDataChannel(AId: Integer);
begin
  rtcSetUserPointer(AId, Self);
  rtcSetOpenCallback(AId, @OpenCB);
  rtcSetClosedCallback(AId, @ClosedCB);
  rtcSetErrorCallback(AId, @ErrorCB);
  rtcSetMessageCallback(AId, @MessageCB);
end;

function TAIWebRTCClient.CreateDataChannel(const ALabel: string): Boolean;
var L: AnsiString;
begin
  Result := False;
  if FPeer < 0 then begin SetError('PeerConnection is not connected.'); Exit; end;
  L := AnsiString(ALabel);
  FDataChannel := rtcCreateDataChannel(FPeer, PAnsiChar(L));
  if FDataChannel < 0 then begin SetError('rtcCreateDataChannel failed: ' + IntToStr(FDataChannel)); Exit; end;
  ConfigureDataChannel(FDataChannel);
  Result := True;
end;

function TAIWebRTCClient.CreateOffer: Boolean;
var T: AnsiString; R: Integer;
begin
  Result := False; if FPeer < 0 then begin SetError('PeerConnection is not connected.'); Exit; end;
  T := 'offer'; R := rtcSetLocalDescription(FPeer, PAnsiChar(T)); Result := R = RTC_ERR_SUCCESS;
  if not Result then SetError('rtcSetLocalDescription(offer) failed: ' + IntToStr(R));
end;

function TAIWebRTCClient.CreateAnswer: Boolean;
var T: AnsiString; R: Integer;
begin
  Result := False; if FPeer < 0 then begin SetError('PeerConnection is not connected.'); Exit; end;
  T := 'answer'; R := rtcSetLocalDescription(FPeer, PAnsiChar(T)); Result := R = RTC_ERR_SUCCESS;
  if not Result then SetError('rtcSetLocalDescription(answer) failed: ' + IntToStr(R));
end;

function TAIWebRTCClient.SetRemoteDescription(const SDP, DescriptionType: string): Boolean;
var A, T: AnsiString; R: Integer;
begin
  Result := False;
  if FPeer < 0 then begin SetError('PeerConnection is not connected.'); Exit; end;
  A := AnsiString(SDP); T := AnsiString(DescriptionType);
  R := rtcSetRemoteDescription(FPeer, PAnsiChar(A), PAnsiChar(T));
  Result := R = RTC_ERR_SUCCESS;
  if not Result then SetError('rtcSetRemoteDescription failed: ' + IntToStr(R));
end;

function TAIWebRTCClient.AddRemoteCandidate(const Candidate, Mid: string): Boolean;
var C, M: AnsiString; R: Integer;
begin
  Result := False;
  if FPeer < 0 then begin SetError('PeerConnection is not connected.'); Exit; end;
  C := AnsiString(Candidate); M := AnsiString(Mid);
  R := rtcAddRemoteCandidate(FPeer, PAnsiChar(C), PAnsiChar(M));
  Result := R = RTC_ERR_SUCCESS;
  if not Result then SetError('rtcAddRemoteCandidate failed: ' + IntToStr(R));
end;

function TAIWebRTCClient.SendText(const S: RawByteString): Boolean;
var R: Integer;
begin
  Result := False;
  if FDataChannel < 0 then begin SetError('DataChannel is not available.'); Exit; end;
  { Negative size tells libdatachannel this is a NUL-terminated text message. }
  R := rtcSendMessage(FDataChannel, PAnsiChar(S), -1);
  Result := R = RTC_ERR_SUCCESS;
  if not Result then SetError('rtcSendMessage failed: ' + IntToStr(R));
end;

end.
