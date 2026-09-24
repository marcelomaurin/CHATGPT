unit aivoicesynthesizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF MSWINDOWS}
  ComObj, ActiveX, Variants, Windows,
  {$ENDIF}
  DynLibs, aibase, LResources, md5,
  aivoiceprovider_types,
  aivoiceprovider_backend,
  aivoiceprovider_openai,
  aivoiceprovider_openaicompatible,
  aivoiceprovider_customhttp,
  aiaudioplayback;

type
  { Baseline speech engines supported:
    - seSystemDefault : OS default (SAPI on Windows, eSpeak on Linux)
    - seSAPI          : Microsoft Speech API via COM/OLE
    - seEspeak        : eSpeak / eSpeak-NG via dynamic library
    - seOpenAI        : OpenAI Speech API (maintained for backward compatibility;
                        delegates to TAIOpenAIVoiceBackend) }
  TSpeechEngine = (seSystemDefault, seSAPI, seEspeak, seOpenAI);

  Pespeak_VOICE = ^Tespeak_VOICE;
  Tespeak_VOICE = record
    name       : PAnsiChar;
    languages  : PAnsiChar;
    identifier : PAnsiChar;
    gender     : Byte;
    age        : Byte;
    variant    : Byte;
    xx1        : Byte;
    score      : Integer;
    spare      : Pointer;
  end;
  PPespeak_VOICE = ^Pespeak_VOICE;

  { eSpeak C API function pointer signatures }
  Tespeak_Initialize = function(output: Integer; buf_length: Integer; path: PAnsiChar; options: Integer): Integer; cdecl;
  Tespeak_SetVoiceByName = function(name: PAnsiChar): Integer; cdecl;
  Tespeak_SetVolume = function(volume: Integer): Integer; cdecl;
  Tespeak_SetRate = function(rate: Integer): Integer; cdecl;
  Tespeak_Synth = function(text: PAnsiChar; size: SizeInt; position: Cardinal; position_type: Integer; end_position: Cardinal; flags: Cardinal; unique_identifier: PCardinal; user_data: Pointer): Integer; cdecl;
  Tespeak_Terminate = function: Integer; cdecl;
  Tespeak_ListVoices = function(voice_selector: Pointer): PPespeak_VOICE; cdecl;

  { TAIVoiceSynthesizer }

  TAIVoiceSynthesizer = class(TAIBaseComponent)
  private
    FText         : string;
    FVolume       : Integer;
    FRate         : Integer;
    FVoiceName    : string;
    FAsynchronous : Boolean;
    FEngine       : TSpeechEngine;

    // Generic remote provider fields
    FProvider          : TAIVoiceProvider;
    FAPIToken          : string;
    FModel             : string;
    FEndpoint          : string;
    FRemoteVoice       : string;
    FLanguage          : string;
    FOutputFormat      : string;
    FOutputFile        : string;
    FInstructions      : string;
    FSpeed             : Double;
    FRemoteTimeoutMS   : Integer;
    FMaxRetries        : Integer;
    FEnableFallback    : Boolean;
    FFallbackEngine    : TSpeechEngine;
    FEnableCache       : Boolean;
    FCacheDir          : string;
    FAutoPlay          : Boolean;

    // Telemetry and state
    FState             : TAIVoiceState;
    FLastUsage         : TAIVoiceUsage;
    FAudioLevel        : Single;
    FCurrentBackend    : IAIVoiceProviderBackend;

    // Audio playback integration
    FAudioPlayer       : TAIAudioPlayer;
    FInternalAudioPlayer: TAIAudioPlayer;

    // Events
    FOnSynthesisStart  : TNotifyEvent;
    FOnSynthesisEnd    : TNotifyEvent;
    FOnSpeechStart     : TNotifyEvent;
    FOnSpeechProgress  : TNotifyEvent;
    FOnSpeechEnd       : TNotifyEvent;

    {$IFDEF MSWINDOWS}
    FSpVoice           : OleVariant;
    FSpVoiceCreated    : Boolean;
    {$ENDIF}

    // eSpeak dynamically loaded fields
    FLibHandle         : TLibHandle;
    FInitialized       : Boolean;
    espeak_Initialize     : Tespeak_Initialize;
    espeak_SetVoiceByName : Tespeak_SetVoiceByName;
    espeak_SetVolume      : Tespeak_SetVolume;
    espeak_SetRate        : Tespeak_SetRate;
    espeak_Synth          : Tespeak_Synth;
    espeak_Terminate      : Tespeak_Terminate;
    espeak_ListVoices     : Tespeak_ListVoices;

    function InitEspeak: Boolean;
    procedure UnloadEspeak;

    // Internal helpers
    function GetEffectiveProvider: TAIVoiceProvider;
    function BuildCurrentConfig: TAIVoiceConfig;
    function ComputeCacheHash(const AConfig: TAIVoiceConfig; const AText: string): string;
    function GetEffectiveAudioPlayer: TAIAudioPlayer;
    procedure SetState(AState: TAIVoiceState);
    procedure FireSpeechEndOnce;
    function SynthesizeRemote(const AText: string; out AOutputFile: string): Boolean;
    procedure SpeakLocal(const AEngineToUse: TSpeechEngine; const AText: string);

    // Legacy OpenAI property getters/setters for 100% backward compatibility
    function GetOpenAIToken: string;
    procedure SetOpenAIToken(const AValue: string);
    function GetOpenAIModel: string;
    procedure SetOpenAIModel(const AValue: string);
    function GetOpenAIEndpoint: string;
    procedure SetOpenAIEndpoint(const AValue: string);
    function GetOpenAIVoice: string;
    procedure SetOpenAIVoice(const AValue: string);
    function GetOpenAIInstructions: string;
    procedure SetOpenAIInstructions(const AValue: string);
    function GetOpenAIOutputFormat: string;
    procedure SetOpenAIOutputFormat(const AValue: string);
    function GetOpenAIOutputFile: string;
    procedure SetOpenAIOutputFile(const AValue: string);
    procedure SetProvider(AValue: TAIVoiceProvider);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Say(const AText: string = '');
    procedure Stop;
    procedure GetAvailableVoices(AList: TStrings);
    function ValidateRemoteConfig(const AText: string): Boolean;
    function ValidateOpenAIConfig(const AText: string): Boolean;
    function TestConfiguration(out AMessage: string): Boolean;
    function CreateProviderBackend: IAIVoiceProviderBackend;
    function JSONEscape(const S: string): string;

    property State: TAIVoiceState read FState;
    property LastUsage: TAIVoiceUsage read FLastUsage;

  published
    property Text: string read FText write FText;
    property Volume: Integer read FVolume write FVolume default 100;
    property Rate: Integer read FRate write FRate default 0;
    property VoiceName: string read FVoiceName write FVoiceName;
    property Asynchronous: Boolean read FAsynchronous write FAsynchronous default True;
    property Engine: TSpeechEngine read FEngine write FEngine default seSystemDefault;

    // Generic Remote Provider Properties
    property Provider: TAIVoiceProvider read FProvider write SetProvider default vpNone;
    property APIToken: string read FAPIToken write FAPIToken;
    property Model: string read FModel write FModel;
    property Endpoint: string read FEndpoint write FEndpoint;
    property RemoteVoice: string read FRemoteVoice write FRemoteVoice;
    property Language: string read FLanguage write FLanguage;
    property OutputFormat: string read FOutputFormat write FOutputFormat;
    property OutputFile: string read FOutputFile write FOutputFile;
    property Instructions: string read FInstructions write FInstructions;
    property Speed: Double read FSpeed write FSpeed;
    property RemoteTimeoutMS: Integer read FRemoteTimeoutMS write FRemoteTimeoutMS default 30000;
    property MaxRetries: Integer read FMaxRetries write FMaxRetries default 1;
    property EnableFallback: Boolean read FEnableFallback write FEnableFallback default False;
    property FallbackEngine: TSpeechEngine read FFallbackEngine write FFallbackEngine default seSystemDefault;
    property EnableCache: Boolean read FEnableCache write FEnableCache default True;
    property CacheDir: string read FCacheDir write FCacheDir;
    property AutoPlay: Boolean read FAutoPlay write FAutoPlay default True;
    property AudioPlayer: TAIAudioPlayer read FAudioPlayer write FAudioPlayer;
    property AudioLevel: Single read FAudioLevel write FAudioLevel;

    // Backward compatibility aliases
    property OpenAIToken: string read GetOpenAIToken write SetOpenAIToken;
    property OpenAIModel: string read GetOpenAIModel write SetOpenAIModel;
    property OpenAIEndpoint: string read GetOpenAIEndpoint write SetOpenAIEndpoint;
    property OpenAIVoice: string read GetOpenAIVoice write SetOpenAIVoice;
    property OpenAIInstructions: string read GetOpenAIInstructions write SetOpenAIInstructions;
    property OpenAIOutputFormat: string read GetOpenAIOutputFormat write SetOpenAIOutputFormat;
    property OpenAIOutputFile: string read GetOpenAIOutputFile write SetOpenAIOutputFile;

    // Lifecycle events
    property OnSynthesisStart: TNotifyEvent read FOnSynthesisStart write FOnSynthesisStart;
    property OnSynthesisEnd: TNotifyEvent read FOnSynthesisEnd write FOnSynthesisEnd;
    property OnSpeechStart: TNotifyEvent read FOnSpeechStart write FOnSpeechStart;
    property OnSpeechProgress: TNotifyEvent read FOnSpeechProgress write FOnSpeechProgress;
    property OnSpeechEnd: TNotifyEvent read FOnSpeechEnd write FOnSpeechEnd;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Audio', [TAIVoiceSynthesizer]);
