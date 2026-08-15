unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aimqtt;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblHost: TLabel;
    cmbBroker: TComboBox;
    lblPort: TLabel;
    edtPort: TEdit;
    lblClientID: TLabel;
    edtClientID: TEdit;
    btnGenID: TButton;
    lblKeepAlive: TLabel;
    edtKeepAlive: TEdit;
    btnConnect: TButton;
    btnDisconnect: TButton;
    btnPing: TButton;
    lblStatus: TLabel;
    pnlMain: TPanel;
    pnlLeft: TPanel;
    grpSubscribe: TGroupBox;
    lblSubTopic: TLabel;
    edtSubTopic: TEdit;
    btnSubscribe: TButton;
    lblSubList: TLabel;
    lstSubscriptions: TListBox;
    grpPublish: TGroupBox;
    lblPubTopic: TLabel;
    edtPubTopic: TEdit;
    lblPayload: TLabel;
    memoPayload: TMemo;
    btnPubTelemetry: TButton;
    btnPublish: TButton;
    lblPubHelp: TLabel;
    pnlRight: TPanel;
    grpReceived: TGroupBox;
    memoReceived: TMemo;
    btnClearReceived: TButton;
    grpLog: TGroupBox;
    memoLog: TMemo;
    pnlLogBottom: TPanel;
    btnClearLog: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGenIDClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnPingClick(Sender: TObject);
    procedure btnSubscribeClick(Sender: TObject);
    procedure btnPublishClick(Sender: TObject);
    procedure btnPubTelemetryClick(Sender: TObject);
    procedure btnClearReceivedClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIMQTT: TAIMQTTClient;
    procedure AddLog(const AMsg: string);
    procedure SetConnectedUI(AConnected: Boolean);
    procedure OnMQTTConnected(Sender: TObject);
    procedure OnMQTTDisconnected(Sender: TObject);
    procedure OnMQTTMessageReceived(Sender: TObject; const ATopic, APayload: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Randomize;
  AddLog('Inicializando demonstração do componente TAIMQTTClient...');
  
  btnGenIDClick(nil);
  
  FAIMQTT := TAIMQTTClient.Create(Self);
  FAIMQTT.OnConnected := @OnMQTTConnected;
  FAIMQTT.OnDisconnected := @OnMQTTDisconnected;
  FAIMQTT.OnMessageReceived := @OnMQTTMessageReceived;
  
  SetConnectedUI(False);
  AddLog('Pronto. Selecione o broker e clique em "Conectar Broker".');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if (FAIMQTT <> nil) and FAIMQTT.Active then
    FAIMQTT.DisconnectBroker;
end;

procedure TfrmMain.btnGenIDClick(Sender: TObject);
begin
  edtClientID.Text := 'LazarusAI_' + IntToHex(Random($FFFFFF), 6);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('[hh:nn:ss] ', Now) + AMsg);
end;

procedure TfrmMain.SetConnectedUI(AConnected: Boolean);
begin
  btnConnect.Enabled := not AConnected;
  cmbBroker.Enabled := not AConnected;
  edtPort.Enabled := not AConnected;
  edtClientID.Enabled := not AConnected;
  btnGenID.Enabled := not AConnected;
  edtKeepAlive.Enabled := not AConnected;
  
  btnDisconnect.Enabled := AConnected;
  btnPing.Enabled := AConnected;
  btnSubscribe.Enabled := AConnected;
  btnPublish.Enabled := AConnected;
  
  if AConnected then
  begin
    lblStatus.Caption := 'Status: Conectado ao Broker (' + FAIMQTT.Host + ':' + IntToStr(FAIMQTT.Port) + ')';
    lblStatus.Font.Color := clGreen;
  end
  else
  begin
    lblStatus.Caption := 'Status: Desconectado';
    lblStatus.Font.Color := clRed;
  end;
end;

procedure TfrmMain.OnMQTTConnected(Sender: TObject);
begin
  SetConnectedUI(True);
  AddLog('>>> [EVENTO OnConnected] Conexão estabelecida com sucesso!');
end;

procedure TfrmMain.OnMQTTDisconnected(Sender: TObject);
begin
  SetConnectedUI(False);
  AddLog('>>> [EVENTO OnDisconnected] Conexão com o broker encerrada.');
end;

procedure TfrmMain.OnMQTTMessageReceived(Sender: TObject; const ATopic, APayload: string);
var
  HeaderMsg: string;
