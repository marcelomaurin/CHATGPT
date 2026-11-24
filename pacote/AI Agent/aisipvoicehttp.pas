unit aisipvoicehttp;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, aisipvoiceagent, aisip_types;

type
  TAISIPVoiceReplyFormat = (vrCasa, vrOpenAICompatible);

  { libcurl verifies TLS peers and hostnames. Each worker owns its HTTP handles.
    Endpoints may be local services; no OpenAI account is required. }
  TAISIPVoiceHTTPBackend = class(TAISIPVoiceBackend)
  private
    FSTTURL, FReplyURL, FTTSURL, FAudioBaseURL: string;
    FSTTToken, FReplyToken, FTTSToken, FModel, FSystemPrompt, FSpeaker: string;
    FTimeoutMs: Integer;
    FReplyFormat: TAISIPVoiceReplyFormat;
    function Request(const Stage, Method, URL, ContentType, Token: string;
      const Body: RawByteString): RawByteString;
  public
    constructor Create(AOwner: TComponent); override;
    function Transcribe(const WAV: RawByteString): string; override;
    function Reply(const SessionID, Text, HistoryJSON: string): string; override;
    function Synthesize(const Text: string): TAISIPAudioSamples; override;
  published
    property STTURL: string read FSTTURL write FSTTURL;
    property ReplyURL: string read FReplyURL write FReplyURL;
    property TTSURL: string read FTTSURL write FTTSURL;
    property AudioBaseURL: string read FAudioBaseURL write FAudioBaseURL;
    property STTToken: string read FSTTToken write FSTTToken stored False;
    property ReplyToken: string read FReplyToken write FReplyToken stored False;
    property TTSToken: string read FTTSToken write FTTSToken stored False;
    property ReplyFormat: TAISIPVoiceReplyFormat read FReplyFormat write FReplyFormat default vrCasa;
    property Model: string read FModel write FModel;
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    property Speaker: string read FSpeaker write FSpeaker;
    property TimeoutMs: Integer read FTimeoutMs write FTimeoutMs default 30000;
  end;

implementation

uses ctypes, libcurl, fpjson, jsonparser, URIParser, aisipvoiceaudio;

const MaxResponse = 8*1024*1024;

function Receive(Buffer: PChar; Size, Count: csize_t; Data: Pointer): csize_t; cdecl;
var Stream: TMemoryStream; Bytes: csize_t;
begin
  Result := 0;
  if (Size = 0) or (Count > MaxResponse div Size) then Exit;
  Bytes := Size*Count; Stream := TMemoryStream(Data);
  if Stream.Size+Int64(Bytes) > MaxResponse then Exit;
  try Stream.WriteBuffer(Buffer^, Bytes); Result := Bytes; except end;
end;

function ObjectOf(const Data: RawByteString; const Stage: string): TJSONObject;
var Parsed: TJSONData;
begin
  Parsed := GetJSON(Data);
  if not (Parsed is TJSONObject) then
  begin Parsed.Free; raise Exception.Create(Stage+' must return a JSON object'); end;
  Result := TJSONObject(Parsed);
  if ((Result.Find('ok') <> nil) and not Result.Get('ok', True)) or
    ((Result.Find('success') <> nil) and not Result.Get('success', True)) or
    (Result.Get('status', '') = 'erro') or (Result.Get('status', '') = 'error') or
    (Result.Get('status_jarvis', '') = 'erro') or Result.Get('simulated', False) then
  begin Result.Free; raise Exception.Create(Stage+' reported unavailable processing'); end;
end;

function TextOf(J: TJSONObject; const Name: string): string;
var D: TJSONData;
begin
  Result := ''; D := J.Find(Name);
  if (D <> nil) and (D.JSONType = jtString) then Result := Trim(D.AsString);
end;

constructor TAISIPVoiceHTTPBackend.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FTimeoutMs := 30000; FReplyFormat := vrCasa;
  FSTTURL := 'http://127.0.0.1:8092/transcribe';
  FReplyURL := 'https://maurinsoft.com.br/casa/api/v1/comando';
  FTTSURL := 'http://127.0.0.1:8097/falar';
  FAudioBaseURL := 'http://127.0.0.1:8097/audio/';
  FSpeaker := 'padrao';
  FSystemPrompt := 'Responda em portugues do Brasil, de forma breve e adequada a uma conversa telefonica.';
