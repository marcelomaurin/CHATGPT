unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, DBGrids, DB, ZConnection, ZDataset, strutils,
  chatgpt,
  aidb_types,
  aidb_dictionary_base,
  aidb_sqlite_dictionary;

type
  TfrmMain = class(TForm)
    PageControl1: TPageControl;
    tabDatabase: TTabSheet;
    tabLLMConfig: TTabSheet;
    tabPrompt: TTabSheet;
    tabSQL: TTabSheet;
    tabResult: TTabSheet;
    pnlDbTop: TPanel;
    lblDatabasePath: TLabel;
    edtDatabasePath: TEdit;
    btnSelectDatabase: TButton;
    btnCreateDatabase: TButton;
    btnConnectDatabase: TButton;
    btnGenerateDictionary: TButton;
    btnSaveDatabaseConfig: TButton;
    lblDatabaseStatus: TLabel;
    memoDictionary: TMemo;
    pnlLlmConfig: TPanel;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblToken: TLabel;
    edtToken: TEdit;
    lblURL: TLabel;
    edtURL: TEdit;
    lblTimeout: TLabel;
    edtTimeout: TEdit;
    lblMaxTokens: TLabel;
    edtMaxTokens: TEdit;
    btnTestLLM: TButton;
    btnSaveLLMConfig: TButton;
    memoLLMLog: TMemo;
    pnlPromptTop: TPanel;
    lblUserPrompt: TLabel;
    memoUserPrompt: TMemo;
    btnGenerateSQL: TButton;
    btnAddExamplePrompt: TButton;
    pnlPromptClient: TPanel;
    lblPromptSent: TLabel;
    memoPromptSentToLLM: TMemo;
    pnlSqlTop: TPanel;
    btnValidateSQL: TButton;
    btnExecuteSQL: TButton;
    btnClearSQL: TButton;
    pnlSqlClient: TPanel;
    lblGeneratedSql: TLabel;
    memoGeneratedSQL: TMemo;
    pnlResultTop: TPanel;
    lblRows: TLabel;
    pnlResultClient: TPanel;
    DBGridResult: TDBGrid;
    memoExecutionLog: TMemo;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure btnSelectDatabaseClick(Sender: TObject);
    procedure btnCreateDatabaseClick(Sender: TObject);
    procedure btnConnectDatabaseClick(Sender: TObject);
    procedure btnGenerateDictionaryClick(Sender: TObject);
    procedure btnSaveDatabaseConfigClick(Sender: TObject);
    procedure btnTestLLMClick(Sender: TObject);
    procedure btnSaveLLMConfigClick(Sender: TObject);
    procedure btnAddExamplePromptClick(Sender: TObject);
    procedure btnGenerateSQLClick(Sender: TObject);
    procedure btnValidateSQLClick(Sender: TObject);
    procedure btnExecuteSQLClick(Sender: TObject);
    procedure btnClearSQLClick(Sender: TObject);
  private
    FChatGPT: TCHATGPT;
    FConnection: TZConnection;
    FDictionary: TAISQLiteDictionary;
    FQueryResult: TZQuery;
    FDataSource: TDataSource;
    FDictionaryGenerated: Boolean;
    FExampleIndex: Integer;

    function ConfigFileName: string;
    procedure LoadConfig;
    procedure SaveConfig;
    procedure UpdateProviderModels;
    function GetDemoDatabaseFileName: string;
    procedure ApplyDatabaseConfig(const AFileName: string);
    procedure CreateDemoDatabase(const AFileName: string);
    procedure ExecuteScript(const AScript: string);
    procedure ConnectSQLite(const AFileName: string);
    function GenerateDatabaseDictionary: Boolean;
    procedure SyncChatGPTConfig;
    function BuildSQLPrompt(const AUserRequest: string; const ADatabaseDictionary: string): string;
    function BuildSQLCorrectionPrompt(const AFailedSQL, AError: string): string;
    function ExtractSQLFromLLMResponse(const AResponse: string): string;
    function IsSafeSelectSQL(const ASQL: string; out AError: string): Boolean;
    function ExecuteSQLWithAutoCorrection(var ASQL: string): Boolean;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
  APP_NAME = 'ai_sqlite_query_assistant_demo';
  MAX_SQL_ATTEMPTS = 3;

  ExamplePrompts: array[0..9] of string = (
    'Show total sales by customer.',
    'List the best-selling products.',
    'Show sales with customer name, sale date and total amount.',
    'Show products that are currently in promotion.',
    'Show total revenue by payment method.',
    'Show pending sales.',
    'Show products with low stock.',
    'Show customers who bought notebooks.',
    'Show monthly sales totals.',
    'Show the top 5 customers by revenue.'
  );

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FChatGPT := TCHATGPT.Create(Self);
  FConnection := TZConnection.Create(Self);
  FDictionary := TAISQLiteDictionary.Create(Self);
  FQueryResult := TZQuery.Create(Self);
  FDataSource := TDataSource.Create(Self);

  FQueryResult.Connection := FConnection;
  FDataSource.DataSet := FQueryResult;
  DBGridResult.DataSource := FDataSource;

  FDictionaryGenerated := False;
  FExampleIndex := 0;

  memoUserPrompt.Text := ExamplePrompts[0];
  lblDatabaseStatus.Caption := 'Status: Not connected';
  lblRows.Caption := 'Rows: 0';

  memoDictionary.Clear;
  memoPromptSentToLLM.Clear;
  memoGeneratedSQL.Clear;
  memoExecutionLog.Clear;
  memoLLMLog.Clear;

  LoadConfig;
  SyncChatGPTConfig;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  try
    SaveConfig;
  except
    // Destruction must not propagate configuration errors.
    on E: Exception do ;
  end;

  if FQueryResult.Active then
    FQueryResult.Close;
  if FConnection.Connected then
    FConnection.Disconnect;
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
begin
  edtURL.Text := GetDefaultEndpointForProvider(
    GetAIProviderFromIndex(cbProvider.ItemIndex));
  UpdateProviderModels;
