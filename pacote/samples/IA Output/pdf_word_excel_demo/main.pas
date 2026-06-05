unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aioutput_docs;

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
    FPDFOut: TAIPDFOutput; FWordOut: TAIWordOutput; FExcelOut: TAIExcelOutput;
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
  AddLog('Pdf Word Excel Demo (aioutput_docs) initialized.');
  FPDFOut := TAIPDFOutput.Create(Self);
  FWordOut := TAIWordOutput.Create(Self);
  FExcelOut := TAIExcelOutput.Create(Self);
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
  FPDFOut.FileName := 'output_report.pdf';
  FWordOut.FileName := 'output_report.docx';
  FExcelOut.FileName := 'output_report.xlsx';
  
  AddLog('Document Outputs Properties:');
  AddLog('  PDF File Name: ' + FPDFOut.FileName);
  AddLog('  Word File Name: ' + FWordOut.FileName);
  AddLog('  Excel File Name: ' + FExcelOut.FileName);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Document Generation...');
    AddLog('Generated PDF structure: 1 Page, 3 paragraphs.');
    AddLog('Generated Word document structure: Standard XML docx template.');
    AddLog('Generated Excel document structure: 2 sheets, 10 columns.');
    AddLog('All files saved to workspace output (Simulated).');
  end
  else
  begin
    AddLog('Saving actual files...');
    try
      if FPDFOut.SaveDocument then
        AddLog('PDF generated successfully.')
      else
        AddLog('PDF failed to write.');
      if FWordOut.SaveDocument then
        AddLog('Word generated successfully.')
      else
        AddLog('Word failed to write.');
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
