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
    lblCustomHost: TLabel;
    edtHost: TEdit;
    lblPort: TLabel;
    edtPort: TEdit;
    lblClientID: TLabel;
    edtClientID: TEdit;
    btnGenID: TButton;
    lblUsername: TLabel;
    edtUsername: TEdit;
    lblPassword: TLabel;
    edtPassword: TEdit;
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
    AIMQTTClient1: TAIMQTTClient;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cmbBrokerChange(Sender: TObject);
    procedure btnGenIDClick(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure btnPingClick(Sender: TObject);
    procedure btnSubscribeClick(Sender: TObject);
    procedure btnPublishClick(Sender: TObject);
    procedure btnPubTelemetryClick(Sender: TObject);
    procedure btnClearReceivedClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure OnMQTTConnected(Sender: TObject);
    procedure OnMQTTDisconnected(Sender: TObject);
    procedure OnMQTTMessageReceived(Sender: TObject; const ATopic, APayload: string);
    procedure AIMQTTClient1Log(Sender: TObject; Level: TAILogLevel; const Message: string);
  private
    procedure AddLog(const AMsg: string);
    procedure SetConnectedUI(AConnected: Boolean);
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
  AddLog('Inicializando demonstração do componente TAIMQTTClient (test.mosquitto.org)...');
  
  btnGenIDClick(nil);
  cmbBroker.ItemIndex := 0;
  cmbBrokerChange(nil);
  SetConnectedUI(False);
  AddLog('Pronto. Selecione um perfil do test.mosquitto.org e clique em "Conectar Broker".');
end;

procedure TfrmMain.cmbBrokerChange(Sender: TObject);
begin
  case cmbBroker.ItemIndex of

    0:
    begin
      edtHost.Text := 'test.mosquitto.org';
      edtPort.Text := '1883';
      edtUsername.Text := '';
      edtPassword.Text := '';
      edtSubTopic.Text := 'lazarus/ai/telemetria';

      AddLog(
        'Perfil selecionado: test.mosquitto.org ' +
        '(Porta 1883 - Sem Autenticação)'
      );
    end;

    1:
    begin
      edtHost.Text := 'test.mosquitto.org';
      edtPort.Text := '1884';
      edtUsername.Text := 'rw';
      edtPassword.Text := 'readwrite';
      edtSubTopic.Text := 'lazarus/ai/telemetria';

      AddLog(
        'Perfil selecionado: test.mosquitto.org ' +
        '(Porta 1884 - Autenticado rw/readwrite)'
      );
    end;

    2:
    begin
      edtHost.Text := 'test.mosquitto.org';
      edtPort.Text := '1884';
      edtUsername.Text := 'ro';
      edtPassword.Text := 'readonly';
      edtSubTopic.Text := 'lazarus/ai/telemetria';

      AddLog(
        'Perfil selecionado: test.mosquitto.org ' +
        '(Porta 1884 - Autenticado ro/readonly)'
      );
    end;

    3:
    begin
      edtHost.Text := 'test.mosquitto.org';
      edtPort.Text := '1884';
      edtUsername.Text := 'wo';
      edtPassword.Text := 'writeonly';
      edtSubTopic.Text := 'lazarus/ai/telemetria';

      AddLog(
        'Perfil selecionado: test.mosquitto.org ' +
        '(Porta 1884 - Autenticado wo/writeonly)'
      );
    end;

    4:
    begin
      edtHost.Text := 'test.mosquitto.org';
      edtPort.Text := '1883';
      edtUsername.Text := '';
      edtPassword.Text := '';
      edtSubTopic.Text := '#';

      AddLog(
        'Perfil selecionado: test.mosquitto.org ' +
        '(Descoberta de tópicos)'
      );
    end;

    5:
    begin
      edtHost.Text := 'broker.hivemq.com';
      edtPort.Text := '1883';
      edtUsername.Text := '';
      edtPassword.Text := '';
      edtSubTopic.Text := 'lazarus/ai/telemetria';

      AddLog('Perfil selecionado: broker.hivemq.com:1883');
    end;

    6:
    begin
      edtHost.Text := 'broker.emqx.io';
      edtPort.Text := '1883';
      edtUsername.Text := '';
      edtPassword.Text := '';
      edtSubTopic.Text := 'lazarus/ai/telemetria';

      AddLog('Perfil selecionado: broker.emqx.io:1883');
    end;

    7:
    begin
      edtHost.Text := 'localhost';
      edtPort.Text := '1883';
      edtUsername.Text := '';
      edtPassword.Text := '';
      edtSubTopic.Text := 'lazarus/ai/telemetria';

      AddLog('Perfil selecionado: localhost:1883');
    end;
  end;

  // Diagnóstico adicional
  AddLog(
    Format(
      '[CONFIG] Host Real="%s" Porta=%s Usuário="%s"',
      [
        edtHost.Text,
        edtPort.Text,
        edtUsername.Text
      ]
    )
  );
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if (AIMQTTClient1 <> nil) and AIMQTTClient1.Active then
    AIMQTTClient1.DisconnectBroker;
end;

procedure TfrmMain.btnGenIDClick(Sender: TObject);
begin
  edtClientID.Text := 'LazarusAI_' + IntToHex(Random($FFFFFF), 6);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('[hh:nn:ss.zzz] ', Now) + AMsg);
