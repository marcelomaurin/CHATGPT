unit aiwebrtc_libdatachannel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dynlibs;

const
  RTC_ERR_SUCCESS   = 0;
  RTC_ERR_INVALID   = -1;
  RTC_ERR_FAILURE   = -2;
  RTC_ERR_NOT_AVAIL = -3;
  RTC_ERR_TOO_SMALL = -4;

type
  TrtcState = (RTC_NEW, RTC_CONNECTING, RTC_CONNECTED, RTC_DISCONNECTED, RTC_FAILED, RTC_CLOSED);
  TrtcDescriptionCallback = procedure(pc: Integer; sdp, descType: PAnsiChar; userPtr: Pointer); cdecl;
  TrtcCandidateCallback = procedure(pc: Integer; candidate, mid: PAnsiChar; userPtr: Pointer); cdecl;
  TrtcStateChangeCallback = procedure(pc: Integer; state: TrtcState; userPtr: Pointer); cdecl;
  TrtcDataChannelCallback = procedure(pc, dc: Integer; userPtr: Pointer); cdecl;
  TrtcOpenCallback = procedure(id: Integer; userPtr: Pointer); cdecl;
  TrtcClosedCallback = procedure(id: Integer; userPtr: Pointer); cdecl;
  TrtcErrorCallback = procedure(id: Integer; error: PAnsiChar; userPtr: Pointer); cdecl;
  TrtcMessageCallback = procedure(id: Integer; message: PAnsiChar; size: Integer; userPtr: Pointer); cdecl;

  TrtcConfiguration = packed record
    iceServers: PPAnsiChar;
    iceServersCount: Integer;
    proxyServer: PAnsiChar;
    bindAddress: PAnsiChar;
    certificateType: Integer;
    certificatePemFile: PAnsiChar;
    keyPemFile: PAnsiChar;
    keyPemPass: PAnsiChar;
    iceTransportPolicy: Integer;
    enableIceTcp: Boolean;
    enableIceUdpMux: Boolean;
    disableAutoNegotiation: Boolean;
    forceMediaTransport: Boolean;
    portRangeBegin: Word;
    portRangeEnd: Word;
    mtu: Integer;
    maxMessageSize: Integer;
    disableFingerprintVerification: Boolean;
  end;
  PrtcConfiguration = ^TrtcConfiguration;

var
  rtcCreatePeerConnection: function(config: PrtcConfiguration): Integer; cdecl;
  rtcClosePeerConnection: function(pc: Integer): Integer; cdecl;
  rtcDeletePeerConnection: function(pc: Integer): Integer; cdecl;
  rtcSetUserPointer: procedure(id: Integer; userPtr: Pointer); cdecl;
  rtcSetLocalDescriptionCallback: function(pc: Integer; cb: TrtcDescriptionCallback): Integer; cdecl;
  rtcSetLocalCandidateCallback: function(pc: Integer; cb: TrtcCandidateCallback): Integer; cdecl;
  rtcSetStateChangeCallback: function(pc: Integer; cb: TrtcStateChangeCallback): Integer; cdecl;
  rtcSetDataChannelCallback: function(pc: Integer; cb: TrtcDataChannelCallback): Integer; cdecl;
  rtcSetRemoteDescription: function(pc: Integer; sdp, descType: PAnsiChar): Integer; cdecl;
  rtcAddRemoteCandidate: function(pc: Integer; candidate, mid: PAnsiChar): Integer; cdecl;
  rtcCreateDataChannel: function(pc: Integer; labelText: PAnsiChar): Integer; cdecl;
  rtcSetOpenCallback: function(id: Integer; cb: TrtcOpenCallback): Integer; cdecl;
  rtcSetClosedCallback: function(id: Integer; cb: TrtcClosedCallback): Integer; cdecl;
  rtcSetErrorCallback: function(id: Integer; cb: TrtcErrorCallback): Integer; cdecl;
  rtcSetMessageCallback: function(id: Integer; cb: TrtcMessageCallback): Integer; cdecl;
  rtcSendMessage: function(id: Integer; data: PAnsiChar; size: Integer): Integer; cdecl;
  rtcClose: function(id: Integer): Integer; cdecl;
  rtcDelete: function(id: Integer): Integer; cdecl;
  rtcCleanup: procedure; cdecl;

