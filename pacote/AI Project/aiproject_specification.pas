unit aiproject_specification;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, aiproject;

type
  { TAIProjectSpecification
    Generates and stores project specification from a simple project description. }

  TAIProjectSpecification = class(TComponent)
  private
    FProject: TAIProject;
    FLastError: string;
    FLastPrompt: string;
    FLastResponse: string;

    function EnsureReady: Boolean;
    function ExtractJSONFromAIResponse(const AText: string): string;

    procedure ReplaceJSONValue(AObject: TJSONObject; const AName: string; AValue: TJSONData);
    procedure CopyJSONField(ASource, ADest: TJSONObject; const AName: string);
    procedure EnsureAgileDocuments;
    procedure MergeSpecification(AJSON: TJSONObject);

  public
    constructor Create(AOwner: TComponent); override;

    function BuildSpecificationPrompt(
      const AProjectName,
            AGoal,
            AConstraints,
            ADeliverables: string
    ): string;

    function GenerateSpecification(
      const AProjectName,
            AGoal,
            AConstraints,
            ADeliverables: string
    ): Boolean;

    property LastPrompt: string read FLastPrompt;
    property LastResponse: string read FLastResponse;
    property LastError: string read FLastError;

  published
    property Project: TAIProject read FProject write FProject;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Project', [TAIProjectSpecification]);
end;

constructor TAIProjectSpecification.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLastError := '';
  FLastPrompt := '';
  FLastResponse := '';
end;

function TAIProjectSpecification.EnsureReady: Boolean;
begin
  Result := False;
  FLastError := '';

  if not Assigned(FProject) then
  begin
    FLastError := 'No TAIProject linked.';
    Exit;
  end;

  if not Assigned(FProject.ProjectData) then
  begin
    FLastError := 'TAIProject.ProjectData is not available.';
    Exit;
  end;

  FProject.EnsureProjectStructure;
  Result := True;
end;

procedure TAIProjectSpecification.ReplaceJSONValue(AObject: TJSONObject; const AName: string; AValue: TJSONData);
var
  LIndex: Integer;
begin
  if not Assigned(AObject) then
  begin
    AValue.Free;
    Exit;
  end;

  LIndex := AObject.IndexOfName(AName);

  if LIndex >= 0 then
    AObject.Delete(LIndex);

  AObject.Add(AName, AValue);
end;

procedure TAIProjectSpecification.CopyJSONField(ASource, ADest: TJSONObject; const AName: string);
var
  LData: TJSONData;
begin
  if not Assigned(ASource) then
    Exit;

  if not Assigned(ADest) then
    Exit;

  LData := ASource.Find(AName);

  if Assigned(LData) then
    ReplaceJSONValue(ADest, AName, LData.Clone);
end;

procedure TAIProjectSpecification.EnsureAgileDocuments;
var
  LDocs: TJSONObject;
begin
  if not Assigned(FProject) then
    Exit;

  FProject.EnsureProjectStructure;

  LDocs := TJSONObject(FProject.ProjectData.FindPath('agile_documents'));

  if not Assigned(LDocs) then
  begin
    LDocs := TJSONObject.Create;
    FProject.ProjectData.Add('agile_documents', LDocs);
  end;

  if LDocs.IndexOfName('business_vision') < 0 then
    LDocs.Add('business_vision', '');

  if LDocs.IndexOfName('functional_requirements') < 0 then
    LDocs.Add('functional_requirements', TJSONArray.Create);

  if LDocs.IndexOfName('non_functional_requirements') < 0 then
    LDocs.Add('non_functional_requirements', TJSONArray.Create);

  if LDocs.IndexOfName('stakeholders') < 0 then
    LDocs.Add('stakeholders', TJSONArray.Create);

  if LDocs.IndexOfName('risk_map') < 0 then
    LDocs.Add('risk_map', TJSONArray.Create);

  if LDocs.IndexOfName('epics') < 0 then
    LDocs.Add('epics', TJSONArray.Create);

  if LDocs.IndexOfName('user_stories') < 0 then
    LDocs.Add('user_stories', TJSONArray.Create);
end;

