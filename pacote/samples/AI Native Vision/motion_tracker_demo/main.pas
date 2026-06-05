unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, aimotiontracker, aiframediff;

type

  { TfrmMotionDemo }

  TfrmMotionDemo = class(TForm)
    pnlLeft: TPanel;
    pnlClient: TPanel;
    pnlBottom: TPanel;
    
    pnlFrameA: TPanel;
    pnlFrameB: TPanel;
    pnlFrameDiff: TPanel;
    
    btnLoadA: TButton;
    btnLoadB: TButton;
    btnRun: TButton;
    btnSaveDiff: TButton;
    
    lblThreshold: TLabel;
    edThreshold: TEdit;
    lblMinMotion: TLabel;
    edMinMotion: TEdit;
    
    imgFrameA: TImage;
    imgFrameB: TImage;
    imgFrameDiff: TImage;
    
    lblInfoA: TLabel;
    lblInfoB: TLabel;
    lblInfoDiff: TLabel;
    
    lblResultMotion: TLabel;
    lblResultPercent: TLabel;
    
    memLog: TMemo;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure btnLoadAClick(Sender: TObject);
    procedure btnLoadBClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnSaveDiffClick(Sender: TObject);
  private
    Tracker: TAIMotionTracker;
    DiffGen: TAIFrameDiff;
    BmpA: TBitmap;
    BmpB: TBitmap;
    BmpDiff: TBitmap;
    procedure LogMsg(const AMsg: string);
  public

  end;

var
  frmMotionDemo: TfrmMotionDemo;

implementation

{$R *.lfm}

{ TfrmMotionDemo }

procedure TfrmMotionDemo.FormCreate(Sender: TObject);
begin
  Tracker := TAIMotionTracker.Create(Self);
  DiffGen := TAIFrameDiff.Create(Self);
  BmpA := TBitmap.Create;
  BmpB := TBitmap.Create;
  BmpDiff := TBitmap.Create;
  
  edThreshold.Text := '15';
  edMinMotion.Text := '1.5';
  
  lblResultMotion.Caption := 'Motion: N/A';
  lblResultPercent.Caption := 'Diff: 0.0%';
  
  LogMsg('Motion Tracker & Frame Difference Demo Initialized.');
end;

procedure TfrmMotionDemo.btnLoadAClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LogMsg('Loading Frame A from: ' + OpenDialog1.FileName);
    try
      BmpA.LoadFromFile(OpenDialog1.FileName);
      imgFrameA.Picture.Assign(BmpA);
      lblInfoA.Caption := Format('Frame A: %dx%d', [BmpA.Width, BmpA.Height]);
    except
      on E: Exception do
      begin
        LogMsg('Error loading Frame A: ' + E.Message);
        ShowMessage('Failed to load Frame A: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmMotionDemo.btnLoadBClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    LogMsg('Loading Frame B from: ' + OpenDialog1.FileName);
    try
      BmpB.LoadFromFile(OpenDialog1.FileName);
      imgFrameB.Picture.Assign(BmpB);
      lblInfoB.Caption := Format('Frame B: %dx%d', [BmpB.Width, BmpB.Height]);
    except
      on E: Exception do
      begin
        LogMsg('Error loading Frame B: ' + E.Message);
        ShowMessage('Failed to load Frame B: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmMotionDemo.btnRunClick(Sender: TObject);
var
  TStart, TEnd: TDateTime;
  ElapsedMs: Double;
  MotionDetected: Boolean;
begin
  if (BmpA.Width = 0) or (BmpB.Width = 0) then
  begin
    ShowMessage('Please load both Frame A and Frame B first.');
    Exit;
  end;

  if (BmpA.Width <> BmpB.Width) or (BmpA.Height <> BmpB.Height) then
  begin
    ShowMessage(Format('Frame dimensions must match! Frame A is %dx%d, Frame B is %dx%d.',
      [BmpA.Width, BmpA.Height, BmpB.Width, BmpB.Height]));
    Exit;
  end;

  LogMsg('Analyzing motion and computing difference map...');
  
  Tracker.Threshold := StrToIntDef(edThreshold.Text, 15);
  Tracker.MinMotionPercent := StrToFloatDef(edMinMotion.Text, 1.5);
  
  TStart := Now;
  try
    MotionDetected := Tracker.DetectMotion(BmpA, BmpB);
    
    // Generate difference bitmap
    if DiffGen.GenerateDiffBitmap(BmpA, BmpB, BmpDiff) then
    begin
      imgFrameDiff.Picture.Assign(BmpDiff);
      lblInfoDiff.Caption := Format('Diff Frame: %dx%d', [BmpDiff.Width, BmpDiff.Height]);
    end;
    
    TEnd := Now;
    ElapsedMs := (TEnd - TStart) * 24.0 * 60.0 * 60.0 * 1000.0;
    
    if MotionDetected then
    begin
      lblResultMotion.Caption := 'Motion: DETECTED';
      lblResultMotion.Font.Color := clRed;
    end
    else
    begin
      lblResultMotion.Caption := 'Motion: NONE';
      lblResultMotion.Font.Color := clGreen;
    end;
    
    lblResultPercent.Caption := Format('Diff: %.3f%%', [Tracker.MotionPercent]);
    
    LogMsg(Format('Analysis completed in %.2f ms. Motion: %s (%.4f%% change, threshold: %s%%)', 
      [ElapsedMs, BoolToStr(MotionDetected, 'Yes', 'No'), Tracker.MotionPercent, edMinMotion.Text]));
  except
    on E: Exception do
    begin
      LogMsg('Error in analysis: ' + E.Message);
      ShowMessage('Error: ' + E.Message);
    end;
  end;
end;

procedure TfrmMotionDemo.btnSaveDiffClick(Sender: TObject);
begin
  if BmpDiff.Width = 0 then
  begin
    ShowMessage('No difference image has been generated.');
    Exit;
  end;

  if SaveDialog1.Execute then
  begin
    LogMsg('Saving difference image to: ' + SaveDialog1.FileName);
    try
      BmpDiff.SaveToFile(SaveDialog1.FileName);
      LogMsg('Saved successfully.');
    except
      on E: Exception do
      begin
        LogMsg('Error saving difference image: ' + E.Message);
        ShowMessage('Failed to save difference image: ' + E.Message);
      end;
    end;
  end;
end;

procedure TfrmMotionDemo.LogMsg(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
