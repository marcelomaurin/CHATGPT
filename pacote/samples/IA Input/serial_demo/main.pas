unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiserial;

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
    FAISerial: TAISerialModem; FEditPort: TEdit;
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
  AddLog('Serial Demo (aiserial) initialized.');
  FAISerial := TAISerialModem.Create(Self);
  
  FEditPort := TEdit.Create(Self);
  FEditPort.Parent := pnlTop;
  FEditPort.Left := 15;
  FEditPort.Top := 115;
  FEditPort.Width := 150;
  FEditPort.Text := 'COM3';
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
  FAISerial.Port := FEditPort.Text;
  FAISerial.BaudRate := 9600;
  FAISerial.Prompt := 'Serial communication';
  
  AddLog('Serial Component Properties:');
  AddLog('  Port: ' + FAISerial.Port);
  AddLog('  BaudRate: ' + IntToStr(FAISerial.BaudRate));
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating Connection...');
    AddLog('Connected to Port: ' + FAISerial.Port);
    // Method 1: Send Data
    AddLog('Sent command AT to Port');
    // Method 2: Receive Data
    AddLog('Received response: OK');
    AddLog('Simulation complete.');
  end
  else
  begin
    AddLog('Connecting to physical serial port: ' + FAISerial.Port);
    try
      if FAISerial.OpenConnection then
      begin
        AddLog('Connection opened.');
        FAISerial.WriteData('AT'#13#10);
        AddLog('Sent: AT');
        Sleep(200);
        AddLog('Received: ' + FAISerial.ReadData);
        FAISerial.CloseConnection;
        AddLog('Connection closed.');
      end
      else
        AddLog('Connection failed: ' + FAISerial.LastError);
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
