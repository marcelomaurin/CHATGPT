unit soundfilters;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, LResources;

type
  TDoubleArray = array of Double;
  TDoubleMatrix = array of TDoubleArray;

  { TLowPassFilter }
  TLowPassFilter = class(TComponent)
  private
    FCutoffFrequency: Double;
    FSampleRate: Double;
    FLastOutput: Double;
    FAlpha: Double;
    procedure RecalculateAlpha;
    procedure SetCutoffFrequency(AValue: Double);
    procedure SetSampleRate(AValue: Double);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Reset;
    function Process(const AInput: Double): Double;
    function ProcessArray(const AInput: TDoubleArray): TDoubleArray;
  published
    property CutoffFrequency: Double read FCutoffFrequency write SetCutoffFrequency;
    property SampleRate: Double read FSampleRate write SetSampleRate;
  end;

  { THighPassFilter }
  THighPassFilter = class(TComponent)
  private
    FCutoffFrequency: Double;
    FSampleRate: Double;
    FLastInput: Double;
    FLastOutput: Double;
    FAlpha: Double;
    procedure RecalculateAlpha;
    procedure SetCutoffFrequency(AValue: Double);
    procedure SetSampleRate(AValue: Double);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Reset;
    function Process(const AInput: Double): Double;
    function ProcessArray(const AInput: TDoubleArray): TDoubleArray;
  published
    property CutoffFrequency: Double read FCutoffFrequency write SetCutoffFrequency;
    property SampleRate: Double read FSampleRate write SetSampleRate;
  end;

  { TAverageFilter }
  TAverageFilter = class(TComponent)
  private
    FWindowSize: Integer;
    FBuffer: TDoubleArray;
    FHead: Integer;
    FCount: Integer;
    FSum: Double;
    procedure SetWindowSize(AValue: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    procedure Reset;
    function Process(const AInput: Double): Double;
    function ProcessArray(const AInput: TDoubleArray): TDoubleArray;
  published
    property WindowSize: Integer read FWindowSize write SetWindowSize;
  end;

  { TFDMMultiplexer }
  TFDMMultiplexer = class(TComponent)
  private
    FChannelsCount: Integer;
    FSampleRate: Double;
    procedure SetChannelsCount(AValue: Integer);
  public
    constructor Create(AOwner: TComponent); override;
    function Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
    function Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
  published
    property ChannelsCount: Integer read FChannelsCount write SetChannelsCount;
    property SampleRate: Double read FSampleRate write FSampleRate;
  end;

  { TTDMMultiplexer }
  TTDMMultiplexer = class(TComponent)
  private
    FChannelsCount: Integer;
    FSlotSize: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
    function Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
  published
    property ChannelsCount: Integer read FChannelsCount write FChannelsCount;
    property SlotSize: Integer read FSlotSize write FSlotSize;
  end;

  { TCDMMultiplexer }
  TCDMMultiplexer = class(TComponent)
  private
    FChannelsCount: Integer;
    FCodeLength: Integer;
    FCodes: TDoubleMatrix;
    procedure GenerateHadamardCodes;
  public
    constructor Create(AOwner: TComponent); override;
    function Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
    function Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
  published
    property ChannelsCount: Integer read FChannelsCount write FChannelsCount;
  end;

  { TOFDMMultiplexer }
  TOFDMMultiplexer = class(TComponent)
  private
    FSubcarriersCount: Integer;
    FCyclicPrefixLength: Integer;
    procedure FFT(var AReal, AImag: TDoubleArray; AInverse: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
    function Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
    function Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
  published
    property SubcarriersCount: Integer read FSubcarriersCount write FSubcarriersCount;
    property CyclicPrefixLength: Integer read FCyclicPrefixLength write FCyclicPrefixLength;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Filtros Sonoros', [
    TLowPassFilter,
    THighPassFilter,
    TAverageFilter,
    TFDMMultiplexer,
    TTDMMultiplexer,
    TCDMMultiplexer,
    TOFDMMultiplexer
  ]);
end;

{ TLowPassFilter }

constructor TLowPassFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCutoffFrequency := 1000.0;
  FSampleRate := 44100.0;
  Reset;
  RecalculateAlpha;
end;

procedure TLowPassFilter.Reset;
begin
  FLastOutput := 0.0;
end;

procedure TLowPassFilter.RecalculateAlpha;
var
  Dt, Rc: Double;
