unit aispeakersignature;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpjson, jsonparser;

type
  TAISpeakerDecision = (sdSame, sdDifferent, sdInconclusive);
  TAISpeakerSignature = array of Double;

  { Profile persistido de um locutor cadastrado no sistema }
  TAISpeakerProfile = record
    SpeakerID   : string;
    SpeakerName : string;
    CreatedAt   : string;
    Signature   : TAISpeakerSignature;
  end;
  TAISpeakerProfiles = array of TAISpeakerProfile;

  { Sessao de comparacao de locutor em tempo de execucao }
  TAISpeakerSession = class
  private
    FReference: TAISpeakerSignature;
    FActive: Boolean;
    FSameThreshold: Double;
    FDifferentThreshold: Double;
  public
    constructor Create;
    procedure Reset;
    function Similarity(const A, B: TAISpeakerSignature): Double;
    function Evaluate(const ASignature: TAISpeakerSignature;
      out ADecision: TAISpeakerDecision): Boolean;

    { Metodos para persistencia e recuperacao de assinaturas vocais em disco }
    function SaveToFile(const AFileName: string; const ASpeakerID, ASpeakerName: string): Boolean;
    function LoadFromFile(const AFileName: string; out ASpeakerID, ASpeakerName: string): Boolean;

    { Serializacao em JSON para integracao com APIs / SQLite }
    function ToJSON(const ASpeakerID, ASpeakerName: string): string;
    function FromJSON(const AJSONStr: string; out ASpeakerID, ASpeakerName: string): Boolean;

    { Carregamento direto de uma assinatura como referencia }
    procedure SetReference(const ASignature: TAISpeakerSignature);
    function GetReference: TAISpeakerSignature;

    property Active: Boolean read FActive;
    property SameThreshold: Double read FSameThreshold write FSameThreshold;
    property DifferentThreshold: Double read FDifferentThreshold write FDifferentThreshold;
  end;

  { Gerenciador de catalogo de assinaturas de multiplos locutores em disco }
  TAISpeakerRegistry = class
  private
    FProfiles: TAISpeakerProfiles;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddOrUpdate(const ASpeakerID, ASpeakerName: string; const ASig: TAISpeakerSignature): Boolean;
    function Remove(const ASpeakerID: string): Boolean;
    function Find(const ASpeakerID: string; out AProfile: TAISpeakerProfile): Boolean;
    
    { Identifica o locutor mais provavel em uma base persistida }
    function IdentifySpeaker(const ASig: TAISpeakerSignature; out AIdentifiedID, AIdentifiedName: string;
      out AMaxScore: Double; AThreshold: Double = 0.82): Boolean;

    { Persistencia de todo o catalogo em arquivo JSON }
    function SaveToFile(const AFileName: string): Boolean;
    function LoadFromFile(const AFileName: string): Boolean;

    function GetCount: Integer;
    property Count: Integer read GetCount;
    property Profiles: TAISpeakerProfiles read FProfiles;
  end;

  { Extrator de caracteristicas acusticas a partir de audio WAV PCM / microfone }
  TAISpeakerExtractor = class
  private
    class procedure RealFFT512(var Re, Im: array of Double);
  public
    { Extrai assinatura espectral de 32 dimensoes a partir de arquivo WAV PCM }
    class function ExtractFromWav(const AWavFileName: string; out ASig: TAISpeakerSignature; out AError: string): Boolean;
    { Extrai assinatura espectral a partir de stream de memoria contendo WAV }
    class function ExtractFromStream(AStream: TStream; out ASig: TAISpeakerSignature; out AError: string): Boolean;
    { Extrai assinatura espectral a partir de amostras PCM normalizadas [-1.0 .. +1.0] }
    class function ExtractFromPCM(const ASamples: array of Double; ASampleRate: Integer;
      out ASig: TAISpeakerSignature; out AError: string): Boolean;
  end;

  { Eventos do componente visual de identificacao vocal }
  TAISpeakerIdentifiedEvent = procedure(Sender: TObject; const ASpeakerID, ASpeakerName: string;
    AConfidence: Double) of object;
  TAISpeakerRejectedEvent = procedure(Sender: TObject; const AWavFile: string;
    AConfidence: Double) of object;

  { Componente Lazarus de alto nivel para identificacao vocal e persistencia }
  TAISpeakerIdentifier = class(TComponent)
  private
    FRegistry: TAISpeakerRegistry;
    FSession: TAISpeakerSession;
    FRegistryFile: string;
    FAutoSave: Boolean;
    FSameThreshold: Double;
    FDifferentThreshold: Double;
    FLastError: string;
    FOnIdentified: TAISpeakerIdentifiedEvent;
    FOnRejected: TAISpeakerRejectedEvent;
    procedure SetRegistryFile(const AValue: string);
    procedure SetSameThreshold(AValue: Double);
    procedure SetDifferentThreshold(AValue: Double);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Operacoes de reconhecimento e cadastro }
    function ExtractSignature(const AWavFileName: string; out ASig: TAISpeakerSignature): Boolean;
    function RegisterSpeakerFromWav(const ASpeakerID, ASpeakerName, AWavFileName: string): Boolean;
    function IdentifyFromWav(const AWavFileName: string; out ASpeakerID, ASpeakerName: string;
      out AConfidence: Double): Boolean;
    function VerifyFromWav(const AWavFileName, ASpeakerID: string; out ADecision: TAISpeakerDecision;
      out AConfidence: Double): Boolean;

    function SaveRegistry: Boolean;
    function LoadRegistry: Boolean;

    property Registry: TAISpeakerRegistry read FRegistry;
    property Session: TAISpeakerSession read FSession;
    property LastError: string read FLastError;
  published
    property RegistryFile: string read FRegistryFile write SetRegistryFile;
    property AutoSave: Boolean read FAutoSave write FAutoSave default True;
    property SameThreshold: Double read FSameThreshold write SetSameThreshold;
    property DifferentThreshold: Double read FDifferentThreshold write SetDifferentThreshold;
    property OnSpeakerIdentified: TAISpeakerIdentifiedEvent read FOnIdentified write FOnIdentified;
    property OnSpeakerRejected: TAISpeakerRejectedEvent read FOnRejected write FOnRejected;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAISpeakerIdentifier]);
