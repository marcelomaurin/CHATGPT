unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aisockets;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    grpServer: TGroupBox;
    lblServerPort: TLabel;
    editServerPort: TEdit;
    grpClient: TGroupBox;
    lblClientHost: TLabel;
    editClientHost: TEdit;
    lblClientPort: TLabel;
    editClientPort: TEdit;
    grpActions: TGroupBox;
    btnStartServer: TButton;
    btnConnectClient: TButton;
    btnStopAll: TButton;
    btnClearLog: TButton;
    lblStatus: TLabel;
    lblCustomText: TLabel;
    editCustomText: TEdit;
    memoLog: TMemo;
    AISocketServer: TAISocketTCP;
    AISocketClient: TAISocketTCP;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartServerClick(Sender: TObject);
    procedure btnConnectClientClick(Sender: TObject);
    procedure btnStopAllClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure OnServerDataReceived(Sender: TObject; const AData: string; const AFromIP: string);
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
  AddLog('Socket TCP Server/Client Demo initialized.');
  AddLog('Please configure and start the server first.');
  AISocketServer.OnDataReceived := @OnServerDataReceived;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(AISocketClient) then
    AISocketClient.Disconnect;
  if Assigned(AISocketServer) then
    AISocketServer.Disconnect;
end;

procedure TfrmMain.btnStartServerClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Starting Server...';
  AddLog('--- Starting TCP Server ---');
  try
    AISocketServer.Port := StrToIntDef(editServerPort.Text, 8085);
    AISocketServer.Mode := smServer;
    
    AddLog('Server configuration: Port ' + IntToStr(AISocketServer.Port));
    
    if AISocketServer.Connect then
    begin
      AddLog('SUCCESS: TCP Server is listening in the background.');
      lblStatus.Caption := 'Status: Server Running';
      btnStartServer.Enabled := False;
    end
    else
    begin
      AddLog('ERROR: Failed to start TCP Server. Port may be in use.');
      lblStatus.Caption := 'Status: Start Server Failed';
    end;
  except
    on E: Exception do
    begin
      AddLog('Exception: ' + E.Message);
      lblStatus.Caption := 'Status: Server Exception';
    end;
  end;
  AddLog('---------------------------');
end;

procedure TfrmMain.btnConnectClientClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Client Connecting...';
  AddLog('--- Client: Connecting & Sending ---');
  try
    AISocketClient.Host := editClientHost.Text;
    AISocketClient.Port := StrToIntDef(editClientPort.Text, 8085);
    AISocketClient.Mode := smClient;
    
    AddLog('Connecting to: ' + AISocketClient.Host + ':' + IntToStr(AISocketClient.Port));
    
    if AISocketClient.Connect then
    begin
      AddLog('SUCCESS: TCP Client connected to server.');
      AddLog('Sending: "' + editCustomText.Text + '"');
      
      if AISocketClient.SendText(editCustomText.Text) then
        AddLog('Sent text successfully.')
      else
        AddLog('ERROR: Send failed.');
        
      AISocketClient.Disconnect;
      AddLog('Client disconnected.');
      lblStatus.Caption := 'Status: Client Sent Message';
    end
    else
    begin
      AddLog('ERROR: Client failed to connect to ' + AISocketClient.Host + ':' + IntToStr(AISocketClient.Port));
      lblStatus.Caption := 'Status: Connection Failed';
    end;
  except
    on E: Exception do
    begin
      AddLog('Exception: ' + E.Message);
      lblStatus.Caption := 'Status: Client Exception';
    end;
  end;
  AddLog('------------------------------------');
end;

procedure TfrmMain.btnStopAllClick(Sender: TObject);
begin
  AddLog('Stopping Server and disconnecting Client...');
  AISocketClient.Disconnect;
  AISocketServer.Disconnect;
  btnStartServer.Enabled := True;
  lblStatus.Caption := 'Status: Stopped';
  AddLog('All sockets stopped.');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.OnServerDataReceived(Sender: TObject; const AData: string; const AFromIP: string);
begin
  AddLog(Format('[SERVER RECEIVED] Data: "%s" from IP: %s', [AData, AFromIP]));
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