begin
  HeaderMsg := Format('=== [%s] Tópico: %s ===', [FormatDateTime('hh:nn:ss.zzz', Now), ATopic]);
  memoReceived.Lines.Add(HeaderMsg);
  memoReceived.Lines.Add(APayload);
  memoReceived.Lines.Add('');
  AddLog('<<< [MENSAGEM RECEBIDA] Tópico: ' + ATopic + ' (' + IntToStr(Length(APayload)) + ' bytes)');
end;

procedure TfrmMain.btnConnectClick(Sender: TObject);
begin
  FAIMQTT.Host := Trim(cmbBroker.Text);
  FAIMQTT.Port := StrToIntDef(edtPort.Text, 1883);
  FAIMQTT.ClientID := Trim(edtClientID.Text);
  FAIMQTT.KeepAlive := StrToIntDef(edtKeepAlive.Text, 60);

  AddLog(Format('Conectando ao broker MQTT "%s:%d" com ClientID "%s"...',
    [FAIMQTT.Host, FAIMQTT.Port, FAIMQTT.ClientID]));
  
  lblStatus.Caption := 'Status: Conectando...';
  lblStatus.Font.Color := clNavy;
  Application.ProcessMessages;

  try
    if FAIMQTT.ConnectBroker then
    begin
      AddLog('Pacote CONNECT enviado com sucesso.');
    end
    else
    begin
      AddLog('Falha na conexão: ' + FAIMQTT.LastError);
      SetConnectedUI(False);
    end;
  except
    on E: Exception do
    begin
      AddLog('Exceção ao conectar: ' + E.Message);
      SetConnectedUI(False);
    end;
  end;
end;

procedure TfrmMain.btnDisconnectClick(Sender: TObject);
begin
  AddLog('Desconectando do broker...');
  try
    FAIMQTT.DisconnectBroker;
  finally
    SetConnectedUI(False);
  end;
end;

procedure TfrmMain.btnPingClick(Sender: TObject);
begin
  if FAIMQTT.Ping then
    AddLog('>>> [PINGREQ] Pacote de KeepAlive enviado ao broker.')
  else
    AddLog('Falha ao enviar Ping ao broker.');
end;

procedure TfrmMain.btnSubscribeClick(Sender: TObject);
var
  Topic: string;
begin
  Topic := Trim(edtSubTopic.Text);
  if Topic = '' then
  begin
    ShowMessage('Informe um tópico para assinar.');
    Exit;
  end;

  AddLog('Enviando SUBSCRIBE para o tópico: ' + Topic);
  if FAIMQTT.Subscribe(Topic) then
  begin
    if lstSubscriptions.Items.IndexOf(Topic) < 0 then
      lstSubscriptions.Items.Add(Topic);
    AddLog('Assinatura registrada no broker para: ' + Topic);
  end
  else
    AddLog('Erro ao assinar tópico: ' + FAIMQTT.LastError);
end;

procedure TfrmMain.btnPublishClick(Sender: TObject);
var
  Topic, Payload: string;
begin
  Topic := Trim(edtPubTopic.Text);
  Payload := memoPayload.Text;
  
  if Topic = '' then
  begin
    ShowMessage('Informe um tópico de publicação.');
    Exit;
  end;

  AddLog('Publicando no tópico "' + Topic + '" (' + IntToStr(Length(Payload)) + ' bytes)...');
  if FAIMQTT.Publish(Topic, Payload) then
    AddLog('Mensagem publicada com sucesso.')
  else
    AddLog('Erro na publicação: ' + FAIMQTT.LastError);
end;

procedure TfrmMain.btnPubTelemetryClick(Sender: TObject);
var
  Temp, Humidity, Pressure: Double;
begin
  Temp := 20.0 + Random(150) / 10.0;
  Humidity := 40.0 + Random(400) / 10.0;
  Pressure := 1010.0 + Random(200) / 10.0;

  memoPayload.Lines.Clear;
  memoPayload.Lines.Add('{');
  memoPayload.Lines.Add(Format('  "dispositivo": "%s",', [edtClientID.Text]));
  memoPayload.Lines.Add(Format('  "temperatura_c": %.1f,', [Temp]));
  memoPayload.Lines.Add(Format('  "umidade_pct": %.1f,', [Humidity]));
  memoPayload.Lines.Add(Format('  "pressao_hpa": %.1f,', [Pressure]));
  memoPayload.Lines.Add(Format('  "timestamp": "%s"', [FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now)]));
  memoPayload.Lines.Add('}');
  AddLog('Nova carga de telemetria gerada no editor.');
end;

procedure TfrmMain.btnClearReceivedClick(Sender: TObject);
begin
  memoReceived.Clear;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

end.
