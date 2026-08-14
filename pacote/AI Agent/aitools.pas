unit aitools;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, fpjson, jsonparser, aibase, aitracebridge,
  LResources;

type
  TAIToolCall = class;
  TAIToolResult = class;
  TAITool = class;

  TAIToolRisk = (
    toolRiskSafe,
    toolRiskRead,
    toolRiskUpdate,
    toolRiskDelete,
    toolRiskExecute,
    toolRiskEmail,
    toolRiskFilesystem
  );

  TAIToolPolicy = (
    toolPolicyInherit,
    toolPolicyAllow,
    toolPolicyConfirm,
    toolPolicyBlock
  );

  TAIToolExecuteEvent = procedure(Sender: TObject; ACall: TAIToolCall;
    AResult: TAIToolResult) of object;
  TAIToolConfirmEvent = procedure(Sender: TObject; ATool: TAITool;
    ACall: TAIToolCall; var AApproved: Boolean) of object;

  IAIToolGuardrail = interface
    ['{2B146AAC-614D-4C5B-A8DC-C46F3171A63A}']
    function EvaluateTool(ATool: TAITool; ACall: TAIToolCall;
      out APolicy: TAIToolPolicy; out AReason: string): Boolean;
  end;

  { TAITool }

  TAITool = class(TPersistent)
  private
    FName: string;
    FDescription: string;
    FParametersSchema: string;
    FRisk: TAIToolRisk;
    FPolicy: TAIToolPolicy;
    FOnExecute: TAIToolExecuteEvent;
  public
    constructor Create;
    function ValidateArguments(AArguments: TJSONObject;
      out AError: string): Boolean;
    procedure Execute(ACall: TAIToolCall; AResult: TAIToolResult);
  published
    property Name: string read FName write FName;
    property Description: string read FDescription write FDescription;
    property ParametersSchema: string read FParametersSchema write FParametersSchema;
    property Risk: TAIToolRisk read FRisk write FRisk default toolRiskSafe;
    property Policy: TAIToolPolicy read FPolicy write FPolicy default toolPolicyInherit;
    property OnExecute: TAIToolExecuteEvent read FOnExecute write FOnExecute;
  end;

  { TAIToolCall }

  TAIToolCall = class
  private
    FCallID: string;
    FToolName: string;
    FArguments: TJSONObject;
    procedure ReplaceArguments(AData: TJSONData);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function ParseJSON(const AJSON: string; out AError: string): Boolean;
    function ToJSON: string;
    procedure SetArgumentsJSON(const AJSON: string);
    function ArgumentsJSON: string;
    property CallID: string read FCallID write FCallID;
    property ToolName: string read FToolName write FToolName;
    property Arguments: TJSONObject read FArguments;
  end;

  { TAIToolResult }

  TAIToolResult = class
  private
    FCallID: string;
    FToolName: string;
    FSuccess: Boolean;
    FErrorText: string;
    FOutput: string;
    FData: TJSONData;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure SetDataJSON(const AJSON: string);
    function DataJSON: string;
    function ToJSON: string;
    property CallID: string read FCallID write FCallID;
    property ToolName: string read FToolName write FToolName;
    property Success: Boolean read FSuccess write FSuccess;
    property ErrorText: string read FErrorText write FErrorText;
    property Output: string read FOutput write FOutput;
    property Data: TJSONData read FData;
  end;

  { TAIToolRegistry }

  TAIToolRegistry = class(TAIBaseComponent)
  private
    FTools: TObjectList;
    FUpdatePolicy: TAIToolPolicy;
    FDeletePolicy: TAIToolPolicy;
    FExecutePolicy: TAIToolPolicy;
    FEmailPolicy: TAIToolPolicy;
    FFilesystemPolicy: TAIToolPolicy;
    FGuardrail: TComponent;
    FTrace: TComponent;
    FLastTraceID: string;
    FOnConfirmTool: TAIToolConfirmEvent;
    function GetCount: Integer;
    function GetTool(AIndex: Integer): TAITool;
    function PolicyFor(ATool: TAITool): TAIToolPolicy;
    procedure SetGuardrail(AValue: TComponent);
    procedure SetTrace(AValue: TComponent);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    function RegisterTool(const AName, ADescription,
      AParametersSchema: string; ARisk: TAIToolRisk;
      AHandler: TAIToolExecuteEvent): TAITool;
    function AddTool(ATool: TAITool): Boolean;
    function RemoveTool(const AName: string): Boolean;
    function FindTool(const AName: string): TAITool;
    function Execute(ACall: TAIToolCall; AResult: TAIToolResult): Boolean;
    function ToolsJSON: string;
    property Count: Integer read GetCount;
    property Tools[AIndex: Integer]: TAITool read GetTool; default;
  published
    property UpdatePolicy: TAIToolPolicy read FUpdatePolicy write FUpdatePolicy default toolPolicyConfirm;
    property DeletePolicy: TAIToolPolicy read FDeletePolicy write FDeletePolicy default toolPolicyConfirm;
    property ExecutePolicy: TAIToolPolicy read FExecutePolicy write FExecutePolicy default toolPolicyConfirm;
    property EmailPolicy: TAIToolPolicy read FEmailPolicy write FEmailPolicy default toolPolicyConfirm;
    property FilesystemPolicy: TAIToolPolicy read FFilesystemPolicy write FFilesystemPolicy default toolPolicyConfirm;
    property Guardrail: TComponent read FGuardrail write SetGuardrail;
    property Trace: TComponent read FTrace write SetTrace;
    property LastTraceID: string read FLastTraceID;
    property OnConfirmTool: TAIToolConfirmEvent read FOnConfirmTool write FOnConfirmTool;
  end;