end;

{ TAISpeakerSession }

constructor TAISpeakerSession.Create;
begin
  inherited Create;
  FSameThreshold := 0.82;
  FDifferentThreshold := 0.58;
end;

procedure TAISpeakerSession.Reset;
begin
  FActive := False;
  SetLength(FReference, 0);
end;

procedure TAISpeakerSession.SetReference(const ASignature: TAISpeakerSignature);
begin
  FReference := Copy(ASignature, 0, Length(ASignature));
  FActive := Length(FReference) > 0;
end;

function TAISpeakerSession.GetReference: TAISpeakerSignature;
begin
  Result := Copy(FReference, 0, Length(FReference));
end;

function TAISpeakerSession.Similarity(const A, B: TAISpeakerSignature): Double;
var
  I: Integer;
  Dot, NormA, NormB: Double;
begin
  if (Length(A) = 0) or (Length(A) <> Length(B)) then
    Exit(Double.NaN);

  Dot := 0.0;
  NormA := 0.0;
  NormB := 0.0;
  for I := 0 to High(A) do
  begin
    Dot := Dot + (A[I] * B[I]);
    NormA := NormA + Sqr(A[I]);
    NormB := NormB + Sqr(B[I]);
  end;

  if (NormA <= 0.0) or (NormB <= 0.0) then
    Exit(Double.NaN);

  Result := Dot / (Sqrt(NormA) * Sqrt(NormB));
end;

function TAISpeakerSession.Evaluate(const ASignature: TAISpeakerSignature;
  out ADecision: TAISpeakerDecision): Boolean;
var
  Score: Double;
begin
  ADecision := sdInconclusive;
  if not FActive then
  begin
    if Length(ASignature) = 0 then
      Exit(True);
    FReference := Copy(ASignature, 0, Length(ASignature));
    FActive := True;
    ADecision := sdSame;
    Exit(True);
  end;

  if Length(ASignature) = 0 then
    Exit(True);

  Score := Similarity(FReference, ASignature);
  if not IsNan(Score) then
  begin
    if Score >= FSameThreshold then ADecision := sdSame
    else if Score <= FDifferentThreshold then ADecision := sdDifferent;
  end;
  Result := ADecision <> sdDifferent;
end;

function TAISpeakerSession.ToJSON(const ASpeakerID, ASpeakerName: string): string;
var
  Root: TJSONObject;
  SigArr: TJSONArray;
  I: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('speaker_id', ASpeakerID);
    Root.Add('speaker_name', ASpeakerName);
    Root.Add('created_at', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now));
    Root.Add('dimension', Length(FReference));
    SigArr := TJSONArray.Create;
    for I := 0 to High(FReference) do
      SigArr.Add(FReference[I]);
    Root.Add('signature', SigArr);
    Result := Root.AsJSON;
  finally
    Root.Free;
  end;
end;

function TAISpeakerSession.FromJSON(const AJSONStr: string; out ASpeakerID, ASpeakerName: string): Boolean;
var
  Data: TJSONData;
  Root: TJSONObject;
  SigArr: TJSONArray;
  I: Integer;
