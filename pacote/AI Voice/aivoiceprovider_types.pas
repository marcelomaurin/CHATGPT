unit aivoiceprovider_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  { TAIVoiceProvider: Supported voice synthesis providers }
  TAIVoiceProvider = (
    vpNone,
    vpOpenAI,
    vpOpenAICompatible,
    vpGoogle,
    vpAzure,
    vpElevenLabs,
    vpCustomHTTP
  );

  { TAIVoiceState: Lifecycle state of the voice synthesizer }
  TAIVoiceState = (
    vsIdle,
    vsSynthesizing,
    vsPlaying,
    vsStopping,
    vsError
  );

  { TAIVoiceUsage: Telemetry and metrics for voice synthesis operations }
  TAIVoiceUsage = record
    Provider          : TAIVoiceProvider;
    Model             : string;
    Voice             : string;
    Characters        : Integer;
    RequestDurationMS : Int64;
    AudioDurationMS   : Int64;
    Success           : Boolean;
    ErrorCode         : string;
    FallbackUsed      : Boolean;
  end;

function VoiceProviderToString(AProvider: TAIVoiceProvider): string;
function StringToVoiceProvider(const AStr: string): TAIVoiceProvider;
function VoiceStateToString(AState: TAIVoiceState): string;

implementation

function VoiceProviderToString(AProvider: TAIVoiceProvider): string;
begin
  case AProvider of
    vpNone:             Result := 'None';
    vpOpenAI:           Result := 'OpenAI';
    vpOpenAICompatible: Result := 'OpenAI-Compatible';
    vpGoogle:           Result := 'Google';
    vpAzure:            Result := 'Azure';
    vpElevenLabs:       Result := 'ElevenLabs';
    vpCustomHTTP:       Result := 'CustomHTTP';
  else
    Result := 'None';
  end;
end;

function StringToVoiceProvider(const AStr: string): TAIVoiceProvider;
var
  S: string;
begin
  S := UpperCase(Trim(AStr));
  if (S = 'OPENAI') then
    Result := vpOpenAI
  else if (S = 'OPENAI-COMPATIBLE') or (S = 'OPENAICOMPATIBLE') or (S = 'COMPATIBLE') then
    Result := vpOpenAICompatible
  else if (S = 'GOOGLE') then
    Result := vpGoogle
  else if (S = 'AZURE') then
    Result := vpAzure
  else if (S = 'ELEVENLABS') or (S = 'ELEVEN_LABS') then
    Result := vpElevenLabs
  else if (S = 'CUSTOMHTTP') or (S = 'CUSTOM_HTTP') or (S = 'CUSTOM') then
    Result := vpCustomHTTP
  else
    Result := vpNone;
end;

function VoiceStateToString(AState: TAIVoiceState): string;
begin
  case AState of
    vsIdle:         Result := 'Idle';
    vsSynthesizing: Result := 'Synthesizing';
    vsPlaying:      Result := 'Playing';
    vsStopping:     Result := 'Stopping';
    vsError:        Result := 'Error';
  else
    Result := 'Unknown';
  end;
end;

end.
