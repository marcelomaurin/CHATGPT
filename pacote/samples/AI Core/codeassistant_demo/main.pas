unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aicodeassistant, chatgpt;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    memoLog: TMemo;
    pnBotton: TPanel;
    pnTop: TPanel;
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    btnRun: TButton;
    btnClearLog: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAICodeAssistant: TAICodeAssistant; 
    FEditLang: TEdit; 
    FMemoCode: TMemo;
    
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblToken: TLabel;
    edtToken: TEdit;
    lblEndpoint: TLabel;
    edtEndpoint: TEdit;
    
    procedure cbProviderChange(Sender: TObject);
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
var
  LBackgroundChatGPT: TCHATGPT;
begin
  AddLog('Codeassistant Demo (aicodeassistant) initialized.');
  FAICodeAssistant := TAICodeAssistant.Create(Self);
  LBackgroundChatGPT := TCHATGPT.Create(Self);
  FAICodeAssistant.ChatGPT := LBackgroundChatGPT;
  
  // Create UI components programmatically to avoid lfm conflicts
  lblProvider := TLabel.Create(Self);
  lblProvider.Parent := pnlTop;
  lblProvider.Left := 15;
  lblProvider.Top := 75;
  lblProvider.Caption := 'Provider:';
  
  cbProvider := TComboBox.Create(Self);
  cbProvider.Parent := pnlTop;
  cbProvider.Left := 70;
  cbProvider.Top := 70;
  cbProvider.Width := 100;
  cbProvider.Style := csDropDownList;
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('OpenRouter');
  cbProvider.Items.Add('Cerebras');
  cbProvider.Items.Add('Ollama');
  cbProvider.Items.Add('Gemini');
  cbProvider.Items.Add('Claude');
  cbProvider.Items.Add('LM Studio');
  cbProvider.Items.Add('Local HTTP');
  cbProvider.OnChange := @cbProviderChange;
  
  lblModel := TLabel.Create(Self);
  lblModel.Parent := pnlTop;
  lblModel.Left := 180;
  lblModel.Top := 75;
  lblModel.Caption := 'Model:';
  
  cbModel := TComboBox.Create(Self);
  cbModel.Parent := pnlTop;
  cbModel.Left := 225;
  cbModel.Top := 70;
  cbModel.Width := 150;
  
  lblToken := TLabel.Create(Self);
  lblToken.Parent := pnlTop;
  lblToken.Left := 385;
  lblToken.Top := 75;
  lblToken.Caption := 'Token:';
  
  edtToken := TEdit.Create(Self);
  edtToken.Parent := pnlTop;
  edtToken.Left := 430;
  edtToken.Top := 70;
  edtToken.Width := 150;
  edtToken.PasswordChar := '*';
  
  lblEndpoint := TLabel.Create(Self);
  lblEndpoint.Parent := pnlTop;
  lblEndpoint.Left := 15;
  lblEndpoint.Top := 105;
  lblEndpoint.Caption := 'URL / IP:';
  
  edtEndpoint := TEdit.Create(Self);
  edtEndpoint.Parent := pnlTop;
  edtEndpoint.Left := 70;
  edtEndpoint.Top := 100;
  edtEndpoint.Width := 200;
  
  // Adjust original buttons
  btnRun.Left := 280;
  btnRun.Top := 98;
  btnClearLog.Left := 440;
  btnClearLog.Top := 98;
  
  FEditLang := TEdit.Create(Self);
  FEditLang.Parent := pnBotton;
  FEditLang.Left := 15;
  FEditLang.Top := 15;
  FEditLang.Width := 150;
  FEditLang.Text := 'Object Pascal';
  
  // Expand pnlTop height to fit the connection controls nicely
  pnlTop.Height := 140;
  
  FMemoCode := TMemo.Create(Self);
  FMemoCode.Parent := pnBotton;
  FMemoCode.Left := 15;
  FMemoCode.Top := 50;
  FMemoCode.Width := 750;
  FMemoCode.Height := 150;
  FMemoCode.Anchors := [akTop, akLeft, akRight, akBottom];
  FMemoCode.Lines.Text := 'procedure TForm1.Button1Click(Sender: TObject)'#13#10'begin'#13#10'  ShowMessage("Hello World");'#13#10'end;';
  
  // Initialize with OpenAI
  cbProvider.ItemIndex := 0;
  cbProviderChange(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.cbProviderChange(Sender: TObject);
begin
  cbModel.Items.Clear;
  edtEndpoint.Text := '';
  edtEndpoint.Enabled := False;

  if SameText(cbProvider.Text, 'OpenAI') then
  begin
    cbModel.Items.Add('gpt-4o');
    cbModel.Items.Add('gpt-4o-mini');
    cbModel.Items.Add('o3-mini');
    cbModel.Text := 'gpt-4o-mini';
  end
  else if SameText(cbProvider.Text, 'Gemini') then
  begin
    cbModel.Items.Add('gemini-2.5-flash');
    cbModel.Items.Add('gemini-2.5-pro');
    cbModel.Items.Add('gemini-2.0-flash');
    cbModel.Text := 'gemini-2.5-flash';
  end
  else if SameText(cbProvider.Text, 'Claude') then
  begin
    cbModel.Items.Add('claude-3-5-sonnet-20241022');
    cbModel.Items.Add('claude-3-5-haiku-20241022');
    cbModel.Text := 'claude-3-5-sonnet-20241022';
  end
  else if SameText(cbProvider.Text, 'OpenRouter') then
  begin
    cbModel.Items.Add('meta-llama/llama-3-8b-instruct:free');
    cbModel.Items.Add('google/gemma-2-9b-it:free');
    cbModel.Items.Add('deepseek/deepseek-r1:free');
    cbModel.Text := 'google/gemma-2-9b-it:free';
  end
  else if SameText(cbProvider.Text, 'Cerebras') then
  begin
    cbModel.Items.Add('qwen-3-235b-a22b-instruct-2507');
    cbModel.Text := 'qwen-3-235b-a22b-instruct-2507';
  end
  else if SameText(cbProvider.Text, 'Ollama') then
  begin
    cbModel.Items.Add('llama3.2');
    cbModel.Items.Add('qwen2.5');
    cbModel.Text := 'llama3.2';
    edtEndpoint.Text := 'http://localhost:11434';
    edtEndpoint.Enabled := True;
  end
  else if SameText(cbProvider.Text, 'LM Studio') then
  begin
    cbModel.Items.Add('local-model');
    cbModel.Text := 'local-model';
    edtEndpoint.Text := 'http://localhost:1234/v1';
    edtEndpoint.Enabled := True;
  end
  else if SameText(cbProvider.Text, 'Local HTTP') then
  begin
    cbModel.Items.Add('local-model');
    cbModel.Text := 'local-model';
    edtEndpoint.Text := 'http://localhost:8080';
    edtEndpoint.Enabled := True;
  end;
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  lblStatus.Caption := 'Status: Processing...';
  AddLog('--- Starting Execution ---');
  try
    if Assigned(FAICodeAssistant.ChatGPT) then
    begin
      FAICodeAssistant.ChatGPT.MaxTokens := 1024;
      
      if SameText(cbProvider.Text, 'OpenAI') then FAICodeAssistant.ChatGPT.Provider := AIP_OPENAI
      else if SameText(cbProvider.Text, 'Gemini') then FAICodeAssistant.ChatGPT.Provider := AIP_GEMINI
      else if SameText(cbProvider.Text, 'Claude') then FAICodeAssistant.ChatGPT.Provider := AIP_CLAUDE
      else if SameText(cbProvider.Text, 'OpenRouter') then FAICodeAssistant.ChatGPT.Provider := AIP_OPENROUTER
      else if SameText(cbProvider.Text, 'Cerebras') then FAICodeAssistant.ChatGPT.Provider := AIP_CEREBRAS
      else FAICodeAssistant.ChatGPT.Provider := AIP_LOCAL;
      
      FAICodeAssistant.ChatGPT.TOKEN := Trim(edtToken.Text);
      FAICodeAssistant.ChatGPT.CustomModel := Trim(cbModel.Text);
      FAICodeAssistant.ChatGPT.URL := '';
      
      if FAICodeAssistant.ChatGPT.Provider = AIP_LOCAL then
        FAICodeAssistant.ChatGPT.LocalIP := Trim(edtEndpoint.Text);
    end;
    
    AddLog('Code Assistant Properties:');
    AddLog('  Provider: ' + cbProvider.Text);
    AddLog('  Model: ' + cbModel.Text);
    AddLog('  Language: ' + FEditLang.Text);
    
    AddLog('Running code assistant...');
    try
      // Optimize code
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

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(AMsg);
  memoLog.SelStart := Length(memoLog.Text);
end;

end.