end;

function TfrmMain.ConfigFileName: string;
var
  LDir: string;
begin
  LDir := GetEnvironmentVariable('APPDATA');
  if LDir <> '' then
    LDir := IncludeTrailingPathDelimiter(LDir) + 'maurinsoft' +
      DirectorySeparator + APP_NAME
  else
    LDir := GetAppConfigDir(False);

  if not DirectoryExists(LDir) then
    ForceDirectories(LDir);
  Result := IncludeTrailingPathDelimiter(LDir) + APP_NAME + '.ini';
end;

procedure TfrmMain.UpdateProviderModels;
var
  LProvider: TAIProvider;
  LCurrentModel: string;
begin
  LCurrentModel := cbModel.Text;
  LProvider := GetAIProviderFromIndex(cbProvider.ItemIndex);

  cbModel.Items.Clear;
  GetAIModelListForProvider(LProvider, cbModel.Items);

  if cbModel.Items.Count > 0 then
  begin
    if cbModel.Items.IndexOf(LCurrentModel) >= 0 then
      cbModel.Text := LCurrentModel
    else
      cbModel.ItemIndex := 0;
  end;

  if Trim(edtURL.Text) = '' then
    edtURL.Text := GetDefaultEndpointForProvider(LProvider);
end;

procedure TfrmMain.LoadConfig;
var
  LIni: TIniFile;
  LProviderName: string;
  LProviderIndex: Integer;
begin
  LIni := TIniFile.Create(ConfigFileName);
  try
    edtDatabasePath.Text := LIni.ReadString('Conexao', 'DatabasePath',
      GetDemoDatabaseFileName);

    GetAIProviderList(cbProvider.Items);
    LProviderName := LIni.ReadString('IA', 'ProviderName', '');
    LProviderIndex := -1;
    if LProviderName <> '' then
      LProviderIndex := cbProvider.Items.IndexOf(LProviderName);
    if LProviderIndex < 0 then
      LProviderIndex := LIni.ReadInteger('IA', 'ProviderIndex', 0);
    if (LProviderIndex >= 0) and (LProviderIndex < cbProvider.Items.Count) then
      cbProvider.ItemIndex := LProviderIndex
    else
      cbProvider.ItemIndex := 0;

    UpdateProviderModels;

    edtToken.Text := LIni.ReadString('IA', 'ApiKey', '');
    cbModel.Text := LIni.ReadString('IA', 'Model', cbModel.Text);
    edtURL.Text := LIni.ReadString('IA', 'URL',
      GetDefaultEndpointForProvider(
        GetAIProviderFromIndex(cbProvider.ItemIndex)));
    edtTimeout.Text := LIni.ReadString('IA', 'TimeoutSegundos', '120');
    edtMaxTokens.Text := LIni.ReadString('IA', 'MaxTokens', '2048');

    memoLLMLog.Lines.Add('Configuration loaded from: ' + ConfigFileName);
  finally
    LIni.Free;
  end;
end;

procedure TfrmMain.SaveConfig;
var
  LIni: TIniFile;