begin
  Result := False;
  ASpeakerID := '';
  ASpeakerName := '';
  if Trim(AJSONStr) = '' then Exit;
  try
    Data := GetJSON(AJSONStr);
    try
      if not (Data is TJSONObject) then Exit;
      Root := TJSONObject(Data);
      ASpeakerID := Root.Get('speaker_id', '');
      ASpeakerName := Root.Get('speaker_name', '');
      SigArr := Root.Get('signature', TJSONArray(nil));
      if Assigned(SigArr) and (SigArr.Count > 0) then
      begin
        SetLength(FReference, SigArr.Count);
        for I := 0 to SigArr.Count - 1 do
          FReference[I] := SigArr.Floats[I];
        FActive := True;
        Result := True;
      end;
    finally
      Data.Free;
    end;
  except
    Result := False;
  end;
end;

function TAISpeakerSession.SaveToFile(const AFileName: string; const ASpeakerID, ASpeakerName: string): Boolean;
var
  S: TStringList;
begin
  Result := False;
  if not FActive or (Length(FReference) = 0) then Exit;
  S := TStringList.Create;
  try
    S.Text := ToJSON(ASpeakerID, ASpeakerName);
    try
      ForceDirectories(ExtractFileDir(AFileName));
      S.SaveToFile(AFileName);
      Result := True;
    except
      Result := False;
    end;
  finally
    S.Free;
  end;
end;

function TAISpeakerSession.LoadFromFile(const AFileName: string; out ASpeakerID, ASpeakerName: string): Boolean;
var
  S: TStringList;
begin
  Result := False;
  ASpeakerID := '';
  ASpeakerName := '';
  if not FileExists(AFileName) then Exit;
  S := TStringList.Create;
  try
    S.LoadFromFile(AFileName);
    Result := FromJSON(S.Text, ASpeakerID, ASpeakerName);
  finally
    S.Free;
  end;
end;

{ TAISpeakerRegistry }

function TAISpeakerRegistry.GetCount: Integer;
begin
  Result := Length(FProfiles);
end;

constructor TAISpeakerRegistry.Create;
begin
  inherited Create;
  SetLength(FProfiles, 0);
end;

destructor TAISpeakerRegistry.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAISpeakerRegistry.Clear;
begin
  SetLength(FProfiles, 0);
end;

function TAISpeakerRegistry.AddOrUpdate(const ASpeakerID, ASpeakerName: string; const ASig: TAISpeakerSignature): Boolean;
var
  I, N: Integer;
begin
  Result := False;
  if (ASpeakerID = '') or (Length(ASig) = 0) then Exit;
  for I := 0 to High(FProfiles) do
  begin
    if SameText(FProfiles[I].SpeakerID, ASpeakerID) then
    begin
      FProfiles[I].SpeakerName := ASpeakerName;
      FProfiles[I].Signature := Copy(ASig, 0, Length(ASig));
      FProfiles[I].CreatedAt := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now);
      Exit(True);
    end;
  end;
  N := Length(FProfiles);
  SetLength(FProfiles, N + 1);
  FProfiles[N].SpeakerID := ASpeakerID;
  FProfiles[N].SpeakerName := ASpeakerName;
  FProfiles[N].CreatedAt := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now);
  FProfiles[N].Signature := Copy(ASig, 0, Length(ASig));
  Result := True;
end;

function TAISpeakerRegistry.Remove(const ASpeakerID: string): Boolean;
var
  I, J: Integer;
begin
  Result := False;
  for I := 0 to High(FProfiles) do
  begin
    if SameText(FProfiles[I].SpeakerID, ASpeakerID) then
    begin
      for J := I to High(FProfiles) - 1 do
        FProfiles[J] := FProfiles[J + 1];
      SetLength(FProfiles, Length(FProfiles) - 1);
      Exit(True);
    end;
  end;
end;

function TAISpeakerRegistry.Find(const ASpeakerID: string; out AProfile: TAISpeakerProfile): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FProfiles) do
  begin
    if SameText(FProfiles[I].SpeakerID, ASpeakerID) then
    begin
      AProfile := FProfiles[I];
      Exit(True);
    end;
  end;
end;

function TAISpeakerRegistry.IdentifySpeaker(const ASig: TAISpeakerSignature;
  out AIdentifiedID, AIdentifiedName: string; out AMaxScore: Double; AThreshold: Double): Boolean;
var
  I, BestIdx: Integer;
  Session: TAISpeakerSession;
  Score: Double;
begin
  Result := False;
  AIdentifiedID := '';
  AIdentifiedName := '';
  AMaxScore := -1.0;
  BestIdx := -1;
  if (Length(FProfiles) = 0) or (Length(ASig) = 0) then Exit;

  Session := TAISpeakerSession.Create;
  try
    for I := 0 to High(FProfiles) do
    begin
      Session.SetReference(FProfiles[I].Signature);
      Score := Session.Similarity(Session.GetReference, ASig);
      if (not IsNan(Score)) and (Score > AMaxScore) then
      begin
        AMaxScore := Score;
        BestIdx := I;
      end;
    end;
  finally
    Session.Free;
  end;

  if (BestIdx >= 0) and (AMaxScore >= AThreshold) then
  begin
    AIdentifiedID := FProfiles[BestIdx].SpeakerID;
    AIdentifiedName := FProfiles[BestIdx].SpeakerName;
    Result := True;
  end;
