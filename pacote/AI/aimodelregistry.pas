unit aimodelregistry;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aibase, chatgpt, LResources,
  aillmmodelcatalog;

type
  { TAIModelItem }

  TAIModelItem = class(TCollectionItem)
  private
    FIsLegacy: Boolean;
    FInternalName: string;
    FFriendlyName: string;
    FProvider: string;
    FDefaultEndpoint: string;
    FMaxTokens: Integer;
    FDefaultTemperature: Double;
    FRequiresAPIKey: Boolean;
    FSupportsVision: Boolean;
    FSupportsTools: Boolean;
    FSupportsStreaming: Boolean;
    FSupportsFineTuning: Boolean;
  published
    property IsLegacy: Boolean read FIsLegacy write FIsLegacy default False;
    property InternalName: string read FInternalName write FInternalName;
    property FriendlyName: string read FFriendlyName write FFriendlyName;
    property Provider: string read FProvider write FProvider;
    property DefaultEndpoint: string read FDefaultEndpoint write FDefaultEndpoint;
    property MaxTokens: Integer read FMaxTokens write FMaxTokens;
    property DefaultTemperature: Double read FDefaultTemperature write FDefaultTemperature;
    property RequiresAPIKey: Boolean read FRequiresAPIKey write FRequiresAPIKey default True;
    property SupportsVision: Boolean read FSupportsVision write FSupportsVision default False;
    property SupportsTools: Boolean read FSupportsTools write FSupportsTools default False;
    property SupportsStreaming: Boolean read FSupportsStreaming write FSupportsStreaming default True;
    property SupportsFineTuning: Boolean read FSupportsFineTuning write FSupportsFineTuning default False;
  end;

  { TAIModelCollection }

  TAIModelCollection = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TAIModelItem;
    procedure SetItem(Index: Integer; AValue: TAIModelItem);
  public
    constructor Create(AOwner: TPersistent);
    function Add: TAIModelItem;
    property Items[Index: Integer]: TAIModelItem read GetItem write SetItem; default;
  end;

  { TAIModelRegistry }

  TAIModelRegistry = class(TAIBaseComponent)
  private
    FModels: TAIModelCollection;
    
    procedure LoadDefaultModels;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    procedure RegisterModel(
      const AProvider, AInternalName, AFriendlyName, AEndpoint: string;
      AMaxTokens: Integer; ATemp: Double; AReqKey, AVision, ATools, AStream, AFineTune: Boolean;
      AIsLegacy: Boolean = False
    );
    
    procedure GetProviders(AList: TStrings);
    procedure GetModels(const AProvider: string; AList: TStrings);
    procedure ApplyModel(const AModelName: string; AChatGPT: TCHATGPT);
    
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
  published
    property Models: TAIModelCollection read FModels write FModels stored False;
    property Category default ccOther;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Core', [TAIModelRegistry]);
end;

{ TAIModelCollection }

constructor TAIModelCollection.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TAIModelItem);
end;

function TAIModelCollection.Add: TAIModelItem;
begin
  Result := TAIModelItem(inherited Add);
end;

function TAIModelCollection.GetItem(Index: Integer): TAIModelItem;
begin
  Result := TAIModelItem(inherited GetItem(Index));
end;

procedure TAIModelCollection.SetItem(Index: Integer; AValue: TAIModelItem);
begin
  inherited SetItem(Index, AValue);
end;

{ TAIModelRegistry }

constructor TAIModelRegistry.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIModelRegistry centralizes provider definitions, endpoints, max token capacities, and functional support attributes (vision, tools, streaming) for OpenAI, Anthropic, Gemini, Ollama, and OpenRouter, configuring TCHATGPT directly.';
  
  FModels := TAIModelCollection.Create(Self);
  LoadDefaultModels;
  ClearError;
end;

destructor TAIModelRegistry.Destroy;
begin
  FModels.Free;
  inherited Destroy;
end;

procedure TAIModelRegistry.RegisterModel(
  const AProvider, AInternalName, AFriendlyName, AEndpoint: string;
  AMaxTokens: Integer; ATemp: Double; AReqKey, AVision, ATools, AStream, AFineTune: Boolean;
  AIsLegacy: Boolean
);
var
  LItem: TAIModelItem;
  Info: TAILLMModelInfo;
  i: Integer;