begin
  LIni := TIniFile.Create(ConfigFileName);
  try
    LIni.WriteString('Conexao', 'DatabasePath', edtDatabasePath.Text);
    LIni.WriteInteger('IA', 'ProviderIndex', cbProvider.ItemIndex);
    LIni.WriteString('IA', 'ProviderName', cbProvider.Text);
    LIni.WriteString('IA', 'ApiKey', edtToken.Text);
    LIni.WriteString('IA', 'Model', cbModel.Text);
    LIni.WriteString('IA', 'URL', edtURL.Text);
    LIni.WriteString('IA', 'TimeoutSegundos', edtTimeout.Text);
    LIni.WriteString('IA', 'MaxTokens', edtMaxTokens.Text);
  finally
    LIni.Free;
  end;
end;

function TfrmMain.GetDemoDatabaseFileName: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'database' + DirectorySeparator + 'sales_ai_demo.db';
end;

procedure TfrmMain.ApplyDatabaseConfig(const AFileName: string);
var
  LAppDir, LLibraryPath: string;
begin
  FConnection.Protocol := 'sqlite';
  FConnection.Database := AFileName;

  // Keep the database client lookup local to the application, as in the
  // PostgreSQL reference demo. The bundled sqlite3.dll must be Win32.
  LAppDir := ExtractFilePath(ParamStr(0));
  LLibraryPath := IncludeTrailingPathDelimiter(LAppDir) + 'sqlite3.dll';
  if FileExists(LLibraryPath) then
    FConnection.LibraryLocation := LLibraryPath
  else
    FConnection.LibraryLocation := LAppDir;
end;

procedure TfrmMain.ExecuteScript(const AScript: string);
var
  LQuery: TZQuery;
  LSQL, LCurrent: string;
  I: Integer;
begin
  LQuery := TZQuery.Create(nil);
  try
    LQuery.Connection := FConnection;
    LCurrent := '';
    for I := 1 to Length(AScript) do
    begin
      LCurrent := LCurrent + AScript[I];
      if AScript[I] = ';' then
      begin
        LSQL := Trim(LCurrent);
        if LSQL <> '' then
        begin
          LQuery.SQL.Text := LSQL;
          LQuery.ExecSQL;
        end;
        LCurrent := '';
      end;
    end;
    LSQL := Trim(LCurrent);
    if LSQL <> '' then
    begin
      LQuery.SQL.Text := LSQL;
      LQuery.ExecSQL;
    end;
  finally
    LQuery.Free;
  end;
end;

procedure TfrmMain.CreateDemoDatabase(const AFileName: string);
var
  LSchema, LData: string;
