unit aiprocessrunner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, pipes;

type
  TAIProcessRunner = class(TComponent)
  private
    FExecutable: string;
    FWorkingDirectory: string;
    FTimeoutMs: Integer;
    FLastExitCode: Integer;
    FStdOutText: string;
    FStdErrText: string;
    FLastError: string;
    FCancelRequested: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    function Execute(const AParams: array of string): Boolean;
    procedure Stop;
    property LastExitCode: Integer read FLastExitCode;
    property StdOutText: string read FStdOutText;
    property StdErrText: string read FStdErrText;
    property LastError: string read FLastError;
  published
    property Executable: string read FExecutable write FExecutable;
    property WorkingDirectory: string read FWorkingDirectory write FWorkingDirectory;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 120000;
  end;

implementation

constructor TAIProcessRunner.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FExecutable := '';
  FWorkingDirectory := '';
  FTimeoutMs := 120000;
  FLastExitCode := -1;
  FStdOutText := '';
  FStdErrText := '';
  FLastError := '';
  FCancelRequested := False;
end;

procedure TAIProcessRunner.Stop;
begin
  FCancelRequested := True;
end;

function TAIProcessRunner.Execute(const AParams: array of string): Boolean;
var
  P: TProcess;
  I: Integer;
  StartTick: QWord;
  Buffer: array[0..2047] of Byte;
  BytesRead: Integer;
  S: string;

  procedure ReadPipe(AStream: TInputPipeStream; var AText: string);
  begin
    while AStream.NumBytesAvailable > 0 do
    begin
      BytesRead := AStream.Read(Buffer, SizeOf(Buffer));
      if BytesRead > 0 then
      begin
        SetString(S, PAnsiChar(@Buffer[0]), BytesRead);
        AText := AText + S;
      end;
    end;
  end;

begin
  Result := False;
  FLastError := '';
  FStdOutText := '';
  FStdErrText := '';
  FLastExitCode := -1;
  FCancelRequested := False;

  if Trim(FExecutable) = '' then
  begin
    FLastError := 'Executable is empty.';
    Exit;
  end;

  P := TProcess.Create(nil);
  try
    P.Executable := FExecutable;
    if FWorkingDirectory <> '' then
      P.CurrentDirectory := FWorkingDirectory;

    for I := Low(AParams) to High(AParams) do
      P.Parameters.Add(AParams[I]);

    P.Options := [poUsePipes, poNoConsole];
    StartTick := GetTickCount64;

    try
      P.Execute;
    except
      on E: Exception do
      begin
        FLastError := 'Process execute failed: ' + E.Message;
        Exit;
      end;
    end;

    while P.Running do
    begin
      ReadPipe(P.Output, FStdOutText);
      ReadPipe(P.Stderr, FStdErrText);

      if FCancelRequested then
      begin
        P.Terminate(1);
        FLastError := 'Process canceled.';
        Exit;
      end;

      if (FTimeoutMs > 0) and ((GetTickCount64 - StartTick) > QWord(FTimeoutMs)) then
      begin
        P.Terminate(1);
        FLastError := 'Process timeout.';
        Exit;
      end;

      Sleep(10);
    end;

    ReadPipe(P.Output, FStdOutText);
    ReadPipe(P.Stderr, FStdErrText);

    FLastExitCode := P.ExitStatus;
    Result := FLastExitCode = 0;
    if not Result then
      FLastError := 'Process failed. ExitCode=' + IntToStr(FLastExitCode) + ' ' + Trim(FStdErrText);
  finally
    P.Free;
  end;
end;

end.
