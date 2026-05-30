unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Math, soundfilters;

type
  { TFormMain }
  TFormMain = class(TForm)
    PanelTop: TPanel;
    GroupBoxControls: TGroupBox;
    LabelCutoffLP: TLabel;
    TrackBarLP: TTrackBar;
    LabelCutoffHP: TLabel;
    TrackBarHP: TTrackBar;
    LabelWindowAvg: TLabel;
    TrackBarAvg: TTrackBar;
    RadioGroupMux: TRadioGroup;
    ButtonRunSim: TButton;
    PageControlGraphs: TPageControl;
    TabSheetFilter: TTabSheet;
    TabSheetMux: TTabSheet;
    PaintBoxFilter: TPaintBox;
    PaintBoxMux: TPaintBox;
    LabelFilterTitle: TLabel;
    LabelMuxTitle: TLabel;
    
    // Nossos componentes inseridos dinamicamente para demonstração
    LowPass: TLowPassFilter;
    HighPass: THighPassFilter;
    Average: TAverageFilter;
    FDM: TFDMMultiplexer;
    TDM: TTDMMultiplexer;
    CDM: TCDMMultiplexer;
    OFDM: TOFDMMultiplexer;

    procedure FormCreate(Sender: TObject);
    procedure ButtonRunSimClick(Sender: TObject);
    procedure PaintBoxFilterPaint(Sender: TObject);
    procedure PaintBoxMuxPaint(Sender: TObject);
    procedure TrackBarLPChange(Sender: TObject);
    procedure TrackBarHPChange(Sender: TObject);
    procedure TrackBarAvgChange(Sender: TObject);
  private
    FSignalOriginal: TDoubleArray;
    FSignalLPFiltered: TDoubleArray;
    FSignalHPFiltered: TDoubleArray;
    FSignalAvgFiltered: TDoubleArray;

    // Matriz de sinais originais para multiplexação
    FChInputs: TDoubleMatrix;
    FCompositeMux: TDoubleArray;
    FChRecovered: TDoubleMatrix;

    procedure GenerateSignals;
    procedure RunSimulation;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  // Instancia dinamicamente os componentes
  LowPass := TLowPassFilter.Create(Self);
  HighPass := THighPassFilter.Create(Self);
  Average := TAverageFilter.Create(Self);
  FDM := TFDMMultiplexer.Create(Self);
  TDM := TTDMMultiplexer.Create(Self);
  CDM := TCDMMultiplexer.Create(Self);
  OFDM := TOFDMMultiplexer.Create(Self);

  // Valores padrão
  LowPass.CutoffFrequency := TrackBarLP.Position;
  HighPass.CutoffFrequency := TrackBarHP.Position;
  Average.WindowSize := TrackBarAvg.Position;

  GenerateSignals;
  RunSimulation;
end;

procedure TFormMain.GenerateSignals;
var
  I, Ch: Integer;
  TimeVal, Noise: Double;
begin
  // Gera 256 amostras para a demonstração gráfica rápida
  SetLength(FSignalOriginal, 256);
  SetLength(FChInputs, 3);
  SetLength(FChInputs[0], 256);
  SetLength(FChInputs[1], 256);
  SetLength(FChInputs[2], 256);

  Randomize;
  for I := 0 to 255 do
  begin
    TimeVal := I / 1000.0; // Amostragem simulada de 1kHz
    
    // Sinal 1: Onda senoidal limpa de baixa frequência (5Hz) com ruído aleatório
    Noise := (Random - 0.5) * 4.0;
    FSignalOriginal[I] := 10.0 * Sin(2.0 * Pi * 5.0 * TimeVal) + Noise;

    // Canais distintos para multiplexação
    // Canal 0 (Vermelho): Senóide de 3Hz
    FChInputs[0][I] := 8.0 * Sin(2.0 * Pi * 3.0 * TimeVal);
    // Canal 1 (Azul): Senóide rápida de 15Hz
    FChInputs[1][I] := 6.0 * Sin(2.0 * Pi * 15.0 * TimeVal);
    // Canal 2 (Verde): Senóide muito rápida de 40Hz
    FChInputs[2][I] := 4.0 * Sin(2.0 * Pi * 40.0 * TimeVal);
  end;
end;

procedure TFormMain.RunSimulation;
var
  Ch: Integer;
