unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, IdHTTP, IdSSLOpenSSL;



{ TCHATGPT }

 type TVersionChat = (VCT_GPT35TURBO, VCT_GPT40 );

 //Class to do connect with chatgpt
 type  TCHATGPT = class(TObject)
  private
    FToken : String; //private variable to use chatgp
    FQuestion : String;
    FResponse : String;
    FTipoChat : TVersionChat;
    function RequestJson(URL : String; token : string ; JSON : string) : String;
    function EncodeURLElement(const AValue: string): string;
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

function TCHATGPT.RequestJson(URL: String; token : string ;JSON: String): String;
var
  RequestBody: TStringStream;
  Resp: string;
  IdHTTP1 : TIdHTTP;
  IdSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
begin
  Resp := '';
   // Crie um TStringStream contendo o JSON
  RequestBody := TStringStream.Create(JSON, TEncoding.UTF8);

  IdHTTP1 := TIdHTTP.Create(nil);
  // Crie e configure o TIdSSLIOHandlerSocketOpenSSL
  IdSSLIOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  IdHTTP1.IOHandler := IdSSLIOHandler;
  try
    // Configurar outras opções do TIdHTTP, se necessário
    dHTTP1.HandleRedirects := True;
    // Defina o cabeçalho Content-Type como application/json
    IdHTTP1.Request.ContentType := 'application/json';
    IdHTTP1.Request.UserAgent := 'MAURINSOFT/1.0';

    // Adicione o header personalizado
    //Authorization: Bearer %s", TOCKENChat
    IdHTTP1.Request.CustomHeaders.Add('Authorization: Bearer '+token);

    // Envie o POST com o JSON no corpo da solicitação
    Resp := IdHTTP1.Post(URL, RequestBody);

    // Faça algo com a resposta
    //ShowMessage(Response);
  finally
    RequestBody.Free;
    // Libere a memória dos objetos criados
    IdHTTP1.Free;
    IdSSLIOHandler.Free;
  end;
  result := Resp;

end;

function TCHATGPT.EncodeURLElement(const AValue: string): string;
const
  HexChars = '0123456789ABCDEF';
var
  Source: PAnsiChar;
  Dest: PAnsiChar;
  CharCode: Byte;
begin
  SetLength(Result, Length(AValue) * 3);
  Source := PAnsiChar(AValue);
  Dest := PAnsiChar(Result);
  while Source^ <> #0 do
  begin
    if Source^ in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_', '.', '~'] then
    begin
      Dest^ := AnsiChar(Source^);
      Inc(Dest);
    end
    else if Source^ = ' ' then
    begin
      Dest^ := '%';
      Inc(Dest);
      Dest^ := '2';
      Inc(Dest);
      Dest^ := '0';
      Inc(Dest);
    end
    else
    begin
      CharCode := Ord(Source^);
      Dest^ := '%';
      Inc(Dest);
      Dest^ := HexChars[(CharCode shr 4) + 1];
      Inc(Dest);
      Dest^ := HexChars[(CharCode and $F) + 1];
      Inc(Dest);
    end;
    Inc(Source);
  end;
  SetLength(Result, Dest - PAnsiChar(Result));
end;


function TCHATGPT.SendQuestion(ASK: String): boolean;
var
  URL : String;
  JSON : String;
  ASKENCODE : String;
  resposta : boolean;
begin
     resposta := false;
     ASKENCODE := EncodeURLElement(ConsoleToUTF8(ASK));
     URL := 'https://api.openai.com/v1/chat/completions';
     JSON := '{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "'+ASKENCODE+'"}]}';
     Response := RequestJson(URL, FToken, JSON);
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

