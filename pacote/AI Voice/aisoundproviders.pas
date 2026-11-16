unit aisoundproviders;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson, jsonparser, base64, opensslsockets,
  aiprocessrunner, airuntimepaths, aisoundruntime;

type
  TAISoundProviderKind = (
    sndOpenAI,
    sndOpenAICompatible,
    sndElevenLabs,
    sndGeminiTTS,
    sndKokoroFastAPI,
    sndPiperHTTP,
    sndOpenedAISpeech,
    sndCoquiXTTS,
    sndAllTalkTTS,
    sndOpenVoice,
    sndF5TTSServer,
    sndChatterbox,
    sndBarkAudioGen,
    sndLocalCPURuntime,
    sndSystemOS
  );

  TAISoundTaskKind = (stkSpeech, stkVoiceClone, stkSFX, stkMusic);

  TAISoundProviderConfig = record
    TaskKind: TAISoundTaskKind;
    Endpoint: string;
    Token: string;
    Model: string;
    Voice: string;
    Language: string;
    TextOrPrompt: string;
    ReferenceAudio: string;
    OutputFile: string;
    OutputFormat: string;
    Speed: Double;
    DurationSec: Double;
    UseGPU: Boolean;
    PythonPath: string;
    WorkerPath: string;
    Timeout: Integer;
  end;

  IAISoundProvider = interface
    ['{D74A1C59-8B20-41F5-B3AE-6E9F2C3812A4}']
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean;
    procedure Cancel;
  end;

  TAISoundProviderBase = class(TInterfacedObject, IAISoundProvider)
  private
    FProviderID: string;
    FProviderName: string;
    FDefaultEndpoint: string;
    FLastError: string;
    FCancelled: Boolean;
    FActiveHTTP: TFPHTTPClient;
    FLock: TRTLCriticalSection;
  protected
    procedure SetIdentity(const AID, AName, AEndpoint: string);
    procedure SetLastError(const Msg: string);
    function IsCancelled: Boolean;
    function HttpPostJsonRaw(const AUrl, ABody: string; AHeaders: TStrings;
      ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
    function HttpPostFormRaw(const AUrl, AFormBody: string; AHeaders: TStrings;
      ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
    function HttpPostMultipartFile(const AUrl: string; const AFields: array of string;
      const AFileField, AFilePath: string; AHeaders: TStrings; ATimeoutMs: Integer;
      out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
    function HttpGetRaw(const AUrl: string; AHeaders: TStrings;
      ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
    function SaveBytesToFile(const ARaw: RawByteString; const AFileName: string): Boolean;
    function FileToBase64(const AFileName: string): string;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; virtual; abstract;
    procedure Cancel; virtual;
  end;

  // OpenAI / Kokoro-FastAPI / OpenedAI-Speech / Generic /v1/audio/speech
  TAISoundOpenAISpeechProvider = class(TAISoundProviderBase)
  private
    FKindId, FKindName, FDefEp: string;
  public
    constructor CreateWithMeta(const AID, AName, AEndpoint: string);
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // ElevenLabs (TTS + Voice Cloning + Sound Effects)
  TAISoundElevenLabsProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // Google Cloud / Gemini TTS
  TAISoundGeminiTTSProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // Piper HTTP (ONNX C++ CPU sem GPU)
  TAISoundPiperHttpProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // Coqui XTTS-v2 HTTP (Clonagem de voz CPU/GPU)
  TAISoundCoquiXTTSProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // AllTalk TTS HTTP (XTTS / Piper / Parler / F5-TTS)
  TAISoundAllTalkProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // MyShell OpenVoice v2 HTTP (Clonagem instantanea de timbre CPU/GPU)
  TAISoundOpenVoiceProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // Chatterbox / Fish-Speech / F5-TTS HTTP
  TAISoundCloneJsonProvider = class(TAISoundProviderBase)
  public
    constructor CreateWithMeta(const AID, AName, AEndpoint: string);
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // AudioCraft (AudioGen / MusicGen) & Suno Bark HTTP
  TAISoundAudioCraftProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  // Local Python CPU Runtime Worker (sem GPU)
  TAISoundLocalCPUWorkerProvider = class(TAISoundProviderBase)
  private
    FRunner: TAIProcessRunner;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
    procedure Cancel; override;
  end;

  // System OS offline (Windows SAPI WAV / eSpeak-NG)
  TAISoundSystemOSProvider = class(TAISoundProviderBase)
  public
    constructor Create; override;
    function Synthesize(const AConfig: TAISoundProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAISoundProviderFactory = class
  public
    class function CreateProvider(AKind: TAISoundProviderKind): IAISoundProvider; static;
    class function KindFromName(const AName: string): TAISoundProviderKind; static;
  end;

procedure InitAISoundProviderConfig(out AConfig: TAISoundProviderConfig);
function AISoundProviderKindName(AKind: TAISoundProviderKind): string;

implementation

uses
  {$IFDEF MSWINDOWS}ComObj, ActiveX, Variants,{$ENDIF}
  Process;

procedure InitAISoundProviderConfig(out AConfig: TAISoundProviderConfig);
begin
  FillChar(AConfig, SizeOf(AConfig), 0);
  AConfig.TaskKind := stkSpeech;
  AConfig.Language := 'pt';
  AConfig.OutputFormat := 'wav';
  AConfig.Speed := 1.0;
  AConfig.DurationSec := 4.0;
  AConfig.UseGPU := False;
  AConfig.Timeout := 180000;
end;

function AISoundProviderKindName(AKind: TAISoundProviderKind): string;
begin
  case AKind of
    sndOpenAI: Result := 'OpenAI';
    sndOpenAICompatible: Result := 'OpenAI-compatible';
    sndElevenLabs: Result := 'ElevenLabs';
    sndGeminiTTS: Result := 'GeminiTTS';
    sndKokoroFastAPI: Result := 'Kokoro-FastAPI';
    sndPiperHTTP: Result := 'Piper-HTTP';
    sndOpenedAISpeech: Result := 'OpenedAI-Speech';
    sndCoquiXTTS: Result := 'Coqui-XTTS';
    sndAllTalkTTS: Result := 'AllTalk-TTS';
    sndOpenVoice: Result := 'OpenVoice-v2';
    sndF5TTSServer: Result := 'F5-TTS-Server';
    sndChatterbox: Result := 'Chatterbox';
    sndBarkAudioGen: Result := 'AudioCraft-Bark';
    sndLocalCPURuntime: Result := 'Local-CPU-Runtime';
    sndSystemOS: Result := 'System-OS';
  end;
end;

function TrimBaseUrl(const AUrl: string): string;
begin
  Result := Trim(AUrl);
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

function UrlEncodeSimple(const S: string): string;
const
  Hex = '0123456789ABCDEF';
var
  I: Integer;
  B: Byte;
  Utf: RawByteString;
begin
  Result := '';
  Utf := UTF8Encode(S);
  for I := 1 to Length(Utf) do
  begin
    B := Ord(Utf[I]);
    if (Char(B) in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~']) then
      Result := Result + Char(B)
    else if B = 32 then
      Result := Result + '+'
    else
      Result := Result + '%' + Hex[(B shr 4) + 1] + Hex[(B and $0F) + 1];
  end;
end;

{ TAISoundProviderBase }

constructor TAISoundProviderBase.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
end;

destructor TAISoundProviderBase.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TAISoundProviderBase.SetIdentity(const AID, AName, AEndpoint: string);
begin
  FProviderID := AID;
  FProviderName := AName;
  FDefaultEndpoint := AEndpoint;
end;

procedure TAISoundProviderBase.SetLastError(const Msg: string);
begin
  FLastError := Msg;
end;

function TAISoundProviderBase.IsCancelled: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAISoundProviderBase.GetProviderID: string; begin Result := FProviderID; end;
function TAISoundProviderBase.GetProviderName: string; begin Result := FProviderName; end;
function TAISoundProviderBase.GetDefaultEndpoint: string; begin Result := FDefaultEndpoint; end;
function TAISoundProviderBase.GetLastError: string; begin Result := FLastError; end;

procedure TAISoundProviderBase.Cancel;
begin
  EnterCriticalSection(FLock);
  try
    FCancelled := True;
    if FActiveHTTP <> nil then
      FActiveHTTP.Terminate;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAISoundProviderBase.HttpPostJsonRaw(const AUrl, ABody: string;
  AHeaders: TStrings; ATimeoutMs: Integer; out ARawBytes: RawByteString;
  out AHttpCode: Integer): Boolean;
var
  Client: TFPHTTPClient;
  ReqStream, RespStream: TStringStream;
  I: Integer;
begin
  Result := False;
  ARawBytes := '';
  AHttpCode := 0;
  if IsCancelled then begin SetLastError('Operacao cancelada.'); Exit; end;

  Client := TFPHTTPClient.Create(nil);
  ReqStream := TStringStream.Create(ABody, TEncoding.UTF8);
  RespStream := TStringStream.Create('');
  try
    Client.AllowRedirect := True;
    Client.ConnectTimeout := 15000;
    if ATimeoutMs > 0 then Client.IOTimeout := ATimeoutMs;
    Client.AddHeader('Content-Type', 'application/json');
    if AHeaders <> nil then
      for I := 0 to AHeaders.Count - 1 do
        Client.AddHeader(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);

    EnterCriticalSection(FLock);
    try FActiveHTTP := Client; finally LeaveCriticalSection(FLock); end;

    try
      Client.RequestBody := ReqStream;
      Client.Post(AUrl, RespStream);
      AHttpCode := Client.ResponseStatusCode;
      ARawBytes := RespStream.DataString;
      Result := (AHttpCode >= 200) and (AHttpCode < 300);
      if not Result then
        SetLastError(Format('HTTP %d: %s', [AHttpCode, Copy(ARawBytes, 1, 300)]));
    except
      on E: Exception do
        SetLastError('Erro HTTP (' + AUrl + '): ' + E.Message);
    end;
  finally
    EnterCriticalSection(FLock);
    try FActiveHTTP := nil; finally LeaveCriticalSection(FLock); end;
    RespStream.Free;
    ReqStream.Free;
    Client.Free;
  end;
end;

function TAISoundProviderBase.HttpPostFormRaw(const AUrl, AFormBody: string;
  AHeaders: TStrings; ATimeoutMs: Integer; out ARawBytes: RawByteString;
  out AHttpCode: Integer): Boolean;
var
  Client: TFPHTTPClient;
  ReqStream, RespStream: TStringStream;
  I: Integer;
begin
  Result := False;
  ARawBytes := '';
  AHttpCode := 0;
  Client := TFPHTTPClient.Create(nil);
  ReqStream := TStringStream.Create(AFormBody, TEncoding.UTF8);
  RespStream := TStringStream.Create('');
  try
    Client.AllowRedirect := True;
    Client.ConnectTimeout := 15000;
    if ATimeoutMs > 0 then Client.IOTimeout := ATimeoutMs;
    Client.AddHeader('Content-Type', 'application/x-www-form-urlencoded');
    if AHeaders <> nil then
      for I := 0 to AHeaders.Count - 1 do
        Client.AddHeader(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);
    try
      Client.RequestBody := ReqStream;
      Client.Post(AUrl, RespStream);
      AHttpCode := Client.ResponseStatusCode;
      ARawBytes := RespStream.DataString;
      Result := (AHttpCode >= 200) and (AHttpCode < 300);
      if not Result then
        SetLastError(Format('HTTP %d: %s', [AHttpCode, Copy(ARawBytes, 1, 300)]));
    except
      on E: Exception do
        SetLastError('Erro HTTP (' + AUrl + '): ' + E.Message);
    end;
  finally
    RespStream.Free;
    ReqStream.Free;
    Client.Free;
  end;
end;

function TAISoundProviderBase.HttpPostMultipartFile(const AUrl: string;
  const AFields: array of string; const AFileField, AFilePath: string;
  AHeaders: TStrings; ATimeoutMs: Integer; out ARawBytes: RawByteString;
  out AHttpCode: Integer): Boolean;
var
  Client: TFPHTTPClient;
  BodyStream, FileStream: TMemoryStream;
  RespStream: TStringStream;
  Boundary, Part: RawByteString;
  I: Integer;

  procedure WriteStr(const S: RawByteString);
  begin
    if Length(S) > 0 then
      BodyStream.WriteBuffer(S[1], Length(S));
  end;

begin
  Result := False;
  ARawBytes := '';
  AHttpCode := 0;
  Boundary := '----MaurinMovieBoundary' + IntToStr(GetTickCount64);
  BodyStream := TMemoryStream.Create;
  RespStream := TStringStream.Create('');
  Client := TFPHTTPClient.Create(nil);
  try
    I := 0;
    while I + 1 <= High(AFields) do
    begin
      Part := '--' + Boundary + #13#10 +
        'Content-Disposition: form-data; name="' + UTF8Encode(AFields[I]) + '"' + #13#10#13#10 +
        UTF8Encode(AFields[I + 1]) + #13#10;
      WriteStr(Part);
      Inc(I, 2);
    end;

    if (AFileField <> '') and (AFilePath <> '') and FileExists(AFilePath) then
    begin
      Part := '--' + Boundary + #13#10 +
        'Content-Disposition: form-data; name="' + UTF8Encode(AFileField) +
        '"; filename="' + UTF8Encode(ExtractFileName(AFilePath)) + '"' + #13#10 +
        'Content-Type: audio/wav' + #13#10#13#10;
      WriteStr(Part);
      FileStream := TMemoryStream.Create;
      try
        FileStream.LoadFromFile(AFilePath);
        if FileStream.Size > 0 then
          BodyStream.CopyFrom(FileStream, 0);
      finally
        FileStream.Free;
      end;
      WriteStr(#13#10);
    end;

    WriteStr('--' + Boundary + '--' + #13#10);
    BodyStream.Position := 0;

    Client.AllowRedirect := True;
    Client.ConnectTimeout := 15000;
    if ATimeoutMs > 0 then Client.IOTimeout := ATimeoutMs;
    Client.AddHeader('Content-Type', 'multipart/form-data; boundary=' + Boundary);
    if AHeaders <> nil then
      for I := 0 to AHeaders.Count - 1 do
        Client.AddHeader(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);

    try
      Client.RequestBody := BodyStream;
      Client.Post(AUrl, RespStream);
      AHttpCode := Client.ResponseStatusCode;
      ARawBytes := RespStream.DataString;
      Result := (AHttpCode >= 200) and (AHttpCode < 300);
      if not Result then
        SetLastError(Format('HTTP %d: %s', [AHttpCode, Copy(ARawBytes, 1, 300)]));
    except
      on E: Exception do
        SetLastError('Erro HTTP multipart (' + AUrl + '): ' + E.Message);
    end;
  finally
    Client.Free;
    RespStream.Free;
    BodyStream.Free;
  end;
end;

function TAISoundProviderBase.HttpGetRaw(const AUrl: string; AHeaders: TStrings;
  ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
var
  Client: TFPHTTPClient;
  RespStream: TStringStream;
  I: Integer;
begin
  Result := False;
  ARawBytes := '';
  AHttpCode := 0;
  Client := TFPHTTPClient.Create(nil);
  RespStream := TStringStream.Create('');
  try
    Client.AllowRedirect := True;
    Client.ConnectTimeout := 15000;
    if ATimeoutMs > 0 then Client.IOTimeout := ATimeoutMs;
    if AHeaders <> nil then
      for I := 0 to AHeaders.Count - 1 do
        Client.AddHeader(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);
    try
      Client.Get(AUrl, RespStream);
      AHttpCode := Client.ResponseStatusCode;
      ARawBytes := RespStream.DataString;
      Result := (AHttpCode >= 200) and (AHttpCode < 300);
      if not Result then
        SetLastError(Format('HTTP %d: %s', [AHttpCode, Copy(ARawBytes, 1, 300)]));
    except
      on E: Exception do
        SetLastError('Erro HTTP GET (' + AUrl + '): ' + E.Message);
    end;
  finally
    RespStream.Free;
    Client.Free;
  end;
end;

function TAISoundProviderBase.SaveBytesToFile(const ARaw: RawByteString;
  const AFileName: string): Boolean;
var
  FS: TFileStream;
begin
  Result := False;
  if (AFileName = '') or (Length(ARaw) = 0) then Exit;
  ForceDirectories(ExtractFileDir(ExpandFileName(AFileName)));
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    FS.WriteBuffer(ARaw[1], Length(ARaw));
    Result := True;
  finally
    FS.Free;
  end;
end;

function TAISoundProviderBase.FileToBase64(const AFileName: string): string;
var
  FS: TFileStream;
  Raw: RawByteString;
begin
  Result := '';
  if not FileExists(AFileName) then Exit;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, FS.Size);
    if FS.Size > 0 then
      FS.ReadBuffer(Raw[1], FS.Size);
    Result := EncodeStringBase64(Raw);
  finally
    FS.Free;
  end;
end;

{ TAISoundOpenAISpeechProvider }

constructor TAISoundOpenAISpeechProvider.CreateWithMeta(const AID, AName,
  AEndpoint: string);
begin
  inherited Create;
  FKindId := AID;
  FKindName := AName;
  FDefEp := AEndpoint;
  SetIdentity(FKindId, FKindName, FDefEp);
end;

constructor TAISoundOpenAISpeechProvider.Create;
begin
  CreateWithMeta('openai-compatible', 'OpenAI-Compatible Audio',
    'http://127.0.0.1:8000/v1/audio/speech');
end;

function TAISoundOpenAISpeechProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, ModelName, VoiceName, Fmt: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw: RawByteString;
  Code: Integer;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  if Pos('/audio/speech', LowerCase(Url)) = 0 then
    Url := TrimBaseUrl(Url) + '/v1/audio/speech';

  ModelName := Trim(AConfig.Model);
  if ModelName = '' then ModelName := 'tts-1';
  VoiceName := Trim(AConfig.Voice);
  if VoiceName = '' then VoiceName := 'alloy';
  Fmt := Trim(AConfig.OutputFormat);
  if Fmt = '' then Fmt := 'wav';

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('model', ModelName);
    ReqObj.Add('input', AConfig.TextOrPrompt);
    ReqObj.Add('voice', VoiceName);
    ReqObj.Add('response_format', Fmt);
    if AConfig.Speed > 0 then
      ReqObj.Add('speed', AConfig.Speed);
    if AConfig.Language <> '' then
      ReqObj.Add('language', AConfig.Language);
    if (AConfig.ReferenceAudio <> '') and FileExists(AConfig.ReferenceAudio) then
      ReqObj.Add('reference_audio_base64', FileToBase64(AConfig.ReferenceAudio));
    if AConfig.Token <> '' then
      Headers.Add('Authorization=Bearer ' + AConfig.Token);

    if HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Result := SaveBytesToFile(Raw, AOutputFile);
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAISoundElevenLabsProvider }

constructor TAISoundElevenLabsProvider.Create;
begin
  inherited Create;
  SetIdentity('elevenlabs', 'ElevenLabs Voice & SFX',
    'https://api.elevenlabs.io/v1/text-to-speech/');
end;

function TAISoundElevenLabsProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, VoiceId, ModelName: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw: RawByteString;
  Code: Integer;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    if AConfig.Token <> '' then
      Headers.Add('xi-api-key=' + AConfig.Token);

    if AConfig.TaskKind in [stkSFX, stkMusic] then
    begin
      Url := Trim(AConfig.Endpoint);
      if (Url = '') or (Pos('sound-generation', LowerCase(Url)) = 0) then
        Url := 'https://api.elevenlabs.io/v1/sound-generation';
      ReqObj.Add('text', AConfig.TextOrPrompt);
      if AConfig.DurationSec > 0 then
        ReqObj.Add('duration_seconds', AConfig.DurationSec);
    end
    else
    begin
      VoiceId := Trim(AConfig.Voice);
      if VoiceId = '' then VoiceId := 'EXAVITQu4vr4xnSDxMaL';
      Url := TrimBaseUrl(AConfig.Endpoint);
      if Url = '' then Url := TrimBaseUrl(FDefaultEndpoint);
      if Pos(LowerCase(VoiceId), LowerCase(Url)) = 0 then
        Url := Url + '/' + VoiceId;
      ModelName := Trim(AConfig.Model);
      if ModelName = '' then ModelName := 'eleven_multilingual_v2';
      ReqObj.Add('text', AConfig.TextOrPrompt);
      ReqObj.Add('model_id', ModelName);
    end;

    if HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Result := SaveBytesToFile(Raw, AOutputFile);
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAISoundGeminiTTSProvider }

constructor TAISoundGeminiTTSProvider.Create;
begin
  inherited Create;
  SetIdentity('gemini-tts', 'Google Cloud / Gemini TTS',
    'https://texttospeech.googleapis.com/v1/text:synthesize');
end;

function TAISoundGeminiTTSProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, Lang, VoiceName, B64, Dec: string;
  ReqObj, InpObj, VoiceObj, AudioObj: TJSONObject;
  Raw: RawByteString;
  Code: Integer;
  Data: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  if AConfig.Token <> '' then
    Url := Url + '?key=' + AConfig.Token;

  Lang := Trim(AConfig.Language);
  if Lang = '' then Lang := 'pt-BR';
  VoiceName := Trim(AConfig.Voice);
  if VoiceName = '' then VoiceName := 'pt-BR-Neural2-A';

  ReqObj := TJSONObject.Create;
  try
    InpObj := TJSONObject.Create; InpObj.Add('text', AConfig.TextOrPrompt);
    VoiceObj := TJSONObject.Create; VoiceObj.Add('languageCode', Lang); VoiceObj.Add('name', VoiceName);
    AudioObj := TJSONObject.Create; AudioObj.Add('audioEncoding', 'LINEAR16');
    ReqObj.Add('input', InpObj);
    ReqObj.Add('voice', VoiceObj);
    ReqObj.Add('audioConfig', AudioObj);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, nil, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if Data is TJSONObject then
      begin
        B64 := TJSONObject(Data).Get('audioContent', '');
        if B64 <> '' then
        begin
          Dec := DecodeStringBase64(B64);
          Result := SaveBytesToFile(Dec, AOutputFile);
          Exit;
        end;
      end;
      SetLastError('GeminiTTS nao retornou audioContent.');
    finally
      Data.Free;
    end;
  finally
    ReqObj.Free;
  end;
end;

{ TAISoundPiperHttpProvider }

constructor TAISoundPiperHttpProvider.Create;
begin
  inherited Create;
  SetIdentity('piper-http', 'Piper TTS HTTP Server (CPU)', 'http://127.0.0.1:5000/');
end;

function TAISoundPiperHttpProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, ModelName: string;
  ReqObj: TJSONObject;
  Raw: RawByteString;
  Code: Integer;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  ModelName := Trim(AConfig.Voice);
  if ModelName = '' then ModelName := Trim(AConfig.Model);

  ReqObj := TJSONObject.Create;
  try
    ReqObj.Add('text', AConfig.TextOrPrompt);
    if ModelName <> '' then
      ReqObj.Add('speaker', ModelName);
    if HttpPostJsonRaw(Url, ReqObj.AsJSON, nil, AConfig.Timeout, Raw, Code) then
      Result := SaveBytesToFile(Raw, AOutputFile);
  finally
    ReqObj.Free;
  end;
end;

{ TAISoundCoquiXTTSProvider }

constructor TAISoundCoquiXTTSProvider.Create;
begin
  inherited Create;
  SetIdentity('coqui-xtts', 'Coqui XTTS-v2 Server (Clonagem)',
    'http://127.0.0.1:8020/tts_to_audio/');
end;

function TAISoundCoquiXTTSProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  BaseUrl, Url, Lang, SpeakerName: string;
  ReqObj: TJSONObject;
  Raw: RawByteString;
  Code: Integer;
  Data: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  BaseUrl := TrimBaseUrl(AConfig.Endpoint);
  if BaseUrl = '' then BaseUrl := 'http://127.0.0.1:8020';
  if Pos('tts_to_audio', LowerCase(BaseUrl)) > 0 then
    Delete(BaseUrl, Pos('/tts_to_audio', LowerCase(BaseUrl)), Length(BaseUrl));

  Lang := Trim(AConfig.Language);
  if Lang = '' then Lang := 'pt';
  SpeakerName := Trim(AConfig.Voice);
  if SpeakerName = '' then SpeakerName := 'default';

  // Se houver WAV de referencia, envia primeiro para /clone_speaker quando suportado
  if (AConfig.ReferenceAudio <> '') and FileExists(AConfig.ReferenceAudio) then
  begin
    if HttpPostMultipartFile(BaseUrl + '/clone_speaker',
         ['speaker_name', SpeakerName], 'wav_file', AConfig.ReferenceAudio,
         nil, AConfig.Timeout, Raw, Code) then
    begin
      Data := nil;
      try
        Data := GetJSON(Raw);
        if Data is TJSONObject then
          SpeakerName := TJSONObject(Data).Get('speaker_name', SpeakerName);
      except
      end;
      if Data <> nil then Data.Free;
    end;
  end;

  Url := BaseUrl + '/tts_to_audio/';
  ReqObj := TJSONObject.Create;
  try
    ReqObj.Add('text', AConfig.TextOrPrompt);
    ReqObj.Add('speaker_wav', SpeakerName);
    ReqObj.Add('language', Lang);
    if HttpPostJsonRaw(Url, ReqObj.AsJSON, nil, AConfig.Timeout, Raw, Code) then
      Result := SaveBytesToFile(Raw, AOutputFile);
  finally
    ReqObj.Free;
  end;
end;

{ TAISoundAllTalkProvider }

constructor TAISoundAllTalkProvider.Create;
begin
  inherited Create;
  SetIdentity('alltalk-tts', 'AllTalk TTS Server (XTTS/Piper/F5)',
    'http://127.0.0.1:7851/api/tts-generate');
end;

function TAISoundAllTalkProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, BaseUrl, FormStr, VoiceName, Lang, OutRel, AudioUrl: string;
  Raw, AudioBytes: RawByteString;
  Code: Integer;
  Data: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  BaseUrl := TrimBaseUrl(Url);
  if Pos('/api/tts-generate', LowerCase(BaseUrl)) > 0 then
    Delete(BaseUrl, Pos('/api/tts-generate', LowerCase(BaseUrl)), Length(BaseUrl));

  VoiceName := Trim(AConfig.Voice);
  if (AConfig.ReferenceAudio <> '') and FileExists(AConfig.ReferenceAudio) then
    VoiceName := ExtractFileName(AConfig.ReferenceAudio);
  if VoiceName = '' then VoiceName := 'female_01.wav';
  Lang := Trim(AConfig.Language);
  if Lang = '' then Lang := 'pt';

  FormStr :=
    'text_input=' + UrlEncodeSimple(AConfig.TextOrPrompt) +
    '&text_filtering=standard' +
    '&character_voice_gen=' + UrlEncodeSimple(VoiceName) +
    '&narrator_enabled=false' +
    '&language=' + UrlEncodeSimple(Lang) +
    '&output_file_name=maurinmovie_tts' +
    '&output_file_timestamp=true' +
    '&autoplay=false';

  if not HttpPostFormRaw(Url, FormStr, nil, AConfig.Timeout, Raw, Code) then
    Exit;

  Data := GetJSON(Raw);
  try
    if Data is TJSONObject then
    begin
      OutRel := TJSONObject(Data).Get('output_file_url', '');
      if OutRel = '' then OutRel := TJSONObject(Data).Get('output_cache_url', '');
      if OutRel <> '' then
      begin
        if Pos('http', LowerCase(OutRel)) = 1 then
          AudioUrl := OutRel
        else
          AudioUrl := BaseUrl + OutRel;
        if HttpGetRaw(AudioUrl, nil, AConfig.Timeout, AudioBytes, Code) then
          Result := SaveBytesToFile(AudioBytes, AOutputFile);
        Exit;
      end;
    end;
    SetLastError('AllTalk TTS nao retornou output_file_url: ' + Copy(Raw, 1, 200));
  finally
    Data.Free;
  end;
end;

{ TAISoundOpenVoiceProvider }

constructor TAISoundOpenVoiceProvider.Create;
begin
  inherited Create;
  SetIdentity('openvoice-v2', 'MyShell OpenVoice v2 (Clonagem CPU)',
    'http://127.0.0.1:8030/synthesize');
end;

function TAISoundOpenVoiceProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, Lang: string;
  Raw: RawByteString;
  Code: Integer;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  Lang := Trim(AConfig.Language);
  if Lang = '' then Lang := 'pt';

  if HttpPostMultipartFile(Url,
       ['text', AConfig.TextOrPrompt, 'language', Lang, 'speed', FloatToStr(AConfig.Speed)],
       'reference_audio', AConfig.ReferenceAudio,
       nil, AConfig.Timeout, Raw, Code) then
    Result := SaveBytesToFile(Raw, AOutputFile);
end;

{ TAISoundCloneJsonProvider }

constructor TAISoundCloneJsonProvider.CreateWithMeta(const AID, AName,
  AEndpoint: string);
begin
  inherited Create;
  SetIdentity(AID, AName, AEndpoint);
end;

constructor TAISoundCloneJsonProvider.Create;
begin
  CreateWithMeta('chatterbox', 'Chatterbox / Fish-Speech / F5 Server',
    'http://127.0.0.1:8080/v1/tts');
end;

function TAISoundCloneJsonProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw: RawByteString;
  Code: Integer;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('text', AConfig.TextOrPrompt);
    ReqObj.Add('model', AConfig.Model);
    ReqObj.Add('format', 'wav');
    if AConfig.Language <> '' then
      ReqObj.Add('language', AConfig.Language);
    if (AConfig.ReferenceAudio <> '') and FileExists(AConfig.ReferenceAudio) then
      ReqObj.Add('reference_audio_base64', FileToBase64(AConfig.ReferenceAudio));
    if AConfig.Token <> '' then
      Headers.Add('Authorization=Bearer ' + AConfig.Token);

    if HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Result := SaveBytesToFile(Raw, AOutputFile);
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAISoundAudioCraftProvider }

constructor TAISoundAudioCraftProvider.Create;
begin
  inherited Create;
  SetIdentity('audiocraft-bark', 'AudioCraft / Bark Open Server (SFX & Musica)',
    'http://127.0.0.1:8040/generate');
end;

function TAISoundAudioCraftProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, ModelName: string;
  ReqObj: TJSONObject;
  Raw: RawByteString;
  Code: Integer;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  ModelName := Trim(AConfig.Model);
  if ModelName = '' then ModelName := 'facebook/audiogen-medium';

  ReqObj := TJSONObject.Create;
  try
    ReqObj.Add('prompt', AConfig.TextOrPrompt);
    ReqObj.Add('model', ModelName);
    ReqObj.Add('duration', AConfig.DurationSec);
    if AConfig.Voice <> '' then
      ReqObj.Add('voice_preset', AConfig.Voice);
    if HttpPostJsonRaw(Url, ReqObj.AsJSON, nil, AConfig.Timeout, Raw, Code) then
      Result := SaveBytesToFile(Raw, AOutputFile);
  finally
    ReqObj.Free;
  end;
end;

{ TAISoundLocalCPUWorkerProvider }

constructor TAISoundLocalCPUWorkerProvider.Create;
begin
  inherited Create;
  SetIdentity('local-cpu-runtime', 'Runtime Python Local CPU (sem GPU)',
    'local://aisound_cpu_worker.py');
  FRunner := TAIProcessRunner.Create(nil);
end;

destructor TAISoundLocalCPUWorkerProvider.Destroy;
begin
  FRunner.Free;
  inherited Destroy;
end;

procedure TAISoundLocalCPUWorkerProvider.Cancel;
begin
  inherited Cancel;
  if FRunner <> nil then FRunner.Stop;
end;

function TAISoundLocalCPUWorkerProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
var
  PyExe, Worker, ModeStr: string;
  Args: TStringList;
  Params: array of string;
  I: Integer;
begin
  Result := False;
  AOutputFile := ExpandFileName(AConfig.OutputFile);
  ForceDirectories(ExtractFileDir(AOutputFile));

  PyExe := Trim(AConfig.PythonPath);
  if PyExe = '' then PyExe := AIResolvePythonExecutable(AIGetDefaultRuntimeRoot);
  Worker := Trim(AConfig.WorkerPath);
  if Worker = '' then Worker := ResolveAISoundCpuWorkerPath('');
  if Worker = '' then
  begin
    SetLastError('Worker local aisound_cpu_worker.py nao encontrado.');
    Exit;
  end;

  case AConfig.TaskKind of
    stkVoiceClone: ModeStr := 'clone';
    stkSFX: ModeStr := 'sfx';
    stkMusic: ModeStr := 'music';
  else
    ModeStr := 'tts';
  end;

  Args := TStringList.Create;
  try
    Args.Add(Worker);
    Args.Add('--mode'); Args.Add(ModeStr);
    Args.Add('--text'); Args.Add(AConfig.TextOrPrompt);
    Args.Add('--output'); Args.Add(AOutputFile);
    if AConfig.Model <> '' then begin Args.Add('--model'); Args.Add(AConfig.Model); end;
    if AConfig.Voice <> '' then begin Args.Add('--voice'); Args.Add(AConfig.Voice); end;
    if AConfig.Language <> '' then begin Args.Add('--language'); Args.Add(AConfig.Language); end;
    if (AConfig.ReferenceAudio <> '') and FileExists(AConfig.ReferenceAudio) then
    begin
      Args.Add('--ref_audio'); Args.Add(AConfig.ReferenceAudio);
    end;
    if AConfig.DurationSec > 0 then
    begin
      Args.Add('--duration'); Args.Add(IntToStr(Round(AConfig.DurationSec)));
    end;
    if AConfig.UseGPU then
      Args.Add('--gpu')
    else
      Args.Add('--cpu');

    SetLength(Params, Args.Count);
    for I := 0 to Args.Count - 1 do Params[I] := Args[I];

    FRunner.Executable := PyExe;
    FRunner.TimeoutMs := AConfig.Timeout;
    if FRunner.Execute(Params) and FileExists(AOutputFile) then
      Result := True
    else
    begin
      SetLastError(Trim(FRunner.LastError + ' ' + FRunner.StdErrText));
      if FLastError = '' then SetLastError('Falha ao executar aisound_cpu_worker.py.');
    end;
  finally
    Args.Free;
  end;
end;

{ TAISoundSystemOSProvider }

constructor TAISoundSystemOSProvider.Create;
begin
  inherited Create;
  SetIdentity('system-os', 'Sistema Operacional (SAPI / eSpeak CPU)', 'system://tts');
end;

function TAISoundSystemOSProvider.Synthesize(const AConfig: TAISoundProviderConfig;
  out AOutputFile: string): Boolean;
{$IFDEF MSWINDOWS}
var
  SpVoice, FileStream: OleVariant;
begin
  Result := False;
  AOutputFile := ExpandFileName(AConfig.OutputFile);
  ForceDirectories(ExtractFileDir(AOutputFile));
  try
    CoInitialize(nil);
    try
      SpVoice := CreateOleObject('SAPI.SpVoice');
      FileStream := CreateOleObject('SAPI.SpFileStream');
      FileStream.Open(AOutputFile, 3, False); // SSFMCreateForWrite = 3
      SpVoice.AudioOutputStream := FileStream;
      if AConfig.Speed <> 1.0 then
        SpVoice.Rate := Round((AConfig.Speed - 1.0) * 5.0);
      SpVoice.Speak(AConfig.TextOrPrompt, 0);
      FileStream.Close;
      Result := FileExists(AOutputFile);
    finally
      CoUninitialize;
    end;
  except
    on E: Exception do
      SetLastError('Falha SAPI WAV: ' + E.Message);
  end;
end;
{$ELSE}
var
  P: TProcess;
begin
  Result := False;
  AOutputFile := ExpandFileName(AConfig.OutputFile);
  ForceDirectories(ExtractFileDir(AOutputFile));
  P := TProcess.Create(nil);
  try
    P.Executable := 'espeak-ng';
    P.Parameters.Add('-w');
    P.Parameters.Add(AOutputFile);
    P.Parameters.Add(AConfig.TextOrPrompt);
    P.Options := [poWaitOnExit];
    try
      P.Execute;
      Result := (P.ExitStatus = 0) and FileExists(AOutputFile);
    except
      on E: Exception do
        SetLastError('Falha eSpeak-NG: ' + E.Message);
    end;
  finally
    P.Free;
  end;
end;
{$ENDIF}

{ TAISoundProviderFactory }

class function TAISoundProviderFactory.CreateProvider(
  AKind: TAISoundProviderKind): IAISoundProvider;
begin
  case AKind of
    sndOpenAI:
      Result := TAISoundOpenAISpeechProvider.CreateWithMeta('openai', 'OpenAI Audio', 'https://api.openai.com/v1/audio/speech');
    sndOpenAICompatible:
      Result := TAISoundOpenAISpeechProvider.Create;
    sndElevenLabs:
      Result := TAISoundElevenLabsProvider.Create;
    sndGeminiTTS:
      Result := TAISoundGeminiTTSProvider.Create;
    sndKokoroFastAPI:
      Result := TAISoundOpenAISpeechProvider.CreateWithMeta('kokoro-fastapi', 'Kokoro-FastAPI (CPU/GPU)', 'http://127.0.0.1:8880/v1/audio/speech');
    sndPiperHTTP:
      Result := TAISoundPiperHttpProvider.Create;
    sndOpenedAISpeech:
      Result := TAISoundOpenAISpeechProvider.CreateWithMeta('openedai-speech', 'OpenedAI-Speech (Piper/XTTS)', 'http://127.0.0.1:8000/v1/audio/speech');
    sndCoquiXTTS:
      Result := TAISoundCoquiXTTSProvider.Create;
    sndAllTalkTTS:
      Result := TAISoundAllTalkProvider.Create;
    sndOpenVoice:
      Result := TAISoundOpenVoiceProvider.Create;
    sndF5TTSServer:
      Result := TAISoundCloneJsonProvider.CreateWithMeta('f5-tts-server', 'F5-TTS Server', 'http://127.0.0.1:7860/api/predict');
    sndChatterbox:
      Result := TAISoundCloneJsonProvider.Create;
    sndBarkAudioGen:
      Result := TAISoundAudioCraftProvider.Create;
    sndLocalCPURuntime:
      Result := TAISoundLocalCPUWorkerProvider.Create;
    sndSystemOS:
      Result := TAISoundSystemOSProvider.Create;
  else
    Result := TAISoundLocalCPUWorkerProvider.Create;
  end;
end;

class function TAISoundProviderFactory.KindFromName(
  const AName: string): TAISoundProviderKind;
var
  S: string;
begin
  S := LowerCase(Trim(AName));
  if Pos('kokoro', S) > 0 then Result := sndKokoroFastAPI
  else if Pos('piper', S) > 0 then Result := sndPiperHTTP
  else if Pos('openedai', S) > 0 then Result := sndOpenedAISpeech
  else if (Pos('coqui', S) > 0) or (Pos('xtts', S) > 0) then Result := sndCoquiXTTS
  else if Pos('alltalk', S) > 0 then Result := sndAllTalkTTS
  else if Pos('openvoice', S) > 0 then Result := sndOpenVoice
  else if Pos('f5', S) > 0 then Result := sndF5TTSServer
  else if (Pos('chatterbox', S) > 0) or (Pos('fish', S) > 0) then Result := sndChatterbox
  else if (Pos('audiocraft', S) > 0) or (Pos('audiogen', S) > 0) or (Pos('musicgen', S) > 0) or (Pos('bark', S) > 0) then Result := sndBarkAudioGen
  else if Pos('eleven', S) > 0 then Result := sndElevenLabs
  else if Pos('gemini', S) > 0 then Result := sndGeminiTTS
  else if (Pos('local-cpu', S) > 0) or (Pos('cpu-worker', S) > 0) then Result := sndLocalCPURuntime
  else if (Pos('system', S) > 0) or (Pos('sapi', S) > 0) or (Pos('espeak', S) > 0) then Result := sndSystemOS
  else if SameText(S, 'openai') then Result := sndOpenAI
  else Result := sndOpenAICompatible;
end;

end.
