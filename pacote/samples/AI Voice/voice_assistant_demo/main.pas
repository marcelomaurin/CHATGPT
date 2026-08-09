unit main;
{$mode objfpc}{$H+}
interface
uses Classes,SysUtils,Forms,Controls,StdCtrls,aiaudio,aiwhisperengine,
 aispeechrecognizer,chatgpt,aif5ttsengine,aivoiceclone,aivoiceassistant,aiaudioplayback;
type TVoiceAssistantForm=class(TForm)
private FAudio:TAIAudioInput;FWhisper:TAIWhisperProcessEngine;FRecognizer:TAISpeechRecognizer;
 FChat:TCHATGPT;FF5:TAIF5TTSProcessEngine;FClone:TAIVoiceClone;FAssistant:TAIVoiceAssistant;
 FInput,FOwner:TEdit;FConsent:TCheckBox;FHistory:TMemo;FPlayer:TAIAudioPlayer;
 procedure Listen(Sender:TObject);procedure StopSend(Sender:TObject);procedure SendText(Sender:TObject);procedure Cancel(Sender:TObject);
 procedure Recognized(Sender:TObject;const AText:string);procedure Response(Sender:TObject;const AText:string);
 procedure AudioReady(Sender:TObject;const AFile:string);procedure ApplyConsent;
public constructor Create(AOwner:TComponent);override;end;
var VoiceAssistantForm:TVoiceAssistantForm;
implementation
constructor TVoiceAssistantForm.Create(AOwner:TComponent);var B:TButton;L:TLabel;URL:string;
begin inherited CreateNew(AOwner,1);Caption:='Voice assistant: Microfone -> STT -> LLM -> Voz';Width:=860;Height:=590;Position:=poScreenCenter;
 L:=TLabel.Create(Self);L.Parent:=Self;L.Caption:='Entrada';L.SetBounds(12,16,80,24);FInput:=TEdit.Create(Self);FInput.Parent:=Self;FInput.SetBounds(90,12,730,28);
 FOwner:=TEdit.Create(Self);FOwner.Parent:=Self;FOwner.SetBounds(90,48,300,28);FOwner.Text:='Titular autorizado';L:=TLabel.Create(Self);L.Parent:=Self;L.Caption:='Titular';L.SetBounds(12,52,80,24);
 FConsent:=TCheckBox.Create(Self);FConsent.Parent:=Self;FConsent.Caption:='Consentimento confirmado';FConsent.SetBounds(410,48,250,28);
 B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Ouvir';B.SetBounds(12,88,90,32);B.OnClick:=@Listen;
 B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Parar + enviar';B.SetBounds(112,88,120,32);B.OnClick:=@StopSend;
 B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Enviar texto';B.SetBounds(242,88,110,32);B.OnClick:=@SendText;
 B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Cancelar';B.SetBounds(362,88,100,32);B.OnClick:=@Cancel;
 FHistory:=TMemo.Create(Self);FHistory.Parent:=Self;FHistory.SetBounds(12,136,808,390);FHistory.ScrollBars:=ssAutoBoth;
 FPlayer:=TAIAudioPlayer.Create(Self);
 FAudio:=TAIAudioInput.Create(Self);FWhisper:=TAIWhisperProcessEngine.Create(Self);FRecognizer:=TAISpeechRecognizer.Create(Self);
 FChat:=TCHATGPT.Create(Self);FF5:=TAIF5TTSProcessEngine.Create(Self);FClone:=TAIVoiceClone.Create(Self);FAssistant:=TAIVoiceAssistant.Create(Self);
 FWhisper.ExecutablePath:=GetEnvironmentVariable('WHISPER_CLI');FWhisper.ModelPath:=GetEnvironmentVariable('WHISPER_MODEL');FRecognizer.Engine:=FWhisper;FRecognizer.ModelPath:=FWhisper.ModelPath;FRecognizer.AudioInput:=FAudio;
 URL:=GetEnvironmentVariable('AI_LLM_URL');if URL<>'' then begin FChat.Provider:=AIP_OPENAI_COMPATIBLE;FChat.URL:=URL;end;FChat.TOKEN:=GetEnvironmentVariable('OPENAI_API_KEY');FChat.CustomModel:=GetEnvironmentVariable('AI_LLM_MODEL');
 FF5.PythonPath:=GetEnvironmentVariable('F5_PYTHON');FF5.F5TTSPath:=GetEnvironmentVariable('F5_TTS_PATH');FF5.ModelPath:=GetEnvironmentVariable('F5_TTS_MODEL');FClone.Engine:=FF5;FClone.ReferenceAudio:=GetEnvironmentVariable('VOICE_REFERENCE');FClone.OutputFile:=IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'output'+DirectorySeparator+'assistant.wav';
 FAssistant.Recognizer:=FRecognizer;FAssistant.ChatGPT:=FChat;FAssistant.VoiceClone:=FClone;FAssistant.OnRecognized:=@Recognized;FAssistant.OnResponse:=@Response;FAssistant.OnAudioReady:=@AudioReady;
end;
procedure TVoiceAssistantForm.ApplyConsent;begin FClone.ConsentConfirmed:=FConsent.Checked;FClone.VoiceOwner:=FOwner.Text;end;
procedure TVoiceAssistantForm.Listen(Sender:TObject);var P:string;begin ApplyConsent;P:=IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'output'+DirectorySeparator+'assistant_input.wav';if not FAssistant.StartListening(P) then FHistory.Lines.Add('ERRO STT: '+FAssistant.LastError);end;
procedure TVoiceAssistantForm.StopSend(Sender:TObject);begin ApplyConsent;if not FAssistant.StopListeningAndRespond then FHistory.Lines.Add('ERRO PIPELINE: '+FAssistant.LastError);end;
procedure TVoiceAssistantForm.SendText(Sender:TObject);begin ApplyConsent;if not FAssistant.ProcessText(FInput.Text) then FHistory.Lines.Add('ERRO PIPELINE: '+FAssistant.LastError);end;
procedure TVoiceAssistantForm.Cancel(Sender:TObject);begin FAssistant.Cancel;FHistory.Lines.Add('Cancelado em todas as etapas.');end;
procedure TVoiceAssistantForm.Recognized(Sender:TObject;const AText:string);begin FInput.Text:=AText;FHistory.Lines.Add('VOCE: '+AText);end;
procedure TVoiceAssistantForm.Response(Sender:TObject;const AText:string);begin FHistory.Lines.Add('IA: '+AText);end;
procedure TVoiceAssistantForm.AudioReady(Sender:TObject;const AFile:string);begin FHistory.Lines.Add('AUDIO: '+AFile);if not FPlayer.Play(AFile) then FHistory.Lines.Add('ERRO PLAYER: '+FPlayer.LastError);end;
end.