function TAIProjectSpecification.ExtractJSONFromAIResponse(const AText: string): string;
var
  I, StartPos: Integer;
  CurlyCount, SquareCount: Integer;
  InString, EscapeNext: Boolean;
  Ch: Char;
begin
  Result := '';
  StartPos := 0;

  for I := 1 to Length(AText) do
  begin
    if (AText[I] = '{') or (AText[I] = '[') then
    begin
      StartPos := I;
      Break;
    end;
  end;

  if StartPos = 0 then
    raise Exception.Create('The AI response does not contain JSON.');

  CurlyCount := 0;
  SquareCount := 0;
  InString := False;
  EscapeNext := False;

  for I := StartPos to Length(AText) do
  begin
    Ch := AText[I];

    if InString then
    begin
      if EscapeNext then
        EscapeNext := False
      else if Ch = '\' then
        EscapeNext := True
      else if Ch = '"' then
        InString := False;
    end
    else
    begin
      case Ch of
        '"': InString := True;
        '{': Inc(CurlyCount);
        '}': Dec(CurlyCount);
        '[': Inc(SquareCount);
        ']': Dec(SquareCount);
      end;

      if (CurlyCount = 0) and (SquareCount = 0) then
      begin
        Result := Trim(Copy(AText, StartPos, I - StartPos + 1));
        Exit;
      end;
    end;
  end;

  raise Exception.Create('The JSON returned by AI is incomplete.');
end;

function TAIProjectSpecification.BuildSpecificationPrompt(
  const AProjectName, AGoal, AConstraints, ADeliverables: string): string;
begin
  Result :=
    'Atue como analista de sistemas e gerente de projetos.' + sLineBreak +
    'Com base na descrição abaixo, gere a especificação inicial do projeto.' + sLineBreak +
    'A especificação deve ser útil para um projeto Lazarus / Free Pascal com IA.' + sLineBreak +
    sLineBreak +
    'Nome do projeto: ' + AProjectName + sLineBreak +
    'Objetivo informado: ' + AGoal + sLineBreak +
    'Restrições informadas: ' + AConstraints + sLineBreak +
    'Entregáveis esperados: ' + ADeliverables + sLineBreak +
    sLineBreak +
    'REGRAS OBRIGATÓRIAS:' + sLineBreak +
    '1. Responda somente com JSON puro.' + sLineBreak +
    '2. Não use Markdown.' + sLineBreak +
    '3. Não use ```json.' + sLineBreak +
    '4. Não escreva explicações antes ou depois.' + sLineBreak +
    '5. A resposta deve começar com { e terminar com }.' + sLineBreak +
    '6. Use texto em português do Brasil.' + sLineBreak +
    sLineBreak +
    'Formato obrigatório:' + sLineBreak +
    '{' + sLineBreak +
    '  "project": {' + sLineBreak +
    '    "name": "",' + sLineBreak +
    '    "description": "",' + sLineBreak +
    '    "goal": "",' + sLineBreak +
    '    "context": "",' + sLineBreak +
    '    "scope": "",' + sLineBreak +
    '    "constraints": "",' + sLineBreak +
    '    "expected_deliverables": ""' + sLineBreak +
    '  },' + sLineBreak +
    '  "agile_documents": {' + sLineBreak +
    '    "business_vision": "",' + sLineBreak +
    '    "functional_requirements": [' + sLineBreak +
    '      {"id":"RF001","title":"","description":"","priority":"alta","status":"draft"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "non_functional_requirements": [' + sLineBreak +
    '      {"id":"RNF001","title":"","description":"","priority":"alta","status":"draft"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "stakeholders": [' + sLineBreak +
    '      {"name":"","role":"","responsibility":"","interest_level":"medio","influence_level":"medio"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "risk_map": [' + sLineBreak +
    '      {"id":"R001","title":"","description":"","impact":"medio","probability":"media","mitigation":"","status":"open"}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "epics": [' + sLineBreak +
    '      {"id":"E001","title":"","description":""}' + sLineBreak +
    '    ],' + sLineBreak +
    '    "user_stories": [' + sLineBreak +
    '      {"id":"US001","title":"","description":"","acceptance_criteria":""}' + sLineBreak +
    '    ]' + sLineBreak +
    '  }' + sLineBreak +
    '}';