procedure Register;

implementation

function JSONTypeMatches(AValue: TJSONData; const AExpected: string): Boolean;
begin
  if SameText(AExpected, 'string') then Exit(AValue.JSONType = jtString);
  if SameText(AExpected, 'number') then Exit(AValue.JSONType in [jtNumber]);
  if SameText(AExpected, 'integer') then
    Exit((AValue.JSONType = jtNumber) and (Frac(AValue.AsFloat) = 0));
  if SameText(AExpected, 'boolean') then Exit(AValue.JSONType = jtBoolean);
  if SameText(AExpected, 'object') then Exit(AValue.JSONType = jtObject);
  if SameText(AExpected, 'array') then Exit(AValue.JSONType = jtArray);
  if SameText(AExpected, 'null') then Exit(AValue.JSONType = jtNull);
  Result := True;
end;

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIToolRegistry]);
end;

{ TAITool }

constructor TAITool.Create;
begin
  inherited Create;
  FRisk := toolRiskSafe;
  FPolicy := toolPolicyInherit;
end;

function TAITool.ValidateArguments(AArguments: TJSONObject;
  out AError: string): Boolean;
var
  SchemaData, RequiredData, PropertiesData, PropertyData, ValueData: TJSONData;
  Schema, Properties, PropertySchema: TJSONObject;
  Required: TJSONArray;
  I, ArgIndex: Integer;
  FieldName, ExpectedType: string;
begin
  Result := False;
  AError := '';
  if AArguments = nil then
  begin
    AError := 'Arguments deve ser um objeto JSON.';
    Exit;
  end;
  if Trim(FParametersSchema) = '' then Exit(True);
  try
    SchemaData := GetJSON(FParametersSchema);
  except
    on E: Exception do
    begin
      AError := 'ParametersSchema invalido em "' + FName + '": ' + E.Message;
      Exit;
    end;
  end;
  try
    if not (SchemaData is TJSONObject) then
    begin
      AError := 'ParametersSchema de "' + FName + '" deve ser um objeto JSON.';
      Exit;
    end;
    Schema := TJSONObject(SchemaData);
    RequiredData := Schema.Find('required');
    if Assigned(RequiredData) and (RequiredData is TJSONArray) then
    begin
      Required := TJSONArray(RequiredData);
      for I := 0 to Required.Count - 1 do
      begin
        FieldName := Required.Strings[I];
        if AArguments.IndexOfName(FieldName) < 0 then
        begin
          AError := 'Argumento obrigatorio ausente: ' + FieldName;
          Exit;
        end;
      end;
    end;
    PropertiesData := Schema.Find('properties');
    if Assigned(PropertiesData) and (PropertiesData is TJSONObject) then
    begin
      Properties := TJSONObject(PropertiesData);
      for I := 0 to Properties.Count - 1 do
      begin
        FieldName := Properties.Names[I];
        ArgIndex := AArguments.IndexOfName(FieldName);
        if ArgIndex < 0 then Continue;
        PropertyData := Properties.Items[I];
        if not (PropertyData is TJSONObject) then Continue;
        PropertySchema := TJSONObject(PropertyData);
        ExpectedType := PropertySchema.Get('type', '');
        ValueData := AArguments.Items[ArgIndex];
        if (ExpectedType <> '') and not JSONTypeMatches(ValueData, ExpectedType) then
        begin
          AError := Format('Argumento "%s" deve ser do tipo %s.',
            [FieldName, ExpectedType]);
          Exit;
        end;
      end;
    end;
    Result := True;
  finally
    SchemaData.Free;
  end;
