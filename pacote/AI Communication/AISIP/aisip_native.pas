unit aisip_native;

{$mode objfpc}{$H+}
{$packrecords c}

interface

uses SysUtils, Dynlibs, ctypes;

const
  ASIP_ABI_VERSION = 1;
  ASIP_REG_STATE = 1;
  ASIP_REGISTRATION = 2;
  ASIP_INCOMING = 3;
  ASIP_CALL_STATE = 4;
  ASIP_DTMF = 5;
  ASIP_ERROR = 6;
  ASIP_AUTH_RESULT = 7;
  ASIP_AUDIO_DROPPED = 8;

type
  TASIPCredentialCB = function(UserData: Pointer; UserName, Realm,
    Remote: PAnsiChar; Secret: PAnsiChar; Capacity: cint;
    Kind: Pcint): cint; cdecl;
  TASIPAuthorizeCB = function(UserData: Pointer; Operation, UserName,
    Target, Remote: PAnsiChar): cint; cdecl;
  TASIPRouteCB = function(UserData: Pointer; CallID: cuint64; Caller,
    Target, Destination: PAnsiChar; Capacity: cint): cint; cdecl;
  TASIPEventCB = procedure(UserData: Pointer; Event: cint; CallID: cuint64;
    Status, Value: cint; Detail, Remote: PAnsiChar); cdecl;
  TASIPAudioCB = procedure(UserData: Pointer; CallID: cuint64;
    Samples: PSmallInt; Count, SampleRate: cint); cdecl;
  TASIPCallbacks = record
    Credential: TASIPCredentialCB;
    Authorize: TASIPAuthorizeCB;
    Route: TASIPRouteCB;
    Event: TASIPEventCB;
    Audio: TASIPAudioCB;
  end;
  PASIPCallbacks = ^TASIPCallbacks;
  TASIPConfig = record
    Size, ABIVersion: cuint32;
    Role, SIPPort, RTPPort, Expires, UseSoundDevice, DigestAlgorithm: cint;
    BindAddress, PublicAddress, UserName, Realm, Registrar, Password: PAnsiChar;
  end;
  PASIPConfig = ^TASIPConfig;
  TASIPABI = function: cint; cdecl;
  TASIPCreate = function(Config: PASIPConfig; Callbacks: PASIPCallbacks;
    UserData: Pointer; out Context: Pointer; Error: PAnsiChar;
    Capacity: cint): cint; cdecl;
  TASIPDestroy = procedure(Context: Pointer); cdecl;
  TASIPPoll = function(TimeoutMs: cint): cint; cdecl;
  TASIPRegister = function(Context: Pointer; Enable: cint): cint; cdecl;
  TASIPCall = function(Context: Pointer; Destination: PAnsiChar;
    out CallID: cuint64): cint; cdecl;
  TASIPCallAction = function(Context: Pointer; CallID: cuint64;
    Status: cint): cint; cdecl;
  TASIPDTMF = function(Context: Pointer; CallID: cuint64;
    Digits: PAnsiChar): cint; cdecl;
  TASIPWriteAudio = function(Context: Pointer; CallID: cuint64;
    Samples: PSmallInt; Count: cint): cint; cdecl;
  TASIPLocalPort = function(Context: Pointer): cint; cdecl;

  { Each component owns a reference to its library. No process-wide Pascal
    function pointers can be left dangling when another component stops. }
  TAISIPNative = class
  private
    FLibrary: TLibHandle;
    function Require(const Name: string): Pointer;
  public
    CreateContext: TASIPCreate;
    DestroyContext: TASIPDestroy;
    Poll: TASIPPoll;
    RegisterAccount: TASIPRegister;
    MakeCall: TASIPCall;
    Answer: TASIPCallAction;
    Hangup: TASIPCallAction;
    SendDTMF: TASIPDTMF;
    WriteAudio: TASIPWriteAudio;
    LocalPort: TASIPLocalPort;
    constructor Create(const LibraryFile: string);
    destructor Destroy; override;
  end;

function DefaultSIPLibraryName: string;

implementation

function DefaultSIPLibraryName: string;
begin
  {$IF Defined(MSWINDOWS)}
  Result := 'chatgpt_sip_bridge.dll';
  {$ELSEIF Defined(DARWIN)}
  Result := 'libchatgpt_sip_bridge.dylib';
  {$ELSE}
  Result := 'libchatgpt_sip_bridge.so';
  {$ENDIF}
end;

function TAISIPNative.Require(const Name: string): Pointer;
begin
  Result := GetProcedureAddress(FLibrary, Name);
  if Result = nil then
    raise Exception.Create('SIP runtime missing symbol: ' + Name);
end;

constructor TAISIPNative.Create(const LibraryFile: string);
var F: string; ABI: TASIPABI;
begin
  inherited Create;
  F := LibraryFile;
  if F = '' then F := DefaultSIPLibraryName;
  FLibrary := LoadLibrary(F);
  if FLibrary = NilHandle then
    raise Exception.Create('Cannot load SIP runtime ' + F + ': ' + GetLoadErrorStr);
  Pointer(ABI) := Require('asip_abi_version');
  if ABI() <> ASIP_ABI_VERSION then
    raise Exception.Create('Incompatible SIP runtime ABI');
  Pointer(CreateContext) := Require('asip_create');
  Pointer(DestroyContext) := Require('asip_destroy');
  Pointer(Poll) := Require('asip_poll');
  Pointer(RegisterAccount) := Require('asip_register');
  Pointer(MakeCall) := Require('asip_call');
  Pointer(Answer) := Require('asip_answer');
  Pointer(Hangup) := Require('asip_hangup');
  Pointer(SendDTMF) := Require('asip_dtmf');
  Pointer(WriteAudio) := Require('asip_write_audio');
  Pointer(LocalPort) := Require('asip_local_port');
end;

destructor TAISIPNative.Destroy;
begin
  if FLibrary <> NilHandle then UnloadLibrary(FLibrary);
  inherited Destroy;
end;
end.
