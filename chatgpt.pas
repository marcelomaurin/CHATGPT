unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fphttpclient;



{ TCHATGPT }

 type TVersionChat = (VCT_GPT35TURBO, VCT_GPT40 );

 //Class to do connect with chatgpt
 type  TCHATGPT = class(TObject)
  private
    FToken : String; //private variable to use chatgp
    FQuestion : String;
    FResponse : String;
    FTipoChat : TVersionChat;

  public
    property TOKEN : String read FToken write FToken; //property to access chatgpt
    property Question : String read FQuestion;
    property Response : String read FResponse write FResponse;
    property TipoChat : TVersionChat read FTipoChat;
    function SendQuestion( ASK : String) : boolean;
    constructor create(Tipo : TVersionChat);
    destructor Destroy;

end;

implementation

{ TCHATGPT }

function TCHATGPT.SendQuestion(ASK: String): boolean;
var
  JSON : String;
  ASKENCODE : String;
  resposta : boolean;
begin
     resposta := false;
     ASKENCODE := EncodeURLElement(ConsoleToUTF8(ASK));
     JSON := '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "'+ASKENCODE+'"}]}';

     result := resposta;
end;

//Class Constructor
constructor TCHATGPT.create(Tipo : TVersionChat);
begin
     FTipoChat:= Tipo;
end;

destructor TCHATGPT.Destroy;
begin
  //not yet
end;

end.