end;

{ TAIVoiceSynthesizer }

constructor TAIVoiceSynthesizer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIVoiceSynthesizer is an AI text-to-speech component. Supports local SAPI/eSpeak engines and remote cloud providers (OpenAI, OpenAI-Compatible, Google, Azure, ElevenLabs, Custom HTTP). Methods: Say(AText), Stop, TestConfiguration(AMessage), GetAvailableVoices(AList).';
  FText := '';
  FVolume := 100;
  FRate := 0;
  FVoiceName := '';
  FAsynchronous := True;
  FEngine := seSystemDefault;

  FProvider := vpNone;
  FAPIToken := '';
  FModel := 'gpt-4o-mini-tts';
  FEndpoint := 'https://api.openai.com/v1/audio/speech';
  FRemoteVoice := 'alloy';
  FLanguage := 'pt-BR';
  FOutputFormat := 'mp3';
  FOutputFile := 'output' + DirectorySeparator + 'speech.mp3';
  FInstructions := '';
  FSpeed := 1.0;
  FRemoteTimeoutMS := 30000;
  FMaxRetries := 1;
  FEnableFallback := False;
  FFallbackEngine := seSystemDefault;
  FEnableCache := True;
  FCacheDir := 'cache' + DirectorySeparator + 'tts';
  FAutoPlay := True;

  FState := vsIdle;
  FAudioLevel := 0.0;
  FAudioPlayer := nil;
  FInternalAudioPlayer := nil;
  FCurrentBackend := nil;

  FillChar(FLastUsage, SizeOf(FLastUsage), 0);

  {$IFDEF MSWINDOWS}
  FSpVoiceCreated := False;
  {$ENDIF}

  FLibHandle := NilHandle;
  FInitialized := False;
  espeak_Initialize := nil;
  espeak_SetVoiceByName := nil;
  espeak_SetVolume := nil;
  espeak_SetRate := nil;
  espeak_Synth := nil;
  espeak_Terminate := nil;
  espeak_ListVoices := nil;