end;

function TAISpeakerRegistry.SaveToFile(const AFileName: string): Boolean;
var
  Root, Item: TJSONObject;
  List: TJSONArray;
  SigArr: TJSONArray;
  I, J: Integer;
  S: TStringList;
begin
  Result := False;
  Root := TJSONObject.Create;
  S := TStringList.Create;
  try
    List := TJSONArray.Create;
    for I := 0 to High(FProfiles) do
    begin
      Item := TJSONObject.Create;
      Item.Add('speaker_id', FProfiles[I].SpeakerID);
      Item.Add('speaker_name', FProfiles[I].SpeakerName);
      Item.Add('created_at', FProfiles[I].CreatedAt);
      SigArr := TJSONArray.Create;
      for J := 0 to High(FProfiles[I].Signature) do
        SigArr.Add(FProfiles[I].Signature[J]);
      Item.Add('signature', SigArr);
      List.Add(Item);
    end;
    Root.Add('profiles', List);
    S.Text := Root.AsJSON;
    ForceDirectories(ExtractFileDir(AFileName));
    S.SaveToFile(AFileName);
    Result := True;
  finally
    S.Free;
    Root.Free;
  end;
end;

function TAISpeakerRegistry.LoadFromFile(const AFileName: string): Boolean;
var
  S: TStringList;
  Data: TJSONData;
  Root, Item: TJSONObject;
  List, SigArr: TJSONArray;
  I, J: Integer;
begin
  Result := False;
  Clear;
  if not FileExists(AFileName) then Exit;
  S := TStringList.Create;
  try
    S.LoadFromFile(AFileName);
    Data := GetJSON(S.Text);
    try
      if not (Data is TJSONObject) then Exit;
      Root := TJSONObject(Data);
      List := Root.Get('profiles', TJSONArray(nil));
      if not Assigned(List) then Exit;
      SetLength(FProfiles, List.Count);
      for I := 0 to List.Count - 1 do
      begin
        Item := List.Objects[I];
        FProfiles[I].SpeakerID := Item.Get('speaker_id', '');
        FProfiles[I].SpeakerName := Item.Get('speaker_name', '');
        FProfiles[I].CreatedAt := Item.Get('created_at', '');
        SigArr := Item.Get('signature', TJSONArray(nil));
        if Assigned(SigArr) then
        begin
          SetLength(FProfiles[I].Signature, SigArr.Count);
          for J := 0 to SigArr.Count - 1 do
            FProfiles[I].Signature[J] := SigArr.Floats[J];
        end;
      end;
      Result := True;
    finally
      Data.Free;
    end;
  finally
    S.Free;
  end;
end;

{ TAISpeakerExtractor }

class procedure TAISpeakerExtractor.RealFFT512(var Re, Im: array of Double);
var
  N, J, I, M, MMax, IStep: Integer;
  Theta, WPr, WPi, Wr, Wi, WTemp: Double;
  TempRe, TempIm: Double;
begin
  N := 512;
  J := 0;
  for I := 0 to N - 2 do
  begin
    if I < J then
    begin
      TempRe := Re[J]; Re[J] := Re[I]; Re[I] := TempRe;
      TempIm := Im[J]; Im[J] := Im[I]; Im[I] := TempIm;
    end;
    M := N shr 1;
    while (M >= 1) and (J >= M) do
    begin
      Dec(J, M);
      M := M shr 1;
    end;
    Inc(J, M);
  end;

  MMax := 1;
  while N > MMax do
  begin
    IStep := MMax shl 1;
    Theta := -2.0 * Pi / IStep;
    WPr := -2.0 * Sqr(Sin(0.5 * Theta));
    WPi := Sin(Theta);
    Wr := 1.0;
    Wi := 0.0;
    for M := 0 to MMax - 1 do
    begin
      I := M;
      while I < N do
      begin
        J := I + MMax;
        TempRe := Wr * Re[J] - Wi * Im[J];
        TempIm := Wr * Im[J] + Wi * Re[J];
        Re[J] := Re[I] - TempRe;
        Im[J] := Im[I] - TempIm;
        Re[I] := Re[I] + TempRe;
        Im[I] := Im[I] + TempIm;
        Inc(I, IStep);
      end;
      WTemp := Wr;
      Wr := Wr * WPr - Wi * WPi + Wr;
      Wi := Wi * WPr + WTemp * WPi + Wi;
    end;
    MMax := IStep;
  end;
end;

