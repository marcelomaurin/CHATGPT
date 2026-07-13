unit aidbase;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, LResources, Forms, Controls, Graphics, Dialogs,
  ZConnection, ZDataset;

type
  TAIDBase = class(TComponent)
  private
    FConnection: TZConnection;
    FMemoryTableName: string;
    FHistoryTableName: string;
    FDatasetTableName: string;
    FAutoCreateTables: Boolean;
    procedure SetConnection(Value: TZConnection);
  protected
    procedure CreateTableIfNotExists(const ATableName, AFieldsDef: string); virtual;
    procedure CheckAndCreateTables; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // AI Memory operations
    procedure SaveMemory(const ACategory, AKey, AContent: string);
    function LoadMemory(const ACategory, AKey: string): string;
    function SearchMemories(const AQuery: string; AMaxResults: Integer = 5): TStringList;

    // Conversation History operations
    procedure LogConversation(const ARole, AMessage: string; const AContext: string = '');

    // Dataset operations
    procedure AddTrainingPair(const APrompt, ACompletion: string; const ATag: string = '');
    function ExportDatasetToJSON(const ATag: string = ''): string;

  published
    property Connection: TZConnection read FConnection write SetConnection;
    property MemoryTableName: string read FMemoryTableName write FMemoryTableName;
    property HistoryTableName: string read FHistoryTableName write FHistoryTableName;
    property DatasetTableName: string read FDatasetTableName write FDatasetTableName;
    property AutoCreateTables: Boolean read FAutoCreateTables write FAutoCreateTables default True;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Database', [TAIDBase]);
end;

constructor TAIDBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMemoryTableName := 'ai_memories';
  FHistoryTableName := 'ai_history';
  FDatasetTableName := 'ai_datasets';
  FAutoCreateTables := True;
  FConnection := nil;
end;

destructor TAIDBase.Destroy;
begin
  inherited Destroy;
end;

procedure TAIDBase.SetConnection(Value: TZConnection);
begin
  if FConnection <> Value then
  begin
    FConnection := Value;
    if FAutoCreateTables and Assigned(FConnection) then
    begin
      if not FConnection.Connected then
        FConnection.Connect;
      CheckAndCreateTables;
    end;
  end;
end;

procedure TAIDBase.CreateTableIfNotExists(const ATableName, AFieldsDef: string);
var
  Query: TZQuery;
begin
  if not Assigned(FConnection) or not FConnection.Connected then
    Exit;

  Query := TZQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'CREATE TABLE IF NOT EXISTS ' + ATableName + ' (' + AFieldsDef + ');';
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

