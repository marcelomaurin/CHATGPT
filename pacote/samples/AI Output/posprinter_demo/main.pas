unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiposprinter;

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
    FAIPosPrinter: TAIPOSPrinter; FEditAddr: TEdit;
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
  AddLog('Posprinter Demo (aiposprinter) initialized.');
  FAIPosPrinter := TAIPOSPrinter.Create(Self);
  
  FEditAddr := TEdit.Create(Self);
  FEditAddr.Parent := pnlTop;
  FEditAddr.Left := 15;
  FEditAddr.Top := 115;
  FEditAddr.Width := 200;
  FEditAddr.Text := '127.0.0.1';
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
  FAIPosPrinter.Host := FEditAddr.Text;
  FAIPosPrinter.Port := 9100;
  FAIPosPrinter.Active := True;
  
  AddLog('POS Printer Component Properties:');
  AddLog('  IP: ' + FAIPosPrinter.Host);
  AddLog('  Port: ' + IntToStr(FAIPosPrinter.Port));
  AddLog('  Active: ' + BoolToStr(FAIPosPrinter.Active, True));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating receipt command formulation...');
    AddLog('Receipt command formatted:');
    AddLog('  ESC @ (Initialize)');
    AddLog('  ESC a 1 (Align Center)');
    AddLog('  "DAILY PRODUCTION SUMMARY\n"');
    AddLog('  "-------------------------\n"');
    AddLog('  "Completed: 100 units\n"');
    AddLog('  GS v 0 (Print image / barcode)');
    AddLog('  GS V 66 (Cut paper)');
    AddLog('Receipt printed to simulated terminal buffer successfully.');
  end
  else
  begin
    AddLog('Sending RAW commands to POS printer at ' + FAIPosPrinter.Host + ':9100...');
    try
      if FAIPosPrinter.OpenConnection then
      begin
        FAIPosPrinter.PrintText('DAILY TEST SUCCESSFUL'#10);
        FAIPosPrinter.CutPaper;
        FAIPosPrinter.CloseConnection;
        AddLog('Printed successfully.');
      end
      else
        AddLog('Could not connect to printer: ' + FAIPosPrinter.LastError);
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