begin
  if (FSampleRate > 0) and (FCutoffFrequency > 0) then
  begin
    Dt := 1.0 / FSampleRate;
    Rc := 1.0 / (2.0 * Pi * FCutoffFrequency);
    FAlpha := Dt / (Rc + Dt);
  end
  else
    FAlpha := 1.0;
end;

procedure TLowPassFilter.SetCutoffFrequency(AValue: Double);
begin
  if AValue < 1.0 then AValue := 1.0;
  if FCutoffFrequency <> AValue then
  begin
    FCutoffFrequency := AValue;
    RecalculateAlpha;
  end;
end;

procedure TLowPassFilter.SetSampleRate(AValue: Double);
begin
  if AValue < 1.0 then AValue := 1.0;
  if FSampleRate <> AValue then
  begin
    FSampleRate := AValue;
    RecalculateAlpha;
  end;
end;

function TLowPassFilter.Process(const AInput: Double): Double;
begin
  FLastOutput := FAlpha * AInput + (1.0 - FAlpha) * FLastOutput;
  Result := FLastOutput;
end;

function TLowPassFilter.ProcessArray(const AInput: TDoubleArray): TDoubleArray;
var
  I: Integer;
begin
  SetLength(Result, Length(AInput));
  for I := 0 to High(AInput) do
    Result[I] := Process(AInput[I]);
end;

{ THighPassFilter }

constructor THighPassFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCutoffFrequency := 100.0;
  FSampleRate := 44100.0;
  Reset;
  RecalculateAlpha;
end;

procedure THighPassFilter.Reset;
begin
  FLastInput := 0.0;
  FLastOutput := 0.0;
end;

procedure THighPassFilter.RecalculateAlpha;
var
  Dt, Rc: Double;
begin
  if (FSampleRate > 0) and (FCutoffFrequency > 0) then
  begin
    Dt := 1.0 / FSampleRate;
    Rc := 1.0 / (2.0 * Pi * FCutoffFrequency);
    FAlpha := Rc / (Rc + Dt);
  end
  else
    FAlpha := 0.0;
end;

procedure THighPassFilter.SetCutoffFrequency(AValue: Double);
begin
  if AValue < 1.0 then AValue := 1.0;
  if FCutoffFrequency <> AValue then
  begin
    FCutoffFrequency := AValue;
    RecalculateAlpha;
  end;
end;

procedure THighPassFilter.SetSampleRate(AValue: Double);
begin
  if AValue < 1.0 then AValue := 1.0;
  if FSampleRate <> AValue then
  begin
    FSampleRate := AValue;
    RecalculateAlpha;
  end;
end;

function THighPassFilter.Process(const AInput: Double): Double;
begin
  FLastOutput := FAlpha * FLastOutput + FAlpha * (AInput - FLastInput);
  FLastInput := AInput;
  Result := FLastOutput;
end;

function THighPassFilter.ProcessArray(const AInput: TDoubleArray): TDoubleArray;
var
  I: Integer;
begin
  SetLength(Result, Length(AInput));
  for I := 0 to High(AInput) do
    Result[I] := Process(AInput[I]);
end;

{ TAverageFilter }

constructor TAverageFilter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FWindowSize := 10;
  Reset;
end;

procedure TAverageFilter.Reset;
begin
  SetLength(FBuffer, FWindowSize);
  FillChar(FBuffer[0], Length(FBuffer) * SizeOf(Double), 0);
  FHead := 0;
  FCount := 0;
  FSum := 0.0;
end;