end;

function TAISIPVoiceHTTPBackend.Request(const Stage, Method, URL,
  ContentType, Token: string; const Body: RawByteString): RawByteString;
var Curl: PCURL; Headers: Pcurl_slist; Stream: TMemoryStream;
    Code: CURLcode; Status: clong; URI: TURI; Header: string;

  procedure Check(Value: CURLcode);
  begin
    if Value <> CURLE_OK then raise Exception.Create(Stage+' HTTP configuration failed');
  end;

begin
  Result := ''; URI := ParseURI(URL);
  if not ((URI.Protocol = 'http') or (URI.Protocol = 'https')) or
    (URI.Host = '') or (URI.UserName <> '') or (URI.Password <> '') or
    (Pos(#13, URL+Token) > 0) or (Pos(#10, URL+Token) > 0) then
    raise Exception.Create(Stage+' requires an HTTP(S) URL without embedded credentials');
  if (FTimeoutMs < 100) or (FTimeoutMs > 120000) then
    raise Exception.Create('HTTP timeout must be 100..120000 ms');
  Curl := curl_easy_init;
  if Curl = nil then raise Exception.Create('Cannot create HTTP client');
  Stream := TMemoryStream.Create; Headers := nil;
  try
    Check(curl_easy_setopt(Curl, CURLOPT_URL, [PChar(URL)]));
    Check(curl_easy_setopt(Curl, CURLOPT_NOSIGNAL, [clong(1)]));
    Check(curl_easy_setopt(Curl, CURLOPT_TIMEOUT_MS, [clong(FTimeoutMs)]));
    Check(curl_easy_setopt(Curl, CURLOPT_CONNECTTIMEOUT_MS, [clong(5000)]));
    Check(curl_easy_setopt(Curl, CURLOPT_SSL_VERIFYPEER, [clong(1)]));
    Check(curl_easy_setopt(Curl, CURLOPT_SSL_VERIFYHOST, [clong(2)]));
    Check(curl_easy_setopt(Curl, CURLOPT_FOLLOWLOCATION, [clong(0)]));
    Check(curl_easy_setopt(Curl, CURLOPT_PROTOCOLS, [clong(CURLPROTO_HTTP or CURLPROTO_HTTPS)]));
    Check(curl_easy_setopt(Curl, CURLOPT_WRITEFUNCTION, [Pointer(@Receive)]));
    Check(curl_easy_setopt(Curl, CURLOPT_WRITEDATA, [Pointer(Stream)]));
    if ContentType <> '' then
    begin
      Header := 'Content-Type: '+ContentType; Headers := curl_slist_append(Headers, PChar(Header));
    end;
    if Token <> '' then
    begin
      Header := 'Authorization: Bearer '+Token; Headers := curl_slist_append(Headers, PChar(Header));
    end;
    if Headers <> nil then Check(curl_easy_setopt(Curl, CURLOPT_HTTPHEADER, [Headers]));
    if Method = 'POST' then
    begin
      Check(curl_easy_setopt(Curl, CURLOPT_POST, [clong(1)]));
      Check(curl_easy_setopt(Curl, CURLOPT_POSTFIELDS, [PChar(Body)]));
      Check(curl_easy_setopt(Curl, CURLOPT_POSTFIELDSIZE, [clong(Length(Body))]));
    end;
    Code := curl_easy_perform(Curl);
    if Code <> CURLE_OK then
      raise Exception.CreateFmt('%s HTTP transport failed (curl=%d)', [Stage, Ord(Code)]);
    Status := 0; Check(curl_easy_getinfo(Curl, CURLINFO_RESPONSE_CODE, [@Status]));
    if Status <> 200 then raise Exception.CreateFmt('%s HTTP status %d', [Stage, Status]);
    SetLength(Result, Stream.Size);
    if Stream.Size > 0 then Move(Stream.Memory^, Result[1], Stream.Size);
  finally curl_slist_free_all(Headers); Stream.Free; curl_easy_cleanup(Curl); end;
end;

function TAISIPVoiceHTTPBackend.Transcribe(const WAV: RawByteString): string;
var J: TJSONObject;
begin
  J := ObjectOf(Request('STT', 'POST', FSTTURL, 'audio/wav', FSTTToken, WAV), 'STT');
  try
    Result := TextOf(J, 'texto'); if Result = '' then Result := TextOf(J, 'text');
    if not SIPVoiceRealTranscript(Result) then
      raise Exception.Create('STT returned empty or demonstration text; configure a real ASR engine');
  finally J.Free; end;
end;

function TAISIPVoiceHTTPBackend.Reply(const SessionID, Text, HistoryJSON: string): string;
var Body, J, Item: TJSONObject; History, Messages, Choices: TJSONArray;
    Parsed, D: TJSONData; I: Integer;
begin
  Parsed := GetJSON(HistoryJSON);
  if not (Parsed is TJSONArray) then
  begin Parsed.Free; raise Exception.Create('Conversation history must be an array'); end;
  History := TJSONArray(Parsed); Body := TJSONObject.Create;
  try
    if FReplyFormat = vrCasa then
    begin
      if FReplyToken = '' then raise Exception.Create('Casa API token is required');
      Body.Add('comando', Text); Body.Add('origem', 'SIP');
      Body.Add('session_id', SessionID); Body.Add('historico_mensagens', History.Clone);
    end
    else
    begin
      if FModel = '' then raise Exception.Create('An AI model is required');
      Messages := TJSONArray.Create; Body.Add('messages', Messages);
      Messages.Add(TJSONObject.Create(['role', 'system', 'content', FSystemPrompt]));
      for I := 0 to History.Count-1 do Messages.Add(History.Items[I].Clone);
      Messages.Add(TJSONObject.Create(['role', 'user', 'content', Text]));
      Body.Add('model', FModel); Body.Add('stream', False);
    end;
    J := ObjectOf(Request('AI', 'POST', FReplyURL, 'application/json', FReplyToken, Body.AsJSON), 'AI');
    try
      if FReplyFormat = vrCasa then Result := TextOf(J, 'resposta')
      else
      begin
        Result := ''; Choices := J.Get('choices', TJSONArray(nil));
        if (Choices <> nil) and (Choices.Count > 0) and (Choices[0] is TJSONObject) then
        begin
          Item := TJSONObject(Choices[0]); D := Item.Find('message');
          if D is TJSONObject then Result := TextOf(TJSONObject(D), 'content');
        end;
      end;
      if Result = '' then raise Exception.Create('AI did not return a textual answer');
    finally J.Free; end;
  finally History.Free; Body.Free; end;
end;

function TAISIPVoiceHTTPBackend.Synthesize(const Text: string): TAISIPAudioSamples;
var Body, J: TJSONObject; Data: RawByteString; URI: TURI;
    AudioName, Base: string; I: Integer;
begin
  Body := TJSONObject.Create(['texto', Text, 'speaker', FSpeaker, 'reproduzir', False]);
  try Data := Request('TTS', 'POST', FTTSURL, 'application/json', FTTSToken, Body.AsJSON);
  finally Body.Free; end;
  if Copy(Data, 1, 4) <> 'RIFF' then
  begin
    J := ObjectOf(Data, 'TTS');
    try URI := ParseURI(TextOf(J, 'audio_url')); finally J.Free; end;
    AudioName := URI.Document;
    if (AudioName = '') or (Pos('..', AudioName) > 0) or
      (LowerCase(ExtractFileExt(AudioName)) <> '.wav') then
      raise Exception.Create('TTS did not return a safe WAV filename');
    for I := 1 to Length(AudioName) do
      if not (AudioName[I] in ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.']) then
        raise Exception.Create('Invalid TTS audio filename');
    Base := FAudioBaseURL;
    if Base = '' then raise Exception.Create('TTS AudioBaseURL is required for JSON responses');
    if Base[Length(Base)] <> '/' then Base := Base+'/';
    { The service response cannot select a host or an arbitrary local path. }
    Data := Request('TTS audio', 'GET', Base+AudioName, '', FTTSToken, '');
  end;
  Result := SIPVoiceReadWAV(Data);
end;

initialization
  if curl_global_init(CURL_GLOBAL_DEFAULT) <> CURLE_OK then
    raise Exception.Create('libcurl initialization failed');
finalization
  curl_global_cleanup;
end.