class function TAISpeakerExtractor.ExtractFromStream(AStream: TStream; out ASig: TAISpeakerSignature; out AError: string): Boolean;
var
  Header: array[0..3] of AnsiChar;
  FormatTag, Channels, BitsPerSample, BlockAlign: Word;
  SampleRate, ByteRate, ChunkSize, SubChunkSize: DWord;
  PosData: Int64;
  DataBytes: Integer;
  Samples: array of Double;
  I, TotalSamples: Integer;
  S8: ShortInt;
  S16: SmallInt;
  MonoVal, LeftVal, RightVal: Double;
begin
  Result := False;
  AError := '';
  SetLength(ASig, 0);

  if AStream.Size < 44 then
  begin
    AError := 'Stream menor que tamanho minimo de cabecalho WAV (44 bytes)';
    Exit;
  end;

  AStream.Position := 0;
  AStream.ReadBuffer(Header[0], 4);
  if Header <> 'RIFF' then
  begin
    AError := 'Identificador RIFF nao encontrado';
    Exit;
  end;

  AStream.ReadBuffer(ChunkSize, 4);
  AStream.ReadBuffer(Header[0], 4);
  if Header <> 'WAVE' then
  begin
    AError := 'Formato WAVE nao encontrado no container RIFF';
    Exit;
  end;

  FormatTag := 0; Channels := 1; SampleRate := 16000; BitsPerSample := 16;
  PosData := -1;
  DataBytes := 0;

  { Leitura de subchunks fmt e data }
  while AStream.Position < AStream.Size - 8 do
  begin
    AStream.ReadBuffer(Header[0], 4);
    AStream.ReadBuffer(SubChunkSize, 4);

    if Header = 'fmt ' then
    begin
      AStream.ReadBuffer(FormatTag, 2);
      AStream.ReadBuffer(Channels, 2);
      AStream.ReadBuffer(SampleRate, 4);
      AStream.ReadBuffer(ByteRate, 4);
      AStream.ReadBuffer(BlockAlign, 2);
      AStream.ReadBuffer(BitsPerSample, 2);
      if SubChunkSize > 16 then
        AStream.Seek(SubChunkSize - 16, soCurrent);
    end
    else if Header = 'data' then
    begin
      PosData := AStream.Position;
      DataBytes := SubChunkSize;
      Break;
    end
    else
    begin
      AStream.Seek(SubChunkSize, soCurrent);
    end;
  end;

  if (PosData < 0) or (DataBytes <= 0) then
  begin
    AError := 'Chunk "data" nao encontrado ou vazio no arquivo WAV';
    Exit;
  end;

  if (FormatTag <> 1) and (FormatTag <> 3) then
  begin
    AError := 'Formato WAV nao suportado (apenas PCM linear tag 1 ou IEEE Float tag 3)';
    Exit;
  end;

  AStream.Position := PosData;
  if Channels <= 0 then Channels := 1;

  if BitsPerSample = 16 then
  begin
    TotalSamples := DataBytes div (Channels * 2);
    SetLength(Samples, TotalSamples);
    for I := 0 to TotalSamples - 1 do
    begin
      AStream.ReadBuffer(S16, 2);
      LeftVal := S16 / 32768.0;
      if Channels > 1 then
      begin
        AStream.ReadBuffer(S16, 2);
        RightVal := S16 / 32768.0;
        MonoVal := (LeftVal + RightVal) * 0.5;
        if Channels > 2 then
          AStream.Seek((Channels - 2) * 2, soCurrent);
      end
      else
        MonoVal := LeftVal;
      Samples[I] := MonoVal;
    end;
  end
  else if BitsPerSample = 8 then
  begin
    TotalSamples := DataBytes div Channels;
    SetLength(Samples, TotalSamples);
    for I := 0 to TotalSamples - 1 do
    begin
      AStream.ReadBuffer(S8, 1);
      LeftVal := (Byte(S8) - 128) / 128.0;
      if Channels > 1 then
      begin
        AStream.ReadBuffer(S8, 1);
        RightVal := (Byte(S8) - 128) / 128.0;
        MonoVal := (LeftVal + RightVal) * 0.5;
        if Channels > 2 then
          AStream.Seek(Channels - 2, soCurrent);
      end
      else
        MonoVal := LeftVal;
      Samples[I] := MonoVal;
    end;
  end
  else
  begin
    AError := 'Suporte a PCM de ' + IntToStr(BitsPerSample) + ' bits ainda nao implementado (use 16 ou 8 bits)';
    Exit;
  end;

  Result := ExtractFromPCM(Samples, SampleRate, ASig, AError);
end;

class function TAISpeakerExtractor.ExtractFromWav(const AWavFileName: string; out ASig: TAISpeakerSignature; out AError: string): Boolean;
var
  FS: TFileStream;
begin
  Result := False;
  AError := '';
  if not FileExists(AWavFileName) then
  begin
    AError := 'Arquivo WAV nao encontrado: ' + AWavFileName;
    Exit;
  end;

  try
    FS := TFileStream.Create(AWavFileName, fmOpenRead or fmShareDenyNone);
    try
      Result := ExtractFromStream(FS, ASig, AError);
    finally
      FS.Free;
    end;
  except
    on E: Exception do
      AError := 'Erro ao abrir WAV: ' + E.Message;
  end;