end;

procedure TAITool.Execute(ACall: TAIToolCall; AResult: TAIToolResult);
begin
  if Assigned(FOnExecute) then
    FOnExecute(Self, ACall, AResult)
  else
  begin
    AResult.Success := False;
    AResult.ErrorText := 'Tool "' + FName + '" nao possui handler.';
  end;
end;

{ TAIToolCall }

constructor TAIToolCall.Create;
begin
  inherited Create;
  FArguments := TJSONObject.Create;
end;

destructor TAIToolCall.Destroy;
begin
  FArguments.Free;
  inherited Destroy;
end;

procedure TAIToolCall.Clear;
begin
  FCallID := '';
  FToolName := '';
  FArguments.Clear;
end;

procedure TAIToolCall.ReplaceArguments(AData: TJSONData);
begin
  FreeAndNil(FArguments);
  if Assigned(AData) and (AData is TJSONObject) then
    FArguments := TJSONObject(GetJSON(AData.AsJSON))
  else
    FArguments := TJSONObject.Create;
end;

function TAIToolCall.ParseJSON(const AJSON: string; out AError: string): Boolean;
var
  Data, ArgumentsData, ParsedArguments: TJSONData;
  Obj, FunctionObj: TJSONObject;
begin
  Result := False;
  AError := '';
  Clear;
  try
    Data := GetJSON(AJSON);
  except
    on E: Exception do
    begin
      AError := 'ToolCall JSON invalido: ' + E.Message;
      Exit;
    end;
  end;
  try
    if not (Data is TJSONObject) then
    begin
      AError := 'ToolCall deve ser um objeto JSON.';
      Exit;
    end;
    Obj := TJSONObject(Data);
    FCallID := Obj.Get('id', Obj.Get('call_id', ''));
    FToolName := Obj.Get('tool', Obj.Get('name', ''));
    ArgumentsData := Obj.Find('arguments');

    if (FToolName = '') and (Obj.Find('function') is TJSONObject) then
    begin
      FunctionObj := TJSONObject(Obj.Find('function'));
      FToolName := FunctionObj.Get('name', '');
      ArgumentsData := FunctionObj.Find('arguments');
      if Assigned(ArgumentsData) and (ArgumentsData.JSONType = jtString) then
      begin
        try
          ParsedArguments := GetJSON(ArgumentsData.AsString);
          try
            ReplaceArguments(ParsedArguments);
          finally
            ParsedArguments.Free;
          end;
        except
          on E: Exception do
          begin
            AError := 'Arguments da function nao contem JSON valido: ' + E.Message;
            Exit;
          end;
        end;
      end
      else
        ReplaceArguments(ArgumentsData);
    end
    else
      ReplaceArguments(ArgumentsData);

    if FToolName = '' then
    begin
      AError := 'ToolCall sem nome de tool.';
      Exit;
    end;
    Result := True;
  finally
    Data.Free;
  end;
end;

function TAIToolCall.ToJSON: string;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('id', FCallID);
    Obj.Add('tool', FToolName);
    Obj.Add('arguments', GetJSON(FArguments.AsJSON));
    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

procedure TAIToolCall.SetArgumentsJSON(const AJSON: string);
var
  Data: TJSONData;
begin
  Data := GetJSON(AJSON);
  try
    if not (Data is TJSONObject) then
      raise Exception.Create('Arguments deve ser um objeto JSON.');
    ReplaceArguments(Data);
  finally
    Data.Free;
  end;
end;

function TAIToolCall.ArgumentsJSON: string;
begin
  Result := FArguments.AsJSON;
end;

{ TAIToolResult }

constructor TAIToolResult.Create;
begin
  inherited Create;
  Clear;
end;

destructor TAIToolResult.Destroy;
begin
  FData.Free;
  inherited Destroy;
end;

procedure TAIToolResult.Clear;
begin
  FCallID := '';
  FToolName := '';
  FSuccess := False;
  FErrorText := '';
  FOutput := '';
  FreeAndNil(FData);
end;

procedure TAIToolResult.SetDataJSON(const AJSON: string);
begin
  FreeAndNil(FData);
  if Trim(AJSON) <> '' then FData := GetJSON(AJSON);
end;

function TAIToolResult.DataJSON: string;
begin
  if FData = nil then Result := 'null' else Result := FData.AsJSON;
end;

function TAIToolResult.ToJSON: string;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('call_id', FCallID);
    Obj.Add('tool', FToolName);
    Obj.Add('success', FSuccess);
    Obj.Add('output', FOutput);
    Obj.Add('error', FErrorText);
    if FData = nil then Obj.Add('data', TJSONNull.Create)
    else Obj.Add('data', GetJSON(FData.AsJSON));
    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