begin
  try
    if FConnection.Connected then
      FConnection.Disconnect;

    // Delete existing db file
    if FileExists(AFileName) then
      DeleteFile(AFileName);

    ForceDirectories(ExtractFilePath(AFileName));

    ApplyDatabaseConfig(AFileName);
    FConnection.Connect;

    LSchema :=
      'PRAGMA foreign_keys = ON;' + sLineBreak +
      'CREATE TABLE customers (' + sLineBreak +
      '    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,' + sLineBreak +
      '    customer_name VARCHAR(80) NOT NULL,' + sLineBreak +
      '    email VARCHAR(120),' + sLineBreak +
      '    phone VARCHAR(30),' + sLineBreak +
      '    city VARCHAR(60),' + sLineBreak +
      '    state VARCHAR(2),' + sLineBreak +
      '    created_at DATE NOT NULL' + sLineBreak +
      ');' + sLineBreak +
      'CREATE TABLE categories (' + sLineBreak +
      '    category_id INTEGER PRIMARY KEY AUTOINCREMENT,' + sLineBreak +
      '    category_name VARCHAR(60) NOT NULL' + sLineBreak +
      ');' + sLineBreak +
      'CREATE TABLE products (' + sLineBreak +
      '    product_id INTEGER PRIMARY KEY AUTOINCREMENT,' + sLineBreak +
      '    category_id INTEGER NOT NULL,' + sLineBreak +
      '    product_name VARCHAR(100) NOT NULL,' + sLineBreak +
      '    sku VARCHAR(30) NOT NULL,' + sLineBreak +
      '    unit_price NUMERIC(12,2) NOT NULL,' + sLineBreak +
      '    stock_quantity INTEGER NOT NULL,' + sLineBreak +
      '    active INTEGER NOT NULL DEFAULT 1,' + sLineBreak +
      '    FOREIGN KEY (category_id) REFERENCES categories(category_id)' + sLineBreak +
      ');' + sLineBreak +
      'CREATE TABLE promotions (' + sLineBreak +
      '    promotion_id INTEGER PRIMARY KEY AUTOINCREMENT,' + sLineBreak +
      '    product_id INTEGER NOT NULL,' + sLineBreak +
      '    promotion_name VARCHAR(100) NOT NULL,' + sLineBreak +
      '    discount_percent NUMERIC(5,2) NOT NULL,' + sLineBreak +
      '    start_date DATE NOT NULL,' + sLineBreak +
      '    end_date DATE NOT NULL,' + sLineBreak +
      '    active INTEGER NOT NULL DEFAULT 1,' + sLineBreak +
      '    FOREIGN KEY (product_id) REFERENCES products(product_id)' + sLineBreak +
      ');' + sLineBreak +
      'CREATE TABLE sales (' + sLineBreak +
      '    sale_id INTEGER PRIMARY KEY AUTOINCREMENT,' + sLineBreak +
      '    customer_id INTEGER NOT NULL,' + sLineBreak +
      '    sale_date DATE NOT NULL,' + sLineBreak +
      '    status VARCHAR(20) NOT NULL,' + sLineBreak +
      '    total_amount NUMERIC(12,2) NOT NULL,' + sLineBreak +
      '    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)' + sLineBreak +
      ');' + sLineBreak +
      'CREATE TABLE sale_items (' + sLineBreak +
      '    sale_item_id INTEGER PRIMARY KEY AUTOINCREMENT,' + sLineBreak +
      '    sale_id INTEGER NOT NULL,' + sLineBreak +
      '    product_id INTEGER NOT NULL,' + sLineBreak +
      '    quantity INTEGER NOT NULL,' + sLineBreak +
      '    unit_price NUMERIC(12,2) NOT NULL,' + sLineBreak +
      '    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,' + sLineBreak +
      '    total_amount NUMERIC(12,2) NOT NULL,' + sLineBreak +
      '    FOREIGN KEY (sale_id) REFERENCES sales(sale_id),' + sLineBreak +
      '    FOREIGN KEY (product_id) REFERENCES products(product_id)' + sLineBreak +
      ');' + sLineBreak +
      'CREATE TABLE payments (' + sLineBreak +
      '    payment_id INTEGER PRIMARY KEY AUTOINCREMENT,' + sLineBreak +
      '    sale_id INTEGER NOT NULL,' + sLineBreak +
      '    payment_date DATE NOT NULL,' + sLineBreak +
      '    payment_method VARCHAR(30) NOT NULL,' + sLineBreak +
      '    amount NUMERIC(12,2) NOT NULL,' + sLineBreak +
      '    FOREIGN KEY (sale_id) REFERENCES sales(sale_id)' + sLineBreak +
      ');' + sLineBreak +
      'CREATE INDEX idx_products_category ON products(category_id);' + sLineBreak +
      'CREATE INDEX idx_sales_customer ON sales(customer_id);' + sLineBreak +
      'CREATE INDEX idx_sales_date ON sales(sale_date);' + sLineBreak +
      'CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);' + sLineBreak +
      'CREATE INDEX idx_sale_items_product ON sale_items(product_id);' + sLineBreak +
      'CREATE INDEX idx_payments_sale ON payments(sale_id);';

    ExecuteScript(LSchema);

    LData :=
      'INSERT INTO customers (customer_name, email, phone, city, state, created_at) VALUES ' +
      '(''John Smith'', ''john@example.com'', ''555-1000'', ''New York'', ''NY'', ''2026-01-10''), ' +
      '(''Mary Johnson'', ''mary@example.com'', ''555-2000'', ''Boston'', ''MA'', ''2026-02-05''), ' +
      '(''Carlos Silva'', ''carlos@example.com'', ''555-3000'', ''Miami'', ''FL'', ''2026-03-15''), ' +
      '(''Ana Brown'', ''ana@example.com'', ''555-4000'', ''Chicago'', ''IL'', ''2026-04-20'');' + sLineBreak +
      'INSERT INTO categories (category_name) VALUES ' +
      '(''Computers''), (''Accessories''), (''Software''), (''Office'');' + sLineBreak +
      'INSERT INTO products (category_id, product_name, sku, unit_price, stock_quantity, active) VALUES ' +
      '(1, ''Notebook Pro 15'', ''NB-PRO-15'', 4500.00, 12, 1), ' +
      '(1, ''Desktop Business'', ''DT-BUS-01'', 3200.00, 8, 1), ' +
      '(2, ''Wireless Mouse'', ''ACC-MOUSE-01'', 80.00, 100, 1), ' +
      '(2, ''Mechanical Keyboard'', ''ACC-KEY-01'', 250.00, 40, 1), ' +
      '(3, ''Antivirus License'', ''SW-AV-01'', 120.00, 200, 1), ' +
      '(4, ''Office Chair'', ''OFF-CHAIR-01'', 650.00, 20, 1);' + sLineBreak +
      'INSERT INTO promotions (product_id, promotion_name, discount_percent, start_date, end_date, active) VALUES ' +
      '(1, ''Notebook Summer Sale'', 10.00, ''2026-06-01'', ''2026-06-30'', 1), ' +
      '(3, ''Mouse Clearance'', 15.00, ''2026-06-01'', ''2026-07-15'', 1), ' +
      '(5, ''Software Campaign'', 20.00, ''2026-05-01'', ''2026-06-30'', 1);' + sLineBreak +
      'INSERT INTO sales (customer_id, sale_date, status, total_amount) VALUES ' +
      '(1, ''2026-06-01'', ''PAID'', 4580.00), ' +
      '(2, ''2026-06-03'', ''PAID'', 330.00), ' +
      '(3, ''2026-06-05'', ''PENDING'', 650.00), ' +
      '(4, ''2026-06-10'', ''PAID'', 4620.00);' + sLineBreak +
      'INSERT INTO sale_items (sale_id, product_id, quantity, unit_price, discount_amount, total_amount) VALUES ' +
      '(1, 1, 1, 4500.00, 0.00, 4500.00), ' +
      '(1, 3, 1, 80.00, 0.00, 80.00), ' +
      '(2, 3, 1, 80.00, 0.00, 80.00), ' +
      '(2, 4, 1, 250.00, 0.00, 250.00), ' +
      '(3, 6, 1, 650.00, 0.00, 650.00), ' +
      '(4, 1, 1, 4500.00, 0.00, 4500.00), ' +
      '(4, 5, 1, 120.00, 0.00, 120.00);' + sLineBreak +
      'INSERT INTO payments (sale_id, payment_date, payment_method, amount) VALUES ' +
      '(1, ''2026-06-01'', ''Credit Card'', 4580.00), ' +
      '(2, ''2026-06-03'', ''Pix'', 330.00), ' +
      '(4, ''2026-06-10'', ''Credit Card'', 4620.00);';

    ExecuteScript(LData);
    FConnection.Disconnect;

    edtDatabasePath.Text := AFileName;
    FDictionaryGenerated := False;
    ShowMessage('Demo database created successfully.');
    lblDatabaseStatus.Caption := 'Status: Demo database created';
  except
    on E: Exception do
    begin
      ShowMessage('Error creating database: ' + E.Message);
      lblDatabaseStatus.Caption := 'Status: Creation failed';
    end;
  end;
