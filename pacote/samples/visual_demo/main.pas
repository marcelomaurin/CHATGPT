unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  StdCtrls, Grids, chatgpt, NeuralNetwork, aicodeassistant, aidatasetgenerator;

type

  { TfrmVisualDemo }

  TfrmVisualDemo = class(TForm)
    PageControl1: TPageControl;
    
    // Tab 1: ChatGPT Connector
    tabChatGPT: TTabSheet;
    pnlChatConfig: TPanel;
    lblToken: TLabel;
    edToken: TEdit;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblModel: TLabel;
    cbModel: TComboBox;
    lblMaxTokens: TLabel;
    edMaxTokens: TEdit;
    meChatConversation: TMemo;
    pnlChatInput: TPanel;
    edChatAsk: TEdit;
    btnChatSend: TButton;

    // Tab 2: Neural Network Dashboard
    tabNeural: TTabSheet;
    pnlNeuralConfig: TPanel;
    btnTrainNeural: TButton;
    btnPredictNeural: TButton;
    lblActType: TLabel;
    cbActivation: TComboBox;
    lblLoss: TLabel;
    edLossResult: TEdit;
    meNeuralLogs: TMemo;
    pnlNeuralInfer: TPanel;
    lblInputVal1: TLabel;
    edInput1: TEdit;
    lblInputVal2: TLabel;
    edInput2: TEdit;
    lblInferResult: TLabel;
    edPredictResult: TEdit;

    // Tab 3: Code Assistant Panel
    tabAssistant: TTabSheet;
    pnlAssistantActions: TPanel;
    btnOptimize: TButton;
    btnFindBugs: TButton;
    btnDocument: TButton;
    btnExplain: TButton;
    lblAssistInstructions: TLabel;
    meOriginalCode: TMemo;
    Splitter1: TSplitter;
    meGeneratedCode: TMemo;

    // Tab 4: Dataset Generator Table
    tabDataset: TTabSheet;
    pnlDatasetActions: TPanel;
    btnAddRow: TButton;
    btnSaveJSONL: TButton;
    btnSaveCSV: TButton;
    btnLoadCSVToNeural: TButton;
    btnClearDataset: TButton;
    gridDataset: TStringGrid;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure btnChatSendClick(Sender: TObject);
    procedure edChatAskKeyPress(Sender: TObject; var Key: char);
    procedure btnTrainNeuralClick(Sender: TObject);
    procedure btnPredictNeuralClick(Sender: TObject);
    procedure btnOptimizeClick(Sender: TObject);
    procedure btnFindBugsClick(Sender: TObject);
    procedure btnDocumentClick(Sender: TObject);
    procedure btnExplainClick(Sender: TObject);
    procedure btnAddRowClick(Sender: TObject);
    procedure btnSaveJSONLClick(Sender: TObject);
    procedure btnSaveCSVClick(Sender: TObject);
    procedure btnClearDatasetClick(Sender: TObject);
    procedure btnLoadCSVToNeuralClick(Sender: TObject);
  private
    FChatgpt: TCHATGPT;
    FNeuralNet: TNeuralNetwork;
    FAssistant: TAICodeAssistant;
    FDatasetGen: TAIDatasetGenerator;

    procedure SyncChatGPTConfig;
  public

  end;

var
  frmVisualDemo: TfrmVisualDemo;

implementation

{$R *.lfm}

{ TfrmVisualDemo }

procedure TfrmVisualDemo.FormCreate(Sender: TObject);
begin
  // Instancia todos os 4 componentes da suíte
  FChatgpt := TCHATGPT.Create(Self);
  FNeuralNet := TNeuralNetwork.Create(Self);
  FAssistant := TAICodeAssistant.Create(Self);
  FDatasetGen := TAIDatasetGenerator.Create(Self);

  // Vincula o assistente de código ao conector central
  FAssistant.ChatGPT := FChatgpt;

  // Preenche provedores de IA
  cbProvider.Items.Clear;
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('OpenRouter');
  cbProvider.Items.Add('Cerebras');
  cbProvider.Items.Add('Local/Ollama');
  cbProvider.Items.Add('Gemini');
  cbProvider.Items.Add('Claude');
  cbProvider.ItemIndex := 0;
  cbProviderChange(nil);

  // Inicializa Grid de dataset
  gridDataset.Cells[0, 0] := 'ID';
  gridDataset.Cells[1, 0] := 'Entrada (Prompt)';
  gridDataset.Cells[2, 0] := 'Saída Esperada (Completion)';
  gridDataset.ColWidths[0] := 50;
  gridDataset.ColWidths[1] := 350;
  gridDataset.ColWidths[2] := 450;
