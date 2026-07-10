unit main;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Forms, Controls, Dialogs, ExtCtrls, StdCtrls,
  chatgpt, aiserial, ailistserialdevices, aiagentserial;
type
  TfrmMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FLLM: TCHATGPT;
    FSerial: TAISerialModem;
    FAgent: TAIAgentSerial;
    FLister: TAIListSerialDevices;
    FTimer: TTimer;
    FManualStream: string;
    FFirmwareManual: string;
    cbProvider, cbPort, cbBaud: TComboBox;
    edtToken, editSend, editPrompt: TEdit;
    memoLog, memoChat, memoManual: TMemo;
    procedure BuildUI;
    procedure RefreshPorts(Sender: TObject);
    procedure ConnectClick(Sender: TObject);
    procedure DisconnectClick(Sender: TObject);
    procedure SendClick(Sender: TObject);
    procedure AskClick(Sender: TObject);
    procedure RequestManual(Sender: TObject);
    procedure PollTimer(Sender: TObject);
    procedure SerialConnect(Sender: TObject);
    procedure SerialRX(Sender: TObject; const AData: string);
    procedure ProcessManualData;
    procedure BeforeAction(Sender: TObject; AKind: TAgentActionKind;
      const AParam: string; var AAllow: Boolean);
    procedure AgentLog(Sender: TObject; const AMessage: string);
    function KindName(AKind: TAgentActionKind): string;
  end;