end;

procedure TAIProjectSpecification.MergeSpecification(AJSON: TJSONObject);
var
  LProjectSrc: TJSONObject;
  LDocsSrc: TJSONObject;
  LProjectDest: TJSONObject;
  LDocsDest: TJSONObject;
begin
  if not Assigned(AJSON) then
    Exit;

  FProject.EnsureProjectStructure;
  EnsureAgileDocuments;

  LProjectSrc := TJSONObject(AJSON.FindPath('project'));
  LDocsSrc := TJSONObject(AJSON.FindPath('agile_documents'));

  LProjectDest := TJSONObject(FProject.ProjectData.FindPath('project'));
  LDocsDest := TJSONObject(FProject.ProjectData.FindPath('agile_documents'));

  if Assigned(LProjectSrc) and Assigned(LProjectDest) then
  begin
    CopyJSONField(LProjectSrc, LProjectDest, 'name');
    CopyJSONField(LProjectSrc, LProjectDest, 'description');
    CopyJSONField(LProjectSrc, LProjectDest, 'goal');
    CopyJSONField(LProjectSrc, LProjectDest, 'context');
    CopyJSONField(LProjectSrc, LProjectDest, 'scope');
    CopyJSONField(LProjectSrc, LProjectDest, 'constraints');
    CopyJSONField(LProjectSrc, LProjectDest, 'expected_deliverables');

    FProject.ProjectName := LProjectDest.Get('name', FProject.ProjectName);
    FProject.Description := LProjectDest.Get('description', FProject.Description);
    FProject.Goal := LProjectDest.Get('goal', FProject.Goal);
    FProject.Context := LProjectDest.Get('context', FProject.Context);
    FProject.Scope := LProjectDest.Get('scope', FProject.Scope);
    FProject.Constraints := LProjectDest.Get('constraints', FProject.Constraints);
    FProject.ExpectedDeliverables := LProjectDest.Get('expected_deliverables', FProject.ExpectedDeliverables);
  end;

  if Assigned(LDocsSrc) and Assigned(LDocsDest) then
  begin
    CopyJSONField(LDocsSrc, LDocsDest, 'business_vision');
    CopyJSONField(LDocsSrc, LDocsDest, 'functional_requirements');
    CopyJSONField(LDocsSrc, LDocsDest, 'non_functional_requirements');
    CopyJSONField(LDocsSrc, LDocsDest, 'stakeholders');
    CopyJSONField(LDocsSrc, LDocsDest, 'risk_map');
    CopyJSONField(LDocsSrc, LDocsDest, 'epics');
    CopyJSONField(LDocsSrc, LDocsDest, 'user_stories');
  end;
end;

function TAIProjectSpecification.GenerateSpecification(
  const AProjectName, AGoal, AConstraints, ADeliverables: string): Boolean;
var
  LCleanJSON: string;
  LData: TJSONData;
begin
  Result := False;
  FLastError := '';
  FLastPrompt := '';
  FLastResponse := '';

  try
    if not EnsureReady then
      Exit;

    if Trim(AGoal) = '' then
    begin
      FLastError := 'Project goal is empty.';
      Exit;
    end;

    FLastPrompt := BuildSpecificationPrompt(
      AProjectName,
      AGoal,
      AConstraints,
      ADeliverables
    );

    FLastResponse := FProject.ExecuteText(FLastPrompt);

    if Trim(FLastResponse) = '' then
    begin
      FLastError := 'AI returned an empty response.';
      Exit;
    end;

    if SameText(Trim(FLastResponse), 'ERROR') then
    begin
      FLastError := FProject.LastError;
      Exit;
    end;

    LCleanJSON := ExtractJSONFromAIResponse(FLastResponse);
    LData := GetJSON(LCleanJSON);

    try
      if not Assigned(LData) or (LData.JSONType <> jtObject) then
      begin
        FLastError := 'AI response is not a JSON object.';
        Exit;
      end;

      MergeSpecification(TJSONObject(LData));
      Result := True;
    finally
      LData.Free;
    end;

  except
    on E: Exception do
    begin
      FLastError := E.Message;
      Result := False;
    end;
  end;
end;

end.
