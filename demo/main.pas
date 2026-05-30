unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  chatgpt;

type

  { Tfrmdemo1 }

  Tfrmdemo1 = class(TForm)
    btSubmit: TButton;
    btRegistry: TButton;
    edASK: TEdit;
    edToken: TEdit;
    edLocalIP: TEdit;
    edCustomModel: TEdit;
    edMaxTokens: TEdit;
    cbProvider: TComboBox;
    cbModel: TComboBox;
    Label1: TLabel;
    LabelProvider: TLabel;
    LabelModel: TLabel;
    LabelMaxTokens: TLabel;
    LabelLocalIP: TLabel;
    LabelCustomModel: TLabel;
    meConversation: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    procedure btRegistryClick(Sender: TObject);
    procedure btSubmitClick(Sender: TObject);
    procedure edASKKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
  private
    FChatgpt : TCHATGPT;
    procedure CallASK();

  public

  end;

var
  frmdemo1: Tfrmdemo1;

implementation

{$R *.lfm}

{ Tfrmdemo1 }

procedure Tfrmdemo1.FormCreate(Sender: TObject);
begin
  FChatgpt := TChatgpt.create(nil);
  
  // Populate Providers
  cbProvider.Items.Clear;
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('OpenRouter');
  cbProvider.Items.Add('Cerebras');
  cbProvider.Items.Add('Local/Ollama');
  cbProvider.Items.Add('Gemini');
  cbProvider.Items.Add('Claude');
  cbProvider.ItemIndex := 0;
  
  // Trigger models update
  cbProviderChange(nil);
end;

procedure Tfrmdemo1.cbProviderChange(Sender: TObject);
begin
  cbModel.Items.Clear;
  case cbProvider.ItemIndex of
    0: // OpenAI
    begin
      cbModel.Items.Add('gpt-4o');
      cbModel.Items.Add('o3-mini');
      cbModel.Items.Add('gpt-4-turbo-preview');
      cbModel.Items.Add('gpt-4');
      cbModel.Items.Add('gpt-3.5-turbo');
      cbModel.Items.Add('gpt-4.1-mini');
      cbModel.Items.Add('gpt-5');
      cbModel.Items.Add('Custom Model');
      cbModel.ItemIndex := 0;
    end;
    1: // OpenRouter
    begin
      cbModel.Items.Add('google/gemma-2-9b-it:free');
      cbModel.Items.Add('Custom Model');
      cbModel.ItemIndex := 0;
    end;
    2: // Cerebras
    begin
      cbModel.Items.Add('qwen-3-235b-a22b-instruct-2507');
      cbModel.Items.Add('Custom Model');
      cbModel.ItemIndex := 0;
    end;
    3: // Local/Ollama
    begin
      cbModel.Items.Add('deepseek-r1:8b');
      cbModel.Items.Add('llama3.2:3b');
      cbModel.Items.Add('qwen2.5:1.5b');
      cbModel.Items.Add('deepseek-r1:1.5b');
      cbModel.Items.Add('deepseek-r1:14b');
      cbModel.Items.Add('deepseek-r1:70b');
      cbModel.Items.Add('Custom Model');
      cbModel.ItemIndex := 0;
    end;
    4: // Gemini
    begin
      cbModel.Items.Add('gemini-2.5-flash');
      cbModel.Items.Add('gemini-2.5-pro');
      cbModel.Items.Add('gemini-2.0-flash');
      cbModel.Items.Add('gemini-1.5-flash');
      cbModel.Items.Add('gemini-1.5-pro');
      cbModel.Items.Add('Custom Model');
      cbModel.ItemIndex := 0;
    end;
    5: // Claude
    begin
      cbModel.Items.Add('claude-3-5-sonnet-20241022');
      cbModel.Items.Add('claude-3-5-haiku-20241022');
      cbModel.Items.Add('claude-3-opus-20240229');
      cbModel.Items.Add('Custom Model');
      cbModel.ItemIndex := 0;
    end;
  end;
end;

procedure Tfrmdemo1.btRegistryClick(Sender: TObject);
begin
  FChatgpt.TOKEN:= edToken.text;
end;

procedure Tfrmdemo1.btSubmitClick(Sender: TObject);
begin
  CallASK();
end;

