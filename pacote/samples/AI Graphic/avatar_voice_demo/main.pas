unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aiavatartypes, aiavatar3d, aivoicesynthesizer;

type
  { TFormMain }
  TFormMain = class(TForm)
    btnSpeak: TButton;
    edtText: TEdit;
    pnlBottom: TPanel;
    pnlDisplay: TPanel;
    procedure btnSpeakClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FAvatar: TAIAvatar3D;
    FVoice: TAIVoiceSynthesizer;
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
  FAvatar.VoiceSynthesizer := FVoice;
end;

procedure TFormMain.btnSpeakClick(Sender: TObject);
begin
  if Trim(edtText.Text) <> '' then
  begin
    FAvatar.SetState(avSpeaking);
    FVoice.Say(edtText.Text);
    pnlDisplay.Caption := 'Falando: ' + edtText.Text;
  end;
end;

end.
