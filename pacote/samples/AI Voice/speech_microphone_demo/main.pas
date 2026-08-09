unit main;
{$mode objfpc}{$H+}
interface
uses Classes,SysUtils,Forms,Controls,StdCtrls,aiaudio,aispeechrecognizer,aiwhisperengine;
type TSpeechMicForm=class(TForm)
private FAudio:TAIAudioInput; FRecognizer:TAISpeechRecognizer; FEngine:TAIWhisperProcessEngine;
  FLog:TMemo; FContinuous:TCheckBox; procedure StartClick(Sender:TObject);
  procedure StopClick(Sender:TObject); procedure CancelClick(Sender:TObject);
  procedure Partial(Sender:TObject;const AText:string); procedure FinalText(Sender:TObject;const AText:string);
  procedure ErrorText(Sender:TObject;const AText:string);
public constructor Create(AOwner:TComponent);override;end;
var SpeechMicForm:TSpeechMicForm;
implementation
constructor TSpeechMicForm.Create(AOwner:TComponent);
var B:TButton;
begin inherited CreateNew(AOwner,1); Caption:='Speech microphone demo';Width:=720;Height:=440;Position:=poScreenCenter;
  FContinuous:=TCheckBox.Create(Self);FContinuous.Parent:=Self;FContinuous.Caption:='Ouvir continuamente (processa blocos ao parar)';FContinuous.SetBounds(12,12,360,28);
  B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Ouvir';B.SetBounds(12,48,100,32);B.OnClick:=@StartClick;
  B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Parar';B.SetBounds(124,48,100,32);B.OnClick:=@StopClick;
  B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Cancelar';B.SetBounds(236,48,100,32);B.OnClick:=@CancelClick;
  FLog:=TMemo.Create(Self);FLog.Parent:=Self;FLog.SetBounds(12,96,680,290);FLog.ScrollBars:=ssAutoBoth;
  FAudio:=TAIAudioInput.Create(Self);FEngine:=TAIWhisperProcessEngine.Create(Self);FRecognizer:=TAISpeechRecognizer.Create(Self);
  FEngine.ExecutablePath:=GetEnvironmentVariable('WHISPER_CLI');FEngine.ModelPath:=GetEnvironmentVariable('WHISPER_MODEL');
  FRecognizer.Engine:=FEngine;FRecognizer.AudioInput:=FAudio;FRecognizer.ModelPath:=FEngine.ModelPath;
  FRecognizer.OnPartialText:=@Partial;FRecognizer.OnText:=@FinalText;FRecognizer.OnError:=@ErrorText;
end;
procedure TSpeechMicForm.StartClick(Sender:TObject);var P:string;begin FRecognizer.Continuous:=FContinuous.Checked;
  P:=IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'output'+DirectorySeparator+'microphone.wav';
  if FRecognizer.StartListening(P) then FLog.Lines.Add('Ouvindo...') else FLog.Lines.Add('ERRO: '+FRecognizer.LastError);end;
procedure TSpeechMicForm.StopClick(Sender:TObject);begin if not FRecognizer.StopListening then FLog.Lines.Add('ERRO: '+FRecognizer.LastError);end;
procedure TSpeechMicForm.CancelClick(Sender:TObject);begin FRecognizer.Cancel;FLog.Lines.Add('Cancelado.');end;
procedure TSpeechMicForm.Partial(Sender:TObject;const AText:string);begin FLog.Lines.Add('PARCIAL: '+AText);end;
procedure TSpeechMicForm.FinalText(Sender:TObject;const AText:string);begin FLog.Lines.Add('FINAL: '+AText);end;
procedure TSpeechMicForm.ErrorText(Sender:TObject;const AText:string);begin FLog.Lines.Add('ERRO: '+AText);end;
end.