procedure TAIDBase.CheckAndCreateTables;
begin
  if not Assigned(FConnection) or not FConnection.Connected then
    Exit;

  // 1. Memory Table
  CreateTableIfNotExists(FMemoryTableName,
    'category VARCHAR(100), ' +
    'key_name VARCHAR(255), ' +
    'content TEXT, ' +
    'updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' +
    'PRIMARY KEY (category, key_name)');

  // 2. History Table
  CreateTableIfNotExists(FHistoryTableName,
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'role VARCHAR(50), ' +
    'message TEXT, ' +
    'context TEXT, ' +
    'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');

  // 3. Dataset Table
  CreateTableIfNotExists(FDatasetTableName,
    'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    'prompt TEXT, ' +
    'completion TEXT, ' +
    'tag VARCHAR(100), ' +
    'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
end;

procedure TAIDBase.SaveMemory(const ACategory, AKey, AContent: string);
var
  Query: TZQuery;
begin
  if not Assigned(FConnection) then
    Exit;
  if not FConnection.Connected then
    FConnection.Connect;

  CheckAndCreateTables;

  Query := TZQuery.Create(nil);
  try
    Query.Connection := FConnection;
    // Compatibility handle for sqlite / mysql ON CONFLICT or DELETE+INSERT
    Query.SQL.Text := 'DELETE FROM ' + FMemoryTableName + ' WHERE category = :cat AND key_name = :key;';
    Query.ParamByName('cat').AsString := ACategory;
    Query.ParamByName('key').AsString := AKey;
    Query.ExecSQL;

    Query.SQL.Text := 'INSERT INTO ' + FMemoryTableName + ' (category, key_name, content) VALUES (:cat, :key, :content);';
    Query.ParamByName('cat').AsString := ACategory;
    Query.ParamByName('key').AsString := AKey;
    Query.ParamByName('content').AsString := AContent;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

function TAIDBase.LoadMemory(const ACategory, AKey: string): string;
var
  Query: TZQuery;
begin
  Result := '';
  if not Assigned(FConnection) then
    Exit;
  if not FConnection.Connected then
    FConnection.Connect;

  CheckAndCreateTables;

  Query := TZQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT content FROM ' + FMemoryTableName + ' WHERE category = :cat AND key_name = :key;';
    Query.ParamByName('cat').AsString := ACategory;
    Query.ParamByName('key').AsString := AKey;
    Query.Open;
    if not Query.EOF then
      Result := Query.FieldByName('content').AsString;
  finally
    Query.Free;
  end;
end;

function TAIDBase.SearchMemories(const AQuery: string; AMaxResults: Integer = 5): TStringList;
var
  Query: TZQuery;
begin
  Result := TStringList.Create;
  if not Assigned(FConnection) then
    Exit;
  if not FConnection.Connected then
    FConnection.Connect;

  CheckAndCreateTables;

  Query := TZQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'SELECT category, key_name, content FROM ' + FMemoryTableName +
                      ' WHERE content LIKE :search OR key_name LIKE :search LIMIT :limit;';
    Query.ParamByName('search').AsString := '%' + AQuery + '%';
    Query.ParamByName('limit').AsInteger := AMaxResults;
    Query.Open;
    while not Query.EOF do
    begin
      Result.Add(Query.FieldByName('category').AsString + '/' +
                 Query.FieldByName('key_name').AsString + '=' +
                 Query.FieldByName('content').AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

procedure TAIDBase.LogConversation(const ARole, AMessage: string; const AContext: string = '');
var
  Query: TZQuery;
begin
  if not Assigned(FConnection) then
    Exit;
  if not FConnection.Connected then
    FConnection.Connect;

  CheckAndCreateTables;

  Query := TZQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'INSERT INTO ' + FHistoryTableName + ' (role, message, context) VALUES (:role, :msg, :ctx);';
    Query.ParamByName('role').AsString := ARole;
    Query.ParamByName('msg').AsString := AMessage;
    Query.ParamByName('ctx').AsString := AContext;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

procedure TAIDBase.AddTrainingPair(const APrompt, ACompletion: string; const ATag: string = '');
var
  Query: TZQuery;
begin
  if not Assigned(FConnection) then
    Exit;
  if not FConnection.Connected then
    FConnection.Connect;

  CheckAndCreateTables;

  Query := TZQuery.Create(nil);
  try
    Query.Connection := FConnection;
    Query.SQL.Text := 'INSERT INTO ' + FDatasetTableName + ' (prompt, completion, tag) VALUES (:prompt, :completion, :tag);';
    Query.ParamByName('prompt').AsString := APrompt;
    Query.ParamByName('completion').AsString := ACompletion;
    Query.ParamByName('tag').AsString := ATag;
    Query.ExecSQL;
  finally
    Query.Free;
  end;
end;

function TAIDBase.ExportDatasetToJSON(const ATag: string = ''): string;
var
  Query: TZQuery;
  Line: string;
begin
  Result := '[';
  if not Assigned(FConnection) then
  begin
    Result := Result + ']';
    Exit;
  end;
  if not FConnection.Connected then
    FConnection.Connect;

  CheckAndCreateTables;

  Query := TZQuery.Create(nil);
  try
    Query.Connection := FConnection;
    if ATag <> '' then
    begin
      Query.SQL.Text := 'SELECT prompt, completion, tag FROM ' + FDatasetTableName + ' WHERE tag = :tag;';
      Query.ParamByName('tag').AsString := ATag;
    end
    else
    begin
      Query.SQL.Text := 'SELECT prompt, completion, tag FROM ' + FDatasetTableName + ';';
    end;
    Query.Open;
    while not Query.EOF do
    begin
      Line := Format('{"prompt": "%s", "completion": "%s", "tag": "%s"}', [
        Query.FieldByName('prompt').AsString.Replace('"', '\"').Replace(#13#10, '\n').Replace(#10, '\n'),
        Query.FieldByName('completion').AsString.Replace('"', '\"').Replace(#13#10, '\n').Replace(#10, '\n'),
        Query.FieldByName('tag').AsString.Replace('"', '\"')
      ]);
      if Result <> '[' then
        Result := Result + ',' + sLineBreak;
      Result := Result + Line;
      Query.Next;
    end;
  finally
    Query.Free;
  end;
  Result := Result + ']';
end;

initialization
  {$I aidbase_icon.lrs}

end.
