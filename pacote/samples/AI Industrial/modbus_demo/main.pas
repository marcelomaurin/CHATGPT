unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, aibase, aimodbus;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    cbSerial: TComboBox;
    Label1: TLabel;
    memoLog: TMemo;
    PageControl1: TPageControl;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    tsMapaPinout: TTabSheet;
    tsOper: TTabSheet;
    tsLog: TTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIModbus: TAIModbusClient; FEditIP: TEdit; FEditRegister: TEdit;
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
  AddLog('Modbus Demo (aimodbus) initialized.');
  FAIModbus := TAIModbusClient.Create(Self);
  
  FEditIP := TEdit.Create(Self);
  FEditIP.Parent := pnlTop;
  FEditIP.Left := 15;
  FEditIP.Top := 115;
  FEditIP.Width := 200;
  FEditIP.Text := '192.168.1.100';
  
  FEditRegister := TEdit.Create(Self);
  FEditRegister.Parent := pnlTop;
  FEditRegister.Left := 230;
  FEditRegister.Top := 115;
  FEditRegister.Width := 100;
  FEditRegister.Text := '40001';
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
  FAIModbus.IPAddress := FEditIP.Text;
  FAIModbus.Port := 502;
  
  AddLog('Modbus TCP Client Properties:');
  AddLog('  IPAddress: ' + FAIModbus.IPAddress);
  AddLog('  Port: ' + IntToStr(FAIModbus.Port));
  

    AddLog('Connecting to physical PLC Modbus endpoint: ' + FAIModbus.IPAddress);
    try
      if FAIModbus.Connect then
      begin
        AddLog('TCP Modbus Link Connected.');
        // Read/Write operations
        FAIModbus.Disconnect;
        AddLog('Disconnected.');
      end
      else
        AddLog('Failed to connect: ' + FAIModbus.LastError);
    except
      on E: Exception do AddLog('Exception: ' + E.Message);
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