begin
  // 1. Processamento dos Filtros
  LowPass.Reset;
  FSignalLPFiltered := LowPass.ProcessArray(FSignalOriginal);

  HighPass.Reset;
  FSignalHPFiltered := HighPass.ProcessArray(FSignalOriginal);

  Average.Reset;
  FSignalAvgFiltered := Average.ProcessArray(FSignalOriginal);

  // 2. Multiplexação baseada na seleção do usuário
  case RadioGroupMux.ItemIndex of
    0: // FDM
    begin
      FCompositeMux := FDM.Multiplex(FChInputs);
      SetLength(FChRecovered, 3);
      for Ch := 0 to 2 do
        FChRecovered[Ch] := FDM.Demultiplex(FCompositeMux, Ch);
    end;
    
    1: // TDM
    begin
      FCompositeMux := TDM.Multiplex(FChInputs);
      SetLength(FChRecovered, 3);
      for Ch := 0 to 2 do
        FChRecovered[Ch] := TDM.Demultiplex(FCompositeMux, Ch);
    end;
    
    2: // CDM / CDMA
    begin
      FCompositeMux := CDM.Multiplex(FChInputs);
      SetLength(FChRecovered, 3);
      for Ch := 0 to 2 do
        FChRecovered[Ch] := CDM.Demultiplex(FCompositeMux, Ch);
    end;
    
    3: // OFDM
    begin
      FCompositeMux := OFDM.Multiplex(FChInputs);
      SetLength(FChRecovered, 3);
      for Ch := 0 to 2 do
        FChRecovered[Ch] := OFDM.Demultiplex(FCompositeMux, Ch);
    end;
  end;

  PaintBoxFilter.Invalidate;
  PaintBoxMux.Invalidate;
end;

procedure TFormMain.ButtonRunSimClick(Sender: TObject);
begin
  GenerateSignals;
  RunSimulation;
end;

procedure TFormMain.TrackBarLPChange(Sender: TObject);
begin
  LabelCutoffLP.Caption := Format('Cutoff LP: %d Hz', [TrackBarLP.Position]);
  LowPass.CutoffFrequency := TrackBarLP.Position;
  RunSimulation;
end;

procedure TFormMain.TrackBarHPChange(Sender: TObject);
begin
  LabelCutoffHP.Caption := Format('Cutoff HP: %d Hz', [TrackBarHP.Position]);
  HighPass.CutoffFrequency := TrackBarHP.Position;
  RunSimulation;
end;

procedure TFormMain.TrackBarAvgChange(Sender: TObject);
begin
  LabelWindowAvg.Caption := Format('Janela Média: %d', [TrackBarAvg.Position]);
  Average.WindowSize := TrackBarAvg.Position;
  RunSimulation;
end;

procedure TFormMain.PaintBoxFilterPaint(Sender: TObject);
var
  W, H, HalfH, I: Integer;
  ScaleX, ScaleY: Double;
  procedure DrawWave(const AData: TDoubleArray; AColor: TColor; AWidth: Integer);
  var
    Idx: Integer;
    Px, Py: Integer;
  begin
    PaintBoxFilter.Canvas.Pen.Color := AColor;
    PaintBoxFilter.Canvas.Pen.Width := AWidth;
    for Idx := 0 to High(AData) do
    begin
      Px := Round(Idx * ScaleX);
      Py := HalfH - Round(AData[Idx] * ScaleY);
      if Idx = 0 then
        PaintBoxFilter.Canvas.MoveTo(Px, Py)
      else
        PaintBoxFilter.Canvas.LineTo(Px, Py);
    end;
  end;
begin
  W := PaintBoxFilter.Width;
  H := PaintBoxFilter.Height;
  HalfH := H div 2;
  ScaleX := W / 256.0;
  ScaleY := (H * 0.4) / 15.0; // Fator de escala vertical

  // Limpa o fundo
  PaintBoxFilter.Canvas.Brush.Color := clWhite;
  PaintBoxFilter.Canvas.FillRect(0, 0, W, H);

  // Desenha linha de referência zero
  PaintBoxFilter.Canvas.Pen.Color := TColor($E0E0E0);
  PaintBoxFilter.Canvas.Pen.Style := psDash;
  PaintBoxFilter.Canvas.Pen.Width := 1;
  PaintBoxFilter.Canvas.MoveTo(0, HalfH);
  PaintBoxFilter.Canvas.LineTo(W, HalfH);
  PaintBoxFilter.Canvas.Pen.Style := psSolid;

  if Length(FSignalOriginal) = 0 then Exit;

  // 1. Desenha onda Original com ruído (Cinza claro)
  DrawWave(FSignalOriginal, TColor($808080), 1);
  // 2. Desenha passa-baixa (Verde)
  DrawWave(FSignalLPFiltered, clGreen, 2);
  // 3. Desenha passa-alta (Azul)
  DrawWave(FSignalHPFiltered, clBlue, 2);
  // 4. Desenha média móvel (Laranja)
  DrawWave(FSignalAvgFiltered, TColor($0080FF), 2);
