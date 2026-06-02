unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, Buttons, aichromiumbrowser, aioscapture, aimqtt, aiemail,
  aimessenger, aiindustrial, aimodbus, aicamera, aiaudio, aisockets,
  aiserial, aiposprinter, aicftvip, aiinput;

type
  { TfrmHardwareDemo }

  TfrmHardwareDemo = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FPageControl: TPageControl;
    
    // TAB 1: Browser
    FTabBrowser: TTabSheet;
    FBrowser: TAIChromiumBrowser;
    
    // TAB 2: Screen and OS Capture
    FTabOSCapture: TTabSheet;
    FOSCapture: TAIOSInputCapture;
    FBtnCaptureScreen: TButton;
    FImgScreen: TImage;
    FTrackMouseChk: TCheckBox;
    FTrackKeyChk: TCheckBox;
    FMouseLogMemo: TMemo;
    FKeyLogMemo: TMemo;
    
    // TAB 3: Network & IoT
    FTabNetwork: TTabSheet;
    FMQTTClient: TAIMQTTClient;
    FBtnMQTTConnect: TButton;
    FEditMQTTPayload: TEdit;
    FBtnMQTTPublish: TButton;
    FBtnMQTTSubscribe: TButton;
    FEditMQTTTopic: TEdit;
    FMailClient: TAIEmailClient;
    FBtnSendEmail: TButton;
    FEditMailTo: TEdit;
    FEditMailSubject: TEdit;
    FEditMailBody: TEdit;
    FNetworkLog: TMemo;
    
    // TAB 4: Industrial Automations
    FTabIndustrial: TTabSheet;
    FPLCBridge: TAIIndustrialBridge;
    FModbusClient: TAIModbusClient;
    FBtnConnectCLP: TButton;
    FBtnReadRegisters: TButton;
    FIndustrialLog: TMemo;
    
    // TAB 5: Hardware Adapters (Audio & Camera)
    FTabHardware: TTabSheet;
    FCamera: TAICameraInput;
    FAudio: TAIAudioInput;
    FBtnStartCamera: TButton;
    FBtnStopCamera: TButton;
    FBtnCaptureCameraFrame: TButton;
    FImgCamera: TImage;
    FBtnRecordAudio: TButton;
    FBtnStopRecordAudio: TButton;
    FBtnMixWavFiles: TButton;
    FHardwareLog: TMemo;
    
    // Component Event Handlers
    procedure OnMouseMoveIntercept(Sender: TObject; X, Y: Integer);
    procedure OnKeyIntercept(Sender: TObject; KeyCode: Word; KeyChar: Char);
    procedure OnMQTTMessage(Sender: TObject; const ATopic, APayload: string);
    procedure OnMQTTConnected(Sender: TObject);
    procedure OnMQTTDisconnected(Sender: TObject);
    
    // UI Event Handlers
    procedure BtnCaptureScreenClick(Sender: TObject);
    procedure TrackMouseChkChange(Sender: TObject);
    procedure TrackKeyChkChange(Sender: TObject);
    
    procedure BtnMQTTConnectClick(Sender: TObject);
    procedure BtnMQTTPublishClick(Sender: TObject);
    procedure BtnMQTTSubscribeClick(Sender: TObject);
    procedure BtnSendEmailClick(Sender: TObject);
    
    procedure BtnConnectCLPClick(Sender: TObject);
    procedure BtnReadRegistersClick(Sender: TObject);
    
    procedure BtnStartCameraClick(Sender: TObject);
    procedure BtnStopCameraClick(Sender: TObject);
    procedure BtnCaptureCameraFrameClick(Sender: TObject);
    procedure BtnRecordAudioClick(Sender: TObject);
    procedure BtnStopRecordAudioClick(Sender: TObject);
    procedure BtnMixWavFilesClick(Sender: TObject);
  public
  end;

var
  frmHardwareDemo: TfrmHardwareDemo;

implementation

{$R *.lfm}

{ TfrmHardwareDemo }

procedure TfrmHardwareDemo.FormCreate(Sender: TObject);
var
  LeftPanel, RightPanel: TPanel;
  LabelTitle: TLabel;
