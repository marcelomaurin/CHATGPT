unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aiemail;

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
    FAIEmail: TAIEmailClient; FEditHost: TEdit; FEditUser: TEdit;
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
  AddLog('Email Classifier Demo (aiemail) initialized.');
  FAIEmail := TAIEmailClient.Create(Self);
  
  FEditHost := TEdit.Create(Self);
  FEditHost.Parent := pnlTop;
  FEditHost.Left := 15;
  FEditHost.Top := 115;
  FEditHost.Width := 200;
  FEditHost.Text := 'mail.server.com';
  
  FEditUser := TEdit.Create(Self);
  FEditUser.Parent := pnlTop;
  FEditUser.Left := 230;
  FEditUser.Top := 115;
  FEditUser.Width := 150;
  FEditUser.Text := 'user@server.com';
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
  FAIEmail.HostSMTP := FEditHost.Text;
  FAIEmail.HostPOP3 := FEditHost.Text;
  FAIEmail.Username := FEditUser.Text;
  FAIEmail.Password := 'password';
  
  AddLog('Email Ingestion Properties:');
  AddLog('  SMTP Server: ' + FAIEmail.HostSMTP);
  AddLog('  POP3 Server: ' + FAIEmail.HostPOP3);
  AddLog('  User: ' + FAIEmail.Username);
  
  if chkSimulation.Checked then
  begin
    AddLog('Running in Simulated Ingestion Mode...');
    AddLog('Fetched 3 new emails:');
    AddLog('  1. Subject: "Alert: Server Disk Space 92%" -> Class: Urgent Support');
    AddLog('  2. Subject: "Invoices for May" -> Class: Billing');
    AddLog('  3. Subject: "Win a new smartphone today!" -> Class: Spam');
    AddLog('Fetch completed (Simulated).');
  end
  else
  begin
    AddLog('Connecting to: ' + FAIEmail.HostPOP3);
    try
      // Method SendEmail / FetchEmails
      if FAIEmail.SendEmail('receiver@test.com', 'Test Subject', 'Body text') then
        AddLog('Sent test email successfully.')
      else
        AddLog('Failed to send email. Check configuration/server.');
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