end;

procedure TfrmVisualDemo.FormDestroy(Sender: TObject);
begin
  // Como passamos Self no Create, o formulário os destrói automaticamente.
end;

procedure TfrmVisualDemo.cbProviderChange(Sender: TObject);
begin
  cbModel.Items.Clear;
  case cbProvider.ItemIndex of
    0: // OpenAI
    begin
      cbModel.Items.Add('gpt-4o');
      cbModel.Items.Add('o3-mini');
      cbModel.Items.Add('gpt-4-turbo-preview');
      cbModel.Items.Add('gpt-3.5-turbo');
      cbModel.ItemIndex := 0;
    end;
    1: // OpenRouter
    begin
      cbModel.Items.Add('google/gemma-2-9b-it:free');
      cbModel.ItemIndex := 0;
    end;
    2: // Cerebras
    begin
      cbModel.Items.Add('qwen-3-235b-a22b-instruct-2507');
      cbModel.ItemIndex := 0;
    end;
    3: // Ollama
    begin
      cbModel.Items.Add('deepseek-r1:8b');
      cbModel.Items.Add('llama3.2:3b');
      cbModel.ItemIndex := 0;
    end;
    4: // Gemini
    begin
      cbModel.Items.Add('gemini-2.5-flash');
      cbModel.Items.Add('gemini-2.5-pro');
      cbModel.ItemIndex := 0;
    end;
    5: // Claude
    begin
      cbModel.Items.Add('claude-3-5-sonnet-20241022');
      cbModel.Items.Add('claude-3-5-haiku-20241022');
      cbModel.ItemIndex := 0;
    end;
  end;
end;

procedure TfrmVisualDemo.SyncChatGPTConfig;
var
  SelModelText: string;
begin
  FChatgpt.TOKEN := Trim(edToken.Text);
  FChatgpt.MaxTokens := StrToIntDef(edMaxTokens.Text, 4096);

  case cbProvider.ItemIndex of
    0: FChatgpt.Provider := AIP_OPENAI;
    1: FChatgpt.Provider := AIP_OPENROUTER;
    2: FChatgpt.Provider := AIP_CEREBRAS;
    3: FChatgpt.Provider := AIP_LOCAL;
    4: FChatgpt.Provider := AIP_GEMINI;
    5: FChatgpt.Provider := AIP_CLAUDE;
  end;

  SelModelText := cbModel.Text;
  if FChatgpt.Provider = AIP_OPENAI then
  begin
    if SelModelText = 'gpt-4o' then FChatgpt.TipoChat := VCT_GPT4o
    else if SelModelText = 'o3-mini' then FChatgpt.TipoChat := VCT_GPTo3_mini
    else if SelModelText = 'gpt-4-turbo-preview' then FChatgpt.TipoChat := VCT_GPT40_TURBO
    else FChatgpt.TipoChat := VCT_GPT35TURBO;
  end
  else if FChatgpt.Provider = AIP_LOCAL then
  begin
    if SelModelText = 'deepseek-r1:8b' then FChatgpt.TipoChat := VCT_DEEPSEEK_R1_8B
    else FChatgpt.TipoChat := VCT_LLAMA32_3B;
  end
  else if FChatgpt.Provider = AIP_GEMINI then
  begin
    if SelModelText = 'gemini-2.5-pro' then FChatgpt.TipoChat := VCT_GEMINI_25_PRO
    else FChatgpt.TipoChat := VCT_GEMINI_25_FLASH;
  end
  else if FChatgpt.Provider = AIP_CLAUDE then
  begin
    if SelModelText = 'claude-3-5-haiku-20241022' then FChatgpt.TipoChat := VCT_CLAUDE_35_HAIKU
    else FChatgpt.TipoChat := VCT_CLAUDE_35_SONNET;
  end;
end;

