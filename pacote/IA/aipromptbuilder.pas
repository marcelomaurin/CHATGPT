unit aipromptbuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, TypInfo;

type
  TAIComponentCategory = (ccInput, ccOutput, ccAction, ccOther);

  { TAIPromptBuilder }

  TAIPromptBuilder = class(TComponent)
  private
    FPrompt: string;
    FIncludeComponentNames: Boolean;
    FIncludeOnlyAIComponents: Boolean;
    FIncludeActions: Boolean;
    FIncludeOutputs: Boolean;
    FIncludeInputs: Boolean;
    FLastPrompt: string;
    
    function IsAIComponent(AComponent: TComponent): Boolean;
    function GetAIComponentCategory(AComponent: TComponent): TAIComponentCategory;
    function GetDefaultDescription(AComponent: TComponent): string;
  public
    constructor Create(AOwner: TComponent); override;
    
    function BuildFromOwner(AOwner: TComponent): string;
    function BuildFromComponents(AComponents: array of TComponent): string;
    function ExtractPrompt(AComponent: TComponent): string;
  published
    property Prompt: string read FPrompt write FPrompt;
    property IncludeComponentNames: Boolean read FIncludeComponentNames write FIncludeComponentNames default True;
    property IncludeOnlyAIComponents: Boolean read FIncludeOnlyAIComponents write FIncludeOnlyAIComponents default True;
    property IncludeActions: Boolean read FIncludeActions write FIncludeActions default True;
    property IncludeOutputs: Boolean read FIncludeOutputs write FIncludeOutputs default True;
    property IncludeInputs: Boolean read FIncludeInputs write FIncludeInputs default True;
    property LastPrompt: string read FLastPrompt write FLastPrompt;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Project', [TAIPromptBuilder]);
end;

{ TAIPromptBuilder }

constructor TAIPromptBuilder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIPromptBuilder automatically scans the owner form or list of components to construct a unified system prompt describing available tools, inputs, outputs, and actions. Properties: IncludeComponentNames, IncludeOnlyAIComponents, IncludeActions, IncludeOutputs, IncludeInputs. Methods: BuildFromOwner(AOwner: TComponent): string, BuildFromComponents(AComponents: array of TComponent): string.';
  FIncludeComponentNames := True;
  FIncludeOnlyAIComponents := True;
  FIncludeActions := True;
  FIncludeOutputs := True;
  FIncludeInputs := True;
  FLastPrompt := '';
end;

function TAIPromptBuilder.IsAIComponent(AComponent: TComponent): Boolean;
var
  ClassNameUpper: string;
  PropInfo: PPropInfo;
begin
  Result := False;
  if not Assigned(AComponent) then Exit;
  
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
    // If owner itself is a single component, pass it
    SetLength(CompList, 1);
    CompList[0] := AOwner;
    Result := BuildFromComponents(CompList);
  end;
end;

function TAIPromptBuilder.BuildFromComponents(AComponents: array of TComponent): string;
var
  I: Integer;
  Comp: TComponent;
  PromptText: string;
  Cat: TAIComponentCategory;
  Lines: TStringList;
  CompName: string;
begin
  Result := '';
  if Length(AComponents) = 0 then Exit;
  
  Lines := TStringList.Create;
  try
    Lines.Add('Você tem disponíveis os seguintes componentes:');
    Lines.Add('');

    for I := Low(AComponents) to High(AComponents) do
    begin
      Comp := AComponents[I];
      if not Assigned(Comp) then Continue;

      // Filter: Only AI Components if requested
      if FIncludeOnlyAIComponents and not IsAIComponent(Comp) then
        Continue;

      Cat := GetAIComponentCategory(Comp);
      // Filter by category
      case Cat of
        ccInput: if not FIncludeInputs then Continue;
        ccOutput: if not FIncludeOutputs then Continue;
        ccAction: if not FIncludeActions then Continue;
        ccOther: if FIncludeOnlyAIComponents then Continue;
      end;

      // Extract Prompt description
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
          
        if FIncludeComponentNames then
          Lines.Add('[' + CompName + ']')
        else
          Lines.Add('[' + Comp.ClassName + ']');
          
        Lines.Add(PromptText);
        Lines.Add('');
      end;
    end;

    Lines.Add('Use apenas os componentes disponíveis.');
    Lines.Add('Responda em JSON quando precisar executar ações.');

    Result := Lines.Text;
    FLastPrompt := Result;
  finally
    Lines.Free;
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

end.