end;

destructor TAIVoiceSynthesizer.Destroy;
begin
  Stop;
  UnloadEspeak;
  if Assigned(FInternalAudioPlayer) then
    FreeAndNil(FInternalAudioPlayer);

  {$IFDEF MSWINDOWS}
  if FSpVoiceCreated then
  begin
    try
      FSpVoice := Unassigned;
      ActiveX.CoUninitialize();
    except
    end;
    FSpVoiceCreated := False;
  end;
  {$ENDIF}
  inherited Destroy;
end;

procedure TAIVoiceSynthesizer.SetState(AState: TAIVoiceState);
begin
  FState := AState;
end;

procedure TAIVoiceSynthesizer.FireSpeechEndOnce;
begin
  FAudioLevel := 0.0;
  if FState <> vsIdle then
    SetState(vsIdle);
  if Assigned(FOnSpeechEnd) then
    FOnSpeechEnd(Self);
end;

function TAIVoiceSynthesizer.GetEffectiveProvider: TAIVoiceProvider;
begin
  if FProvider <> vpNone then
    Result := FProvider
  else if FEngine = seOpenAI then
    Result := vpOpenAI
  else
    Result := vpNone;
end;

procedure TAIVoiceSynthesizer.SetProvider(AValue: TAIVoiceProvider);
begin
  FProvider := AValue;
  // Apply reasonable defaults if switching to OpenAI
  if FProvider = vpOpenAI then
  begin
    if Trim(FEndpoint) = '' then
      FEndpoint := 'https://api.openai.com/v1/audio/speech';
    if Trim(FModel) = '' then
      FModel := 'gpt-4o-mini-tts';
    if Trim(FRemoteVoice) = '' then
      FRemoteVoice := 'alloy';
    if Trim(FOutputFormat) = '' then
      FOutputFormat := 'mp3';
  end;
