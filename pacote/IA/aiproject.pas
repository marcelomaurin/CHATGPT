unit aiproject;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, aiagent, aipipeline, fpjson, jsonparser, LResources, aibase;

type
  TAIErrorEvent = procedure(Sender: TObject; const AError: string) of object;

  { TAIProject }

  TAIProject = class(TAIBaseComponent)
  private
    FProjectName: string;
    FDescription: string;
    FChatGPT: TCHATGPT;
    FAgent: TAIAgent;
    FPipeline: TAIPipeline;
    FDefaultProvider: TAIProvider;
    FDefaultModel: string;
    FToken: string;
    FLocalURL: string;
    FSafeMode: Boolean;
    FSimulationMode: Boolean;
    FSaveToken: Boolean;
    FConfigFileName: string;
    FOnBeforeExecute: TNotifyEvent;
    FOnAfterExecute: TNotifyEvent;
    FOnError: TAIErrorEvent;
  protected
    procedure DoError(const AError: string);
  public
    constructor Create(AOwner: TComponent); override;
    
    function Initialize: Boolean;
    function TestConnection: Boolean;
    function ExecuteText(const AText: string): string;
    function Execute: Boolean;
    
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    function LoadConfig: Boolean;
    function SaveConfig: Boolean;
    function BuildSystemPrompt: string;
  published
    property ProjectName: string read FProjectName write FProjectName;
    property Description: string read FDescription write FDescription;
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property Agent: TAIAgent read FAgent write FAgent;
    property Pipeline: TAIPipeline read FPipeline write FPipeline;
    property DefaultProvider: TAIProvider read FDefaultProvider write FDefaultProvider default AIP_OPENAI;
    property DefaultModel: string read FDefaultModel write FDefaultModel;
    property Token: string read FToken write FToken;
    property LocalURL: string read FLocalURL write FLocalURL;
    property SafeMode: Boolean read FSafeMode write FSafeMode default False;
    property SimulationMode: Boolean read FSimulationMode write FSimulationMode default False;
    property SaveToken: Boolean read FSaveToken write FSaveToken default False;
    property ConfigFileName: string read FConfigFileName write FConfigFileName;
    property OnBeforeExecute: TNotifyEvent read FOnBeforeExecute write FOnBeforeExecute;
    property OnAfterExecute: TNotifyEvent read FOnAfterExecute write FOnAfterExecute;
    property OnError: TAIErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Project', [TAIProject]);
end;

constructor TAIProject.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccProject;
  FPrompt := 'Component TAIProject coordinates the entire AI Project structure. Properties: ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode. Methods: Initialize: Boolean, TestConnection: Boolean, ExecuteText(const AText: string): string, Execute: Boolean, LoadFromFile(const AFileName: string), SaveToFile(const AFileName: string), BuildSystemPrompt: string. AI Agent: Use this as the main project configuration coordinator.';
  FDefaultProvider := AIP_OPENAI;
  FSafeMode := False;
  FSimulationMode := False;
  FSaveToken := False;
  FConfigFileName := '';
  FProjectName := 'New AI Project';
  FDescription := '';
  FDefaultModel := '';
  FToken := '';
  FLocalURL := '';
end;

procedure TAIProject.DoError(const AError: string);
begin
  SetError(AError);
  if Assigned(FOnError) then
    FOnError(Self, AError);
end;

