import os

target_path = r'P:\maurinsoft\Assistente\src\main.pas'
with open(target_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add aicontinuouslistener to uses
uses_target = 'aivoicerecognizer, soundfilters,'
uses_repl = 'aivoicerecognizer, soundfilters, aicontinuouslistener,'
if uses_target in text:
    text = text.replace(uses_target, uses_repl, 1)
    print('1. Added aicontinuouslistener to uses')

# 2. Add fields in Tfrmmain private
fields_target = 'FVoiceActive: Boolean;'
fields_repl = '''FVoiceActive: Boolean;
    FAssistantSpeaking: Boolean;
    FContinuousListener: TAIContinuousListener;'''
if fields_target in text:
    text = text.replace(fields_target, fields_repl, 1)
    print('2. Added listener fields in Tfrmmain')

# 3. Add method declarations in Tfrmmain
methods_target = 'procedure VoiceRecognized(Sender: TObject; const AText: string);'
methods_repl = '''procedure VoiceRecognized(Sender: TObject; const AText: string);
    procedure ProcessUserSpeech(const AText: string);
    function ValidateWavFile(const AFileName: string; out AError: string): Boolean;
    procedure OnContinuousSpeechUtterance(Sender: TObject; const AWavFileName: string; ADurationMs: Integer);
    procedure OnContinuousStateChanged(Sender: TObject; AOldState, ANewState: TAIListeningState);
    procedure OnContinuousRMSChanged(Sender: TObject; ARMS: Double);
    procedure OnContinuousAudioOrigin(Sender: TObject; AOrigin: TAudioOrigin; AConfidence: Double);
    procedure OnContinuousBargeIn(Sender: TObject);
    procedure OnAudioPlayerPlaybackStart(Sender: TObject; const AFileName: string);
    procedure OnAudioPlayerPlaybackStop(Sender: TObject);'''
if methods_target in text:
    text = text.replace(methods_target, methods_repl, 1)
    print('3. Added method declarations')

# 4. Property declarations
prop_target = 'property AudioPlayer: TAIAudioPlayer read FAudioPlayer;'
prop_repl = '''property AudioPlayer: TAIAudioPlayer read FAudioPlayer;
    property ContinuousListener: TAIContinuousListener read FContinuousListener;'''
if prop_target in text:
    text = text.replace(prop_target, prop_repl, 1)
    print('4. Added property ContinuousListener')

# 5. FormCreate listener instantiation
fc_target = '''  FVoiceRecog := TAIVoiceRecognizer.Create(Self);
  FVoiceRecog.OnRecognized := @VoiceRecognized;'''
fc_repl = '''  FVoiceRecog := TAIVoiceRecognizer.Create(Self);
  FVoiceRecog.OnRecognized := @VoiceRecognized;

  // Inicializa escuta contínua com VAD e supressão da própria voz
  FContinuousListener := TAIContinuousListener.Create(Self);
  FContinuousListener.Continuous := True;
  FContinuousListener.OnSpeechUtterance := @OnContinuousSpeechUtterance;
  FContinuousListener.OnStateChanged := @OnContinuousStateChanged;
  FContinuousListener.OnRMSChanged := @OnContinuousRMSChanged;
  FContinuousListener.OnAudioOriginDetected := @OnContinuousAudioOrigin;
  FContinuousListener.OnBargeIn := @OnContinuousBargeIn;

  if Assigned(FAudioPlayer) then
  begin
    FAudioPlayer.OnPlaybackStart := @OnAudioPlayerPlaybackStart;
    FAudioPlayer.OnPlaybackStop := @OnAudioPlayerPlaybackStop;
  end;'''
if fc_target in text:
    text = text.replace(fc_target, fc_repl, 1)
    print('5. Added listener initialization in FormCreate')

# 6. Apply settings to FContinuousListener and FVoiceRecog in FormCreate
cfg_target = '''  if Assigned(FVoiceRecog) then
  begin
    case FSetMain.RecogEngine of
      0: FVoiceRecog.Engine := vreOpenAIWhisper;
      1: FVoiceRecog.Engine := vreSAPI;
      2: FVoiceRecog.Engine := vreSystemDefault;
    else
      FVoiceRecog.Engine := vreOpenAIWhisper;
    end;
    if Trim(FSetMain.RecogLanguage) <> '' then
      FVoiceRecog.Language := FSetMain.RecogLanguage
    else
      FVoiceRecog.Language := 'pt';
    FVoiceRecog.OpenAIToken := FSetMain.CHATGPT;
  end;'''
cfg_repl = '''  if Assigned(FVoiceRecog) then
  begin
    case FSetMain.RecogEngine of
      0: FVoiceRecog.Engine := vreOpenAIWhisper;
      1: FVoiceRecog.Engine := vreSAPI;
      2: FVoiceRecog.Engine := vreSystemDefault;
    else
      FVoiceRecog.Engine := vreOpenAIWhisper;
    end;
    if Trim(FSetMain.RecogLanguage) <> '' then
      FVoiceRecog.Language := FSetMain.RecogLanguage
    else
      FVoiceRecog.Language := 'pt';

    if (FSetMain <> nil) and (Trim(FSetMain.STTToken) <> '') then
      FVoiceRecog.OpenAIToken := FSetMain.STTToken
    else
      FVoiceRecog.OpenAIToken := FSetMain.CHATGPT;

    if (FSetMain <> nil) and (Trim(FSetMain.STTModel) <> '') then
      FVoiceRecog.OpenAIModel := FSetMain.STTModel;
    if (FSetMain <> nil) and (Trim(FSetMain.STTEndpoint) <> '') then
      FVoiceRecog.OpenAIEndpoint := FSetMain.STTEndpoint;
  end;

  if Assigned(FContinuousListener) and (FSetMain <> nil) then
  begin
    FContinuousListener.Enabled := FSetMain.ContinuousListening;
    FContinuousListener.VoiceThreshold := FSetMain.VoiceThreshold;
    FContinuousListener.SilenceTimeoutMs := FSetMain.SilenceTimeoutMs;
    FContinuousListener.MinSpeechMs := FSetMain.MinSpeechMs;
    FContinuousListener.MaxSpeechMs := FSetMain.MaxSpeechMs;
    FContinuousListener.EchoSuppressionEnabled := FSetMain.EchoSuppressionEnabled;
    FContinuousListener.SelfAudioCorrelationThreshold := FSetMain.SelfAudioCorrelationThreshold;

    if FContinuousListener.Enabled then
      FContinuousListener.StartListening;
  end;'''
if cfg_target in text:
    text = text.replace(cfg_target, cfg_repl, 1)
    print('6. Applied settings to FVoiceRecog and FContinuousListener')

# 7. FormDestroy listener cleanup
fd_target = 'procedure Tfrmmain.FormDestroy(Sender: TObject);'
fd_repl = '''procedure Tfrmmain.FormDestroy(Sender: TObject);
begin
  if Assigned(FContinuousListener) then
  begin
    FContinuousListener.StopListening;
    FreeAndNil(FContinuousListener);
  end;'''
if fd_target in text:
    # replace the procedure header and its begin
    text = text.replace('procedure Tfrmmain.FormDestroy(Sender: TObject);\nbegin', fd_repl, 1)
    print('7. Added FormDestroy cleanup')

# 8. OnVoiceSpeechStart and OnVoiceSpeechEnd updates
speech_start_target = '''procedure Tfrmmain.OnVoiceSpeechStart(Sender: TObject);
begin
  if FAvatar3D <> nil then
    FAvatar3D.SetState(avSpeaking);
  if FPublicViewMode = pvmPresentation then
    SetProfessorState('presenting')
  else
    SetProfessorState('speaking');
end;'''
speech_start_repl = '''procedure Tfrmmain.OnVoiceSpeechStart(Sender: TObject);
begin
  FAssistantSpeaking := True;
  if FContinuousListener <> nil then
    FContinuousListener.NotifyAssistantSpeechStart;

  if FAvatar3D <> nil then
    FAvatar3D.SetState(avSpeaking);
  if FPublicViewMode = pvmPresentation then
    SetProfessorState('presenting')
  else
    SetProfessorState('speaking');
end;'''
if speech_start_target in text:
    text = text.replace(speech_start_target, speech_start_repl, 1)
    print('8. Updated OnVoiceSpeechStart')

speech_end_target = '''procedure Tfrmmain.OnVoiceSpeechEnd(Sender: TObject);
begin
  if FAvatar3D <> nil then
    FAvatar3D.SetState(avIdle);
  SetProfessorState('idle');
end;'''
speech_end_repl = '''procedure Tfrmmain.OnVoiceSpeechEnd(Sender: TObject);
begin
  FAssistantSpeaking := False;
  if FContinuousListener <> nil then
    FContinuousListener.NotifyAssistantSpeechEnd;

  if FAvatar3D <> nil then
    FAvatar3D.SetState(avIdle);

  if (FContinuousListener <> nil) and FContinuousListener.Enabled then
    SetProfessorState('listening')
  else
    SetProfessorState('idle');
end;'''
if speech_end_target in text:
    text = text.replace(speech_end_target, speech_end_repl, 1)
    print('9. Updated OnVoiceSpeechEnd')

# 10. Implement ProcessUserSpeech, ValidateWavFile, and ContinuousListener callbacks
new_methods = '''
function Tfrmmain.ValidateWavFile(const AFileName: string; out AError: string): Boolean;
var
  FS: TFileStream;
  RiffTag, WaveTag: array[0..3] of AnsiChar;
begin
  Result := False;
  AError := '';
  if not FileExists(AFileName) then
  begin
    AError := 'Arquivo de áudio não encontrado';
    Exit;
  end;

  try
    FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      if FS.Size <= 44 then
      begin
        AError := 'Tamanho do arquivo insuficiente';
        Exit;
      end;

      FS.ReadBuffer(RiffTag, 4);
      FS.Position := 8;
      FS.ReadBuffer(WaveTag, 4);
      if (RiffTag <> 'RIFF') or (WaveTag <> 'WAVE') then
      begin
        AError := 'Formato WAV inválido';
        Exit;
      end;

      Result := True;
    finally
      FS.Free;
    end;
  except
    on E: Exception do
      AError := E.Message;
  end;
end;

procedure Tfrmmain.ProcessUserSpeech(const AText: string);
var
  TextoLimpo: string;
begin
  TextoLimpo := Trim(AText);
  if TextoLimpo = '' then Exit;

  AdicionaMensagemHistorico('Você (Voz)', TextoLimpo);

  // Notifica orquestrador de conversação e contexto
  if FConversationOrchestrator <> nil then
  begin
    FConversationOrchestrator.NotifySpeechStart;
    FConversationOrchestrator.Context.ResolveReference(TextoLimpo);
    if (FAssistantManager <> nil) and (FConversationOrchestrator.Context.CurrentProject <> '') then
      FAssistantManager.ActiveProject := FConversationOrchestrator.Context.CurrentProject;
    if FConversationOrchestrator.SessionManager.ActiveSession <> nil then
      FConversationOrchestrator.SessionManager.ActiveSession.AddMessage('user', TextoLimpo);
  end;

  if FAvatar3D <> nil then
  begin
    FAvatar3D.SetState(avListening);
    FAvatar3D.SetState(avThinking);
  end;

  SetProfessorState('thinking');

  // Se o Professor Virtual estiver em apresentação guiada, responde com desvio didático
  if (FPresentationAgent <> nil) and (FPresentationAgent.State in [psPresentingConcept, psGreeting]) then
  begin
    FPresentationAgent.AnswerQuestion(TextoLimpo);
    Exit;
  end;

  // Pipeline Inteligente do Agente
  FAguardandoResposta := True;
  btEnviar.Enabled := False;

  if Assigned(FAssistantManager) then
    FAssistantManager.ProcessUserRequestAsync(TextoLimpo)
  else if Trim(FSetMain.JarvisURL) <> '' then
    TAskJarvisThread.Create(TextoLimpo, FSetMain.JarvisIAMode, FSetMain.JarvisURL, FSetMain.JarvisAPIKey)
  else
    TAskChatGPTThread.Create(TextoLimpo);
end;

procedure Tfrmmain.OnContinuousSpeechUtterance(Sender: TObject; const AWavFileName: string; ADurationMs: Integer);
var
  ValErr: string;
begin
  if not FileExists(AWavFileName) then Exit;

  if not ValidateWavFile(AWavFileName, ValErr) then
  begin
    AdicionaMensagemHistorico('Voz', 'Áudio descartado: ' + ValErr);
    try DeleteFile(AWavFileName); except end;
    Exit;
  end;

  SetProfessorState('thinking');
  AdicionaMensagemHistorico('Voz', Format('🎤 Fala capturada (%.1fs). Reconhecendo...', [ADurationMs / 1000.0]));

  if FVoiceRecog <> nil then
    FVoiceRecog.Recognize(AWavFileName);

  try
    DeleteFile(AWavFileName);
  except
  end;
end;

procedure Tfrmmain.OnContinuousStateChanged(Sender: TObject; AOldState, ANewState: TAIListeningState);
begin
  case ANewState of
    lsListening:
      if not FAssistantSpeaking then
        SetProfessorState('listening');
    lsSpeechDetected, lsCapturingSpeech:
      begin
        if Assigned(lblProfessorStatus) then
        begin
          lblProfessorStatus.Font.Color := $0000D4FF;
          lblProfessorStatus.Caption := '🎤 Você está falando...';
        end;
        if FAvatar3D <> nil then
          FAvatar3D.SetState(avListening);
      end;
    lsProcessing:
      SetProfessorState('thinking');
    lsSuppressedByAssistantSpeech:
      ; // Supressão silenciosa da própria voz
  end;
end;

procedure Tfrmmain.OnContinuousRMSChanged(Sender: TObject; ARMS: Double);
begin
  // Diagnóstico de nível em tempo real
  if Assigned(lblStatVoice) and (FContinuousListener <> nil) and (FContinuousListener.State in [lsListening, lsSpeechDetected, lsCapturingSpeech]) then
  begin
    // Pode ser monitorado no admin
  end;
end;

procedure Tfrmmain.OnContinuousAudioOrigin(Sender: TObject; AOrigin: TAudioOrigin; AConfidence: Double);
begin
  // Monitoramento de origem
end;

procedure Tfrmmain.OnContinuousBargeIn(Sender: TObject);
begin
  AdicionaMensagemHistorico('Voz', '⚡ Interrupção do visitante detectada (Barge-In)!');

  if FVoiceSynth <> nil then
    FVoiceSynth.Stop;
  if (FAudioPlayer <> nil) and FAudioPlayer.Playing then
    FAudioPlayer.Stop;

  FAssistantSpeaking := False;

  if FAvatar3D <> nil then
  begin
    FAvatar3D.CancelGesture;
    FAvatar3D.SetState(avListening);
  end;

  SetProfessorState('listening');

  if FConversationOrchestrator <> nil then
    FConversationOrchestrator.NotifySpeechStart;
end;

procedure Tfrmmain.OnAudioPlayerPlaybackStart(Sender: TObject; const AFileName: string);
begin
  if FContinuousListener <> nil then
  begin
    FContinuousListener.FeedPlaybackWav(AFileName);
    FContinuousListener.NotifyAssistantSpeechStart;
  end;
end;

procedure Tfrmmain.OnAudioPlayerPlaybackStop(Sender: TObject);
begin
  if FContinuousListener <> nil then
    FContinuousListener.NotifyAssistantSpeechEnd;
end;
'''

voice_recog_target = '''procedure Tfrmmain.VoiceRecognized(Sender: TObject; const AText: string);
var
  Info: string;
begin
  Info := Trim(AText);
  if Info <> '' then
  begin
    AdicionaMensagemHistorico('Você (Voz)', Info);
    ExecutaComandoJarvis(Info);
  end;
end;'''

voice_recog_repl = '''procedure Tfrmmain.VoiceRecognized(Sender: TObject; const AText: string);
begin
  ProcessUserSpeech(AText);
end;''' + new_methods

if voice_recog_target in text:
    text = text.replace(voice_recog_target, voice_recog_repl, 1)
    print('10. Replaced VoiceRecognized with ProcessUserSpeech and added callbacks')

# 11. Fix btIniciarClick duplicate execution
bt_target = '''      if (FVoiceRecog <> nil) and FVoiceRecog.Recognize(FListeningWavFile) then
      begin
        AdicionaMensagemHistorico('Você (Voz)', FVoiceRecog.RecognizedText);
        ExecutaComandoJarvis(FVoiceRecog.RecognizedText);
      end'''
bt_repl = '''      if FVoiceRecog <> nil then
      begin
        // Recognize já dispara OnRecognized -> VoiceRecognized -> ProcessUserSpeech
        FVoiceRecog.Recognize(FListeningWavFile);
      end'''
if bt_target in text:
    text = text.replace(bt_target, bt_repl, 1)
    print('11. Fixed duplicate execution in btIniciarClick')

with open(target_path, 'w', encoding='utf-8') as f:
    f.write(text)
print('main.pas updated successfully!')
