unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiwebserver;

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
    FAIWebServer: TAIWebAPIServer; FEditPort: TEdit;
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
  AddLog('Webserver Demo (aiwebserver) initialized.');
  FAIWebServer := TAIWebAPIServer.Create(Self);
  
  FEditPort := TEdit.Create(Self);
  FEditPort.Parent := pnlTop;
  FEditPort.Left := 15;
  FEditPort.Top := 115;
  FEditPort.Width := 100;
  FEditPort.Text := '8086';
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
  FAIWebServer.Port := StrToInt(FEditPort.Text);
  FAIWebServer.Active := True;
  
  AddLog('Web Server Component Properties:');
  AddLog('  Port: ' + IntToStr(FAIWebServer.Port));
  AddLog('  Active: ' + BoolToStr(FAIWebServer.Active, True));
  
  if chkSimulation.Checked then
  begin
    AddLog('Running in Simulated Mode...');
    AddLog('Web API server listening on http://localhost:' + FEditPort.Text);
    AddLog('Method GetJSONEndpointResponse called: Returns standard OK status.');
    FAIWebServer.Active := False;
    AddLog('Server stopped.');
  end
  else
  begin
    AddLog('Starting real HTTP Web Server on port ' + FEditPort.Text);
    try
      if FAIWebServer.StartServer then
      begin
        AddLog('Web Server running. Press browser to test.');
        Sleep(1000);
        FAIWebServer.StopServer;
        AddLog('Web Server stopped.');
      end
      else
        AddLog('Failed to start server: ' + FAIWebServer.LastError);
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
