unit aivoiceprovider_backend;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets,
  aivoiceprovider_types;

type
  { TAIVoiceConfig: Encapsulates all parameters for remote voice synthesis }
  TAIVoiceConfig = record
    Provider     : TAIVoiceProvider;
    APIToken     : string;
    Model        : string;
    Endpoint     : string;
    RemoteVoice  : string;
    Language     : string;
    OutputFormat : string;
    OutputFile   : string;
    Speed        : Double;
    Instructions : string;
    TimeoutMS    : Integer;
    MaxRetries   : Integer;
  end;

  { IAIVoiceProviderBackend: Abstract contract for remote TTS providers }
  IAIVoiceProviderBackend = interface
    ['{6E7E91FE-131B-4A1E-B4A1-561A7C203792}']
    function ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean;
    function Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean;
    procedure Cancel;
    function LastError: string;
  end;

  { TAIVoiceProviderBackendBase: Common base class for remote backends }
  TAIVoiceProviderBackendBase = class(TInterfacedObject, IAIVoiceProviderBackend)
  protected
    FLastError: string;
    FCancelled: Boolean;
    function MaskToken(const AToken: string): string;
    function JSONEscape(const S: string): string;
    function BuildLanguagePrompt(const ALanguage, ACustomInstructions: string): string;
    function ExecuteHTTPRequest(const AEndpoint, APayload, AToken, AOutputFile: string;
      ATimeoutMS, AMaxRetries: Integer; out AErrorMsg: string): Boolean;
  public
    constructor Create; virtual;
    function ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean; virtual; abstract;
    function Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean; virtual; abstract;
    procedure Cancel; virtual;
    function LastError: string;
  end;

implementation

constructor TAIVoiceProviderBackendBase.Create;
begin
  inherited Create;
  FLastError := '';
  FCancelled := False;
end;

procedure TAIVoiceProviderBackendBase.Cancel;
begin
  FCancelled := True;
end;

function TAIVoiceProviderBackendBase.LastError: string;
begin
  Result := FLastError;
end;

function TAIVoiceProviderBackendBase.MaskToken(const AToken: string): string;
var
  L: Integer;
begin
  L := Length(AToken);
  if L <= 8 then
    Result := '***'
  else
    Result := Copy(AToken, 1, 4) + '...' + Copy(AToken, L - 3, 4);
end;

function TAIVoiceProviderBackendBase.JSONEscape(const S: string): string;
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

function TAIVoiceProviderBackendBase.BuildLanguagePrompt(const ALanguage, ACustomInstructions: string): string;
var
  LangPrompt: string;
begin
  if SameText(ALanguage, 'pt-BR') then
    LangPrompt := 'Speak in Brazilian Portuguese (pt-BR). Use a natural, clear and professional tone.'
  else if SameText(ALanguage, 'en-US') then
    LangPrompt := 'Speak in English (en-US). Use a natural, clear and professional tone.'
  else if SameText(ALanguage, 'es-ES') then
    LangPrompt := 'Speak in Spanish (es-ES). Use a natural, clear and professional tone.'
  else if SameText(ALanguage, 'fr-FR') then
    LangPrompt := 'Speak in French (fr-FR). Use a natural, clear and professional tone.'
  else if SameText(ALanguage, 'it-IT') then
    LangPrompt := 'Speak in Italian (it-IT). Use a natural, clear and professional tone.'
  else if SameText(ALanguage, 'de-DE') then
    LangPrompt := 'Speak in German (de-DE). Use a natural, clear and professional tone.'
  else if SameText(ALanguage, 'ja-JP') then
    LangPrompt := 'Speak in Japanese (ja-JP). Use a natural, clear and professional tone.'
  else if SameText(ALanguage, 'zh-CN') then
    LangPrompt := 'Speak in Chinese (zh-CN). Use a natural, clear and professional tone.'
  else if Trim(ALanguage) <> '' then
    LangPrompt := 'Speak in the selected language (' + ALanguage + '). Use a natural, clear and professional tone.'
  else
    LangPrompt := '';

  if Trim(ACustomInstructions) <> '' then
  begin
    if LangPrompt <> '' then
      Result := LangPrompt + ' ' + ACustomInstructions
    else
      Result := ACustomInstructions;
  end
  else
    Result := LangPrompt;
end;

function TAIVoiceProviderBackendBase.ExecuteHTTPRequest(const AEndpoint, APayload, AToken, AOutputFile: string;
  ATimeoutMS, AMaxRetries: Integer; out AErrorMsg: string): Boolean;
var
  HTTP: TFPHttpClient;
  BodyStream: TStringStream;
  ResponseStream: TFileStream;
  DestDir: string;
  Attempt: Integer;
  Success: Boolean;
  ActualTimeout: Integer;
begin
  Result := False;
  AErrorMsg := '';
  FLastError := '';
  FCancelled := False;

  if ATimeoutMS <= 0 then
    ActualTimeout := 30000
  else
    ActualTimeout := ATimeoutMS;

  if AMaxRetries < 0 then
    AMaxRetries := 0;

  DestDir := ExtractFilePath(AOutputFile);
  if DestDir = '' then
    DestDir := 'output' + DirectorySeparator;
  if not DirectoryExists(DestDir) then
    ForceDirectories(DestDir);

  Attempt := 0;
  Success := False;

  while (Attempt <= AMaxRetries) and (not Success) and (not FCancelled) do
  begin
    Inc(Attempt);
    HTTP := TFPHttpClient.Create(nil);
    BodyStream := nil;
    ResponseStream := nil;
    try
      try
        BodyStream := TStringStream.Create(APayload);
        HTTP.AddHeader('Content-Type', 'application/json');
        if Trim(AToken) <> '' then
          HTTP.AddHeader('Authorization', 'Bearer ' + AToken);

        HTTP.RequestBody := BodyStream;
        HTTP.AllowRedirect := True;
        HTTP.IOTimeout := ActualTimeout;
        HTTP.ConnectTimeout := ActualTimeout;

        if FileExists(AOutputFile) then
          DeleteFile(AOutputFile);

        ResponseStream := TFileStream.Create(AOutputFile, fmCreate);
        HTTP.Post(AEndpoint, ResponseStream);

        // Check HTTP response code
        if (HTTP.ResponseStatusCode >= 200) and (HTTP.ResponseStatusCode < 300) then
        begin
          Success := True;
        end
        else
        begin
          AErrorMsg := Format('HTTP Error %d: %s (Endpoint: %s)', [HTTP.ResponseStatusCode, HTTP.ResponseStatusText, AEndpoint]);
          // Do not retry on authentication/authorization errors (401, 403) or bad request (400)
          if (HTTP.ResponseStatusCode = 400) or (HTTP.ResponseStatusCode = 401) or (HTTP.ResponseStatusCode = 403) then
            Break;
        end;
      except
        on E: Exception do
        begin
          AErrorMsg := Format('Network/HTTP error on attempt %d: %s (Endpoint: %s)', [Attempt, E.Message, AEndpoint]);
          // Sleep briefly before retry if retrying
          if Attempt <= AMaxRetries then
            Sleep(500);
        end;
      end;
    finally
      if Assigned(ResponseStream) then
        FreeAndNil(ResponseStream);
      if Assigned(BodyStream) then
        FreeAndNil(BodyStream);
      FreeAndNil(HTTP);
    end;
  end;

  if FCancelled then
  begin
    AErrorMsg := 'Voice synthesis cancelled by user.';
    if FileExists(AOutputFile) then
      DeleteFile(AOutputFile);
    Success := False;
  end;

  FLastError := AErrorMsg;
  Result := Success;
end;

end.