procedure TfrmVisualDemo.btnChatSendClick(Sender: TObject);
begin
  if Trim(edChatAsk.Text) = '' then
    Exit;

  SyncChatGPTConfig;
  meChatConversation.Lines.Append('>>> Você: ' + edChatAsk.Text);
  
  if FChatgpt.SendQuestion(edChatAsk.Text) then
    meChatConversation.Lines.Append('>>> IA: ' + FChatgpt.Response)
  else
    meChatConversation.Lines.Append('>>> ERRO: ' + FChatgpt.Response);
  
  meChatConversation.Lines.Append('');
  edChatAsk.Text := '';
end;

procedure TfrmVisualDemo.edChatAskKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    btnChatSendClick(nil);
    Key := #0;
  end;
end;

procedure TfrmVisualDemo.btnTrainNeuralClick(Sender: TObject);
var
  Inputs, Targets: TMatrix;
  Loss: Double;
begin
  meNeuralLogs.Lines.Append('Inicializando Rede Neural (2 entradas, 4 ocultos, 1 saída)...');
  FNeuralNet.Initialize(2, 4, 1, 0.1);
  
  case cbActivation.ItemIndex of
    0: FNeuralNet.ActivationType := atSigmoid;
    1: FNeuralNet.ActivationType := atReLU;
    2: FNeuralNet.ActivationType := atTanh;
  end;

  // Cria Dataset XOR
  SetLength(Inputs, 4);
  SetLength(Inputs[0], 2); Inputs[0, 0] := 0; Inputs[0, 1] := 0;
  SetLength(Inputs[1], 2); Inputs[1, 0] := 0; Inputs[1, 1] := 1;
  SetLength(Inputs[2], 2); Inputs[2, 0] := 1; Inputs[2, 1] := 0;
  SetLength(Inputs[3], 2); Inputs[3, 0] := 1; Inputs[3, 1] := 1;

  SetLength(Targets, 4);
  SetLength(Targets[0], 1); Targets[0, 0] := 0;
  SetLength(Targets[1], 1); Targets[1, 0] := 1;
  SetLength(Targets[2], 1); Targets[2, 0] := 1;
  SetLength(Targets[3], 1); Targets[3, 0] := 0;

  meNeuralLogs.Lines.Append('Iniciando 5000 épocas de treinamento local...');
  FNeuralNet.TrainEpochs(Inputs, Targets, 5000, Loss);
  
  edLossResult.Text := Format('%0.6f', [Loss]);
  meNeuralLogs.Lines.Append(Format('Treino concluído com MSE Loss: %0.6f', [Loss]));
  meNeuralLogs.Lines.Append('Rede Neural pronta para predições!');
  meNeuralLogs.Lines.Append('');
end;

procedure TfrmVisualDemo.btnPredictNeuralClick(Sender: TObject);
var
  InArr, OutArr: TArray;
begin
  SetLength(InArr, 2);
  InArr[0] := StrToFloatDef(edInput1.Text, 0.0);
  InArr[1] := StrToFloatDef(edInput2.Text, 0.0);

  try
    OutArr := FNeuralNet.Predict(InArr);
    edPredictResult.Text := Format('%0.4f', [OutArr[0]]);
  except
    on E: Exception do
      ShowMessage('Erro na predição: ' + E.Message);
  end;
end;

procedure TfrmVisualDemo.btnOptimizeClick(Sender: TObject);
begin
  if Trim(meOriginalCode.Text) = '' then Exit;
  SyncChatGPTConfig;
  meGeneratedCode.Text := 'Processando Otimização estrutural... Por favor aguarde.';
  Application.ProcessMessages;
  meGeneratedCode.Text := FAssistant.OptimizeCode(meOriginalCode.Text);
end;

procedure TfrmVisualDemo.btnFindBugsClick(Sender: TObject);
begin
  if Trim(meOriginalCode.Text) = '' then Exit;
  SyncChatGPTConfig;
  meGeneratedCode.Text := 'Buscando erros lógicos e falhas... Por favor aguarde.';
  Application.ProcessMessages;
  meGeneratedCode.Text := FAssistant.FindBugs(meOriginalCode.Text);
end;

procedure TfrmVisualDemo.btnDocumentClick(Sender: TObject);
begin
  if Trim(meOriginalCode.Text) = '' then Exit;
  SyncChatGPTConfig;
  meGeneratedCode.Text := 'Escrevendo comentários e documentando... Por favor aguarde.';
  Application.ProcessMessages;
  meGeneratedCode.Text := FAssistant.DocumentCode(meOriginalCode.Text);
end;