end;

procedure TfrmMain.ConnectSQLite(const AFileName: string);
begin
  if Trim(AFileName) = '' then
  begin
    ShowMessage('Database file path is empty.');
    Exit;
  end;
  if not FileExists(AFileName) then
  begin
    ShowMessage('Database file does not exist.');
    Exit;
  end;

  try
    if FConnection.Connected then
      FConnection.Disconnect;

    ApplyDatabaseConfig(AFileName);
    FConnection.Connect;

    FQueryResult.Connection := FConnection;
    FDictionary.Connection := FConnection;
    FDataSource.DataSet := FQueryResult;
    DBGridResult.DataSource := FDataSource;
    
    FDictionaryGenerated := False;
    ShowMessage('Database connected successfully.');
    lblDatabaseStatus.Caption := 'Status: Connected';
  except
    on E: Exception do
    begin
      ShowMessage('Error connecting to database: ' + E.Message);
      lblDatabaseStatus.Caption := 'Status: Connection failed';
    end;
  end;
end;

function TfrmMain.GenerateDatabaseDictionary: Boolean;
begin
  Result := False;
  if not FConnection.Connected then
  begin
    ShowMessage('Database is not connected.');
    Exit;
  end;

  memoDictionary.Clear;
  FDictionary.Connection := FConnection;
  FDictionary.OutputFormat := dofAIPrompt;
  
  if FDictionary.Generate then
  begin
    FDictionaryGenerated := True;
    memoDictionary.Text := FDictionary.AsMarkdown;
    lblDatabaseStatus.Caption := 'Status: Dictionary generated';
    Result := True;
  end
  else
  begin
    FDictionaryGenerated := False;
    memoDictionary.Text := FDictionary.LastError;
    lblDatabaseStatus.Caption := 'Status: Dictionary generation failed';
  end;
end;

procedure TfrmMain.SyncChatGPTConfig;
begin
  FChatGPT.Provider := GetAIProviderFromIndex(cbProvider.ItemIndex);
  FChatGPT.TOKEN := Trim(edtToken.Text);
  FChatGPT.TipoChat := VCT_CUSTOM;
  FChatGPT.CustomModel := Trim(cbModel.Text);
  FChatGPT.URL := Trim(edtURL.Text);
  FChatGPT.Timeout := StrToIntDef(edtTimeout.Text, 120) * 1000;
  FChatGPT.MaxTokens := StrToIntDef(edtMaxTokens.Text, 2048);
