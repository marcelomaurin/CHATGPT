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
    procedure SetError(const S: string);
    procedure ConfigureDataChannel(AId: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function CheckDependencies: Boolean;
    function Connect: Boolean;
    procedure Disconnect;
    function CreateDataChannel(const ALabel: string = 'chatgpt'): Boolean;
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
  end;

procedure Register;

implementation

procedure DescriptionCB(pc: Integer; sdp, descType: PAnsiChar; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) and Assigned(O.FOnLocalDescription) then
    O.FOnLocalDescription(O, string(sdp), string(descType));
end;

procedure CandidateCB(pc: Integer; candidate, mid: PAnsiChar; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) and Assigned(O.FOnLocalCandidate) then
    O.FOnLocalCandidate(O, string(candidate), string(mid));
end;

procedure StateCB(pc: Integer; state: TrtcState; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) and Assigned(O.FOnState) then O.FOnState(O, state);
end;

procedure OpenCB(id: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient;
begin
  O := TAIWebRTCClient(userPtr);
  if Assigned(O) and Assigned(O.FOnDataChannelOpen) then O.FOnDataChannelOpen(O);
end;

procedure MessageCB(id: Integer; message: PAnsiChar; size: Integer; userPtr: Pointer); cdecl;
var O: TAIWebRTCClient; S: RawByteString;
begin
  O := TAIWebRTCClient(userPtr);
  if not Assigned(O) or not Assigned(O.FOnMessage) then Exit;
  if size < 0 then
    S := RawByteString(StrPas(message))
  else begin
    SetLength(S, size);
    if size > 0 then Move(message^, S[1], size);
  end;
  O.FOnMessage(O, S);
end;

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
  Disconnect;
  inherited Destroy;
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

function TAIWebRTCClient.SetRemoteDescription(const SDP, DescriptionType: string): Boolean;
var A, T: AnsiString; R: Integer;
begin
  A := AnsiString(SDP); T := AnsiString(DescriptionType);
  R := rtcSetRemoteDescription(FPeer, PAnsiChar(A), PAnsiChar(T));
  Result := R = RTC_ERR_SUCCESS;
  if not Result then SetError('rtcSetRemoteDescription failed: ' + IntToStr(R));
end;

function TAIWebRTCClient.AddRemoteCandidate(const Candidate, Mid: string): Boolean;
var C, M: AnsiString; R: Integer;
begin
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
  R := rtcSendMessage(FDataChannel, PAnsiChar(S), Length(S));
  Result := R = RTC_ERR_SUCCESS;
  if not Result then SetError('rtcSendMessage failed: ' + IntToStr(R));
end;

end.
