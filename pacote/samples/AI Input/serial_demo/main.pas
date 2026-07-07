unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiserial;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    grpConfig: TGroupBox;
    lblPort: TLabel;
    editPort: TEdit;
    lblBaud: TLabel;
    editBaud: TEdit;
    grpActions: TGroupBox;
    lblCommand: TLabel;
    editCommand: TEdit;
    btnSendAT: TButton;
    btnClearLog: TButton;
    lblStatus: TLabel;
    memoLog: TMemo;
    AISerialModem1: TAISerialModem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSendATClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
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
  AddLog('Serial Demo initialized.');
  AddLog('Please configure your Serial Port settings above.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free
end;

procedure TfrmMain.btnSendATClick(Sender: TObject);
var
  Response: string;
begin
  lblStatus.Caption := 'Status: Connecting...';
  AddLog('--- Starting Serial Communication ---');
  try
    AISerialModem1.DeviceName := editPort.Text;
    AISerialModem1.BaudRate := StrToIntDef(editBaud.Text, 9600);

    AddLog('Target Port: ' + AISerialModem1.DeviceName);
    AddLog('Baud Rate: ' + IntToStr(AISerialModem1.BaudRate));
    AddLog('Sending Command: ' + editCommand.Text);

    if AISerialModem1.OpenPort then
    begin
      AddLog('SUCCESS: Serial port opened.');
      lblStatus.Caption := 'Status: Sending command...';
      
      if AISerialModem1.SendATCommand(editCommand.Text, Response) then
      begin
        AddLog('Sent command successfully.');
        AddLog('Response: ' + Response);
        lblStatus.Caption := 'Status: Execution Completed';
      end
      else
      begin
        AddLog('ERROR: Failed to receive expected response from device.');
        lblStatus.Caption := 'Status: Send Failed';
      end;
      
      AISerialModem1.ClosePort;
      AddLog('Serial port closed.');
    end
    else
    begin
      AddLog('ERROR: Failed to open serial port: ' + AISerialModem1.LastError);
      lblStatus.Caption := 'Status: Open Port Failed';
    end;
  except
    on E: Exception do
    begin
      AddLog('Exception: ' + E.Message);
      lblStatus.Caption := 'Status: Exception Occurred';
    end;
  end;
  AddLog('-------------------------------------');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