{ TAIToolRegistry }

constructor TAIToolRegistry.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccAction;
  FTools := TObjectList.Create(True);
  FUpdatePolicy := toolPolicyConfirm;
  FDeletePolicy := toolPolicyConfirm;
  FExecutePolicy := toolPolicyConfirm;
  FEmailPolicy := toolPolicyConfirm;
  FFilesystemPolicy := toolPolicyConfirm;
  FTrace := nil;
  FLastTraceID := '';
end;

procedure TAIToolRegistry.SetGuardrail(AValue: TComponent);
begin
  if FGuardrail = AValue then Exit;
  if FGuardrail <> nil then FGuardrail.RemoveFreeNotification(Self);
  FGuardrail := AValue;
  if FGuardrail <> nil then FGuardrail.FreeNotification(Self);
end;

procedure TAIToolRegistry.SetTrace(AValue: TComponent);
begin
  if FTrace = AValue then Exit;
  if FTrace <> nil then FTrace.RemoveFreeNotification(Self);
  FTrace := AValue;
  if FTrace <> nil then FTrace.FreeNotification(Self);
end;

procedure TAIToolRegistry.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FGuardrail) then FGuardrail := nil;
  if (Operation = opRemove) and (AComponent = FTrace) then FTrace := nil;
end;

destructor TAIToolRegistry.Destroy;
begin
  FTools.Free;
  inherited Destroy;
end;

procedure TAIToolRegistry.Clear;
begin
  FTools.Clear;
  ClearError;
end;

function TAIToolRegistry.GetCount: Integer;
begin
  Result := FTools.Count;
end;

function TAIToolRegistry.GetTool(AIndex: Integer): TAITool;
begin
  Result := TAITool(FTools[AIndex]);
end;

function TAIToolRegistry.FindTool(const AName: string): TAITool;
var
  I: Integer;
begin
  for I := 0 to FTools.Count - 1 do
    if SameText(TAITool(FTools[I]).Name, AName) then Exit(TAITool(FTools[I]));
  Result := nil;
end;

function TAIToolRegistry.AddTool(ATool: TAITool): Boolean;
var
  SchemaData: TJSONData;
begin
  Result := False;
  ClearError;
  if ATool = nil then begin SetError('Tool nula.'); Exit; end;
  if Trim(ATool.Name) = '' then begin SetError('Nome da tool vazio.'); Exit; end;
  if FindTool(ATool.Name) <> nil then
  begin
    SetError('Tool duplicada: ' + ATool.Name);
    Exit;
  end;
  if Trim(ATool.ParametersSchema) <> '' then
  begin
    try
      SchemaData := GetJSON(ATool.ParametersSchema);
      try
        if not (SchemaData is TJSONObject) then
        begin SetError('ParametersSchema deve ser um objeto JSON.'); Exit; end;
      finally
        SchemaData.Free;
      end;
    except
      on E: Exception do begin SetError('ParametersSchema invalido: ' + E.Message); Exit; end;
    end;
  end;
  FTools.Add(ATool);
  Result := True;
  FLastSuccess := True;
end;

