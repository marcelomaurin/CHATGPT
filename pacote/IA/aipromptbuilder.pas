unit aipromptbuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo, LResources, aibase, fpjson;

type
  TPromptLanguage = (plPortuguese, plEnglish, plSpanish);
  TPromptOutputFormat = (pofText, pofMarkdown, pofJSON);

  { TAIPromptBuilder }

  TAIPromptBuilder = class(TAIBaseComponent)
  private
    FIncludeComponentNames: Boolean;
    FIncludeOnlyAIComponents: Boolean;
    FIncludeActions: Boolean;
    FIncludeOutputs: Boolean;
    FIncludeInputs: Boolean;
    FLastPrompt: string;
    FLanguage: TPromptLanguage;
    FOutputFormat: TPromptOutputFormat;
    FIncludeProperties: Boolean;
    FIncludePublishedProperties: Boolean;
    
    function IsAIComponent(AComponent: TComponent): Boolean;
    function GetAIComponentCategory(AComponent: TComponent): TAIComponentCategory;
    function GetDefaultDescription(AComponent: TComponent): string;
    procedure ExtractProps(AComponent: TComponent; AOutputList: TStringList; AOutputJSON: TJSONObject);
  public
    constructor Create(AOwner: TComponent); override;
    
    function BuildFromOwner(AOwner: TComponent): string;
    function BuildFromComponents(AComponents: array of TComponent): string;
    function ExtractPrompt(AComponent: TComponent): string;
  published
    property IncludeComponentNames: Boolean read FIncludeComponentNames write FIncludeComponentNames default True;
    property IncludeOnlyAIComponents: Boolean read FIncludeOnlyAIComponents write FIncludeOnlyAIComponents default True;
    property IncludeActions: Boolean read FIncludeActions write FIncludeActions default True;
    property IncludeOutputs: Boolean read FIncludeOutputs write FIncludeOutputs default True;
    property IncludeInputs: Boolean read FIncludeInputs write FIncludeInputs default True;
    property Language: TPromptLanguage read FLanguage write FLanguage default plPortuguese;
    property OutputFormat: TPromptOutputFormat read FOutputFormat write FOutputFormat default pofText;
    property IncludeProperties: Boolean read FIncludeProperties write FIncludeProperties default False;
    property IncludePublishedProperties: Boolean read FIncludePublishedProperties write FIncludePublishedProperties default False;
    property LastPrompt: string read FLastPrompt write FLastPrompt;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Core', [TAIPromptBuilder]);
end;

{ TAIPromptBuilder }

constructor TAIPromptBuilder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIPromptBuilder automatically scans the owner form or list of components to construct a unified system prompt describing available tools, inputs, outputs, and actions. Properties: IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs, Language, OutputFormat, IncludeProperties, IncludePublishedProperties. Methods: BuildFromOwner(AOwner: TComponent): string, BuildFromComponents(AComponents: array of TComponent): string.';
  FIncludeComponentNames := True;
  FIncludeOnlyAIComponents := True;
  FIncludeActions := True;
  FIncludeOutputs := True;
  FIncludeInputs := True;
  FLanguage := plPortuguese;
  FOutputFormat := pofText;
  FIncludeProperties := False;
  FIncludePublishedProperties := False;
  FLastPrompt := '';
end;

function TAIPromptBuilder.IsAIComponent(AComponent: TComponent): Boolean;
var
  ClassNameUpper: string;
  PropInfo: PPropInfo;
begin
  Result := False;
  if not Assigned(AComponent) then Exit;
  
  if AComponent is TAIBaseComponent then
  begin
    Result := True;
    Exit;
  end;
  
  ClassNameUpper := UpperCase(AComponent.ClassName);
  if (Pos('TAI', ClassNameUpper) = 1) or 
     (ClassNameUpper = 'TCHATGPT') or 
     (ClassNameUpper = 'TNEURALNETWORK') then
  begin
    Result := True;
    Exit;
  end;

  // Check if it has a string Prompt property
  PropInfo := GetPropInfo(AComponent, 'Prompt');
  if Assigned(PropInfo) and (PropInfo^.PropType^.Kind in [tkSString, tkAString, tkUString, tkWString]) then
    Result := True;
end;

function TAIPromptBuilder.GetAIComponentCategory(AComponent: TComponent): TAIComponentCategory;
var
  ClassNameUpper: string;
