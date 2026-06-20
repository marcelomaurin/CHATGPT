unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
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
    lblDatabaseStatus: TLabel;
    memoDictionary: TMemo;
    pnlLlmConfig: TPanel;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblToken: TLabel;
    edtToken: TEdit;
    lblMaxTokens: TLabel;
    edtMaxTokens: TEdit;
    btnTestLLM: TButton;
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
    procedure btnTestLLMClick(Sender: TObject);
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

    function GetDemoDatabaseFileName: string;
    procedure CreateDemoDatabase(const AFileName: string);
    procedure ExecuteScript(const AScript: string);
    procedure ConnectSQLite(const AFileName: string);
    function GenerateDatabaseDictionary: Boolean;
    procedure SyncChatGPTConfig;
    function BuildSQLPrompt(const AUserRequest: string; const ADatabaseDictionary: string): string;
    function ExtractSQLFromLLMResponse(const AResponse: string): string;
    function IsSafeSelectSQL(const ASQL: string; out AError: string): Boolean;
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

const
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

  // Set startup defaults
  edtMaxTokens.Text := '2048';
  
  cbProvider.Items.Clear;
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('OpenRouter');
  cbProvider.Items.Add('Cerebras');
  cbProvider.Items.Add('Local/Ollama');
  cbProvider.Items.Add('Gemini');
  cbProvider.Items.Add('Claude');
  cbProvider.ItemIndex := 0;
  cbProviderChange(Self);

  memoUserPrompt.Text := ExamplePrompts[0];
  edtDatabasePath.Text := GetDemoDatabaseFileName;
  lblDatabaseStatus.Caption := 'Status: Not connected';
  lblRows.Caption := 'Rows: 0';

  memoDictionary.Clear;
  memoPromptSentToLLM.Clear;
  memoGeneratedSQL.Clear;
  memoExecutionLog.Clear;
  memoLLMLog.Clear;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FQueryResult.Active then
    FQueryResult.Close;
  if FConnection.Connected then
    FConnection.Disconnect;
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
begin
  cbModel.Items.Clear;
  if cbProvider.Text = 'OpenAI' then
  begin
    cbModel.Items.Add('gpt-4o-mini');
    cbModel.Items.Add('gpt-4o');
    cbModel.Items.Add('o3-mini');
    cbModel.Items.Add('gpt-4-turbo-preview');
    cbModel.Items.Add('gpt-3.5-turbo');
    cbModel.ItemIndex := 0;
  end
  else if cbProvider.Text = 'Local/Ollama' then
  begin
    cbModel.Items.Add('llama3.2:3b');
    cbModel.Items.Add('deepseek-r1:8b');
    cbModel.ItemIndex := 0;
  end
  else if cbProvider.Text = 'Gemini' then
  begin
    cbModel.Items.Add('gemini-2.5-flash');
    cbModel.Items.Add('gemini-2.5-pro');
    cbModel.ItemIndex := 0;
  end
  else if cbProvider.Text = 'Claude' then
  begin
    cbModel.Items.Add('claude-3-5-sonnet-latest');
    cbModel.ItemIndex := 0;
  end
  else
  begin
    cbModel.Items.Add('default');
    cbModel.ItemIndex := 0;
  end;
end;

function TfrmMain.GetDemoDatabaseFileName: string;
begin
  Result := ExtractFilePath(Application.ExeName) + 'database' + DirectorySeparator + 'sales_ai_demo.db';
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

    FConnection.Protocol := 'sqlite';
    FConnection.Database := AFileName;
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

    FConnection.Protocol := 'sqlite';
    FConnection.Database := AFileName;
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
  FChatGPT.TOKEN := Trim(edtToken.Text);
  FChatGPT.MaxTokens := StrToIntDef(edtMaxTokens.Text, 2048);

  if cbProvider.Text = 'OpenAI' then
  begin
    FChatGPT.Provider := AIP_OPENAI;
    if cbModel.Text = 'gpt-4o' then
      FChatGPT.TipoChat := VCT_GPT4o
    else if cbModel.Text = 'gpt-4o-mini' then
      FChatGPT.TipoChat := VCT_GPT4O_MINI
    else if cbModel.Text = 'o3-mini' then
      FChatGPT.TipoChat := VCT_GPTo3_mini
    else if cbModel.Text = 'gpt-4-turbo-preview' then
      FChatGPT.TipoChat := VCT_GPT40_TURBO
    else
      FChatGPT.TipoChat := VCT_GPT35TURBO;
  end
  else if cbProvider.Text = 'Local/Ollama' then
  begin
    FChatGPT.Provider := AIP_LOCAL;
    if cbModel.Text = 'deepseek-r1:8b' then
      FChatGPT.TipoChat := VCT_DEEPSEEK_R1_8B
    else
      FChatGPT.TipoChat := VCT_LLAMA32_3B;
  end
  else if cbProvider.Text = 'Gemini' then
  begin
    FChatGPT.Provider := AIP_GEMINI;
    FChatGPT.TipoChat := VCT_GEMINI_25_FLASH;
  end
  else if cbProvider.Text = 'Claude' then
  begin
    FChatGPT.Provider := AIP_CLAUDE;
    FChatGPT.TipoChat := VCT_CLAUDE_35_SONNET;
  end;
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
  LErr: string;
begin
  if not FConnection.Connected then
  begin
    ShowMessage('Database is not connected.');
    Exit;
  end;

  if not IsSafeSelectSQL(memoGeneratedSQL.Text, LErr) then
  begin
    ShowMessage('Cannot execute SQL: ' + LErr);
    Exit;
  end;

  memoExecutionLog.Lines.Add('Executing SQL...');
  try
    if FQueryResult.Active then
      FQueryResult.Close;

    FQueryResult.SQL.Text := memoGeneratedSQL.Text;
    FQueryResult.Open;

    lblRows.Caption := 'Rows: ' + IntToStr(FQueryResult.RecordCount);
    memoExecutionLog.Lines.Add('SQL executed successfully.');
    PageControl1.ActivePage := tabResult;
  except
    on E: Exception do
    begin
      memoExecutionLog.Lines.Add('Execution failed: ' + E.Message);
      ShowMessage('Execution failed: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnClearSQLClick(Sender: TObject);
begin
  memoGeneratedSQL.Clear;
  lblRows.Caption := 'Rows: 0';
  memoExecutionLog.Lines.Add('SQL cleared.');
end;

end.