end;

procedure TFormMain.PaintBoxMuxPaint(Sender: TObject);
var
  W, H, SubH, Ch, I: Integer;
  ScaleX, ScaleY: Double;
  procedure DrawMuxWave(const AData: TDoubleArray; AYOffset, AHeight: Integer; AColor: TColor; AWidth: Integer);
  var
    Idx: Integer;
    Px, Py: Integer;
    MaxVal: Double;
  begin
    if Length(AData) = 0 then Exit;
    PaintBoxMux.Canvas.Pen.Color := AColor;
    PaintBoxMux.Canvas.Pen.Width := AWidth;
    
    // Determina o máximo local para normalização visual
    MaxVal := 0.001;
    for Idx := 0 to High(AData) do
      if Abs(AData[Idx]) > MaxVal then MaxVal := Abs(AData[Idx]);

    for Idx := 0 to High(AData) do
    begin
      Px := Round(Idx * (W / Length(AData)));
      Py := AYOffset + (AHeight div 2) - Round((AData[Idx] / MaxVal) * (AHeight * 0.45));
      if Idx = 0 then
        PaintBoxMux.Canvas.MoveTo(Px, Py)
      else
        PaintBoxMux.Canvas.LineTo(Px, Py);
    end;
  end;
begin
  W := PaintBoxMux.Width;
  H := PaintBoxMux.Height;

  // Limpa o fundo
  PaintBoxMux.Canvas.Brush.Color := TColor($FAFAFA);
  PaintBoxMux.Canvas.FillRect(0, 0, W, H);

  // Divide a tela verticalmente em 3 seções:
  // Seção 1 (Topo): Canais originais (3 ondas sobrepostas)
  // Seção 2 (Meio): Sinal Composto Multiplexado (Modulado no cabo/canal físico)
  // Seção 3 (Baixo): Canais desmultiplexados / recuperados
  SubH := H div 3;

  // Divisórias das seções
  PaintBoxMux.Canvas.Pen.Color := clSilver;
  PaintBoxMux.Canvas.Pen.Width := 1;
  PaintBoxMux.Canvas.MoveTo(0, SubH); PaintBoxMux.Canvas.LineTo(W, SubH);
  PaintBoxMux.Canvas.MoveTo(0, SubH * 2); PaintBoxMux.Canvas.LineTo(W, SubH * 2);

  // Rótulos explicativos
  PaintBoxMux.Canvas.Font.Color := clBlack;
  PaintBoxMux.Canvas.Font.Style := [fsBold];
  PaintBoxMux.Canvas.TextOut(10, 5, '1. Canais Originais (Modulados independentes)');
  PaintBoxMux.Canvas.TextOut(10, SubH + 5, '2. Sinal Composto Multiplexado (Transmitido)');
  PaintBoxMux.Canvas.TextOut(10, SubH * 2 + 5, '3. Canais Desmultiplexados (Recuperados)');
  PaintBoxMux.Canvas.Font.Style := [];

  if Length(FChInputs) = 0 then Exit;

  // 1. Plota Canais Originais
  DrawMuxWave(FChInputs[0], 0, SubH, clRed, 1);
  DrawMuxWave(FChInputs[1], 0, SubH, clBlue, 1);
  DrawMuxWave(FChInputs[2], 0, SubH, clGreen, 1);

  // 2. Plota Sinal Composto
  DrawMuxWave(FCompositeMux, SubH, SubH, clPurple, 2);

  // 3. Plota Canais Recuperados
  if Length(FChRecovered) >= 3 then
  begin
    DrawMuxWave(FChRecovered[0], SubH * 2, SubH, clRed, 2);
    DrawMuxWave(FChRecovered[1], SubH * 2, SubH, clBlue, 2);
    DrawMuxWave(FChRecovered[2], SubH * 2, SubH, clGreen, 2);
  end;
end;

end.
