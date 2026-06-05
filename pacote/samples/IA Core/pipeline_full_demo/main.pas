unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aipipeline, chatgpt, aioutput, aioutput_docs;

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
    FAIPipeline: TAIPipeline; FChatGPT: TCHATGPT; FAIOutput: TAIOutputData; FAIOutputDocs: TAIOutputDocs; FEditInput: TEdit;
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
  AddLog('Pipeline Full Demo (aipipeline) initialized.');
  FChatGPT := TCHATGPT.Create(Self);
  FAIOutput := TAIOutputData.Create(Self);
  FAIOutputDocs := TAIOutputDocs.Create(Self);
  
  FAIPipeline := TAIPipeline.Create(Self);
  FAIPipeline.ChatGPT := FChatGPT;
  FAIPipeline.OutputData := FAIOutput;
  FAIPipeline.OutputDocs := FAIOutputDocs;
  
  FEditInput := TEdit.Create(Self);
  FEditInput.Parent := pnlTop;
  FEditInput.Left := 15;
  FEditInput.Top := 115;
  FEditInput.Width := 300;
  FEditInput.Text := 'Generate a weekly production report';
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
  FAIPipeline.Mode := pmTextLLM;
  FAIPipeline.InputText := FEditInput.Text;
  FAIPipeline.SaveTXT := True;
  FAIPipeline.SavePDF := False;
  FAIPipeline.BaseFileName := 'pipeline_out';
  
  AddLog('Pipeline properties set.');
  AddLog('  Mode: pmTextLLM');
  AddLog('  InputText: ' + FAIPipeline.InputText);
  AddLog('  BaseFileName: ' + FAIPipeline.BaseFileName);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating pipeline execution...');
    FAIPipeline.OutputText := 'Report generated: Weekly production is normal. Efficiency at 98.2%.';
    AddLog('OutputText: ' + FAIPipeline.OutputText);
    AddLog('Pipeline Run completed successfully (Simulated).');
  end
  else
  begin
    AddLog('Running actual text LLM pipeline step...');
    if FAIPipeline.Run then
      AddLog('Pipeline execution success. Output: ' + FAIPipeline.OutputText)
    else
      AddLog('Pipeline execution failed: ' + FAIPipeline.LastError);
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