begin
  Caption := 'AI Input Suite — Multiplatform Hardware & Network Demo';
  Width := 900;
  Height := 650;
  Position := poScreenCenter;
  
  // 1. Page Control setup
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;
  
  // ==========================================
  // TAB 1: BROWSER INCORPORADO
  // ==========================================
  FTabBrowser := FPageControl.AddTabSheet;
  FTabBrowser.Caption := 'Navegador Web';
  
  FBrowser := TAIChromiumBrowser.Create(Self);
  FBrowser.Parent := FTabBrowser;
  FBrowser.Align := alClient;
  FBrowser.URL := 'https://www.google.com';
  
  // ==========================================
  // TAB 2: CAPTURA DO SISTEMA OPERACIONAL
  // ==========================================
  FTabOSCapture := FPageControl.AddTabSheet;
  FTabOSCapture.Caption := 'Captura de Sistema (OS)';
  
  FOSCapture := TAIOSInputCapture.Create(Self);
  FOSCapture.OnMouseMove := @OnMouseMoveIntercept;
  FOSCapture.OnKeyIntercepted := @OnKeyIntercept;
  FOSCapture.Active := True;
  
  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := FTabOSCapture;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 440;
  LeftPanel.BevelOuter := bvNone;
  
  FBtnCaptureScreen := TButton.Create(Self);
  FBtnCaptureScreen.Parent := LeftPanel;
  FBtnCaptureScreen.Align := alTop;
  FBtnCaptureScreen.Height := 40;
  FBtnCaptureScreen.Caption := 'Capturar Tela Inteira';
  FBtnCaptureScreen.OnClick := @BtnCaptureScreenClick;
  
  FImgScreen := TImage.Create(Self);
  FImgScreen.Parent := LeftPanel;
  FImgScreen.Align := alClient;
  FImgScreen.Stretch := True;
  FImgScreen.Proportional := True;
  
  RightPanel := TPanel.Create(Self);
  RightPanel.Parent := FTabOSCapture;
  RightPanel.Align := alClient;
  RightPanel.BevelOuter := bvNone;
  
  FTrackMouseChk := TCheckBox.Create(Self);
  FTrackMouseChk.Parent := RightPanel;
  FTrackMouseChk.Align := alTop;
  FTrackMouseChk.Caption := 'Rastrear Cursor do Mouse (e Touchscreen)';
  FTrackMouseChk.Checked := True;
  FTrackMouseChk.OnChange := @TrackMouseChkChange;
  
  FMouseLogMemo := TMemo.Create(Self);
  FMouseLogMemo.Parent := RightPanel;
  FMouseLogMemo.Align := alTop;
  FMouseLogMemo.Height := 200;
  FMouseLogMemo.ScrollBars := ssAutoVertical;
  FMouseLogMemo.ReadOnly := True;
  FMouseLogMemo.Lines.Add('=== Log de Movimentos do Mouse/Touch ===');
  
  FTrackKeyChk := TCheckBox.Create(Self);
  FTrackKeyChk.Parent := RightPanel;
  FTrackKeyChk.Align := alTop;
  FTrackKeyChk.Caption := 'Interceptar Teclado Globais';
  FTrackKeyChk.Checked := True;
  FTrackKeyChk.OnChange := @TrackKeyChkChange;
  
  FKeyLogMemo := TMemo.Create(Self);
  FKeyLogMemo.Parent := RightPanel;
  FKeyLogMemo.Align := alClient;
  FKeyLogMemo.ScrollBars := ssAutoVertical;
  FKeyLogMemo.ReadOnly := True;
  FKeyLogMemo.Lines.Add('=== Log de Teclas Interceptadas ===');
  
  // ==========================================
  // TAB 3: NETWORK & IOT (MQTT & EMAIL)
  // ==========================================
  FTabNetwork := FPageControl.AddTabSheet;
  FTabNetwork.Caption := 'Rede & IoT';
  
  FMQTTClient := TAIMQTTClient.Create(Self);
  FMQTTClient.OnMessageReceived := @OnMQTTMessage;
  FMQTTClient.OnConnected := @OnMQTTConnected;
  FMQTTClient.OnDisconnected := @OnMQTTDisconnected;
  
  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := FTabNetwork;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 400;
  LeftPanel.BevelOuter := bvNone;
  
  LabelTitle := TLabel.Create(Self);
  LabelTitle.Parent := LeftPanel;
  LabelTitle.Align := alTop;
  LabelTitle.Caption := ' IoT Telemetria (MQTT)';
  LabelTitle.Font.Style := [fsBold];
  LabelTitle.Height := 25;
  
  FBtnMQTTConnect := TButton.Create(Self);
  FBtnMQTTConnect.Parent := LeftPanel;
  FBtnMQTTConnect.Align := alTop;
  FBtnMQTTConnect.Height := 38;
  FBtnMQTTConnect.Caption := 'Conectar Broker MQTT';
  FBtnMQTTConnect.OnClick := @BtnMQTTConnectClick;
  
  FEditMQTTTopic := TEdit.Create(Self);
  FEditMQTTTopic.Parent := LeftPanel;
  FEditMQTTTopic.Align := alTop;
  FEditMQTTTopic.Text := 'lazarus/ai/demo';
  FEditMQTTTopic.Height := 28;
  
  FBtnMQTTSubscribe := TButton.Create(Self);
  FBtnMQTTSubscribe.Parent := LeftPanel;
  FBtnMQTTSubscribe.Align := alTop;
  FBtnMQTTSubscribe.Height := 35;
  FBtnMQTTSubscribe.Caption := 'Subscrever no Tópico';
  FBtnMQTTSubscribe.OnClick := @BtnMQTTSubscribeClick;
  
  FEditMQTTPayload := TEdit.Create(Self);
  FEditMQTTPayload.Parent := LeftPanel;
  FEditMQTTPayload.Align := alTop;
  FEditMQTTPayload.Text := '{"temperatura": 24.5, "sensor": "A1"}';
  FEditMQTTPayload.Height := 28;
  
  FBtnMQTTPublish := TButton.Create(Self);
  FBtnMQTTPublish.Parent := LeftPanel;
  FBtnMQTTPublish.Align := alTop;
  FBtnMQTTPublish.Height := 35;
  FBtnMQTTPublish.Caption := 'Publicar Mensagem MQTT';
  FBtnMQTTPublish.OnClick := @BtnMQTTPublishClick;
  
  // Separator
  TPanel.Create(Self).Parent := LeftPanel;
  LeftPanel.Controls[LeftPanel.ControlCount - 1].Align := alTop;
  LeftPanel.Controls[LeftPanel.ControlCount - 1].Height := 15;
  
  LabelTitle := TLabel.Create(Self);
  LabelTitle.Parent := LeftPanel;
  LabelTitle.Align := alTop;
  LabelTitle.Caption := ' Notificações por E-mail (SMTP)';
  LabelTitle.Font.Style := [fsBold];
  LabelTitle.Height := 25;
  
  FMailClient := TAIEmailClient.Create(Self);
  FMailClient.HostSMTP := 'localhost';
  FMailClient.PortSMTP := 25;
  
  FEditMailTo := TEdit.Create(Self);
  FEditMailTo.Parent := LeftPanel;
  FEditMailTo.Align := alTop;
  FEditMailTo.Text := 'alerta-sensor@empresa.com';
  FEditMailTo.Height := 28;
  
  FEditMailSubject := TEdit.Create(Self);
  FEditMailSubject.Parent := LeftPanel;
  FEditMailSubject.Align := alTop;
  FEditMailSubject.Text := 'Anomalia Detectada pela IA';
  FEditMailSubject.Height := 28;
  
  FEditMailBody := TEdit.Create(Self);
  FEditMailBody.Parent := LeftPanel;
  FEditMailBody.Align := alTop;
  FEditMailBody.Text := 'Modelo detectou aumento atípico de temperatura na correia transportadora.';
  FEditMailBody.Height := 28;
  
  FBtnSendEmail := TButton.Create(Self);
  FBtnSendEmail.Parent := LeftPanel;
  FBtnSendEmail.Align := alTop;
  FBtnSendEmail.Height := 38;
  FBtnSendEmail.Caption := 'Enviar E-mail de Teste';
  FBtnSendEmail.OnClick := @BtnSendEmailClick;
  
  RightPanel := TPanel.Create(Self);
  RightPanel.Parent := FTabNetwork;
  RightPanel.Align := alClient;
  RightPanel.BevelOuter := bvNone;
  
  FNetworkLog := TMemo.Create(Self);
  FNetworkLog.Parent := RightPanel;
  FNetworkLog.Align := alClient;
  FNetworkLog.ScrollBars := ssAutoVertical;
  FNetworkLog.ReadOnly := True;
  FNetworkLog.Lines.Add('=== Console de Operações IoT e Rede ===');
  
  // ==========================================
  // TAB 4: INDUSTRIAL (MODBUS & PROFINET/PROFIBUS)
  // ==========================================
  FTabIndustrial := FPageControl.AddTabSheet;
  FTabIndustrial.Caption := 'Automação Industrial';
  
  FPLCBridge := TAIIndustrialBridge.Create(Self);
  FModbusClient := TAIModbusClient.Create(Self);
  
  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := FTabIndustrial;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 350;
  LeftPanel.BevelOuter := bvNone;
  
  FBtnConnectCLP := TButton.Create(Self);
  FBtnConnectCLP.Parent := LeftPanel;
  FBtnConnectCLP.Align := alTop;
  FBtnConnectCLP.Height := 40;
  FBtnConnectCLP.Caption := 'Conectar Ponte Industrial (Profinet/Profibus)';
  FBtnConnectCLP.OnClick := @BtnConnectCLPClick;
  
  FBtnReadRegisters := TButton.Create(Self);
  FBtnReadRegisters.Parent := LeftPanel;
  FBtnReadRegisters.Align := alTop;
  FBtnReadRegisters.Height := 40;
  FBtnReadRegisters.Caption := 'Ler Registros Modbus / CLP';
  FBtnReadRegisters.OnClick := @BtnReadRegistersClick;
  
  FIndustrialLog := TMemo.Create(Self);
  FIndustrialLog.Parent := FTabIndustrial;
  FIndustrialLog.Align := alClient;
  FIndustrialLog.ScrollBars := ssAutoVertical;
  FIndustrialLog.ReadOnly := True;
  FIndustrialLog.Lines.Add('=== Log Industrial e Telemetria de CLP ===');
  
  // ==========================================
  // TAB 5: HARDWARE ADAPTERS (CAMERA & AUDIO)
  // ==========================================
  FTabHardware := FPageControl.AddTabSheet;
  FTabHardware.Caption := 'Multimídia & Adaptores';
  
  FCamera := TAICameraInput.Create(Self);
  FAudio := TAIAudioInput.Create(Self);
  
  LeftPanel := TPanel.Create(Self);
  LeftPanel.Parent := FTabHardware;
  LeftPanel.Align := alLeft;
  LeftPanel.Width := 420;
  LeftPanel.BevelOuter := bvNone;
  
  FBtnStartCamera := TButton.Create(Self);
  FBtnStartCamera.Parent := LeftPanel;
  FBtnStartCamera.Align := alTop;
  FBtnStartCamera.Height := 38;
  FBtnStartCamera.Caption := 'Ligar Câmera';
  FBtnStartCamera.OnClick := @BtnStartCameraClick;
  
  FBtnStopCamera := TButton.Create(Self);
  FBtnStopCamera.Parent := LeftPanel;
  FBtnStopCamera.Align := alTop;
  FBtnStopCamera.Height := 38;
  FBtnStopCamera.Caption := 'Desligar Câmera';
  FBtnStopCamera.OnClick := @BtnStopCameraClick;
  
  FBtnCaptureCameraFrame := TButton.Create(Self);
  FBtnCaptureCameraFrame.Parent := LeftPanel;
  FBtnCaptureCameraFrame.Align := alTop;
  FBtnCaptureCameraFrame.Height := 38;
  FBtnCaptureCameraFrame.Caption := 'Capturar Frame de Câmera';
  FBtnCaptureCameraFrame.OnClick := @BtnCaptureCameraFrameClick;
  
  FImgCamera := TImage.Create(Self);
  FImgCamera.Parent := LeftPanel;
  FImgCamera.Align := alClient;
  FImgCamera.Stretch := True;
  FImgCamera.Proportional := True;
  FImgCamera.Center := True;
  
  RightPanel := TPanel.Create(Self);
  RightPanel.Parent := FTabHardware;
  RightPanel.Align := alClient;
  RightPanel.BevelOuter := bvNone;
  
  FBtnRecordAudio := TButton.Create(Self);
  FBtnRecordAudio.Parent := RightPanel;
  FBtnRecordAudio.Align := alTop;
  FBtnRecordAudio.Height := 38;
  FBtnRecordAudio.Caption := 'Gravar Áudio (Microfone)';
  FBtnRecordAudio.OnClick := @BtnRecordAudioClick;
  
  FBtnStopRecordAudio := TButton.Create(Self);
  FBtnStopRecordAudio.Parent := RightPanel;
  FBtnStopRecordAudio.Align := alTop;
  FBtnStopRecordAudio.Height := 38;
  FBtnStopRecordAudio.Caption := 'Parar Gravação';
  FBtnStopRecordAudio.OnClick := @BtnStopRecordAudioClick;
  
  FBtnMixWavFiles := TButton.Create(Self);
  FBtnMixWavFiles.Parent := RightPanel;
  FBtnMixWavFiles.Align := alTop;
  FBtnMixWavFiles.Height := 38;
  FBtnMixWavFiles.Caption := 'Misturar Arquivos WAV (Mixer)';
  FBtnMixWavFiles.OnClick := @BtnMixWavFilesClick;
  
  FHardwareLog := TMemo.Create(Self);
  FHardwareLog.Parent := RightPanel;
  FHardwareLog.Align := alClient;
  FHardwareLog.ScrollBars := ssAutoVertical;
  FHardwareLog.ReadOnly := True;
  FHardwareLog.Lines.Add('=== Log Multimídia de Câmeras e Microfones ===');
