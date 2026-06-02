unit aipipeline;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, NeuralNetwork, aiagent, aiinput, aioutput, aioutput_docs, LResources,
  aibase, aimodbus, aimqtt, aiindustrial, aigraphmap;

type
  TAIPipelineMode = (
    pmTextLLM,
    pmNumericML,
    pmAgentAction,
    pmDocumentGeneration,
    pmIndustrialMonitor,
    pmGraphMapClassification
  );

  { TAIPipeline }

  TAIPipeline = class(TAIBaseComponent)
  private
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
    FBaseFileName: string;
    FDocumentTitle: string;
    FDocumentAuthor: string;
    FDocumentSubject: string;
    FSavePDF: Boolean;
    FSaveWord: Boolean;
    FSaveExcel: Boolean;
    FSaveTXT: Boolean;
    FIndustrialInput: TComponent;
    FGraphMap: TAIGraphMap;
  public
    constructor Create(AOwner: TComponent); override;
    
    function Run: Boolean;
    function RunText(const AText: string): string;
    function RunNumeric: Boolean;
    function RunAgent(const AInput: string): Boolean;
    function RunDocument(const AText: string): Boolean;
    function RunIndustrialMonitor: Boolean;
    function RunGraphMapClassification: Boolean;
  published
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
    property BaseFileName: string read FBaseFileName write FBaseFileName;
    property DocumentTitle: string read FDocumentTitle write FDocumentTitle;
    property DocumentAuthor: string read FDocumentAuthor write FDocumentAuthor;
    property DocumentSubject: string read FDocumentSubject write FDocumentSubject;
    property SavePDF: Boolean read FSavePDF write FSavePDF default True;
    property SaveWord: Boolean read FSaveWord write FSaveWord default True;
    property SaveExcel: Boolean read FSaveExcel write FSaveExcel default True;
    property SaveTXT: Boolean read FSaveTXT write FSaveTXT default True;
    property IndustrialInput: TComponent read FIndustrialInput write FIndustrialInput;
    property GraphMap: TAIGraphMap read FGraphMap write FGraphMap;
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
  FCategory := ccOther;
  FPrompt := 'Component TAIPipeline integrates Input, AI models, and Output. Mode: pmTextLLM, pmNumericML, pmAgentAction, pmDocumentGeneration, pmIndustrialMonitor. Properties: ChatGPT, NeuralNetwork, Agent, InputData, OutputData, OutputDocs, InputText, OutputText, AutoNormalize, AutoSoftMax. Methods: Run: Boolean, RunText(const AText: string): string, RunNumeric: Boolean, RunAgent(const AInput: string): Boolean, RunDocument(const AText: string): Boolean. AI Agent: Use this component to execute structured pipelines linking perception, decision, and document generation.';
  FMode := pmTextLLM;
  FAutoNormalize := True;
  FAutoSoftMax := True;
  FInputText := '';
  FOutputText := '';
  FBaseFileName := '';
  FDocumentTitle := '';
  FDocumentAuthor := '';
  FDocumentSubject := '';
  FSavePDF := True;
  FSaveWord := True;
  FSaveExcel := True;
  FSaveTXT := True;
  FIndustrialInput := nil;
  FGraphMap := nil;
  ClearError;
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
      
    pmGraphMapClassification:
      Result := RunGraphMapClassification;
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
    if Assigned(FAgent.Action) then
      FLastResult := 'Action: ' + FAgent.Action.SelectedAction + ' | Rationale: ' + FAgent.LastRationale
    else
      FLastResult := 'Agent executed. Rationale: ' + FAgent.LastRationale;
    FOutputText := FLastResult;
  end
  else
    FLastError := FAgent.LastError;
end;

function TAIPipeline.RunDocument(const AText: string): Boolean;
var
  Base: string;
