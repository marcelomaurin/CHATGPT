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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnFetchClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIEmail: TAIEmailClient;
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
  FAIEmail := TAIEmailClient.Create(Self);
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
    FAIEmail.HostSMTP := editHostSMTP.Text;
    FAIEmail.PortSMTP := StrToIntDef(editPortSMTP.Text, 25);
    FAIEmail.Username := editUser.Text;
    FAIEmail.Password := editPass.Text;

    AddLog('SMTP Target Server: ' + FAIEmail.HostSMTP + ':' + IntToStr(FAIEmail.PortSMTP));
    AddLog('SMTP User: ' + FAIEmail.Username);
    AddLog('Sending to: ' + editTo.Text);

    if FAIEmail.SendEmail(editTo.Text, 'Test Subject from Lazarus AI Suite', 'Hello! This is a test email sent in real-time from the Lazarus AI Suite.') then
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
    FAIEmail.HostPOP3 := editHostPOP3.Text;
    FAIEmail.PortPOP3 := StrToIntDef(editPortPOP3.Text, 110);
    FAIEmail.Username := editUser.Text;
    FAIEmail.Password := editPass.Text;

    AddLog('POP3 Target Server: ' + FAIEmail.HostPOP3 + ':' + IntToStr(FAIEmail.PortPOP3));
    AddLog('POP3 User: ' + FAIEmail.Username);

    if FAIEmail.FetchEmails(Emails) then
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