end;

class function TAISpeakerExtractor.ExtractFromPCM(const ASamples: array of Double; ASampleRate: Integer;
  out ASig: TAISpeakerSignature; out AError: string): Boolean;
const
  N_FFT = 512;
  HOP = 256;
  BANDS = 16;
var
  NumSamples, TotalFrames, FrameIdx, I, K, VoicedCount: Integer;
  FrameRe, FrameIm: array[0..N_FFT - 1] of Double;
  Mag: array[0..N_FFT div 2] of Double;
  Hamming: array[0..N_FFT - 1] of Double;
  EnergySum, EnergySqSum, ZCRSum, ZCRSqSum: Double;
  CentroidSum, SpreadSum, RollOffSum, TiltSum: Double;
  BandEnergySum: array[0..BANDS - 1] of Double;
  FormantProxies: array[0..7] of Double;
  RMS, FrameEnergy, ZCR, SumMag, Centroid, Spread, RollOff, Freq, CumMag: Double;
  MinRMSThreshold, MaxRMS, Norm: Double;
  FreqBoundaries: array[0..BANDS] of Double;
  LowEnergy, HighEnergy: Double;
begin
  Result := False;
  AError := '';
  SetLength(ASig, 32);
  for I := 0 to 31 do ASig[I] := 0.0;

  NumSamples := Length(ASamples);
  if NumSamples < N_FFT then
  begin
    AError := 'Amostras de audio insuficientes para extracao (minimo 512 amostras)';
    Exit;
  end;

  if ASampleRate <= 0 then ASampleRate := 16000;

  { Pre-calculo da Janela Hamming }
  for I := 0 to N_FFT - 1 do
    Hamming[I] := 0.54 - 0.46 * Cos(2.0 * Pi * I / (N_FFT - 1));

  { Faixas de frequencia para 16 sub-bandas de locutor (80 Hz a 7500 Hz) }
  FreqBoundaries[0]  := 80.0;
  FreqBoundaries[1]  := 180.0;
  FreqBoundaries[2]  := 300.0;
  FreqBoundaries[3]  := 450.0;
  FreqBoundaries[4]  := 650.0;
  FreqBoundaries[5]  := 900.0;
  FreqBoundaries[6]  := 1200.0;
  FreqBoundaries[7]  := 1600.0;
  FreqBoundaries[8]  := 2100.0;
  FreqBoundaries[9]  := 2700.0;
  FreqBoundaries[10] := 3400.0;
  FreqBoundaries[11] := 4200.0;
  FreqBoundaries[12] := 5100.0;
  FreqBoundaries[13] := 6100.0;
  FreqBoundaries[14] := 7200.0;
  FreqBoundaries[15] := 8500.0;
  FreqBoundaries[16] := Min(ASampleRate * 0.5, 10000.0);

  for I := 0 to BANDS - 1 do
    BandEnergySum[I] := 0.0;
  for I := 0 to 7 do
    FormantProxies[I] := 0.0;

  EnergySum := 0.0; EnergySqSum := 0.0; ZCRSum := 0.0; ZCRSqSum := 0.0;
  CentroidSum := 0.0; SpreadSum := 0.0; RollOffSum := 0.0; TiltSum := 0.0;

  { Determinacao de nivel maximo para calibracao de silencio/VAD }
  MaxRMS := 0.0;
  TotalFrames := (NumSamples - N_FFT) div HOP;
  if TotalFrames <= 0 then TotalFrames := 1;

  for FrameIdx := 0 to TotalFrames - 1 do
  begin
    RMS := 0.0;
    for I := 0 to N_FFT - 1 do
      RMS := RMS + Sqr(ASamples[FrameIdx * HOP + I]);
    RMS := Sqrt(RMS / N_FFT);
    if RMS > MaxRMS then MaxRMS := RMS;
  end;

  MinRMSThreshold := Max(0.005, MaxRMS * 0.12);
  VoicedCount := 0;

  { Processamento dos quadros de fala com VAD ativo }
  for FrameIdx := 0 to TotalFrames - 1 do
  begin
    { Verificacao de RMS e ZCR do quadro }
    FrameEnergy := 0.0;
    ZCR := 0.0;
    for I := 0 to N_FFT - 1 do
      FrameEnergy := FrameEnergy + Sqr(ASamples[FrameIdx * HOP + I]);
    RMS := Sqrt(FrameEnergy / N_FFT);

    { Ignora quadros de silencio / ruido residual }
    if RMS < MinRMSThreshold then
      Continue;

    for I := 1 to N_FFT - 1 do
      if (ASamples[FrameIdx * HOP + I] >= 0.0) <> (ASamples[FrameIdx * HOP + I - 1] >= 0.0) then
        ZCR := ZCR + 1.0;
    ZCR := ZCR / (N_FFT - 1);

    Inc(VoicedCount);
    EnergySum := EnergySum + RMS;
    EnergySqSum := EnergySqSum + Sqr(RMS);
    ZCRSum := ZCRSum + ZCR;
    ZCRSqSum := ZCRSqSum + Sqr(ZCR);

    { Aplicacao de janela e calculo FFT }
    for I := 0 to N_FFT - 1 do
    begin
      FrameRe[I] := ASamples[FrameIdx * HOP + I] * Hamming[I];
      FrameIm[I] := 0.0;
    end;

    RealFFT512(FrameRe, FrameIm);

    SumMag := 0.0;
    for K := 0 to N_FFT div 2 do
    begin
      Mag[K] := Sqrt(Sqr(FrameRe[K]) + Sqr(FrameIm[K]));
      SumMag := SumMag + Mag[K];
    end;

    if SumMag <= 1e-9 then Continue;

    { Spectral Centroid }
    Centroid := 0.0;
    for K := 0 to N_FFT div 2 do
    begin
      Freq := K * ASampleRate / N_FFT;
      Centroid := Centroid + (Freq * Mag[K]);
    end;
    Centroid := Centroid / SumMag;
    CentroidSum := CentroidSum + Centroid;

    { Spectral Spread }
    Spread := 0.0;
    for K := 0 to N_FFT div 2 do
    begin
      Freq := K * ASampleRate / N_FFT;
      Spread := Spread + (Sqr(Freq - Centroid) * Mag[K]);
    end;
    Spread := Sqrt(Spread / SumMag);
    SpreadSum := SpreadSum + Spread;

    { Spectral Roll-Off 85% }
    CumMag := 0.0;
    RollOff := 0.0;
    for K := 0 to N_FFT div 2 do
    begin
      CumMag := CumMag + Mag[K];
      if CumMag >= (SumMag * 0.85) then
      begin
        RollOff := K * ASampleRate / N_FFT;
        Break;
      end;
    end;
    RollOffSum := RollOffSum + RollOff;

    { 16 Sub-band Energies }
    LowEnergy := 0.0; HighEnergy := 0.0;
    for I := 0 to BANDS - 1 do
    begin
      for K := 0 to N_FFT div 2 do
      begin
        Freq := K * ASampleRate / N_FFT;
        if (Freq >= FreqBoundaries[I]) and (Freq < FreqBoundaries[I + 1]) then
        begin
          BandEnergySum[I] := BandEnergySum[I] + Sqr(Mag[K]);
          if Freq < 1500.0 then
            LowEnergy := LowEnergy + Sqr(Mag[K])
          else
            HighEnergy := HighEnergy + Sqr(Mag[K]);
        end;
      end;
    end;

    if LowEnergy > 1e-6 then
      TiltSum := TiltSum + (HighEnergy / LowEnergy);

    { Formant proxies (picos nas faixas F1, F2, F3) }
    FormantProxies[0] := FormantProxies[0] + BandEnergySum[2] / (SumMag + 1e-6);
    FormantProxies[1] := FormantProxies[1] + BandEnergySum[4] / (SumMag + 1e-6);
    FormantProxies[2] := FormantProxies[2] + BandEnergySum[6] / (SumMag + 1e-6);
    FormantProxies[3] := FormantProxies[3] + BandEnergySum[8] / (SumMag + 1e-6);
  end;

  if VoicedCount < 2 then
  begin
    AError := 'Sinal de voz insuficiente ou nivel sonoro muito baixo (sem locucao valida)';
    Exit;
  end;

  { Compilacao do vetor de 32 dimensoes }
  ASig[0] := EnergySum / VoicedCount;
  ASig[1] := Sqrt(Max(0.0, (EnergySqSum / VoicedCount) - Sqr(ASig[0])));
  ASig[2] := ZCRSum / VoicedCount;
  ASig[3] := Sqrt(Max(0.0, (ZCRSqSum / VoicedCount) - Sqr(ASig[2])));
  ASig[4] := (CentroidSum / VoicedCount) / (ASampleRate * 0.5);
  ASig[5] := (SpreadSum / VoicedCount) / (ASampleRate * 0.5);
  ASig[6] := (RollOffSum / VoicedCount) / (ASampleRate * 0.5);
  ASig[7] := Min(5.0, TiltSum / VoicedCount);

  { Sub-bandas 8..23 }
  for I := 0 to BANDS - 1 do
    ASig[8 + I] := BandEnergySum[I] / VoicedCount;

  { Formant proxies 24..31 }
  for I := 0 to 7 do
    ASig[24 + I] := FormantProxies[I] / VoicedCount;

  { Normalizacao L2 do vetor de caracteristicas }
  Norm := 0.0;
  for I := 0 to 31 do
    Norm := Norm + Sqr(ASig[I]);
  Norm := Sqrt(Norm);

  if Norm > 1e-9 then
  begin
    for I := 0 to 31 do
      ASig[I] := ASig[I] / Norm;
    Result := True;
  end
  else
  begin
    AError := 'Falha na normalizacao da assinatura vocal (norma nula)';
  end;
