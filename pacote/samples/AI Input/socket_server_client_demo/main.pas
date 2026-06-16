unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aisockets;

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
    FAISocketServer: TAISocketTCP; FAISocketClient: TAISocketTCP; FEditPort: TEdit;
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
  AddLog('Socket Server Client Demo (aisockets) initialized.');
  FAISocketServer := TAISocketTCP.Create(Self);
  FAISocketClient := TAISocketTCP.Create(Self);
  
  FEditPort := TEdit.Create(Self);
  FEditPort.Parent := pnlTop;
  FEditPort.Left := 15;
  FEditPort.Top := 115;
  FEditPort.Width := 100;
  FEditPort.Text := '8085';
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
  FAISocketServer.Port := StrToInt(FEditPort.Text);
  FAISocketClient.Host := '127.0.0.1';
  FAISocketClient.Port := StrToInt(FEditPort.Text);
  
  AddLog('Socket TCP Server/Client Properties:');
  AddLog('  Server Port: ' + IntToStr(FAISocketServer.Port));
  AddLog('  Client Host: ' + FAISocketClient.Host);
  
  if chkSimulation.Checked then
  begin
    AddLog('Simulating TCP Server/Client flow...');
    AddLog('TCP Server listening on port ' + FEditPort.Text);
    AddLog('TCP Client connected to ' + FAISocketClient.Host + ':' + FEditPort.Text);
    AddLog('Client Sent: "Hello Server!"');
    AddLog('Server Received: "Hello Server!"');
    AddLog('Server Sent: "Welcome Client!"');
    AddLog('Client Received: "Welcome Client!"');
    AddLog('Simulated Socket communication SUCCESS.');
  end
  else
  begin
    AddLog('Opening real socket server and client connection...');
    try
      if FAISocketServer.Listen then
      begin
        AddLog('Server is listening.');
        if FAISocketClient.Connect then
        begin
          AddLog('Client connected.');
          FAISocketClient.SendString('Hello Server!');
          Sleep(100);
          FAISocketClient.Disconnect;
          AddLog('Client disconnected.');
        end;
        FAISocketServer.Stop;
        AddLog('Server stopped.');
      end
      else
        AddLog('Server failed to listen.');
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
