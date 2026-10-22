program test_speaker_signature;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, aispeakersignature;

var
  Gate: TAISpeakerSession;
  Registry: TAISpeakerRegistry;
  Decision: TAISpeakerDecision;
  TmpFile, TmpRegFile, ID, Name: string;
  MaxScore: Double;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then
    raise Exception.Create('Check failed: ' + Msg);
end;

function Sig(X, Y: Double): TAISpeakerSignature;
begin
  SetLength(Result, 2);
  Result[0] := X;
  Result[1] := Y;
end;

begin
  Gate := TAISpeakerSession.Create;
  Registry := TAISpeakerRegistry.Create;
  try
    { 1. Testes de Sessão e Similaridade }
    Check(Gate.Evaluate(Sig(1, 0), Decision), 'first accepted');
    Check(Gate.Active, 'reference locked');
    Check(Gate.Evaluate(Sig(1, 0), Decision) and (Decision = sdSame), 'same speaker detected');
    Check(not Gate.Evaluate(Sig(0, 1), Decision) and (Decision = sdDifferent), 'different speaker rejected');
    Check(Gate.Evaluate(Sig(0.7, 0.7), Decision) and (Decision = sdInconclusive), 'inconclusive accepted');
    Check(Gate.Evaluate(nil, Decision) and (Decision = sdInconclusive), 'missing signature accepted');
    Check(not Gate.Evaluate(Sig(0, 1), Decision), 'reference unchanged');

    { 2. Testes de Persistência em Disco da Sessão }
    TmpFile := GetTempDir + 'test_speaker_ref.json';
    if FileExists(TmpFile) then DeleteFile(TmpFile);

    Check(Gate.SaveToFile(TmpFile, 'spk_01', 'Marcelo'), 'save speaker signature to disk');
    Check(FileExists(TmpFile), 'file exists on disk');

    Gate.Reset;
    Check(not Gate.Active, 'gate active reset');
    Check(Gate.LoadFromFile(TmpFile, ID, Name), 'load speaker signature from disk');
    Check(Gate.Active, 'gate restored from disk');
    Check(ID = 'spk_01', 'speaker ID restored');
    Check(Name = 'Marcelo', 'speaker Name restored');
    Check(Gate.Evaluate(Sig(1, 0), Decision) and (Decision = sdSame), 'restored speaker matches original voice');

    DeleteFile(TmpFile);

    { 3. Testes do Catálogo/Registry de Múltiplos Locutores em Disco }
    TmpRegFile := GetTempDir + 'test_speaker_registry.json';
    if FileExists(TmpRegFile) then DeleteFile(TmpRegFile);

    Check(Registry.AddOrUpdate('user_alice', 'Alice', Sig(1, 0)), 'add Alice');
    Check(Registry.AddOrUpdate('user_bob', 'Bob', Sig(0, 1)), 'add Bob');
    Check(Registry.AddOrUpdate('user_charlie', 'Charlie', Sig(0.7071, 0.7071)), 'add Charlie');
    Check(Registry.Count = 3, 'registry count 3');

    Check(Registry.SaveToFile(TmpRegFile), 'save registry to disk');
    Check(FileExists(TmpRegFile), 'registry file exists');

    Registry.Clear;
    Check(Registry.Count = 0, 'registry cleared');
    Check(Registry.LoadFromFile(TmpRegFile), 'load registry from disk');
    Check(Registry.Count = 3, 'registry loaded count 3');

    { 4. Identificação de Locutor na Base Persistida }
    Check(Registry.IdentifySpeaker(Sig(1, 0), ID, Name, MaxScore, 0.82), 'identify Alice voice');
    Check(ID = 'user_alice', 'Alice correctly identified');
    Check(Name = 'Alice', 'Alice name correct');

    Check(Registry.IdentifySpeaker(Sig(0, 1), ID, Name, MaxScore, 0.82), 'identify Bob voice');
    Check(ID = 'user_bob', 'Bob correctly identified');

    DeleteFile(TmpRegFile);

    WriteLn('PASS: all speaker session and disk persistence tests passed successfully.');
  finally
    Gate.Free;
    Registry.Free;
  end;
end.