begin
  // Check if model already registered to avoid duplicates
  for i := 0 to FModels.Count - 1 do
  begin
    if SameText(FModels[i].InternalName, AInternalName) and SameText(FModels[i].Provider, AProvider) then
      Exit;
  end;

  LItem := FModels.Add;
  LItem.Provider := AProvider;
  LItem.InternalName := AInternalName;
  LItem.FriendlyName := AFriendlyName;
  LItem.DefaultEndpoint := AEndpoint;
  LItem.MaxTokens := AMaxTokens;
  LItem.DefaultTemperature := ATemp;
  LItem.RequiresAPIKey := AReqKey;
  LItem.SupportsVision := AVision;
  LItem.SupportsTools := ATools;
  LItem.SupportsStreaming := AStream;
  LItem.SupportsFineTuning := AFineTune;
  LItem.IsLegacy := AIsLegacy;
  if FindAILLMModel(AProvider, AInternalName, Info) then
    LItem.IsLegacy := LItem.IsLegacy or Info.IsLegacy;
end;

procedure TAIModelRegistry.LoadDefaultModels;
var
  I: Integer;
  Info: TAILLMModelInfo;
begin
  for I := 0 to AILLMModelCount - 1 do
    if GetAILLMModelInfo(I, Info) then
      RegisterModel(Info.Provider, Info.InternalName, Info.FriendlyName,
        Info.DefaultEndpoint, Info.MaxTokens, Info.DefaultTemperature,
        Info.RequiresAPIKey, Info.SupportsVision, Info.SupportsTools,
        Info.SupportsStreaming, Info.SupportsFineTuning, Info.IsLegacy);
end;

procedure TAIModelRegistry.GetProviders(AList: TStrings);
var
  i: Integer;
begin
  AList.Clear;
  for i := 0 to FModels.Count - 1 do
  begin
    if AList.IndexOf(FModels[i].Provider) < 0 then
      AList.Add(FModels[i].Provider);
  end;
end;

procedure TAIModelRegistry.GetModels(const AProvider: string; AList: TStrings);
var
  i: Integer;
begin
  AList.Clear;
  for i := 0 to FModels.Count - 1 do
  begin
    if SameText(FModels[i].Provider, AProvider) and not FModels[i].IsLegacy then
      AList.Add(FModels[i].FriendlyName);
  end;
end;

procedure TAIModelRegistry.ApplyModel(const AModelName: string; AChatGPT: TCHATGPT);
var
  i: Integer;
  LModel: TAIModelItem;
  LProvider: TAIProvider;
  LFound: Boolean;
begin
  ClearError;
  if not Assigned(AChatGPT) then
  begin
    SetError('Component TCHATGPT não associado para aplicação de modelo.');
    Exit;
  end;
  
  LModel := nil;
  LFound := False;
  for i := 0 to FModels.Count - 1 do
  begin
    if SameText(FModels[i].FriendlyName, AModelName) or SameText(FModels[i].InternalName, AModelName) then
    begin
      LModel := FModels[i];
      LFound := True;
      Break;
    end;
  end;
  
  if not LFound then
  begin
    SetError('Modelo não encontrado no Registry: ' + AModelName);
    Exit;
  end;
  
  if not TryGetAIProviderFromName(LModel.Provider, LProvider) then
  begin
    SetError('Provedor nao reconhecido no Registry: ' + LModel.Provider);
    Exit;
  end;
  AChatGPT.Provider := LProvider;
  
  // Map Model enum and custom model
  AChatGPT.CustomModel := LModel.InternalName;
  AChatGPT.MaxTokens := LModel.MaxTokens;
  AChatGPT.Temperature := LModel.DefaultTemperature;
  
  // Try to map default types to TypeChat for backward compatibility if names match
  if SameText(LModel.InternalName, 'gpt-3.5-turbo') then AChatGPT.TipoChat := VCT_GPT35TURBO
  else if SameText(LModel.InternalName, 'gpt-4') then AChatGPT.TipoChat := VCT_GPT40
  else if SameText(LModel.InternalName, 'gpt-4o') then AChatGPT.TipoChat := VCT_GPT4o
  else if SameText(LModel.InternalName, 'gpt-4o-mini') then AChatGPT.TipoChat := VCT_GPT4O_MINI
  else if SameText(LModel.InternalName, 'o3-mini') then AChatGPT.TipoChat := VCT_GPTo3_mini
  else if SameText(LModel.InternalName, 'gemini-2.5-flash') then AChatGPT.TipoChat := VCT_GEMINI_25_FLASH
  else if SameText(LModel.InternalName, 'gemini-2.0-flash') then AChatGPT.TipoChat := VCT_GEMINI_20_FLASH
  else if SameText(LModel.InternalName, 'gemini-2.5-pro') then AChatGPT.TipoChat := VCT_GEMINI_25_PRO
  else if SameText(LModel.InternalName, 'claude-3-5-sonnet-20241022') then AChatGPT.TipoChat := VCT_CLAUDE_35_SONNET
  else if SameText(LModel.InternalName, 'claude-3-5-haiku-20241022') then AChatGPT.TipoChat := VCT_CLAUDE_35_HAIKU
  else if SameText(LModel.InternalName, 'llama3.2:3b') then AChatGPT.TipoChat := VCT_LLAMA32_3B
  else if SameText(LModel.InternalName, 'qwen2.5:1.5b') then AChatGPT.TipoChat := VCT_QWEN25_15B
  else if SameText(LModel.InternalName, 'deepseek-r1:1.5b') then AChatGPT.TipoChat := VCT_DEEPSEEK_R1_15B
  else if SameText(LModel.InternalName, 'deepseek-r1:8b') then AChatGPT.TipoChat := VCT_DEEPSEEK_R1_8B
  else AChatGPT.TipoChat := VCT_CUSTOM;
  
  // Clear a previous provider URL as well (Gemini uses its own model route).
  AChatGPT.URL := LModel.DefaultEndpoint;
  
  FLastResult := 'Modelo aplicado: ' + LModel.FriendlyName;
  FLastSuccess := True;
  Log(llInfo, FLastResult);