procedure TAverageFilter.SetWindowSize(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  if FWindowSize <> AValue then
  begin
    FWindowSize := AValue;
    Reset;
  end;
end;

function TAverageFilter.Process(const AInput: Double): Double;
begin
  if FCount < FWindowSize then
  begin
    FBuffer[FHead] := AInput;
    FSum := FSum + AInput;
    Inc(FCount);
    FHead := (FHead + 1) mod FWindowSize;
  end
  else
  begin
    FSum := FSum - FBuffer[FHead];
    FBuffer[FHead] := AInput;
    FSum := FSum + AInput;
    FHead := (FHead + 1) mod FWindowSize;
  end;
  
  if FCount > 0 then
    Result := FSum / FCount
  else
    Result := AInput;
end;

function TAverageFilter.ProcessArray(const AInput: TDoubleArray): TDoubleArray;
var
  I: Integer;
begin
  SetLength(Result, Length(AInput));
  for I := 0 to High(AInput) do
    Result[I] := Process(AInput[I]);
end;

{ TFDMMultiplexer }

constructor TFDMMultiplexer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChannelsCount := 3;
  FSampleRate := 44100.0;
end;

procedure TFDMMultiplexer.SetChannelsCount(AValue: Integer);
begin
  if AValue < 1 then AValue := 1;
  FChannelsCount := AValue;
end;

function TFDMMultiplexer.Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
var
  Len, Ch, I: Integer;
  CarrierFreq, TimeVal, Modulated: Double;
begin
  if Length(AInputs) = 0 then Exit(nil);
  Len := Length(AInputs[0]);
  SetLength(Result, Len);
  for I := 0 to Len - 1 do
    Result[I] := 0.0;

  for Ch := 0 to Min(FChannelsCount - 1, Length(AInputs) - 1) do
  begin
    // Espaça as frequências portadoras a partir de 2000Hz (2kHz, 4kHz, 6kHz...)
    CarrierFreq := 2000.0 + Ch * 2000.0;
    for I := 0 to Len - 1 do
    begin
      TimeVal := I / FSampleRate;
      // Modulação AM (Double Sideband Suppressed Carrier)
      Modulated := AInputs[Ch][I] * Cos(2.0 * Pi * CarrierFreq * TimeVal);
      Result[I] := Result[I] + Modulated;
    end;
  end;
end;

function TFDMMultiplexer.Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
var
  Len, I: Integer;
  CarrierFreq, TimeVal, Demodulated, Alpha, Dt, Rc, LastLowPass: Double;
begin
  Len := Length(AComposite);
  SetLength(Result, Len);
  if (AChannelIndex < 0) or (AChannelIndex >= FChannelsCount) then Exit;

  CarrierFreq := 2000.0 + AChannelIndex * 2000.0;
  
  // Coeficiente do filtro passa-baixa para recuperar o sinal original (corta a portadora de alta frequência)
  Dt := 1.0 / FSampleRate;
  Rc := 1.0 / (2.0 * Pi * 1000.0); // Frequência de corte de 1000Hz para reconstrução do áudio
  Alpha := Dt / (Rc + Dt);
  LastLowPass := 0.0;

  for I := 0 to Len - 1 do
  begin
    TimeVal := I / FSampleRate;
    // Demodulação coerente: multiplica pela mesma portadora
    Demodulated := AComposite[I] * Cos(2.0 * Pi * CarrierFreq * TimeVal) * 2.0;
    
    // Aplica filtro passa-baixa integrado para remover a componente de frequência duplicada (2 * CarrierFreq)
    LastLowPass := Alpha * Demodulated + (1.0 - Alpha) * LastLowPass;
    Result[I] := LastLowPass;
  end;
end;

{ TTDMMultiplexer }

constructor TTDMMultiplexer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChannelsCount := 3;
  FSlotSize := 4; // Tamanho do slot em amostras
end;

function TTDMMultiplexer.Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
var
  Len, TotalSamples, FrameSize, FrameCount, Frame, Ch, S, OutIdx: Integer;
begin
  if Length(AInputs) = 0 then Exit(nil);
  Len := Length(AInputs[0]);
  FrameSize := FChannelsCount * FSlotSize;
  FrameCount := Len div FSlotSize;
  TotalSamples := FrameCount * FrameSize;
  SetLength(Result, TotalSamples);

  OutIdx := 0;
  for Frame := 0 to FrameCount - 1 do
  begin
    for Ch := 0 to FChannelsCount - 1 do
    begin
      for S := 0 to FSlotSize - 1 do
      begin
        if Ch < Length(AInputs) then
          Result[OutIdx] := AInputs[Ch][Frame * FSlotSize + S]
        else
          Result[OutIdx] := 0.0;
        Inc(OutIdx);
      end;
    end;
  end;
end;

function TTDMMultiplexer.Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
var
  TotalSamples, FrameSize, FrameCount, Frame, S, OutIdx, InIdx: Integer;
begin
  TotalSamples := Length(AComposite);
  FrameSize := FChannelsCount * FSlotSize;
  FrameCount := TotalSamples div FrameSize;
  SetLength(Result, FrameCount * FSlotSize);

  OutIdx := 0;
  for Frame := 0 to FrameCount - 1 do
  begin
    // Localiza o início do slot deste canal no frame
    InIdx := Frame * FrameSize + AChannelIndex * FSlotSize;
    for S := 0 to FSlotSize - 1 do
    begin
      if InIdx < TotalSamples then
        Result[OutIdx] := AComposite[InIdx]
      else
        Result[OutIdx] := 0.0;
      Inc(InIdx);
      Inc(OutIdx);
    end;
  end;
end;

{ TCDMMultiplexer }

constructor TCDMMultiplexer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChannelsCount := 4;
  FCodeLength := 4;
  GenerateHadamardCodes;
end;

procedure TCDMMultiplexer.GenerateHadamardCodes;
begin
  // Gera códigos de Walsh-Hadamard ortogonais de tamanho 4
  SetLength(FCodes, 4);
  
  // Canal 0: [ 1,  1,  1,  1]
  SetLength(FCodes[0], 4);
  FCodes[0][0] := 1.0; FCodes[0][1] := 1.0; FCodes[0][2] := 1.0; FCodes[0][3] := 1.0;
  
  // Canal 1: [ 1, -1,  1, -1]
  SetLength(FCodes[1], 4);
  FCodes[1][0] := 1.0; FCodes[1][1] := -1.0; FCodes[1][2] := 1.0; FCodes[1][3] := -1.0;
  
  // Canal 2: [ 1,  1, -1, -1]
  SetLength(FCodes[2], 4);
  FCodes[2][0] := 1.0; FCodes[2][1] := 1.0; FCodes[2][2] := -1.0; FCodes[2][3] := -1.0;
  
  // Canal 3: [ 1, -1, -1,  1]
  SetLength(FCodes[3], 4);
  FCodes[3][0] := 1.0; FCodes[3][1] := -1.0; FCodes[3][2] := -1.0; FCodes[3][3] := 1.0;
end;

function TCDMMultiplexer.Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
var
  Len, Chip, Ch, I: Integer;
  Val: Double;
begin
  if Length(AInputs) = 0 then Exit(nil);
  Len := Length(AInputs[0]);
  SetLength(Result, Len * FCodeLength);

  for I := 0 to Len - 1 do
  begin
    for Chip := 0 to FCodeLength - 1 do
    begin
      Val := 0.0;
      for Ch := 0 to Min(FChannelsCount - 1, Length(AInputs) - 1) do
      begin
        // Multiplica a amostra do canal pelo respectivo chip do código ortogonal
        Val := Val + AInputs[Ch][I] * FCodes[Ch mod 4][Chip];
      end;
      Result[I * FCodeLength + Chip] := Val;
    end;
  end;
end;

function TCDMMultiplexer.Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
var
  Len, I, Chip: Integer;
  Correlation: Double;
begin
  Len := Length(AComposite) div FCodeLength;
  SetLength(Result, Len);
  if (AChannelIndex < 0) or (AChannelIndex >= FChannelsCount) then Exit;

  for I := 0 to Len - 1 do
  begin
    Correlation := 0.0;
    for Chip := 0 to FCodeLength - 1 do
    begin
      // Correlação / Produto interno do sinal composto com o código ortogonal
      Correlation := Correlation + AComposite[I * FCodeLength + Chip] * FCodes[AChannelIndex mod 4][Chip];
    end;
    // Normaliza pelo tamanho do código (Code Length)
    Result[I] := Correlation / FCodeLength;
  end;
end;

{ TOFDMMultiplexer }

constructor TOFDMMultiplexer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSubcarriersCount := 8;     // Deve ser potência de 2 para FFT rápida
  FCyclicPrefixLength := 2;   // Prefixo cíclico (Guard Interval)
end;

procedure TOFDMMultiplexer.FFT(var AReal, AImag: TDoubleArray; AInverse: Boolean);
var
  N, I, J, K, M, L, LE, LE1, IP: Integer;
  UR, UI, SR, SI, TR, TI, WR, WI: Double;
begin
  N := Length(AReal);
  if N < 2 then Exit;

  // Bit-reversal
  J := 0;
  for I := 0 to N - 2 do
  begin
    if I < J then
    begin
      TR := AReal[I]; AReal[I] := AReal[J]; AReal[J] := TR;
      TI := AImag[I]; AImag[I] := AImag[J]; AImag[J] := TI;
    end;
    K := N div 2;
    while K <= J do
    begin
      J := J - K;
      K := K div 2;
    end;
    J := J + K;
  end;

  // Cooley-Tukey Radix-2
  M := Round(Log2(N));
  for L := 1 to M do
  begin
    LE := 1 shl L;
    LE1 := LE div 2;
    UR := 1.0;
    UI := 0.0;
    WR := Cos(Pi / LE1);
    WI := Sin(Pi / LE1);
    if not AInverse then
      WI := -WI;
    for J := 0 to LE1 - 1 do
    begin
      I := J;
      while I < N do
      begin
        IP := I + LE1;
        TR := AReal[IP] * UR - AImag[IP] * UI;
        TI := AReal[IP] * UI + AImag[IP] * UR;
        AReal[IP] := AReal[I] - TR;
        AImag[IP] := AImag[I] - TI;
        AReal[I] := AReal[I] + TR;
        AImag[I] := AImag[I] + TI;
        Inc(I, LE);
      end;
      SR := UR * WR - UI * WI;
      UI := UR * WI + UI * WR;
      UR := SR;
    end;
  end;

  if AInverse then
  begin
    for I := 0 to N - 1 do
    begin
      AReal[I] := AReal[I] / N;
      AImag[I] := AImag[I] / N;
    end;
  end;
end;

function TOFDMMultiplexer.Multiplex(const AInputs: TDoubleMatrix): TDoubleArray;
var
  Len, BlockCount, B, I, S: Integer;
  SubReal, SubImag: TDoubleArray;
  SymbolSize, BlockSize: Integer;
begin
  if Length(AInputs) = 0 then Exit(nil);
  Len := Length(AInputs[0]);
  
  SymbolSize := FSubcarriersCount;
  BlockSize := SymbolSize + FCyclicPrefixLength;
  BlockCount := Len div SymbolSize;
  if BlockCount = 0 then BlockCount := 1;

  SetLength(Result, BlockCount * BlockSize);
  SetLength(SubReal, SymbolSize);
  SetLength(SubImag, SymbolSize);

  for B := 0 to BlockCount - 1 do
  begin
    // Mapeia os sinais dos canais nas subportadoras reais (Modulação OFDM no domínio da freq)
    for S := 0 to SymbolSize - 1 do
    begin
      if (S < Length(AInputs)) and (B * SymbolSize + S < Len) then
        SubReal[S] := AInputs[S][B * SymbolSize + S]
      else
        SubReal[S] := 0.0;
      SubImag[S] := 0.0;
    end;

    // Transforma para o domínio do tempo usando IFFT (Fast Fourier Transform Inversa)
    FFT(SubReal, SubImag, True);

    // Insere prefixo cíclico (Copia as últimas amostras do símbolo OFDM para o início)
    for I := 0 to FCyclicPrefixLength - 1 do
    begin
      Result[B * BlockSize + I] := SubReal[SymbolSize - FCyclicPrefixLength + I];
    end;

    // Copia o corpo do símbolo OFDM
    for I := 0 to SymbolSize - 1 do
    begin
      Result[B * BlockSize + FCyclicPrefixLength + I] := SubReal[I];
    end;
  end;
end;

function TOFDMMultiplexer.Demultiplex(const AComposite: TDoubleArray; AChannelIndex: Integer): TDoubleArray;
var
  TotalSamples, SymbolSize, BlockSize, BlockCount, B, I: Integer;
  SubReal, SubImag: TDoubleArray;
begin
  TotalSamples := Length(AComposite);
  SymbolSize := FSubcarriersCount;
  BlockSize := SymbolSize + FCyclicPrefixLength;
  BlockCount := TotalSamples div BlockSize;

  SetLength(Result, BlockCount * SymbolSize);
  SetLength(SubReal, SymbolSize);
  SetLength(SubImag, SymbolSize);

  for B := 0 to BlockCount - 1 do
  begin
    // Remove o prefixo cíclico e extrai o símbolo OFDM
    for I := 0 to SymbolSize - 1 do
    begin
      SubReal[I] := AComposite[B * BlockSize + FCyclicPrefixLength + I];
      SubImag[I] := 0.0;
    end;

    // Aplica FFT para retornar ao domínio da frequência
    FFT(SubReal, SubImag, False);

    // Extrai a subportadora correspondente ao canal
    for I := 0 to SymbolSize - 1 do
    begin
      if I = (AChannelIndex mod SymbolSize) then
        Result[B * SymbolSize + I] := SubReal[I]
      else
        Result[B * SymbolSize + I] := 0.0;
    end;
  end;
end;

initialization
  {$I soundfilters_icon.lrs}

end.
