program test_virtualserial_backend;
{$mode objfpc}{$H+}
uses Classes, SysUtils, aivirtualserialpair;
type
  TFakeBackend = class(TAIVirtualSerialPair)
  public
    Calls: Integer;
    Installed, FailInstall, MissingAfterInstall: Boolean;
    function Run(const Args: array of string): Boolean; override;
  end;
function TFakeBackend.Run(const Args: array of string): Boolean;
begin
  Inc(Calls); Result := True;
  if Args[0]='list' then begin
    if Installed and not MissingAfterInstall then
      SetBackendOutput('CNCA0 PortName=COM41'+#10+'CNCB0 PortName=COM42')
    else SetBackendOutput('CNCA1 PortName=COM410'+#10+'CNCB1 PortName=COM420');
  end else if Args[0]='install' then begin
    Result := not FailInstall; Installed := Result;
    if not Result then SetError('Backend failure');
  end else raise Exception.Create('Unexpected backend command');
end;
procedure Check(B: Boolean; const Msg: string);
begin if not B then raise Exception.Create(Msg); end;
var B: TFakeBackend;
begin
  B := TFakeBackend.Create(nil);
  try
    Check(B.CreatePair('COM41','COM42'),'Create and verify');
    Check(B.Calls=3,'List/install/list');
    Check(not B.CreatePair('COM41','COM42'),'No duplicate pair');
    Check(B.Calls=4,'Duplicate must not invoke install');
    B.Installed:=False; B.FailInstall:=True;
    Check(not B.CreatePair('COM41','COM42'),'Propagate backend failure');
    B.FailInstall:=False; B.MissingAfterInstall:=True;
    Check(not B.CreatePair('COM41','COM42'),'Verify claimed creation');
    Writeln('PASS virtual serial backend: verify, duplicates, failure, false success');
  finally B.Free; end;
end.
