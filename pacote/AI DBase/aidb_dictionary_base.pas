unit aidb_dictionary_base;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, ZConnection, ZDataset, aidb_types, aidb_dictionary_exporter, aibase;

type
  TAICustomDBDictionary = class(TAIBaseComponent)
  private
    FConnection: TZConnection;
    FSchemaName: string;
    FIncludeTables: Boolean;
    FIncludeViews: Boolean;
    FIncludeIndexes: Boolean;
    FIncludePrimaryKeys: Boolean;
    FIncludeForeignKeys: Boolean;
    FIncludeTriggers: Boolean;
    FIncludeSequences: Boolean;
    FIncludeRoutines: Boolean;
    FIncludeSystemObjects: Boolean;
    FIncludeRowCount: Boolean;
    FAutoConnect: Boolean;
    FOutputFormat: TAIDictionaryOutputFormat;
    FOutputFileName: string;
    FDataDictionary: TAIDBDataDictionary;

    FMaxRowsForCount: Integer;
    FUseComments: Boolean;
    FUseEstimatedRowCount: Boolean;
    FSortObjects: Boolean;
    FIncludeEmptyTables: Boolean;
    FGenerateAIPrompt: Boolean;

    // Events
    FOnBeforeGenerate: TNotifyEvent;
    FOnAfterGenerate: TNotifyEvent;
    FOnTableFound: TAIDBTableEvent;
    FOnColumnFound: TAIDBColumnEvent;
    FOnProgress: TAIDBProgressEvent;
    FOnError: TAIDBErrorEvent;

    procedure SetConnection(Value: TZConnection);
  protected
    function GetEngine: TAIDBEngine; virtual; abstract;

    function LoadTables: Boolean; virtual; abstract;
    function LoadColumns: Boolean; virtual; abstract;
    function LoadPrimaryKeys: Boolean; virtual; abstract;
    function LoadForeignKeys: Boolean; virtual; abstract;
    function LoadIndexes: Boolean; virtual; abstract;
    function LoadViews: Boolean; virtual; abstract;
    function LoadTriggers: Boolean; virtual; abstract;
    function LoadSequences: Boolean; virtual; abstract;
    function LoadRoutines: Boolean; virtual; abstract;

    function CreateQuery: TZQuery;
    procedure SetError(const AMessage: string);
    procedure DoProgress(const AMessage: string; APosition, ATotal: Integer);
    procedure DoTableFound(const ATableName: string);
    procedure DoColumnFound(const ATableName, AColumnName: string);

    property MaxRowsForCount: Integer read FMaxRowsForCount write FMaxRowsForCount default 0;
    property UseComments: Boolean read FUseComments write FUseComments default True;
    property UseEstimatedRowCount: Boolean read FUseEstimatedRowCount write FUseEstimatedRowCount default True;
    property SortObjects: Boolean read FSortObjects write FSortObjects default True;
    property IncludeEmptyTables: Boolean read FIncludeEmptyTables write FIncludeEmptyTables default True;
    property GenerateAIPrompt: Boolean read FGenerateAIPrompt write FGenerateAIPrompt default True;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Generate: Boolean; virtual;
    function GenerateToFile(const AFileName: string): Boolean;
    function SaveToJSON(const AFileName: string): Boolean;
    function SaveToMarkdown(const AFileName: string): Boolean;
    function SaveToText(const AFileName: string): Boolean;
    function AsJSON: string;
    function AsMarkdown: string;
    function AsText: string;
    function AsAIPrompt: string;
    procedure Clear;
    function TestConnection: Boolean;

    property DataDictionary: TAIDBDataDictionary read FDataDictionary;
  published
    property Connection: TZConnection read FConnection write SetConnection;
    property SchemaName: string read FSchemaName write FSchemaName;
    property IncludeTables: Boolean read FIncludeTables write FIncludeTables default True;
    property IncludeViews: Boolean read FIncludeViews write FIncludeViews default True;
    property IncludeIndexes: Boolean read FIncludeIndexes write FIncludeIndexes default True;
    property IncludePrimaryKeys: Boolean read FIncludePrimaryKeys write FIncludePrimaryKeys default True;
    property IncludeForeignKeys: Boolean read FIncludeForeignKeys write FIncludeForeignKeys default True;
    property IncludeTriggers: Boolean read FIncludeTriggers write FIncludeTriggers default True;
    property IncludeSequences: Boolean read FIncludeSequences write FIncludeSequences default True;
    property IncludeRoutines: Boolean read FIncludeRoutines write FIncludeRoutines default True;
    property IncludeSystemObjects: Boolean read FIncludeSystemObjects write FIncludeSystemObjects default False;
    property IncludeRowCount: Boolean read FIncludeRowCount write FIncludeRowCount default False;
    property AutoConnect: Boolean read FAutoConnect write FAutoConnect default False;
    property OutputFormat: TAIDictionaryOutputFormat read FOutputFormat write FOutputFormat default dofMarkdown;
    property OutputFileName: string read FOutputFileName write FOutputFileName;

    // Events
    property OnBeforeGenerate: TNotifyEvent read FOnBeforeGenerate write FOnBeforeGenerate;
    property OnAfterGenerate: TNotifyEvent read FOnAfterGenerate write FOnAfterGenerate;
    property OnTableFound: TAIDBTableEvent read FOnTableFound write FOnTableFound;
    property OnColumnFound: TAIDBColumnEvent read FOnColumnFound write FOnColumnFound;
    property OnProgress: TAIDBProgressEvent read FOnProgress write FOnProgress;
    property OnError: TAIDBErrorEvent read FOnError write FOnError;
  end;