function LoadLibDataChannel(const ALibraryFile: string): Boolean;
procedure UnloadLibDataChannel;
function LibDataChannelLoaded: Boolean;
function DefaultLibDataChannelName: string;

implementation

var
  GLib: TLibHandle = dynlibs.NilHandle;

function DefaultLibDataChannelName: string;
begin
  {$IFDEF MSWINDOWS}
  Result := 'datachannel.dll';
  {$ELSEIF Defined(DARWIN)}
  Result := 'libdatachannel.dylib';
  {$ELSE}
  Result := 'libdatachannel.so';
  {$ENDIF}
end;

function Sym(const N: PChar): Pointer;
begin
  Result := GetProcedureAddress(GLib, N);
end;

function LoadLibDataChannel(const ALibraryFile: string): Boolean;
var F: string;
begin
  if GLib <> dynlibs.NilHandle then Exit(True);
  F := ALibraryFile;
  if F = '' then F := DefaultLibDataChannelName;
  GLib := LoadLibrary(F);
  if GLib = dynlibs.NilHandle then Exit(False);

  Pointer(rtcCreatePeerConnection) := Sym('rtcCreatePeerConnection');
  Pointer(rtcClosePeerConnection) := Sym('rtcClosePeerConnection');
  Pointer(rtcDeletePeerConnection) := Sym('rtcDeletePeerConnection');
  Pointer(rtcSetUserPointer) := Sym('rtcSetUserPointer');
  Pointer(rtcSetLocalDescriptionCallback) := Sym('rtcSetLocalDescriptionCallback');
  Pointer(rtcSetLocalCandidateCallback) := Sym('rtcSetLocalCandidateCallback');
  Pointer(rtcSetStateChangeCallback) := Sym('rtcSetStateChangeCallback');
  Pointer(rtcSetDataChannelCallback) := Sym('rtcSetDataChannelCallback');
  Pointer(rtcSetRemoteDescription) := Sym('rtcSetRemoteDescription');
  Pointer(rtcAddRemoteCandidate) := Sym('rtcAddRemoteCandidate');
  Pointer(rtcCreateDataChannel) := Sym('rtcCreateDataChannel');
  Pointer(rtcSetOpenCallback) := Sym('rtcSetOpenCallback');
  Pointer(rtcSetClosedCallback) := Sym('rtcSetClosedCallback');
  Pointer(rtcSetErrorCallback) := Sym('rtcSetErrorCallback');
  Pointer(rtcSetMessageCallback) := Sym('rtcSetMessageCallback');
  Pointer(rtcSendMessage) := Sym('rtcSendMessage');
  Pointer(rtcClose) := Sym('rtcClose');
  Pointer(rtcDelete) := Sym('rtcDelete');
  Pointer(rtcCleanup) := Sym('rtcCleanup');

  Result := Assigned(rtcCreatePeerConnection) and Assigned(rtcDeletePeerConnection) and
            Assigned(rtcCreateDataChannel) and Assigned(rtcSendMessage) and
            Assigned(rtcSetRemoteDescription);
  if not Result then UnloadLibDataChannel;
end;

procedure UnloadLibDataChannel;
begin
  if GLib = dynlibs.NilHandle then Exit;
  if Assigned(rtcCleanup) then rtcCleanup;
  UnloadLibrary(GLib);
  GLib := dynlibs.NilHandle;
end;

function LibDataChannelLoaded: Boolean;
begin
  Result := GLib <> dynlibs.NilHandle;
end;

finalization
  UnloadLibDataChannel;
end.
