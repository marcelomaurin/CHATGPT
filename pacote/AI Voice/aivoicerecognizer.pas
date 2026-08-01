unit aivoicerecognizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF MSWINDOWS}
  ComObj, ActiveX, Variants,
  {$ENDIF}
  aibase, LResources,
  fphttpclient, opensslsockets, fpjson, jsonparser;

type
  TAIVoiceRecognitionEngine = (vreOpenAIWhisper, vreSAPI, vreSystemDefault);

  TAIVoiceRecognizedEvent = procedure(
    Sender: TObject;
    const AText: string
  ) of object;

  { TAIVoiceRecognizer }

  TAIVoiceRecognizer = class(TAIBaseComponent)
  private
    FAudioFile     : string;
    FLanguage      : string;
    FPromptText    : string;
    FEngine        : TAIVoiceRecognitionEngine;
    FOpenAIToken   : string;
    FOpenAIModel   : string;
    FOpenAIEndpoint: string;
    FRecognizedText: string;
    FOnRecognized  : TAIVoiceRecognizedEvent;

    function TranscribeOpenAIWhisper(const AFileName: string; out AText: string): Boolean;
    function TranscribeSAPI(const AFileName: string; out AText: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    function Recognize(const AAudioFile: string = ''): Boolean;
    function TranscribeFile(const AFileName: string; out AText: string): Boolean;

  published
    property AudioFile: string read FAudioFile write FAudioFile;
    property Language: string read FLanguage write FLanguage;
    property PromptText: string read FPromptText write FPromptText;
    property Engine: TAIVoiceRecognitionEngine read FEngine write FEngine default vreOpenAIWhisper;
    property OpenAIToken: string read FOpenAIToken write FOpenAIToken;
    property OpenAIModel: string read FOpenAIModel write FOpenAIModel;
    property OpenAIEndpoint: string read FOpenAIEndpoint write FOpenAIEndpoint;
    property RecognizedText: string read FRecognizedText;

    property OnRecognized: TAIVoiceRecognizedEvent read FOnRecognized write FOnRecognized;
  end;

  // Alias para retrocompatibilidade com TAISpeechRecognizer
  TAISpeechRecognizer = TAIVoiceRecognizer;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Voice', [TAIVoiceRecognizer]);
end;

{ TAIVoiceRecognizer }

constructor TAIVoiceRecognizer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FAudioFile := '';
  FLanguage := 'pt';
  FPromptText := '';
  FEngine := vreOpenAIWhisper;
  FOpenAIToken := GetEnvironmentVariable('OPENAI_API_KEY');
  FOpenAIModel := 'whisper-1';
  FOpenAIEndpoint := 'https://api.openai.com/v1/audio/transcriptions';
  FRecognizedText := '';
  FPrompt := 'TAIVoiceRecognizer realiza reconhecimento de voz e transcrição de áudio via Whisper e SAPI.';
  ClearError;
end;

destructor TAIVoiceRecognizer.Destroy;
begin
  inherited Destroy;
end;

procedure TAIVoiceRecognizer.Clear;
begin
  ClearError;
  FRecognizedText := '';
  FLastResult := '';
end;

function TAIVoiceRecognizer.TranscribeOpenAIWhisper(const AFileName: string; out AText: string): Boolean;
var
  Client: TFPHTTPClient;
  Boundary, BodyHeader, BodyFooter: string;
  RequestStream: TMemoryStream;
  AudioData: TFileStream;
  ResponseText, Token: string;
  JSONData: TJSONData;
  Obj: TJSONObject;
begin
  Result := False;
  AText := '';

  Token := Trim(FOpenAIToken);
  if Token = '' then
    Token := GetEnvironmentVariable('OPENAI_API_KEY');

  if Token = '' then
  begin
    SetError('OpenAI API Token nao configurado.');
    Exit(False);
  end;

  if not FileExists(AFileName) then
  begin
    SetError('Arquivo de audio nao encontrado: ' + AFileName);
    Exit(False);
  end;

  Boundary := '---------------------------' + FormatDateTime('hhnnsszzz', Now);
  RequestStream := TMemoryStream.Create;
  AudioData := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  Client := TFPHTTPClient.Create(nil);
  try
    try
      // Field: model
      BodyHeader := '--' + Boundary + sLineBreak +
        'Content-Disposition: form-data; name="model"' + sLineBreak + sLineBreak +
        FOpenAIModel + sLineBreak;

      // Field: language (opcional)
      if Trim(FLanguage) <> '' then
        BodyHeader := BodyHeader + '--' + Boundary + sLineBreak +
          'Content-Disposition: form-data; name="language"' + sLineBreak + sLineBreak +
          FLanguage + sLineBreak;

      // Field: prompt (opcional)
      if Trim(FPromptText) <> '' then
        BodyHeader := BodyHeader + '--' + Boundary + sLineBreak +
          'Content-Disposition: form-data; name="prompt"' + sLineBreak + sLineBreak +
          FPromptText + sLineBreak;

      // Field: file
      BodyHeader := BodyHeader + '--' + Boundary + sLineBreak +
        'Content-Disposition: form-data; name="file"; filename="' + ExtractFileName(AFileName) + '"' + sLineBreak +
        'Content-Type: application/octet-stream' + sLineBreak + sLineBreak;

      RequestStream.WriteBuffer(BodyHeader[1], Length(BodyHeader));
      RequestStream.CopyFrom(AudioData, AudioData.Size);

      BodyFooter := sLineBreak + '--' + Boundary + '--' + sLineBreak;
      RequestStream.WriteBuffer(BodyFooter[1], Length(BodyFooter));
      RequestStream.Position := 0;

      Client.AddHeader('Authorization', 'Bearer ' + Token);
      Client.AddHeader('Content-Type', 'multipart/form-data; boundary=' + Boundary);
      Client.RequestBody := RequestStream;

      ResponseText := Client.Post(FOpenAIEndpoint);

      if ResponseText <> '' then
      begin
        JSONData := GetJSON(ResponseText);
        try
          if JSONData is TJSONObject then
          begin
            Obj := TJSONObject(JSONData);
            if Obj.IndexOfName('text') >= 0 then
            begin
              AText := Obj.Get('text', '');
              Result := True;
            end;
            if Obj.IndexOfName('error') >= 0 then
            begin
              SetError(Obj.FormatJSON);
              Exit(False);
            end;
          end;
        finally
          JSONData.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        SetError('Erro ao transcrever audio via OpenAI Whisper: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Client.Free;
    AudioData.Free;
    RequestStream.Free;
  end;
end;

function TAIVoiceRecognizer.TranscribeSAPI(const AFileName: string; out AText: string): Boolean;
begin
  Result := False;
  AText := '';
  {$IFDEF MSWINDOWS}
  try
    if AFileName = '' then ;
    SetError('SAPI Speech Recognition requer arquivo WAV gravado no formato SAPI.');
    Result := False;
  except
    on E: Exception do
      SetError('Erro no SAPI: ' + E.Message);
  end;
  {$ELSE}
  if AFileName = '' then ;
  SetError('SAPI esta disponivel apenas no Windows.');
  {$ENDIF}
end;

function TAIVoiceRecognizer.TranscribeFile(const AFileName: string; out AText: string): Boolean;
begin
  ClearError;
  Result := False;
  AText := '';

  case FEngine of
    vreOpenAIWhisper, vreSystemDefault:
      Result := TranscribeOpenAIWhisper(AFileName, AText);
    vreSAPI:
      Result := TranscribeSAPI(AFileName, AText);
  end;
end;

function TAIVoiceRecognizer.Recognize(const AAudioFile: string): Boolean;
var
  TargetFile: string;
begin
  ClearError;
  Result := False;
  FRecognizedText := '';

  if Trim(AAudioFile) <> '' then
    TargetFile := AAudioFile
  else
    TargetFile := FAudioFile;

  if Trim(TargetFile) = '' then
  begin
    SetError('Nenhum arquivo de audio especificado para reconhecimento.');
    Exit(False);
  end;

  Result := TranscribeFile(TargetFile, FRecognizedText);
  if Result then
  begin
    FLastResult := FRecognizedText;
    FLastSuccess := True;
    Log(llInfo, 'Voz reconhecida com sucesso.');
    if Assigned(FOnRecognized) then
      FOnRecognized(Self, FRecognizedText);
  end;
end;

end.
