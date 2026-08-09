program voice_pipeline_test;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, Classes, SysUtils, aispeechtypes, aispeechrecognizer,
  aiwhisperengine, aivoiceclonetypes, aif5ttsengine, aivoiceclone,
  aivoiceassistant, chatgpt;

type
  TProbe = class
  public
    Starts, Texts, Partials, Errors, Finishes, Progresses: Integer;
    procedure Start(Sender: TObject);
    procedure Text(Sender: TObject; const AText: string);
    procedure Error(Sender: TObject; const AError: string);
    procedure Finish(Sender: TObject; ASuccess: Boolean);
    procedure Progress(Sender: TObject; APercent: Integer; const AMessage: string);
    procedure CloneFinish(Sender: TObject; ASuccess: Boolean; const AOutput: string);
  end;

procedure Fail(const M: string); begin Writeln(StdErr, 'FAIL: ', M); Halt(1); end;
procedure Check(C: Boolean; const M: string); begin if not C then Fail(M); end;
procedure TProbe.Start(Sender: TObject); begin Inc(Starts); end;
procedure TProbe.Text(Sender: TObject; const AText: string);
begin if AText <> '' then Inc(Texts); end;
procedure TProbe.Error(Sender: TObject; const AError: string);
begin if AError <> '' then Inc(Errors); end;
procedure TProbe.Finish(Sender: TObject; ASuccess: Boolean); begin Inc(Finishes); end;
procedure TProbe.Progress(Sender: TObject; APercent: Integer; const AMessage: string);
begin if (APercent >= 0) and (AMessage <> '') then Inc(Progresses); end;
procedure TProbe.CloneFinish(Sender: TObject; ASuccess: Boolean; const AOutput: string);
begin Inc(Finishes); end;

procedure CreateWav(const AFileName: string; ASeconds: Integer);
var
  S: TFileStream; H: array[0..43] of Byte; Buffer: array[0..4095] of Byte;
  RiffSize, DataSize, FmtSize, SampleRate, ByteRate: LongWord;
  AudioFormat, Channels, BlockAlign, Bits: Word; Remaining, N: Integer;
begin
  FillChar(H, SizeOf(H), 0); FillChar(Buffer, SizeOf(Buffer), 0);
  Move('RIFF'[1], H[0], 4); Move('WAVE'[1], H[8], 4); Move('fmt '[1], H[12], 4);
  FmtSize := 16; AudioFormat := 1; Channels := 1; SampleRate := 16000;
  Bits := 16; BlockAlign := 2; ByteRate := 32000; DataSize := ByteRate * ASeconds;
  RiffSize := 36 + DataSize; Move(RiffSize, H[4], 4); Move(FmtSize, H[16], 4);
  Move(AudioFormat, H[20], 2); Move(Channels, H[22], 2); Move(SampleRate, H[24], 4);
  Move(ByteRate, H[28], 4); Move(BlockAlign, H[32], 2); Move(Bits, H[34], 2);
  Move('data'[1], H[36], 4); Move(DataSize, H[40], 4);
  S := TFileStream.Create(AFileName, fmCreate);
  try
    S.WriteBuffer(H, SizeOf(H)); Remaining := DataSize;
    while Remaining > 0 do begin N := Remaining; if N > SizeOf(Buffer) then N := SizeOf(Buffer); S.WriteBuffer(Buffer, N); Dec(Remaining, N); end;
  finally S.Free; end;
end;

procedure Touch(const AFileName: string);
var S: TFileStream; B: Byte;
begin B := 0; S := TFileStream.Create(AFileName, fmCreate); try S.WriteBuffer(B, 1); finally S.Free; end; end;

var
  Whisper: TAIWhisperProcessEngine;
  Recognizer: TAISpeechRecognizer;
  F5: TAIF5TTSProcessEngine;
  Clone: TAIVoiceClone;
  Assistant, BrokenAssistant: TAIVoiceAssistant;
  Chat: TCHATGPT;
  Probe: TProbe;
  Args, Chunks: TStringList;
  BaseDir, AudioFile, ModelFile, RefFile, OutputFile, Err: string;
  I: Integer;
