unit aiaudio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Math, ExtCtrls,
  {$IFDEF MSWINDOWS}mmsystem,{$ENDIF}
  Dialogs, LResources;

type
  TAIAudioSource = (asMic, asSystemMix, asWavFile, asMp3File);
  TAIAudioLevelEvent = procedure(Sender: TObject; ALevel: Double) of object;

  TAIAudioInput = class(TComponent)
  private
    FPrompt: string;
    FInputSource: TAIAudioSource;
    FSampleRate, FChannels, FDurationLimit: Integer;
    FRecording: Boolean;
    FProcess: TProcess;
    FLastError, FOutputWavFile: string;
    FMonitorTimer: TTimer;
    FMonitorInterval: Integer;
    FOnAudioLevel: TAIAudioLevelEvent;
    function CommandExists(const ACommand: string): Boolean;
    procedure MonitorTick(Sender: TObject);
    function ReadCurrentLevel: Double;
    procedure SetMonitorInterval(AValue: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function StartRecord(const AOutputWavFile: string): Boolean;
    procedure StopRecord;
    function MixAudio(const AFileA, AFileB, AOutFile: string): Boolean;
    function ValidateWavFile(const AFileName: string; out AError: string): Boolean;
    property OutputWavFile: string read FOutputWavFile;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Recording: Boolean read FRecording;
    property InputSource: TAIAudioSource read FInputSource write FInputSource default asMic;
    property SampleRate: Integer read FSampleRate write FSampleRate default 44100;
    property Channels: Integer read FChannels write FChannels default 2;
    property DurationLimit: Integer read FDurationLimit write FDurationLimit default 0;
    property MonitorInterval: Integer read FMonitorInterval write SetMonitorInterval default 50;
    property OnAudioLevel: TAIAudioLevelEvent read FOnAudioLevel write FOnAudioLevel;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIAudioInput]);
end;

constructor TAIAudioInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Captura audio e publica nivel RMS durante a gravacao para VAD.';
  FInputSource := asMic; FSampleRate := 44100; FChannels := 2; FDurationLimit := 0;
  FRecording := False; FProcess := nil; FLastError := ''; FOutputWavFile := '';
  FMonitorInterval := 50;
  FMonitorTimer := TTimer.Create(Self);
  FMonitorTimer.Enabled := False;
  FMonitorTimer.Interval := FMonitorInterval;
  FMonitorTimer.OnTimer := @MonitorTick;
end;

destructor TAIAudioInput.Destroy;
begin
  StopRecord;
  inherited Destroy;
end;

procedure TAIAudioInput.SetMonitorInterval(AValue: Integer);
begin
  if AValue < 20 then AValue := 20;
  FMonitorInterval := AValue;
  FMonitorTimer.Interval := AValue;
end;

function TAIAudioInput.CommandExists(const ACommand: string): Boolean;
begin
  Result := (FileSearch(ACommand, GetEnvironmentVariable('PATH')) <> '') or FileExists(ACommand);
end;

procedure TAIAudioInput.MonitorTick(Sender: TObject);
var L: Double;
begin
  if not FRecording or not Assigned(FOnAudioLevel) then Exit;
  L := ReadCurrentLevel;
  if L >= 0 then FOnAudioLevel(Self, L);
end;

function TAIAudioInput.ReadCurrentLevel: Double;
{$IFDEF MSWINDOWS}
var V: LongInt;
{$ENDIF}
begin
  Result := -1;
  {$IFDEF MSWINDOWS}
  { MCI waveaudio exposes the current input level through status level.
    The value is normalized for the listener (0..1). }
  V := 0;
  if mciSendString('status mydevice level', PChar(@V), SizeOf(V), 0) = 0 then
    Result := EnsureRange(V / 1000.0, 0.0, 1.0);
  {$ELSE}
  { ALSA arecord does not expose RMS through its process interface. The streaming
    backend will be added independently; keeping -1 avoids false VAD events. }
  Result := -1;
  {$ENDIF}
end;