procedure TfrmVisualDemo.btnExplainClick(Sender: TObject);
begin
  if Trim(meOriginalCode.Text) = '' then Exit;
  SyncChatGPTConfig;
  meGeneratedCode.Text := 'Solicitando explicação algorítmica... Por favor aguarde.';
  Application.ProcessMessages;
  meGeneratedCode.Text := FAssistant.ExplainCode(meOriginalCode.Text);
end;

procedure TfrmVisualDemo.btnAddRowClick(Sender: TObject);
var
  InputVal, OutputVal: string;
  R: Integer;
begin
  InputVal := InputBox('Dataset Input', 'Digite o prompt de entrada:', '');
  if InputVal = '' then Exit;
  OutputVal := InputBox('Dataset Output', 'Digite a resposta esperada (completion):', '');
  if OutputVal = '' then Exit;

  FDatasetGen.AddDataRow(InputVal, OutputVal);
  
  R := gridDataset.RowCount;
  gridDataset.RowCount := R + 1;
  gridDataset.Cells[0, R] := IntToStr(R);
  gridDataset.Cells[1, R] := InputVal;
  gridDataset.Cells[2, R] := OutputVal;
end;

procedure TfrmVisualDemo.btnSaveJSONLClick(Sender: TObject);
var
  SD: TSaveDialog;
begin
  if FDatasetGen.Count = 0 then
  begin
    ShowMessage('Adicione linhas ao dataset antes de exportar.');
    Exit;
  end;

  SD := TSaveDialog.Create(Self);
  try
    SD.Filter := 'Arquivo JSONL (*.jsonl)|*.jsonl';
    SD.DefaultExt := 'jsonl';
    if SD.Execute then
    begin
      FDatasetGen.SaveAsJSONL(SD.FileName);
      ShowMessage('Dataset exportado com sucesso no formato JSONL!');
    end;
  finally
    SD.Free;
  end;
end;

procedure TfrmVisualDemo.btnSaveCSVClick(Sender: TObject);
var
  SD: TSaveDialog;
begin
  if FDatasetGen.Count = 0 then
  begin
    ShowMessage('Adicione linhas ao dataset antes de exportar.');
    Exit;
  end;

  SD := TSaveDialog.Create(Self);
  try
    SD.Filter := 'Arquivo CSV (*.csv)|*.csv';
    SD.DefaultExt := 'csv';
    if SD.Execute then
    begin
      FDatasetGen.SaveAsCSV(SD.FileName);
      ShowMessage('Dataset exportado com sucesso no formato CSV!');
    end;
  finally
    SD.Free;
  end;
end;

procedure TfrmVisualDemo.btnClearDatasetClick(Sender: TObject);
begin
  FDatasetGen.Clear;
  gridDataset.RowCount := 2;
  gridDataset.Cells[1, 1] := '';
  gridDataset.Cells[2, 1] := '';
  gridDataset.RowCount := 2;
end;

procedure TfrmVisualDemo.btnLoadCSVToNeuralClick(Sender: TObject);
var
  OD: TOpenDialog;
  InMat, TargetMat: TMatrix;
  L: Double;
  i: Integer;
begin
  OD := TOpenDialog.Create(Self);
  try
    OD.Filter := 'Planilha CSV (*.csv)|*.csv';
    if OD.Execute then
    begin
      // Carrega um CSV com 2 entradas e 1 saída (ex: xor tabular)
      try
        FDatasetGen.LoadFromCSV(OD.FileName, InMat, TargetMat, 2, 1);
        
        meNeuralLogs.Lines.Append(Format('Carga de CSV concluída! %d amostras prontas.', [Length(InMat)]));
        FNeuralNet.Initialize(2, 4, 1, 0.1);
        FNeuralNet.TrainEpochs(InMat, TargetMat, 2000, L);
        
        edLossResult.Text := Format('%0.6f', [L]);
        meNeuralLogs.Lines.Append(Format('Treinamento via CSV completado com MSE Loss: %0.6f', [L]));
        
        // Copia dados de teste do primeiro registro para a tela
        if Length(InMat) > 0 then
        begin
          edInput1.Text := Format('%0.0f', [InMat[0, 0]]);
          edInput2.Text := Format('%0.0f', [InMat[0, 1]]);
        end;
      except
        on E: Exception do
          ShowMessage('Falha ao processar CSV: ' + E.Message);
      end;
    end;
  finally
    OD.Free;
  end;
end;

end.
