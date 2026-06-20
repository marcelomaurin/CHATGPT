unit aidb_types;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIDBEngine = (
    dbUnknown,
    dbPostgreSQL,
    dbMySQL,
    dbMariaDB,
    dbSQLite,
    dbFirebird,
    dbSQLServer,
    dbOracle
  );

  TAIDictionaryOutputFormat = (
    dofText,
    dofMarkdown,
    dofJSON,
    dofSQL,
    dofAIPrompt
  );

  TAIDBObjectKind = (
    dokTable,
    dokView,
    dokColumn,
    dokPrimaryKey,
    dokForeignKey,
    dokIndex,
    dokTrigger,
    dokSequence,
    dokProcedure,
    dokFunction
  );

  // Event types
  TAIDBTableEvent = procedure(Sender: TObject; const ATableName: string) of object;
  TAIDBColumnEvent = procedure(Sender: TObject; const ATableName, AColumnName: string) of object;
  TAIDBProgressEvent = procedure(Sender: TObject; const AMessage: string; APosition, ATotal: Integer) of object;
  TAIDBErrorEvent = procedure(Sender: TObject; const AMessage: string) of object;

  // Collection Items
  TAIDBColumnInfo = class(TCollectionItem)
  private
    FTableName: string;
    FColumnName: string;
    FDataType: string;
    FNativeDataType: string;
    FSize: Integer;
    FPrecision: Integer;
    FScale: Integer;
    FNullable: Boolean;
    FDefaultValue: string;
    FIsPrimaryKey: Boolean;
    FIsForeignKey: Boolean;
    FIsUnique: Boolean;
    FOrdinalPosition: Integer;
    FDescription: string;
  published
    property TableName: string read FTableName write FTableName;
    property ColumnName: string read FColumnName write FColumnName;
    property DataType: string read FDataType write FDataType;
    property NativeDataType: string read FNativeDataType write FNativeDataType;
    property Size: Integer read FSize write FSize;
    property Precision: Integer read FPrecision write FPrecision;
    property Scale: Integer read FScale write FScale;
    property Nullable: Boolean read FNullable write FNullable;
    property DefaultValue: string read FDefaultValue write FDefaultValue;
    property IsPrimaryKey: Boolean read FIsPrimaryKey write FIsPrimaryKey;
    property IsForeignKey: Boolean read FIsForeignKey write FIsForeignKey;
    property IsUnique: Boolean read FIsUnique write FIsUnique;
    property OrdinalPosition: Integer read FOrdinalPosition write FOrdinalPosition;
    property Description: string read FDescription write FDescription;
  end;

  TAIDBColumnCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBColumnInfo;
    procedure SetItem(Index: Integer; Value: TAIDBColumnInfo);
  public
    constructor Create;
    function Add: TAIDBColumnInfo;
    property Items[Index: Integer]: TAIDBColumnInfo read GetItem write SetItem; default;
  end;

  TAIDBTableInfo = class(TCollectionItem)
  private
    FSchemaName: string;
    FTableName: string;
    FTableType: string;
    FDescription: string;
    FRowCount: Int64;
    FColumns: TAIDBColumnCollection;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
  published
    property SchemaName: string read FSchemaName write FSchemaName;
    property TableName: string read FTableName write FTableName;
    property TableType: string read FTableType write FTableType;
    property Description: string read FDescription write FDescription;
    property RowCount: Int64 read FRowCount write FRowCount;
    property Columns: TAIDBColumnCollection read FColumns;
  end;

  TAIDBTableCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBTableInfo;
    procedure SetItem(Index: Integer; Value: TAIDBTableInfo);
  public
    constructor Create;
    function Add: TAIDBTableInfo;
    function FindTable(const ATableName: string): TAIDBTableInfo;
    property Items[Index: Integer]: TAIDBTableInfo read GetItem write SetItem; default;
  end;

  TAIDBForeignKeyInfo = class(TCollectionItem)
  private
    FConstraintName: string;
    FTableName: string;
    FColumnName: string;
    FRefTableName: string;
    FRefColumnName: string;
    FUpdateRule: string;
    FDeleteRule: string;
  published
    property ConstraintName: string read FConstraintName write FConstraintName;
    property TableName: string read FTableName write FTableName;
    property ColumnName: string read FColumnName write FColumnName;
    property RefTableName: string read FRefTableName write FRefTableName;
    property RefColumnName: string read FRefColumnName write FRefColumnName;
    property UpdateRule: string read FUpdateRule write FUpdateRule;
    property DeleteRule: string read FDeleteRule write FDeleteRule;
  end;

  TAIDBForeignKeyCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBForeignKeyInfo;
    procedure SetItem(Index: Integer; Value: TAIDBForeignKeyInfo);
  public
    constructor Create;
    function Add: TAIDBForeignKeyInfo;
    property Items[Index: Integer]: TAIDBForeignKeyInfo read GetItem write SetItem; default;
  end;

  TAIDBIndexInfo = class(TCollectionItem)
  private
    FIndexName: string;
    FTableName: string;
    FColumnName: string;
    FIsUnique: Boolean;
    FIsPrimary: Boolean;
    FIndexType: string;
  published
    property IndexName: string read FIndexName write FIndexName;
    property TableName: string read FTableName write FTableName;
    property ColumnName: string read FColumnName write FColumnName;
    property IsUnique: Boolean read FIsUnique write FIsUnique;
    property IsPrimary: Boolean read FIsPrimary write FIsPrimary;
    property IndexType: string read FIndexType write FIndexType;
  end;

  TAIDBIndexCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBIndexInfo;
    procedure SetItem(Index: Integer; Value: TAIDBIndexInfo);
  public
    constructor Create;
    function Add: TAIDBIndexInfo;
    property Items[Index: Integer]: TAIDBIndexInfo read GetItem write SetItem; default;
  end;

  TAIDBViewInfo = class(TCollectionItem)
  private
    FSchemaName: string;
    FViewName: string;
    FSQLDefinition: string;
    FDescription: string;
  published
    property SchemaName: string read FSchemaName write FSchemaName;
    property ViewName: string read FViewName write FViewName;
    property SQLDefinition: string read FSQLDefinition write FSQLDefinition;
    property Description: string read FDescription write FDescription;
  end;

  TAIDBViewCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBViewInfo;
    procedure SetItem(Index: Integer; Value: TAIDBViewInfo);
  public
    constructor Create;
    function Add: TAIDBViewInfo;
    property Items[Index: Integer]: TAIDBViewInfo read GetItem write SetItem; default;
  end;

  TAIDBTriggerInfo = class(TCollectionItem)
  private
    FTriggerName: string;
    FTableName: string;
    FEventName: string;
    FTiming: string;
    FSQLDefinition: string;
    FEnabled: Boolean;
  published
    property TriggerName: string read FTriggerName write FTriggerName;
    property TableName: string read FTableName write FTableName;
    property EventName: string read FEventName write FEventName;
    property Timing: string read FTiming write FTiming;
    property SQLDefinition: string read FSQLDefinition write FSQLDefinition;
    property Enabled: Boolean read FEnabled write FEnabled;
  end;

  TAIDBTriggerCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBTriggerInfo;
    procedure SetItem(Index: Integer; Value: TAIDBTriggerInfo);
  public
    constructor Create;
    function Add: TAIDBTriggerInfo;
    property Items[Index: Integer]: TAIDBTriggerInfo read GetItem write SetItem; default;
  end;

  TAIDBSequenceInfo = class(TCollectionItem)
  private
    FSequenceName: string;
    FSchemaName: string;
    FCurrentValue: string;
    FIncrementBy: Integer;
  published
    property SequenceName: string read FSequenceName write FSequenceName;
    property SchemaName: string read FSchemaName write FSchemaName;
    property CurrentValue: string read FCurrentValue write FCurrentValue;
    property IncrementBy: Integer read FIncrementBy write FIncrementBy;
  end;

  TAIDBSequenceCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBSequenceInfo;
    procedure SetItem(Index: Integer; Value: TAIDBSequenceInfo);
  public
    constructor Create;
    function Add: TAIDBSequenceInfo;
    property Items[Index: Integer]: TAIDBSequenceInfo read GetItem write SetItem; default;
  end;

  TAIDBRoutineInfo = class(TCollectionItem)
  private
    FRoutineName: string;
    FRoutineType: string;
    FSchemaName: string;
    FReturnType: string;
    FSQLDefinition: string;
  published
    property RoutineName: string read FRoutineName write FRoutineName;
    property RoutineType: string read FRoutineType write FRoutineType;
    property SchemaName: string read FSchemaName write FSchemaName;
    property ReturnType: string read FReturnType write FReturnType;
    property SQLDefinition: string read FSQLDefinition write FSQLDefinition;
  end;

  TAIDBRoutineCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIDBRoutineInfo;
    procedure SetItem(Index: Integer; Value: TAIDBRoutineInfo);
  public
    constructor Create;
    function Add: TAIDBRoutineInfo;
    property Items[Index: Integer]: TAIDBRoutineInfo read GetItem write SetItem; default;
  end;

  // Central dictionary data model
  TAIDBDataDictionary = class(TPersistent)
  private
    FEngine: TAIDBEngine;
    FSchemaName: string;
    FDatabaseName: string;
    FGeneratedAt: TDateTime;
    FTables: TAIDBTableCollection;
    FViews: TAIDBViewCollection;
    FForeignKeys: TAIDBForeignKeyCollection;
    FIndexes: TAIDBIndexCollection;
    FTriggers: TAIDBTriggerCollection;
    FSequences: TAIDBSequenceCollection;
    FRoutines: TAIDBRoutineCollection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function TableCount: Integer;
    function ColumnCount: Integer;

    property Engine: TAIDBEngine read FEngine write FEngine;
    property SchemaName: string read FSchemaName write FSchemaName;
    property DatabaseName: string read FDatabaseName write FDatabaseName;
    property GeneratedAt: TDateTime read FGeneratedAt write FGeneratedAt;

    property Tables: TAIDBTableCollection read FTables;
    property Views: TAIDBViewCollection read FViews;
    property ForeignKeys: TAIDBForeignKeyCollection read FForeignKeys;
    property Indexes: TAIDBIndexCollection read FIndexes;
    property Triggers: TAIDBTriggerCollection read FTriggers;
    property Sequences: TAIDBSequenceCollection read FSequences;
    property Routines: TAIDBRoutineCollection read FRoutines;
  end;