end;

procedure TfrmHardwareDemo.FormDestroy(Sender: TObject);
begin
  if FCamera.Active then FCamera.StopCapture;
  if FPLCBridge.Active then FPLCBridge.DisconnectBridge;
  if FMQTTClient.Active then FMQTTClient.DisconnectBroker;
end;

// ==========================================
// EVENT HANDLERS
// ==========================================

procedure TfrmHardwareDemo.OnMouseMoveIntercept(Sender: TObject; X, Y: Integer);
begin
  FMouseLogMemo.Lines.Add(Format('Coordenadas de cursor: X=%d, Y=%d (Horário: %s)', [X, Y, FormatDateTime('hh:nn:ss.zzz', Now)]));
  // Cap history length for stability
  if FMouseLogMemo.Lines.Count > 100 then
    FMouseLogMemo.Lines.Delete(1);
end;

procedure TfrmHardwareDemo.OnKeyIntercept(Sender: TObject; KeyCode: Word; KeyChar: Char);
begin
  if KeyChar <> #0 then
    FKeyLogMemo.Lines.Add(Format('Caractere: "%s" [Código Tecla: %d]', [KeyChar, KeyCode]))
  else
    FKeyLogMemo.Lines.Add(Format('Tecla de Controle: [Código Tecla: %d]', [KeyCode]));
    
  if FKeyLogMemo.Lines.Count > 100 then
    FKeyLogMemo.Lines.Delete(1);