end;

{ TAISpeakerIdentifier }

constructor TAISpeakerIdentifier.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRegistry := TAISpeakerRegistry.Create;
  FSession := TAISpeakerSession.Create;
  FRegistryFile := '';
  FAutoSave := True;
  FSameThreshold := 0.82;
  FDifferentThreshold := 0.58;
  FLastError := '';
end;

destructor TAISpeakerIdentifier.Destroy;
begin
  if FAutoSave and (FRegistryFile <> '') then
    SaveRegistry;
  FSession.Free;
  FRegistry.Free;
  inherited Destroy;
end;

procedure TAISpeakerIdentifier.SetRegistryFile(const AValue: string);
begin
  if FRegistryFile = AValue then Exit;
  FRegistryFile := AValue;
  if FileExists(FRegistryFile) then
    LoadRegistry;
end;

procedure TAISpeakerIdentifier.SetSameThreshold(AValue: Double);
begin
  FSameThreshold := AValue;
  FSession.SameThreshold := AValue;
end;

procedure TAISpeakerIdentifier.SetDifferentThreshold(AValue: Double);
begin
  FDifferentThreshold := AValue;
  FSession.DifferentThreshold := AValue;
end;

function TAISpeakerIdentifier.SaveRegistry: Boolean;
begin
  Result := False;
  if FRegistryFile = '' then
  begin
    FLastError := 'Arquivo de catalogo (RegistryFile) nao configurado';
    Exit;
  end;
  Result := FRegistry.SaveToFile(FRegistryFile);
  if not Result then
    FLastError := 'Falha ao salvar catalogo em ' + FRegistryFile;