var frmMain: TfrmMain;
implementation
{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  BuildUI;
  FLLM := TCHATGPT.Create(Self);
  FSerial := TAISerialModem.Create(Self);
  FLister := TAIListSerialDevices.Create(Self);
  FTimer := TTimer.Create(Self);
  FAgent := TAIAgentSerial.Create(Self);
  FSerial.OnConnect := @SerialConnect;
  FSerial.OnRXReceive := @SerialRX;
  FAgent.Serial := FSerial;
  FAgent.LLM := FLLM;
  FAgent.OnBeforeAction := @BeforeAction;
  FAgent.OnAgentLog := @AgentLog;
  FTimer.Interval := 100;
  FTimer.OnTimer := @PollTimer;
  FTimer.Enabled := True;
  RefreshPorts(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FTimer.Enabled := False;
  FSerial.ClosePort;
end;

procedure TfrmMain.BuildUI;
var
  TopPanel, BottomPanel, ManualPanel: TPanel;
  B: TButton;
begin
  TopPanel := TPanel.Create(Self); TopPanel.Parent := Self; TopPanel.Align := alTop; TopPanel.Height := 105;
  cbProvider := TComboBox.Create(Self); cbProvider.Parent := TopPanel; cbProvider.SetBounds(10,10,120,24);
  cbProvider.Items.AddStrings(['OpenAI','OpenRouter','Local']); cbProvider.ItemIndex := 0;
  edtToken := TEdit.Create(Self); edtToken.Parent := TopPanel; edtToken.SetBounds(140,10,230,24);
  edtToken.PasswordChar := '*'; edtToken.TextHint := 'API key/token';
  cbPort := TComboBox.Create(Self); cbPort.Parent := TopPanel; cbPort.SetBounds(10,42,190,24); cbPort.Style := csDropDownList;
  B := TButton.Create(Self); B.Parent := TopPanel; B.SetBounds(205,41,75,26); B.Caption := 'Atualizar'; B.OnClick := @RefreshPorts;
  cbBaud := TComboBox.Create(Self); cbBaud.Parent := TopPanel; cbBaud.SetBounds(290,42,100,24);
  cbBaud.Items.AddStrings(['9600','19200','38400','57600','115200']); cbBaud.ItemIndex := 4;
  B := TButton.Create(Self); B.Parent := TopPanel; B.SetBounds(400,41,85,26); B.Caption := 'Conectar'; B.OnClick := @ConnectClick;
  B := TButton.Create(Self); B.Parent := TopPanel; B.SetBounds(490,41,100,26); B.Caption := 'Desconectar'; B.OnClick := @DisconnectClick;
  B := TButton.Create(Self); B.Parent := TopPanel; B.SetBounds(600,41,95,26); B.Caption := 'Ler MAN'; B.OnClick := @RequestManual;
  editSend := TEdit.Create(Self); editSend.Parent := TopPanel; editSend.SetBounds(10,74,480,24);
  B := TButton.Create(Self); B.Parent := TopPanel; B.SetBounds(500,73,80,26); B.Caption := 'Enviar'; B.OnClick := @SendClick;

  ManualPanel := TPanel.Create(Self); ManualPanel.Parent := Self; ManualPanel.Align := alRight; ManualPanel.Width := 310;
  memoManual := TMemo.Create(Self); memoManual.Parent := ManualPanel; memoManual.Align := alClient;
  memoManual.ReadOnly := True; memoManual.ScrollBars := ssVertical; memoManual.Font.Name := 'Courier New';
  memoManual.Text := 'Manual do firmware ainda não carregado.';

  BottomPanel := TPanel.Create(Self); BottomPanel.Parent := Self; BottomPanel.Align := alBottom; BottomPanel.Height := 245;
  memoChat := TMemo.Create(Self); memoChat.Parent := BottomPanel; memoChat.Align := alClient; memoChat.ScrollBars := ssVertical;
  editPrompt := TEdit.Create(Self); editPrompt.Parent := BottomPanel; editPrompt.Align := alBottom; editPrompt.Height := 28;
  editPrompt.Text := 'acenda o LED do Arduino';
  B := TButton.Create(Self); B.Parent := BottomPanel; B.Align := alBottom; B.Height := 32;
  B.Caption := 'Perguntar ao agente'; B.OnClick := @AskClick;
  memoLog := TMemo.Create(Self); memoLog.Parent := Self; memoLog.Align := alClient;
  memoLog.Font.Name := 'Courier New'; memoLog.ScrollBars := ssVertical;
end;

procedure TfrmMain.RefreshPorts(Sender: TObject);
begin
  FLister.ProbeOpenable := False;
  FLister.Refresh;
  FLister.GetDeviceNames(cbPort.Items);
  if cbPort.Items.Count > 0 then cbPort.ItemIndex := 0;
end;

procedure TfrmMain.ConnectClick(Sender: TObject);
begin
  FSerial.DeviceName := cbPort.Text;
  FSerial.BaudRate := StrToIntDef(cbBaud.Text, 115200);
  if not FSerial.OpenPort then memoLog.Lines.Add('ERRO: ' + FSerial.LastError);
end;

procedure TfrmMain.DisconnectClick(Sender: TObject);
begin
  FSerial.ClosePort;
end;

procedure TfrmMain.SendClick(Sender: TObject);
begin
  if not FSerial.WriteText(Trim(editSend.Text) + #10) then
    memoLog.Lines.Add('ERRO TX: ' + FSerial.LastError);
end;

procedure TfrmMain.SerialConnect(Sender: TObject);
begin
  memoLog.Lines.Add('*** Conectado; solicitando MAN ao firmware ***');
  RequestManual(Sender);
end;

procedure TfrmMain.RequestManual(Sender: TObject);
begin
  if not FSerial.Active then
  begin
    memoLog.Lines.Add('ERRO: conecte a porta antes de solicitar MAN.');
    Exit;
  end;
  FManualStream := '';
  FFirmwareManual := '';
  memoManual.Text := 'Aguardando resposta do comando MAN...';
  if not FSerial.WriteText('MAN' + #10) then
    memoLog.Lines.Add('ERRO MAN: ' + FSerial.LastError);
end;

procedure TfrmMain.PollTimer(Sender: TObject);
begin
  FSerial.Poll;
end;

procedure TfrmMain.SerialRX(Sender: TObject; const AData: string);
begin
  memoLog.Lines.Add('RX <= ' + AData);
  FAgent.AppendRX(AData);
  FManualStream := FManualStream + AData;
  ProcessManualData;
end;

procedure TfrmMain.ProcessManualData;
var
  PStart, PEnd: Integer;
begin
  PStart := Pos('MAN-BEGIN', FManualStream);
  PEnd := Pos('MAN-END', FManualStream);
  if (PStart = 0) or (PEnd <= PStart) then Exit;
  FFirmwareManual := Trim(Copy(FManualStream, PStart,
    PEnd + Length('MAN-END') - PStart));
  memoManual.Text := FFirmwareManual;
  FAgent.SystemPrompt :=
    'MANUAL FORNECIDO PELO FIRMWARE CONECTADO:' + LineEnding +
    FFirmwareManual + LineEnding +
    'Use exclusivamente os comandos documentados nesse manual. ' +
    'Para operar o firmware, gere uma ação send com o comando exato e terminador \n. ' +
    'Não invente comandos.';
  memoLog.Lines.Add('*** MAN carregado no contexto do agente ***');
  FManualStream := '';
end;

procedure TfrmMain.AgentLog(Sender: TObject; const AMessage: string);
begin
  memoLog.Lines.Add(AMessage);
end;

function TfrmMain.KindName(AKind: TAgentActionKind): string;
const
  N: array[TAgentActionKind] of string = ('none','set_port','set_baud',
    'connect','disconnect','send','read','list_ports','status');
begin
  Result := N[AKind];
end;

procedure TfrmMain.BeforeAction(Sender: TObject; AKind: TAgentActionKind;
  const AParam: string; var AAllow: Boolean);
begin
  AAllow := MessageDlg('Agente quer executar: ' + KindName(AKind) + ' ' +
    AParam + '. Permitir?', mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmMain.AskClick(Sender: TObject);
begin
  if FFirmwareManual = '' then
  begin
    MessageDlg('Conecte o Arduino e aguarde o carregamento do MAN.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  case cbProvider.ItemIndex of
    1: FLLM.Provider := AIP_OPENROUTER;
    2: FLLM.Provider := AIP_LOCAL;
    else FLLM.Provider := AIP_OPENAI;
  end;
  FLLM.TOKEN := edtToken.Text;
  if FLLM.Provider = AIP_LOCAL then
  begin
    FLLM.LocalIP := 'http://localhost:11434';
    FLLM.CustomModel := 'llama3.2:3b';
  end;
  memoChat.Lines.Add('Você: ' + editPrompt.Text);
  memoChat.Lines.Add('Agente: ' + FAgent.Execute(editPrompt.Text));
end;

end.
