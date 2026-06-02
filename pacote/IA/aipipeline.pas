unit aipipeline;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, NeuralNetwork, aiagent, aiinput, aioutput, aioutput_docs, LResources;

type
  TAIPipelineMode = (
    pmTextLLM,
    pmNumericML,
    pmAgentAction,
    pmDocumentGeneration,
    pmIndustrialMonitor
  );

  { TAIPipeline }

  TAIPipeline = class(TComponent)
  private
    FPrompt: string;
    FMode: TAIPipelineMode;
    FChatGPT: TCHATGPT;
    FNeuralNetwork: TNeuralNetwork;
    FAgent: TAIAgent;
    FInputData: TAIInputData;
    FOutputData: TAIOutputData;
    FOutputDocs: TAIOutputDocs;
    FInputText: string;
    FOutputText: string;
    FAutoNormalize: Boolean;
    FAutoSoftMax: Boolean;
    FLastError: string;
    FLastResult: string;
  public
    constructor Create(AOwner: TComponent); override;
    
    function Run: Boolean;
    function RunText(const AText: string): string;
    function RunNumeric: Boolean;
    function RunAgent(const AInput: string): Boolean;
    function RunDocument(const AText: string): Boolean;
    function RunIndustrialMonitor: Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Mode: TAIPipelineMode read FMode write FMode default pmTextLLM;
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property NeuralNetwork: TNeuralNetwork read FNeuralNetwork write FNeuralNetwork;
    property Agent: TAIAgent read FAgent write FAgent;
    property InputData: TAIInputData read FInputData write FInputData;
    property OutputData: TAIOutputData read FOutputData write FOutputData;
    property OutputDocs: TAIOutputDocs read FOutputDocs write FOutputDocs;
    property InputText: string read FInputText write FInputText;
    property OutputText: string read FOutputText write FOutputText;
    property AutoNormalize: Boolean read FAutoNormalize write FAutoNormalize default True;
    property AutoSoftMax: Boolean read FAutoSoftMax write FAutoSoftMax default True;
    property LastError: string read FLastError write FLastError;
    property LastResult: string read FLastResult write FLastResult;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Project', [TAIPipeline]);
end;

constructor TAIPipeline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIPipeline integrates Input, AI models, and Output. Mode: pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor. Properties: ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax. Methods: Run: Boolean, RunText(const AText: string): string, RunNumeric: Boolean, RunAgent(const AInput: string): Boolean, RunDocument(const AText: string): Boolean. AI Agent: Use this component to execute structured pipelines linking perception, decision, and document generation.';
  FMode := pmTextLLM;
  FAutoNormalize := True;
  FAutoSoftMax := True;
  FLastError := '';
  FLastResult := '';
  FInputText := '';
  FOutputText := '';
end;

function TAIPipeline.Run: Boolean;
begin
  Result := False;
  FLastError := '';
  FLastResult := '';
  FOutputText := '';
  
  case FMode of
    pmTextLLM:
      begin
        if not Assigned(FChatGPT) then
        begin
          FLastError := 'Component TCHATGPT is not connected.';
          Exit;
        end;
        Result := FChatGPT.SendQuestion(FInputText);
        if Result then
        begin
          FOutputText := FChatGPT.Response;
          FLastResult := FOutputText;
        end
        else
          FLastError := FChatGPT.Response;
      end;
      
    pmNumericML:
      Result := RunNumeric;
      
    pmAgentAction:
      Result := RunAgent(FInputText);
      
    pmDocumentGeneration:
      Result := RunDocument(FInputText);
      
    pmIndustrialMonitor:
      Result := RunIndustrialMonitor;
  end;
end;

function TAIPipeline.RunText(const AText: string): string;
begin
  FInputText := AText;
  FMode := pmTextLLM;
  if Run then
    Result := FOutputText
  else
    Result := 'ERROR: ' + FLastError;
end;

function TAIPipeline.RunNumeric: Boolean;
var
  InArr: NeuralNetwork.TArray;
  OutArr: NeuralNetwork.TArray;
  OutProb: aioutput.TArray;
  I: Integer;