begin
  if ParamCount < 3 then Fail('uso: test fake_whisper fake_f5 llm_endpoint');
  BaseDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  AudioFile := BaseDir + 'input.wav'; ModelFile := BaseDir + 'model.bin';
  RefFile := BaseDir + 'reference.wav'; OutputFile := BaseDir + 'generated.wav';
  CreateWav(AudioFile, 3); CreateWav(RefFile, 1); Touch(ModelFile);
  Whisper := TAIWhisperProcessEngine.Create(nil);
  Recognizer := TAISpeechRecognizer.Create(nil);
  F5 := TAIF5TTSProcessEngine.Create(nil);
  Clone := TAIVoiceClone.Create(nil);
  Assistant := TAIVoiceAssistant.Create(nil);
  BrokenAssistant := TAIVoiceAssistant.Create(nil);
  Chat := TCHATGPT.Create(nil);
  Probe := TProbe.Create;
  Args := TStringList.Create; Chunks := TStringList.Create;
  try
    Check(not Whisper.ValidateExecutable(Err), 'whisper vazio deveria falhar');
    Whisper.ExecutablePath := ParamStr(1); Whisper.ModelPath := ModelFile;
    Check(Whisper.ValidateExecutable(Err) and Whisper.ValidateModel(Err), Err);
    Whisper.BuildCommandArguments(AudioFile, 'pt', False, 2, Args);
    Check((Args.IndexOf('-m') >= 0) and (Args.IndexOf('--no-gpu') >= 0),
      'argumentos whisper incompletos');

    Recognizer.Engine := Whisper; Recognizer.ModelPath := ModelFile;
    Recognizer.OnStart := @Probe.Start; Recognizer.OnText := @Probe.Text;
    Recognizer.OnPartialText := @Probe.Text; Recognizer.OnError := @Probe.Error;
    Recognizer.OnFinish := @Probe.Finish;
    Check(Recognizer.TranscribeFile(AudioFile), Recognizer.LastError);
    Check(Recognizer.LastText = 'fala reconhecida', 'texto Whisper nao foi limpo');
    Check(not Recognizer.Busy, 'recognizer permaneceu Busy');
    Check(Recognizer.MergeTranscripts('ola mundo', 'mundo novamente') =
      'ola mundo novamente', 'merge repetiu sobreposicao');
    Check(Recognizer.SplitWavIntoChunks(AudioFile, 1, Chunks, Err), Err);
    Check(Chunks.Count = 3, 'divisao WAV nao gerou 3 blocos');
    Check(Recognizer.TranscribeFiles(Chunks), Recognizer.LastError);
    Check(Recognizer.LastText = 'ola mundo novamente fim',
      'fila continua duplicou ou perdeu texto: ' + Recognizer.LastText);
    for I := 0 to Chunks.Count - 1 do if FileExists(Chunks[I]) then DeleteFile(Chunks[I]);
    Chunks.Clear;
    Recognizer.Cancel; Check(Recognizer.State = ssStopped, 'cancelamento STT inconsistente');

    Check(not F5.ValidatePython(Err), 'Python vazio deveria falhar');
    F5.PythonPath := ParamStr(2); F5.F5TTSPath := ParamStr(2);
    Clone.Engine := F5; Clone.ReferenceAudio := RefFile; Clone.OutputFile := OutputFile;
    Clone.VoiceID := 'voice-1'; Clone.Language := 'pt';
    Clone.OnStart := @Probe.Start; Clone.OnProgress := @Probe.Progress;
    Clone.OnError := @Probe.Error; Clone.OnFinish := @Probe.CloneFinish;
    Check(not Clone.Synthesize('nao autorizado'), 'clone ignorou consentimento');
    Check(not FileExists(OutputFile), 'clone bloqueado gerou arquivo');
    Clone.ConsentConfirmed := True;
    Check(not Clone.CreateVoice, 'clone aceitou VoiceOwner vazio');
    Clone.VoiceOwner := 'Titular autorizado';
    Check(Clone.CreateVoice, Clone.LastError);
    Check(Clone.Synthesize('resposta falada'), Clone.LastError);
    Check((Clone.LastOutputFile = ExpandFileName(OutputFile)) and FileExists(OutputFile),
      'clone nao retornou WAV real');
    Clone.Cancel; Check(Clone.State = vcsIdle, 'cancelamento clone inconsistente');

    Chat.Provider := AIP_OPENAI_COMPATIBLE; Chat.URL := ParamStr(3);
    Chat.CustomModel := 'mock-model'; Chat.Timeout := 5000;
    Assistant.Recognizer := Recognizer; Assistant.ChatGPT := Chat;
    Assistant.VoiceClone := Clone;
    Check(Assistant.ProcessAudioFile(AudioFile), Assistant.LastError);
    Check((Assistant.LastRecognizedText = 'fala reconhecida') and
      (Assistant.LastResponse = 'mock-sync') and FileExists(Assistant.LastAudioFile),
      'pipeline Microfone/STT/LLM/Clone/WAV incompleto');
    Assistant.Cancel; Check(Assistant.State = vasCancelled, 'cancelamento do pipeline falhou');
    Check(not BrokenAssistant.ProcessText('teste'), 'pipeline sem componentes nao falhou');
    Check(BrokenAssistant.State = vasError, 'erro de etapa nao atualizou estado');
    Check((Probe.Starts >= 4) and (Probe.Texts >= 3) and
      (Probe.Errors >= 2) and (Probe.Finishes >= 4) and (Probe.Progresses >= 2),
      'eventos de voz nao foram propagados');
  finally
    Chunks.Free; Args.Free; Probe.Free; Chat.Free; BrokenAssistant.Free;
    Assistant.Free; Clone.Free; F5.Free; Recognizer.Free; Whisper.Free;
    if FileExists(OutputFile) then DeleteFile(OutputFile);
    if FileExists(RefFile) then DeleteFile(RefFile);
    if FileExists(ModelFile) then DeleteFile(ModelFile);
    if FileExists(AudioFile) then DeleteFile(AudioFile);
  end;
  Writeln('PASS: Whisper + WAV chunks + consent + F5 + STT/LLM/voice pipeline');
end.
