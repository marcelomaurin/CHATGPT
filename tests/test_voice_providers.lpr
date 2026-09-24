program test_voice_providers;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  aivoiceprovider_types,
  aivoiceprovider_backend,
  aivoiceprovider_openai,
  aivoiceprovider_openaicompatible,
  aivoiceprovider_customhttp,
  aivoicecredentialstore,
  aivoicesynthesizer;

var
  TotalTests: Integer = 0;
  PassedTests: Integer = 0;

procedure Assert(ACondition: Boolean; const ATestName: string);
begin
  Inc(TotalTests);
  if ACondition then
  begin
    Inc(PassedTests);
    WriteLn('[PASS] ', ATestName);
  end
  else
  begin
    WriteLn('[FAIL] ', ATestName);
  end;
end;

procedure TestProviderEnumsAndStrings;
begin
  WriteLn('--- Testing Voice Provider Enums & Conversions ---');
  Assert(VoiceProviderToString(vpNone) = 'None', 'VoiceProviderToString(vpNone)');
  Assert(VoiceProviderToString(vpOpenAI) = 'OpenAI', 'VoiceProviderToString(vpOpenAI)');
  Assert(VoiceProviderToString(vpOpenAICompatible) = 'OpenAI-Compatible', 'VoiceProviderToString(vpOpenAICompatible)');
  Assert(VoiceProviderToString(vpGoogle) = 'Google', 'VoiceProviderToString(vpGoogle)');
  Assert(VoiceProviderToString(vpAzure) = 'Azure', 'VoiceProviderToString(vpAzure)');
  Assert(VoiceProviderToString(vpElevenLabs) = 'ElevenLabs', 'VoiceProviderToString(vpElevenLabs)');
  Assert(VoiceProviderToString(vpCustomHTTP) = 'CustomHTTP', 'VoiceProviderToString(vpCustomHTTP)');

  Assert(StringToVoiceProvider('OpenAI') = vpOpenAI, 'StringToVoiceProvider("OpenAI")');
  Assert(StringToVoiceProvider('OPENAI-COMPATIBLE') = vpOpenAICompatible, 'StringToVoiceProvider("OPENAI-COMPATIBLE")');
  Assert(StringToVoiceProvider('google') = vpGoogle, 'StringToVoiceProvider("google")');
  Assert(StringToVoiceProvider('azure') = vpAzure, 'StringToVoiceProvider("azure")');
  Assert(StringToVoiceProvider('elevenlabs') = vpElevenLabs, 'StringToVoiceProvider("elevenlabs")');
  Assert(StringToVoiceProvider('customhttp') = vpCustomHTTP, 'StringToVoiceProvider("customhttp")');
  Assert(StringToVoiceProvider('invalid_value') = vpNone, 'StringToVoiceProvider invalid returns vpNone');
end;

procedure TestCredentialStore;
var
  Secret: string;
  ProtectedStr: string;
  RecoveredStr: string;
begin
  WriteLn('--- Testing TVoiceCredentialStore ---');
  Secret := 'sk-test-secret-key-1234567890abcdef';
  ProtectedStr := TVoiceCredentialStore.ProtectToken(Secret);
  Assert(ProtectedStr <> '', 'ProtectToken returns non-empty string');
  Assert(ProtectedStr <> Secret, 'Protected token is not plain text');

  RecoveredStr := TVoiceCredentialStore.UnprotectToken(ProtectedStr);
  Assert(RecoveredStr = Secret, 'UnprotectToken recovers original secret');

  // Test legacy unencrypted token fallback
  RecoveredStr := TVoiceCredentialStore.UnprotectToken('sk-legacy-unencrypted-token');
  Assert(RecoveredStr = 'sk-legacy-unencrypted-token', 'UnprotectToken returns raw legacy token as fallback');
end;

procedure TestBackwardCompatibilityProperties;
var
  Synth: TAIVoiceSynthesizer;
begin
  WriteLn('--- Testing Backward Compatibility Aliases ---');
  Synth := TAIVoiceSynthesizer.Create(nil);
  try
    Synth.OpenAIToken := 'token-abc';
    Assert(Synth.APIToken = 'token-abc', 'OpenAIToken maps to APIToken');

    Synth.OpenAIModel := 'tts-1-hd';
    Assert(Synth.Model = 'tts-1-hd', 'OpenAIModel maps to Model');

    Synth.OpenAIEndpoint := 'https://custom.endpoint/v1';
    Assert(Synth.Endpoint = 'https://custom.endpoint/v1', 'OpenAIEndpoint maps to Endpoint');

    Synth.OpenAIVoice := 'nova';
    Assert(Synth.RemoteVoice = 'nova', 'OpenAIVoice maps to RemoteVoice');

    Synth.OpenAIOutputFormat := 'wav';
    Assert(Synth.OutputFormat = 'wav', 'OpenAIOutputFormat maps to OutputFormat');

    Synth.OpenAIOutputFile := 'custom.wav';
    Assert(Synth.OutputFile = 'custom.wav', 'OpenAIOutputFile maps to OutputFile');
  finally
    Synth.Free;
  end;
