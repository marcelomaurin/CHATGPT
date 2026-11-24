unit aisip_types;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils;

type
  TAISIPCallID = QWord;
  TAISIPCallState = (scCalling, scReceiving, scRinging, scConnecting,
    scConnected, scDisconnected);
  TAISIPCredentialKind = (skPassword, skMD5HA1, skSHA256HA1);
  TAISIPDigestAlgorithm = (sdMD5, sdSHA256);
  TAISIPRouteAction = (srDeny, srRoute, srAnswerLocally);
  TAISIPAudioSamples = array of SmallInt;

  TAISIPAuthenticateEvent = procedure(Sender: TObject; const UserName,
    Realm, RemoteAddress: string; var Secret: string;
    var Kind: TAISIPCredentialKind; var Found: Boolean) of object;
  TAISIPAuthorizeEvent = procedure(Sender: TObject; const UserName,
    Target, RemoteAddress: string; var Allow: Boolean) of object;
  TAISIPRouteEvent = procedure(Sender: TObject; CallID: TAISIPCallID;
    const Caller, Target: string; var Destination: string;
    var Action: TAISIPRouteAction) of object;
  TAISIPIncomingCallEvent = procedure(Sender: TObject; CallID: TAISIPCallID;
    const Caller, Target: string) of object;
  TAISIPCallStateEvent = procedure(Sender: TObject; CallID: TAISIPCallID;
    State: TAISIPCallState; StatusCode: Integer; const Reason: string) of object;
  TAISIPRegistrationStateEvent = procedure(Sender: TObject; StatusCode,
    Expires: Integer; const Reason: string) of object;
  TAISIPRegistrationEvent = procedure(Sender: TObject; const UserName,
    Contact: string; Expires, StatusCode: Integer) of object;
  TAISIPAuthenticationResultEvent = procedure(Sender: TObject;
    const UserName, RemoteAddress: string; Accepted: Boolean;
    StatusCode: Integer) of object;
  TAISIPDTMFEvent = procedure(Sender: TObject; CallID: TAISIPCallID;
    const Digit: string; DurationMs: Integer) of object;
  TAISIPAudioEvent = procedure(Sender: TObject; CallID: TAISIPCallID;
    const Samples: TAISIPAudioSamples; SampleRate: Integer) of object;
  TAISIPErrorEvent = procedure(Sender: TObject; StatusCode: Integer;
    const Message: string) of object;
  TAISIPAudioOverflowEvent = procedure(Sender: TObject; CallID: TAISIPCallID;
    DroppedFrames: Integer) of object;
  TAISIPCredentialsEvent = procedure(Sender: TObject; var UserName,
    Realm, Password: string) of object;

implementation
end.
