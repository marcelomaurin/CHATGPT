unit aiaudioplayback;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process,
  {$IFDEF MSWINDOWS}Windows, MMSystem,{$ENDIF}
  LResources;

type
  { TAIAudioPlayer: Audio playback component supporting WAV and MP3 }
  TAIAudioPlayer = class(TComponent)
  private
    FProcess: TProcess;
    FLastError: string;
    FPlaying: Boolean;
    FUsingMCI: Boolean;
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
begin
  RegisterComponents('AI Voice', [TAIAudioPlayer]);
end;

constructor TAIAudioPlayer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProcess := nil;
  FLastError := '';
  FPlaying := False;
  FUsingMCI := False;
end;

destructor TAIAudioPlayer.Destroy;
begin
  Stop;
  if Assigned(FProcess) then
    FreeAndNil(FProcess);
  inherited Destroy;
end;

function TAIAudioPlayer.Play(const AFileName: string): Boolean;
var
  Ext: string;
  {$IFDEF MSWINDOWS}
  OpenCmd: string;
  Ret: MCIERROR;
  {$ENDIF}
begin
  Result := False;
  FLastError := '';
  Stop;

  if not FileExists(AFileName) then
  begin
    FLastError := 'Arquivo de audio nao encontrado: ' + AFileName;
    Exit;
  end;

  Ext := LowerCase(ExtractFileExt(AFileName));

  {$IFDEF MSWINDOWS}
  if (Ext = '.mp3') then
  begin
    FUsingMCI := True;
    mciSendString('close voice_playback_alias', nil, 0, 0);
    OpenCmd := 'open "' + AFileName + '" type mpegvideo alias voice_playback_alias';
    Ret := mciSendString(PChar(OpenCmd), nil, 0, 0);
    if Ret = 0 then
    begin
      Ret := mciSendString('play voice_playback_alias', nil, 0, 0);
      Result := (Ret = 0);
      if not Result then
        FLastError := Format('Falha ao reproduzir MP3 via MCI (Erro %d)', [Ret]);
    end
    else
    begin
      FLastError := Format('Falha ao abrir MP3 via MCI (Erro %d)', [Ret]);
    end;
  end
  else
  begin
    // WAV playback via sndPlaySound
    FUsingMCI := False;
    Result := sndPlaySound(PChar(AFileName), SND_ASYNC or SND_FILENAME or SND_NODEFAULT);
    if not Result then
      FLastError := 'Windows nao conseguiu reproduzir o audio WAV.';
  end;
  {$ELSE}
  FProcess := TProcess.Create(nil);
  if Ext = '.mp3' then
    FProcess.Executable := 'mpg123'
  else
    FProcess.Executable := 'aplay';

  FProcess.Parameters.Add(AFileName);
  FProcess.Options := [poNoConsole];
  try
    FProcess.Execute;
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Falha ao executar player Linux: ' + E.Message;
      FreeAndNil(FProcess);
    end;
  end;
  {$ENDIF}

  FPlaying := Result;
end;

procedure TAIAudioPlayer.Stop;
begin
  {$IFDEF MSWINDOWS}
  if FUsingMCI then
  begin
    mciSendString('stop voice_playback_alias', nil, 0, 0);
    mciSendString('close voice_playback_alias', nil, 0, 0);
    FUsingMCI := False;
  end;
  sndPlaySound(nil, SND_ASYNC);
  {$ELSE}
  if Assigned(FProcess) then
  begin
    if FProcess.Running then
      FProcess.Terminate(0);
    FreeAndNil(FProcess);
  end;
  {$ENDIF}
  FPlaying := False;
end;

initialization
  {$I aiaudioplayback_icon.lrs}

end.