function TAIToolRegistry.RemoveTool(const AName: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := FTools.Count - 1 downto 0 do
    if SameText(TAITool(FTools[I]).Name, AName) then
    begin
      FTools.Delete(I);
      Exit(True);
    end;
end;

function TAIToolRegistry.RegisterTool(const AName, ADescription,
  AParametersSchema: string; ARisk: TAIToolRisk;
  AHandler: TAIToolExecuteEvent): TAITool;
begin
  Result := TAITool.Create;
  Result.Name := Trim(AName);
  Result.Description := ADescription;
  Result.ParametersSchema := AParametersSchema;
  Result.Risk := ARisk;
  Result.OnExecute := AHandler;
  if not AddTool(Result) then FreeAndNil(Result);
end;

function TAIToolRegistry.PolicyFor(ATool: TAITool): TAIToolPolicy;
begin
  if ATool.Policy <> toolPolicyInherit then Exit(ATool.Policy);
  case ATool.Risk of
    toolRiskSafe, toolRiskRead: Result := toolPolicyAllow;
    toolRiskUpdate: Result := FUpdatePolicy;
    toolRiskDelete: Result := FDeletePolicy;
    toolRiskExecute: Result := FExecutePolicy;
    toolRiskEmail: Result := FEmailPolicy;
    toolRiskFilesystem: Result := FFilesystemPolicy;
  else
    Result := toolPolicyBlock;
  end;
end;

function TAIToolRegistry.Execute(ACall: TAIToolCall;
  AResult: TAIToolResult): Boolean;
var
  Tool: TAITool;
  Policy: TAIToolPolicy;
  GuardrailIntf: IAIToolGuardrail;
  Approved: Boolean;
  Err: string;
  SpanID: string;
  TraceObj: TJSONObject;
begin
  Result := False;
  ClearError;
  if AResult = nil then begin SetError('ToolResult nulo.'); Exit; end;
  AResult.Clear;
  if ACall = nil then
  begin
    AResult.ErrorText := 'ToolCall nulo.';
    SetError(AResult.ErrorText);
    Exit;
  end;
  AResult.CallID := ACall.CallID;
  AResult.ToolName := ACall.ToolName;
  TraceObj := TJSONObject.Create;
  try
    TraceObj.Add('tool', ACall.ToolName);
    TraceObj.Add('call_id', ACall.CallID);
    if AITraceAllowsSensitiveContent(FTrace) then
      TraceObj.Add('arguments', ACall.Arguments.Clone);
    SpanID := AITraceBegin(FTrace, 'tool', ACall.ToolName, '', TraceObj.AsJSON);
    FLastTraceID := AITraceID(FTrace);
  finally TraceObj.Free; end;
  try
  Tool := FindTool(ACall.ToolName);
  if Tool = nil then
  begin
    AResult.ErrorText := 'Tool nao registrada: ' + ACall.ToolName;
    SetError(AResult.ErrorText);
    Exit;
  end;
  if not Tool.ValidateArguments(ACall.Arguments, Err) then
  begin
    AResult.ErrorText := Err;
    SetError(Err);
    Exit;
  end;
  Policy := PolicyFor(Tool);
  if Assigned(FGuardrail) and Supports(FGuardrail, IAIToolGuardrail, GuardrailIntf) then
  begin
    if not GuardrailIntf.EvaluateTool(Tool, ACall, Policy, Err) then
    begin
      AResult.ErrorText := Err;
      if AResult.ErrorText = '' then AResult.ErrorText := 'Tool bloqueada pelo guardrail.';
      SetError(AResult.ErrorText);
      Exit;
    end;
  end;
  if Policy = toolPolicyBlock then
  begin
    AResult.ErrorText := 'Tool bloqueada pela politica: ' + Tool.Name;
    SetError(AResult.ErrorText);
    Exit;
  end;
  if Policy = toolPolicyConfirm then
  begin
    Approved := False;
    if Assigned(FOnConfirmTool) then FOnConfirmTool(Self, Tool, ACall, Approved);
    if not Approved then
    begin
      AResult.ErrorText := 'Tool rejeitada ou sem confirmacao: ' + Tool.Name;
      SetError(AResult.ErrorText);
      Exit;
    end;
  end;
  try
    Tool.Execute(ACall, AResult);
  except
    on E: Exception do
    begin
      AResult.Success := False;
      AResult.ErrorText := 'Excecao na tool "' + Tool.Name + '": ' + E.Message;
    end;
  end;
  Result := AResult.Success;
  if not Result then
  begin
    if AResult.ErrorText = '' then AResult.ErrorText := 'Tool falhou sem mensagem.';
    SetError(AResult.ErrorText);
  end;
  FLastSuccess := Result;
  if Result then FLastResult := AResult.Output;
  finally
    TraceObj := TJSONObject.Create;
    try
      TraceObj.Add('success', AResult.Success);
      TraceObj.Add('output_chars', Length(AResult.Output));
      if AITraceAllowsSensitiveContent(FTrace) then
        TraceObj.Add('output', AResult.Output);
      AITraceEnd(FTrace, SpanID, AResult.ErrorText, TraceObj.AsJSON);
    finally TraceObj.Free; end;
  end;
end;

function TAIToolRegistry.ToolsJSON: string;
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
  Tool: TAITool;
begin
  Arr := TJSONArray.Create;
  try
    for I := 0 to FTools.Count - 1 do
    begin
      Tool := TAITool(FTools[I]);
      Obj := TJSONObject.Create;
      Obj.Add('name', Tool.Name);
      Obj.Add('description', Tool.Description);
      if Trim(Tool.ParametersSchema) = '' then
        Obj.Add('inputSchema', TJSONObject.Create)
      else
        Obj.Add('inputSchema', GetJSON(Tool.ParametersSchema));
      Arr.Add(Obj);
    end;
    Result := Arr.AsJSON;
  finally
    Arr.Free;
  end;
end;

initialization
  {$I aitools_icon.lrs}

end.
