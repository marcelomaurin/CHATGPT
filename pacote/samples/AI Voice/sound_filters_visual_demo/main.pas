unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Clipbrd, aibase, soundfilters;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    pcMain: TPageControl;
    
    // Signal tab
    tsSignal: TTabSheet;
    lblSampleRate: TLabel;
    edtSampleRate: TEdit;
    lblDuration: TLabel;
    edtDuration: TEdit;
    lblBaseFrequency: TLabel;
    edtBaseFrequency: TEdit;
    lblNoiseFrequency: TLabel;
    edtNoiseFrequency: TEdit;
    lblNoiseAmplitude: TLabel;
    edtNoiseAmplitude: TEdit;
    btnGenerateSignal: TButton;
    btnClearSignal: TButton;
    
    // Filters tab
    tsFilters: TTabSheet;
    lblFilterType: TLabel;
    cbFilterType: TComboBox;
    lblLowPassCutoff: TLabel;
    edtLowPassCutoff: TEdit;
    lblHighPassCutoff: TLabel;
    edtHighPassCutoff: TEdit;
    lblAverageWindow: TLabel;
    edtAverageWindow: TEdit;
    btnApplyFilter: TButton;
    btnResetFilters: TButton;
    
    // Result tab
    tsResult: TTabSheet;
    lblInputSignal: TLabel;
    pbInputSignal: TPaintBox;
    lblFilteredSignal: TLabel;
    pbOutputSignal: TPaintBox;
    lblMetrics: TLabel;
    memoMetrics: TMemo;
    btnExportCSV: TButton;
    btnCopyMetrics: TButton;
    
    // Log tab
    tsLog: TTabSheet;
    memoLog: TMemo;
    btnClearLog: TButton;
    
    dlgSave: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGenerateSignalClick(Sender: TObject);
    procedure btnClearSignalClick(Sender: TObject);
    procedure btnApplyFilterClick(Sender: TObject);
    procedure btnResetFiltersClick(Sender: TObject);
    procedure btnExportCSVClick(Sender: TObject);
    procedure btnCopyMetricsClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure pbInputSignalPaint(Sender: TObject);
    procedure pbOutputSignalPaint(Sender: TObject);
  private
    FLowPass: TLowPassFilter;
    FHighPass: THighPassFilter;
    FAverage: TAverageFilter;

    FInputSignal: TDoubleArray;
    FOutputSignal: TDoubleArray;

    FSampleRate: Double;
    FDuration: Double;

    procedure AddLog(const AMsg: string);
    procedure GenerateTestSignal;
    procedure ApplySelectedFilter;
    procedure UpdateCharts;
    procedure UpdateMetrics;
    procedure DrawSignal(APaintBox: TPaintBox; const ASignal: TDoubleArray; const ATitle: string);

    function CalculatePeak(const ASignal: TDoubleArray): Double;
    function CalculateRMS(const ASignal: TDoubleArray): Double;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FLowPass := TLowPassFilter.Create(Self);
  FHighPass := THighPassFilter.Create(Self);
  FAverage := TAverageFilter.Create(Self);
  
  AddLog('Sound Filters Visual Demo initialized.');
  lblStatus.Caption := 'Status: Ready';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

procedure TfrmMain.GenerateTestSignal;
var
  BaseFreq, NoiseFreq, NoiseAmp: Double;
  NumSamples, I: Integer;
  TimeVal: Double;
begin
  FSampleRate := StrToFloatDef(edtSampleRate.Text, 44100.0);
  FDuration := StrToFloatDef(edtDuration.Text, 1.0);
  BaseFreq := StrToFloatDef(edtBaseFrequency.Text, 1000.0);
  NoiseFreq := StrToFloatDef(edtNoiseFrequency.Text, 12000.0);
  NoiseAmp := StrToFloatDef(edtNoiseAmplitude.Text, 0.35);

  if FSampleRate <= 0 then FSampleRate := 44100.0;
  if FDuration <= 0 then FDuration := 1.0;

  NumSamples := Round(FSampleRate * FDuration);
  if NumSamples <= 0 then NumSamples := 44100;

  SetLength(FInputSignal, NumSamples);
  SetLength(FOutputSignal, 0); // Reset output signal

  for I := 0 to NumSamples - 1 do
  begin
    TimeVal := I / FSampleRate;
    FInputSignal[I] := Sin(2 * Pi * BaseFreq * TimeVal) + 
                       NoiseAmp * Sin(2 * Pi * NoiseFreq * TimeVal);
  end;

  AddLog(Format('Input signal generated. Samples: %d, Base Freq: %g Hz, Noise Freq: %g Hz', 
    [NumSamples, BaseFreq, NoiseFreq]));
