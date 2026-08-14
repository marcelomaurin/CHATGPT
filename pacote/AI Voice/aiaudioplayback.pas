unit aiaudioplayback;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process,
  {$IFDEF MSWINDOWS}Windows, MMSystem,{$ENDIF}
  LResources;

type
  TAIAudioPlayer = class(TComponent)
  private
    FProcess: TProcess;
    FLastError: string;
    FPlaying: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function Play(const AFileName: string): Boolean;
    procedure Stop;
  published
    property LastError: string read FLastError;
    property Playing: Boolean read FPlaying;
  end;

procedure Register;

implementation

procedure Register;
begin RegisterComponents('AI Voice', [TAIAudioPlayer]); end;

constructor TAIAudioPlayer.Create(AOwner: TComponent);
begin inherited Create(AOwner); FProcess := nil; end;

destructor TAIAudioPlayer.Destroy;
begin Stop; FProcess.Free; inherited Destroy; end;

function TAIAudioPlayer.Play(const AFileName: string): Boolean;
begin
  Result := False; FLastError := ''; Stop;
  if not FileExists(AFileName) then begin FLastError := 'WAV nao encontrado: ' + AFileName; Exit; end;
  {$IFDEF MSWINDOWS}
  Result := sndPlaySound(PChar(AFileName), SND_ASYNC or SND_FILENAME or SND_NODEFAULT);
  if not Result then FLastError := 'Windows nao conseguiu reproduzir o WAV.';
  {$ELSE}
  FProcess := TProcess.Create(nil);
  FProcess.Executable := 'aplay'; FProcess.Parameters.Add(AFileName);
  FProcess.Options := [poNoConsole];
  try FProcess.Execute; Result := True; except on E: Exception do begin FLastError := E.Message; FreeAndNil(FProcess); end; end;
  {$ENDIF}
  FPlaying := Result;
end;

procedure TAIAudioPlayer.Stop;
begin
  {$IFDEF MSWINDOWS}
  sndPlaySound(nil, SND_ASYNC);
  {$ELSE}
  if Assigned(FProcess) then begin if FProcess.Running then FProcess.Terminate(0); FreeAndNil(FProcess); end;
  {$ENDIF}
  FPlaying := False;
end;

initialization
  {$I aiaudioplayback_icon.lrs}

end.
