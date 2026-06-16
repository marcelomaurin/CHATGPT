unit aiaudio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Math,
  {$IFDEF MSWINDOWS}
  mmsystem,
  {$ENDIF}
  Dialogs, LResources;

type
  TAIAudioSource = (asMic, asSystemMix, asWavFile, asMp3File);

  { TAIAudioInput }

  TAIAudioInput = class(TComponent)
  private
    FPrompt: string;
    FInputSource: TAIAudioSource;
    FSampleRate: Integer;
    FChannels: Integer;
    FDurationLimit: Integer;
    FRecording: Boolean;
    FProcess: TProcess;
    FLastError: string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function StartRecord(const AOutputWavFile: string): Boolean;
    procedure StopRecord;
    function MixAudio(const AFileA, AFileB, AOutFile: string): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property InputSource: TAIAudioSource read FInputSource write FInputSource default asMic;
    property SampleRate: Integer read FSampleRate write FSampleRate default 44100;
    property Channels: Integer read FChannels write FChannels default 2;
    property DurationLimit: Integer read FDurationLimit write FDurationLimit default 0;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIAudioInput]);
end;

{ TAIAudioInput }

constructor TAIAudioInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIAudioInput records audio natively on Windows (MCI waveaudio) and Linux (ALSA arecord process). Properties: InputSource: TAIAudioSource (asMic, asSystemMix, asWavFile, asMp3File), SampleRate: Integer (default 44100), Channels: Integer (default 2, stereo). Methods: StartRecord(const AOutputWavFile: string): Boolean, StopRecord, MixAudio(const AFileA, AFileB, AOutFile: string): Boolean to mix two WAV files. AI Agent: Use this to capture speech, command inputs, or mix background sounds.';
  FInputSource := asMic;
  FSampleRate := 44100;
  FChannels := 2;
  FDurationLimit := 0;
  FRecording := False;
  FProcess := nil;
  FLastError := '';
end;

destructor TAIAudioInput.Destroy;
begin
  StopRecord;
  inherited Destroy;
end;

function TAIAudioInput.StartRecord(const AOutputWavFile: string): Boolean;
{$IFDEF MSWINDOWS}
var
  MciCommand: string;
  MciError: Cardinal;
  Buffer: array[0..255] of Char;
{$ENDIF}
begin
  Result := False;
  FLastError := '';
  if FRecording then Exit;

  {$IFDEF MSWINDOWS}
  // Windows: Native MCI Recording
  // 1. Close any previous recording
  mciSendString('close mydevice', nil, 0, 0);
  
  // 2. Open new waveaudio alias mydevice
  MciError := mciSendString('open new type waveaudio alias mydevice', nil, 0, 0);
  if MciError <> 0 then
  begin
    mciGetErrorString(MciError, Buffer, SizeOf(Buffer));
    FLastError := 'MCI Open Error: ' + string(Buffer);
    Exit;
  end;
  
  // 3. Set SampleRate and Channels
  MciCommand := Format('set mydevice bitspersample 16 samplespersec %d channels %d bytespersec %d alignment 4',
                       [FSampleRate, FChannels, FSampleRate * FChannels * 2]);
  mciSendString(PChar(MciCommand), nil, 0, 0);
  
  // 4. Start recording
  MciError := mciSendString('record mydevice', nil, 0, 0);
  if MciError <> 0 then
  begin
    mciGetErrorString(MciError, Buffer, SizeOf(Buffer));
    FLastError := 'MCI Record Error: ' + string(Buffer);
    mciSendString('close mydevice', nil, 0, 0);
    Exit;
  end;

  FRecording := True;
  Result := True;
  {$ELSE}
  // Linux: Execute arecord utilizing ALSA
  FProcess := TProcess.Create(nil);
  try
    FProcess.Executable := 'arecord';
    FProcess.Parameters.Add('-f');
    FProcess.Parameters.Add('cd'); // cd quality (16-bit stereo 44.1kHz)
    FProcess.Parameters.Add('-r');
    FProcess.Parameters.Add(IntToStr(FSampleRate));
    FProcess.Parameters.Add('-c');
    FProcess.Parameters.Add(IntToStr(FChannels));
    FProcess.Parameters.Add(AOutputWavFile);
    FProcess.Options := [poUsePipes];
    
    FProcess.Execute;
    FRecording := True;
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'ALSA arecord executing failed: ' + E.Message;
      FProcess.Free;
      FProcess := nil;
    end;
  end;
  {$ENDIF}
end;

procedure TAIAudioInput.StopRecord;
{$IFDEF MSWINDOWS}
var
  MciError: Cardinal;
  Buffer: array[0..255] of Char;
{$ENDIF}
begin
  if not FRecording then Exit;

  {$IFDEF MSWINDOWS}
  // Windows: Stop and Save MCI Recording
  mciSendString('stop mydevice', nil, 0, 0);
  MciError := mciSendString('save mydevice "output.wav"', nil, 0, 0);
  if MciError <> 0 then
  begin
    mciGetErrorString(MciError, Buffer, SizeOf(Buffer));
    FLastError := 'MCI Save Error: ' + string(Buffer);
  end;
  mciSendString('close mydevice', nil, 0, 0);
  {$ELSE}
  // Linux: Kill arecord process
  if Assigned(FProcess) then
  begin
    try
      FProcess.Terminate(0);
    finally
      FreeAndNil(FProcess);
    end;
  end;
  {$ENDIF}

  FRecording := False;
end;

// Pure Pascal WAV audio mixing implementation
function TAIAudioInput.MixAudio(const AFileA, AFileB, AOutFile: string): Boolean;
var
  StreamA, StreamB, StreamOut: TFileStream;
  HeaderA, HeaderB: array[0..43] of Byte;
  SampleA, SampleB, MixedSample: SmallInt;
  BytesReadA, BytesReadB: Integer;
  DataSize: Integer;
begin
  Result := False;
  FLastError := '';
  try
    StreamA := TFileStream.Create(AFileA, fmOpenRead or fmShareDenyNone);
    try
      StreamB := TFileStream.Create(AFileB, fmOpenRead or fmShareDenyNone);
      try
        StreamOut := TFileStream.Create(AOutFile, fmCreate);
        try
          // Read headers
          StreamA.Read(HeaderA, 44);
          StreamB.Read(HeaderB, 44);
          
          // Write default header to output (based on A)
          StreamOut.Write(HeaderA, 44);
          
          DataSize := Min(StreamA.Size, StreamB.Size) - 44;
          
          // Mix loop
          while (StreamA.Position < StreamA.Size) and (StreamB.Position < StreamB.Size) do
          begin
            BytesReadA := StreamA.Read(SampleA, 2);
            BytesReadB := StreamB.Read(SampleB, 2);
            
            if (BytesReadA = 2) and (BytesReadB = 2) then
            begin
              // Add and clip to prevent distortion
              MixedSample := EnsureRange(Integer(SampleA) + Integer(SampleB), -32768, 32767);
              StreamOut.Write(MixedSample, 2);
            end;
          end;
          Result := True;
        finally
          StreamOut.Free;
        end;
      finally
        StreamB.Free;
      end;
    finally
      StreamA.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Mix WAV Audio Failed: ' + E.Message;
      Result := False;
    end;
  end;
end;

initialization
  {$I aiaudio_icon.lrs}

end.