implementation

{ TAIDBColumnCollection }

constructor TAIDBColumnCollection.Create;
begin
  inherited Create(TAIDBColumnInfo);
end;

function TAIDBColumnCollection.Add: TAIDBColumnInfo;
begin
  Result := TAIDBColumnInfo(inherited Add);
end;

function TAIDBColumnCollection.GetItem(Index: Integer): TAIDBColumnInfo;
begin
  Result := TAIDBColumnInfo(inherited GetItem(Index));
end;

procedure TAIDBColumnCollection.SetItem(Index: Integer; Value: TAIDBColumnInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TAIDBTableInfo }

constructor TAIDBTableInfo.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FColumns := TAIDBColumnCollection.Create;
end;

destructor TAIDBTableInfo.Destroy;
begin
  FColumns.Free;
  inherited Destroy;
end;

{ TAIDBTableCollection }

constructor TAIDBTableCollection.Create;
begin
  inherited Create(TAIDBTableInfo);
end;

function TAIDBTableCollection.Add: TAIDBTableInfo;
begin
  Result := TAIDBTableInfo(inherited Add);
end;

function TAIDBTableCollection.GetItem(Index: Integer): TAIDBTableInfo;
begin
  Result := TAIDBTableInfo(inherited GetItem(Index));
end;

