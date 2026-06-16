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
    FAIOutputDocs: TAIOutputDocs; FEditTitle: TEdit;
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
  AddLog('Output Docs Demo (aioutput_docs) initialized.');
  FAIOutputDocs := TAIOutputDocs.Create(Self);
  
  FEditTitle := TEdit.Create(Self);
  FEditTitle.Parent := pnlTop;
  FEditTitle.Left := 15;
  FEditTitle.Top := 115;
  FEditTitle.Width := 300;
  FEditTitle.Text := 'Factory Incident Log Report';
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
  FAIOutputDocs.Title := FEditTitle.Text;
  FAIOutputDocs.Author := 'AI Agent System';
  FAIOutputDocs.Subject := 'Industrial Audit Log';
  
  AddLog('Output Document Properties:');
  AddLog('  Title: ' + FAIOutputDocs.Title);
  AddLog('  Author: ' + FAIOutputDocs.Author);
  
  // Methods to assemble structure
  FAIOutputDocs.Clear;
  FAIOutputDocs.AddHeading('Summary Audit Log', 1);
  FAIOutputDocs.AddParagraph('Date: ' + DateToStr(Now));
  FAIOutputDocs.AddParagraph('All mechanical nodes reported operational parameters within default variances.');
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating File Export...');
    AddLog('Export targets:');
    AddLog('  - PDF File: audit_report.pdf');
    AddLog('  - Word File: audit_report.docx');
    AddLog('  - Text File: audit_report.txt');
    AddLog('Simulated export successfully executed.');
  end
  else
  begin
    AddLog('Writing files locally...');
    try
      FAIOutputDocs.FileNameTXT := 'audit_report.txt';
      if FAIOutputDocs.SaveToTXT then
        AddLog('Saved to ' + FAIOutputDocs.FileNameTXT)
      else
        AddLog('Error saving document txt: ' + FAIOutputDocs.LastError);
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
