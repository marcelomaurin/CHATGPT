unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, TypInfo, aibase, aicodeassistant, chatgpt, IniFiles;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    memoLog: TMemo;
    pgcMain: TPageControl;
    tsSetup: TTabSheet;
    tsOperation: TTabSheet;
    tsLog: TTabSheet;
    
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnSave: TButton;
    
    FAICodeAssistant: TAICodeAssistant; 
    FBackgroundChatGPT: TCHATGPT;
    
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblToken: TLabel;
    edtToken: TEdit;
    lblEndpoint: TLabel;
    edtEndpoint: TEdit;
    
    lblCustomModel: TLabel;
    edtCustomModel: TEdit;
    
    pnlLogButtons: TPanel;
    btnClearLog: TButton;
    
    // Operation Tab Components
    pnResult: TPanel;
    meAnalise: TMemo;
    pnMeio: TPanel;
    FMemoCode: TMemo;
    pnTop: TPanel;
    lblLang: TLabel;
    lblCode: TLabel;
    cbScript: TComboBox;
    btCheck: TButton;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btCheckClick(Sender: TObject);
    procedure cbScriptChange(Sender: TObject);
  private
    procedure AddLog(const AMsg: string);
    function GetConfigFilename: string;
    procedure SaveConfig;
    procedure LoadConfig;
    procedure PopulateProviders;
    procedure ConfigureAssistant;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.PopulateProviders;
var
  Prov: TAIProvider;
  S: string;
begin
  cbProvider.Items.Clear;
  for Prov := Low(TAIProvider) to High(TAIProvider) do
  begin
    case Prov of
      AIP_OPENAI: S := 'OpenAI (AIP_OPENAI)';
      AIP_OPENROUTER: S := 'OpenRouter (AIP_OPENROUTER)';
      AIP_CEREBRAS: S := 'Cerebras (AIP_CEREBRAS)';
      AIP_LOCAL: S := 'Local / Ollama (AIP_LOCAL)';
      AIP_GEMINI: S := 'Gemini (AIP_GEMINI)';
      AIP_CLAUDE: S := 'Claude (AIP_CLAUDE)';
    else
      S := GetEnumName(TypeInfo(TAIProvider), Ord(Prov));
    end;
    cbProvider.Items.AddObject(S, TObject(Pointer(Prov)));
  end;
end;

function TfrmMain.GetConfigFilename: string;
var
  AppDir: string;
begin
  AppDir := GetAppConfigDir(False);
  if not DirectoryExists(AppDir) then
    ForceDirectories(AppDir);
  Result := IncludeTrailingPathDelimiter(AppDir) + 'config.ini';
end;

procedure TfrmMain.SaveConfig;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetConfigFilename);
  try
    Ini.WriteString('Settings', 'Provider', cbProvider.Text);
    Ini.WriteString('Settings', 'Model', cbModel.Text);
    Ini.WriteString('Settings', 'CustomModel', edtCustomModel.Text);
    Ini.WriteString('Settings', 'Token', edtToken.Text);
    Ini.WriteString('Settings', 'Endpoint', edtEndpoint.Text);
    Ini.WriteString('Settings', 'Language', cbScript.Text);
    Ini.WriteString('Settings', 'Code', FMemoCode.Lines.Text);
    AddLog('Configuration saved to: ' + GetConfigFilename);
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.LoadConfig;
var
  Ini: TIniFile;
  ProvStr, ModelStr, LangStr: string;
begin
  if not FileExists(GetConfigFilename) then
    Exit;
  Ini := TIniFile.Create(GetConfigFilename);
  try
    ProvStr := Ini.ReadString('Settings', 'Provider', '');
    cbProvider.ItemIndex := cbProvider.Items.IndexOf(ProvStr);
    if cbProvider.ItemIndex = -1 then cbProvider.ItemIndex := 0;
    cbProviderChange(nil); // Updates cbModel items

    ModelStr := Ini.ReadString('Settings', 'Model', '');
    cbModel.ItemIndex := cbModel.Items.IndexOf(ModelStr);
    if cbModel.ItemIndex = -1 then cbModel.ItemIndex := 0;

    edtCustomModel.Text := Ini.ReadString('Settings', 'CustomModel', '');
    edtToken.Text := Ini.ReadString('Settings', 'Token', '');
    edtEndpoint.Text := Ini.ReadString('Settings', 'Endpoint', '');
    
    LangStr := Ini.ReadString('Settings', 'Language', 'Object Pascal (with bug)');
    cbScript.ItemIndex := cbScript.Items.IndexOf(LangStr);
    if cbScript.ItemIndex = -1 then cbScript.ItemIndex := 0;
    cbScriptChange(nil);

    FMemoCode.Lines.Text := Ini.ReadString('Settings', 'Code', FMemoCode.Lines.Text);
    AddLog('Configuration loaded from: ' + GetConfigFilename);
  finally
    Ini.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  AddLog('Codeassistant Demo (aicodeassistant) initialized.');
  
  PopulateProviders;
  
  // Load saved settings if any, otherwise default to OpenAI
  if FileExists(GetConfigFilename) then
    LoadConfig
  else
  begin
    cbProvider.ItemIndex := 0;
    cbProviderChange(nil);
    cbScript.ItemIndex := 0;
    cbScriptChange(nil);
  end;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