end;

function TAIVoiceSynthesizer.GetEffectiveAudioPlayer: TAIAudioPlayer;
begin
  if Assigned(FAudioPlayer) then
    Result := FAudioPlayer
  else
  begin
    if not Assigned(FInternalAudioPlayer) then
      FInternalAudioPlayer := TAIAudioPlayer.Create(Self);
    Result := FInternalAudioPlayer;
  end;
end;

function TAIVoiceSynthesizer.BuildCurrentConfig: TAIVoiceConfig;
begin
  Result.Provider     := GetEffectiveProvider;
  Result.APIToken     := FAPIToken;
  Result.Model        := FModel;
  Result.Endpoint     := FEndpoint;
  Result.RemoteVoice  := FRemoteVoice;
  Result.Language     := FLanguage;
  Result.OutputFormat := FOutputFormat;
  Result.OutputFile   := FOutputFile;
  Result.Speed        := FSpeed;
  Result.Instructions := FInstructions;
  Result.TimeoutMS    := FRemoteTimeoutMS;
  Result.MaxRetries   := FMaxRetries;
end;

function TAIVoiceSynthesizer.CreateProviderBackend: IAIVoiceProviderBackend;
var
  EffProvider: TAIVoiceProvider;
begin
  EffProvider := GetEffectiveProvider;
  case EffProvider of
    vpOpenAI:
      Result := TAIOpenAIVoiceBackend.Create;
    vpOpenAICompatible:
      Result := TAIOpenAICompatibleVoiceBackend.Create;
    vpCustomHTTP:
      Result := TAICustomHTTPVoiceBackend.Create;
    vpGoogle:
      Result := TAIUnimplementedVoiceBackend.Create('Google Cloud TTS');
    vpAzure:
      Result := TAIUnimplementedVoiceBackend.Create('Microsoft Azure Speech');
    vpElevenLabs:
      Result := TAIUnimplementedVoiceBackend.Create('ElevenLabs TTS');
  else
    Result := nil;
  end;
end;

function TAIVoiceSynthesizer.ValidateRemoteConfig(const AText: string): Boolean;
var
  Cfg: TAIVoiceConfig;
  Backend: IAIVoiceProviderBackend;
  ErrMsg: string;
begin
  Result := False;
  Cfg := BuildCurrentConfig;

  if Cfg.Provider = vpNone then
  begin
    SetError('No remote voice provider selected.');
    Exit;
  end;

  if Trim(AText) = '' then
  begin
    SetError('Text is empty.');
    Exit;
  end;

  if (Cfg.Provider = vpOpenAI) and (Trim(Cfg.APIToken) = '') then
  begin
    SetError('OpenAI API token is required.');
    Exit;
  end;

  if Trim(Cfg.Endpoint) = '' then
  begin
    SetError('Endpoint is required.');
    Exit;
  end;

  if Trim(Cfg.Model) = '' then
  begin
    SetError('Model is required.');
    Exit;
  end;

  if (Cfg.Provider = vpOpenAI) and (Trim(Cfg.RemoteVoice) = '') then
  begin
    SetError('Voice is required.');
    Exit;
  end;

  if Trim(Cfg.OutputFormat) = '' then
  begin
    SetError('Output format is required.');
    Exit;
  end;

  if (Cfg.Speed < 0.25) or (Cfg.Speed > 4.0) then
  begin
    SetError('Speed must be between 0.25 and 4.0.');
    Exit;
  end;

  Backend := CreateProviderBackend;
  if not Assigned(Backend) then
  begin
    SetError('Failed to create voice provider backend for: ' + VoiceProviderToString(Cfg.Provider));
    Exit;
  end;

  Result := Backend.ValidateConfig(Cfg, AText, ErrMsg);
  if not Result then
    SetError(ErrMsg);
end;

function TAIVoiceSynthesizer.ValidateOpenAIConfig(const AText: string): Boolean;
begin
  Result := ValidateRemoteConfig(AText);
end;

function TAIVoiceSynthesizer.TestConfiguration(out AMessage: string): Boolean;
var
  Cfg: TAIVoiceConfig;
  Backend: IAIVoiceProviderBackend;
  ErrMsg: string;
