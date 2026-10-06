unit aivirtualserialpair;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, aibase, aiprocessrunner;
type
  { Manages an installed com0com backend. Does not install a kernel driver,
    request elevation, change signing settings or emulate a USB device. }
  TAIVirtualSerialPair = class(TAIBaseComponent)
  private
    FSetupExecutable, FLastOutput: string;
    FRunner: TAIProcessRunner;
  protected
    function Run(const Args: array of string): Boolean; virtual;
    procedure SetBackendOutput(const Text: string);
  public
    constructor Create(AOwner: TComponent); override;
    class function ValidPortName(const PortName: string): Boolean; static;
    class function OutputHasPort(const Text, PortName: string): Boolean; static;
    class function BuildCreateArguments(const PortA, PortB: string;
      Arguments: TStrings; out ErrorText: string): Boolean; static;
    function BackendAvailable: Boolean;
    function ListPairs: Boolean;
    function CreatePair(const PortA, PortB: string): Boolean;
    property LastOutput: string read FLastOutput;
  published
    property SetupExecutable: string read FSetupExecutable write FSetupExecutable;
  end;
implementation
constructor TAIVirtualSerialPair.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FCategory := ccInput;
  FPrompt := 'Manage virtual COM pairs using an installed com0com setupc executable. Explicit CreatePair only; no automatic driver installation.';
  FRunner := TAIProcessRunner.Create(Self); FRunner.TimeoutMs := 30000;
end;
class function TAIVirtualSerialPair.ValidPortName(const PortName: string): Boolean;
var N,I: Integer;
begin
  Result := False;
  if (Length(PortName) < 4) or (UpperCase(Copy(PortName,1,3)) <> 'COM') then Exit;
  for I := 4 to Length(PortName) do if not (PortName[I] in ['0'..'9']) then Exit;
  if not TryStrToInt(Copy(PortName,4,MaxInt),N) then Exit;
  Result := (N >= 1) and (N <= 4096) and (Copy(PortName,4,MaxInt) = IntToStr(N));
end;
class function TAIVirtualSerialPair.BuildCreateArguments(const PortA, PortB: string;
  Arguments: TStrings; out ErrorText: string): Boolean;
begin
  Result := False; Arguments.Clear; ErrorText := '';
  if not ValidPortName(PortA) or not ValidPortName(PortB) then begin
    ErrorText := 'Use canonical COM names between COM1 and COM4096'; Exit;
  end;
  if SameText(PortA,PortB) then begin ErrorText := 'Ports must be different'; Exit; end;
  Arguments.Add('install'); Arguments.Add('PortName='+UpperCase(PortA));
  Arguments.Add('PortName='+UpperCase(PortB)); Result := True;
end;
function TAIVirtualSerialPair.BackendAvailable: Boolean;
begin Result := (FSetupExecutable <> '') and FileExists(FSetupExecutable); end;
function TAIVirtualSerialPair.Run(const Args: array of string): Boolean;
begin
  ClearError; FLastOutput := ''; Result := False;
  {$IFNDEF MSWINDOWS}
  SetError('This backend requires Windows and com0com'); Exit;
  {$ENDIF}
  if not BackendAvailable then begin SetError('Select the installed com0com setupc.exe'); Exit; end;
  FRunner.Executable := FSetupExecutable;
  Result := FRunner.Execute(Args);
  FLastOutput := FRunner.StdOutText + FRunner.StdErrText;
  if not Result then SetError(FRunner.LastError);
end;
function TAIVirtualSerialPair.ListPairs: Boolean;
begin Result := Run(['list']); end;
procedure TAIVirtualSerialPair.SetBackendOutput(const Text: string);
begin FLastOutput := Text; end;
class function TAIVirtualSerialPair.OutputHasPort(const Text, PortName: string): Boolean;
var S, Token: string; P,I: Integer;
begin
  Result := False; S := UpperCase(Text);
  repeat
    P := Pos('PORTNAME=',S); if P = 0 then Exit;
    Delete(S,1,P+8); I := 1;
    while (I <= Length(S)) and (S[I] in ['A'..'Z','0'..'9']) do Inc(I);
    Token := Copy(S,1,I-1);
    if SameText(Token,PortName) then Exit(True);
    Delete(S,1,I);
  until S = '';
end;
function TAIVirtualSerialPair.CreatePair(const PortA, PortB: string): Boolean;
var Args: TStringList; ErrorText: string;
begin
  Args := TStringList.Create;
  try
    if not BuildCreateArguments(PortA,PortB,Args,ErrorText) then begin
      SetError(ErrorText); Exit(False);
    end;
    if not ListPairs then Exit(False);
    if OutputHasPort(FLastOutput,PortA) or OutputHasPort(FLastOutput,PortB) then begin
      SetError('A requested port already belongs to a virtual pair'); Exit(False);
    end;
    Result := Run([Args[0],Args[1],Args[2]]);
    if not Result then Exit;
    Result := ListPairs;
    if Result then begin
      Result := OutputHasPort(FLastOutput,PortA) and OutputHasPort(FLastOutput,PortB);
      if not Result then SetError('Backend did not report both requested ports');
    end;
    // Registration is not proof the kernel driver is loaded/openable.
    // Consumers must refresh TAIListSerialDevices and open both ports to verify.
  finally Args.Free; end;
end;
end.