procedure Tfrmdemo1.edASKKeyPress(Sender: TObject; var Key: char);
begin
  if (key = #13) then
  begin
    CallASK();
  end;
end;

procedure Tfrmdemo1.FormDestroy(Sender: TObject);
begin
  FChatgpt.free;
end;

procedure Tfrmdemo1.CallASK;
var
  SelectedModelText: string;
begin
  FChatgpt.TOKEN := Trim(edToken.Text);
  FChatgpt.LocalIP := Trim(edLocalIP.Text);
  FChatgpt.CustomModel := Trim(edCustomModel.Text);
  FChatgpt.MaxTokens := StrToIntDef(edMaxTokens.Text, 4096);

  // Set AI Provider
  case cbProvider.ItemIndex of
    0: FChatgpt.Provider := AIP_OPENAI;
    1: FChatgpt.Provider := AIP_OPENROUTER;
    2: FChatgpt.Provider := AIP_CEREBRAS;
    3: FChatgpt.Provider := AIP_LOCAL;
    4: FChatgpt.Provider := AIP_GEMINI;
    5: FChatgpt.Provider := AIP_CLAUDE;
  end;

  // Set Model Version
  SelectedModelText := cbModel.Text;
  if SelectedModelText = 'Custom Model' then
  begin
    FChatgpt.TipoChat := VCT_CUSTOM;
  end
  else
  begin
    if FChatgpt.Provider = AIP_OPENAI then
    begin
      if SelectedModelText = 'gpt-4o' then FChatgpt.TipoChat := VCT_GPT4o
      else if SelectedModelText = 'o3-mini' then FChatgpt.TipoChat := VCT_GPTo3_mini
      else if SelectedModelText = 'gpt-4-turbo-preview' then FChatgpt.TipoChat := VCT_GPT40_TURBO
      else if SelectedModelText = 'gpt-4' then FChatgpt.TipoChat := VCT_GPT40
      else if SelectedModelText = 'gpt-3.5-turbo' then FChatgpt.TipoChat := VCT_GPT35TURBO
      else if SelectedModelText = 'gpt-4.1-mini' then FChatgpt.TipoChat := VCT_GPT41_MINI
      else if SelectedModelText = 'gpt-5' then FChatgpt.TipoChat := VCT_GPT5;
    end
    else if FChatgpt.Provider = AIP_LOCAL then
    begin
      if SelectedModelText = 'deepseek-r1:8b' then FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B
      else if SelectedModelText = 'llama3.2:3b' then FChatgpt.TipoChat := VCT_LLAMA32_3B
      else if SelectedModelText = 'qwen2.5:1.5b' then FChatgpt.TipoChat := VCT_QWEN25_15B
      else if SelectedModelText = 'deepseek-r1:1.5b' then FChatgpt.TipoChat := VCT_DEEPSEEK_R1_15B
      else if SelectedModelText = 'deepseek-r1:14b' then FChatgpt.TipoChat := VCT_DEEPSEEK_R1_14B
      else if SelectedModelText = 'deepseek-r1:70b' then FChatgpt.TipoChat := VCT_DEEPSEEK_R1_70B;
    end
    else if FChatgpt.Provider = AIP_GEMINI then
    begin
      if SelectedModelText = 'gemini-2.5-flash' then FChatgpt.TipoChat := VCT_GEMINI_25_FLASH
      else if SelectedModelText = 'gemini-2.5-pro' then FChatgpt.TipoChat := VCT_GEMINI_25_PRO
      else if SelectedModelText = 'gemini-2.0-flash' then FChatgpt.TipoChat := VCT_GEMINI_20_FLASH
      else if SelectedModelText = 'gemini-1.5-flash' then FChatgpt.TipoChat := VCT_GEMINI_15_FLASH
      else if SelectedModelText = 'gemini-1.5-pro' then FChatgpt.TipoChat := VCT_GEMINI_15_PRO;
    end
    else if FChatgpt.Provider = AIP_CLAUDE then
    begin
      if SelectedModelText = 'claude-3-5-sonnet-20241022' then FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET
      else if SelectedModelText = 'claude-3-5-haiku-20241022' then FChatgpt.TipoChat := VCT_CLAUDE_35_HAIKU
      else if SelectedModelText = 'claude-3-opus-20240229' then FChatgpt.TipoChat := VCT_CLAUDE_3_OPUS;
    end;
  end;

  meConversation.Lines.Append('>>> (' + FChatgpt.ProviderName + ' - ' + FChatgpt.TipoModelo + ') ' + edASK.Text);
  if FChatgpt.SendQuestion(edASK.Text) then
    meConversation.Lines.Append(FChatgpt.Response)
  else
    meConversation.Lines.Append('ERROR: ' + FChatgpt.Response);
  meConversation.Lines.Append('');
end;

end.