begin
  Result := False;
  AMessage := '';
  Cfg := BuildCurrentConfig;

  if (Cfg.Provider = vpNone) and (FEngine <> seOpenAI) then
  begin
    AMessage := 'Local engine configured (' + BoolToStr(FEngine = seSAPI, 'SAPI', 'eSpeak') + '). No remote credentials needed.';
    Result := True;
    Exit;
  end;

  Backend := CreateProviderBackend;
  if not Assigned(Backend) then
  begin
    AMessage := 'Voice provider backend not available for: ' + VoiceProviderToString(Cfg.Provider);
    Exit;
  end;

  if not Backend.ValidateConfig(Cfg, 'Teste de voz do Professor Virtual da FATEC.', ErrMsg) then
  begin
    AMessage := 'Validation failed: ' + ErrMsg;
    Exit;
  end;

  AMessage := 'Configuration valid for provider ' + VoiceProviderToString(Cfg.Provider) + ' (Model: ' + Cfg.Model + ')';
  Result := True;
end;

function TAIVoiceSynthesizer.ComputeCacheHash(const AConfig: TAIVoiceConfig; const AText: string): string;
var
  RawStr: string;
begin
  RawStr := Format('%s|%s|%s|%s|%0.2f|%s|%s', [
    VoiceProviderToString(AConfig.Provider),
    AConfig.Model,
    AConfig.RemoteVoice,
    AConfig.OutputFormat,
    AConfig.Speed,
    AConfig.Instructions,
    AText
  ]);
  Result := MD5Print(MD5String(RawStr));
end;

function TAIVoiceSynthesizer.JSONEscape(const S: string): string;
var
  I: Integer;
  C: Char;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    case C of
      '"':  Result := Result + '\"';
      '\':  Result := Result + '\\';
      '/':  Result := Result + '\/';
      #8:   Result := Result + '\b';
      #9:   Result := Result + '\t';
      #10:  Result := Result + '\n';
      #12:  Result := Result + '\f';
      #13:  Result := Result + '\r';
    else
      Result := Result + C;
    end;
  end;
end;

function TAIVoiceSynthesizer.SynthesizeRemote(const AText: string; out AOutputFile: string): Boolean;
var
  Cfg: TAIVoiceConfig;
  Backend: IAIVoiceProviderBackend;
  ErrMsg: string;
  StartTime: QWord;
  CacheFile: string;
  HashStr: string;
  FormatExt: string;
begin
  Result := False;
  AOutputFile := '';
  Cfg := BuildCurrentConfig;

  FillChar(FLastUsage, SizeOf(FLastUsage), 0);
  FLastUsage.Provider := Cfg.Provider;
  FLastUsage.Model := Cfg.Model;
  FLastUsage.Voice := Cfg.RemoteVoice;
  FLastUsage.Characters := Length(AText);

  FormatExt := LowerCase(Trim(Cfg.OutputFormat));
  if FormatExt = '' then FormatExt := 'mp3';

  // Check audio cache
  if FEnableCache then
  begin
    if not DirectoryExists(FCacheDir) then
      ForceDirectories(FCacheDir);

    HashStr := ComputeCacheHash(Cfg, AText);
    CacheFile := IncludeTrailingPathDelimiter(FCacheDir) + 'tts_' + HashStr + '.' + FormatExt;

    if FileExists(CacheFile) then
    begin
      AOutputFile := CacheFile;
      FLastResult := CacheFile;
      FLastSuccess := True;
      FLastUsage.Success := True;
      Result := True;
      Exit;
    end;
  end;

  Backend := CreateProviderBackend;
  if not Assigned(Backend) then
  begin
    SetError('Unsupported voice provider: ' + VoiceProviderToString(Cfg.Provider));
    FLastUsage.ErrorCode := FLastError;
    Exit;
  end;

  FCurrentBackend := Backend;
  if Trim(AOutputFile) = '' then
  begin
    if FEnableCache and (CacheFile <> '') then
      AOutputFile := CacheFile
    else
    begin
      if Trim(Cfg.OutputFile) <> '' then
        AOutputFile := Cfg.OutputFile
      else
        AOutputFile := 'output' + DirectorySeparator + 'speech.' + FormatExt;
    end;
  end;

  StartTime := GetTickCount64;
  try
    Result := Backend.Synthesize(Cfg, AText, AOutputFile, ErrMsg);
    FLastUsage.RequestDurationMS := GetTickCount64 - StartTime;
    FLastUsage.Success := Result;

    if Result then
    begin
      FLastResult := AOutputFile;
      FLastSuccess := True;
    end
    else
    begin
      FLastUsage.ErrorCode := ErrMsg;
      SetError(ErrMsg);
    end;
  finally
    FCurrentBackend := nil;
  end;
end;

