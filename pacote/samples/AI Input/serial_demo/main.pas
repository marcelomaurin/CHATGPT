unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiserial, ailistserialdevices;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblPort: TLabel;
    cbPort: TComboBox;
    btnRefreshPorts: TButton;
    lblBaud: TLabel;
    cbBaud: TComboBox;
    btnConnect: TButton;
    btnDisconnect: TButton;
    lblStatus: TLabel;
    memoLog: TMemo;
    pnlBottom: TPanel;
    editSend: TEdit;
    btnSend: TButton;
    chkCRLF: TCheckBox;
    btnClearLog: TButton;
    tmrPoll: TTimer;
    AISerialModem1: TAISerialModem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRefreshPortsClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnSendClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure editSendKeyPress(Sender: TObject; var Key: Char);
    procedure tmrPollTimer(Sender: TObject);
  private
    FLister: TAIListSerialDevices;
    procedure AddLog(const AMsg: string);
    procedure RefreshPorts;
    procedure SerialConnect(Sender: TObject);
    procedure SerialDisconnect(Sender: TObject);
    procedure SerialRX(Sender: TObject; const AData: string);
    procedure SerialTX(Sender: TObject; const AData: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FLister := TAIListSerialDevices.Create(Self);
  FLister.ProbeOpenable := False;

  AISerialModem1.OnConnect := @SerialConnect;
  AISerialModem1.OnDisconnect := @SerialDisconnect;
  AISerialModem1.OnRXReceive := @SerialRX;
  AISerialModem1.OnTXSend := @SerialTX;

  cbBaud.ItemIndex := cbBaud.Items.IndexOf('9600');
  btnDisconnect.Enabled := False;
  btnSend.Enabled := False;
  lblStatus.Caption := 'Desconectado';
  AddLog('Terminal serial inicializado.');
  RefreshPorts;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  tmrPoll.Enabled := False;
  AISerialModem1.ClosePort;
end;

procedure TfrmMain.btnRefreshPortsClick(Sender: TObject);
begin
  RefreshPorts;
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  if cbPort.Text = '' then
  begin
    AddLog('ERRO: selecione uma porta.');
    Exit;
  end;

  AISerialModem1.DeviceName := cbPort.Text;
  AISerialModem1.BaudRate := StrToIntDef(cbBaud.Text, 9600);
  if not AISerialModem1.OpenPort then
    AddLog('ERRO: ' + AISerialModem1.LastError);
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
begin
  AISerialModem1.ClosePort;
end;

procedure TfrmMain.btnSendClick(Sender: TObject);
var
  S: string;
begin
  S := editSend.Text;
  if chkCRLF.Checked then
    S := S + #13#10;
  if AISerialModem1.WriteText(S) then
    editSend.Text := ''
  else
    AddLog('ERRO TX: ' + AISerialModem1.LastError);
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.editSendKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    btnSendClick(btnSend);
  end;
end;

procedure TfrmMain.tmrPollTimer(Sender: TObject);
begin
  AISerialModem1.Poll;
end;

procedure TfrmMain.RefreshPorts;
begin
  FLister.Refresh;
  FLister.GetDeviceNames(cbPort.Items);
  if cbPort.Items.Count > 0 then
    cbPort.ItemIndex := 0
  else
    AddLog('Nenhuma porta encontrada.');
end;

procedure TfrmMain.SerialConnect(Sender: TObject);
begin
  lblStatus.Caption := 'Conectado a ' + cbPort.Text;
  AddLog('*** Conectado ***');
  tmrPoll.Enabled := True;
  cbPort.Enabled := False;
  cbBaud.Enabled := False;
  btnRefreshPorts.Enabled := False;
  btnConnect.Enabled := False;
  btnDisconnect.Enabled := True;
  btnSend.Enabled := True;
  editSend.SetFocus;
end;

procedure TfrmMain.SerialDisconnect(Sender: TObject);
begin
  lblStatus.Caption := 'Desconectado';
  AddLog('*** Desconectado ***');
  tmrPoll.Enabled := False;
  cbPort.Enabled := True;
  cbBaud.Enabled := True;
  btnRefreshPorts.Enabled := True;
  btnConnect.Enabled := True;
  btnDisconnect.Enabled := False;
  btnSend.Enabled := False;
end;

procedure TfrmMain.SerialRX(Sender: TObject; const AData: string);
begin
  AddLog('RX <= ' + AData);
end;

procedure TfrmMain.SerialTX(Sender: TObject; const AData: string);
begin
  AddLog('TX => ' + TrimRight(AData));
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
