unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiwebserver;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    grpConfig: TGroupBox;
    lblPort: TLabel;
    editPort: TEdit;
    grpActions: TGroupBox;
    btnStartServer: TButton;
    btnStopServer: TButton;
    btnClearLog: TButton;
    lblStatus: TLabel;
    memoLog: TMemo;
    AIWebAPIServer1: TAIWebAPIServer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnStartServerClick(Sender: TObject);
    procedure btnStopServerClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure OnAPIRequest(Sender: TObject; const ARoute, AMethod, AContent: string;
      out AResponse: string; out AResponseCode: Integer);
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
  AddLog('Web Server Demo initialized.');
  AddLog('Configure port and click "Start Web Server" to begin listening.');
  AIWebAPIServer1.OnRequestReceived := @OnAPIRequest;
  btnStartServer.Enabled := True;
  btnStopServer.Enabled := False;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(AIWebAPIServer1) then
    AIWebAPIServer1.StopServer;
end;

procedure TfrmMain.btnStartServerClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Starting Server...';
  AddLog('--- Starting Embedded HTTP Server ---');
  try
    AIWebAPIServer1.Port := StrToIntDef(editPort.Text, 8086);
    
    AddLog('Target Port: ' + IntToStr(AIWebAPIServer1.Port));
    
    if AIWebAPIServer1.StartServer then
    begin
      AddLog('SUCCESS: HTTP Server running on http://localhost:' + IntToStr(AIWebAPIServer1.Port));
      AddLog('Open your browser and test routes (e.g., http://localhost:' + IntToStr(AIWebAPIServer1.Port) + '/test)');
      lblStatus.Caption := 'Status: Web Server Running';
      btnStartServer.Enabled := False;
      btnStopServer.Enabled := True;
    end
    else
    begin
      AddLog('ERROR: Failed to start web server. Check port availability.');
      lblStatus.Caption := 'Status: Startup Failed';
    end;
  except
    on E: Exception do
    begin
      AddLog('Exception: ' + E.Message);
      lblStatus.Caption := 'Status: Server Exception';
    end;
  end;
  AddLog('-------------------------------------');
end;

procedure TfrmMain.btnStopServerClick(Sender: TObject);
begin
  AddLog('Stopping Web Server...');
  AIWebAPIServer1.StopServer;
  btnStartServer.Enabled := True;
  btnStopServer.Enabled := False;
  lblStatus.Caption := 'Status: Server Stopped';
  AddLog('Web Server stopped.');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.OnAPIRequest(Sender: TObject; const ARoute, AMethod, AContent: string;
  out AResponse: string; out AResponseCode: Integer);
begin
  AddLog(Format('[HTTP REQUEST] Route: "%s" | Method: "%s" | ContentLength: %d', 
    [ARoute, AMethod, Length(AContent)]));
  if AContent <> '' then
    AddLog('  Body: ' + AContent);
    
  AResponse := '{"status": "ok", "route": "' + ARoute + '", "method": "' + AMethod + '", "message": "Request processed successfully by Lazarus Embedded Web Server"}';
  AResponseCode := 200;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