function TAIAudioInput.StartRecord(const AOutputWavFile: string): Boolean;
{$IFDEF MSWINDOWS}
var MciCommand: string; MciError: Cardinal; Buffer: array[0..255] of Char;
    BlockAlign, BytesPerSec: Integer;
{$ENDIF}
begin
  Result := False; FLastError := '';
  if FRecording then Exit;
  FOutputWavFile := Trim(AOutputWavFile);
  if FOutputWavFile = '' then begin FLastError := 'Output WAV file is required.'; Exit(False); end;
  if ExtractFilePath(FOutputWavFile) <> '' then ForceDirectories(ExtractFilePath(FOutputWavFile));
  {$IFDEF MSWINDOWS}
  mciSendString('close mydevice', nil, 0, 0);
  MciError := mciSendString('open new type waveaudio alias mydevice', nil, 0, 0);
  if MciError <> 0 then begin mciGetErrorString(MciError, Buffer, SizeOf(Buffer)); FLastError := 'MCI Open Error: '+string(Buffer); Exit; end;
  BlockAlign := FChannels * 2; BytesPerSec := FSampleRate * BlockAlign;
  MciCommand := Format('set mydevice bitspersample 16 samplespersec %d channels %d bytespersec %d alignment %d',[FSampleRate,FChannels,BytesPerSec,BlockAlign]);
  mciSendString(PChar(MciCommand), nil, 0, 0);
  MciError := mciSendString('record mydevice', nil, 0, 0);
  if MciError <> 0 then begin mciGetErrorString(MciError, Buffer, SizeOf(Buffer)); FLastError := 'MCI Record Error: '+string(Buffer); mciSendString('close mydevice',nil,0,0); Exit; end;
  FRecording := True; FMonitorTimer.Enabled := True; Result := True;
  {$ELSE}
  if not CommandExists('arecord') then begin FLastError := 'ALSA arecord was not found. Install alsa-utils.'; Exit(False); end;
  FProcess := TProcess.Create(nil);
  try
    FProcess.Executable := 'arecord'; FProcess.Parameters.Add('-f'); FProcess.Parameters.Add('S16_LE');
    FProcess.Parameters.Add('-r'); FProcess.Parameters.Add(IntToStr(FSampleRate));
    FProcess.Parameters.Add('-c'); FProcess.Parameters.Add(IntToStr(FChannels));
    if FDurationLimit > 0 then begin FProcess.Parameters.Add('-d'); FProcess.Parameters.Add(IntToStr(FDurationLimit)); end;
    FProcess.Parameters.Add(FOutputWavFile); FProcess.Options := [poUsePipes]; FProcess.Execute;
    FRecording := True; FMonitorTimer.Enabled := True; Result := True;
  except on E: Exception do begin FLastError := 'ALSA arecord executing failed: '+E.Message; FreeAndNil(FProcess); end; end;
  {$ENDIF}
end;

procedure TAIAudioInput.StopRecord;
{$IFDEF MSWINDOWS}
var MciError: Cardinal; Buffer: array[0..255] of Char; MciCommand: string;
{$ENDIF}
begin
  if not FRecording then Exit;
  FMonitorTimer.Enabled := False;
  {$IFDEF MSWINDOWS}
  mciSendString('stop mydevice',nil,0,0); MciCommand := 'save mydevice "'+FOutputWavFile+'"';
  MciError := mciSendString(PChar(MciCommand),nil,0,0);
  if MciError <> 0 then begin mciGetErrorString(MciError,Buffer,SizeOf(Buffer)); FLastError := 'MCI Save Error: '+string(Buffer); end;
  mciSendString('close mydevice',nil,0,0);
  {$ELSE}
  if Assigned(FProcess) then begin try FProcess.Terminate(0); finally FreeAndNil(FProcess); end; end;
  {$ENDIF}
  FRecording := False;
end;

function TAIAudioInput.MixAudio(const AFileA,AFileB,AOutFile:string):Boolean;
var A,B,O:TFileStream; H:array[0..43] of Byte; SA,SB,SM:SmallInt; RA,RB:Integer;
begin
  Result:=False; FLastError:='';
  try A:=TFileStream.Create(AFileA,fmOpenRead or fmShareDenyNone); try B:=TFileStream.Create(AFileB,fmOpenRead or fmShareDenyNone); try O:=TFileStream.Create(AOutFile,fmCreate); try
    A.Read(H,44); B.Seek(44,soBeginning); O.Write(H,44);
    while (A.Position<A.Size) and (B.Position<B.Size) do begin RA:=A.Read(SA,2); RB:=B.Read(SB,2); if (RA=2) and (RB=2) then begin SM:=EnsureRange(Integer(SA)+Integer(SB),-32768,32767); O.Write(SM,2); end; end; Result:=True;
  finally O.Free; end; finally B.Free; end; finally A.Free; end;
  except on E:Exception do begin FLastError:='Mix WAV Audio Failed: '+E.Message; Result:=False; end; end;
end;

function TAIAudioInput.ValidateWavFile(const AFileName:string; out AError:string):Boolean;
var FS:TFileStream; H:array[0..11] of AnsiChar;
begin
  Result:=False; AError:=''; if not FileExists(AFileName) then begin AError:='WAV file does not exist.'; Exit; end;
  try FS:=TFileStream.Create(AFileName,fmOpenRead or fmShareDenyNone); try
    if FS.Size<44 then begin AError:='WAV file is too small.'; Exit; end; FS.Read(H,12);
    if (H[0]<>'R') or (H[1]<>'I') or (H[2]<>'F') or (H[3]<>'F') then begin AError:='Invalid WAV header: RIFF not found.'; Exit; end;
    if (H[8]<>'W') or (H[9]<>'A') or (H[10]<>'V') or (H[11]<>'E') then begin AError:='Invalid WAV header: WAVE not found.'; Exit; end; Result:=True;
  finally FS.Free; end; except on E:Exception do AError:='Error reading WAV file: '+E.Message; end;
end;

initialization
  {$I aiaudio_icon.lrs}
end.
