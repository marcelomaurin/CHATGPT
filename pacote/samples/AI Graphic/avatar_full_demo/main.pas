unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiavatartypes, aiavatar3d, aivoicesynthesizer, aiagent;

type
  { TFormMain }
  TFormMain = class(TForm)
    btnSend: TButton;
    chkDebug: TCheckBox;
    edtChat: TEdit;
    memoChat: TMemo;
    pnlBottom: TPanel;
    pnlTop: TPanel;
    procedure btnSendClick(Sender: TObject);
    procedure chkDebugChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAvatar: TAIAvatar3D;
    FVoice: TAIVoiceSynthesizer;
    FAgent: TAIAgent;
    procedure LogEvent(const Msg: string);
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
  FVoice := TAIVoiceSynthesizer.Create(Self);
  FAgent := TAIAgent.Create(Self);
  FAvatar.VoiceSynthesizer := FVoice;
  FAvatar.ShowDebugPanel := True;
  chkDebug.Checked := True;

  LogEvent('[SISTEMA] Avatar 3D e componentes de IA carregados com sucesso.');
end;

procedure TFormMain.LogEvent(const Msg: string);
begin
  memoChat.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
end;

procedure TFormMain.chkDebugChange(Sender: TObject);
begin
  FAvatar.ShowDebugPanel := chkDebug.Checked;
  if FAvatar.ShowDebugPanel then
    LogEvent(FAvatar.GetDebugInfoText);
end;

procedure TFormMain.btnSendClick(Sender: TObject);
var
  RespJSON: string;
begin
  if Trim(edtChat.Text) = '' then Exit;

  LogEvent('Usuario: ' + edtChat.Text);
  FAvatar.SetState(avListening);
  LogEvent('Avatar: escutando...');

  FAvatar.SetState(avThinking);
  LogEvent('Avatar: pensando...');

  // Resposta estruturada simulada
  RespJSON := '{"text":"O subsistema 3D contem carregador glTF, esqueleto humanoide, controlador de gestos, lip-sync e orquestrador de alto nivel.", "emotion":"confident", "gesture":"explain", "intensity":0.9}';

  FAvatar.ApplyAgentResponse(RespJSON);
  LogEvent('Avatar falando com gesto de explicacao.');

  if FAvatar.ShowDebugPanel then
    LogEvent(FAvatar.GetDebugInfoText);
end;

end.
