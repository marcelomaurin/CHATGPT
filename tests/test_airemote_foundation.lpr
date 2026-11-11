program test_airemote_foundation;
{$mode objfpc}{$H+}
uses SysUtils, fpjson, airemoteidentity, airemotesignaling;
procedure Check(B:Boolean; const Name:string);
begin if not B then raise Exception.Create(Name); WriteLn('OK ',Name); end;
var A,B,FileName:string; C:TAIRemoteSignalingClient; R:TJSONObject;
begin
  Check(AIRemoteValidKey('0123456789'),'leading zero key');
  Check(not AIRemoteValidKey('123456789'),'short key');
  Check(not AIRemoteValidKey('123456789a'),'nonnumeric key');
  A:=AIRemoteRandomHex(32); B:=AIRemoteRandomHex(32);
  Check((Length(A)=64) and (A<>B),'system random');
  Check(Length(AIRemoteUUID)=36,'UUID');
  {$IFDEF WINDOWS}
  FileName:=GetTempDir+AIRemoteUUID+'.identity';
  try
    AIRemoteSaveSecret(FileName,A);
    Check(AIRemoteLoadSecret(FileName)=A,'DPAPI roundtrip');
    AIRemoteSaveSecret(FileName,B);
    Check(AIRemoteLoadSecret(FileName)=B,'atomic identity replacement');
  finally DeleteFile(FileName); end;
  {$ENDIF}
  C:=TAIRemoteSignalingClient.Create;
  try
    C.BaseURL:='http://example.com/v1';
    try
      R:=C.Incoming; R.Free;
      raise Exception.Create('insecure transport allowed');
    except on E:Exception do Check(E.Message='HTTPS URL required','reject insecure remote API'); end;
  finally C.Free; end;
  WriteLn('Remote foundation tests passed');
end.
