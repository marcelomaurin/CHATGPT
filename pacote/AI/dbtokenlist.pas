unit DBTokenList;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  ZConnection, ZDataset, tokenizer;

type
  TDBTokenList = class(TCustomControl)
  private
    FZConnection: TZConnection;
    FTableName: string;  // Nome da tabela é privado
    FTokenList: TTokenList;  // Composição do TTokenList
    procedure CreateTableIfNotExists;
    procedure SetZConnection(Value: TZConnection);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SaveToDatabase;
    procedure LoadFromDatabase;
    procedure AddToken(const AKey, AToken: string);
    function GetToken(const AKey: string): string;
    function Count: Integer;
    function Item(Index: Integer): string;

    property ZConnection: TZConnection read FZConnection write SetZConnection;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Core', [TDBTokenList]);
end;

procedure TDBTokenList.LoadFromDatabase;
var
  SQLQuery: TZQuery;
begin
  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit;

  CreateTableIfNotExists;

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;
    SQLQuery.SQL.Text := Format('SELECT key, token FROM %s;', [FTableName]);
    SQLQuery.Open;

    while not SQLQuery.EOF do
    begin
      AddToken(SQLQuery.FieldByName('key').AsString,
               SQLQuery.FieldByName('token').AsString);
      SQLQuery.Next;
    end;

    SQLQuery.Close;
  finally
    SQLQuery.Free;
  end;
end;

constructor TDBTokenList.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FZConnection := nil;
  FTableName := 'tokens';  // Nome da tabela fixado internamente
  FTokenList := TTokenList.Create(Self);  // Instância do TTokenList
  CreateTableIfNotExists;
end;

destructor TDBTokenList.Destroy;
begin
  FTokenList.Free;  // Libera a instância do TTokenList
  inherited Destroy;
end;

procedure TDBTokenList.CreateTableIfNotExists;
var
  SQLQuery: TZQuery;
begin
  if Assigned(FZConnection) and FZConnection.Connected then
  begin
    SQLQuery := TZQuery.Create(nil);
    try
      SQLQuery.Connection := FZConnection;
      SQLQuery.SQL.Text := Format(
        'CREATE TABLE IF NOT EXISTS %s (' +
        '`key` VARCHAR(255) NOT NULL PRIMARY KEY, ' +
        '`token` TEXT NOT NULL);',
        [FTableName]);
      SQLQuery.ExecSQL;
    finally
      SQLQuery.Free;
    end;
  end;
end;

procedure TDBTokenList.SetZConnection(Value: TZConnection);
begin
  if FZConnection <> Value then
  begin
    FZConnection := Value;
    if Assigned(FZConnection) and not FZConnection.Connected then
    begin
      FZConnection.Connect;
    end;
    CreateTableIfNotExists;
  end;
end;

procedure TDBTokenList.SaveToDatabase;
var
  SQLQuery: TZQuery;
  i: Integer;
begin
  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit;

  CreateTableIfNotExists;

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;

    for i := 0 to FTokenList.Count - 1 do
    begin
      SQLQuery.SQL.Text := Format(
        'INSERT INTO %s (`key`, `token`) VALUES (:key, :token) ' +
        'ON DUPLICATE KEY UPDATE `token` = VALUES(`token`);',
        [FTableName]);
      SQLQuery.ParamByName('key').AsString := FTokenList.Item(i);
      SQLQuery.ParamByName('token').AsString := FTokenList.GetToken(FTokenList.Item(i));
      SQLQuery.ExecSQL;
    end;
  finally
    SQLQuery.Free;
  end;
end;

procedure TDBTokenList.AddToken(const AKey, AToken: string);
begin
  FTokenList.AddToken(AKey, AToken);
end;

function TDBTokenList.GetToken(const AKey: string): string;
begin
  Result := FTokenList.GetToken(AKey);
end;

function TDBTokenList.Count: Integer;
begin
  Result := FTokenList.Count;
end;

function TDBTokenList.Item(Index: Integer): string;
begin
  Result := FTokenList.Item(Index);
end;

initialization
  {$I dbtokenlist_icon.lrs}

end.