implementation

constructor TAICustomDBDictionary.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FDataDictionary := TAIDBDataDictionary.Create;
  FIncludeTables := True;
  FIncludeViews := True;
  FIncludeIndexes := True;
  FIncludePrimaryKeys := True;
  FIncludeForeignKeys := True;
  FIncludeTriggers := True;
  FIncludeSequences := True;
  FIncludeRoutines := True;
  FIncludeSystemObjects := False;
  FIncludeRowCount := False;
  FAutoConnect := False;
  FOutputFormat := dofMarkdown;
  FMaxRowsForCount := 0;
  FUseComments := True;
  FUseEstimatedRowCount := True;
  FSortObjects := True;
  FIncludeEmptyTables := True;
  FGenerateAIPrompt := True;
end;

destructor TAICustomDBDictionary.Destroy;
begin
  FDataDictionary.Free;
  inherited Destroy;
end;

procedure TAICustomDBDictionary.SetConnection(Value: TZConnection);
begin
  if FConnection <> Value then
  begin
    FConnection := Value;
  end;
end;

function TAICustomDBDictionary.CreateQuery: TZQuery;
begin
  Result := TZQuery.Create(nil);
  if Assigned(FConnection) then
    Result.Connection := FConnection;
end;

procedure TAICustomDBDictionary.SetError(const AMessage: string);
begin
  FLastError := AMessage;
  if Assigned(FOnError) then
    FOnError(Self, AMessage);
end;

procedure TAICustomDBDictionary.DoProgress(const AMessage: string; APosition, ATotal: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, AMessage, APosition, ATotal);
end;

procedure TAICustomDBDictionary.DoTableFound(const ATableName: string);
begin
  if Assigned(FOnTableFound) then
    FOnTableFound(Self, ATableName);
end;

procedure TAICustomDBDictionary.DoColumnFound(const ATableName, AColumnName: string);
begin
  if Assigned(FOnColumnFound) then
    FOnColumnFound(Self, ATableName, AColumnName);
end;

