unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser,
  fphttpclient, opensslsockets;

{ TCHATGPT }

 type TVersionChat = (VCT_GPT35TURBO, VCT_GPT40 );

 //Class to do connect with chatgpt
 type  TCHATGPT = class(TComponent)
  private
    FToken : String; //private variable to use chatgp
    FQuestion : String;
    FResponse : String;
    FTipoChat : TVersionChat;
    FParams: TStrings;
    function RequestJson(LURL : String; token : string ; ASK : string) : String;
    function PegaMensagem(const JSON: string): string;
    //function RequestJson2(LURL: string; token: string; JSON: string): string;
  public
    property TOKEN : String read FToken write FToken; //property to access chatgpt
    property Question : String read FQuestion;
    property Response : String read FResponse write FResponse;
    property TipoChat : TVersionChat read FTipoChat;
    function SendQuestion( ASK : String) : boolean;

    constructor create(AOwner: TComponent); override;
    destructor Destroy;

end;

implementation

{ TCHATGPT }
(*
function TCHATGPT.RequestJson2(LURL: string; token: string; JSON: string): string;

var
  ClienteHTTP: THTTPClient;
  Dados: TStringStream;
  Resposta: string;
begin
  Resposta := '';
  ClienteHTTP := THTTPClient.Create;
  try
    Dados := TStringStream.Create(JSON);
    try
      ClienteHTTP.RequestHeaders['Content-Type'] := 'application/json';
      ClienteHTTP.RequestHeaders['Authorization'] := 'Bearer ' + token;

      ClienteHTTP.Post(LURL, Dados);

      Resposta := ClienteHTTP.ResponseText;
    finally
      Dados.Free;
    end;
  finally
    ClienteHTTP.Free;
  end;

  Result := Resposta;
end;
    *)


function TCHATGPT.PegaMensagem(const JSON: string): string;
var
  Data: TJSONData;
  JsonObject: TJSONObject;
begin
  // Cria um objeto TJSONData a partir da string JSON
  Data := GetJSON(JSON);

  try
    // Verifica se o objeto é um TJSONObject
    if Data is TJSONObject then
    begin
      // Converte o objeto para um TJSONObject
      JsonObject := TJSONObject(Data);

      // Obtém o valor do campo "message"
      Result := JsonObject.GetPath('choices[0].message.content').AsString;
    end
    else
    begin
      // Objeto JSON inválido, retorna uma string vazia ou lança uma exceção, conforme necessário
      Result := '';
    end;
  finally
    Data.Free; // Libera a memória do objeto TJSONData
  end;
end;

function TCHATGPT.RequestJson(LURL: string; token: string; ASK: string): string;

var
  ClienteHTTP: TFPHttpClient;
  Resposta : AnsiString;
  LResponse: TStringStream;
  formulario : string;
  Params: string;
begin
  //Resposta := '';
  Formulario := '' ;
  params :=  '{ "model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "'+ASK +'"}]  }';
  ClienteHTTP := TFPHttpClient.Create(nil);
  try
    LResponse := TStringStream.Create('');
    ClienteHTTP.AddHeader('Content-Type', 'application/json;');
    ClienteHTTP.AddHeader('Authorization',' Bearer ' + EncodeURLElement(token));
    ClienteHTTP.RequestBody := TRawByteStringStream.Create(Params);
    try
            //resposta:= ClienteHTTP.SimpleFormPost(LURL, formulario);
            resposta:=  ClienteHTTP.Post(LURL);
     except on E: Exception do
            //Writeln('Something bad happened: ' + E.Message);
            //Resposta.read;
     end;
  finally

      (*
      {"id":"chatcmpl-7Lcq4Pi5m9sGZBLbH0VoXR0GOjgkh",
      "object":"chat.completion","created":1685388540,
      "model":"gpt-3.5-turbo-0301","usage":{"prompt_tokens":15,"completion_tokens":29,"total_tokens":44},"choices":[{"message":{"role":"assistant","content":"1, 2, 3, 4, 5, 6, 7, 8, 9, 10."},"finish_reason":"stop","index":0}]}
      *)

      Result := resposta;
      ClienteHTTP.RequestBody.Free;
      ClienteHTTP.Free;


      //Resposta.Free;

  end;


      //Resposta := ClienteHTTP.ResponseText;
      //Resposta:= ClienteHTTP.Get(LURL);
    //finally
    //  Dados.Free;
   // end;
  //finally
  //  ClienteHTTP.Free;



end;

function TCHATGPT.SendQuestion(ASK: String): boolean;
var
  LURL : String;
  JSON : String;
  AUX : String;
  resposta : boolean;
begin
     resposta := false;

     LURL := 'https://api.openai.com/v1/chat/completions';
     //JSON := EncodeURLElement('{"model": "gpt-3.5-turbo", "messages": [{"role": "user", "content": "'+ASK+'"}]}');

     AUX := RequestJson(LURL, FToken, EncodeURLElement(ASK));
     try
       FResponse := PegaMensagem(AUX);
     except
       FResponse := AUX
     end;

     //FResponse := RequestJson2(LURL, FToken, JSON);
     result := resposta;
end;

//Class Constructor
constructor TCHATGPT.create(AOwner: TComponent);

begin
  inherited Create(AOwner);
  FTipoChat:= VCT_GPT35TURBO;
  //HTTPSend.Sock.SSL.SSLType := LT_TLSv1;
  //Self.IsUTF8 := False;
  FParams := TStringList.Create;
end;

destructor TCHATGPT.Destroy;
begin
    FParams.Free;
  inherited;
end;

end.