begin
  if AComponent is TAIBaseComponent then
  begin
    Result := TAIBaseComponent(AComponent).Category;
    if Result <> ccOther then Exit;
  end;

  ClassNameUpper := UpperCase(AComponent.ClassName);
  
  // Actions / Core
  if (ClassNameUpper = 'TAIAGENT') or 
     (ClassNameUpper = 'TAIPIPELINE') or 
     (ClassNameUpper = 'TNEURALNETWORK') or 
     (ClassNameUpper = 'TCHATGPT') or
     (ClassNameUpper = 'TAIPROJECT') or
     (ClassNameUpper = 'TAIPROMPTBUILDER') or
     (ClassNameUpper = 'TAICODEASSISTANT') or
     (ClassNameUpper = 'TAIDATASETGENERATOR') or
     (ClassNameUpper = 'TYOLODETECT') or
     (ClassNameUpper = 'TFACEDETECTION') or
     (ClassNameUpper = 'TPERCEPTRON') or
     (ClassNameUpper = 'TSOMMAP') or
     (ClassNameUpper = 'TCNNCLASSIFIER') or
     (ClassNameUpper = 'TLSTMPREDICTOR') then
  begin
    Result := ccAction;
    Exit;
  end;

  // Outputs / Documents / Messengers
  if (Pos('OUTPUT', ClassNameUpper) > 0) or 
     (Pos('PRINTER', ClassNameUpper) > 0) or 
     (Pos('EMAIL', ClassNameUpper) > 0) or 
     (Pos('MESSENGER', ClassNameUpper) > 0) or 
     (Pos('VOICE', ClassNameUpper) > 0) or 
     (Pos('SYNTHESIZER', ClassNameUpper) > 0) then
  begin
    Result := ccOutput;
    Exit;
  end;

  // Inputs / Sockets / Capture / Devices
  if (Pos('INPUT', ClassNameUpper) > 0) or 
     (Pos('CAMERA', ClassNameUpper) > 0) or 
     (Pos('AUDIO', ClassNameUpper) > 0) or 
     (Pos('CAPTURE', ClassNameUpper) > 0) or 
     (Pos('BROWSER', ClassNameUpper) > 0) or 
     (Pos('MODBUS', ClassNameUpper) > 0) or 
     (Pos('MQTT', ClassNameUpper) > 0) or 
     (Pos('SOCKETS', ClassNameUpper) > 0) or 
     (Pos('SERIAL', ClassNameUpper) > 0) or 
     (Pos('BRIDGE', ClassNameUpper) > 0) or
     (Pos('CFTVIP', ClassNameUpper) > 0) then
  begin
    Result := ccInput;
    Exit;
  end;

  Result := ccOther;
end;

function TAIPromptBuilder.GetDefaultDescription(AComponent: TComponent): string;
var
  ClassNameUpper: string;
begin
  Result := '';
  if not Assigned(AComponent) then Exit;
  ClassNameUpper := UpperCase(AComponent.ClassName);
  if ClassNameUpper = 'TBUTTON' then
    Result := 'Botão clicável para acionar comandos e disparar rotinas.'
  else if ClassNameUpper = 'TEDIT' then
    Result := 'Campo de entrada de texto de linha única para digitação do usuário.'
  else if ClassNameUpper = 'TMEMO' then
    Result := 'Campo de entrada de texto com múltiplas linhas para logs ou textos longos.'
  else if ClassNameUpper = 'TLABEL' then
    Result := 'Exibição de texto estático ou informacional na tela.'
  else if ClassNameUpper = 'TTIMER' then
    Result := 'Temporizador em segundo plano para tarefas cíclicas ou periódicas.'
  else if ClassNameUpper = 'TCHECKBOX' then
    Result := 'Opção booleana de marcação (verdadeiro/falso).'
  else
    Result := 'Componente do tipo ' + AComponent.ClassName + ' para integração operacional.';
end;

procedure TAIPromptBuilder.ExtractProps(AComponent: TComponent; AOutputList: TStringList; AOutputJSON: TJSONObject);
var
  PropList: PPropList;
  PropCount: Integer;
  I: Integer;
  PropName: string;
  PropVal: string;
  IsSensitive: Boolean;
  IsIncluded: Boolean;