function TAICustomDBDictionary.Generate: Boolean;
begin
  Result := False;
  FLastError := '';
  FLastResult := '';

  if not Assigned(FConnection) then
  begin
    SetError('Conexão com o banco de dados (Connection) não foi informada.');
    Exit;
  end;

  try
    if not FConnection.Connected then
    begin
      if FAutoConnect then
        FConnection.Connect
      else
      begin
        SetError('A conexão com o banco de dados está fechada.');
        Exit;
      end;
    end;

    FDataDictionary.Clear;
    FDataDictionary.Engine := GetEngine;
    FDataDictionary.SchemaName := FSchemaName;
    FDataDictionary.DatabaseName := FConnection.Database;
    FDataDictionary.GeneratedAt := Now;

    if Assigned(FOnBeforeGenerate) then
      FOnBeforeGenerate(Self);

    DoProgress('Iniciando leitura de metadados...', 0, 100);

    if FIncludeTables then
    begin
      DoProgress('Carregando tabelas...', 10, 100);
      if not LoadTables then Exit;

      DoProgress('Carregando colunas...', 30, 100);
      if not LoadColumns then Exit;
    end;

    if FIncludePrimaryKeys then
    begin
      DoProgress('Carregando chaves primárias...', 50, 100);
      if not LoadPrimaryKeys then Exit;
    end;

    if FIncludeForeignKeys then
    begin
      DoProgress('Carregando chaves estrangeiras...', 60, 100);
      if not LoadForeignKeys then Exit;
    end;

    if FIncludeIndexes then
    begin
      DoProgress('Carregando índices...', 70, 100);
      if not LoadIndexes then Exit;
    end;

    if FIncludeViews then
    begin
      DoProgress('Carregando views...', 80, 100);
      if not LoadViews then Exit;
    end;

    if FIncludeTriggers then
    begin
      DoProgress('Carregando triggers...', 85, 100);
      if not LoadTriggers then Exit;
    end;

    if FIncludeSequences then
    begin
      DoProgress('Carregando sequences...', 90, 100);
      if not LoadSequences then Exit;
    end;

    if FIncludeRoutines then
    begin
      DoProgress('Carregando routines...', 95, 100);
      if not LoadRoutines then Exit;
    end;

    DoProgress('Finalizando geração do dicionário...', 100, 100);

    // Populate LastResult based on FOutputFormat
    case FOutputFormat of
      dofText:     FLastResult := AsText;
      dofMarkdown: FLastResult := AsMarkdown;
      dofJSON:     FLastResult := AsJSON;
      dofAIPrompt: FLastResult := AsAIPrompt;
    end;

    if FOutputFileName <> '' then
      GenerateToFile(FOutputFileName);

    if Assigned(FOnAfterGenerate) then
      FOnAfterGenerate(Self);

    Result := True;
  except
    on E: Exception do
    begin
      SetError('Erro ao gerar dicionário: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TAICustomDBDictionary.GenerateToFile(const AFileName: string): Boolean;
var
  List: TStringList;
begin
  Result := False;
  try
    List := TStringList.Create;
    try
      List.Text := FLastResult;
      List.SaveToFile(AFileName);
      Result := True;
    finally
      List.Free;
    end;
  except
    on E: Exception do
      SetError('Erro ao salvar em arquivo: ' + E.Message);
  end;
end;

function TAICustomDBDictionary.SaveToJSON(const AFileName: string): Boolean;
var
  List: TStringList;
begin
  Result := False;
  try
    List := TStringList.Create;
    try
      List.Text := AsJSON;
      List.SaveToFile(AFileName);
      Result := True;
    finally
      List.Free;
    end;
  except
    on E: Exception do
      SetError('Erro ao salvar JSON: ' + E.Message);
  end;
end;

function TAICustomDBDictionary.SaveToMarkdown(const AFileName: string): Boolean;
var
  List: TStringList;
begin
  Result := False;
  try
    List := TStringList.Create;
    try
      List.Text := AsMarkdown;
      List.SaveToFile(AFileName);
      Result := True;
    finally
      List.Free;
    end;
  except
    on E: Exception do
      SetError('Erro ao salvar Markdown: ' + E.Message);
  end;
end;

function TAICustomDBDictionary.SaveToText(const AFileName: string): Boolean;
var
  List: TStringList;
begin
  Result := False;
  try
    List := TStringList.Create;
    try
      List.Text := AsText;
      List.SaveToFile(AFileName);
      Result := True;
    finally
      List.Free;
    end;
  except
    on E: Exception do
      SetError('Erro ao salvar Texto: ' + E.Message);
  end;
end;

function TAICustomDBDictionary.AsJSON: string;
begin
  Result := TAIDBDataDictionaryExporter.ToJSON(FDataDictionary);
end;

function TAICustomDBDictionary.AsMarkdown: string;
begin
  Result := TAIDBDataDictionaryExporter.ToMarkdown(FDataDictionary);
end;

function TAICustomDBDictionary.AsText: string;
begin
  Result := TAIDBDataDictionaryExporter.ToText(FDataDictionary);
end;

function TAICustomDBDictionary.AsAIPrompt: string;
begin
  Result := TAIDBDataDictionaryExporter.ToAIPrompt(FDataDictionary);
end;

procedure TAICustomDBDictionary.Clear;
begin
  FDataDictionary.Clear;
  FLastError := '';
  FLastResult := '';
end;

function TAICustomDBDictionary.TestConnection: Boolean;
begin
  Result := False;
  if not Assigned(FConnection) then
  begin
    SetError('Conexão não especificada.');
    Exit;
  end;

  try
    if not FConnection.Connected then
      FConnection.Connect;
    Result := FConnection.Connected;
  except
    on E: Exception do
      SetError('Falha no teste de conexão: ' + E.Message);
  end;
end;

end.