end;

procedure TfrmHardwareDemo.OnMQTTMessage(Sender: TObject; const ATopic, APayload: string);
begin
  FNetworkLog.Lines.Add(Format('[MQTT] Mensagem Recebida no tópico "%s" -> %s', [ATopic, APayload]));
end;

procedure TfrmHardwareDemo.OnMQTTConnected(Sender: TObject);
begin
  FNetworkLog.Lines.Add('[MQTT] Conectado ao Broker MQTT com Sucesso!');
  FBtnMQTTConnect.Caption := 'Desconectar MQTT';
end;

procedure TfrmHardwareDemo.OnMQTTDisconnected(Sender: TObject);
begin
  FNetworkLog.Lines.Add('[MQTT] Desconectado do Broker MQTT.');
  FBtnMQTTConnect.Caption := 'Conectar Broker MQTT';
end;

// ==========================================
// BUTTON CLICKS & ACTIONS
// ==========================================

procedure TfrmHardwareDemo.BtnCaptureScreenClick(Sender: TObject);
var
  Bmp: TBitmap;
begin
  Bmp := nil;
  try
    FNetworkLog.Lines.Add('[Captura] Capturando imagem do Desktop...');
    if FOSCapture.CaptureScreen(Bmp) then
    begin
      FImgScreen.Picture.Assign(Bmp);
      FNetworkLog.Lines.Add('[Captura] Tela capturada com sucesso!');
    end
    else
      FNetworkLog.Lines.Add('[Captura] Falha ao capturar tela.');
  finally
    if Bmp <> nil then Bmp.Free;
  end;
