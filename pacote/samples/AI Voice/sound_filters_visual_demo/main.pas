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
    btnSelfTest: TButton;
    
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
    lblViewMode: TLabel;
    cbViewMode: TComboBox;
    lblMetrics: TLabel;
    memoMetrics: TMemo;
    pnlPassStatus: TPanel;
    lblExplanation: TLabel;
    memoExplanation: TMemo;
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
    procedure cbViewModeSelect(Sender: TObject);
    procedure btnSelfTestClick(Sender: TObject);
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
    procedure UpdateExplanationAndValidation(const AFilter: string);
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
  pnlPassStatus.Caption := 'STATUS: UNKNOWN';
  pnlPassStatus.Color := clSilver;
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
    pnlPassStatus.Caption := 'STATUS: UNKNOWN';
    pnlPassStatus.Color := clSilver;
    memoExplanation.Clear;
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
  pnlPassStatus.Caption := 'STATUS: UNKNOWN';
  pnlPassStatus.Color := clSilver;
  memoExplanation.Clear;
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
  HighPassCutoff := StrToFloatDef(edtHighPassCutoff.Text, 6000.0);
  AvgWindow := StrToIntDef(edtAverageWindow.Text, 5);

  AddLog('Applying filter: ' + cbFilterType.Text);

  if cbFilterType.Text = 'Low-pass' then
  begin
    FLowPass.Reset;
    FLowPass.SampleRate := FSampleRate;
    FLowPass.CutoffFrequency := LowPassCutoff;
    FOutputSignal := FLowPass.ProcessArray(FInputSignal);
    AddLog(Format('Low-pass applied. Cutoff: %g Hz', [LowPassCutoff]));
  end
  else if cbFilterType.Text = 'High-pass' then
  begin
    FHighPass.Reset;
    FHighPass.SampleRate := FSampleRate;
    FHighPass.CutoffFrequency := HighPassCutoff;
    FOutputSignal := FHighPass.ProcessArray(FInputSignal);
    AddLog(Format('High-pass applied. Cutoff: %g Hz', [HighPassCutoff]));
  end
  else
  begin
    FAverage.Reset;
    FAverage.WindowSize := AvgWindow;
    FOutputSignal := FAverage.ProcessArray(FInputSignal);
    AddLog(Format('Moving average applied. Window size: %d', [AvgWindow]));
  end;
  
  UpdateExplanationAndValidation(cbFilterType.Text);
end;

procedure TfrmMain.UpdateExplanationAndValidation(const AFilter: string);
var
  InRMS, OutRMS: Double;
  InPeak, OutPeak: Double;
begin
  InRMS := CalculateRMS(FInputSignal);
  OutRMS := CalculateRMS(FOutputSignal);
  InPeak := CalculatePeak(FInputSignal);
  OutPeak := CalculatePeak(FOutputSignal);

  if AFilter = 'Low-pass' then
  begin
    memoExplanation.Text := 'The low-pass filter keeps frequencies below the cutoff and reduces frequencies above it. ' +
                            'In this test, the 1000 Hz base signal is below the 4000 Hz cutoff and should remain. ' +
                            'The 12000 Hz noise is above the cutoff and should be reduced.';
    
    // Evaluation for Low-pass
    if OutRMS < (InRMS * 0.95) then
    begin
      pnlPassStatus.Caption := 'STATUS: PASS';
      pnlPassStatus.Color := clGreen;
      pnlPassStatus.Font.Color := clWhite;
    end
    else if Abs(OutRMS - InRMS) < (InRMS * 0.05) then
    begin
      pnlPassStatus.Caption := 'STATUS: WARNING';
      pnlPassStatus.Color := $0000A5FF; // Orange
      pnlPassStatus.Font.Color := clWhite;
    end
    else
    begin
      pnlPassStatus.Caption := 'STATUS: FAIL';
      pnlPassStatus.Color := clRed;
      pnlPassStatus.Font.Color := clWhite;
    end;
  end
  else if AFilter = 'High-pass' then
  begin
    memoExplanation.Text := 'The high-pass filter reduces frequencies below the cutoff and keeps frequencies above it. ' +
                            'In this test, the 1000 Hz base signal is below the 6000 Hz cutoff and should be reduced, ' +
                            'while the 12000 Hz high frequency noise remains.';
                            
    // Evaluation for High-pass (should drop base frequency, meaning RMS goes down)
    if OutRMS < InRMS then
    begin
      pnlPassStatus.Caption := 'STATUS: PASS';
      pnlPassStatus.Color := clGreen;
      pnlPassStatus.Font.Color := clWhite;
    end
    else
    begin
      pnlPassStatus.Caption := 'STATUS: FAIL';
      pnlPassStatus.Color := clRed;
      pnlPassStatus.Font.Color := clWhite;
    end;
  end
  else // Moving average
  begin
    memoExplanation.Text := 'The moving average filter smooths fast variations in the signal. ' +
                            'It averages neighboring samples to cancel out high-frequency noise spikes.';
                            
    // Evaluation for Moving average
    if (OutPeak < InPeak) or (OutRMS < InRMS) then
    begin
      pnlPassStatus.Caption := 'STATUS: PASS';
      pnlPassStatus.Color := clGreen;
      pnlPassStatus.Font.Color := clWhite;
    end
    else
    begin
      pnlPassStatus.Caption := 'STATUS: FAIL';
      pnlPassStatus.Color := clRed;
      pnlPassStatus.Font.Color := clWhite;
    end;
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
  pnlPassStatus.Caption := 'STATUS: UNKNOWN';
  pnlPassStatus.Color := clSilver;
  memoExplanation.Clear;
  AddLog('Filters reset.');
  lblStatus.Caption := 'Status: Filters reset';
