program test_speaker_wav_extractor;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, Math, aispeakersignature;

procedure Check(Condition: Boolean; const Msg: string);
begin
  if not Condition then
  begin
    WriteLn('FAIL: ', Msg);
    Halt(1);
  end;
end;

{ Funcao auxiliar para gerar arquivo WAV PCM 16-bit 16kHz com caracteristicas espectrais controladas }
procedure GenerateTestWav(const AFileName: string; ADurationSec: Double; AF0, AF1, AF2, AF3: Double);
var
  FS: TFileStream;
  SampleRate, TotalSamples, I: Integer;
  HeaderRIFF: array[0..3] of AnsiChar;
  HeaderWAVE: array[0..3] of AnsiChar;
  HeaderFMT: array[0..3] of AnsiChar;
  HeaderDATA: array[0..3] of AnsiChar;
  ChunkSize, SubChunkSize, ByteRate, DataBytes: DWord;
  FormatTag, Channels, BlockAlign, BitsPerSample: Word;
  T, Signal, SampleVal: Double;
  S16: SmallInt;
begin
  SampleRate := 16000;
  Channels := 1;
  BitsPerSample := 16;
  TotalSamples := Round(SampleRate * ADurationSec);
  DataBytes := TotalSamples * Channels * (BitsPerSample div 8);
  ByteRate := SampleRate * Channels * (BitsPerSample div 8);
  BlockAlign := Channels * (BitsPerSample div 8);
  FormatTag := 1; { PCM }

  FS := TFileStream.Create(AFileName, fmCreate);
  try
    HeaderRIFF := 'RIFF';
    ChunkSize := 36 + DataBytes;
    HeaderWAVE := 'WAVE';
    FS.WriteBuffer(HeaderRIFF[0], 4);
    FS.WriteBuffer(ChunkSize, 4);
    FS.WriteBuffer(HeaderWAVE[0], 4);

    HeaderFMT := 'fmt ';
    SubChunkSize := 16;
    FS.WriteBuffer(HeaderFMT[0], 4);
    FS.WriteBuffer(SubChunkSize, 4);
    FS.WriteBuffer(FormatTag, 2);
    FS.WriteBuffer(Channels, 2);
    FS.WriteBuffer(SampleRate, 4);
    FS.WriteBuffer(ByteRate, 4);
    FS.WriteBuffer(BlockAlign, 2);
    FS.WriteBuffer(BitsPerSample, 2);

    HeaderDATA := 'data';
    FS.WriteBuffer(HeaderDATA[0], 4);
    FS.WriteBuffer(DataBytes, 4);

    for I := 0 to TotalSamples - 1 do
    begin
      T := I / SampleRate;
      { Modulacao e envelope de fala suave }
      Signal := 0.35 * Sin(2.0 * Pi * AF0 * T) +
                0.30 * Sin(2.0 * Pi * AF1 * T) +
                0.20 * Sin(2.0 * Pi * AF2 * T) +
                0.15 * Sin(2.0 * Pi * AF3 * T);
      { Aplica envelope silabico }
      Signal := Signal * (0.6 + 0.4 * Sin(2.0 * Pi * 3.5 * T));
      SampleVal := Max(-1.0, Min(1.0, Signal));
      S16 := Round(SampleVal * 32000.0);
      FS.WriteBuffer(S16, 2);
    end;
  finally
    FS.Free;
  end;
end;

var
  WavA1, WavA2, WavB1, CatFile: string;
  SigA1, SigA2, SigB1: TAISpeakerSignature;
  Err: string;
  Session: TAISpeakerSession;
  Decision: TAISpeakerDecision;
  ScoreAA, ScoreAB: Double;
  Identifier: TAISpeakerIdentifier;
  IdentifiedID, IdentifiedName: string;
  Confidence: Double;