procedure TAIVoiceSynthesizer.SpeakLocal(const AEngineToUse: TSpeechEngine; const AText: string);
var
  SpeakText: string;
  {$IFDEF MSWINDOWS}
  Flags: Integer;
  {$ENDIF}
begin
  SpeakText := AText;
  if SpeakText = '' then Exit;

  FAudioLevel := 0.75;
  SetState(vsPlaying);
  if Assigned(FOnSpeechStart) then
    FOnSpeechStart(Self);

  // SAPI implementation
  if (AEngineToUse = seSAPI) or ((AEngineToUse = seSystemDefault) and
     {$IFDEF MSWINDOWS}True{$ELSE}False{$ENDIF}) then
  begin
    {$IFDEF MSWINDOWS}
    try
      if not FSpVoiceCreated then
      begin
        ActiveX.CoInitialize(nil);
        FSpVoice := CreateOleObject('SAPI.SpVoice');
        FSpVoiceCreated := True;
      end;

      if FVolume < 0 then FVolume := 0;
      if FVolume > 100 then FVolume := 100;
      FSpVoice.Volume := FVolume;

      if FRate < -10 then FRate := -10;
      if FRate > 10 then FRate := 10;
      FSpVoice.Rate := FRate;

      if FVoiceName <> '' then
      begin
        try
          FSpVoice.Voice := FSpVoice.GetVoices('Name=' + FVoiceName).Item(0);
        except
        end;
      end;

      if FAsynchronous then
        Flags := 1
      else
        Flags := 0;

      FSpVoice.Speak(SpeakText, Flags);
      FLastResult := 'Speech synthesis completed (SAPI)';
      FLastSuccess := True;
    except
      on E: Exception do
      begin
        SetState(vsError);
        SetError('Exceção ao sintetizar voz via SAPI: ' + E.Message);
      end;
    end;
    {$ELSE}
    SetError('SAPI é suportado apenas no Windows.');
    {$ENDIF}
  end
  else
  begin
    // eSpeak implementation
    if not FInitialized then
    begin
      if not InitEspeak then
      begin
        SetState(vsError);
        FireSpeechEndOnce;
        Exit;
      end;
    end;

    if FInitialized and Assigned(espeak_Synth) then
    begin
      try
        if FVolume < 0 then FVolume := 0;
        if FVolume > 100 then FVolume := 100;
        if Assigned(espeak_SetVolume) then
          espeak_SetVolume(FVolume);

        if FRate < -10 then FRate := -10;
        if FRate > 10 then FRate := 10;
        if Assigned(espeak_SetRate) then
          espeak_SetRate(175 + (FRate * 12));

        if (FVoiceName <> '') and Assigned(espeak_SetVoiceByName) then
          espeak_SetVoiceByName(PAnsiChar(AnsiString(FVoiceName)));

        espeak_Synth(PAnsiChar(AnsiString(SpeakText)), Length(SpeakText) + 1, 0, 0, 0, 1, nil, nil);
        FLastResult := 'Speech synthesis completed (eSpeak)';
        FLastSuccess := True;
      except
        on E: Exception do
        begin
          SetState(vsError);
          SetError('Exceção ao sintetizar voz via eSpeak: ' + E.Message);
        end;
      end;
    end;
  end;

  FireSpeechEndOnce;
end;

procedure TAIVoiceSynthesizer.Say(const AText: string);
var
  SpeakText: string;
  EffProvider: TAIVoiceProvider;
  SynthesizedFile: string;
  Player: TAIAudioPlayer;
begin
  ClearError;
  if AText <> '' then
    FText := AText;

  SpeakText := FText;
  if Trim(SpeakText) = '' then Exit;

  EffProvider := GetEffectiveProvider;

  // Remote TTS synthesis pathway
  if EffProvider <> vpNone then
  begin
    SetState(vsSynthesizing);
    if Assigned(FOnSynthesisStart) then
      FOnSynthesisStart(Self);

    if not SynthesizeRemote(SpeakText, SynthesizedFile) then
    begin
      SetState(vsError);
      if Assigned(FOnSynthesisEnd) then
        FOnSynthesisEnd(Self);

      // Check fallback option
      if FEnableFallback then
      begin
        FLastUsage.FallbackUsed := True;
        SpeakLocal(FFallbackEngine, SpeakText);
        Exit;
      end;

      FireSpeechEndOnce;
      Exit;
    end;

    if Assigned(FOnSynthesisEnd) then
      FOnSynthesisEnd(Self);

    // Audio Playback
    if FAutoPlay and FileExists(SynthesizedFile) then
    begin
      SetState(vsPlaying);
      FAudioLevel := 0.75;
      if Assigned(FOnSpeechStart) then
        FOnSpeechStart(Self);

      Player := GetEffectiveAudioPlayer;
      if Assigned(Player) then
      begin
        Player.Play(SynthesizedFile);
      end;

      FireSpeechEndOnce;
    end
    else
    begin
      FireSpeechEndOnce;
    end;

    Exit;
  end;

  // Local speech engine pathway (SAPI or eSpeak)
  SpeakLocal(FEngine, SpeakText);