end;

procedure TfrmMain.DrawSignal(APaintBox: TPaintBox; const ASignal: TDoubleArray; const ATitle: string);
var
  W, H, MidY, I, StartIdx, DrawSamplesCount: Integer;
  MaxVal: Double;
  X, Y, LastX, LastY: Integer;
  Step: Double;
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

  // Normalization value (use input signal maximum to keep output scale proportional)
  MaxVal := CalculatePeak(FInputSignal);
  if MaxVal = 0 then MaxVal := 1.0;

  APaintBox.Canvas.Pen.Color := clBlue;
  if APaintBox = pbOutputSignal then
    APaintBox.Canvas.Pen.Color := clRed;
  APaintBox.Canvas.Pen.Style := psSolid;

  StartIdx := 0;
  
  // View mode limit calculation
  if cbViewMode.Text = 'First 5 ms' then
    DrawSamplesCount := Min(Length(ASignal), Round(FSampleRate * 0.005))
  else if cbViewMode.Text = 'First 20 ms' then
    DrawSamplesCount := Min(Length(ASignal), Round(FSampleRate * 0.020))
  else
    DrawSamplesCount := Length(ASignal);

  if DrawSamplesCount <= 0 then Exit;

  // Draw waveforms
  Step := DrawSamplesCount / W;
  LastX := 0;
  LastY := MidY - Round((ASignal[StartIdx] / MaxVal) * (MidY - 10));

  for I := 1 to W - 1 do
  begin
    X := I;
    Y := MidY - Round((ASignal[StartIdx + Round(I * Step)] / MaxVal) * (MidY - 10));
    APaintBox.Canvas.Line(LastX, LastY, X, Y);
    LastX := X;
    LastY := Y;
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

procedure TfrmMain.cbViewModeSelect(Sender: TObject);
begin
  UpdateCharts;
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

// Root-mean-square calculation
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
      Metrics.Add(Format('  Duration: %.3f s', [FDuration]));
      Metrics.Add(Format('  Peak Amplitude: %.3f', [CalculatePeak(FInputSignal)]));
      Metrics.Add(Format('  RMS: %.3f', [CalculateRMS(FInputSignal)]));
    end
    else
      Metrics.Add('  (No signal generated)');

    Metrics.Add('');
    Metrics.Add('Output (Filtered) signal details:');
    Metrics.Add(Format('  Samples: %d', [Length(FOutputSignal)]));
    if Length(FOutputSignal) > 0 then
    begin
      Metrics.Add(Format('  Selected Filter: %s', [cbFilterType.Text]));
      Metrics.Add(Format('  Peak Amplitude: %.3f', [CalculatePeak(FOutputSignal)]));
      Metrics.Add(Format('  RMS: %.3f', [CalculateRMS(FOutputSignal)]));
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
        InVal := Format('%.6f', [FInputSignal[I]]);
        if I < Length(FOutputSignal) then
          OutVal := Format('%.6f', [FOutputSignal[I]])
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

