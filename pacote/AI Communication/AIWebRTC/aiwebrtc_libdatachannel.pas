unit aiwebrtc_libdatachannel;

{$mode objfpc}{$H+}
{$PACKRECORDS C}

interface

uses
  Classes, SysUtils, Dynlibs, ctypes;

const
  RTC_ERR_SUCCESS   = 0;
  RTC_ERR_INVALID   = -1;
  RTC_ERR_FAILURE   = -2;
  RTC_ERR_NOT_AVAIL = -3;
  RTC_ERR_TOO_SMALL = -4;

type
  TrtcState = (
    RTC_NEW = 0,
    RTC_CONNECTING = 1,
    RTC_CONNECTED = 2,
    RTC_DISCONNECTED = 3,
    RTC_FAILED = 4,
    RTC_CLOSED = 5
  );

  TrtcCertificateType = (
    RTC_CERTIFICATE_DEFAULT = 0,
    RTC_CERTIFICATE_ECDSA = 1,
    RTC_CERTIFICATE_RSA = 2
  );

  TrtcTransportPolicy = (
    RTC_TRANSPORT_POLICY_ALL = 0,
    RTC_TRANSPORT_POLICY_RELAY = 1
  );

  { C99 bool is one byte. Do not use Pascal Boolean in ABI records. }
  TrtcCBool = cuint8;

  TrtcDescriptionCallback = procedure(pc: cint; sdp, descType: PAnsiChar; userPtr: Pointer); cdecl;
  TrtcCandidateCallback = procedure(pc: cint; candidate, mid: PAnsiChar; userPtr: Pointer); cdecl;
  TrtcStateChangeCallback = procedure(pc: cint; state: TrtcState; userPtr: Pointer); cdecl;
  TrtcDataChannelCallback = procedure(pc, dc: cint; userPtr: Pointer); cdecl;
  TrtcOpenCallback = procedure(id: cint; userPtr: Pointer); cdecl;
  TrtcClosedCallback = procedure(id: cint; userPtr: Pointer); cdecl;
  TrtcErrorCallback = procedure(id: cint; error: PAnsiChar; userPtr: Pointer); cdecl;
  TrtcMessageCallback = procedure(id: cint; message: PAnsiChar; size: cint; userPtr: Pointer); cdecl;

  { Exact rtcConfiguration layout from libdatachannel v0.24.5 include/rtc/rtc.h. }
  TrtcConfiguration = record
    iceServers: PPAnsiChar;
    iceServersCount: cint;
    proxyServer: PAnsiChar;
    bindAddress: PAnsiChar;
    certificateType: TrtcCertificateType;
    iceTransportPolicy: TrtcTransportPolicy;
    enableIceTcp: TrtcCBool;
    enableIceUdpMux: TrtcCBool;
    disableAutoNegotiation: TrtcCBool;
    forceMediaTransport: TrtcCBool;
    portRangeBegin: cuint16;
    portRangeEnd: cuint16;
    mtu: cint;
    maxMessageSize: cint;
  end;
  PrtcConfiguration = ^TrtcConfiguration;

var
  rtcCreatePeerConnection: function(config: PrtcConfiguration): cint; cdecl;
  rtcClosePeerConnection: function(pc: cint): cint; cdecl;
  rtcDeletePeerConnection: function(pc: cint): cint; cdecl;
  rtcSetUserPointer: procedure(id: cint; userPtr: Pointer); cdecl;
  rtcGetUserPointer: function(id: cint): Pointer; cdecl;
  rtcSetLocalDescriptionCallback: function(pc: cint; cb: TrtcDescriptionCallback): cint; cdecl;
  rtcSetLocalCandidateCallback: function(pc: cint; cb: TrtcCandidateCallback): cint; cdecl;
  rtcSetStateChangeCallback: function(pc: cint; cb: TrtcStateChangeCallback): cint; cdecl;
  rtcSetDataChannelCallback: function(pc: cint; cb: TrtcDataChannelCallback): cint; cdecl;
  rtcSetLocalDescription: function(pc: cint; descType: PAnsiChar): cint; cdecl;
  rtcSetRemoteDescription: function(pc: cint; sdp, descType: PAnsiChar): cint; cdecl;
  rtcAddRemoteCandidate: function(pc: cint; candidate, mid: PAnsiChar): cint; cdecl;
  rtcCreateDataChannel: function(pc: cint; labelText: PAnsiChar): cint; cdecl;
  rtcSetOpenCallback: function(id: cint; cb: TrtcOpenCallback): cint; cdecl;
  rtcSetClosedCallback: function(id: cint; cb: TrtcClosedCallback): cint; cdecl;
  rtcSetErrorCallback: function(id: cint; cb: TrtcErrorCallback): cint; cdecl;
  rtcSetMessageCallback: function(id: cint; cb: TrtcMessageCallback): cint; cdecl;
  rtcSendMessage: function(id: cint; data: PAnsiChar; size: cint): cint; cdecl;
  rtcClose: function(id: cint): cint; cdecl;
  rtcDelete: function(id: cint): cint; cdecl;
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
var
  F: string;
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
  Pointer(rtcGetUserPointer) := Sym('rtcGetUserPointer');
  Pointer(rtcSetLocalDescriptionCallback) := Sym('rtcSetLocalDescriptionCallback');
  Pointer(rtcSetLocalCandidateCallback) := Sym('rtcSetLocalCandidateCallback');
  Pointer(rtcSetStateChangeCallback) := Sym('rtcSetStateChangeCallback');
  Pointer(rtcSetDataChannelCallback) := Sym('rtcSetDataChannelCallback');
  Pointer(rtcSetLocalDescription) := Sym('rtcSetLocalDescription');
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

  Result := Assigned(rtcCreatePeerConnection) and
            Assigned(rtcClosePeerConnection) and
            Assigned(rtcDeletePeerConnection) and
            Assigned(rtcSetUserPointer) and
            Assigned(rtcSetLocalDescriptionCallback) and
            Assigned(rtcSetLocalCandidateCallback) and
            Assigned(rtcSetStateChangeCallback) and
            Assigned(rtcSetDataChannelCallback) and
            Assigned(rtcSetLocalDescription) and
            Assigned(rtcSetRemoteDescription) and
            Assigned(rtcAddRemoteCandidate) and
            Assigned(rtcCreateDataChannel) and
            Assigned(rtcSetOpenCallback) and
            Assigned(rtcSetClosedCallback) and
            Assigned(rtcSetErrorCallback) and
            Assigned(rtcSetMessageCallback) and
            Assigned(rtcSendMessage) and
            Assigned(rtcClose) and
            Assigned(rtcDelete) and
            Assigned(rtcCleanup);
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
