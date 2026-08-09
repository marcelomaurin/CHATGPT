unit main;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Forms, Controls, StdCtrls, Dialogs, aispeechrecognizer,
  aiwhisperengine;
type
  TSpeechFileForm = class(TForm)
  private
    FRecognizer: TAISpeechRecognizer; FEngine: TAIWhisperProcessEngine;
    FFile, FCLI, FModel: TEdit; FResult: TMemo; FDialog: TOpenDialog;
    procedure SelectFile(Sender: TObject); procedure Transcribe(Sender: TObject);
    procedure TextReady(Sender: TObject; const AText: string);
    procedure ErrorReady(Sender: TObject; const AError: string);
  public constructor Create(AOwner: TComponent); override; end;
var SpeechFileForm: TSpeechFileForm;
implementation
function AddEdit(AForm:TForm; const ACaption,AValue:string; ATop:Integer):TEdit;
var L:TLabel; begin L:=TLabel.Create(AForm); L.Parent:=AForm; L.Caption:=ACaption;
  L.Left:=12; L.Top:=ATop+4; Result:=TEdit.Create(AForm); Result.Parent:=AForm;
  Result.Left:=125; Result.Top:=ATop; Result.Width:=590; Result.Text:=AValue; end;
constructor TSpeechFileForm.Create(AOwner:TComponent);
var B:TButton;
begin inherited CreateNew(AOwner,1); Caption:='Speech file demo'; Width:=760; Height:=480;
  Position:=poScreenCenter; FCLI:=AddEdit(Self,'whisper-cli',GetEnvironmentVariable('WHISPER_CLI'),16);
  FModel:=AddEdit(Self,'Modelo',GetEnvironmentVariable('WHISPER_MODEL'),48);
  FFile:=AddEdit(Self,'Arquivo WAV','',80); B:=TButton.Create(Self); B.Parent:=Self;
  B.Caption:='Selecionar'; B.Left:=620; B.Top:=112; B.OnClick:=@SelectFile;
  B:=TButton.Create(Self); B.Parent:=Self; B.Caption:='Transcrever'; B.Left:=12; B.Top:=112; B.OnClick:=@Transcribe;
  FResult:=TMemo.Create(Self); FResult.Parent:=Self; FResult.SetBounds(12,152,720,270); FResult.ScrollBars:=ssAutoBoth;
  FDialog:=TOpenDialog.Create(Self); FDialog.Filter:='Audio WAV|*.wav|Todos|*.*';
  FEngine:=TAIWhisperProcessEngine.Create(Self); FRecognizer:=TAISpeechRecognizer.Create(Self);
  FRecognizer.Engine:=FEngine; FRecognizer.OnText:=@TextReady; FRecognizer.OnError:=@ErrorReady;
end;
procedure TSpeechFileForm.SelectFile(Sender:TObject); begin if FDialog.Execute then FFile.Text:=FDialog.FileName; end;
procedure TSpeechFileForm.Transcribe(Sender:TObject); begin FEngine.ExecutablePath:=FCLI.Text;
  FEngine.ModelPath:=FModel.Text; FRecognizer.ModelPath:=FModel.Text;
  if not FRecognizer.TranscribeFile(FFile.Text) then FResult.Lines.Add('ERRO: '+FRecognizer.LastError); end;
procedure TSpeechFileForm.TextReady(Sender:TObject;const AText:string); begin FResult.Lines.Text:=AText; end;
procedure TSpeechFileForm.ErrorReady(Sender:TObject;const AError:string); begin FResult.Lines.Add('ERRO: '+AError); end;
end.
