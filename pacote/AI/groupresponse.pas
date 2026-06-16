unit GroupResponse;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  ZConnection, ZDataset;

type
  TGroupResponse = class(TComponent)
  private
    FZConnection: TZConnection;
    FGroupTable: string;
    FResponseTable: string;
    procedure CreateTablesIfNotExists;
    procedure SetZConnection(Value: TZConnection);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure SaveGroup(const GroupName: string);
    procedure SaveResponse(const GroupName, Response: string);
    function LoadResponses(const GroupName: string): TStringList;
    function EnsureResponse(const GroupName, Response: string): Integer;
    function GetGroupID(const GroupName: string): Integer;
    function ListGroups: TStringList;
    function ListKeys(const GroupName: string): TStringList;

    property ZConnection: TZConnection read FZConnection write SetZConnection;
    property GroupTable: string read FGroupTable write FGroupTable;
    property ResponseTable: string read FResponseTable write FResponseTable;
  end;


procedure Register;

implementation


procedure TGroupResponse.CreateTablesIfNotExists;
var
  SQLQuery: TZQuery;
begin
  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit;

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;

    // Criação da tabela de grupos
    SQLQuery.SQL.Text := Format(
      'CREATE TABLE IF NOT EXISTS %s (' +
      '`id` INT AUTO_INCREMENT PRIMARY KEY, ' +
      '`name` VARCHAR(255) NOT NULL UNIQUE);',
      [FGroupTable]);
    SQLQuery.ExecSQL;

    // Criação da tabela de respostas
    SQLQuery.SQL.Text := Format(
      'CREATE TABLE IF NOT EXISTS %s (' +
      '`id` INT AUTO_INCREMENT PRIMARY KEY, ' +
      '`group_id` INT NOT NULL, ' +
      '`response` TEXT NOT NULL, ' +
      'FOREIGN KEY (`group_id`) REFERENCES %s(`id`) ON DELETE CASCADE);',
      [FResponseTable, FGroupTable]);
    SQLQuery.ExecSQL;
  finally
    SQLQuery.Free;
  end;
end;

procedure TGroupResponse.SetZConnection(Value: TZConnection);
begin
  if FZConnection <> Value then
    FZConnection := Value;
end;

constructor TGroupResponse.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FZConnection := nil;
  FGroupTable := 'groups';
  FResponseTable := 'responses';
end;

destructor TGroupResponse.Destroy;
begin
  inherited Destroy;
end;

procedure TGroupResponse.SaveGroup(const GroupName: string);
var
  SQLQuery: TZQuery;
begin
  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit;

  CreateTablesIfNotExists;

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;
    SQLQuery.SQL.Text := Format(
      'INSERT IGNORE INTO %s (`name`) VALUES (:name);',
      [FGroupTable]);
    SQLQuery.ParamByName('name').AsString := GroupName;
    SQLQuery.ExecSQL;
  finally
    SQLQuery.Free;
  end;
end;

procedure TGroupResponse.SaveResponse(const GroupName, Response: string);
begin
  EnsureResponse(GroupName, Response);
end;

function TGroupResponse.LoadResponses(const GroupName: string): TStringList;
var
  SQLQuery: TZQuery;
  GroupID: Integer;
  Responses: TStringList;
begin
  Responses := TStringList.Create;

  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit(Responses);

  CreateTablesIfNotExists;

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;

    // Buscar o ID do grupo
    SQLQuery.SQL.Text := Format('SELECT `id` FROM %s WHERE `name` = :name;', [FGroupTable]);
    SQLQuery.ParamByName('name').AsString := GroupName;
    SQLQuery.Open;

    if SQLQuery.EOF then
      Exit(Responses); // Grupo não encontrado

    GroupID := SQLQuery.FieldByName('id').AsInteger;

    // Carregar as respostas do grupo
    SQLQuery.Close;
    SQLQuery.SQL.Text := Format('SELECT `response` FROM %s WHERE `group_id` = :group_id;', [FResponseTable]);
    SQLQuery.ParamByName('group_id').AsInteger := GroupID;
    SQLQuery.Open;

    while not SQLQuery.EOF do
    begin
      Responses.Add(SQLQuery.FieldByName('response').AsString);
      SQLQuery.Next;
    end;

  finally
    SQLQuery.Free;
  end;

  Result := Responses;