end;

procedure TAIVoiceSynthesizer.Stop;
begin
  SetState(vsStopping);

  // Cancel any ongoing HTTP synthesis
  if Assigned(FCurrentBackend) then
  begin
    try
      FCurrentBackend.Cancel;
    except
    end;
  end;

  // Stop audio player
  if Assigned(FAudioPlayer) then
    FAudioPlayer.Stop;
  if Assigned(FInternalAudioPlayer) then
    FInternalAudioPlayer.Stop;

  // Stop SAPI
  {$IFDEF MSWINDOWS}
  try
    if FSpVoiceCreated then
      FSpVoice.Speak('', 2); // SVSFPurgeBeforeSpeak
  except
  end;
  {$ENDIF}

  // Stop eSpeak
  if FInitialized and Assigned(espeak_Terminate) then
  begin
    try
      espeak_Terminate();
      FInitialized := False;
    except
    end;
  end;

  FireSpeechEndOnce;
end;

procedure TAIVoiceSynthesizer.GetAvailableVoices(AList: TStrings);
var
  {$IFDEF MSWINDOWS}
  Voices: OleVariant;
  I: Integer;
  {$ENDIF}
  VoiceList: PPespeak_VOICE;
  VoicePtr: Pespeak_VOICE;
  Idx: Integer;
begin
  AList.Clear;
  ClearError;

  if (FEngine = seSAPI) or ((FEngine = seSystemDefault) and
     {$IFDEF MSWINDOWS}True{$ELSE}False{$ENDIF}) then
  begin
    {$IFDEF MSWINDOWS}
    try
      if not FSpVoiceCreated then
      begin
        ActiveX.CoInitialize(nil);
        FSpVoice := CreateOleObject('SAPI.SpVoice');
        FSpVoiceCreated := True;
      end;
      Voices := FSpVoice.GetVoices;
      for I := 0 to Voices.Count - 1 do
      begin
        try
          AList.Add(Voices.Item(I).GetAttribute('Name'));
        except
          try
            AList.Add(Voices.Item(I).GetDescription);
          except
          end;
        end;
      end;
      FLastResult := 'SAPI voices retrieved successfully';
      FLastSuccess := True;
    except
      on E: Exception do
        SetError('Exceção ao listar vozes via SAPI: ' + E.Message);
    end;
    {$ELSE}
    SetError('SAPI é suportado apenas no Windows.');
    {$ENDIF}
  end
  else
  begin
    // eSpeak
    if not FInitialized then
    begin
      if not InitEspeak then Exit;
    end;

    if FInitialized and Assigned(espeak_ListVoices) then
    begin
      try
        VoiceList := espeak_ListVoices(nil);
        if Assigned(VoiceList) then
        begin
          Idx := 0;
          while Assigned(VoiceList[Idx]) do
          begin
            VoicePtr := VoiceList[Idx];
            if Assigned(VoicePtr^.name) then
            begin
              AList.Add(string(VoicePtr^.name));
            end;
            Inc(Idx);
          end;
        end;
        FLastResult := 'eSpeak voices retrieved successfully';
        FLastSuccess := True;
      except
        on E: Exception do
          SetError('Exceção ao listar vozes via eSpeak: ' + E.Message);
      end;
    end;
  end;
end;

function TAIVoiceSynthesizer.InitEspeak: Boolean;
var
  Candidates: array[0..3] of string;
  I: Integer;
