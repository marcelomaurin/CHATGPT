unit aiwebrtc_client;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiwebrtc_libdatachannel, airuntimepaths;

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

    FPendingSDP: string;
    FPendingDescType: string;
    FPendingCandidate: string;
    FPendingMid: string;
    FPendingState: TrtcState;
    FPendingMessage: RawByteString;
    FPendingError: RawByteString;

    procedure TriggerLocalDescription;
    procedure TriggerLocalCandidate;
    procedure TriggerState;
    procedure TriggerMessage;
    procedure TriggerOpen;
    procedure TriggerClosed;
    procedure TriggerError;

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

procedure StateChangeCB(pc: Integer; state: TrtcState; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueState(state);
end;

procedure DataChannelCB(pc: Integer; dc: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.ConfigureDataChannel(dc);
end;

procedure DCOpenCB(id: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueOpen;
end;

procedure DCClosedCB(id: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueClosed;
end;

procedure DCErrorCB(id: Integer; err: PAnsiChar; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) then O.QueueError(RawByteString(err));
end;

procedure DCMessageCB(id: Integer; msg: PAnsiChar; size: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient; S: RawByteString;
begin
  O := TAIWebRTCClient(userPtr);
  if not Assigned(O) then Exit;
  SetLength(S, size);
  if size > 0 then Move(msg^, S[1], size);
  O.QueueMessage(S);
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
  TThread.RemoveQueuedEvents(nil, @TriggerLocalDescription);
  TThread.RemoveQueuedEvents(nil, @TriggerLocalCandidate);
  TThread.RemoveQueuedEvents(nil, @TriggerState);
  TThread.RemoveQueuedEvents(nil, @TriggerMessage);
  TThread.RemoveQueuedEvents(nil, @TriggerOpen);
  TThread.RemoveQueuedEvents(nil, @TriggerClosed);
  TThread.RemoveQueuedEvents(nil, @TriggerError);
  inherited Destroy;
end;

procedure TAIWebRTCClient.TriggerLocalDescription;
begin
  if (not FDestroying) and Assigned(FOnLocalDescription) then
    FOnLocalDescription(Self, FPendingSDP, FPendingDescType);
end;

procedure TAIWebRTCClient.TriggerLocalCandidate;
begin
  if (not FDestroying) and Assigned(FOnLocalCandidate) then
    FOnLocalCandidate(Self, FPendingCandidate, FPendingMid);
end;

procedure TAIWebRTCClient.TriggerState;
begin
  if (not FDestroying) and Assigned(FOnState) then
    FOnState(Self, FPendingState);
end;

procedure TAIWebRTCClient.TriggerMessage;
begin
  if (not FDestroying) and Assigned(FOnMessage) then
    FOnMessage(Self, FPendingMessage);
end;

procedure TAIWebRTCClient.TriggerOpen;
begin
  if (not FDestroying) and Assigned(FOnDataChannelOpen) then
    FOnDataChannelOpen(Self);
end;

procedure TAIWebRTCClient.TriggerClosed;
begin
  if (not FDestroying) and Assigned(FOnDataChannelClosed) then
    FOnDataChannelClosed(Self);
end;

procedure TAIWebRTCClient.TriggerError;
begin
  if not FDestroying then
  begin
    SetError(string(FPendingError));
    if Assigned(FOnError) then
      FOnError(Self, FPendingError);
  end;
end;

procedure TAIWebRTCClient.QueueDescription(const SDP, DescriptionType: string);
begin
  FPendingSDP := SDP;
  FPendingDescType := DescriptionType;
  TThread.Queue(nil, @TriggerLocalDescription);
end;

procedure TAIWebRTCClient.QueueCandidate(const Candidate, Mid: string);
begin
  FPendingCandidate := Candidate;
  FPendingMid := Mid;
  TThread.Queue(nil, @TriggerLocalCandidate);
end;

procedure TAIWebRTCClient.QueueState(AState: TrtcState);
begin
  FPendingState := AState;
  TThread.Queue(nil, @TriggerState);
end;

procedure TAIWebRTCClient.QueueMessage(const S: RawByteString);
begin
  FPendingMessage := S;
  TThread.Queue(nil, @TriggerMessage);
end;

procedure TAIWebRTCClient.QueueOpen;
begin
  TThread.Queue(nil, @TriggerOpen);
end;

procedure TAIWebRTCClient.QueueClosed;
begin
  TThread.Queue(nil, @TriggerClosed);
end;

procedure TAIWebRTCClient.QueueError(const S: RawByteString);
begin
  FPendingError := S;
  TThread.Queue(nil, @TriggerError);
end;

procedure TAIWebRTCClient.SetError(const S: string);
begin
  FLastError := S;
end;

function TAIWebRTCClient.CheckDependencies: Boolean;
var Resolved: string;
begin
  Resolved := FRuntimeLibrary;
  if Resolved = '' then Resolved := AIResolveLibDataChannel;
  if Resolved = '' then Resolved := DefaultLibDataChannelName;
  Result := LibDataChannelLoaded or LoadLibDataChannel(Resolved);
  if not Result then SetError('libdatachannel runtime not found: ' + Resolved);
end;

function TAIWebRTCClient.Connect: Boolean;
var C: TrtcConfiguration; Server: AnsiString; Servers: array[0..0] of PAnsiChar;
begin
  Result := False;
  if not CheckDependencies then Exit;
  Disconnect;
  FillChar(C, SizeOf(C), 0);
  if FStunServer <> '' then
  begin
    Server := AnsiString(FStunServer);
    Servers[0] := PAnsiChar(Server);
    C.iceServers := @Servers[0];
    C.iceServersCount := 1;
  end;
  FPeer := rtcCreatePeerConnection(@C);
  if FPeer < 0 then begin SetError('rtcCreatePeerConnection failed'); Exit; end;
  rtcSetUserPointer(FPeer, Self);
  rtcSetLocalDescriptionCallback(FPeer, @DescriptionCB);
  rtcSetLocalCandidateCallback(FPeer, @CandidateCB);
  rtcSetStateChangeCallback(FPeer, @StateChangeCB);
  rtcSetDataChannelCallback(FPeer, @DataChannelCB);
  Result := True;
end;

procedure TAIWebRTCClient.Disconnect;
begin
  if FDataChannel >= 0 then begin rtcDelete(FDataChannel); FDataChannel := -1; end;
  if FPeer >= 0 then begin rtcDeletePeerConnection(FPeer); FPeer := -1; end;
end;

procedure TAIWebRTCClient.ConfigureDataChannel(AId: Integer);
begin
  FDataChannel := AId;
  rtcSetUserPointer(FDataChannel, Self);
  rtcSetOpenCallback(FDataChannel, @DCOpenCB);
  rtcSetClosedCallback(FDataChannel, @DCClosedCB);
  rtcSetErrorCallback(FDataChannel, @DCErrorCB);
  rtcSetMessageCallback(FDataChannel, @DCMessageCB);
end;

function TAIWebRTCClient.CreateDataChannel(const ALabel: string): Boolean;
var LabelA: AnsiString;
begin
  Result := False;
  if FPeer < 0 then begin SetError('Peer not connected'); Exit; end;
  LabelA := AnsiString(ALabel);
  FDataChannel := rtcCreateDataChannel(FPeer, PAnsiChar(LabelA));
  if FDataChannel < 0 then begin SetError('rtcCreateDataChannel failed'); Exit; end;
  ConfigureDataChannel(FDataChannel);
  Result := True;
end;

function TAIWebRTCClient.CreateOffer: Boolean;
begin
  Result := (FPeer >= 0) and (rtcSetLocalDescription(FPeer, nil) = 0);
  if not Result then SetError('rtcSetLocalDescription offer failed');
end;

function TAIWebRTCClient.CreateAnswer: Boolean;
begin
  Result := (FPeer >= 0) and (rtcSetLocalDescription(FPeer, 'answer') = 0);
  if not Result then SetError('rtcSetLocalDescription answer failed');
end;

function TAIWebRTCClient.SetRemoteDescription(const SDP, DescriptionType: string): Boolean;
var SDPA, TypeA: AnsiString;
begin
  Result := False;
  if FPeer < 0 then begin SetError('Peer not connected'); Exit; end;
  SDPA := AnsiString(SDP);
  TypeA := AnsiString(DescriptionType);
  Result := rtcSetRemoteDescription(FPeer, PAnsiChar(SDPA), PAnsiChar(TypeA)) = 0;
  if not Result then SetError('rtcSetRemoteDescription failed');
end;

function TAIWebRTCClient.AddRemoteCandidate(const Candidate, Mid: string): Boolean;
var CandA, MidA: AnsiString;
begin
  Result := False;
  if FPeer < 0 then begin SetError('Peer not connected'); Exit; end;
  CandA := AnsiString(Candidate);
  MidA := AnsiString(Mid);
  Result := rtcAddRemoteCandidate(FPeer, PAnsiChar(CandA), PAnsiChar(MidA)) = 0;
  if not Result then SetError('rtcAddRemoteCandidate failed');
end;

function TAIWebRTCClient.SendText(const S: RawByteString): Boolean;
begin
  Result := False;
  if FDataChannel < 0 then begin SetError('DataChannel not open'); Exit; end;
  Result := rtcSendMessage(FDataChannel, PAnsiChar(S), Length(S)) >= 0;
  if not Result then SetError('rtcSendMessage failed');
end;

end.
