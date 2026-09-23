unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiavatartypes, aiavatar3d;

type
  { TFormMain }
  TFormMain = class(TForm)
    btnHappy: TButton;
    btnIdle: TButton;
    btnLoad: TButton;
    btnNod: TButton;
    btnSad: TButton;
    btnThink: TButton;
    btnWave: TButton;
    OpenDialog1: TOpenDialog;
    pnlControls: TPanel;
    pnlDisplay: TPanel;
    procedure btnHappyClick(Sender: TObject);
    procedure btnIdleClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnNodClick(Sender: TObject);
    procedure btnSadClick(Sender: TObject);
    procedure btnThinkClick(Sender: TObject);
    procedure btnWaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAvatar: TAIAvatar3D;
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
  FAvatar.AutoIdle := True;
  FAvatar.AutoBlink := True;
end;

procedure TFormMain.btnLoadClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FAvatar.LoadAvatar(OpenDialog1.FileName);
    pnlDisplay.Caption := 'Avatar Carregado: ' + ExtractFileName(OpenDialog1.FileName);
  end;
end;

procedure TFormMain.btnIdleClick(Sender: TObject);
begin
  FAvatar.SetState(avIdle);
  pnlDisplay.Caption := 'Estado: Idle (Auto-Idle ativo)';
end;

procedure TFormMain.btnWaveClick(Sender: TObject);
begin
  FAvatar.PlayGesture(agWave);
  pnlDisplay.Caption := 'Gesto: Wave (Aceno)';
end;

procedure TFormMain.btnNodClick(Sender: TObject);
begin
  FAvatar.PlayGesture(agNod);
  pnlDisplay.Caption := 'Gesto: Nod (Concordar)';
end;

procedure TFormMain.btnThinkClick(Sender: TObject);
begin
  FAvatar.PlayGesture(agThink);
  pnlDisplay.Caption := 'Gesto: Think (Pensar)';
end;

procedure TFormMain.btnHappyClick(Sender: TObject);
begin
  FAvatar.SetEmotion(aeHappy, 0.8);
  pnlDisplay.Caption := 'Emocao: Feliz (Happy 0.8)';
end;

procedure TFormMain.btnSadClick(Sender: TObject);
begin
  FAvatar.SetEmotion(aeSad, 0.7);
  pnlDisplay.Caption := 'Emocao: Triste (Sad 0.7)';
end;

end.