begin
  Result := False;
  if not Assigned(FOutputDocs) then
  begin
    FLastError := 'Component TAIOutputDocs is not connected.';
    Exit;
  end;
  
  FInputText := AText;
  try
    if FDocumentTitle <> '' then
      FOutputDocs.Title := FDocumentTitle
    else
      FOutputDocs.Title := 'Pipeline Document Report';

    if FDocumentAuthor <> '' then
      FOutputDocs.Author := FDocumentAuthor;

    if FDocumentSubject <> '' then
      FOutputDocs.Subject := FDocumentSubject;

    FOutputDocs.Clear;
    FOutputDocs.AddHeading(FOutputDocs.Title, 1);
    FOutputDocs.AddParagraph('Generated on: ' + DateTimeToStr(Now));
    FOutputDocs.AddParagraph(AText);
    
    if FBaseFileName = '' then
      FBaseFileName := 'relatorio_pipeline';
      
    Base := ChangeFileExt(FBaseFileName, '');
    FOutputDocs.FileNamePDF := Base + '.pdf';
    FOutputDocs.FileNameWord := Base + '.docx';
    FOutputDocs.FileNameExcel := Base + '.xlsx';
    FOutputDocs.FileNameTXT := Base + '.txt';

    Result := True;
    if FSavePDF then
      Result := Result and FOutputDocs.SaveToPDF;
    if FSaveWord then
      Result := Result and FOutputDocs.SaveToWord;
    if FSaveExcel then
      Result := Result and FOutputDocs.SaveToExcel;
    if FSaveTXT then
      Result := Result and FOutputDocs.SaveToTXT;
      
    if Result then
    begin
      FLastResult := 'Documents generated successfully.';
      FOutputText := FLastResult;
    end
    else
      FLastError := 'Failed to generate one or more document formats.';
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
  Modbus: TAIModbusClient;
  MQTT: TAIMQTTClient;
  Bridge: TAIIndustrialBridge;
  Regs: array[0..9] of Word;
  Bytes: array[0..9] of Byte;
begin
  Result := False;
  FLastError := '';
  FLastResult := '';
  
  if not Assigned(FChatGPT) then
  begin
    FLastError := 'Component TCHATGPT is not connected.';
    Exit;
  end;
  
  PromptStr := 'Determine if the following industrial telemetries indicate an anomaly, error, or critical state. Telemetry details: ';
  
  if Assigned(FIndustrialInput) then
  begin
    if FIndustrialInput is TAIModbusClient then
    begin
      Modbus := TAIModbusClient(FIndustrialInput);
      if Modbus.Connect then
      begin
        if Modbus.ReadHoldingRegisters(1, 0, 10, Regs) then
        begin
          PromptStr := PromptStr + 'Modbus TCP [Slave 1, Registers 0-9]: ';
          for I := 0 to 9 do
          begin
            if I > 0 then PromptStr := PromptStr + ', ';
            PromptStr := PromptStr + IntToStr(Regs[I]);
          end;
        end
        else
        begin
          FLastError := 'Modbus read holding registers failed: ' + Modbus.LastError;
          Exit;
        end;
      end
      else
      begin
        FLastError := 'Modbus connect failed: ' + Modbus.LastError;
        Exit;
      end;
    end
    else if FIndustrialInput is TAIMQTTClient then
    begin
      MQTT := TAIMQTTClient(FIndustrialInput);
      PromptStr := PromptStr + 'MQTT Topic: ' + MQTT.LastTopic + ' | Payload: ' + MQTT.LastPayload;
    end
    else if FIndustrialInput is TAIIndustrialBridge then
    begin
      Bridge := TAIIndustrialBridge(FIndustrialInput);
      if Bridge.ConnectBridge then
      begin
        if Bridge.ReadBytes(1, 0, 10, Bytes) then
        begin
          PromptStr := PromptStr + 'Siemens PLC Bridge [DB 1, Bytes 0-9]: ';
          for I := 0 to 9 do
          begin
            if I > 0 then PromptStr := PromptStr + ', ';
            PromptStr := PromptStr + IntToStr(Bytes[I]);
          end;
        end
        else
        begin
          FLastError := 'Industrial Bridge read bytes failed: ' + Bridge.LastError;
          Exit;
        end;
      end
      else
      begin
        FLastError := 'Industrial Bridge connection failed: ' + Bridge.LastError;
        Exit;
      end;
    end
    else
    begin
      FLastError := 'Unknown IndustrialInput component type: ' + FIndustrialInput.ClassName;
      Exit;
    end;
  end
  else
  begin
    // Fallback to FInputData.RawData if FIndustrialInput is not assigned
    if not Assigned(FInputData) then
    begin
      FLastError := 'No IndustrialInput or InputData assigned.';
      Exit;
    end;
    PromptStr := PromptStr + 'InputData RawValues: ';
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
  end;
  
  // Send to ChatGPT
  Result := FChatGPT.SendQuestion(PromptStr);
  if Result then
  begin
    FOutputText := FChatGPT.Response;
    FLastResult := FOutputText;
  end
  else
    FLastError := FChatGPT.Response;
end;

function TAIPipeline.RunGraphMapClassification: Boolean;
var
  LList: TStringList;
begin
  Result := False;
  if not Assigned(FGraphMap) then
  begin
    FLastError := 'Component TAIGraphMap is not connected.';
    Exit;
  end;
  
  LList := TStringList.Create;
  try
    FGraphMap.Predict(FInputText);
    FGraphMap.PredictRanking(FInputText, LList);
    FOutputText := LList.Text;
    FLastResult := FOutputText;
    Result := True;
  finally
    LList.Free;
  end;
end;

initialization
  {$I aipipeline_icon.lrs}

end.