end;

procedure TfrmHardwareDemo.TrackMouseChkChange(Sender: TObject);
begin
  FOSCapture.TrackMouse := FTrackMouseChk.Checked;
end;

procedure TfrmHardwareDemo.TrackKeyChkChange(Sender: TObject);
begin
  FOSCapture.TrackKeyboard := FTrackKeyChk.Checked;
end;

procedure TfrmHardwareDemo.BtnMQTTConnectClick(Sender: TObject);
begin
  if FMQTTClient.Active then
    FMQTTClient.DisconnectBroker
  else
  begin
    FNetworkLog.Lines.Add('[MQTT] Conectando ao broker: broker.hivemq.com ...');
    FMQTTClient.Host := 'broker.hivemq.com';
    FMQTTClient.Port := 1883;
    FMQTTClient.ConnectBroker;
  end;
end;

procedure TfrmHardwareDemo.BtnMQTTPublishClick(Sender: TObject);
begin
  if not FMQTTClient.Active then
  begin
    ShowMessage('Favor conectar ao Broker MQTT primeiro.');
    Exit;
  end;
  
  if FMQTTClient.Publish(FEditMQTTTopic.Text, FEditMQTTPayload.Text) then
    FNetworkLog.Lines.Add(Format('[MQTT] Publicado no tópico "%s": %s', [FEditMQTTTopic.Text, FEditMQTTPayload.Text]))
  else
    FNetworkLog.Lines.Add('[MQTT] Falha na publicação.');