var
  Prov: TAIProvider;
begin
  if cbProvider.ItemIndex = -1 then Exit;
  Prov := TAIProvider(Pointer(cbProvider.Items.Objects[cbProvider.ItemIndex]));

  cbModel.Items.Clear;
  edtEndpoint.Text := '';
  edtEndpoint.Enabled := False;

  case Prov of
    AIP_OPENAI:
    begin
      cbModel.Items.AddObject('gpt-4o', TObject(Pointer(VCT_GPT4o)));
      cbModel.Items.AddObject('gpt-4o-mini', TObject(Pointer(VCT_GPT4O_MINI)));
      cbModel.Items.AddObject('o3-mini', TObject(Pointer(VCT_GPTo3_mini)));
      cbModel.Items.AddObject('gpt-4', TObject(Pointer(VCT_GPT40)));
      cbModel.Items.AddObject('gpt-4-turbo', TObject(Pointer(VCT_GPT40_TURBO)));
      cbModel.Items.AddObject('o1', TObject(Pointer(VCT_GPTo1)));
      cbModel.Items.AddObject('o1-mini', TObject(Pointer(VCT_GPTo1_mini)));
      cbModel.Items.AddObject('o1-preview', TObject(Pointer(VCT_GPTo1_preview)));
      cbModel.Items.AddObject('gpt-3.5-turbo', TObject(Pointer(VCT_GPT35TURBO)));
      cbModel.ItemIndex := 1; // gpt-4o-mini
    end;
    AIP_GEMINI:
    begin
      cbModel.Items.AddObject('gemini-2.5-flash', TObject(Pointer(VCT_GEMINI_25_FLASH)));
      cbModel.Items.AddObject('gemini-2.5-pro', TObject(Pointer(VCT_GEMINI_25_PRO)));
      cbModel.Items.AddObject('gemini-2.0-flash', TObject(Pointer(VCT_GEMINI_20_FLASH)));
      cbModel.ItemIndex := 0; // gemini-2.5-flash
    end;
    AIP_CLAUDE:
    begin
      cbModel.Items.AddObject('claude-3-5-sonnet-20241022', TObject(Pointer(VCT_CLAUDE_35_SONNET)));
      cbModel.Items.AddObject('claude-3-5-haiku-20241022', TObject(Pointer(VCT_CLAUDE_35_HAIKU)));
      cbModel.Items.AddObject('claude-3-opus-20240229', TObject(Pointer(VCT_CLAUDE_3_OPUS)));
      cbModel.ItemIndex := 0; // claude-3-5-sonnet-20241022
    end;
    AIP_OPENROUTER:
    begin
      cbModel.Items.AddObject('meta-llama/llama-3-8b-instruct:free', TObject(Pointer(VCT_OPENROUTER_LLAMA3_8B_FREE)));
      cbModel.Items.AddObject('google/gemma-2-9b-it:free', TObject(Pointer(VCT_OPENROUTER_GEMMA2_9B_FREE)));
      cbModel.Items.AddObject('deepseek/deepseek-r1:free', TObject(Pointer(VCT_OPENROUTER_DEEPSEEK_R1_FREE)));
      cbModel.Items.AddObject('meta-llama/llama-3.2-3b-instruct:free', TObject(Pointer(VCT_OPENROUTER_LLAMA32_3B_FREE)));
      cbModel.ItemIndex := 1; // google/gemma-2-9b-it:free
    end;
    AIP_CEREBRAS:
    begin
      cbModel.Items.AddObject('qwen-3-235b-a22b-instruct-2507', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 0;
    end;
    AIP_LOCAL:
    begin
      cbModel.Items.AddObject('llama3.2', TObject(Pointer(VCT_LLAMA32_3B)));
      cbModel.Items.AddObject('qwen2.5', TObject(Pointer(VCT_QWEN25_15B)));
      cbModel.Items.AddObject('deepseek-r1:1.5b', TObject(Pointer(VCT_DEEPSEEK_R1_1_5b)));
      cbModel.Items.AddObject('deepseek-r1:7b', TObject(Pointer(VCT_DEEPSEEK_R1_7b)));
      cbModel.Items.AddObject('deepseek-r1:8b', TObject(Pointer(VCT_DEEPSEEK_R1_8B)));
      cbModel.Items.AddObject('deepseek-r1:14b', TObject(Pointer(VCT_DEEPSEEK_R1_14B)));
      cbModel.Items.AddObject('deepseek-r1:70b', TObject(Pointer(VCT_DEEPSEEK_R1_70B)));
      cbModel.Items.AddObject('local-model', TObject(Pointer(VCT_CUSTOM)));
      cbModel.ItemIndex := 0; // llama3.2
      edtEndpoint.Text := 'http://localhost:11434';
      edtEndpoint.Enabled := True;
    end;
  end;
end;

procedure TfrmMain.cbScriptChange(Sender: TObject);
begin
  case cbScript.ItemIndex of
    0: // Object Pascal
    begin
      FMemoCode.Lines.Text := 
        'procedure TForm1.Button1Click(Sender: TObject)'#13#10 +
        'begin'#13#10 +
        '  ShowMessage("Hello World")'#13#10 +
        'end;';
    end;
    1: // Python
    begin
      FMemoCode.Lines.Text := 
        'def calculate_sum(a, b)'#13#10 +
        '    return a + b'#13#10 +
        'print(calculate_sum(5, "10"))';
    end;
    2: // JavaScript
    begin
      FMemoCode.Lines.Text := 
        'function greet(name) {'#13#10 +
        '  console.log("Hello, " + name)'#13#10 +
        '}'#13#10 +
        'greet(';
    end;
    3: // C++
    begin
      FMemoCode.Lines.Text := 
        '#include <iostream>'#13#10 +
        'int main() {'#13#10 +
        '    std::cout << "Hello World"'#13#10 +
        '    return 0;'#13#10 +
        '}';
    end;
  end;
end;

procedure TfrmMain.ConfigureAssistant;
var
  LProv: TAIProvider;
begin
  if Assigned(FAICodeAssistant.ChatGPT) then
  begin
    FAICodeAssistant.ChatGPT.MaxTokens := 1024;
    
    if cbProvider.ItemIndex <> -1 then
    begin
      LProv := TAIProvider(Pointer(cbProvider.Items.Objects[cbProvider.ItemIndex]));
      FAICodeAssistant.ChatGPT.Provider := LProv;
    end;
    
    FAICodeAssistant.ChatGPT.TOKEN := Trim(edtToken.Text);
    FAICodeAssistant.ChatGPT.URL := '';
    
    if Trim(edtCustomModel.Text) <> '' then
    begin
      FAICodeAssistant.ChatGPT.TipoChat := VCT_CUSTOM;
      FAICodeAssistant.ChatGPT.CustomModel := Trim(edtCustomModel.Text);
    end
    else if cbModel.ItemIndex <> -1 then
    begin
      FAICodeAssistant.ChatGPT.TipoChat := TVersionChat(Pointer(cbModel.Items.Objects[cbModel.ItemIndex]));
      FAICodeAssistant.ChatGPT.CustomModel := cbModel.Text;
    end;
    
    if FAICodeAssistant.ChatGPT.Provider = AIP_LOCAL then
      FAICodeAssistant.ChatGPT.LocalIP := Trim(edtEndpoint.Text);
  end;
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
    ConfigureAssistant;
    
    AddLog('Code Assistant Properties:');
    AddLog('  Provider: ' + cbProvider.Text);
    if Trim(edtCustomModel.Text) <> '' then
      AddLog('  Model (Custom): ' + edtCustomModel.Text)
    else
      AddLog('  Model: ' + cbModel.Text);
    AddLog('  Language (Selected Script): ' + cbScript.Text);
    
    AddLog('Running code assistant...');
    try
      AddLog('Result: ' + FAICodeAssistant.OptimizeCode(FMemoCode.Lines.Text));
    except
      on E: Exception do AddLog('Error: ' + E.Message);
    end;

    lblStatus.Caption := 'Status: Completed Successfully';
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      lblStatus.Caption := 'Status: Execution Error';
    end;
  end;
  AddLog('--- Execution Finished ---');
end;

procedure TfrmMain.btCheckClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Checking Syntax...';
  meAnalise.Clear;
  AddLog('--- Starting Code Syntax Check ---');
  try
    ConfigureAssistant;
    
    AddLog('Requesting syntax analysis (FindBugs) from Assistant...');
    meAnalise.Lines.Text := FAICodeAssistant.FindBugs(FMemoCode.Lines.Text);
    AddLog('Code Syntax Check completed.');
    
    lblStatus.Caption := 'Status: Syntax Checked';
  except
    on E: Exception do
    begin
      meAnalise.Lines.Text := 'Error during syntax analysis: ' + E.Message;
      AddLog('Error during syntax check: ' + E.Message);
      lblStatus.Caption := 'Status: Syntax Check Error';
    end;
  end;
  AddLog('--- Code Syntax Check Finished ---');
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  SaveConfig;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
  memoLog.SelStart := Length(memoLog.Text);
end;

end.