end;

procedure TAIModelRegistry.SaveToFile(const AFileName: string);
var
  LRoot: TJSONObject;
  LArr: TJSONArray;
  LItemObj: TJSONObject;
  LOut: TStringList;
  i: Integer;
  LModel: TAIModelItem;
begin
  ClearError;
  LRoot := TJSONObject.Create;
  LArr := TJSONArray.Create;
  LOut := TStringList.Create;
  try
    LRoot.Add('models', LArr);
    for i := 0 to FModels.Count - 1 do
    begin
      LModel := FModels[i];
      LItemObj := TJSONObject.Create;
      LItemObj.Add('provider', LModel.Provider);
      LItemObj.Add('internalName', LModel.InternalName);
      LItemObj.Add('friendlyName', LModel.FriendlyName);
      LItemObj.Add('defaultEndpoint', LModel.DefaultEndpoint);
      LItemObj.Add('maxTokens', LModel.MaxTokens);
      LItemObj.Add('defaultTemperature', LModel.DefaultTemperature);
      LItemObj.Add('requiresAPIKey', LModel.RequiresAPIKey);
      LItemObj.Add('supportsVision', LModel.SupportsVision);
      LItemObj.Add('supportsTools', LModel.SupportsTools);
      LItemObj.Add('supportsStreaming', LModel.SupportsStreaming);
      LItemObj.Add('supportsFineTuning', LModel.SupportsFineTuning);
      LItemObj.Add('isLegacy', LModel.IsLegacy);
      LArr.Add(LItemObj);
    end;
    
    LOut.Text := LRoot.AsJSON;
    LOut.SaveToFile(AFileName);
    FLastResult := 'Registry salvo em: ' + AFileName;
    FLastSuccess := True;
    Log(llInfo, FLastResult);
  finally
    LOut.Free;
    LRoot.Free;
  end;
end;

procedure TAIModelRegistry.LoadFromFile(const AFileName: string);
var
  LList: TStringList;
  LData: TJSONData;
  LRoot, LItemObj: TJSONObject;
  LArr: TJSONArray;
  i: Integer;
begin
  ClearError;
  if not FileExists(AFileName) then
  begin
    SetError('Arquivo não existe: ' + AFileName);
    Exit;
  end;
  
  LList := TStringList.Create;
  try
    LList.LoadFromFile(AFileName);
    LData := GetJSON(LList.Text);
    try
      if LData.JSONType = jtObject then
      begin
        LRoot := TJSONObject(LData);
        LArr := LRoot.Arrays['models'];
        FModels.Clear;
        
        for i := 0 to LArr.Count - 1 do
        begin
          LItemObj := LArr.Objects[i];
          RegisterModel(
            LItemObj.Strings['provider'],
            LItemObj.Strings['internalName'],
            LItemObj.Strings['friendlyName'],
            LItemObj.Strings['defaultEndpoint'],
            LItemObj.Integers['maxTokens'],
            LItemObj.Floats['defaultTemperature'],
            LItemObj.Booleans['requiresAPIKey'],
            LItemObj.Booleans['supportsVision'],
            LItemObj.Booleans['supportsTools'],
            LItemObj.Booleans['supportsStreaming'],
            LItemObj.Booleans['supportsFineTuning'],
            LItemObj.Get('isLegacy', False)
          );
        end;
        FLastResult := 'Registry carregado de: ' + AFileName;
        FLastSuccess := True;
        Log(llInfo, FLastResult);
      end;
    finally
      LData.Free;
    end;
  finally
    LList.Free;
  end;
end;

initialization
  {$I aimodelregistry_icon.lrs}

end.