function TAIProject.Initialize: Boolean;
begin
  Result := True;
  ClearError;
  Log(llInfo, 'Initializing TAIProject: ' + FProjectName);
  
  if Assigned(FChatGPT) then
  begin
    FChatGPT.Provider := FDefaultProvider;
    if FDefaultModel <> '' then
      FChatGPT.CustomModel := FDefaultModel;
    if FToken <> '' then
      FChatGPT.TOKEN := FToken;
    if FLocalURL <> '' then
      FChatGPT.LocalIP := FLocalURL;
  end;
  
  if Assigned(FAgent) and (FToken <> '') and Assigned(FAgent.ChatGPT) then
  begin
    FAgent.ChatGPT.Provider := FDefaultProvider;
    if FDefaultModel <> '' then
      FAgent.ChatGPT.CustomModel := FDefaultModel;
    if FToken <> '' then
      FAgent.ChatGPT.TOKEN := FToken;
    if FLocalURL <> '' then
      FAgent.ChatGPT.LocalIP := FLocalURL;
  end;

  // Propagate SafeMode and SimulationMode to Agent Safety
  if Assigned(FAgent) and Assigned(FAgent.Safety) then
  begin
    FAgent.Safety.SimulationMode := FSimulationMode;
    Log(llDebug, 'Propagated SimulationMode=' + BoolToStr(FSimulationMode, True) + ' to agent safety.');
    if FSafeMode then
    begin
      FAgent.Safety.Enabled := True;
      FAgent.Safety.ReadOnlyMode := True;
      FAgent.Safety.AllowFileWrite := False;
      FAgent.Safety.AllowNetwork := False;
      FAgent.Safety.AllowIndustrialWrite := False;
      FAgent.Safety.AllowEmailSend := False;
      Log(llInfo, 'SafeMode is active: Propagated safety constraints to Agent Safety.');
    end;
  end;
end;

function TAIProject.TestConnection: Boolean;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Testing connection for TAIProject...');
  
  if FSimulationMode then
  begin
    FLastResult := 'Simulated: Connection Succeeded.';
    Log(llInfo, 'TestConnection simulated successfully.');
    Result := True;
    Exit;
  end;
  
  Initialize;
  if not Assigned(FChatGPT) then
  begin
    DoError('Component TCHATGPT is not connected.');
    Exit;
  end;
  
  Result := FChatGPT.SendQuestion('Respond strictly with "OK" if you receive this message.');
  if Result then
  begin
    FLastResult := FChatGPT.Response;
    Log(llInfo, 'TestConnection succeeded: ' + FLastResult);
  end
  else
  begin
    DoError(FChatGPT.Response);
  end;
end;

function TAIProject.ExecuteText(const AText: string): string;
begin
  Result := '';
  ClearError;
  Log(llInfo, 'Executing custom prompt: ' + AText);
  
  if FSimulationMode then
  begin
    FLastResult := 'Simulated response for: ' + AText;
    Result := FLastResult;
    Log(llInfo, 'ExecuteText simulated: ' + FLastResult);
    Exit;
  end;
  
  Initialize;
  if not Assigned(FChatGPT) then
  begin
    DoError('Component TCHATGPT is not connected.');
    Exit;
  end;
  
  if FChatGPT.SendQuestion(AText) then
  begin
    FLastResult := FChatGPT.Response;
    Result := FLastResult;
    Log(llInfo, 'ExecuteText completed successfully.');
  end
  else
  begin
    DoError(FChatGPT.Response);
    Result := 'ERROR';
  end;
end;

function TAIProject.Execute: Boolean;
begin
  Result := False;
  ClearError;
  FLastResult := '';
  Log(llInfo, 'Starting TAIProject.Execute execution cycle.');
  
  if Assigned(FOnBeforeExecute) then
    FOnBeforeExecute(Self);
    
  if FSimulationMode then
  begin
    FLastResult := 'Simulated Execute Succeeded.';
    Result := True;
    Log(llInfo, 'Execute execution cycle simulated successfully.');
    if Assigned(FOnAfterExecute) then
      FOnAfterExecute(Self);
    Exit;
  end;
  
  Initialize;
  
  if Assigned(FPipeline) then
  begin
    Log(llInfo, 'Executing pipeline.');
    Result := FPipeline.Run;
    if Result then
    begin
      FLastResult := FPipeline.LastResult;
      Log(llInfo, 'Pipeline run completed successfully.');
    end
    else
      DoError(FPipeline.LastError);
  end
  else if Assigned(FAgent) then
  begin
    Log(llInfo, 'Executing agent.');
    Result := FAgent.Execute('Analyze state and perform actions.');
    if Result then
    begin
      FLastResult := 'Agent run successfully.';
      Log(llInfo, 'Agent execution completed successfully.');
    end
    else
      DoError(FAgent.LastError);
  end
  else
  begin
    DoError('No Pipeline or Agent is connected to this project.');
  end;
  
  if Assigned(FOnAfterExecute) then
    FOnAfterExecute(Self);
