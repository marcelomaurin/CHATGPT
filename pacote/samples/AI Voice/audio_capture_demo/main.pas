unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiaudio;

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
    FAIAudio: TAIAudioInput; FEditFile: TEdit;
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
  AddLog('Audio Capture Demo (aiaudio) initialized.');
  FAIAudio := TAIAudioInput.Create(Self);
  
  FEditFile := TEdit.Create(Self);
  FEditFile.Parent := pnlTop;
  FEditFile.Left := 15;
  FEditFile.Top := 115;
  FEditFile.Width := 300;
  FEditFile.Text := 'voice_rec.wav';
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
  FAIAudio.SampleRate := 16000;
  FAIAudio.Channels := 1;
  
  AddLog('Audio Capture Properties:');
  AddLog('  SampleRate: ' + IntToStr(FAIAudio.SampleRate));
  AddLog('  Channels: ' + IntToStr(FAIAudio.Channels));
  AddLog('  OutputFile: ' + FEditFile.Text);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating audio mic recording...');
    FAIAudio.StartRecord(FEditFile.Text);
    AddLog('Audio recording active. Ingesting stream...');
    Sleep(500);
    FAIAudio.StopRecord;
    AddLog('Audio recording finished. Saved WAV file to ' + FEditFile.Text + ' (Simulated).');
  end
  else
  begin
    AddLog('Opening real audio capture handle...');
    try
      FAIAudio.StartRecord(FEditFile.Text);
      if FAIAudio.Recording then
      begin
        Sleep(500);
        FAIAudio.StopRecord;
        AddLog('Recording complete.');
      end
      else
        AddLog('Audio card device not connected.');
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
