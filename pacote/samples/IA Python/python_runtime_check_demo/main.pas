unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aipythonruntime, pythonconnector;

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
    FAIPython: TAIPythonRuntime; FConnector: TPythonConnector; FEditExecutable: TEdit;
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
  AddLog('Python Runtime Check Demo (aipythonruntime) initialized.');
  FAIPython := TAIPythonRuntime.Create(Self);
  FConnector := TPythonConnector.Create(Self);
  FConnector.Runtime := FAIPython;
  
  FEditExecutable := TEdit.Create(Self);
  FEditExecutable.Parent := pnlTop;
  FEditExecutable.Left := 15;
  FEditExecutable.Top := 115;
  FEditExecutable.Width := 300;
  FEditExecutable.Text := 'python.exe';
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
  FAIPython.PythonExecutable := FEditExecutable.Text;
  FAIPython.AutoDetect := True;
  FConnector.TimeoutMs := 5000;
  
  AddLog('Python Runtime Properties:');
  AddLog('  PythonExecutable: ' + FAIPython.PythonExecutable);
  AddLog('  AutoDetect: ' + BoolToStr(FAIPython.AutoDetect, True));
  AddLog('  Connector Timeout: ' + IntToStr(FConnector.TimeoutMs));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating python runtime environment detection...');
    AddLog('Python version detected: 3.10.12 (64-bit)');
    AddLog('NumPy import check: OK (v1.23.5)');
    AddLog('OpenCV import check: OK (v4.7.0)');
    AddLog('External processes validation check: SUCCESS');
  end
  else
  begin
    AddLog('Checking system python executable: ' + FAIPython.PythonExecutable);
    try
      if FAIPython.DetectRuntime then
      begin
        AddLog('Runtime detected. Executable: ' + FAIPython.DetectedPath);
        if FConnector.TestConnection then
          AddLog('NumPy & OpenCV integration is functional.')
        else
          AddLog('Failed import validation test: ' + FConnector.LastError);
      end
      else
        AddLog('Python executable path not found or invalid: ' + FAIPython.LastError);
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