begin
  WriteLn('Iniciando testes de extracao acustica e biometria vocal a partir de WAV...');

  WavA1 := GetTempDir + 'test_speaker_A1.wav';
  WavA2 := GetTempDir + 'test_speaker_A2.wav';
  WavB1 := GetTempDir + 'test_speaker_B1.wav';
  CatFile := GetTempDir + 'test_catalog_demo.json';

  if FileExists(WavA1) then DeleteFile(WavA1);
  if FileExists(WavA2) then DeleteFile(WavA2);
  if FileExists(WavB1) then DeleteFile(WavB1);
  if FileExists(CatFile) then DeleteFile(CatFile);

  try
    { 1. Sintetizar amostras de voz com formantes acusticos distintos }
    { Locutor A: Tom mais grave F0=130Hz, formantes F1=650Hz, F2=1350Hz, F3=2400Hz }
    GenerateTestWav(WavA1, 1.4, 130.0, 650.0, 1350.0, 2400.0);
    GenerateTestWav(WavA2, 1.1, 135.0, 660.0, 1360.0, 2420.0);

    { Locutor B: Tom mais agudo F0=240Hz, formantes F1=320Hz, F2=2150Hz, F3=3100Hz }
    GenerateTestWav(WavB1, 1.4, 240.0, 320.0, 2150.0, 3100.0);

    Check(FileExists(WavA1), 'WavA1 gerado com sucesso');
    Check(FileExists(WavA2), 'WavA2 gerado com sucesso');
    Check(FileExists(WavB1), 'WavB1 gerado com sucesso');

    { 2. Testar Extracao de Caracteristicas Acusticas (VAD, FFT, Subbandas, Normalizacao) }
    Check(TAISpeakerExtractor.ExtractFromWav(WavA1, SigA1, Err), 'Extracao WavA1: ' + Err);
    Check(Length(SigA1) = 32, 'Vetor SigA1 possui 32 dimensoes');

    Check(TAISpeakerExtractor.ExtractFromWav(WavA2, SigA2, Err), 'Extracao WavA2: ' + Err);
    Check(Length(SigA2) = 32, 'Vetor SigA2 possui 32 dimensoes');

    Check(TAISpeakerExtractor.ExtractFromWav(WavB1, SigB1, Err), 'Extracao WavB1: ' + Err);
    Check(Length(SigB1) = 32, 'Vetor SigB1 possui 32 dimensoes');

    { 3. Teste de Similaridade e Decisao (Mesmo Locutor vs Locutor Diferente) }
    Session := TAISpeakerSession.Create;
    try
      ScoreAA := Session.Similarity(SigA1, SigA2);
      ScoreAB := Session.Similarity(SigA1, SigB1);
      WriteLn(Format('Similaridade Locutor A vs Locutor A (mesma voz): %0.4f', [ScoreAA]));
      WriteLn(Format('Similaridade Locutor A vs Locutor B (vozes distintas): %0.4f', [ScoreAB]));

      Check(ScoreAA >= 0.82, 'Mesmo locutor deve ter alta similaridade (>= 0.82)');
      Check(ScoreAB <= 0.58, 'Locutor diferente deve ter baixa similaridade (<= 0.58)');

      { Sessao avaliando mesma voz }
      Session.SetReference(SigA1);
      Check(Session.Evaluate(SigA2, Decision) and (Decision = sdSame), 'Decisao sdSame para Locutor A');

      { Sessao avaliando voz diferente }
      Check((not Session.Evaluate(SigB1, Decision)) and (Decision = sdDifferent), 'Decisao sdDifferent para Locutor B');
    finally
      Session.Free;
    end;

    { 4. Teste do Componente Lazarus TAISpeakerIdentifier com persistencia em disco }
    Identifier := TAISpeakerIdentifier.Create(nil);
    try
      Identifier.RegistryFile := CatFile;
      Identifier.AutoSave := True;

      { Cadastrar Locutor A }
      Check(Identifier.RegisterSpeakerFromWav('user_marcelo', 'Marcelo Maurin', WavA1), 'Cadastro Locutor A');
      Check(Identifier.Registry.Count = 1, 'Catalogo com 1 locutor');
      Check(FileExists(CatFile), 'Arquivo de catalogo salvo em disco automaticamente');

      { Identificar a partir de uma nova fala do Locutor A (WavA2) }
      Check(Identifier.IdentifyFromWav(WavA2, IdentifiedID, IdentifiedName, Confidence), 'Identificacao de fala nova');
      Check(IdentifiedID = 'user_marcelo', 'ID identificado confere com Marcelo');
      Check(IdentifiedName = 'Marcelo Maurin', 'Nome identificado confere');
      WriteLn(Format('Locutor identificado com sucesso: %s (%s) com confianca %0.2f%%',
        [IdentifiedName, IdentifiedID, Confidence * 100.0]));

      { Verificar que fala de locutor desconhecido (Locutor B) nao e falsamente aceita (FAR = 0%) }
      Check(not Identifier.IdentifyFromWav(WavB1, IdentifiedID, IdentifiedName, Confidence),
        'Locutor B nao cadastrado nao deve ser aceito');
      WriteLn('Rejeicao correta de locutor nao cadastrado (FAR = 0%)');
    finally
      Identifier.Free;
    end;

    WriteLn('PASS: Todos os testes de extracao WAV, biometria vocal e catalogo passaram 100%!');
  finally
    if FileExists(WavA1) then DeleteFile(WavA1);
    if FileExists(WavA2) then DeleteFile(WavA2);
    if FileExists(WavB1) then DeleteFile(WavB1);
    if FileExists(CatFile) then DeleteFile(CatFile);
  end;
end.