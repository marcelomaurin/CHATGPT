unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiavatartypes, aiavatar3d, aiagent;

type
  { TFormMain }
  TFormMain = class(TForm)
    btnAsk: TButton;
    edtPrompt: TEdit;
    memoLog: TMemo;
    pnlBottom: TPanel;
    procedure btnAskClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAvatar: TAIAvatar3D;
    FAgent: TAIAgent;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  FAvatar := TAIAvatar3D.Create(Self);
  FAgent := TAIAgent.Create(Self);
  memoLog.Lines.Add('Sistema inicializado. Digite uma pergunta para o Agente com avatar.');
end;

procedure TFormMain.btnAskClick(Sender: TObject);
var
  SimulatedJSON: string;
begin
  if Trim(edtPrompt.Text) = '' then Exit;

  memoLog.Lines.Add('Usuario: ' + edtPrompt.Text);
  FAvatar.SetState(avThinking);
  memoLog.Lines.Add('Avatar: Thinking...');

  // Resposta estruturada JSON da IA (Tarefa 79 e 88)
  SimulatedJSON := '{"text":"Estou muito feliz em conversar com voce! Tudo esta funcionando perfeitamente.", "emotion":"happy", "gesture":"wave", "intensity":0.85}';

  FAvatar.ApplyAgentResponse(SimulatedJSON);
  memoLog.Lines.Add('IA Resposta Aplicada: ' + SimulatedJSON);
  memoLog.Lines.Add('Avatar Estado: Speaking | Emocao: ' + AvatarEmotionToString(FAvatar.Emotion) + ' | Gesto: ' + AvatarGestureToString(FAvatar.Gesture));
end;

end.