end;

procedure TfrmMain.btnGenerateSignalClick(Sender: TObject);
begin
  try
    GenerateTestSignal;
    UpdateCharts;
    UpdateMetrics;
    lblStatus.Caption := 'Status: Signal generated successfully';
  except
    on E: Exception do
    begin
      AddLog('Error generating signal: ' + E.Message);
      lblStatus.Caption := 'Status: Error generating signal';
    end;
  end;
end;

procedure TfrmMain.btnClearSignalClick(Sender: TObject);
begin
  SetLength(FInputSignal, 0);
  SetLength(FOutputSignal, 0);
  UpdateCharts;
  UpdateMetrics;
  AddLog('Signals cleared.');
  lblStatus.Caption := 'Status: Signals cleared';
end;

procedure TfrmMain.ApplySelectedFilter;
var
  LowPassCutoff, HighPassCutoff: Double;
  AvgWindow: Integer;
begin
  if Length(FInputSignal) = 0 then
  begin
    ShowMessage('Please generate the test signal first.');
    Exit;
  end;

  LowPassCutoff := StrToFloatDef(edtLowPassCutoff.Text, 4000.0);
  HighPassCutoff := StrToFloatDef(edtHighPassCutoff.Text, 12000.0);
  AvgWindow := StrToIntDef(edtAverageWindow.Text, 5);

  FLowPass.SampleRate := FSampleRate;
  FLowPass.CutoffFrequency := LowPassCutoff;

  FHighPass.SampleRate := FSampleRate;
  FHighPass.CutoffFrequency := HighPassCutoff;

  FAverage.WindowSize := AvgWindow;

  AddLog('Applying filter: ' + cbFilterType.Text);

  if cbFilterType.Text = 'Low-pass' then
  begin
    FLowPass.Reset;
    FOutputSignal := FLowPass.ProcessArray(FInputSignal);
    AddLog(Format('Low-pass applied. Cutoff: %g Hz', [LowPassCutoff]));
  end
  else if cbFilterType.Text = 'High-pass' then
  begin
    FHighPass.Reset;
    FOutputSignal := FHighPass.ProcessArray(FInputSignal);
    AddLog(Format('High-pass applied. Cutoff: %g Hz', [HighPassCutoff]));
  end
  else
  begin
    FAverage.Reset;
    FOutputSignal := FAverage.ProcessArray(FInputSignal);
    AddLog(Format('Moving average applied. Window size: %d', [AvgWindow]));
  end;
end;

procedure TfrmMain.btnApplyFilterClick(Sender: TObject);
begin
  try
    ApplySelectedFilter;
    UpdateCharts;
    UpdateMetrics;
    lblStatus.Caption := 'Status: Filter applied successfully';
  except
    on E: Exception do
    begin
      AddLog('Error applying filter: ' + E.Message);
      lblStatus.Caption := 'Status: Error applying filter';
    end;
  end;
end;

procedure TfrmMain.btnResetFiltersClick(Sender: TObject);
begin
  SetLength(FOutputSignal, 0);
  UpdateCharts;
  UpdateMetrics;
  AddLog('Filters reset.');
  lblStatus.Caption := 'Status: Filters reset';
end;

procedure TfrmMain.DrawSignal(APaintBox: TPaintBox; const ASignal: TDoubleArray; const ATitle: string);
var
  W, H, MidY, I, Step, PtsCount: Integer;
  MaxVal: Double;
  X, Y, LastX, LastY: Integer;
begin
  W := APaintBox.Width;
  H := APaintBox.Height;
  MidY := H div 2;

  // Clear paintbox
  APaintBox.Canvas.Brush.Color := clWhite;
  APaintBox.Canvas.FillRect(0, 0, W, H);

  // Draw central axis
  APaintBox.Canvas.Pen.Color := clLtGray;
  APaintBox.Canvas.Pen.Style := psDash;
  APaintBox.Canvas.Line(0, MidY, W, MidY);
  
  if Length(ASignal) = 0 then
  begin
    APaintBox.Canvas.Font.Color := clGray;
    APaintBox.Canvas.TextOut(15, 15, ATitle + ': No signal');
    Exit;
  end;

  APaintBox.Canvas.Font.Color := clBlack;
  APaintBox.Canvas.TextOut(15, 15, ATitle);

  // Normalization value
  MaxVal := CalculatePeak(ASignal);
  if MaxVal = 0 then MaxVal := 1.0;

  APaintBox.Canvas.Pen.Color := clBlue;
  APaintBox.Canvas.Pen.Style := psSolid;

  PtsCount := Length(ASignal);
  Step := Max(1, PtsCount div W);

  LastX := 0;
  LastY := MidY - Round((ASignal[0] / MaxVal) * (MidY - 10));

  for I := 1 to W - 1 do
  begin
    X := I;
    if I * Step < PtsCount then
    begin
      Y := MidY - Round((ASignal[I * Step] / MaxVal) * (MidY - 10));
      APaintBox.Canvas.Line(LastX, LastY, X, Y);
      LastX := X;
      LastY := Y;
    end;
  end;