end;

function TfrmMain.BuildSQLPrompt(const AUserRequest: string; const ADatabaseDictionary: string): string;
begin
  Result :=
    'You are a SQLite SQL generator.' + sLineBreak + sLineBreak +
    'Your task is to generate a single SQLite SELECT query based on the user''s request.' + sLineBreak + sLineBreak +
    'Important rules:' + sLineBreak +
    '- Return only the SQL query.' + sLineBreak +
    '- Do not explain.' + sLineBreak +
    '- Do not use Markdown.' + sLineBreak +
    '- Do not wrap the SQL in ```sql.' + sLineBreak +
    '- Generate only SELECT statements.' + sLineBreak +
    '- Do not generate INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, PRAGMA, ATTACH, DETACH, VACUUM, BEGIN, COMMIT or ROLLBACK commands.' + sLineBreak +
    '- Use only the tables and columns listed in the database dictionary.' + sLineBreak +
    '- Use SQLite-compatible syntax only.' + sLineBreak +
    '- Prefer explicit JOIN clauses.' + sLineBreak +
    '- Use readable aliases.' + sLineBreak +
    '- If aggregation is needed, use GROUP BY.' + sLineBreak +
    '- If filtering by dates, use SQLite date strings in YYYY-MM-DD format.' + sLineBreak +
    '- If the request is ambiguous, make the safest SELECT query possible.' + sLineBreak + sLineBreak +
    'Database dictionary:' + sLineBreak + sLineBreak +
    ADatabaseDictionary + sLineBreak + sLineBreak +
    'User request:' + sLineBreak + sLineBreak +
    AUserRequest + sLineBreak + sLineBreak +
    'Return only the SQLite SQL:';
end;

function TfrmMain.BuildSQLCorrectionPrompt(const AFailedSQL, AError: string): string;
begin
  Result :=
    'You are correcting a SQLite SELECT query that failed.' + sLineBreak + sLineBreak +
    'Correction rules:' + sLineBreak +
    '- Return only the corrected SQL query.' + sLineBreak +
    '- Do not explain and do not use Markdown.' + sLineBreak +
    '- Generate only a SELECT statement or a WITH query ending in SELECT.' + sLineBreak +
    '- Use only tables and columns from the database dictionary.' + sLineBreak +
    '- Use SQLite-compatible syntax.' + sLineBreak +
    '- Correct table names, column names, JOINs, aliases and data types based on the error.' + sLineBreak +
    '- Never generate INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, PRAGMA, ATTACH, ' +
      'DETACH, VACUUM, BEGIN, COMMIT or ROLLBACK.' + sLineBreak + sLineBreak +
    'Database dictionary:' + sLineBreak + sLineBreak +
    FDictionary.AsAIPrompt + sLineBreak + sLineBreak +
    'Original user request:' + sLineBreak +
    memoUserPrompt.Text + sLineBreak + sLineBreak +
    'SQL that failed:' + sLineBreak +
    AFailedSQL + sLineBreak + sLineBreak +
    'SQLite error or validation error:' + sLineBreak +
    AError + sLineBreak + sLineBreak +
    'Return only the corrected SQLite SQL:';
end;

