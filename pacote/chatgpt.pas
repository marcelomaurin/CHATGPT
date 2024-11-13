unit chatgpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser, Controls, Graphics,
  fphttpclient, opensslsockets, funcoes, LResources;

{ TCHATGPT }



 type TVersionChat = (VCT_GPT35TURBO, VCT_GPT40,VCT_GPT40_TURBO );

 //Class to do connect with chatgpt
 type  TCHATGPT = class(TCustomControl)
  private
    FToken : String; //private variable to use chatgp
    FQuestion : String;
    FResponse : String;
    FTipoChat : TVersionChat;
    FParams: TStrings;
    function RequestJson(LURL : String; token : string ; ASK : string) : String;
    function PegaMensagem(const JSON: string): string;
  protected
    // Sobrescreva o método Paint para definir como o componente será desenhado
    procedure Paint; override;

  public
    constructor create(AOwner: TComponent); override;
    destructor Destroy;

  published
    property TOKEN : String read FToken write FToken; //property to access chatgpt
    property Question : String read FQuestion;
    property Response : String read FResponse write FResponse;
    property TipoChat : TVersionChat read FTipoChat;
    function SendQuestion( ASK : String) : boolean;
    // Propriedades visíveis no Inspector de Objetos
    property Width;
    property Height;


end;

procedure Register;

implementation


{ TCHATGPT }

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

procedure TCHATGPT.Paint;
begin
  inherited Paint;
  // Exemplo de pintura simples: um quadrado vermelho
  Canvas.Brush.Color := clRed;
  Canvas.FillRect(ClientRect);
end;


function TCHATGPT.RequestJson(LURL: String; token: string; ASK: string): String;

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
    ClienteHTTP.AddHeader('Authorization',' Bearer ' + token);

    try

            resposta:=  ClienteHTTP.Post(LURL);
     except on E: Exception do
     end;
  finally



      Result := resposta;
      ClienteHTTP.RequestBody.Free;
      ClienteHTTP.Free;




  end;



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

procedure Register;
begin
  // Registrar o componente na aba "Samples"
  RegisterComponents('OpenAI', [TCHATGPT]);

end;

initialization
  {$I chatgpt_icon.lrs}

end.