end;

procedure TestValidationRules;
var
  Synth: TAIVoiceSynthesizer;
  Msg: string;
begin
  WriteLn('--- Testing Validation Rules ---');
  Synth := TAIVoiceSynthesizer.Create(nil);
  try
    Synth.Provider := vpOpenAI;
    Synth.APIToken := '';
    Assert(not Synth.ValidateRemoteConfig('Hello'), 'Validate fails when APIToken is empty');
    Assert(Pos('token', LowerCase(Synth.LastError)) > 0, 'Error message mentions token');

    Synth.APIToken := 'sk-valid-token-mock';
    Synth.Model := '';
    Assert(not Synth.ValidateRemoteConfig('Hello'), 'Validate fails when Model is empty');
    Assert(Pos('model', LowerCase(Synth.LastError)) > 0, 'Error message mentions model');

    Synth.Model := 'gpt-4o-mini-tts';
    Synth.Endpoint := '';
    Assert(not Synth.ValidateRemoteConfig('Hello'), 'Validate fails when Endpoint is empty');

    Synth.Endpoint := 'https://api.openai.com/v1/audio/speech';
    Assert(not Synth.ValidateRemoteConfig('   '), 'Validate fails when text is empty');

    Synth.Speed := 5.0;
    Assert(not Synth.ValidateRemoteConfig('Hello'), 'Validate fails when speed > 4.0');

    Synth.Speed := 1.0;
    Assert(Synth.ValidateRemoteConfig('Hello'), 'Validate succeeds with valid configuration');
    Assert(Synth.ValidateOpenAIConfig('Hello'), 'ValidateOpenAIConfig wrapper succeeds');

    // Test TestConfiguration method
    Assert(Synth.TestConfiguration(Msg), 'TestConfiguration succeeds');
    Assert(Pos('valid', LowerCase(Msg)) > 0, 'TestConfiguration message confirms valid');
  finally
    Synth.Free;
  end;
end;

procedure TestProviderBackends;
var
  Synth: TAIVoiceSynthesizer;
  Backend: IAIVoiceProviderBackend;
  ErrMsg: string;
  Cfg: TAIVoiceConfig;
begin
  WriteLn('--- Testing Provider Backends ---');
  Synth := TAIVoiceSynthesizer.Create(nil);
  try
    Synth.Provider := vpOpenAI;
    Backend := Synth.CreateProviderBackend;
    Assert(Backend <> nil, 'Backend created for vpOpenAI');

    Synth.Provider := vpOpenAICompatible;
    Backend := Synth.CreateProviderBackend;
    Assert(Backend <> nil, 'Backend created for vpOpenAICompatible');

    Synth.Provider := vpCustomHTTP;
    Backend := Synth.CreateProviderBackend;
    Assert(Backend <> nil, 'Backend created for vpCustomHTTP');

    // Test unimplemented providers return clear error
    Synth.Provider := vpGoogle;
    Backend := Synth.CreateProviderBackend;
    Assert(Backend <> nil, 'Stub backend created for vpGoogle');
    FillChar(Cfg, SizeOf(Cfg), 0);
    Assert(not Backend.ValidateConfig(Cfg, 'test', ErrMsg), 'Google backend returns not implemented');
    Assert(Pos('not implemented', LowerCase(ErrMsg)) > 0, 'Google error message is clear');

    Synth.Provider := vpElevenLabs;
    Backend := Synth.CreateProviderBackend;
    Assert(not Backend.ValidateConfig(Cfg, 'test', ErrMsg), 'ElevenLabs backend returns not implemented');
  finally
    Synth.Free;
  end;
end;

procedure TestLifecycleAndState;
var
  Synth: TAIVoiceSynthesizer;
begin
  WriteLn('--- Testing Lifecycle & State ---');
  Synth := TAIVoiceSynthesizer.Create(nil);
  try
    Assert(Synth.State = vsIdle, 'Initial state is vsIdle');
    Synth.Stop;
    Assert(Synth.State = vsIdle, 'State after Stop is vsIdle');
  finally
    Synth.Free;
  end;
end;

begin
  WriteLn('========================================');
  WriteLn('  TAIVoiceSynthesizer & Provider Tests  ');
  WriteLn('========================================');

  TestProviderEnumsAndStrings;
  TestCredentialStore;
  TestBackwardCompatibilityProperties;
  TestValidationRules;
  TestProviderBackends;
  TestLifecycleAndState;

  WriteLn('========================================');
  WriteLn(Format('Tests Completed: %d | Passed: %d | Failed: %d', [TotalTests, PassedTests, TotalTests - PassedTests]));
  WriteLn('========================================');

  if TotalTests = PassedTests then
    Halt(0)
  else
    Halt(1);
end.
