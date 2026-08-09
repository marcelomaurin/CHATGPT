unit main;
{$mode objfpc}{$H+}
interface
uses Classes,SysUtils,Forms,Controls,StdCtrls,Dialogs,aif5ttsengine,aivoiceclone,aiaudioplayback;
type TVoiceCloneForm=class(TForm)
private FEngine:TAIF5TTSProcessEngine;FClone:TAIVoiceClone;FRef,FOwner,FOutput:TEdit;
  FText,FLog:TMemo;FConsent:TCheckBox;FDialog:TOpenDialog;FPlayer:TAIAudioPlayer;
  procedure SelectRef(Sender:TObject);procedure Generate(Sender:TObject);procedure Play(Sender:TObject);
  procedure Progress(Sender:TObject;APercent:Integer;const AMessage:string);
  procedure Finished(Sender:TObject;ASuccess:Boolean;const AOutput:string);
public constructor Create(AOwner:TComponent);override;end;
var VoiceCloneForm:TVoiceCloneForm;
implementation
function EditAt(F:TForm;const C,V:string;Y:Integer):TEdit;var L:TLabel;begin L:=TLabel.Create(F);L.Parent:=F;L.Caption:=C;L.SetBounds(12,Y+4,100,24);
 Result:=TEdit.Create(F);Result.Parent:=F;Result.SetBounds(120,Y,580,28);Result.Text:=V;end;
constructor TVoiceCloneForm.Create(AOwner:TComponent);var B:TButton;L:TLabel;
begin inherited CreateNew(AOwner,1);Caption:='Voice clone demo';Width:=760;Height:=610;Position:=poScreenCenter;
 FRef:=EditAt(Self,'Referencia','',12);B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Selecionar';B.SetBounds(600,44,100,28);B.OnClick:=@SelectRef;
 FOwner:=EditAt(Self,'Titular','',76);FOutput:=EditAt(Self,'Saida',IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName))+'output'+DirectorySeparator+'clone.wav',108);
 FConsent:=TCheckBox.Create(Self);FConsent.Parent:=Self;FConsent.Caption:='Confirmo consentimento explicito do titular';FConsent.SetBounds(120,140,400,28);
 L:=TLabel.Create(Self);L.Parent:=Self;L.Caption:='Texto';L.SetBounds(12,176,100,24);FText:=TMemo.Create(Self);FText.Parent:=Self;FText.SetBounds(120,176,580,100);FText.Text:='Texto de demonstracao autorizado.';
 B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Gerar';B.SetBounds(120,288,100,32);B.OnClick:=@Generate;
 B:=TButton.Create(Self);B.Parent:=Self;B.Caption:='Reproduzir';B.SetBounds(232,288,100,32);B.OnClick:=@Play;
 FLog:=TMemo.Create(Self);FLog.Parent:=Self;FLog.SetBounds(12,336,688,210);FLog.ScrollBars:=ssAutoBoth;
 FDialog:=TOpenDialog.Create(Self);FDialog.Filter:='Audio WAV|*.wav|Todos|*.*';FPlayer:=TAIAudioPlayer.Create(Self);
 FEngine:=TAIF5TTSProcessEngine.Create(Self);FEngine.PythonPath:=GetEnvironmentVariable('F5_PYTHON');FEngine.F5TTSPath:=GetEnvironmentVariable('F5_TTS_PATH');FEngine.ModelPath:=GetEnvironmentVariable('F5_TTS_MODEL');
 FClone:=TAIVoiceClone.Create(Self);FClone.Engine:=FEngine;FClone.OnProgress:=@Progress;FClone.OnFinish:=@Finished;
end;
procedure TVoiceCloneForm.SelectRef(Sender:TObject);begin if FDialog.Execute then FRef.Text:=FDialog.FileName;end;
procedure TVoiceCloneForm.Generate(Sender:TObject);begin FClone.ReferenceAudio:=FRef.Text;FClone.VoiceOwner:=FOwner.Text;FClone.ConsentConfirmed:=FConsent.Checked;FClone.OutputFile:=FOutput.Text;
 if not FClone.Synthesize(FText.Text) then FLog.Lines.Add('ERRO: '+FClone.LastError);end;
procedure TVoiceCloneForm.Play(Sender:TObject);begin if not FileExists(FClone.LastOutputFile) then begin FLog.Lines.Add('Nenhum WAV valido gerado.');Exit;end;
 if not FPlayer.Play(FClone.LastOutputFile) then FLog.Lines.Add('ERRO PLAYER: '+FPlayer.LastError);end;
procedure TVoiceCloneForm.Progress(Sender:TObject;APercent:Integer;const AMessage:string);begin FLog.Lines.Add(IntToStr(APercent)+'% '+AMessage);end;
procedure TVoiceCloneForm.Finished(Sender:TObject;ASuccess:Boolean;const AOutput:string);begin if ASuccess then FLog.Lines.Add('WAV gerado: '+AOutput) else FLog.Lines.Add('Falha; nenhum audio foi declarado como gerado.');end;
end.