begin
  Result := False;
  if FInitialized then Exit(True);

  FLibHandle := NilHandle;

  {$IFDEF MSWINDOWS}
  Candidates[0] := 'libespeak-ng.dll';
  Candidates[1] := 'espeak.dll';
  Candidates[2] := 'libespeak.dll';
  Candidates[3] := 'espeak-ng.dll';
  {$ELSE}
  Candidates[0] := 'libespeak-ng.so.1';
  Candidates[1] := 'libespeak.so.1';
  Candidates[2] := 'libespeak-ng.so';
  Candidates[3] := 'libespeak.so';
  {$ENDIF}

  for I := 0 to 3 do
  begin
    FLibHandle := SafeLoadLibrary(Candidates[I]);
    if FLibHandle <> NilHandle then
      Break;
  end;

  if FLibHandle = NilHandle then
  begin
    SetError('Falha ao carregar biblioteca eSpeak.');
    Exit;
  end;

  espeak_Initialize := Tespeak_Initialize(GetProcedureAddress(FLibHandle, 'espeak_Initialize'));
  espeak_SetVoiceByName := Tespeak_SetVoiceByName(GetProcedureAddress(FLibHandle, 'espeak_SetVoiceByName'));
  espeak_SetVolume := Tespeak_SetVolume(GetProcedureAddress(FLibHandle, 'espeak_SetVolume'));
  espeak_SetRate := Tespeak_SetRate(GetProcedureAddress(FLibHandle, 'espeak_SetRate'));
  espeak_Synth := Tespeak_Synth(GetProcedureAddress(FLibHandle, 'espeak_Synth'));
  espeak_Terminate := Tespeak_Terminate(GetProcedureAddress(FLibHandle, 'espeak_Terminate'));
  espeak_ListVoices := Tespeak_ListVoices(GetProcedureAddress(FLibHandle, 'espeak_ListVoices'));

  if not Assigned(espeak_Initialize) or not Assigned(espeak_Synth) then
  begin
    SetError('Funções essenciais do eSpeak não foram encontradas.');
    FreeLibrary(FLibHandle);
    FLibHandle := NilHandle;
    Exit;
  end;

  try
    if FAsynchronous then
      espeak_Initialize(0, 0, nil, 0)
    else
      espeak_Initialize(2, 0, nil, 0);

    FInitialized := True;
    Result := True;
  except
    on E: Exception do
    begin
      SetError('Erro na inicialização do eSpeak: ' + E.Message);
      FreeLibrary(FLibHandle);
      FLibHandle := NilHandle;
    end;
  end;
end;

procedure TAIVoiceSynthesizer.UnloadEspeak;
begin
  if FInitialized then
  begin
    if Assigned(espeak_Terminate) then
    begin
      try
        espeak_Terminate();
      except
      end;
    end;
    FInitialized := False;
  end;

  if FLibHandle <> NilHandle then
  begin
    FreeLibrary(FLibHandle);
    FLibHandle := NilHandle;
  end;

  espeak_Initialize := nil;
  espeak_SetVoiceByName := nil;
  espeak_SetVolume := nil;
  espeak_SetRate := nil;
  espeak_Synth := nil;
  espeak_Terminate := nil;
  espeak_ListVoices := nil;
end;

// Backward compatibility property getters and setters
function TAIVoiceSynthesizer.GetOpenAIToken: string;
begin
  Result := FAPIToken;
end;

procedure TAIVoiceSynthesizer.SetOpenAIToken(const AValue: string);
begin
  FAPIToken := AValue;
end;

function TAIVoiceSynthesizer.GetOpenAIModel: string;
begin
  Result := FModel;
end;

procedure TAIVoiceSynthesizer.SetOpenAIModel(const AValue: string);
begin
  FModel := AValue;
end;

function TAIVoiceSynthesizer.GetOpenAIEndpoint: string;
begin
  Result := FEndpoint;
end;

procedure TAIVoiceSynthesizer.SetOpenAIEndpoint(const AValue: string);
begin
  FEndpoint := AValue;
end;

function TAIVoiceSynthesizer.GetOpenAIVoice: string;
begin
  Result := FRemoteVoice;
end;

procedure TAIVoiceSynthesizer.SetOpenAIVoice(const AValue: string);
begin
  FRemoteVoice := AValue;
end;

function TAIVoiceSynthesizer.GetOpenAIInstructions: string;
begin
  Result := FInstructions;
end;

procedure TAIVoiceSynthesizer.SetOpenAIInstructions(const AValue: string);
begin
  FInstructions := AValue;
end;

function TAIVoiceSynthesizer.GetOpenAIOutputFormat: string;
begin
  Result := FOutputFormat;
end;

procedure TAIVoiceSynthesizer.SetOpenAIOutputFormat(const AValue: string);
begin
  FOutputFormat := AValue;
end;

function TAIVoiceSynthesizer.GetOpenAIOutputFile: string;
begin
  Result := FOutputFile;
end;

procedure TAIVoiceSynthesizer.SetOpenAIOutputFile(const AValue: string);
begin
  FOutputFile := AValue;
end;

initialization
  {$I aivoicesynthesizer_icon.lrs}

end.
