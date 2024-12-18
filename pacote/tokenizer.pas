unit tokenizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Graphics, fpjson, jsonparser;

type
  TTokenItem = class
  private
    FToken: string;
  public
    constructor Create(const AToken: string);
    property Token: string read FToken write FToken;
  end;

  TTokenList = class(TCustomControl)
  private
    FList: TStringList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Paint; override;
    procedure AddToken(const AKey, AToken: string);
    function GetToken(const AKey: string): string;
    procedure LoadFromJSON(const AJSON: string);
    function Find(const AKey: string): string;
    function Count: Integer;
    function Item(Index: Integer): string;
    procedure Encode(List: TStringList);
    function IndexOf(AKey: string): Integer;
  end;

procedure Register;

implementation

function TTokenList.IndexOf(AKey: string): Integer;
begin
  Result := FList.IndexOf(AKey);  // Retorna a posição da chave na lista ou -1 se não for encontrada
end;


constructor TTokenItem.Create(const AToken: string);
begin
  inherited Create;
  FToken := AToken;
end;

constructor TTokenList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FList := TStringList.Create;
  FList.OwnsObjects := True;
end;

function TTokenList.Count: Integer;
begin
  Result := FList.Count;
end;


destructor TTokenList.Destroy;
begin
  FList.Free;
  inherited Destroy;
end;

procedure TTokenList.Paint;
begin
  inherited Paint;
  Canvas.Brush.Color := clRed;
  Canvas.FillRect(ClientRect);
end;

function TTokenList.Item(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FList.Count) then
    Result := FList.Names[Index]
  else
    Result := '';  // Retorna uma string vazia se o índice for inválido
end;


procedure TTokenList.AddToken(const AKey, AToken: string);
begin
  FList.AddObject(AKey, TTokenItem.Create(AToken));
end;

function TTokenList.GetToken(const AKey: string): string;
var
  Index: Integer;
begin
  Index := FList.IndexOf(AKey);
  if Index >= 0 then
    Result := TTokenItem(FList.Objects[Index]).Token
  else
    Result := '';
end;

procedure TTokenList.LoadFromJSON(const AJSON: string);
var
  JSONData: TJSONData;
  JSONObj: TJSONObject;
  JSONArray: TJSONArray;
  i: Integer;
  Key: string;
  TokenObj: TJSONObject;
begin
  JSONData := GetJSON(AJSON);
  JSONObj := JSONData as TJSONObject;
  try
    for i := 0 to JSONObj.Count - 1 do
    begin
      Key := JSONObj.Names[i];
      JSONArray := JSONObj.Items[i] as TJSONArray;
      TokenObj := JSONArray.Items[0] as TJSONObject;
      AddToken(Key, TokenObj.Strings['token']);
    end;
  finally
    JSONData.Free;
  end;
end;

function TTokenList.Find(const AKey: string): string;
var
  Index: Integer;
begin
  Index := FList.IndexOf(AKey);
  if Index >= 0 then
    Result := TTokenItem(FList.Objects[Index]).Token
  else
    Result := AKey;  // Retorna a própria chave se o token não for encontrado
end;

procedure TTokenList.Encode(List: TStringList);
var
  i, j: Integer;
  Words: TStringList;
  Key: string;
begin
  Words := TStringList.Create;
  try
    for i := 0 to List.Count - 1 do
    begin
      // Divide a string em palavras baseadas em espaços
      ExtractStrings([' '], [], PChar(List[i]), Words);
      for j := 0 to Words.Count - 1 do
      begin
        Key := Words[j];
        if (Key <> '') and (FList.IndexOf(Key) = -1) then  // Verifica se a chave não existe e não é uma string vazia
          AddToken(Key, Key);  // Adiciona a chave com o token sendo igual ao AKey
      end;
    end;
  finally
    Words.Free;
  end;
end;



procedure Register;
begin
  RegisterComponents('IA', [TTokenList]);
end;

end.