end;

procedure TfrmHardwareDemo.BtnMQTTSubscribeClick(Sender: TObject);
begin
  if not FMQTTClient.Active then
  begin
    ShowMessage('Favor conectar ao Broker MQTT primeiro.');
    Exit;
  end;
  
  if FMQTTClient.Subscribe(FEditMQTTTopic.Text) then
    FNetworkLog.Lines.Add(Format('[MQTT] Subscrição registrada para o tópico: %s', [FEditMQTTTopic.Text]))
  else
    FNetworkLog.Lines.Add('[MQTT] Falha na subscrição.');
end;

procedure TfrmHardwareDemo.BtnSendEmailClick(Sender: TObject);
begin
  FNetworkLog.Lines.Add('[SMTP] Tentando enviar e-mail via canal SMTP...');
  if FMailClient.SendEmail(FEditMailTo.Text, FEditMailSubject.Text, FEditMailBody.Text) then
    FNetworkLog.Lines.Add('[SMTP] E-mail enviado com sucesso (RFC protocol)!')
  else
    FNetworkLog.Lines.Add('[SMTP] Falha no envio. Certifique-se de possuir um servidor local de envio.');
end;

procedure TfrmHardwareDemo.BtnConnectCLPClick(Sender: TObject);
begin
  if FPLCBridge.Active then
  begin
    FPLCBridge.DisconnectBridge;
    FBtnConnectCLP.Caption := 'Conectar Ponte Industrial (Profinet/Profibus)';
    FIndustrialLog.Lines.Add('[Industrial] Ponte Profinet desconectada.');
  end
  else
  begin
    FIndustrialLog.Lines.Add('[Industrial] Tentando iniciar conexão com Profinet PLC...');
    FPLCBridge.IPAddress := '192.168.0.1';
    if FPLCBridge.ConnectBridge then
    begin
      FBtnConnectCLP.Caption := 'Desconectar Ponte Industrial';
      FIndustrialLog.Lines.Add('[Industrial] CLP Profinet conectado com sucesso (Modo Simulação/Real ativo)!');
    end;
  end;
