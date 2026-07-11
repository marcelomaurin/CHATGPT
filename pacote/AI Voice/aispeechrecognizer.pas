unit aispeechrecognizer;

{$mode objfpc}{$H+}
{$packrecords c}

interface

uses
  Classes, SysUtils, Math, Process, Pipes, DynLibs,
  fphttpclient, opensslsockets, fpjson, jsonparser,
  aibase, aiaudio, LResources;

type
  TAISpeechBackend = (
    sbAuto,
    sbWhisperCpp,
    sbSherpaOnnx,
    sbOpenAI,
    sbAzure
  );

  TWavInfo = record
    Valid: Boolean;
    AudioFormat: Word;
    Channels: Word;
    SampleRate: Cardinal;
    BitsPerSample: Word;
    DataOffset: Int64;
    DataSize: Int64;
  end;

  TSingleArray = array of Single;

  TSherpaOnnxFeatureConfig = record
    sample_rate: LongInt;
    feature_dim: LongInt;
  end;

  TSherpaOnnxOfflineTransducerModelConfig = record
    encoder: PAnsiChar;
    decoder: PAnsiChar;
    joiner: PAnsiChar;
  end;

  TSherpaOnnxOfflineParaformerModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineNemoEncDecCtcModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineWhisperModelConfig = record
    encoder: PAnsiChar;
    decoder: PAnsiChar;
    language: PAnsiChar;
    task: PAnsiChar;
    tail_paddings: LongInt;
    enable_token_timestamps: LongInt;
    enable_segment_timestamps: LongInt;
  end;

  TSherpaOnnxOfflineCanaryModelConfig = record
    encoder: PAnsiChar;
    decoder: PAnsiChar;
    src_lang: PAnsiChar;
    tgt_lang: PAnsiChar;
    use_pnc: LongInt;
  end;

  TSherpaOnnxOfflineCohereTranscribeModelConfig = record
    encoder: PAnsiChar;
    decoder: PAnsiChar;
    language: PAnsiChar;
    use_punct: LongInt;
    use_itn: LongInt;
  end;

  TSherpaOnnxOfflineFireRedAsrModelConfig = record
    encoder: PAnsiChar;
    decoder: PAnsiChar;
  end;

  TSherpaOnnxOfflineFireRedAsrCtcModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineMoonshineModelConfig = record
    preprocessor: PAnsiChar;
    encoder: PAnsiChar;
    uncached_decoder: PAnsiChar;
    cached_decoder: PAnsiChar;
    merged_decoder: PAnsiChar;
  end;

  TSherpaOnnxOfflineTdnnModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineLMConfig = record
    model: PAnsiChar;
    scale: Single;
  end;

  TSherpaOnnxOfflineSenseVoiceModelConfig = record
    model: PAnsiChar;
    language: PAnsiChar;
    use_itn: LongInt;
  end;

  TSherpaOnnxOfflineDolphinModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineZipformerCtcModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineWenetCtcModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineOmnilingualAsrCtcModelConfig = record
    model: PAnsiChar;
  end;

  TSherpaOnnxOfflineFunASRNanoModelConfig = record
    encoder_adaptor: PAnsiChar;
    llm: PAnsiChar;
    embedding: PAnsiChar;
    tokenizer: PAnsiChar;
    system_prompt: PAnsiChar;
    user_prompt: PAnsiChar;
    max_new_tokens: LongInt;
    temperature: Single;
    top_p: Single;
    seed: LongInt;
    language: PAnsiChar;
  end;

  TSherpaOnnxOfflineModelConfig = record
    transducer: TSherpaOnnxOfflineTransducerModelConfig;
    paraformer: TSherpaOnnxOfflineParaformerModelConfig;
    nemo_ctc: TSherpaOnnxOfflineNemoEncDecCtcModelConfig;
    whisper: TSherpaOnnxOfflineWhisperModelConfig;
    canary: TSherpaOnnxOfflineCanaryModelConfig;
    cohere_transcribe: TSherpaOnnxOfflineCohereTranscribeModelConfig;
    fire_red_asr: TSherpaOnnxOfflineFireRedAsrModelConfig;
    fire_red_asr_ctc: TSherpaOnnxOfflineFireRedAsrCtcModelConfig;
    moonshine: TSherpaOnnxOfflineMoonshineModelConfig;
    tdnn: TSherpaOnnxOfflineTdnnModelConfig;
    sense_voice: TSherpaOnnxOfflineSenseVoiceModelConfig;
    dolphin: TSherpaOnnxOfflineDolphinModelConfig;
    zipformer_ctc: TSherpaOnnxOfflineZipformerCtcModelConfig;
    wenet_ctc: TSherpaOnnxOfflineWenetCtcModelConfig;
    omnilingual_asr_ctc: TSherpaOnnxOfflineOmnilingualAsrCtcModelConfig;
    funasr_nano: TSherpaOnnxOfflineFunASRNanoModelConfig;
    tokens: PAnsiChar;
    num_threads: LongInt;
    provider: PAnsiChar;
    debug: LongInt;
    model_type: PAnsiChar;
    modeling_unit: PAnsiChar;
    bpe_vocab: PAnsiChar;
    tokens_buf: PAnsiChar;
    tokens_buf_size: LongInt;
  end;

  TSherpaOnnxHomophoneReplacerConfig = record
    dict_dir: PAnsiChar;
    lexicon: PAnsiChar;
    rule_fsts: PAnsiChar;
  end;

  TSherpaOnnxOfflineRecognizerConfig = record
    feat_config: TSherpaOnnxFeatureConfig;
    model_config: TSherpaOnnxOfflineModelConfig;
    lm_config: TSherpaOnnxOfflineLMConfig;
    decoding_method: PAnsiChar;
    max_active_paths: LongInt;
    hotwords_file: PAnsiChar;
    hotwords_score: Single;
    rule_fsts: PAnsiChar;
    rule_fars: PAnsiChar;
    blank_penalty: Single;
    hotwords_buf: PAnsiChar;
    hotwords_buf_size: LongInt;
    hr: TSherpaOnnxHomophoneReplacerConfig;
  end;

  TSherpaOnnxOfflineRecognizerResult = record
    text: PAnsiChar;
    tokens: PAnsiChar;
    tokens_arr: PPAnsiChar;
    timestamps: PSingle;
    count: LongInt;
    json: PAnsiChar;
  end;

  PSherpaOnnxOfflineRecognizer = Pointer;
  PSherpaOnnxOfflineStream = Pointer;
  PSherpaOnnxOfflineRecognizerConfig = ^TSherpaOnnxOfflineRecognizerConfig;
  PSherpaOnnxOfflineRecognizerResult = ^TSherpaOnnxOfflineRecognizerResult;

  TSherpaOnnxCreateOfflineRecognizer = function(const Config: PSherpaOnnxOfflineRecognizerConfig): PSherpaOnnxOfflineRecognizer; cdecl;
  TSherpaOnnxDestroyOfflineRecognizer = procedure(const Recognizer: PSherpaOnnxOfflineRecognizer); cdecl;
  TSherpaOnnxCreateOfflineStream = function(const Recognizer: PSherpaOnnxOfflineRecognizer): PSherpaOnnxOfflineStream; cdecl;
  TSherpaOnnxDestroyOfflineStream = procedure(const Stream: PSherpaOnnxOfflineStream); cdecl;
  TSherpaOnnxAcceptWaveformOffline = procedure(const Stream: PSherpaOnnxOfflineStream; SampleRate: LongInt; const Samples: PSingle; NumSamples: LongInt); cdecl;
  TSherpaOnnxDecodeOfflineStream = procedure(const Recognizer: PSherpaOnnxOfflineRecognizer; const Stream: PSherpaOnnxOfflineStream); cdecl;
  TSherpaOnnxGetOfflineStreamResult = function(const Stream: PSherpaOnnxOfflineStream): PSherpaOnnxOfflineRecognizerResult; cdecl;
  TSherpaOnnxDestroyOfflineRecognizerResult = procedure(const Result: PSherpaOnnxOfflineRecognizerResult); cdecl;

  { TAISpeechRecognizer }

  TAISpeechRecognizer = class(TAIBaseComponent)
  private
    FBackend: TAISpeechBackend;
    FInputFile: string;
    FLanguage: string;
    FPromptText: string;
    FTimeoutMs: Integer;
    FStrictWavValidation: Boolean;

    // Whisper.cpp
    FWhisperCppExecutable: string;
    FWhisperCppModel: string;
    FWhisperCppThreads: Integer;
    FWhisperCppExtraArgs: string;

    // Sherpa-ONNX
    FSherpaLibraryPath: string;
    FSherpaEncoderFile: string;
    FSherpaDecoderFile: string;
    FSherpaTokensFile: string;
    FSherpaProvider: string;
    FSherpaNumThreads: Integer;
    FSherpaTask: string;

    // OpenAI
    FOpenAIToken: string;
    FOpenAIModel: string;
    FOpenAIEndpoint: string;
    FOpenAIResponseFormat: string;

    // Azure
    FAzureSubscriptionKey: string;
    FAzureRegion: string;
    FAzureEndpoint: string;
    FAzureFormat: string;

    // Stable ANSI mirrors for C API pointers
    FSherpaEncoderAnsi: AnsiString;
    FSherpaDecoderAnsi: AnsiString;
    FSherpaTokensAnsi: AnsiString;
    FSherpaProviderAnsi: AnsiString;
    FSherpaTaskAnsi: AnsiString;
    FSherpaLanguageAnsi: AnsiString;
    FSherpaDecodingAnsi: AnsiString;

    function ReadWavInfo(const AFileName: string; out AInfo: TWavInfo; out AError: string): Boolean;
    function LoadWavSamplesAsMonoFloat(const AFileName: string; out ASamples: TSingleArray; out ASampleRate: Integer; out AError: string): Boolean;
    function ValidateWavForBackend(const AFileName: string; const ABackend: TAISpeechBackend; out AInfo: TWavInfo; out AError: string): Boolean;
    function ResolveBackend: TAISpeechBackend;
    function BackendConfigured(const ABackend: TAISpeechBackend): Boolean;
    function FindWhisperExecutable: string;
    function BuildWhisperOutputBase(const AInputFile: string): string;
    function ExecuteWhisperCpp(const AWavFile: string): Boolean;
    function ExecuteSherpaOnnx(const AWavFile: string): Boolean;
    function ExecuteOpenAI(const AWavFile: string): Boolean;
    function ExecuteAzure(const AWavFile: string): Boolean;
    function LoadSherpaLibrary(out ALib: TLibHandle; out AError: string): Boolean;
    function PrepareSherpaConfig(out AConfig: TSherpaOnnxOfflineRecognizerConfig): Boolean;
    function MultipartBoundary: string;
    function BuildOpenAIMultipartBody(const AWavFile: string; out ABoundary: string): TMemoryStream;
    function OpenAIJsonEscape(const S: string): string;
    function GetAzureEndpointURL: string;
    function GetOutputTextFromResponse(const ABody: string; const AKeyName: string): string;
    procedure StoreSuccess(const ABackendName, AText: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Recognize: Boolean;
    function RecognizeFile(const AWavFile: string): Boolean;
    function ValidateInputFile(const AWavFile: string): Boolean;
    procedure GetSupportedBackends(AList: TStrings);
  published
    property Backend: TAISpeechBackend read FBackend write FBackend default sbAuto;
    property InputFile: string read FInputFile write FInputFile;
    property Language: string read FLanguage write FLanguage;
    property PromptText: string read FPromptText write FPromptText;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 120000;
    property StrictWavValidation: Boolean read FStrictWavValidation write FStrictWavValidation default True;

    property WhisperCppExecutable: string read FWhisperCppExecutable write FWhisperCppExecutable;
    property WhisperCppModel: string read FWhisperCppModel write FWhisperCppModel;
    property WhisperCppThreads: Integer read FWhisperCppThreads write FWhisperCppThreads default 0;
    property WhisperCppExtraArgs: string read FWhisperCppExtraArgs write FWhisperCppExtraArgs;

    property SherpaLibraryPath: string read FSherpaLibraryPath write FSherpaLibraryPath;
    property SherpaEncoderFile: string read FSherpaEncoderFile write FSherpaEncoderFile;
    property SherpaDecoderFile: string read FSherpaDecoderFile write FSherpaDecoderFile;
    property SherpaTokensFile: string read FSherpaTokensFile write FSherpaTokensFile;
    property SherpaProvider: string read FSherpaProvider write FSherpaProvider;
    property SherpaNumThreads: Integer read FSherpaNumThreads write FSherpaNumThreads default 1;
    property SherpaTask: string read FSherpaTask write FSherpaTask;

    property OpenAIToken: string read FOpenAIToken write FOpenAIToken;
    property OpenAIModel: string read FOpenAIModel write FOpenAIModel;
    property OpenAIEndpoint: string read FOpenAIEndpoint write FOpenAIEndpoint;
    property OpenAIResponseFormat: string read FOpenAIResponseFormat write FOpenAIResponseFormat;

    property AzureSubscriptionKey: string read FAzureSubscriptionKey write FAzureSubscriptionKey;
    property AzureRegion: string read FAzureRegion write FAzureRegion;
    property AzureEndpoint: string read FAzureEndpoint write FAzureEndpoint;
    property AzureFormat: string read FAzureFormat write FAzureFormat;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Voice', [TAISpeechRecognizer]);
end;

function ReadUInt16LE(AStream: TStream): Word;
var
  B: array[0..1] of Byte;
begin
  AStream.ReadBuffer(B, SizeOf(B));
  Result := Word(B[0]) or (Word(B[1]) shl 8);
end;

function ReadUInt32LE(AStream: TStream): Cardinal;
var
  B: array[0..3] of Byte;
begin
  AStream.ReadBuffer(B, SizeOf(B));
  Result := Cardinal(B[0]) or (Cardinal(B[1]) shl 8) or
            (Cardinal(B[2]) shl 16) or (Cardinal(B[3]) shl 24);
end;

procedure WriteAnsiToStream(AStream: TStream; const S: string);
var
  U: UTF8String;
begin
  U := UTF8Encode(S);
  if Length(U) > 0 then
    AStream.WriteBuffer(Pointer(U)^, Length(U));
end;

function StreamToString(AStream: TStream): string;
var
  S: TStringStream;
begin
  AStream.Position := 0;
  S := TStringStream.Create('');
  try
    S.CopyFrom(AStream, 0);
    Result := S.DataString;
  finally
    S.Free;
  end;
end;

function SplitSimpleArgs(const AText: string): TStringList;
begin
  Result := TStringList.Create;
  if Trim(AText) = '' then
    Exit;
  ExtractStrings([' '], ['"', ''''], PChar(AText), Result);
end;

{ TAISpeechRecognizer }

constructor TAISpeechRecognizer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Randomize;
  FCategory := ccInput;
  FPrompt := 'Component TAISpeechRecognizer transcribes speech from WAV files using four real backends: offline.whispercpp through an external process, offline.sherpaonnx through the Sherpa-ONNX C API loaded dynamically, online.openai through the audio transcriptions endpoint, and online.azure through the Speech to text REST API. Properties: Backend, InputFile, Language, PromptText, TimeoutMs, StrictWavValidation, WhisperCppExecutable, WhisperCppModel, WhisperCppThreads, WhisperCppExtraArgs, SherpaLibraryPath, SherpaEncoderFile, SherpaDecoderFile, SherpaTokensFile, SherpaProvider, SherpaNumThreads, SherpaTask, OpenAIToken, OpenAIModel, OpenAIEndpoint, OpenAIResponseFormat, AzureSubscriptionKey, AzureRegion, AzureEndpoint, AzureFormat. Methods: Recognize, RecognizeFile, ValidateInputFile, GetSupportedBackends. Use this component to convert recorded audio into audit-ready text without returning false positives.';

  FBackend := sbAuto;
  FInputFile := '';
  FLanguage := 'pt-BR';
  FPromptText := '';
  FTimeoutMs := 120000;
  FStrictWavValidation := True;

  FWhisperCppExecutable := 'main';
  FWhisperCppModel := '';
  FWhisperCppThreads := 0;
  FWhisperCppExtraArgs := '';

  FSherpaLibraryPath := '';
  FSherpaEncoderFile := '';
  FSherpaDecoderFile := '';
  FSherpaTokensFile := '';
  FSherpaProvider := 'cpu';
  FSherpaNumThreads := 1;
  FSherpaTask := 'transcribe';

  FOpenAIToken := '';
  FOpenAIModel := 'gpt-4o-mini-transcribe';
  FOpenAIEndpoint := 'https://api.openai.com/v1/audio/transcriptions';
  FOpenAIResponseFormat := 'json';

  FAzureSubscriptionKey := '';
  FAzureRegion := '';
  FAzureEndpoint := '';
  FAzureFormat := 'simple';

  FSherpaEncoderAnsi := '';
  FSherpaDecoderAnsi := '';
  FSherpaTokensAnsi := '';
  FSherpaProviderAnsi := '';
  FSherpaTaskAnsi := '';
  FSherpaLanguageAnsi := '';
  FSherpaDecodingAnsi := '';
end;

destructor TAISpeechRecognizer.Destroy;
begin
  inherited Destroy;
end;

procedure TAISpeechRecognizer.StoreSuccess(const ABackendName, AText: string);
begin
  FLastResult := Trim(AText);
  FLastSuccess := True;
  FLastError := '';
  if Trim(FLastResult) = '' then
    FLastResult := '';
  if Trim(ABackendName) <> '' then
    Log(llInfo, 'Speech transcribed using ' + ABackendName);
end;

function TAISpeechRecognizer.ReadWavInfo(const AFileName: string; out AInfo: TWavInfo; out AError: string): Boolean;
var
  FS: TFileStream;
  ChunkId: array[0..3] of AnsiChar;
  ChunkSize: Cardinal;
  FmtFound: Boolean;
  DataFound: Boolean;
  ChunkStart: Int64;
begin
  Result := False;
  AError := '';
  FillChar(AInfo, SizeOf(AInfo), 0);

  if not FileExists(AFileName) then
  begin
    AError := 'Arquivo nao encontrado: ' + AFileName;
    Exit;
  end;

  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    if FS.Size < 44 then
    begin
      AError := 'Arquivo WAV muito pequeno.';
      Exit;
    end;

    FS.ReadBuffer(ChunkId, 4);
    if not ((ChunkId[0] = 'R') and (ChunkId[1] = 'I') and (ChunkId[2] = 'F') and (ChunkId[3] = 'F')) then
    begin
      AError := 'Assinatura RIFF ausente.';
      Exit;
    end;

    ReadUInt32LE(FS); // file size, unused
    FS.ReadBuffer(ChunkId, 4);
    if not ((ChunkId[0] = 'W') and (ChunkId[1] = 'A') and (ChunkId[2] = 'V') and (ChunkId[3] = 'E')) then
    begin
      AError := 'Assinatura WAVE ausente.';
      Exit;
    end;

    FmtFound := False;
    DataFound := False;

    while FS.Position + 8 <= FS.Size do
    begin
      FS.ReadBuffer(ChunkId, 4);
      ChunkSize := ReadUInt32LE(FS);
      ChunkStart := FS.Position;

      if (ChunkId[0] = 'f') and (ChunkId[1] = 'm') and (ChunkId[2] = 't') and (ChunkId[3] = ' ') then
      begin
        AInfo.AudioFormat := ReadUInt16LE(FS);
        AInfo.Channels := ReadUInt16LE(FS);
        AInfo.SampleRate := ReadUInt32LE(FS);
        ReadUInt32LE(FS); // byte rate
        ReadUInt16LE(FS); // block align
        AInfo.BitsPerSample := ReadUInt16LE(FS);
        FmtFound := True;
      end
      else if (ChunkId[0] = 'd') and (ChunkId[1] = 'a') and (ChunkId[2] = 't') and (ChunkId[3] = 'a') then
      begin
        AInfo.DataOffset := FS.Position;
        AInfo.DataSize := ChunkSize;
        DataFound := True;
      end;

      FS.Position := ChunkStart + ChunkSize;
      if Odd(ChunkSize) then
        FS.Position := FS.Position + 1;

      if FmtFound and DataFound then
        Break;
    end;

    if not FmtFound then
    begin
      AError := 'Bloco fmt nao encontrado.';
      Exit;
    end;

    if not DataFound then
    begin
      AError := 'Bloco data nao encontrado.';
      Exit;
    end;

    AInfo.Valid := True;
    Result := True;
  finally
    FS.Free;
  end;
end;

function TAISpeechRecognizer.ValidateWavForBackend(const AFileName: string; const ABackend: TAISpeechBackend; out AInfo: TWavInfo; out AError: string): Boolean;
var
  AudioValidator: TAIAudioInput;
  DummyError: string;
begin
  Result := False;
  AError := '';

  if not FileExists(AFileName) then
  begin
    AError := 'Arquivo nao encontrado: ' + AFileName;
    Exit;
  end;

  AudioValidator := TAIAudioInput.Create(nil);
  try
    if not AudioValidator.ValidateWavFile(AFileName, DummyError) then
    begin
      AError := DummyError;
      Exit;
    end;
  finally
    AudioValidator.Free;
  end;

  if not ReadWavInfo(AFileName, AInfo, AError) then
    Exit;

  if FStrictWavValidation and (AInfo.AudioFormat <> 1) then
  begin
    AError := 'Somente WAV PCM e aceito por este componente.';
    Exit;
  end;

  if ABackend = sbAzure then
  begin
    if (AInfo.AudioFormat <> 1) or (AInfo.Channels <> 1) or (AInfo.SampleRate <> 16000) or (AInfo.BitsPerSample <> 16) then
    begin
      AError := 'Azure exige WAV PCM 16-bit, mono, 16 kHz.';
      Exit;
    end;
  end;

  if ABackend in [sbWhisperCpp, sbSherpaOnnx] then
  begin
    if AInfo.BitsPerSample <> 16 then
    begin
      AError := 'Este backend espera WAV PCM 16-bit.';
      Exit;
    end;
  end;

  Result := True;
end;

function TAISpeechRecognizer.ValidateInputFile(const AWavFile: string): Boolean;
var
  Info: TWavInfo;
  Err: string;
begin
  Result := ValidateWavForBackend(AWavFile, ResolveBackend, Info, Err);
  if not Result then
    SetError(Err)
  else
    ClearError;
end;

function TAISpeechRecognizer.ResolveBackend: TAISpeechBackend;
begin
  Result := FBackend;
  if Result <> sbAuto then
    Exit;

  if BackendConfigured(sbWhisperCpp) then
    Exit(sbWhisperCpp);
  if BackendConfigured(sbSherpaOnnx) then
    Exit(sbSherpaOnnx);
  if BackendConfigured(sbOpenAI) then
    Exit(sbOpenAI);
  if BackendConfigured(sbAzure) then
    Exit(sbAzure);

  Result := sbWhisperCpp;
end;

function TAISpeechRecognizer.BackendConfigured(const ABackend: TAISpeechBackend): Boolean;
begin
  case ABackend of
    sbWhisperCpp:
      Result := (Trim(FWhisperCppModel) <> '') and (Trim(FindWhisperExecutable) <> '');
    sbSherpaOnnx:
      Result := (Trim(FSherpaLibraryPath) <> '') and (Trim(FSherpaEncoderFile) <> '') and
                (Trim(FSherpaDecoderFile) <> '') and (Trim(FSherpaTokensFile) <> '');
    sbOpenAI:
      Result := (Trim(FOpenAIToken) <> '') and (Trim(FOpenAIModel) <> '');
    sbAzure:
      Result := (Trim(FAzureSubscriptionKey) <> '') and ((Trim(FAzureEndpoint) <> '') or (Trim(FAzureRegion) <> ''));
  else
    Result := False;
  end;
end;

function TAISpeechRecognizer.FindWhisperExecutable: string;
var
  Candidate: string;
  Names: array[0..3] of string;
  I: Integer;
begin
  if Trim(FWhisperCppExecutable) <> '' then
  begin
    Candidate := ExpandFileName(FWhisperCppExecutable);
    if FileExists(Candidate) then
      Exit(Candidate);
    {$IFDEF MSWINDOWS}
    if ExtractFileExt(Candidate) = '' then
    begin
      Candidate := Candidate + '.exe';
      if FileExists(Candidate) then
        Exit(Candidate);
    end;
    {$ENDIF}
  end;

  Names[0] := 'whisper-cli';
  Names[1] := 'main';
  Names[2] := 'whisper';
  Names[3] := 'whisper.exe';

  for I := Low(Names) to High(Names) do
  begin
    Candidate := FileSearch(Names[I], GetEnvironmentVariable('PATH'));
    if Candidate = '' then
      Candidate := ExpandFileName(Names[I]);
    if FileExists(Candidate) then
      Exit(Candidate);
  end;

  Result := '';
end;

function TAISpeechRecognizer.BuildWhisperOutputBase(const AInputFile: string): string;
begin
  Result := ExtractFilePath(ExpandFileName(AInputFile)) +
            'taispeech_' +
            FormatDateTime('yyyymmddhhnnsszzz', Now);
end;

function TAISpeechRecognizer.MultipartBoundary: string;
begin
  Result := '----TAISpeechRecognizer' + IntToHex(Random(MaxInt), 8);
end;

function TAISpeechRecognizer.OpenAIJsonEscape(const S: string): string;
begin
  Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
end;

function TAISpeechRecognizer.BuildOpenAIMultipartBody(const AWavFile: string; out ABoundary: string): TMemoryStream;
var
  Boundary, FileName, S: string;
  FS: TFileStream;
  Buf: array[0..8191] of Byte;
  BytesRead: Integer;
begin
  Boundary := MultipartBoundary;
  ABoundary := Boundary;
  Result := TMemoryStream.Create;

  S := '--' + Boundary + #13#10 +
       'Content-Disposition: form-data; name="model"' + #13#10#13#10 +
       FOpenAIModel + #13#10;
  WriteAnsiToStream(Result, S);

  if Trim(FLanguage) <> '' then
  begin
    S := '--' + Boundary + #13#10 +
         'Content-Disposition: form-data; name="language"' + #13#10#13#10 +
         FLanguage + #13#10;
    WriteAnsiToStream(Result, S);
  end;

  if Trim(FPromptText) <> '' then
  begin
    S := '--' + Boundary + #13#10 +
         'Content-Disposition: form-data; name="prompt"' + #13#10#13#10 +
         FPromptText + #13#10;
    WriteAnsiToStream(Result, S);
  end;

  if Trim(FOpenAIResponseFormat) <> '' then
  begin
    S := '--' + Boundary + #13#10 +
         'Content-Disposition: form-data; name="response_format"' + #13#10#13#10 +
         FOpenAIResponseFormat + #13#10;
    WriteAnsiToStream(Result, S);
  end;

  FileName := ExtractFileName(AWavFile);
  S := '--' + Boundary + #13#10 +
       'Content-Disposition: form-data; name="file"; filename="' + OpenAIJsonEscape(FileName) + '"' + #13#10 +
       'Content-Type: audio/wav' + #13#10#13#10;
  WriteAnsiToStream(Result, S);

  FS := TFileStream.Create(AWavFile, fmOpenRead or fmShareDenyNone);
  try
    repeat
      BytesRead := FS.Read(Buf, SizeOf(Buf));
      if BytesRead > 0 then
        Result.WriteBuffer(Buf, BytesRead);
    until BytesRead = 0;
  finally
    FS.Free;
  end;

  WriteAnsiToStream(Result, #13#10 + '--' + Boundary + '--' + #13#10);
  Result.Position := 0;
end;

function TAISpeechRecognizer.GetOutputTextFromResponse(const ABody: string; const AKeyName: string): string;
var
  Parser: TJSONParser;
  Data: TJSONData;
  Obj, Item: TJSONObject;
  Arr: TJSONArray;
  Val: TJSONData;
begin
  Result := '';
  Parser := TJSONParser.Create(ABody);
  try
    Data := Parser.Parse;
    try
      if (Data <> nil) and (Data.JSONType = jtObject) then
      begin
        Obj := TJSONObject(Data);
        Val := Obj.Find(AKeyName);
        if (Val <> nil) and (Val.JSONType = jtString) then
          Exit(Val.AsString);

        Val := Obj.Find('NBest');
        if (Val <> nil) and (Val.JSONType = jtArray) then
        begin
          Arr := TJSONArray(Val);
          if Arr.Count = 0 then
            Exit('');
          if Arr.Items[0].JSONType = jtObject then
          begin
            Item := Arr.Objects[0];
            Val := Item.Find('Display');
            if (Val <> nil) and (Val.JSONType = jtString) then
              Exit(Val.AsString);
            Val := Item.Find('Lexical');
            if (Val <> nil) and (Val.JSONType = jtString) then
              Exit(Val.AsString);
          end;
        end;
      end;
    finally
      Data.Free;
    end;
  finally
    Parser.Free;
  end;
end;

function TAISpeechRecognizer.GetAzureEndpointURL: string;
begin
  if Trim(FAzureEndpoint) <> '' then
    Exit(FAzureEndpoint);

  if Trim(FAzureRegion) = '' then
    Exit('');

  Result := 'https://' + Trim(FAzureRegion) + '.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=' + FLanguage + '&format=' + FAzureFormat;
end;

function TAISpeechRecognizer.LoadSherpaLibrary(out ALib: TLibHandle; out AError: string): Boolean;
var
  Candidates: array[0..3] of string;
  I: Integer;
  BaseDir, Candidate: string;
begin
  Result := False;
  AError := '';
  ALib := NilHandle;

  if Trim(FSherpaLibraryPath) = '' then
  begin
    AError := 'Sherpa library path not configured.';
    Exit;
  end;

  if FileExists(FSherpaLibraryPath) then
  begin
    ALib := SafeLoadLibrary(FSherpaLibraryPath);
    if ALib <> NilHandle then
      Exit(True);
  end;

  BaseDir := ExpandFileName(FSherpaLibraryPath);
  if not DirectoryExists(BaseDir) then
    BaseDir := ExtractFilePath(BaseDir);

  {$IFDEF MSWINDOWS}
  Candidates[0] := 'libsherpa-onnx-c-api.dll';
  Candidates[1] := 'sherpa-onnx-c-api.dll';
  Candidates[2] := 'sherpa-onnx.dll';
  Candidates[3] := 'libsherpa_onnx_c_api.dll';
  {$ELSE}
    {$IFDEF DARWIN}
    Candidates[0] := 'libsherpa-onnx-c-api.dylib';
    Candidates[1] := 'sherpa-onnx-c-api.dylib';
    Candidates[2] := 'libsherpa_onnx_c_api.dylib';
    Candidates[3] := 'sherpa-onnx.dylib';
    {$ELSE}
    Candidates[0] := 'libsherpa-onnx-c-api.so';
    Candidates[1] := 'sherpa-onnx-c-api.so';
    Candidates[2] := 'libsherpa_onnx_c_api.so';
    Candidates[3] := 'sherpa-onnx.so';
    {$ENDIF}
  {$ENDIF}

  for I := Low(Candidates) to High(Candidates) do
  begin
    Candidate := Candidates[I];
    if BaseDir <> '' then
      Candidate := IncludeTrailingPathDelimiter(BaseDir) + Candidate;
    if FileExists(Candidate) then
    begin
      ALib := SafeLoadLibrary(Candidate);
      if ALib <> NilHandle then
        Exit(True);
    end;
  end;

  AError := 'Could not load Sherpa-ONNX C API library from ' + FSherpaLibraryPath;
end;

function TAISpeechRecognizer.PrepareSherpaConfig(out AConfig: TSherpaOnnxOfflineRecognizerConfig): Boolean;
begin
  Result := False;
  FillChar(AConfig, SizeOf(AConfig), 0);

  if (Trim(FSherpaEncoderFile) = '') or (Trim(FSherpaDecoderFile) = '') or (Trim(FSherpaTokensFile) = '') then
    Exit;

  FSherpaEncoderAnsi := AnsiString(FSherpaEncoderFile);
  FSherpaDecoderAnsi := AnsiString(FSherpaDecoderFile);
  FSherpaTokensAnsi := AnsiString(FSherpaTokensFile);
  if Trim(FSherpaProvider) <> '' then
    FSherpaProviderAnsi := AnsiString(FSherpaProvider)
  else
    FSherpaProviderAnsi := 'cpu';

  if Trim(FSherpaTask) <> '' then
    FSherpaTaskAnsi := AnsiString(FSherpaTask)
  else
    FSherpaTaskAnsi := 'transcribe';
  FSherpaLanguageAnsi := AnsiString(FLanguage);
  FSherpaDecodingAnsi := 'greedy_search';

  AConfig.feat_config.sample_rate := 16000;
  AConfig.feat_config.feature_dim := 80;
  AConfig.model_config.whisper.encoder := PAnsiChar(FSherpaEncoderAnsi);
  AConfig.model_config.whisper.decoder := PAnsiChar(FSherpaDecoderAnsi);
  AConfig.model_config.whisper.language := PAnsiChar(FSherpaLanguageAnsi);
  AConfig.model_config.whisper.task := PAnsiChar(FSherpaTaskAnsi);
  AConfig.model_config.whisper.tail_paddings := 0;
  AConfig.model_config.whisper.enable_token_timestamps := 0;
  AConfig.model_config.whisper.enable_segment_timestamps := 0;
  AConfig.model_config.tokens := PAnsiChar(FSherpaTokensAnsi);
  AConfig.model_config.num_threads := FSherpaNumThreads;
  AConfig.model_config.provider := PAnsiChar(FSherpaProviderAnsi);
  AConfig.model_config.debug := 0;
  AConfig.decoding_method := PAnsiChar(FSherpaDecodingAnsi);
  AConfig.max_active_paths := 4;
  Result := True;
end;

function TAISpeechRecognizer.LoadWavSamplesAsMonoFloat(const AFileName: string; out ASamples: TSingleArray; out ASampleRate: Integer; out AError: string): Boolean;
var
  Info: TWavInfo;
  FS: TFileStream;
  SampleCount, I, C: Integer;
  FrameValue: SmallInt;
  FrameSum: Integer;
  Value: Single;
begin
  Result := False;
  AError := '';
  ASampleRate := 0;

  if not ReadWavInfo(AFileName, Info, AError) then
    Exit;

  if (Info.AudioFormat <> 1) or (Info.BitsPerSample <> 16) then
  begin
    AError := 'Somente WAV PCM 16-bit e suportado para este backend.';
    Exit;
  end;

  ASampleRate := Info.SampleRate;
  if Info.Channels = 0 then
  begin
    AError := 'WAV invalido: canais zero.';
    Exit;
  end;

  SampleCount := Integer(Info.DataSize div (Info.Channels * 2));
  if SampleCount <= 0 then
  begin
    AError := 'WAV sem amostras de audio.';
    Exit;
  end;

  SetLength(ASamples, SampleCount);
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    FS.Position := Info.DataOffset;
    for I := 0 to SampleCount - 1 do
    begin
      FrameSum := 0;
      for C := 0 to Info.Channels - 1 do
      begin
        FrameValue := SmallInt(ReadUInt16LE(FS));
        Inc(FrameSum, FrameValue);
      end;
      Value := FrameSum / (Info.Channels * 32768.0);
      if Value > 1.0 then Value := 1.0;
      if Value < -1.0 then Value := -1.0;
      ASamples[I] := Value;
    end;
    Result := True;
  finally
    FS.Free;
  end;
end;

function TAISpeechRecognizer.ExecuteWhisperCpp(const AWavFile: string): Boolean;
var
  ExePath, OutputBase, OutTxt, CommandArg: string;
  Process: TProcess;
  ExtraArgs: TStringList;
  ResponseText, StdErrText: string;
  OutputStream: TInputPipeStream;
  Buf: array[0..2047] of Byte;
  ReadCount: Integer;
  StartTick: QWord;
  Chunk: string;
  OutputText: TStringList;
  procedure DrainPipe;
  begin
    if not Assigned(OutputStream) then
      Exit;
    while OutputStream.NumBytesAvailable > 0 do
    begin
      ReadCount := OutputStream.Read(Buf, SizeOf(Buf));
      if ReadCount > 0 then
      begin
        SetString(Chunk, PAnsiChar(@Buf[0]), ReadCount);
        ResponseText := ResponseText + Chunk;
      end;
    end;
  end;
begin
  Result := False;
  ClearError;

  ExePath := FindWhisperExecutable;
  if ExePath = '' then
  begin
    SetError('Executavel do whisper.cpp nao encontrado.');
    Exit;
  end;

  if Trim(FWhisperCppModel) = '' then
  begin
    SetError('Modelo do whisper.cpp nao informado.');
    Exit;
  end;

  OutputBase := BuildWhisperOutputBase(AWavFile);
  OutTxt := OutputBase + '.txt';

  Process := TProcess.Create(nil);
  ExtraArgs := SplitSimpleArgs(FWhisperCppExtraArgs);
  OutputText := nil;
  ResponseText := '';
  StdErrText := '';
  OutputStream := nil;
  try
    Process.Executable := ExePath;
    Process.Options := [poUsePipes, poNoConsole, poStderrToOutPut];
    Process.Parameters.Add('-m');
    Process.Parameters.Add(FWhisperCppModel);
    if Trim(FLanguage) <> '' then
    begin
      Process.Parameters.Add('-l');
      Process.Parameters.Add(FLanguage);
    end;
    if FWhisperCppThreads > 0 then
    begin
      Process.Parameters.Add('-t');
      Process.Parameters.Add(IntToStr(FWhisperCppThreads));
    end;
    Process.Parameters.Add('-f');
    Process.Parameters.Add(OutputBase);
    Process.Parameters.Add('-otxt');
    if Assigned(ExtraArgs) then
      Process.Parameters.AddStrings(ExtraArgs);
    Process.Parameters.Add(AWavFile);

    Process.Execute;
    OutputStream := Process.Output;
    StartTick := GetTickCount64;

    while Process.Running do
    begin
      DrainPipe;
      if (FTimeoutMs > 0) and ((GetTickCount64 - StartTick) > QWord(FTimeoutMs)) then
      begin
        Process.Terminate(1);
        SetError('Timeout na execucao do whisper.cpp.');
        Exit;
      end;
      Sleep(10);
    end;

    DrainPipe;

    if Process.ExitStatus <> 0 then
    begin
      if Trim(StdErrText) = '' then
        StdErrText := ResponseText;
      SetError('whisper.cpp falhou com codigo ' + IntToStr(Process.ExitStatus) + ': ' + Trim(StdErrText));
      Exit;
    end;

    if not FileExists(OutTxt) then
    begin
      if Trim(ResponseText) <> '' then
      begin
        StoreSuccess('offline.whispercpp', Trim(ResponseText));
        Result := True;
        Exit;
      end;
      SetError('Arquivo de saida do whisper.cpp nao foi gerado.');
      Exit;
    end;

    OutputText := TStringList.Create;
    OutputText.LoadFromFile(OutTxt);
    ResponseText := Trim(StringReplace(StringReplace(StringReplace(OutputText.Text, #13#10, ' ', [rfReplaceAll]), #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
    if ResponseText = '' then
    begin
      SetError('Transcricao vazia retornada pelo whisper.cpp.');
      Exit;
    end;

    StoreSuccess('offline.whispercpp', ResponseText);
    Result := True;
  finally
    if Assigned(OutputText) then
      OutputText.Free;
    ExtraArgs.Free;
    Process.Free;
    if FileExists(OutTxt) then
      DeleteFile(OutTxt);
  end;
end;

function TAISpeechRecognizer.ExecuteOpenAI(const AWavFile: string): Boolean;
var
  Info: TWavInfo;
  Err: string;
  HTTP: TFPHttpClient;
  RequestBody: TMemoryStream;
  Response: TStringStream;
  JsonText, Transcript, Boundary: string;
begin
  Result := False;
  ClearError;

  if not ValidateWavForBackend(AWavFile, sbOpenAI, Info, Err) then
  begin
    SetError(Err);
    Exit;
  end;

  if Trim(FOpenAIToken) = '' then
  begin
    SetError('Token da OpenAI nao informado.');
    Exit;
  end;

  if Trim(FOpenAIEndpoint) = '' then
  begin
    SetError('Endpoint da OpenAI nao informado.');
    Exit;
  end;

  RequestBody := BuildOpenAIMultipartBody(AWavFile, Boundary);
  Response := TStringStream.Create('');
  HTTP := TFPHttpClient.Create(nil);
  try
    HTTP.AllowRedirect := True;
    HTTP.IOTimeout := FTimeoutMs;
    HTTP.ConnectTimeout := FTimeoutMs;
    HTTP.AddHeader('Authorization', 'Bearer ' + FOpenAIToken);
    HTTP.AddHeader('Accept', 'application/json');
    HTTP.AddHeader('Content-Type', 'multipart/form-data; boundary=' + Boundary);
    HTTP.RequestBody := RequestBody;
    HTTP.Post(FOpenAIEndpoint, Response);
    JsonText := Response.DataString;
    Transcript := GetOutputTextFromResponse(JsonText, 'text');
    if Trim(Transcript) = '' then
      Transcript := GetOutputTextFromResponse(JsonText, 'transcript');
    if Trim(Transcript) = '' then
    begin
      SetError('OpenAI retornou resposta vazia ou nao reconhecida.');
      Exit;
    end;
    StoreSuccess('online.openai', Transcript);
    Result := True;
  except
    on E: Exception do
      SetError('Falha na transcricao OpenAI: ' + E.Message);
  end;
  Response.Free;
  RequestBody.Free;
  HTTP.Free;
end;

function TAISpeechRecognizer.ExecuteAzure(const AWavFile: string): Boolean;
var
  Info: TWavInfo;
  Err: string;
  HTTP: TFPHttpClient;
  RequestBody: TFileStream;
  Response: TStringStream;
  Url, JsonText, Transcript, RecognitionStatus: string;
  Parser: TJSONParser;
  Data: TJSONData;
  Obj: TJSONObject;
  Val: TJSONData;
begin
  Result := False;
  ClearError;

  if not ValidateWavForBackend(AWavFile, sbAzure, Info, Err) then
  begin
    SetError(Err);
    Exit;
  end;

  if Trim(FAzureSubscriptionKey) = '' then
  begin
    SetError('Chave do Azure Speech nao informada.');
    Exit;
  end;

  Url := GetAzureEndpointURL;
  if Trim(Url) = '' then
  begin
    SetError('Endpoint/region do Azure Speech nao informado.');
    Exit;
  end;

  RequestBody := TFileStream.Create(AWavFile, fmOpenRead or fmShareDenyNone);
  Response := TStringStream.Create('');
  HTTP := TFPHttpClient.Create(nil);
  try
    HTTP.AllowRedirect := True;
    HTTP.IOTimeout := FTimeoutMs;
    HTTP.ConnectTimeout := FTimeoutMs;
    HTTP.AddHeader('Ocp-Apim-Subscription-Key', FAzureSubscriptionKey);
    HTTP.AddHeader('Accept', 'application/json');
    HTTP.AddHeader('Content-Type', 'audio/wav; codecs=audio/pcm; samplerate=16000');
    HTTP.RequestBody := RequestBody;
    HTTP.Post(Url, Response);
    JsonText := Response.DataString;

    Parser := TJSONParser.Create(JsonText);
    try
      Data := Parser.Parse;
      try
        if (Data <> nil) and (Data.JSONType = jtObject) then
        begin
          Obj := TJSONObject(Data);
          Val := Obj.Find('RecognitionStatus');
          if (Val <> nil) and (Val.JSONType = jtString) then
            RecognitionStatus := Val.AsString
          else
            RecognitionStatus := '';

          Val := Obj.Find('DisplayText');
          if (Val <> nil) and (Val.JSONType = jtString) then
            Transcript := Val.AsString
          else
            Transcript := '';

        end;
      finally
        Data.Free;
      end;
    finally
      Parser.Free;
    end;

    if SameText(RecognitionStatus, 'Success') and (Trim(Transcript) <> '') then
    begin
      StoreSuccess('online.azure', Transcript);
      Result := True;
    end
    else
      SetError('Azure nao retornou reconhecimento bem-sucedido.');
  except
    on E: Exception do
      SetError('Falha na transcricao Azure: ' + E.Message);
  end;
  Response.Free;
  RequestBody.Free;
  HTTP.Free;
end;

function TAISpeechRecognizer.ExecuteSherpaOnnx(const AWavFile: string): Boolean;
var
  Info: TWavInfo;
  Err: string;
  LibHandle: TLibHandle;
  LibErr: string;
  CreateRecognizer: TSherpaOnnxCreateOfflineRecognizer;
  DestroyRecognizer: TSherpaOnnxDestroyOfflineRecognizer;
  CreateStream: TSherpaOnnxCreateOfflineStream;
  DestroyStream: TSherpaOnnxDestroyOfflineStream;
  AcceptWaveform: TSherpaOnnxAcceptWaveformOffline;
  DecodeStream: TSherpaOnnxDecodeOfflineStream;
  GetResult: TSherpaOnnxGetOfflineStreamResult;
  DestroyResult: TSherpaOnnxDestroyOfflineRecognizerResult;
  Recognizer: PSherpaOnnxOfflineRecognizer;
  Stream: PSherpaOnnxOfflineStream;
  ResultPtr: PSherpaOnnxOfflineRecognizerResult;
  Config: TSherpaOnnxOfflineRecognizerConfig;
  Samples: TSingleArray;
  SampleRate: Integer;
  Transcript: string;
begin
  Result := False;
  ClearError;

  if not ValidateWavForBackend(AWavFile, sbSherpaOnnx, Info, Err) then
  begin
    SetError(Err);
    Exit;
  end;

  if not LoadSherpaLibrary(LibHandle, LibErr) then
  begin
    SetError(LibErr);
    Exit;
  end;

  Pointer(CreateRecognizer) := GetProcedureAddress(LibHandle, 'SherpaOnnxCreateOfflineRecognizer');
  Pointer(DestroyRecognizer) := GetProcedureAddress(LibHandle, 'SherpaOnnxDestroyOfflineRecognizer');
  Pointer(CreateStream) := GetProcedureAddress(LibHandle, 'SherpaOnnxCreateOfflineStream');
  Pointer(DestroyStream) := GetProcedureAddress(LibHandle, 'SherpaOnnxDestroyOfflineStream');
  Pointer(AcceptWaveform) := GetProcedureAddress(LibHandle, 'SherpaOnnxAcceptWaveformOffline');
  Pointer(DecodeStream) := GetProcedureAddress(LibHandle, 'SherpaOnnxDecodeOfflineStream');
  Pointer(GetResult) := GetProcedureAddress(LibHandle, 'SherpaOnnxGetOfflineStreamResult');
  Pointer(DestroyResult) := GetProcedureAddress(LibHandle, 'SherpaOnnxDestroyOfflineRecognizerResult');

  if not Assigned(CreateRecognizer) or not Assigned(DestroyRecognizer) or not Assigned(CreateStream) or
     not Assigned(DestroyStream) or not Assigned(AcceptWaveform) or not Assigned(DecodeStream) or
     not Assigned(GetResult) or not Assigned(DestroyResult) then
  begin
    SetError('Funcoes essenciais do Sherpa-ONNX nao encontradas na biblioteca carregada.');
    FreeLibrary(LibHandle);
    Exit;
  end;

  if not PrepareSherpaConfig(Config) then
  begin
    SetError('Configuracao do Sherpa-ONNX incompleta.');
    FreeLibrary(LibHandle);
    Exit;
  end;

  SetLength(Samples, 0);
  if not LoadWavSamplesAsMonoFloat(AWavFile, Samples, SampleRate, Err) then
  begin
    SetError(Err);
    FreeLibrary(LibHandle);
    Exit;
  end;

  Recognizer := CreateRecognizer(@Config);
  if Recognizer = nil then
  begin
    SetError('Sherpa-ONNX recusou a configuracao informada.');
    FreeLibrary(LibHandle);
    Exit;
  end;

  Stream := nil;
  ResultPtr := nil;
  try
    Stream := CreateStream(Recognizer);
    if Stream = nil then
    begin
      SetError('Sherpa-ONNX nao criou a stream de reconhecimento.');
      Exit;
    end;

    if Length(Samples) > 0 then
      AcceptWaveform(Stream, SampleRate, @Samples[0], Length(Samples));

    DecodeStream(Recognizer, Stream);
    ResultPtr := GetResult(Stream);
    if (ResultPtr = nil) or (ResultPtr^.text = nil) then
    begin
      SetError('Sherpa-ONNX nao retornou texto.');
      Exit;
    end;

    Transcript := string(ResultPtr^.text);
    if Trim(Transcript) = '' then
    begin
      SetError('Sherpa-ONNX retornou texto vazio.');
      Exit;
    end;

    StoreSuccess('offline.sherpaonnx', Transcript);
    Result := True;
  finally
    if ResultPtr <> nil then
      DestroyResult(ResultPtr);
    if Stream <> nil then
      DestroyStream(Stream);
    if Recognizer <> nil then
      DestroyRecognizer(Recognizer);
    FreeLibrary(LibHandle);
  end;
end;

procedure TAISpeechRecognizer.GetSupportedBackends(AList: TStrings);
begin
  AList.Clear;
  AList.Add('offline.whispercpp');
  AList.Add('offline.sherpaonnx');
  AList.Add('online.openai');
  AList.Add('online.azure');
end;

function TAISpeechRecognizer.RecognizeFile(const AWavFile: string): Boolean;
var
  BackendToUse: TAISpeechBackend;
  Info: TWavInfo;
  Err: string;
begin
  Result := False;
  ClearError;

  FInputFile := AWavFile;
  BackendToUse := ResolveBackend;

  if not ValidateWavForBackend(AWavFile, BackendToUse, Info, Err) then
  begin
    SetError(Err);
    Exit;
  end;

  case BackendToUse of
    sbWhisperCpp:
      Result := ExecuteWhisperCpp(AWavFile);
    sbSherpaOnnx:
      Result := ExecuteSherpaOnnx(AWavFile);
    sbOpenAI:
      Result := ExecuteOpenAI(AWavFile);
    sbAzure:
      Result := ExecuteAzure(AWavFile);
  else
    SetError('Backend de reconhecimento nao suportado.');
  end;

  if Result and (Trim(FLastResult) = '') then
    FLastResult := '';
end;

function TAISpeechRecognizer.Recognize: Boolean;
begin
  if Trim(FInputFile) = '' then
  begin
    SetError('InputFile nao foi definido.');
    Exit(False);
  end;
  Result := RecognizeFile(FInputFile);
end;

initialization
  {$I aispeechrecognizer_icon.lrs}

end.