procedure TfrmMain.btnSelfTestClick(Sender: TObject);
var
  LowPassCutoff, HighPassCutoff: Double;
  AvgWindow: Integer;
  LInRMS, LOutRMS: Double;
  LP_Pass, HP_Pass, MA_Pass: Boolean;
  SummaryText: string;
begin
  AddLog('--- Launching Sound Filters Self-Test ---');
  lblStatus.Caption := 'Status: Running self-test...';
  
  try
    // Step 1: Generate Default Signal
    GenerateTestSignal;
    LInRMS := CalculateRMS(FInputSignal);
    AddLog(Format('Self-Test Input Signal RMS: %.3f', [LInRMS]));
    
    LowPassCutoff := StrToFloatDef(edtLowPassCutoff.Text, 4000.0);
    HighPassCutoff := StrToFloatDef(edtHighPassCutoff.Text, 6000.0);
    AvgWindow := StrToIntDef(edtAverageWindow.Text, 5);
    
    // Step 2: Apply Low-Pass
    FLowPass.Reset;
    FLowPass.SampleRate := FSampleRate;
    FLowPass.CutoffFrequency := LowPassCutoff;
    FOutputSignal := FLowPass.ProcessArray(FInputSignal);
    LOutRMS := CalculateRMS(FOutputSignal);
    LP_Pass := LOutRMS < (LInRMS * 0.95);
    AddLog(Format('Low-Pass Self-Test: Input RMS %.3f -> Output RMS %.3f [%s]', 
      [LInRMS, LOutRMS, BoolToStr(LP_Pass, 'PASS', 'FAIL')]));
      
    // Step 3: Apply High-Pass
    FHighPass.Reset;
    FHighPass.SampleRate := FSampleRate;
    FHighPass.CutoffFrequency := HighPassCutoff;
    FOutputSignal := FHighPass.ProcessArray(FInputSignal);
    LOutRMS := CalculateRMS(FOutputSignal);
    HP_Pass := LOutRMS < LInRMS;
    AddLog(Format('High-Pass Self-Test: Input RMS %.3f -> Output RMS %.3f [%s]', 
      [LInRMS, LOutRMS, BoolToStr(HP_Pass, 'PASS', 'FAIL')]));
      
    // Step 4: Apply Moving Average
    FAverage.Reset;
    FAverage.WindowSize := AvgWindow;
    FOutputSignal := FAverage.ProcessArray(FInputSignal);
    LOutRMS := CalculateRMS(FOutputSignal);
    MA_Pass := LOutRMS < LInRMS;
    AddLog(Format('Moving Average Self-Test: Input RMS %.3f -> Output RMS %.3f [%s]', 
      [LInRMS, LOutRMS, BoolToStr(MA_Pass, 'PASS', 'FAIL')]));
      
    // Summary
    SummaryText := 'Self-Test Results Summary:' + sLineBreak +
                   Format('Low-pass filter check: %s' + sLineBreak, [BoolToStr(LP_Pass, 'PASS', 'FAIL')]) +
                   Format('High-pass filter check: %s' + sLineBreak, [BoolToStr(HP_Pass, 'PASS', 'FAIL')]) +
                   Format('Moving average filter check: %s', [BoolToStr(MA_Pass, 'PASS', 'FAIL')]);
                   
    ShowMessage(SummaryText);
    AddLog('Self-Test completed.');
    
    // Set view back to Low-Pass result visually
    cbFilterType.ItemIndex := 0; // Low-pass
    ApplySelectedFilter;
    UpdateCharts;
    UpdateMetrics;
    
    lblStatus.Caption := 'Status: Self-test completed';
  except
    on E: Exception do
    begin
      AddLog('Self-Test Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Self-test failed';
      ShowMessage('Self-Test failed: ' + E.Message);
    end;
  end;
end;

end.