end;

procedure TfrmMain.AIMQTTClient1Log(Sender: TObject; Level: TAILogLevel; const Message: string);
var
  Prefix: string;
begin
  case Level of
    llDebug:   Prefix := '[DEBUG] ';
    llInfo:    Prefix := '[INFO] ';
    llWarning: Prefix := '[AVISO] ';
    llError:   Prefix := '[ERRO] ';
  end;
  AddLog(Prefix + Message);
end;

procedure TfrmMain.SetConnectedUI(AConnected: Boolean);
begin
  btnConnect.Enabled := not AConnected;
  cmbBroker.Enabled := not AConnected;
  edtHost.Enabled := not AConnected;
  edtPort.Enabled := not AConnected;
  edtClientID.Enabled := not AConnected;
  btnGenID.Enabled := not AConnected;
  edtUsername.Enabled := not AConnected;
  edtPassword.Enabled := not AConnected;
  edtKeepAlive.Enabled := not AConnected;
  
  btnDisconnect.Enabled := AConnected;
  btnPing.Enabled := AConnected;
  btnSubscribe.Enabled := AConnected;
  btnPublish.Enabled := AConnected;
  
  if AConnected then
  begin
    lblStatus.Caption := 'Status: Conectado ao Broker (' + AIMQTTClient1.Host + ':' + IntToStr(AIMQTTClient1.Port) + ')';
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
  AIMQTTClient1.Host := Trim(edtHost.Text);
  AIMQTTClient1.Port := StrToIntDef(edtPort.Text, 1883);
  AIMQTTClient1.ClientID := Trim(edtClientID.Text);
  AIMQTTClient1.Username := Trim(edtUsername.Text);
  AIMQTTClient1.Password := edtPassword.Text;
  AIMQTTClient1.KeepAlive := StrToIntDef(edtKeepAlive.Text, 60);

  AddLog(Format('Conectando ao broker MQTT "%s:%d" com ClientID "%s" (Usuário: "%s")...',
    [AIMQTTClient1.Host, AIMQTTClient1.Port, AIMQTTClient1.ClientID, AIMQTTClient1.Username]));
  
  lblStatus.Caption := 'Status: Conectando...';
  lblStatus.Font.Color := clNavy;
  Application.ProcessMessages;

  try
    if AIMQTTClient1.ConnectBroker then
    begin
      AddLog('Pacote CONNECT enviado com sucesso.');
    end
    else
    begin
      AddLog('Falha na conexão: ' + AIMQTTClient1.LastError);
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
    AIMQTTClient1.DisconnectBroker;
  finally
    SetConnectedUI(False);
  end;
end;

procedure TfrmMain.btnPingClick(Sender: TObject);
begin
  if AIMQTTClient1.Ping then
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
  if AIMQTTClient1.Subscribe(Topic) then
  begin
    if lstSubscriptions.Items.IndexOf(Topic) < 0 then
      lstSubscriptions.Items.Add(Topic);
    AddLog('Assinatura registrada no broker para: ' + Topic);
  end
  else
    AddLog('Erro ao assinar tópico: ' + AIMQTTClient1.LastError);
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
  if AIMQTTClient1.Publish(Topic, Payload) then
    AddLog('Mensagem publicada com sucesso.')
  else
    AddLog('Erro na publicação: ' + AIMQTTClient1.LastError);
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
