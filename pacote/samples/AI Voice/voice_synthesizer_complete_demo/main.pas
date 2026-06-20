unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aivoicesynthesizer;

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
    FAIVoice: TAIVoiceSynthesizer; FEditSpeech: TEdit;
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
  AddLog('Voice Synthesizer Complete Demo (aivoicesynthesizer) initialized.');
  FAIVoice := TAIVoiceSynthesizer.Create(Self);
  
  FEditSpeech := TEdit.Create(Self);
  FEditSpeech.Parent := pnlTop;
  FEditSpeech.Left := 15;
  FEditSpeech.Top := 115;
  FEditSpeech.Width := 300;
  FEditSpeech.Text := 'Welcome to Lazarus AI Native Vision Suite.';
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
  FAIVoice.Rate := 0;
  FAIVoice.Volume := 100;
  FAIVoice.VoiceName := 'English-US-Male';
  
  AddLog('Voice Synthesizer Properties:');
  AddLog('  Rate: 0 (Normal)');
  AddLog('  Volume: 100');
  AddLog('  VoiceName: ' + FAIVoice.VoiceName);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Speech Synthesis to local audio device...');
    AddLog('Synthesizing: "' + FEditSpeech.Text + '"');
    // Call methods
    FAIVoice.Say(FEditSpeech.Text);
    AddLog('Synthesized voice waveform processed successfully (Simulated).');
  end
  else
  begin
    AddLog('Speaking actual sentence...');
    try
      FAIVoice.Say(FEditSpeech.Text);
      if FAIVoice.LastSuccess then
        AddLog('Speak finished.')
      else
        AddLog('Speech synthesis failed: ' + FAIVoice.LastError);
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
