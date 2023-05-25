unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { Tfrmdemo1 }

  Tfrmdemo1 = class(TForm)
    btSubmit: TButton;
    edASK: TEdit;
    edToken: TEdit;
    Label1: TLabel;
    meConversation: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
  private

  public

  end;

var
  frmdemo1: Tfrmdemo1;

implementation

{$R *.lfm}

end.

