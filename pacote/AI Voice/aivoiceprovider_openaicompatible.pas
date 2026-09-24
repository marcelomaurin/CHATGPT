unit aivoiceprovider_openaicompatible;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  aivoiceprovider_types, aivoiceprovider_backend;

type
  { TAIOpenAICompatibleVoiceBackend: For OpenAI-compatible TTS endpoints (e.g. LocalAI, vLLM, RunPod) }
  TAIOpenAICompatibleVoiceBackend = class(TAIVoiceProviderBackendBase)
  public
    function ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean; override;
    function Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean; override;
  end;

implementation

function TAIOpenAICompatibleVoiceBackend.ValidateConfig(const AConfig: TAIVoiceConfig; const AText: string; out AErrorMsg: string): Boolean;
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
    AErrorMsg := 'OpenAI-Compatible endpoint URL is required.';
    FLastError := AErrorMsg;
    Exit;
  end;

  if Trim(AConfig.Model) = '' then
  begin
    AErrorMsg := 'Model name is required for OpenAI-Compatible TTS.';
    FLastError := AErrorMsg;
    Exit;
  end;

  if (AConfig.Speed < 0.25) or (AConfig.Speed > 4.0) then
  begin
    AErrorMsg := Format('Speed %0.2f out of range (allowed: 0.25 to 4.0).', [AConfig.Speed]);
    FLastError := AErrorMsg;
    Exit;
  end;

  Result := True;
end;

function TAIOpenAICompatibleVoiceBackend.Synthesize(const AConfig: TAIVoiceConfig; const AText, AOutputFile: string; out AErrorMsg: string): Boolean;
var
  Payload: string;
  EscapedInput: string;
  SpeedStr: string;
  FormatStr: string;
  TargetFile: string;
  VoiceName: string;
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
  if VoiceName = '' then
    VoiceName := 'default';

  EscapedInput := JSONEscape(AText);
  SpeedStr := Format('%0.2f', [AConfig.Speed]);
  SpeedStr := StringReplace(SpeedStr, ',', '.', []);

  Payload := '{' +
    '"model": "' + JSONEscape(AConfig.Model) + '",' +
    '"input": "' + EscapedInput + '",' +
    '"voice": "' + JSONEscape(VoiceName) + '",' +
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

end.
