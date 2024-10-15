unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser,
  fphttpclient, opensslsockets, funcoes;

{ TCHATGPT }

 type TVersionChat = (VCT_GPT35TURBO, VCT_GPT40,VCT_GPT40_TURBO );

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

function TCHATGPT.PegaMensagem(const JSON: string): string;
var
  Data: TJSONData;
  JsonObject, MessageObject: TJSONObject;
  ChoicesArray: TJSONArray;
  Parser: TJSONParser;
begin
  // Cria um objeto TJSONParser a partir da string JSON
  Parser := TJSONParser.Create(JSON);

  try
    // Faz o parsing do JSON
    Data := Parser.Parse;

    // Verifica se o objeto é um TJSONObject
    if Data is TJSONObject then
    begin
      // Converte o objeto para um TJSONObject
      JsonObject := TJSONObject(Data);

      // Verifica se o campo "choices" existe
      if JsonObject.IndexOfName('choices') >= 0 then
      begin
        // Obtém o array de escolhas (choices)
        ChoicesArray := JsonObject.Arrays['choices'];

        // Verifica se o array de escolhas existe e se possui elementos
        if (ChoicesArray <> nil) and (ChoicesArray.Count > 0) then
        begin
          // Obtém o primeiro objeto de mensagem (message)
          MessageObject := ChoicesArray.Objects[0].Objects['message'] as TJSONObject;

          // Verifica se o objeto de mensagem existe
          if MessageObject <> nil then
          begin
            // Verifica se o campo "content" existe no objeto de mensagem
            //Response:{ "role" : "assistant", "content" : "Olá! Como posso ajudar?" }
            if MessageObject.IndexOfName('content') >= 0 then
            begin
              // Obtém o valor do campo "content"
              Result := MessageObject.Find('content').AsString;
              //MessageObject.Get('content').AsString;
            end
            else
            begin
              // O campo "content" não existe, pega o conteúdo completo do objeto de mensagem
              Result := MessageObject.AsJSON;
            end;
          end
          else
          begin
            // O objeto de mensagem não existe, retorna uma string vazia ou lança uma exceção, conforme necessário
            Result := '';
          end;
        end
        else
        begin
          // O array de escolhas está vazio, retorna uma string vazia ou lança uma exceção, conforme necessário
          Result := '';
        end;
      end
      else if JsonObject.IndexOfName('content') >= 0 then
      begin
        // O campo "choices" não existe, mas o campo "content" existe no nível superior
        Result := JsonObject.Get('content').AsString;
      end
      else
      begin
        // Resposta inválida, retorna uma string vazia ou lança uma exceção, conforme necessário
        Result := '';
      end;
    end
    else
    begin
      // Objeto JSON inválido, retorna uma string vazia ou lança uma exceção, conforme necessário
      Result := '';
    end;
  finally
    Parser.Free; // Libera a memória do objeto TJSONParser
  end;
end;
  *)

function TCHATGPT.PegaMensagem(const JSON: string): string;
var
  CleanJSON: string;
  Data: TJSONData;
  JsonObject, MessageObject: TJSONObject;
  ChoicesArray: TJSONArray;
  ContentData: TJSONData;
  Parser: TJSONParser;
begin
  // Remove caracteres de controle do JSON
  CleanJSON := StringReplace(JSON, '#$0A', '', [rfReplaceAll]);

  // Inicializa o resultado
  Result := '';

  // Cria um objeto TJSONParser a partir da string JSON limpa
  Parser := TJSONParser.Create(CleanJSON);

  try
    // Faz o parsing do JSON
    Data := Parser.Parse;

    if Data.JSONType = jtObject then
    begin
      JsonObject := TJSONObject(Data);

      if JsonObject.Find('choices', ChoicesArray) then
      begin
        if (ChoicesArray <> nil) and (ChoicesArray.Count > 0) then
        begin
          if ChoicesArray.Items[0].JSONType = jtObject then
          begin
            MessageObject := ChoicesArray.Objects[0].FindPath('message') as TJSONObject;

            if MessageObject <> nil then
            begin
              // Verifica se 'content' existe e é do tipo correto
              ContentData := MessageObject.Find('content');
              if (ContentData <> nil) and (ContentData.JSONType = jtString) then
              begin
                Result := ContentData.AsString;
              end;
            end;
          end;
        end;
      end;
    end;
  finally
    Parser.Free;
  end;
end;


function TCHATGPT.RequestJson(LURL: string; token: string; ASK: string): string;

var
  ClienteHTTP: TFPHttpClient;
  Resposta : AnsiString;
  LResponse: TStringStream;
  formulario : string;
  Params: string;
  tipo: string;
begin
  //Resposta := '';
  Formulario := '' ;
  case FTipoChat of
       VCT_GPT35TURBO:
          tipo := '"gpt-3.5-turbo"';
       VCT_GPT40:
          tipo := '"gpt-4o-mini"';
       VCT_GPT40_TURBO:
          tipo := '"gpt-4-turbo-preview"';
  end;
  params :=  '{ "model": '+tipo +
             ', "messages": [{"role": "user", "content": "'+
             ASK +'"}]'+
             ' }';
  ClienteHTTP := TFPHttpClient.Create(nil);
  try
    LResponse := TStringStream.Create('');
    ClienteHTTP.RequestBody := TRawByteStringStream.Create(Params);


    ClienteHTTP.AddHeader('Content-Type', 'application/json;');
    //ClienteHTTP.AddHeader('Authorization',' Bearer ' + EncodeURLElement(token));
    ClienteHTTP.AddHeader('Authorization',' Bearer ' + token);

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

     AUX := RequestJson(LURL, FToken, EncodeURLElement(retiraCRLF(ASK)));
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
  //FTipoChat:= VCT_GPT35TURBO;
  FTipoChat:= VCT_GPT40;
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

