unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, soundfilters;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    chkSimulation: TCheckBox;
    btnRun: TButton;
    btnClearLog: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FLowPass: TLowPassFilter; FHighPass: THighPassFilter; FAverage: TAverageFilter; FEditFile: TEdit;
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Sound Filters Visual Demo (soundfilters) initialized.');
  FLowPass := TLowPassFilter.Create(Self);
  FHighPass := THighPassFilter.Create(Self);
  FAverage := TAverageFilter.Create(Self);
  
  FEditFile := TEdit.Create(Self);
  FEditFile.Parent := pnlTop;
  FEditFile.Left := 15;
  FEditFile.Top := 115;
  FEditFile.Width := 300;
  FEditFile.Text := 'audio.wav';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
  FLowPass.CutoffFrequency := 4000;
  FHighPass.CutoffFrequency := 12000;
  FAverage.WindowSize := 5;
  
  AddLog('Sound Filters Properties:');
  AddLog('  LowPass Cutoff: 4000 Hz');
  AddLog('  HighPass Cutoff: 12000 Hz');
  AddLog('  Average Window: 5');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating sound filter convolution pass...');
    AddLog('Loading: ' + FEditFile.Text);
    // Call methods
    FLowPass.ApplyFilter(FEditFile.Text, 'lowpass_out.wav');
    AddLog('Low-pass cutoff filter applied. Output saved: lowpass_out.wav');
    FHighPass.ApplyFilter(FEditFile.Text, 'highpass_out.wav');
    AddLog('High-pass cutoff filter applied. Output saved: highpass_out.wav');
    AddLog('Filter operations successful.');
  end
  else
  begin
    AddLog('Executing filters on ' + FEditFile.Text);
    try
      FLowPass.ApplyFilter(FEditFile.Text, 'lowpass_out.wav');
      AddLog('LowPass filter completed.');
    except
      on E: Exception do AddLog('Exception: ' + E.Message);
    end;
  end;
    lblStatus.Caption := 'Status: Completed Successfully';
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;
  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
end;

end.