begin
  Result := False;
  if not Assigned(FInputData) then
  begin
    FLastError := 'Component TAIInputData is not connected.';
    Exit;
  end;
  if not Assigned(FNeuralNetwork) then
  begin
    FLastError := 'Component TNeuralNetwork is not connected.';
    Exit;
  end;
  if not Assigned(FOutputData) then
  begin
    FLastError := 'Component TAIOutputData is not connected.';
    Exit;
  end;
  
  try
    if FAutoNormalize then
      FInputData.Normalize;
      
    SetLength(InArr, FInputData.GetLength);
    if FAutoNormalize then
    begin
      for I := 0 to FInputData.GetLength - 1 do
        InArr[I] := FInputData.NormalizedData[I];
    end
    else
    begin
      for I := 0 to FInputData.GetLength - 1 do
        InArr[I] := FInputData.RawData[I];
    end;
      
    OutArr := FNeuralNetwork.Predict(InArr);
    
    // Set OutputData probabilities
    SetLength(OutProb, Length(OutArr));
    for I := 0 to High(OutArr) do
      OutProb[I] := OutArr[I];
    FOutputData.Probabilities := OutProb;
      
    if FAutoSoftMax then
      FOutputData.SoftMax;
      
    FOutputData.UpdateResult;
    FLastResult := FOutputData.ClassificationResult;
    FOutputText := FLastResult;
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := False;
    end;
  end;
end;

function TAIPipeline.RunAgent(const AInput: string): Boolean;
begin
  Result := False;
  if not Assigned(FAgent) then
  begin
    FLastError := 'Component TAIAgent is not connected.';
    Exit;
  end;
  
  FInputText := AInput;
  Result := FAgent.Execute(AInput);
  if Result then
  begin
    FLastResult := 'Action: ' + FAgent.Action.SelectedAction + ' | Rationale: ' + FAgent.LastRationale;
    FOutputText := FLastResult;
  end
  else
    FLastError := FAgent.LastError;
end;

function TAIPipeline.RunDocument(const AText: string): Boolean;
begin
  Result := False;
  if not Assigned(FOutputDocs) then
  begin
    FLastError := 'Component TAIOutputDocs is not connected.';
    Exit;
  end;
  
  FInputText := AText;
  try
    FOutputDocs.Clear;
    FOutputDocs.AddHeading('Pipeline Document Report', 1);
    FOutputDocs.AddParagraph('Generated on: ' + DateTimeToStr(Now));
    FOutputDocs.AddParagraph(AText);
    
    Result := FOutputDocs.SaveAll('relatorio_pipeline');
    if Result then
    begin
      FLastResult := 'Documents generated successfully.';
      FOutputText := FLastResult;
    end
    else
      FLastError := 'Failed to generate all document formats.';
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := False;
    end;
  end;
end;

function TAIPipeline.RunIndustrialMonitor: Boolean;
var
  PromptStr: string;
  I: Integer;
begin
  Result := False;
  if not Assigned(FChatGPT) then
  begin
    FLastError := 'Component TCHATGPT is not connected.';
    Exit;
  end;
  if not Assigned(FInputData) then
  begin
    FLastError := 'Component TAIInputData is not connected.';
    Exit;
  end;
  
  try
    // Format input data array for prompt evaluation
    PromptStr := 'Determine if the following sensor telemetries indicate an anomaly, error, or critical state. Raw values: ';
    if Length(FInputData.RawData) > 0 then
    begin
      for I := 0 to High(FInputData.RawData) do
      begin
        if I > 0 then PromptStr := PromptStr + ', ';
        PromptStr := PromptStr + FloatToStr(FInputData.RawData[I]);
      end;
    end
    else
      PromptStr := PromptStr + '[]';
      
    // Send to ChatGPT
    Result := FChatGPT.SendQuestion(PromptStr);
    if Result then
    begin
      FOutputText := FChatGPT.Response;
      FLastResult := FOutputText;
    end
    else
      FLastError := FChatGPT.Response;
  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := False;
    end;
  end;
end;

initialization
  {$I aipipeline_icon.lrs}

end.
