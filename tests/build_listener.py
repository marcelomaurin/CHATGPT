import os

listener_code = """unit aicontinuouslistener;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math,
  {$IFDEF MSWINDOWS}
  Windows, MMSystem,
  {$ENDIF}
  LResources;

type
  TAIListeningState = (
    lsStopped,
    lsListening,
    lsSpeechDetected,
    lsCapturingSpeech,
    lsWaitingSilence,
    lsProcessing,
    lsSuppressedByAssistantSpeech,
    lsError
  );

  TAudioOrigin = (
    aoUnknown,
    aoEnvironment,
    aoExternalSpeech,
    aoAssistantSpeech
  );

  TAIAudioBufferEvent = procedure(
    Sender: TObject;
    const AData: TBytes;
    ASampleRate: Integer;
    AChannels: Integer
  ) of object;

  TAISpeechUtteranceEvent = procedure(
    Sender: TObject;
    const AWavFileName: string;
    ADurationMs: Integer
  ) of object;

  TAIListeningStateEvent = procedure(
    Sender: TObject;
    AOldState, ANewState: TAIListeningState
  ) of object;

  TAIAudioRMSChangedEvent = procedure(
    Sender: TObject;
    ARMS: Double
  ) of object;

  TAIAudioOriginEvent = procedure(
    Sender: TObject;
    AOrigin: TAudioOrigin;
    AConfidence: Double
  ) of object;

  TAIContinuousListener = class;

  {$IFDEF MSWINDOWS}
  { TAIContinuousCaptureThread }
  TAIContinuousCaptureThread = class(TThread)
  private
    FOwner: TAIContinuousListener;
    FEvent: THandle;
    FWaveIn: HWAVEIN;
    FHeaders: array[0..3] of WAVEHDR;
    FBuffers: array[0..3] of array of Byte;
    FBufferSize: Integer;
    FDevOpened: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIContinuousListener; ABufferSize: Integer);
    destructor Destroy; override;
    procedure StopCapture;
  end;
  {$ENDIF}

  { TAIContinuousListener }
  TAIContinuousListener = class(TComponent)
  private
    FEnabled: Boolean;
    FContinuous: Boolean;
    FSampleRate: Integer;
    FChannels: Integer;
    FVoiceThreshold: Double;
    FSilenceThreshold: Double;
    FMinSpeechMs: Integer;
    FSilenceTimeoutMs: Integer;
    FMaxSpeechMs: Integer;
    FPreRollMs: Integer;
    FPostRollMs: Integer;
    FEchoSuppressionEnabled: Boolean;
    FSelfSpeechIgnoreMs: Integer;
    FSelfAudioCorrelationThreshold: Double;
    FSelfAudioMinEnergy: Double;
    FSelfAudioReferenceWindowMs: Integer;

    FState: TAIListeningState;
    FCurrentRMS: Double;
    FLastOrigin: TAudioOrigin;
    FLastConfidence: Double;
    FAssistantSpeaking: Boolean;
    FLastError: string;

    // Internal VAD & Accumulator state
    FConsecutiveVoiceFrames: Integer;
    FSilenceAccumMs: Integer;
    FSpeechDurationMs: Integer;
    FLastAssistantSpeakStopTime: Int64;

    // Circular Pre-roll buffer
    FPreRollBuffer: TBytes;
    FPreRollWritePos: Integer;
    FPreRollCount: Integer;
    FPreRollCapacity: Integer;

    // Speech accumulator stream
    FSpeechStream: TMemoryStream;

    // Reference ring buffer for assistant playback (echo correlation)
    FRefBuffer: array of SmallInt;
    FRefWritePos: Integer;
    FRefCount: Integer;
    FRefCapacity: Integer;

    {$IFDEF MSWINDOWS}
    FCaptureThread: TAIContinuousCaptureThread;
    {$ENDIF}

    // Events
    FOnAudioBuffer: TAIAudioBufferEvent;
    FOnSpeechUtterance: TAISpeechUtteranceEvent;
    FOnStateChanged: TAIListeningStateEvent;
    FOnRMSChanged: TAIAudioRMSChangedEvent;
    FOnAudioOriginDetected: TAIAudioOriginEvent;
    FOnBargeIn: TNotifyEvent;

    procedure SetState(ANewState: TAIListeningState);
    procedure SetEnabled(AValue: Boolean);
    procedure SetAssistantSpeaking(AValue: Boolean);
    procedure InitBuffers;
    procedure AppendToPreRoll(const ABuffer: PSmallInt; ASamples: Integer);
    procedure FlushPreRollToSpeechStream;
    function ComputeRMS(const ABuffer: PSmallInt; ASamples: Integer): Double;
    function ComputeCorrelation(const AMicSamples: PSmallInt; ASamples: Integer; out ARefRMS: Double): Double;
    function SaveSpeechStreamToWav(out AOutPath: string): Boolean;
    procedure FinalizeUtterance;
    procedure ResetVAD;
  protected
    procedure ProcessPcmFrame(const AData: PSmallInt; ASampleCount: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function StartListening: Boolean;
    procedure StopListening;
    procedure Reset;

    // Feeds assistant playback PCM for echo suppression
    procedure FeedPlaybackReference(const ASamples: PSmallInt; ACount: Integer);
    procedure FeedPlaybackWav(const AWavPath: string);
    procedure NotifyAssistantSpeechStart;
    procedure NotifyAssistantSpeechEnd;

    property State: TAIListeningState read FState;
    property CurrentRMS: Double read FCurrentRMS;
    property LastOrigin: TAudioOrigin read FLastOrigin;
    property LastConfidence: Double read FLastConfidence;
    property LastError: string read FLastError;
    property AssistantSpeaking: Boolean read FAssistantSpeaking write SetAssistantSpeaking;
  published
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property Continuous: Boolean read FContinuous write FContinuous default True;
    property SampleRate: Integer read FSampleRate write FSampleRate default 16000;
    property Channels: Integer read FChannels write FChannels default 1;
    property VoiceThreshold: Double read FVoiceThreshold write FVoiceThreshold;
    property SilenceThreshold: Double read FSilenceThreshold write FSilenceThreshold;
    property MinSpeechMs: Integer read FMinSpeechMs write FMinSpeechMs default 250;
    property SilenceTimeoutMs: Integer read FSilenceTimeoutMs write FSilenceTimeoutMs default 900;
    property MaxSpeechMs: Integer read FMaxSpeechMs write FMaxSpeechMs default 15000;
    property PreRollMs: Integer read FPreRollMs write FPreRollMs default 300;
    property PostRollMs: Integer read FPostRollMs write FPostRollMs default 250;
    property EchoSuppressionEnabled: Boolean read FEchoSuppressionEnabled write FEchoSuppressionEnabled default True;
    property SelfSpeechIgnoreMs: Integer read FSelfSpeechIgnoreMs write FSelfSpeechIgnoreMs default 400;
    property SelfAudioCorrelationThreshold: Double read FSelfAudioCorrelationThreshold write FSelfAudioCorrelationThreshold;
    property SelfAudioMinEnergy: Double read FSelfAudioMinEnergy write FSelfAudioMinEnergy;
    property SelfAudioReferenceWindowMs: Integer read FSelfAudioReferenceWindowMs write FSelfAudioReferenceWindowMs default 400;

    property OnAudioBuffer: TAIAudioBufferEvent read FOnAudioBuffer write FOnAudioBuffer;
    property OnSpeechUtterance: TAISpeechUtteranceEvent read FOnSpeechUtterance write FOnSpeechUtterance;
    property OnStateChanged: TAIListeningStateEvent read FOnStateChanged write FOnStateChanged;
    property OnRMSChanged: TAIAudioRMSChangedEvent read FOnRMSChanged write FOnRMSChanged;
    property OnAudioOriginDetected: TAIAudioOriginEvent read FOnAudioOriginDetected write FOnAudioOriginDetected;
    property OnBargeIn: TNotifyEvent read FOnBargeIn write FOnBargeIn;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Voice', [TAIContinuousListener]);
end;

{ WAV Header Helper }
type
  TWavHeader = packed record
    riff_tag: array[0..3] of AnsiChar;
    riff_size: UInt32;
    wave_tag: array[0..3] of AnsiChar;
    fmt_tag: array[0..3] of AnsiChar;
    fmt_size: UInt32;
    audio_format: UInt16;
    num_channels: UInt16;
    sample_rate: UInt32;
    byte_rate: UInt32;
    block_align: UInt16;
    bits_per_sample: UInt16;
    data_tag: array[0..3] of AnsiChar;
    data_size: UInt32;
  end;

{$IFDEF MSWINDOWS}
{ TAIContinuousCaptureThread }

constructor TAIContinuousCaptureThread.Create(AOwner: TAIContinuousListener; ABufferSize: Integer);
var
  i: Integer;
  wfx: WAVEFORMATEX;
  mmRes: MMRESULT;
begin
  inherited Create(True);
  FOwner := AOwner;
  FBufferSize := ABufferSize;
  FDevOpened := False;
  FEvent := CreateEvent(nil, False, False, nil);

  FillChar(wfx, SizeOf(wfx), 0);
  wfx.wFormatTag := WAVE_FORMAT_PCM;
  wfx.nChannels := FOwner.Channels;
  wfx.nSamplesPerSec := FOwner.SampleRate;
  wfx.wBitsPerSample := 16;
  wfx.nBlockAlign := wfx.nChannels * (wfx.wBitsPerSample div 8);
  wfx.nAvgBytesPerSec := wfx.nSamplesPerSec * wfx.nBlockAlign;
  wfx.cbSize := 0;

  mmRes := waveInOpen(@FWaveIn, WAVE_MAPPER, @wfx, DWORD_PTR(FEvent), 0, CALLBACK_EVENT);
  if mmRes <> MMSYSERR_NOERROR then
  begin
    FOwner.FLastError := Format('waveInOpen failed (error %d)', [mmRes]);
    Exit;
  end;
  FDevOpened := True;

  for i := 0 to High(FHeaders) do
  begin
    SetLength(FBuffers[i], FBufferSize);
    FillChar(FHeaders[i], SizeOf(WAVEHDR), 0);
    FHeaders[i].lpData := PAnsiChar(@FBuffers[i][0]);
    FHeaders[i].dwBufferLength := FBufferSize;
    FHeaders[i].dwUser := i;
    waveInPrepareHeader(FWaveIn, @FHeaders[i], SizeOf(WAVEHDR));
    waveInAddBuffer(FWaveIn, @FHeaders[i], SizeOf(WAVEHDR));
  end;

  waveInStart(FWaveIn);
  Start;
end;

destructor TAIContinuousCaptureThread.Destroy;
begin
  StopCapture;
  if FEvent <> 0 then
    CloseHandle(FEvent);
  inherited Destroy;
end;

procedure TAIContinuousCaptureThread.StopCapture;
var
  i: Integer;
begin
  Terminate;
  if FEvent <> 0 then
    SetEvent(FEvent);
  WaitFor;

  if FDevOpened then
  begin
    waveInReset(FWaveIn);
    for i := 0 to High(FHeaders) do
    begin
      waveInUnprepareHeader(FWaveIn, @FHeaders[i], SizeOf(WAVEHDR));
      SetLength(FBuffers[i], 0);
    end;
    waveInClose(FWaveIn);
    FDevOpened := False;
  end;
end;

procedure TAIContinuousCaptureThread.Execute;
var
  i: Integer;
  WaitRes: DWORD;
  SampleCount: Integer;
begin
  while not Terminated do
  begin
    WaitRes := WaitForSingleObject(FEvent, 100);
    if Terminated then Break;
    if WaitRes = WAIT_OBJECT_0 then
    begin
      for i := 0 to High(FHeaders) do
      begin
        if (FHeaders[i].dwFlags and WHDR_DONE) <> 0 then
        begin
          if (FHeaders[i].dwBytesRecorded > 0) and Assigned(FOwner) and (not Terminated) then
          begin
            SampleCount := FHeaders[i].dwBytesRecorded div 2;
            FOwner.ProcessPcmFrame(PSmallInt(FHeaders[i].lpData), SampleCount);
          end;
          // Re-queue buffer
          FHeaders[i].dwFlags := FHeaders[i].dwFlags and not WHDR_DONE;
          waveInAddBuffer(FWaveIn, @FHeaders[i], SizeOf(WAVEHDR));
        end;
      end;
    end;
  end;
end;
{$ENDIF}

{ TAIContinuousListener }

constructor TAIContinuousListener.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEnabled := True;
  FContinuous := True;
  FSampleRate := 16000;
  FChannels := 1;
  FVoiceThreshold := 0.015;
  FSilenceThreshold := 0.008;
  FMinSpeechMs := 250;
  FSilenceTimeoutMs := 900;
  FMaxSpeechMs := 15000;
  FPreRollMs := 300;
  FPostRollMs := 250;
  FEchoSuppressionEnabled := True;
  FSelfSpeechIgnoreMs := 400;
  FSelfAudioCorrelationThreshold := 0.70;
  FSelfAudioMinEnergy := 0.005;
  FSelfAudioReferenceWindowMs := 400;

  FState := lsStopped;
  FCurrentRMS := 0.0;
  FLastOrigin := aoUnknown;
  FLastConfidence := 0.0;
  FAssistantSpeaking := False;
  FLastError := '';

  FConsecutiveVoiceFrames := 0;
  FSilenceAccumMs := 0;
  FSpeechDurationMs := 0;
  FLastAssistantSpeakStopTime := 0;

  FSpeechStream := TMemoryStream.Create;
  InitBuffers;
end;

destructor TAIContinuousListener.Destroy;
begin
  StopListening;
  FreeAndNil(FSpeechStream);
  inherited Destroy;
end;

procedure TAIContinuousListener.InitBuffers;
begin
  FPreRollCapacity := (FSampleRate * (FPreRollMs div 1000 + 1) * 2);
  SetLength(FPreRollBuffer, FPreRollCapacity);
  FPreRollWritePos := 0;
  FPreRollCount := 0;

  FRefCapacity := FSampleRate;
  SetLength(FRefBuffer, FRefCapacity);
  FillChar(FRefBuffer[0], FRefCapacity * SizeOf(SmallInt), 0);
  FRefWritePos := 0;
  FRefCount := 0;
end;

procedure TAIContinuousListener.SetState(ANewState: TAIListeningState);
var
  OldState: TAIListeningState;
begin
  if FState <> ANewState then
  begin
    OldState := FState;
    FState := ANewState;
    if Assigned(FOnStateChanged) then
      FOnStateChanged(Self, OldState, ANewState);
  end;
end;

procedure TAIContinuousListener.SetEnabled(AValue: Boolean);
begin
  if FEnabled <> AValue then
  begin
    FEnabled := AValue;
    if FEnabled then
    begin
      if FContinuous then
        StartListening;
    end
    else
      StopListening;
  end;
end;

procedure TAIContinuousListener.SetAssistantSpeaking(AValue: Boolean);
begin
  if FAssistantSpeaking <> AValue then
  begin
    FAssistantSpeaking := AValue;
    if FAssistantSpeaking then
      NotifyAssistantSpeechStart
    else
      NotifyAssistantSpeechEnd;
  end;
end;

function TAIContinuousListener.StartListening: Boolean;
{$IFDEF MSWINDOWS}
var
  FrameBytes: Integer;
{$ENDIF}
begin
  Result := False;
  FLastError := '';
  if FState <> lsStopped then
  begin
    Result := True;
    Exit;
  end;

  ResetVAD;
  InitBuffers;

  {$IFDEF MSWINDOWS}
  FrameBytes := (FSampleRate * 50 div 1000) * 2 * FChannels;
  if FrameBytes < 512 then FrameBytes := 512;

  try
    FCaptureThread := TAIContinuousCaptureThread.Create(Self, FrameBytes);
    SetState(lsListening);
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Falha ao iniciar captura de audio: ' + E.Message;
      SetState(lsError);
    end;
  end;
  {$ELSE}
  SetState(lsListening);
  Result := True;
  {$ENDIF}
end;

procedure TAIContinuousListener.StopListening;
begin
  {$IFDEF MSWINDOWS}
  if Assigned(FCaptureThread) then
  begin
    FCaptureThread.StopCapture;
    FreeAndNil(FCaptureThread);
  end;
  {$ENDIF}
  ResetVAD;
  SetState(lsStopped);
end;

procedure TAIContinuousListener.Reset;
begin
  ResetVAD;
  if FState <> lsStopped then
    SetState(lsListening);
end;

procedure TAIContinuousListener.ResetVAD;
begin
  FConsecutiveVoiceFrames := 0;
  FSilenceAccumMs := 0;
  FSpeechDurationMs := 0;
  FCurrentRMS := 0.0;
  if Assigned(FSpeechStream) then
    FSpeechStream.Clear;
  FPreRollWritePos := 0;
  FPreRollCount := 0;
end;

procedure TAIContinuousListener.NotifyAssistantSpeechStart;
begin
  FAssistantSpeaking := True;
  if FState in [lsSpeechDetected, lsCapturingSpeech, lsWaitingSilence] then
    ResetVAD;
  SetState(lsSuppressedByAssistantSpeech);
end;

procedure TAIContinuousListener.NotifyAssistantSpeechEnd;
begin
  FAssistantSpeaking := False;
  FLastAssistantSpeakStopTime := GetTickCount64;
  if FState = lsSuppressedByAssistantSpeech then
    SetState(lsListening);
end;

procedure TAIContinuousListener.FeedPlaybackReference(const ASamples: PSmallInt; ACount: Integer);
var
  i: Integer;
begin
  if (ASamples = nil) or (ACount <= 0) then Exit;
  for i := 0 to ACount - 1 do
  begin
    FRefBuffer[FRefWritePos] := ASamples[i];
    FRefWritePos := (FRefWritePos + 1) mod FRefCapacity;
    if FRefCount < FRefCapacity then
      Inc(FRefCount);
  end;
end;

procedure TAIContinuousListener.FeedPlaybackWav(const AWavPath: string);
var
  FS: TFileStream;
  Hdr: TWavHeader;
  DataBytes: Integer;
  Buffer: array of SmallInt;
begin
  if not FileExists(AWavPath) then Exit;
  try
    FS := TFileStream.Create(AWavPath, fmOpenRead or fmShareDenyNone);
    try
      if FS.Size > SizeOf(TWavHeader) then
      begin
        FS.ReadBuffer(Hdr, SizeOf(TWavHeader));
        if (Hdr.riff_tag = 'RIFF') and (Hdr.wave_tag = 'WAVE') then
        begin
          DataBytes := FS.Size - FS.Position;
          if DataBytes > 0 then
          begin
            SetLength(Buffer, DataBytes div 2);
            FS.ReadBuffer(Buffer[0], DataBytes);
            FeedPlaybackReference(@Buffer[0], Length(Buffer));
          end;
        end;
      end;
    finally
      FS.Free;
    end;
  except
    // Ignora erro de leitura em fallback
  end;
end;

function TAIContinuousListener.ComputeRMS(const ABuffer: PSmallInt; ASamples: Integer): Double;
var
  i: Integer;
  SumSq, Norm: Double;
begin
  Result := 0.0;
  if (ABuffer = nil) or (ASamples <= 0) then Exit;
  SumSq := 0.0;
  for i := 0 to ASamples - 1 do
  begin
    Norm := ABuffer[i] / 32768.0;
    SumSq := SumSq + (Norm * Norm);
  end;
  Result := Sqrt(SumSq / ASamples);
end;

function TAIContinuousListener.ComputeCorrelation(const AMicSamples: PSmallInt; ASamples: Integer; out ARefRMS: Double): Double;
var
  Lag, i: Integer;
  MaxLags: Integer;
  SumMicRef, SumMicSq, SumRefSq: Double;
  MicNorm, RefNorm, Corr, BestCorr: Double;
  RefIdx: Integer;
  RefSample: SmallInt;
begin
  ARefRMS := 0.0;
  BestCorr := 0.0;
  if (AMicSamples = nil) or (ASamples <= 0) or (FRefCount < ASamples) then
    Exit(0.0);

  SumMicSq := 0.0;
  for i := 0 to ASamples - 1 do
  begin
    MicNorm := AMicSamples[i] / 32768.0;
    SumMicSq := SumMicSq + (MicNorm * MicNorm);
  end;

  if SumMicSq < 1e-8 then Exit(0.0);

  MaxLags := Min(FRefCount - ASamples, FSampleRate * 160 div 1000);
  Lag := 0;
  while Lag <= MaxLags do
  begin
    SumMicRef := 0.0;
    SumRefSq := 0.0;
    for i := 0 to ASamples - 1 do
    begin
      MicNorm := AMicSamples[i] / 32768.0;
      RefIdx := (FRefWritePos - 1 - Lag - (ASamples - 1 - i));
      while RefIdx < 0 do
        Inc(RefIdx, FRefCapacity);
      RefIdx := RefIdx mod FRefCapacity;

      RefSample := FRefBuffer[RefIdx];
      RefNorm := RefSample / 32768.0;

      SumMicRef := SumMicRef + (MicNorm * RefNorm);
      SumRefSq := SumRefSq + (RefNorm * RefNorm);
    end;

    if (SumMicSq > 1e-8) and (SumRefSq > 1e-8) then
    begin
      Corr := SumMicRef / (Sqrt(SumMicSq) * Sqrt(SumRefSq) + 1e-7);
      if Corr > BestCorr then
      begin
        BestCorr := Corr;
        ARefRMS := Sqrt(SumRefSq / ASamples);
      end;
    end;

    Lag := Lag + (FSampleRate * 10 div 1000);
  end;

  if BestCorr < 0.0 then
    Result := 0.0
  else
    Result := BestCorr;
end;

procedure TAIContinuousListener.AppendToPreRoll(const ABuffer: PSmallInt; ASamples: Integer);
var
  BytesToCopy: Integer;
begin
  if (ABuffer = nil) or (ASamples <= 0) then Exit;
  BytesToCopy := ASamples * 2;
  if FPreRollWritePos + BytesToCopy <= FPreRollCapacity then
  begin
    Move(ABuffer^, FPreRollBuffer[FPreRollWritePos], BytesToCopy);
    FPreRollWritePos := FPreRollWritePos + BytesToCopy;
  end
  else
  begin
    FPreRollWritePos := 0;
    if BytesToCopy <= FPreRollCapacity then
    begin
      Move(ABuffer^, FPreRollBuffer[0], BytesToCopy);
      FPreRollWritePos := BytesToCopy;
    end;
  end;

  FPreRollCount := Min(FPreRollCapacity, FPreRollCount + BytesToCopy);
end;

procedure TAIContinuousListener.FlushPreRollToSpeechStream;
var
  PreRollBytesWanted: Integer;
  StartPos: Integer;
begin
  if not Assigned(FSpeechStream) then Exit;
  PreRollBytesWanted := (FSampleRate * FPreRollMs div 1000) * 2;
  PreRollBytesWanted := Min(PreRollBytesWanted, FPreRollCount);

  if PreRollBytesWanted > 0 then
  begin
    StartPos := FPreRollWritePos - PreRollBytesWanted;
    if StartPos < 0 then
      StartPos := 0;
    FSpeechStream.WriteBuffer(FPreRollBuffer[StartPos], PreRollBytesWanted);
  end;
end;

procedure TAIContinuousListener.ProcessPcmFrame(const AData: PSmallInt; ASampleCount: Integer);
var
  FrameRMS: Double;
  FrameDurationMs: Integer;
  RefRMS: Double;
  Corr: Double;
  DetectedOrigin: TAudioOrigin;
  RawBytes: TBytes;
  NowTick: Int64;
  IsSelfEchoTail: Boolean;
begin
  if (AData = nil) or (ASampleCount <= 0) or (not FEnabled) then Exit;

  FrameDurationMs := (ASampleCount * 1000) div FSampleRate;
  FrameRMS := ComputeRMS(AData, ASampleCount);
  FCurrentRMS := (FCurrentRMS * 0.2) + (FrameRMS * 0.8);

  if Assigned(FOnRMSChanged) then
    FOnRMSChanged(Self, FCurrentRMS);

  if Assigned(FOnAudioBuffer) then
  begin
    SetLength(RawBytes, ASampleCount * 2);
    Move(AData^, RawBytes[0], ASampleCount * 2);
    FOnAudioBuffer(Self, RawBytes, FSampleRate, FChannels);
  end;

  AppendToPreRoll(AData, ASampleCount);

  // 1. Verificacao de eco e fala do proprio assistente (Self-Speech Suppression)
  DetectedOrigin := aoUnknown;
  Corr := 0.0;
  RefRMS := 0.0;

  NowTick := GetTickCount64;
  IsSelfEchoTail := (FLastAssistantSpeakStopTime > 0) and
                    (NowTick - FLastAssistantSpeakStopTime < Int64(FSelfSpeechIgnoreMs));

  if (FAssistantSpeaking or IsSelfEchoTail) and FEchoSuppressionEnabled then
  begin
    if FRefCount >= ASampleCount then
      Corr := ComputeCorrelation(AData, ASampleCount, RefRMS)
    else
      Corr := 0.0;

    FLastConfidence := Corr;

    if (Corr >= FSelfAudioCorrelationThreshold) or (IsSelfEchoTail and (FrameRMS < FVoiceThreshold * 2.0)) then
      DetectedOrigin := aoAssistantSpeech
    else if (FrameRMS >= FVoiceThreshold * 1.8) and (Corr < 0.45) then
      DetectedOrigin := aoExternalSpeech
    else
      DetectedOrigin := aoEnvironment;

    FLastOrigin := DetectedOrigin;
    if Assigned(FOnAudioOriginDetected) then
      FOnAudioOriginDetected(Self, DetectedOrigin, Corr);

    if (DetectedOrigin = aoExternalSpeech) and FAssistantSpeaking then
    begin
      Inc(FConsecutiveVoiceFrames);
      if FConsecutiveVoiceFrames >= 4 then // ~200ms de voz externa
      begin
        // Barge-in confirmado!
        if Assigned(FOnBargeIn) then
          FOnBargeIn(Self);
        FAssistantSpeaking := False;
        FLastAssistantSpeakStopTime := GetTickCount64;
        SetState(lsSpeechDetected);
        FlushPreRollToSpeechStream;
        FSpeechStream.WriteBuffer(AData^, ASampleCount * 2);
        FSpeechDurationMs := FrameDurationMs;
        FSilenceAccumMs := 0;
        Exit;
      end;
    end
    else
    begin
      FConsecutiveVoiceFrames := 0;
      SetState(lsSuppressedByAssistantSpeech);
      Exit;
    end;
  end;

  // 2. Classificacao de voz externa vs ambiente fora de reproducao
  if FrameRMS >= FVoiceThreshold then
    DetectedOrigin := aoExternalSpeech
  else
    DetectedOrigin := aoEnvironment;

  FLastOrigin := DetectedOrigin;
  if Assigned(FOnAudioOriginDetected) then
    FOnAudioOriginDetected(Self, DetectedOrigin, 1.0);

  // 3. Maquina de Estados VAD
  case FState of
    lsStopped, lsError:
      Exit;

    lsSuppressedByAssistantSpeech:
    begin
      if not FAssistantSpeaking then
        SetState(lsListening);
    end;

    lsListening:
    begin
      if FrameRMS >= FVoiceThreshold then
      begin
        Inc(FConsecutiveVoiceFrames);
        if FConsecutiveVoiceFrames >= 3 then
        begin
          SetState(lsSpeechDetected);
          FSpeechStream.Clear;
          FlushPreRollToSpeechStream;
          FSpeechStream.WriteBuffer(AData^, ASampleCount * 2);
          FSpeechDurationMs := FrameDurationMs;
          FSilenceAccumMs := 0;
          SetState(lsCapturingSpeech);
        end;
      end
      else
        FConsecutiveVoiceFrames := 0;
    end;

    lsSpeechDetected, lsCapturingSpeech:
    begin
      FSpeechStream.WriteBuffer(AData^, ASampleCount * 2);
      FSpeechDurationMs := FSpeechDurationMs + FrameDurationMs;

      if FrameRMS < FSilenceThreshold then
      begin
        FSilenceAccumMs := FSilenceAccumMs + FrameDurationMs;
        if FSilenceAccumMs >= FSilenceTimeoutMs then
          FinalizeUtterance;
      end
      else
        FSilenceAccumMs := 0;

      if FSpeechDurationMs >= FMaxSpeechMs then
        FinalizeUtterance;
    end;

    lsWaitingSilence, lsProcessing:
      ;
  end;
end;

function TAIContinuousListener.SaveSpeechStreamToWav(out AOutPath: string): Boolean;
var
  FS: TFileStream;
  Hdr: TWavHeader;
  TempDir: string;
  FileName: string;
  DataSize: UInt32;
begin
  Result := False;
  AOutPath := '';
  if (FSpeechStream = nil) or (FSpeechStream.Size <= 0) then Exit;

  TempDir := IncludeTrailingPathDelimiter(GetTempDir);
  FileName := Format('assistente_speech_%s_%d.wav', [
    FormatDateTime('yyyymmdd_hhnnss', Now),
    GetTickCount64 mod 10000
  ]);
  AOutPath := TempDir + FileName;

  DataSize := FSpeechStream.Size;
  FillChar(Hdr, SizeOf(Hdr), 0);
  Hdr.riff_tag := 'RIFF';
  Hdr.riff_size := SizeOf(TWavHeader) - 8 + DataSize;
  Hdr.wave_tag := 'WAVE';
  Hdr.fmt_tag := 'fmt ';
  Hdr.fmt_size := 16;
  Hdr.audio_format := 1; // PCM
  Hdr.num_channels := FChannels;
  Hdr.sample_rate := FSampleRate;
  Hdr.bits_per_sample := 16;
  Hdr.block_align := FChannels * 2;
  Hdr.byte_rate := FSampleRate * Hdr.block_align;
  Hdr.data_tag := 'data';
  Hdr.data_size := DataSize;

  try
    FS := TFileStream.Create(AOutPath, fmCreate);
    try
      FS.WriteBuffer(Hdr, SizeOf(Hdr));
      FSpeechStream.Position := 0;
      FS.CopyFrom(FSpeechStream, DataSize);
      Result := True;
    finally
      FS.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Falha ao salvar WAV da utterance: ' + E.Message;
      Result := False;
    end;
  end;
end;

procedure TAIContinuousListener.FinalizeUtterance;
var
  WavPath: string;
  Duration: Integer;
begin
  Duration := FSpeechDurationMs;
  SetState(lsProcessing);

  if Duration < FMinSpeechMs then
  begin
    ResetVAD;
    SetState(lsListening);
    Exit;
  end;

  if SaveSpeechStreamToWav(WavPath) then
  begin
    if Assigned(FOnSpeechUtterance) then
      FOnSpeechUtterance(Self, WavPath, Duration);
  end;

  ResetVAD;
  if FContinuous then
    SetState(lsListening)
  else
    SetState(lsStopped);
end;

end.
"""

target_path = r"P:\maurinsoft\CHATGPT\pacote\AI Voice\aicontinuouslistener.pas"
with open(target_path, "w", encoding="utf-8") as f:
    f.write(listener_code)
print(f"Successfully wrote {target_path} ({len(listener_code)} bytes)")
