unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, chatgpt;

type

  { Tfrmmain }

  Tfrmmain = class(TForm)
    Button1: TButton;
    CHATGPT1: TCHATGPT;
    edpergunta: TEdit;
    meresposta: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

var
  frmmain: Tfrmmain;

implementation

{$R *.lfm}

{ Tfrmmain }

procedure Tfrmmain.FormCreate(Sender: TObject);
begin

end;

procedure Tfrmmain.Button1Click(Sender: TObject);
begin
  CHATGPT1.SendQuestion(edpergunta.text);
  meresposta.Lines.text := CHATGPT1.Response;
end;

end.