function TfrmMain.ExtractSQLFromLLMResponse(const AResponse: string): string;
begin
  Result := Trim(AResponse);
  Result := StringReplace(Result, '```sql', '', [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '```', '', [rfReplaceAll]);
  Result := Trim(Result);
end;

function TfrmMain.IsSafeSelectSQL(const ASQL: string; out AError: string): Boolean;
var
  LUpper: string;
  DangerousKeywords: array[0..14] of string;
  I: Integer;
begin
  Result := False;
  LUpper := UpperCase(Trim(ASQL));
  
  if LUpper = '' then
  begin
    AError := 'SQL is empty.';
    Exit;
  end;

  if (not StartsText('SELECT', LUpper)) and (not StartsText('WITH', LUpper)) then
  begin
    AError := 'Only SELECT or WITH queries are allowed.';
    Exit;
  end;

  DangerousKeywords[0] := 'INSERT';
  DangerousKeywords[1] := 'UPDATE';
  DangerousKeywords[2] := 'DELETE';
  DangerousKeywords[3] := 'DROP';
  DangerousKeywords[4] := 'ALTER';
  DangerousKeywords[5] := 'CREATE';
  DangerousKeywords[6] := 'PRAGMA';
  DangerousKeywords[7] := 'ATTACH';
  DangerousKeywords[8] := 'DETACH';
  DangerousKeywords[9] := 'REPLACE';
  DangerousKeywords[10] := 'TRUNCATE';
  DangerousKeywords[11] := 'VACUUM';
  DangerousKeywords[12] := 'BEGIN';
  DangerousKeywords[13] := 'COMMIT';
  DangerousKeywords[14] := 'ROLLBACK';

  for I := 0 to High(DangerousKeywords) do
  begin
    if Pos(DangerousKeywords[I], LUpper) > 0 then
    begin
      AError := 'Unsafe SQL command detected: ' + DangerousKeywords[I];
      Exit;
    end;
  end;

  AError := 'SQL is valid.';
  Result := True;
end;

function TfrmMain.ExecuteSQLWithAutoCorrection(var ASQL: string): Boolean;
var
  LAttempt, LAttemptsUsed: Integer;
  LValidationMessage, LError, LPrompt, LResponse: string;
begin
  Result := False;
  ASQL := Trim(ASQL);
  LAttemptsUsed := 0;
  LError := '';

  SyncChatGPTConfig;

  for LAttempt := 1 to MAX_SQL_ATTEMPTS do
  begin
    LAttemptsUsed := LAttempt;
    memoGeneratedSQL.Text := ASQL;

    if not IsSafeSelectSQL(ASQL, LValidationMessage) then
      LError := 'SQL safety validation failed: ' + LValidationMessage
    else
    begin
      memoExecutionLog.Lines.Add(Format('Executing SQL (attempt %d of %d)...',
        [LAttempt, MAX_SQL_ATTEMPTS]));
      try
        if FQueryResult.Active then
          FQueryResult.Close;

        FQueryResult.SQL.Text := ASQL;
        FQueryResult.Open;

        lblRows.Caption := 'Rows: ' + IntToStr(FQueryResult.RecordCount);
        memoExecutionLog.Lines.Add(Format(
          'SQL executed successfully on attempt %d. Rows: %d',
          [LAttempt, FQueryResult.RecordCount]));
        PageControl1.ActivePage := tabResult;
        Result := True;
        Exit;
      except
        on E: Exception do
          LError := E.Message;
      end;
    end;

    memoExecutionLog.Lines.Add(Format(
      'SQL failed on attempt %d of %d: %s',
      [LAttempt, MAX_SQL_ATTEMPTS, LError]));

    if LAttempt >= MAX_SQL_ATTEMPTS then
      Break;

    if not FDictionaryGenerated then
    begin
      if not GenerateDatabaseDictionary then
      begin
        LError := 'Could not generate the SQLite database dictionary for correction.';
        memoExecutionLog.Lines.Add(LError);
        Break;
      end;
    end;

    if (FChatGPT.Provider <> AIP_LOCAL) and (FChatGPT.TOKEN = '') then
    begin
      LError := 'API token is required to send the SQLite error to the LLM.';
      memoExecutionLog.Lines.Add(LError);
      Break;
    end;

    LPrompt := BuildSQLCorrectionPrompt(ASQL, LError);
    memoPromptSentToLLM.Text := LPrompt;
    memoExecutionLog.Lines.Add('Sending the SQLite error to the LLM for correction...');

    try
      if not FChatGPT.SendQuestion(LPrompt) then
      begin
        LError := 'LLM correction failed: ' + FChatGPT.LastError;
        memoExecutionLog.Lines.Add(LError);
        Break;
      end;

      LResponse := FChatGPT.Response;
      ASQL := ExtractSQLFromLLMResponse(LResponse);
      if ASQL = '' then
      begin
        LError := 'The LLM returned an empty SQL correction.';
        memoExecutionLog.Lines.Add(LError);
        Break;
      end;

      memoGeneratedSQL.Text := ASQL;
      memoExecutionLog.Lines.Add('The LLM returned corrected SQLite SQL. Retrying...');
    except
      on E: Exception do
      begin
        LError := 'LLM correction failed: ' + E.Message;
        memoExecutionLog.Lines.Add(LError);
        Break;
      end;
    end;
  end;

  memoExecutionLog.Lines.Add(Format(
    'Final failure after %d attempt(s). Last error: %s',
    [LAttemptsUsed, LError]));
  ShowMessage(Format(
    'Failed to execute the SQLite SQL after %d attempt(s).' + sLineBreak +
    sLineBreak + '%s', [LAttemptsUsed, LError]));
end;

procedure TfrmMain.btnSelectDatabaseClick(Sender: TObject);
begin
  OpenDialog1.Filter := 'SQLite Database (*.db)|*.db|All files (*.*)|*.*';
  if OpenDialog1.Execute then
  begin
    edtDatabasePath.Text := OpenDialog1.FileName;
    lblDatabaseStatus.Caption := 'Status: Database selected';
    FDictionaryGenerated := False;
  end;
end;

procedure TfrmMain.btnCreateDatabaseClick(Sender: TObject);
begin
  CreateDemoDatabase(GetDemoDatabaseFileName);
end;

procedure TfrmMain.btnConnectDatabaseClick(Sender: TObject);
begin
  ConnectSQLite(edtDatabasePath.Text);
end;

procedure TfrmMain.btnGenerateDictionaryClick(Sender: TObject);
begin
  GenerateDatabaseDictionary;
end;

procedure TfrmMain.btnSaveDatabaseConfigClick(Sender: TObject);
begin
  SaveConfig;
  ShowMessage('Database configuration saved to:' + sLineBreak + ConfigFileName);
end;

procedure TfrmMain.btnSaveLLMConfigClick(Sender: TObject);
begin
  SyncChatGPTConfig;
  SaveConfig;
  ShowMessage('LLM configuration saved.');
end;

procedure TfrmMain.btnTestLLMClick(Sender: TObject);
var
  LPrompt, LResponse: string;
begin
  SyncChatGPTConfig;
  
  if (FChatGPT.Provider <> AIP_LOCAL) and (FChatGPT.TOKEN = '') then
  begin
    memoLLMLog.Lines.Add('API token is required for this provider.');
    Exit;
  end;

  memoLLMLog.Lines.Add('Testing LLM connection...');
  LPrompt := 'Reply only with: LLM connection OK';
  
  if FChatGPT.SendQuestion(LPrompt) then
  begin
    LResponse := FChatGPT.Response;
    memoLLMLog.Lines.Add('LLM Response: ' + LResponse);
    memoLLMLog.Lines.Add('LLM connection OK.');
  end;
end;

procedure TfrmMain.btnAddExamplePromptClick(Sender: TObject);
begin
  FExampleIndex := (FExampleIndex + 1) mod 10;
  memoUserPrompt.Text := ExamplePrompts[FExampleIndex];
end;

procedure TfrmMain.btnGenerateSQLClick(Sender: TObject);
var
  LPrompt, LResponse, LSQL: string;
begin
  if not FConnection.Connected then
  begin
    ShowMessage('Database is not connected.');
    Exit;
  end;

  if Trim(memoUserPrompt.Text) = '' then
  begin
    ShowMessage('User request is empty.');
    Exit;
  end;

  SyncChatGPTConfig;

  if (FChatGPT.Provider <> AIP_LOCAL) and (FChatGPT.TOKEN = '') then
  begin
    ShowMessage('API token is required for this provider.');
    Exit;
  end;

  if not FDictionaryGenerated then
  begin
    if not GenerateDatabaseDictionary then
    begin
      ShowMessage('Could not generate database dictionary.');
      Exit;
    end;
  end;

  LPrompt := BuildSQLPrompt(memoUserPrompt.Text, FDictionary.AsAIPrompt);
  memoPromptSentToLLM.Text := LPrompt;

  Screen.Cursor := crHourGlass;
  try
    if FChatGPT.SendQuestion(LPrompt) then
    begin
      LResponse := FChatGPT.Response;
      LSQL := ExtractSQLFromLLMResponse(LResponse);
      memoGeneratedSQL.Text := LSQL;
      PageControl1.ActivePage := tabSQL;
    end
    else
    begin
      ShowMessage('SQL generation failed: ' + FChatGPT.LastError);
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnValidateSQLClick(Sender: TObject);
var
  LMsg: string;
begin
  if IsSafeSelectSQL(memoGeneratedSQL.Text, LMsg) then
    ShowMessage('SQL validation succeeded: ' + LMsg)
  else
    ShowMessage('SQL validation failed: ' + LMsg);
end;

procedure TfrmMain.btnExecuteSQLClick(Sender: TObject);
var
  LSQL: string;
begin
  if not FConnection.Connected then
  begin
    ShowMessage('Database is not connected.');
    Exit;
  end;

  LSQL := memoGeneratedSQL.Text;
  Screen.Cursor := crHourGlass;
  try
    ExecuteSQLWithAutoCorrection(LSQL);
  finally
    memoGeneratedSQL.Text := LSQL;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.btnClearSQLClick(Sender: TObject);
begin
  memoGeneratedSQL.Clear;
  lblRows.Caption := 'Rows: 0';
  memoExecutionLog.Lines.Add('SQL cleared.');
end;

end.