procedure TAIDBTableCollection.SetItem(Index: Integer; Value: TAIDBTableInfo);
begin
  inherited SetItem(Index, Value);
end;

function TAIDBTableCollection.FindTable(const ATableName: string): TAIDBTableInfo;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if SameText(Items[i].TableName, ATableName) then
    begin
      Result := Items[i];
      Exit;
    end;
  end;
end;

{ TAIDBForeignKeyCollection }

constructor TAIDBForeignKeyCollection.Create;
begin
  inherited Create(TAIDBForeignKeyInfo);
end;

function TAIDBForeignKeyCollection.Add: TAIDBForeignKeyInfo;
begin
  Result := TAIDBForeignKeyInfo(inherited Add);
end;

function TAIDBForeignKeyCollection.GetItem(Index: Integer): TAIDBForeignKeyInfo;
begin
  Result := TAIDBForeignKeyInfo(inherited GetItem(Index));
end;

procedure TAIDBForeignKeyCollection.SetItem(Index: Integer; Value: TAIDBForeignKeyInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TAIDBIndexCollection }

constructor TAIDBIndexCollection.Create;
begin
  inherited Create(TAIDBIndexInfo);
end;

function TAIDBIndexCollection.Add: TAIDBIndexInfo;
begin
  Result := TAIDBIndexInfo(inherited Add);
