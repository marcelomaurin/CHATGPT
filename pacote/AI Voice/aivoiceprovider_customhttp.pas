unit aivoiceprovider_customhttp;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  aivoiceprovider_types, aivoiceprovider_backend;

type
  { TAICustomHTTPVoiceBackend: For generic custom HTTP voice synthesis endpoints }
  TAICustomHTTPVoiceBackend = class(TAIVoiceProviderBackendBase)
  public
    function ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean; override;
    function Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean; override;
  end;

  { TAIUnimplementedVoiceBackend: Explicit stub for providers pending implementation }
  TAIUnimplementedVoiceBackend = class(TAIVoiceProviderBackendBase)
  private
    FProviderName: string;
  public
    constructor Create(const AProviderName: string); reintroduce;
    function ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean; override;
    function Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean; override;
  end;

implementation

{ TAICustomHTTPVoiceBackend }

function TAICustomHTTPVoiceBackend.ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean;
begin
  Result := False;
  AErrorMsg := '';

  if Trim(AText) = '' then
  begin
    AErrorMsg := 'Text to synthesize is empty.';
    FLastError := AErrorMsg;
    Exit;
  end;

  if Trim(AConfig.Endpoint) = '' then
  begin
    AErrorMsg := 'Custom HTTP endpoint URL is required.';
    FLastError := AErrorMsg;
    Exit;
  end;

  Result := True;
end;

function TAICustomHTTPVoiceBackend.Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean;
var
  Payload: string;
  EscapedInput: string;
  SpeedStr: string;
  FormatStr: string;
  TargetFile: string;
  VoiceName: string;
  ModelName: string;
begin
  Result := False;
  AErrorMsg := '';

  if not ValidateConfig(AConfig, AText, AErrorMsg) then
    Exit;

  TargetFile := AOutputFile;
  if Trim(TargetFile) = '' then
    TargetFile := AConfig.OutputFile;
  if Trim(TargetFile) = '' then
    TargetFile := 'output' + DirectorySeparator + 'speech.mp3';

  FormatStr := LowerCase(Trim(AConfig.OutputFormat));
  if FormatStr = '' then
    FormatStr := 'mp3';

  VoiceName := Trim(AConfig.RemoteVoice);
  ModelName := Trim(AConfig.Model);
  EscapedInput := JSONEscape(AText);
  SpeedStr := Format('%0.2f', [AConfig.Speed]);
  SpeedStr := StringReplace(SpeedStr, ',', '.', []);

  Payload := '{' +
    '"text": "' + EscapedInput + '",' +
    '"input": "' + EscapedInput + '",' +
    '"model": "' + JSONEscape(ModelName) + '",' +
    '"voice": "' + JSONEscape(VoiceName) + '",' +
    '"format": "' + JSONEscape(FormatStr) + '",' +
    '"response_format": "' + JSONEscape(FormatStr) + '",' +
    '"speed": ' + SpeedStr +
    '}';

  Result := ExecuteHTTPRequest(
    AConfig.Endpoint,
    Payload,
    AConfig.APIToken,
    TargetFile,
    AConfig.TimeoutMS,
    AConfig.MaxRetries,
    AErrorMsg
  );
end;

{ TAIUnimplementedVoiceBackend }

constructor TAIUnimplementedVoiceBackend.Create(const AProviderName: string);
begin
  inherited Create;
  FProviderName := AProviderName;
end;

function TAIUnimplementedVoiceBackend.ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean;
begin
  AErrorMsg := Format('Provider not implemented: %s', [FProviderName]);
  FLastError := AErrorMsg;
  Result := False;
end;

function TAIUnimplementedVoiceBackend.Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean;
begin
  AErrorMsg := Format('Provider not implemented: %s', [FProviderName]);
  FLastError := AErrorMsg;
  Result := False;
end;

end.