end;

procedure TfrmHardwareDemo.BtnReadRegistersClick(Sender: TObject);
var
  Data: array[0..9] of Byte;
  I: Integer;
  LineStr: string;
begin
  if not FPLCBridge.Active then
  begin
    ShowMessage('Favor conectar a ponte do CLP antes de ler.');
    Exit;
  end;
  
  FIndustrialLog.Lines.Add('[Industrial] Lendo 10 bytes do Bloco DB1...');
  if FPLCBridge.ReadBytes(1, 0, 10, Data) then
  begin
    LineStr := 'Bytes CLP: [';
    for I := 0 to 9 do
    begin
      LineStr := LineStr + IntToStr(Data[I]);
      if I < 9 then LineStr := LineStr + ', ';
    end;
    LineStr := LineStr + ']';
    FIndustrialLog.Lines.Add('[Industrial] ' + LineStr);
  end;
end;

procedure TfrmHardwareDemo.BtnStartCameraClick(Sender: TObject);
begin
  FHardwareLog.Lines.Add('[Câmera] Ligando dispositivo de captura multimídia...');
  if FCamera.StartCapture then
  begin
    FHardwareLog.Lines.Add('[Câmera] Câmera ativa!');
  end;
end;

procedure TfrmHardwareDemo.BtnStopCameraClick(Sender: TObject);
begin
  FCamera.StopCapture;
  FHardwareLog.Lines.Add('[Câmera] Dispositivo desligado.');
end;

procedure TfrmHardwareDemo.BtnCaptureCameraFrameClick(Sender: TObject);
var
  Bmp: TBitmap;
begin
  Bmp := nil;
  try
    FHardwareLog.Lines.Add('[Câmera] Adquirindo quadro instantâneo...');
    if FCamera.CaptureFrame(Bmp) then
    begin
      FImgCamera.Picture.Assign(Bmp);
      FHardwareLog.Lines.Add('[Câmera] Frame adquirido!');
    end
    else
      FHardwareLog.Lines.Add('[Câmera] Falha ao ler quadro. Certifique-se de ter ativado a câmera.');
  finally
    if Bmp <> nil then Bmp.Free;
  end;
end;

procedure TfrmHardwareDemo.BtnRecordAudioClick(Sender: TObject);
begin
  FHardwareLog.Lines.Add('[Áudio] Iniciando gravação de entrada (Microfone/Mix)...');
  FAudio.InputSource := asMic;
  FAudio.StartRecord('captura_voz.wav');
end;

procedure TfrmHardwareDemo.BtnStopRecordAudioClick(Sender: TObject);
begin
  FAudio.StopRecord;
  FHardwareLog.Lines.Add('[Áudio] Gravação concluída e salva no arquivo local: "captura_voz.wav"');
end;

procedure TfrmHardwareDemo.BtnMixWavFilesClick(Sender: TObject);
var
  MixedFile: string;
begin
  FHardwareLog.Lines.Add('[Áudio] Executando mixagem linear em thread de sinais...');
  MixedFile := 'mistura.wav';
  if FAudio.MixAudio('canal_a.wav', 'canal_b.wav', MixedFile) then
    FHardwareLog.Lines.Add('[Áudio] Sinais de áudio mixados no arquivo: ' + MixedFile);
end;

end.