end;

function TAISpeakerIdentifier.LoadRegistry: Boolean;
begin
  Result := False;
  if (FRegistryFile = '') or (not FileExists(FRegistryFile)) then
  begin
    FLastError := 'Arquivo de catalogo nao encontrado: ' + FRegistryFile;
    Exit;
  end;
  Result := FRegistry.LoadFromFile(FRegistryFile);
  if not Result then
    FLastError := 'Falha ao carregar catalogo de ' + FRegistryFile;
end;

function TAISpeakerIdentifier.ExtractSignature(const AWavFileName: string; out ASig: TAISpeakerSignature): Boolean;
begin
  Result := TAISpeakerExtractor.ExtractFromWav(AWavFileName, ASig, FLastError);
end;

function TAISpeakerIdentifier.RegisterSpeakerFromWav(const ASpeakerID, ASpeakerName, AWavFileName: string): Boolean;
var
  Sig: TAISpeakerSignature;
begin
  Result := False;
  if not ExtractSignature(AWavFileName, Sig) then Exit;
  Result := FRegistry.AddOrUpdate(ASpeakerID, ASpeakerName, Sig);
  if Result and FAutoSave and (FRegistryFile <> '') then
    SaveRegistry;
end;

function TAISpeakerIdentifier.IdentifyFromWav(const AWavFileName: string; out ASpeakerID, ASpeakerName: string;
  out AConfidence: Double): Boolean;
var
  Sig: TAISpeakerSignature;
begin
  Result := False;
  ASpeakerID := '';
  ASpeakerName := '';
  AConfidence := 0.0;
  if not ExtractSignature(AWavFileName, Sig) then Exit;

  Result := FRegistry.IdentifySpeaker(Sig, ASpeakerID, ASpeakerName, AConfidence, FSameThreshold);
  if Result then
  begin
    if Assigned(FOnIdentified) then
      FOnIdentified(Self, ASpeakerID, ASpeakerName, AConfidence);
  end
  else
  begin
    if Assigned(FOnRejected) then
      FOnRejected(Self, AWavFileName, AConfidence);
  end;
end;

function TAISpeakerIdentifier.VerifyFromWav(const AWavFileName, ASpeakerID: string;
  out ADecision: TAISpeakerDecision; out AConfidence: Double): Boolean;
var
  Sig: TAISpeakerSignature;
  Profile: TAISpeakerProfile;
begin
  Result := False;
  ADecision := sdInconclusive;
  AConfidence := 0.0;

  if not FRegistry.Find(ASpeakerID, Profile) then
  begin
    FLastError := 'Locutor com ID ' + ASpeakerID + ' nao encontrado no catalogo';
    Exit;
  end;

  if not ExtractSignature(AWavFileName, Sig) then Exit;

  FSession.SetReference(Profile.Signature);
  AConfidence := FSession.Similarity(Profile.Signature, Sig);
  Result := FSession.Evaluate(Sig, ADecision);
end;

end.