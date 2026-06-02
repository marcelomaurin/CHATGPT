unit aiproject;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, chatgpt, aiagent, aipipeline, fpjson, jsonparser;

type
  TAIErrorEvent = procedure(Sender: TObject; const AError: string) of object;

  { TAIProject }

  TAIProject = class(TComponent)
  private
    FPrompt: string;
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
    FLastError: string;
    FLastResult: string;
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
    function BuildSystemPrompt: string;
  published
    property Prompt: string read FPrompt write FPrompt;
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
    property LastError: string read FLastError write FLastError;
    property LastResult: string read FLastResult write FLastResult;
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
  FPrompt := 'Component TAIProject coordinates the entire AI Project structure. Properties: ProjectName, Description, ChatGPT, Agent, Pipeline, DefaultProvider, DefaultModel, Token, LocalURL, SafeMode, SimulationMode. Methods: Initialize: Boolean, TestConnection: Boolean, ExecuteText(const AText: string): string, Execute: Boolean, LoadFromFile(const AFileName: string), SaveToFile(const AFileName: string), BuildSystemPrompt: string. AI Agent: Use this as the main project configuration coordinator.';
  FDefaultProvider := AIP_OPENAI;
  FSafeMode := False;
  FSimulationMode := False;
  FProjectName := 'New AI Project';
  FDescription := '';
  FDefaultModel := '';
  FToken := '';
  FLocalURL := '';
end;

procedure TAIProject.DoError(const AError: string);
begin
  FLastError := AError;
  if Assigned(FOnError) then
    FOnError(Self, AError);
end;

function TAIProject.Initialize: Boolean;
begin
  Result := True;
  FLastError := '';
  
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
end;

function TAIProject.TestConnection: Boolean;
begin
  Result := False;
  FLastError := '';
  
  if FSimulationMode then
  begin
    FLastResult := 'Simulated: Connection Succeeded.';
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
    FLastResult := FChatGPT.Response
  else
    DoError(FChatGPT.Response);
end;

function TAIProject.ExecuteText(const AText: string): string;
begin
  Result := '';
  FLastError := '';
  
  if FSimulationMode then
  begin
    FLastResult := 'Simulated response for: ' + AText;
    Result := FLastResult;
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
  FLastError := '';
  FLastResult := '';
  
  if Assigned(FOnBeforeExecute) then
    FOnBeforeExecute(Self);
    
  if FSimulationMode then
  begin
    FLastResult := 'Simulated Execute Succeeded.';
    Result := True;
    if Assigned(FOnAfterExecute) then
      FOnAfterExecute(Self);
    Exit;
  end;
  
  Initialize;
  
  if Assigned(FPipeline) then
  begin
    Result := FPipeline.Run;
    if Result then
      FLastResult := FPipeline.LastResult
    else
      DoError(FPipeline.LastError);
  end
  else if Assigned(FAgent) then
  begin
    Result := FAgent.Execute('Analyze state and perform actions.');
    if Result then
      FLastResult := 'Agent run successfully.'
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
  // Use relative path fallback if needed
begin
  LObj := TJSONObject.Create;
  LList := TStringList.Create;
  try
    LObj.Add('ProjectName', FProjectName);
    LObj.Add('Description', FDescription);
    LObj.Add('DefaultModel', FDefaultModel);
    LObj.Add('Token', FToken);
    LObj.Add('LocalURL', FLocalURL);
    LObj.Add('SafeMode', FSafeMode);
    LObj.Add('SimulationMode', FSimulationMode);
    
    LList.Text := LObj.AsJSON;
    LList.SaveToFile(AFileName);
  finally
    LObj.Free;
    LList.Free;
  end;
end;

end.
