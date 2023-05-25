unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  chatgpt, IdHTTP, IdSSLOpenSSL;

type

  { Tfrmdemo1 }

  Tfrmdemo1 = class(TForm)
    btSubmit: TButton;
    btRegistry: TButton;
    edASK: TEdit;
    edToken: TEdit;
    IdHTTP1: TIdHTTP;
    IdSSLIOHandlerSocketOpenSSL1: TIdSSLIOHandlerSocketOpenSSL;
    Label1: TLabel;
    meConversation: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure btRegistryClick(Sender: TObject);
    procedure btSubmitClick(Sender: TObject);
    procedure edASKKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FChatgpt : TCHATGPT;
    procedure CallASK();

  public

  end;

var
  frmdemo1: Tfrmdemo1;

implementation

{$R *.lfm}

{ Tfrmdemo1 }

procedure Tfrmdemo1.FormCreate(Sender: TObject);
begin
  FChatgpt := TChatgpt.create(VCT_GPT35TURBO);
  FChatgpt.IdHTTP := IdHTTP1;
end;

procedure Tfrmdemo1.btRegistryClick(Sender: TObject);
begin
  FChatgpt.TOKEN:= edToken.text;
end;

procedure Tfrmdemo1.btSubmitClick(Sender: TObject);
begin
  CallASK();
end;

procedure Tfrmdemo1.edASKKeyPress(Sender: TObject; var Key: char);
begin
  if (key = #13) then
  begin
    FChatgpt.SendQuestion(edASK.text);
  end;
end;

procedure Tfrmdemo1.FormDestroy(Sender: TObject);
begin
  FChatgpt.free;
end;

procedure Tfrmdemo1.CallASK;
begin
  FChatgpt.SendQuestion(edASK.text);
end;

end.

