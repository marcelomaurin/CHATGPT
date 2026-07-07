unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiemail;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    grpConfig: TGroupBox;
    grpActions: TGroupBox;
    lblTitle: TLabel;
    lblHostSMTP: TLabel;
    editHostSMTP: TEdit;
    lblPortSMTP: TLabel;
    editPortSMTP: TEdit;
    lblHostPOP3: TLabel;
    editHostPOP3: TEdit;
    lblPortPOP3: TLabel;
    editPortPOP3: TEdit;
    lblUser: TLabel;
    editUser: TEdit;
    lblPass: TLabel;
    editPass: TEdit;
    lblTo: TLabel;
    editTo: TEdit;
    btnSend: TButton;
    btnFetch: TButton;
    btnClearLog: TButton;
    lblStatus: TLabel;
    memoLog: TMemo;
    AIEmailClient1: TAIEmailClient;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnFetchClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
    function ClassifyEmailText(const ASubject: string): string;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Email Client & Classifier Demo initialized.');
  AddLog('Please configure your SMTP/POP3 settings above.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Managed by owner auto-free
end;

function TfrmMain.ClassifyEmailText(const ASubject: string): string;
var
  S: string;
begin
  S := LowerCase(ASubject);
  if (Pos('urgent', S) > 0) or (Pos('alerta', S) > 0) or (Pos('urgente', S) > 0) or (Pos('critico', S) > 0) then
    Result := 'URGENT SUPPORT'
  else if (Pos('invoice', S) > 0) or (Pos('fatura', S) > 0) or (Pos('pagamento', S) > 0) or (Pos('cobranca', S) > 0) or (Pos('boleto', S) > 0) then
    Result := 'BILLING / INVOICE'
  else if (Pos('win', S) > 0) or (Pos('promo', S) > 0) or (Pos('oferta', S) > 0) or (Pos('desconto', S) > 0) or (Pos('sorteio', S) > 0) or (Pos('gratis', S) > 0) then
    Result := 'SPAM / ADVERTISING'
  else
    Result := 'GENERAL INQUIRY';
end;

procedure TfrmMain.btnSendClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Sending Email...';
  AddLog('--- Sending Test Email ---');
  try
    AIEmailClient1.HostSMTP := editHostSMTP.Text;
    AIEmailClient1.PortSMTP := StrToIntDef(editPortSMTP.Text, 25);
    AIEmailClient1.Username := editUser.Text;
    AIEmailClient1.Password := editPass.Text;

    AddLog('SMTP Target Server: ' + AIEmailClient1.HostSMTP + ':' + IntToStr(AIEmailClient1.PortSMTP));
    AddLog('SMTP User: ' + AIEmailClient1.Username);
    AddLog('Sending to: ' + editTo.Text);

    if AIEmailClient1.SendEmail(editTo.Text, 'Test Subject from Lazarus AI Suite', 'Hello! This is a test email sent in real-time from the Lazarus AI Suite.') then
    begin
      AddLog('SUCCESS: Email sent successfully!');
      lblStatus.Caption := 'Status: Email Sent successfully';
    end
    else
    begin
      AddLog('ERROR: Failed to send email. Check SMTP server parameters, authentication, or network port.');
      lblStatus.Caption := 'Status: Sending Failed';
    end;
  except
    on E: Exception do
    begin
      AddLog('Exception: ' + E.Message);
      lblStatus.Caption := 'Status: SMTP Exception';
    end;
  end;
  AddLog('--------------------------');
end;

procedure TfrmMain.btnFetchClick(Sender: TObject);
var
  Emails: TStrings;
  I: Integer;
  EmailLine: string;
  Classification: string;
begin
  lblStatus.Caption := 'Status: Fetching Emails...';
  AddLog('--- Fetching & Classifying Emails ---');
  Emails := nil;
  try
    AIEmailClient1.HostPOP3 := editHostPOP3.Text;
    AIEmailClient1.PortPOP3 := StrToIntDef(editPortPOP3.Text, 110);
    AIEmailClient1.Username := editUser.Text;
    AIEmailClient1.Password := editPass.Text;

    AddLog('POP3 Target Server: ' + AIEmailClient1.HostPOP3 + ':' + IntToStr(AIEmailClient1.PortPOP3));
    AddLog('POP3 User: ' + AIEmailClient1.Username);

    if AIEmailClient1.FetchEmails(Emails) then
    begin
      if Assigned(Emails) then
      begin
        AddLog('Connection Successful! Fetched ' + IntToStr(Emails.Count) + ' email headers.');
        for I := 0 to Emails.Count - 1 do
        begin
          EmailLine := Emails[I];
          Classification := ClassifyEmailText(EmailLine);
          AddLog(Format('%s => Classification: [%s]', [EmailLine, Classification]));
        end;
        Emails.Free;
      end;
      lblStatus.Caption := 'Status: Fetch && Classify Completed';
    end
    else
    begin
      AddLog('ERROR: Failed to fetch emails from POP3 server. Check connection details, credentials, or network port.');
      lblStatus.Caption := 'Status: Fetch Failed';
    end;
  except
    on E: Exception do
    begin
      AddLog('Exception: ' + E.Message);
      lblStatus.Caption := 'Status: POP3 Exception';
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