end;

function TAIProject.BuildSystemPrompt: string;
begin
  Log(llDebug, 'Building system prompt.');
  Result := 'Project: ' + FProjectName + sLineBreak;
  if FDescription <> '' then
    Result := Result + 'Description: ' + FDescription + sLineBreak;
  if FSafeMode then
    Result := Result + 'Safety constraints: SAFE MODE is ACTIVE. Do not execute destructive actions.' + sLineBreak;
    
  if Assigned(FAgent) then
    Result := Result + 'Agent Instructions: ' + FAgent.SystemPrompt + sLineBreak;
end;

procedure TAIProject.LoadFromFile(const AFileName: string);
var
  LList: TStringList;
  LData: TJSONData;
  LObj: TJSONObject;
  LVal: string;
begin
  Log(llInfo, 'Loading config from file: ' + AFileName);
  if not FileExists(AFileName) then
    raise Exception.CreateFmt('File %s does not exist.', [AFileName]);
    
  LList := TStringList.Create;
  try
    LList.LoadFromFile(AFileName);
    LVal := LList.Text;
    LData := GetJSON(LVal);
    try
      if LData.JSONType = jtObject then
      begin
        LObj := TJSONObject(LData);
        if LObj.IndexOfName('ProjectName') >= 0 then
          FProjectName := LObj.Strings['ProjectName'];
        if LObj.IndexOfName('Description') >= 0 then
          FDescription := LObj.Strings['Description'];
        if LObj.IndexOfName('DefaultModel') >= 0 then
          FDefaultModel := LObj.Strings['DefaultModel'];
        if LObj.IndexOfName('Token') >= 0 then
          FToken := LObj.Strings['Token'];
        if LObj.IndexOfName('LocalURL') >= 0 then
          FLocalURL := LObj.Strings['LocalURL'];
        if LObj.IndexOfName('SafeMode') >= 0 then
          FSafeMode := LObj.Booleans['SafeMode'];
        if LObj.IndexOfName('SimulationMode') >= 0 then
          FSimulationMode := LObj.Booleans['SimulationMode'];
        Log(llInfo, 'Config loaded successfully.');
      end;
    finally
      LData.Free;
    end;
  finally
    LList.Free;
  end;
end;

procedure TAIProject.SaveToFile(const AFileName: string);
var
  LObj: TJSONObject;
  LList: TStringList;
begin
  Log(llInfo, 'Saving config to file: ' + AFileName);
  LObj := TJSONObject.Create;
  LList := TStringList.Create;
  try
    LObj.Add('ProjectName', FProjectName);
    LObj.Add('Description', FDescription);
    LObj.Add('DefaultModel', FDefaultModel);
    if FSaveToken then
    begin
      LObj.Add('Token', FToken);
      Log(llWarning, 'SaveToken is enabled: Saving API token/key to file.');
    end;
    LObj.Add('LocalURL', FLocalURL);
    LObj.Add('SafeMode', FSafeMode);
    LObj.Add('SimulationMode', FSimulationMode);
    
    LList.Text := LObj.AsJSON;
    LList.SaveToFile(AFileName);
    Log(llInfo, 'Config saved successfully.');
  finally
    LObj.Free;
    LList.Free;
  end;
end;

function TAIProject.LoadConfig: Boolean;
begin
  Result := False;
  if FConfigFileName = '' then
  begin
    DoError('ConfigFileName is empty.');
    Exit;
  end;
  try
    LoadFromFile(FConfigFileName);
    Result := True;
  except
    on E: Exception do
      DoError('LoadConfig failed: ' + E.Message);
  end;
end;

function TAIProject.SaveConfig: Boolean;
begin
  Result := False;
  if FConfigFileName = '' then
  begin
    DoError('ConfigFileName is empty.');
    Exit;
  end;
  try
    SaveToFile(FConfigFileName);
    Result := True;
  except
    on E: Exception do
      DoError('SaveConfig failed: ' + E.Message);
  end;
end;

initialization
  {$I aiproject_icon.lrs}

end.