end;

procedure TfrmMain.pbInputSignalPaint(Sender: TObject);
begin
  DrawSignal(pbInputSignal, FInputSignal, 'Input Waveform');
end;

procedure TfrmMain.pbOutputSignalPaint(Sender: TObject);
begin
  DrawSignal(pbOutputSignal, FOutputSignal, 'Filtered Waveform');
end;

procedure TfrmMain.UpdateCharts;
begin
  pbInputSignal.Invalidate;
  pbOutputSignal.Invalidate;
end;

function TfrmMain.CalculatePeak(const ASignal: TDoubleArray): Double;
var
  I: Integer;
begin
  Result := 0.0;
  for I := 0 to High(ASignal) do
    Result := Max(Result, Abs(ASignal[I]));
end;

function TfrmMain.CalculateRMS(const ASignal: TDoubleArray): Double;
var
  I: Integer;
  Sum: Double;
begin
  Result := 0.0;
  if Length(ASignal) = 0 then Exit;

  Sum := 0.0;
  for I := 0 to High(ASignal) do
    Sum := Sum + Sqr(ASignal[I]);

  Result := Sqrt(Sum / Length(ASignal));
end;

procedure TfrmMain.UpdateMetrics;
var
  Metrics: TStringList;
begin
  Metrics := TStringList.Create;
  try
    Metrics.Add('Input signal details:');
    Metrics.Add(Format('  Samples: %d', [Length(FInputSignal)]));
    if Length(FInputSignal) > 0 then
    begin
      Metrics.Add(Format('  Sample Rate: %g Hz', [FSampleRate]));
      Metrics.Add(Format('  Duration: %g s', [FDuration]));
      Metrics.Add(Format('  Peak Amplitude: %g', [CalculatePeak(FInputSignal)]));
      Metrics.Add(Format('  RMS: %g', [CalculateRMS(FInputSignal)]));
    end
    else
      Metrics.Add('  (No signal generated)');

    Metrics.Add('');
    Metrics.Add('Output (Filtered) signal details:');
    Metrics.Add(Format('  Samples: %d', [Length(FOutputSignal)]));
    if Length(FOutputSignal) > 0 then
    begin
      Metrics.Add(Format('  Selected Filter: %s', [cbFilterType.Text]));
      Metrics.Add(Format('  Peak Amplitude: %g', [CalculatePeak(FOutputSignal)]));
      Metrics.Add(Format('  RMS: %g', [CalculateRMS(FOutputSignal)]));
    end
    else
      Metrics.Add('  (No filter applied)');

    memoMetrics.Text := Metrics.Text;
  finally
    Metrics.Free;
  end;
end;

procedure TfrmMain.btnExportCSVClick(Sender: TObject);
var
  List: TStringList;
  I: Integer;
  InVal, OutVal: string;
begin
  if Length(FInputSignal) = 0 then
  begin
    ShowMessage('There is no signal data to export.');
    Exit;
  end;

  if dlgSave.Execute then
  begin
    lblStatus.Caption := 'Status: Exporting CSV...';
    List := TStringList.Create;
    try
      List.Add('sample_index,input_signal,output_signal');
      for I := 0 to High(FInputSignal) do
      begin
        InVal := FloatToStr(FInputSignal[I]);
        if I < Length(FOutputSignal) then
          OutVal := FloatToStr(FOutputSignal[I])
        else
          OutVal := '';
        List.Add(Format('%d,%s,%s', [I, InVal, OutVal]));
      end;
      List.SaveToFile(dlgSave.FileName);
      AddLog('Data exported to CSV: ' + dlgSave.FileName);
      lblStatus.Caption := 'Status: Export completed successfully';
    finally
      List.Free;
    end;
  end;
end;

procedure TfrmMain.btnCopyMetricsClick(Sender: TObject);
begin
  Clipboard.AsText := memoMetrics.Text;
  AddLog('Metrics copied to clipboard.');
  lblStatus.Caption := 'Status: Metrics copied';
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

end.