end;

function TAIDBIndexCollection.GetItem(Index: Integer): TAIDBIndexInfo;
begin
  Result := TAIDBIndexInfo(inherited GetItem(Index));
end;

procedure TAIDBIndexCollection.SetItem(Index: Integer; Value: TAIDBIndexInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TAIDBViewCollection }

constructor TAIDBViewCollection.Create;
begin
  inherited Create(TAIDBViewInfo);
end;

function TAIDBViewCollection.Add: TAIDBViewInfo;
begin
  Result := TAIDBViewInfo(inherited Add);
end;

function TAIDBViewCollection.GetItem(Index: Integer): TAIDBViewInfo;
begin
  Result := TAIDBViewInfo(inherited GetItem(Index));
end;

procedure TAIDBViewCollection.SetItem(Index: Integer; Value: TAIDBViewInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TAIDBTriggerCollection }

constructor TAIDBTriggerCollection.Create;
begin
  inherited Create(TAIDBTriggerInfo);
end;

function TAIDBTriggerCollection.Add: TAIDBTriggerInfo;
begin
  Result := TAIDBTriggerInfo(inherited Add);
end;

function TAIDBTriggerCollection.GetItem(Index: Integer): TAIDBTriggerInfo;
begin
  Result := TAIDBTriggerInfo(inherited GetItem(Index));
end;

procedure TAIDBTriggerCollection.SetItem(Index: Integer; Value: TAIDBTriggerInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TAIDBSequenceCollection }

constructor TAIDBSequenceCollection.Create;
begin
  inherited Create(TAIDBSequenceInfo);
end;

function TAIDBSequenceCollection.Add: TAIDBSequenceInfo;
begin
  Result := TAIDBSequenceInfo(inherited Add);
end;

function TAIDBSequenceCollection.GetItem(Index: Integer): TAIDBSequenceInfo;
begin
  Result := TAIDBSequenceInfo(inherited GetItem(Index));
end;

procedure TAIDBSequenceCollection.SetItem(Index: Integer; Value: TAIDBSequenceInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TAIDBRoutineCollection }

constructor TAIDBRoutineCollection.Create;
begin
  inherited Create(TAIDBRoutineInfo);
end;

function TAIDBRoutineCollection.Add: TAIDBRoutineInfo;
begin
  Result := TAIDBRoutineInfo(inherited Add);
end;

function TAIDBRoutineCollection.GetItem(Index: Integer): TAIDBRoutineInfo;
begin
  Result := TAIDBRoutineInfo(inherited GetItem(Index));
end;

procedure TAIDBRoutineCollection.SetItem(Index: Integer; Value: TAIDBRoutineInfo);
begin
  inherited SetItem(Index, Value);
end;

{ TAIDBDataDictionary }

constructor TAIDBDataDictionary.Create;
begin
  inherited Create;
  FEngine := dbUnknown;
  FTables := TAIDBTableCollection.Create;
  FViews := TAIDBViewCollection.Create;
  FForeignKeys := TAIDBForeignKeyCollection.Create;
  FIndexes := TAIDBIndexCollection.Create;
  FTriggers := TAIDBTriggerCollection.Create;
  FSequences := TAIDBSequenceCollection.Create;
  FRoutines := TAIDBRoutineCollection.Create;
end;

destructor TAIDBDataDictionary.Destroy;
begin
  FTables.Free;
  FViews.Free;
  FForeignKeys.Free;
  FIndexes.Free;
  FTriggers.Free;
  FSequences.Free;
  FRoutines.Free;
  inherited Destroy;
end;

procedure TAIDBDataDictionary.Clear;
begin
  FTables.Clear;
  FViews.Clear;
  FForeignKeys.Clear;
  FIndexes.Clear;
  FTriggers.Clear;
  FSequences.Clear;
  FRoutines.Clear;
  FEngine := dbUnknown;
  FSchemaName := '';
  FDatabaseName := '';
  FGeneratedAt := 0;
end;

function TAIDBDataDictionary.TableCount: Integer;
begin
  Result := FTables.Count;
end;

function TAIDBDataDictionary.ColumnCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FTables.Count - 1 do
    Result := Result + FTables[i].Columns.Count;
end;

end.