begin
  if not Assigned(AComponent) then Exit;
  
  PropCount := GetPropList(AComponent.ClassInfo, tkProperties, nil);
  if PropCount > 0 then
  begin
    GetMem(PropList, PropCount * SizeOf(PPropInfo));
    try
      GetPropList(AComponent.ClassInfo, tkProperties, PropList);
      for I := 0 to PropCount - 1 do
      begin
        PropName := PropList^[I]^.Name;
        
        // Skip sensitive or common properties
        IsSensitive := SameText(PropName, 'Token') or
                       SameText(PropName, 'Password') or
                       SameText(PropName, 'APIKey') or
                       SameText(PropName, 'Secret') or
                       SameText(PropName, 'PrivateKey') or
                       SameText(PropName, 'Prompt') or
                       SameText(PropName, 'Name') or
                       SameText(PropName, 'Tag') or
                       SameText(PropName, 'Category') or
                       SameText(PropName, 'OnLog');
                       
        if IsSensitive then Continue;
        
        IsIncluded := FIncludePublishedProperties;
        if not IsIncluded and FIncludeProperties then
        begin
          // Standard properties subset
          IsIncluded := SameText(PropName, 'Host') or
                        SameText(PropName, 'IPAddress') or
                        SameText(PropName, 'Port') or
                        SameText(PropName, 'ProtocolType') or
                        SameText(PropName, 'ClientID') or
                        SameText(PropName, 'DeviceName') or
                        SameText(PropName, 'BaudRate') or
                        SameText(PropName, 'Active') or
                        SameText(PropName, 'SafeMode') or
                        SameText(PropName, 'SimulationMode') or
                        SameText(PropName, 'LibraryPath') or
                        SameText(PropName, 'FileName') or
                        SameText(PropName, 'Title') or
                        SameText(PropName, 'Author') or
                        SameText(PropName, 'Subject');
        end;
        
        if IsIncluded then
        begin
          try
            PropVal := GetPropValue(AComponent, PropName, True);
            if Assigned(AOutputList) then
              AOutputList.Add(PropName + '=' + PropVal);
            if Assigned(AOutputJSON) then
              AOutputJSON.Add(PropName, PropVal);
          except
            // Ignore RTTI errors
          end;
        end;
      end;
    finally
      FreeMem(PropList);
    end;
  end;
end;

function TAIPromptBuilder.BuildFromOwner(AOwner: TComponent): string;
var
  I: Integer;
  CompList: array of TComponent;
  Count: Integer;
begin
  Result := '';
  if not Assigned(AOwner) then Exit;
  CompList := nil;
  
  Count := AOwner.ComponentCount;
  if Count > 0 then
  begin
    SetLength(CompList, Count);
    for I := 0 to Count - 1 do
      CompList[I] := AOwner.Components[I];
      
    Result := BuildFromComponents(CompList);
  end
  else
  begin
    SetLength(CompList, 1);
    CompList[0] := AOwner;
    Result := BuildFromComponents(CompList);
  end;
end;

function TAIPromptBuilder.BuildFromComponents(AComponents: array of TComponent): string;
var
  I, J: Integer;
  Comp: TComponent;
  PromptText: string;
  Cat: TAIComponentCategory;
  Lines: TStringList;
  CompName: string;
  HeaderStr, FooterStr: string;
  JSONRoot, JSONComp, JSONProps: TJSONObject;
  JSONArray: TJSONArray;
  CatName: string;
  TempList: TStringList;