end;

function TGroupResponse.EnsureResponse(const GroupName, Response: string): Integer;
var
  GroupID: Integer;
  SQLQuery: TZQuery;
begin
  Result := -1;

  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit;

  GroupID := GetGroupID(GroupName);

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;

    // Verificar se a resposta já existe
    SQLQuery.SQL.Text := Format('SELECT `id` FROM %s WHERE `group_id` = :group_id AND `response` = :response;', [FResponseTable]);
    SQLQuery.ParamByName('group_id').AsInteger := GroupID;
    SQLQuery.ParamByName('response').AsString := Response;
    SQLQuery.Open;

    if not SQLQuery.EOF then
    begin
      Result := SQLQuery.FieldByName('id').AsInteger; // Resposta já existe
      Exit;
    end;

    // Inserir nova resposta
    SQLQuery.Close;
    SQLQuery.SQL.Text := Format(
      'INSERT INTO %s (`group_id`, `response`) VALUES (:group_id, :response);',
      [FResponseTable]);
    SQLQuery.ParamByName('group_id').AsInteger := GroupID;
    SQLQuery.ParamByName('response').AsString := Response;
    SQLQuery.ExecSQL;

    // Obter o ID da nova resposta
    SQLQuery.Close;
    SQLQuery.SQL.Text := 'SELECT LAST_INSERT_ID() AS id;';
    SQLQuery.Open;
    Result := SQLQuery.FieldByName('id').AsInteger;
  finally
    SQLQuery.Free;
  end;
end;

function TGroupResponse.GetGroupID(const GroupName: string): Integer;
var
  SQLQuery: TZQuery;
begin
  Result := -1;

  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit;

  CreateTablesIfNotExists;

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;

    // Buscar o ID do grupo
    SQLQuery.SQL.Text := Format('SELECT `id` FROM %s WHERE `name` = :name;', [FGroupTable]);
    SQLQuery.ParamByName('name').AsString := GroupName;
    SQLQuery.Open;

    if SQLQuery.EOF then
    begin
      // Inserir o grupo se não existir
      SaveGroup(GroupName);
      SQLQuery.Close;
      SQLQuery.SQL.Text := Format('SELECT `id` FROM %s WHERE `name` = :name;', [FGroupTable]);
      SQLQuery.ParamByName('name').AsString := GroupName;
      SQLQuery.Open;
    end;

    Result := SQLQuery.FieldByName('id').AsInteger;
  finally
    SQLQuery.Free;
  end;
end;

function TGroupResponse.ListGroups: TStringList;
var
  SQLQuery: TZQuery;
  Groups: TStringList;
begin
  Groups := TStringList.Create;

  if not Assigned(FZConnection) or not FZConnection.Connected then
    Exit(Groups);

  CreateTablesIfNotExists;

  SQLQuery := TZQuery.Create(nil);
  try
    SQLQuery.Connection := FZConnection;
    SQLQuery.SQL.Text := Format('SELECT `name` FROM %s;', [FGroupTable]);
    SQLQuery.Open;

    while not SQLQuery.EOF do
    begin
      Groups.Add(SQLQuery.FieldByName('name').AsString);
      SQLQuery.Next;
    end;

  finally
    SQLQuery.Free;
  end;

  Result := Groups;
end;

function TGroupResponse.ListKeys(const GroupName: string): TStringList;
begin
  Result := LoadResponses(GroupName);
end;

procedure Register;
begin
  {$I groupresponse_icon.lrs}
  RegisterComponents('AI Core', [TGroupResponse]);
end;

end.