begin
  Result := '';
  if Length(AComponents) = 0 then Exit;
  
  case FLanguage of
    plEnglish:
      begin
        HeaderStr := 'The following components are available to you:';
        FooterStr := 'Use only the available components.' + sLineBreak + 'Respond in JSON when actions need to be executed.';
      end;
    plSpanish:
      begin
        HeaderStr := 'Tiene disponibles los siguientes componentes:';
        FooterStr := 'Use solo los componentes disponibles.' + sLineBreak + 'Responda en JSON cuando necesite ejecutar acciones.';
      end;
    else // plPortuguese
      begin
        HeaderStr := 'Você tem disponíveis os seguintes componentes:';
        FooterStr := 'Use apenas os componentes disponíveis.' + sLineBreak + 'Responda em JSON quando precisar executar ações.';
      end;
  end;
  
  if FOutputFormat = pofJSON then
  begin
    JSONRoot := TJSONObject.Create;
    JSONArray := TJSONArray.Create;
    try
      JSONRoot.Add('instruction', HeaderStr);
      JSONRoot.Add('footer', FooterStr);
      JSONRoot.Add('components', JSONArray);
      
      for I := Low(AComponents) to High(AComponents) do
      begin
        Comp := AComponents[I];
        if not Assigned(Comp) then Continue;
        
        if FIncludeOnlyAIComponents and not IsAIComponent(Comp) then
          Continue;
          
        Cat := GetAIComponentCategory(Comp);
        case Cat of
          ccInput: if not FIncludeInputs then Continue;
          ccOutput: if not FIncludeOutputs then Continue;
          ccAction: if not FIncludeActions then Continue;
          ccOther: if FIncludeOnlyAIComponents then Continue;
        end;
        
        PromptText := ExtractPrompt(Comp);
        if PromptText = '' then
        begin
          if not FIncludeOnlyAIComponents then
            PromptText := GetDefaultDescription(Comp);
        end;
        
        JSONComp := TJSONObject.Create;
        CompName := Comp.Name;
        if CompName = '' then
          CompName := Comp.ClassName;
          
        JSONComp.Add('name', CompName);
        JSONComp.Add('type', Comp.ClassName);
        
        case Cat of
          ccInput: CatName := 'Input';
          ccOutput: CatName := 'Output';
          ccAction: CatName := 'Action';
          ccModel: CatName := 'Model';
          ccProject: CatName := 'Project';
          ccSafety: CatName := 'Safety';
          else CatName := 'Other';
        end;
        JSONComp.Add('category', CatName);
        JSONComp.Add('description', PromptText);
        
        if FIncludeProperties or FIncludePublishedProperties then
        begin
          JSONProps := TJSONObject.Create;
          ExtractProps(Comp, nil, JSONProps);
          JSONComp.Add('properties', JSONProps);
        end;
        
        JSONArray.Add(JSONComp);
      end;
      
      Result := JSONRoot.AsJSON;
      FLastPrompt := Result;
    finally
      JSONRoot.Free;
    end;
  end
  else // pofText or pofMarkdown
  begin
    Lines := TStringList.Create;
    TempList := TStringList.Create;
    try
      Lines.Add(HeaderStr);
      Lines.Add('');
      
      for I := Low(AComponents) to High(AComponents) do
      begin
        Comp := AComponents[I];
        if not Assigned(Comp) then Continue;
        
        if FIncludeOnlyAIComponents and not IsAIComponent(Comp) then
          Continue;
          
        Cat := GetAIComponentCategory(Comp);
        case Cat of
          ccInput: if not FIncludeInputs then Continue;
          ccOutput: if not FIncludeOutputs then Continue;
          ccAction: if not FIncludeActions then Continue;
          ccOther: if FIncludeOnlyAIComponents then Continue;
        end;
        
        PromptText := ExtractPrompt(Comp);
        if PromptText = '' then
        begin
          if not FIncludeOnlyAIComponents then
            PromptText := GetDefaultDescription(Comp);
        end;
        
        if PromptText <> '' then
        begin
          CompName := Comp.Name;
          if CompName = '' then
            CompName := Comp.ClassName;
            
          if FOutputFormat = pofMarkdown then
          begin
            if FIncludeComponentNames then
              Lines.Add('### ' + CompName + ' (`' + Comp.ClassName + '`)')
            else
              Lines.Add('### `' + Comp.ClassName + '`');
              
            Lines.Add('*Description*: ' + PromptText);
          end
          else // pofText
          begin
            if FIncludeComponentNames then
              Lines.Add('[' + CompName + ']')
            else
              Lines.Add('[' + Comp.ClassName + ']');
              
            Lines.Add('Prompt: ' + PromptText);
          end;
          
          if FIncludeProperties or FIncludePublishedProperties then
          begin
            TempList.Clear;
            ExtractProps(Comp, TempList, nil);
            if TempList.Count > 0 then
            begin
              if FOutputFormat = pofMarkdown then
              begin
                Lines.Add('');
                Lines.Add('| Property | Value |');
                Lines.Add('| --- | --- |');
                for J := 0 to TempList.Count - 1 do
                begin
                  Lines.Add('| ' + TempList.Names[J] + ' | ' + TempList.ValueFromIndex[J] + ' |');
                end;
              end
              else // pofText
              begin
                for J := 0 to TempList.Count - 1 do
                  Lines.Add(TempList.Names[J] + ': ' + TempList.ValueFromIndex[J]);
              end;
            end;
          end;
          
          Lines.Add('');
        end;
      end;
      
      Lines.Add(FooterStr);
      Result := Lines.Text;
      FLastPrompt := Result;
    finally
      Lines.Free;
      TempList.Free;
    end;
  end;
end;

function TAIPromptBuilder.ExtractPrompt(AComponent: TComponent): string;
var
  PropInfo: PPropInfo;
begin
  Result := '';
  if not Assigned(AComponent) then Exit;
  PropInfo := GetPropInfo(AComponent, 'Prompt');
  if Assigned(PropInfo) and (PropInfo^.PropType^.Kind in [tkSString, tkAString, tkUString, tkWString]) then
  begin
    Result := GetStrProp(AComponent, PropInfo);
  end;
end;

initialization
  {$I aipromptbuilder_icon.lrs}

end.
