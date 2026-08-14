unit aievaluation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, Math, fpjson, jsonparser, chatgpt,
  aibase, LResources;

type
  TAIEvaluationCase = class
  private
    FSources: TStringList;
    FChunks: TStringList;
  public
    Name: string;
    Input: string;
    Expected: string;
    Actual: string;
    Context: string;
    Score: Double;
    Details: string;
    constructor Create;
    destructor Destroy; override;
    property Sources: TStringList read FSources;
    property Chunks: TStringList read FChunks;
  end;

  TAIEvaluationDataset = class(TAIBaseComponent)
  private
    FCases: TObjectList;
    function GetCount: Integer;
    function GetCase(AIndex: Integer): TAIEvaluationCase;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddCase(const AName, AInput, AExpected: string): TAIEvaluationCase;
    procedure Clear;
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
    property Count: Integer read GetCount;
    property Cases[AIndex: Integer]: TAIEvaluationCase read GetCase; default;
  end;

  TAILexicalEvaluator = class(TAIBaseComponent)
  public
    constructor Create(AOwner: TComponent); override;
    function EvaluateText(const AExpected, AActual: string): Double;
    function EvaluateCase(ACase: TAIEvaluationCase): Double;
    function EvaluateDataset(ADataset: TAIEvaluationDataset): Double;
    function EvaluateRAG(ACase: TAIEvaluationCase): Double;
  end;

  TAILLMJudge = class(TAIBaseComponent)
  private
    FChatGPT: TCHATGPT;
    FFallback: TAILexicalEvaluator;
    procedure SetChatGPT(AValue: TCHATGPT);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function EvaluateCase(ACase: TAIEvaluationCase): Double;
  published
    property ChatGPT: TCHATGPT read FChatGPT write SetChatGPT;
  end;

  TAIRegressionReporter = class(TAIBaseComponent)
  public
    constructor Create(AOwner: TComponent); override;
    function BuildReport(ABaseline, ACurrent: TAIEvaluationDataset;
      out ARawJSON: string): string;
  end;

procedure Register;

implementation

function ClampScore(AValue: Double): Double;
begin
  if AValue < 0 then Exit(0);
  if AValue > 1 then Exit(1);
  Result := AValue;
end;

function JSONString(AObject: TJSONObject; const AName: string): string;
var D: TJSONData;
begin
  Result := '';
  D := AObject.Find(AName);
  if Assigned(D) then Result := D.AsString;
end;

function JSONFloat(AObject: TJSONObject; const AName: string;
  ADefault: Double): Double;
var D: TJSONData;
begin
  Result := ADefault;
  D := AObject.Find(AName);
  if Assigned(D) then
    try Result := D.AsFloat; except Result := ADefault; end;
end;

function CaseToJSON(ACase: TAIEvaluationCase): TJSONObject;
var
  A: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.Add('name', ACase.Name);
  Result.Add('input', ACase.Input);
  Result.Add('expected', ACase.Expected);
  Result.Add('actual', ACase.Actual);
  Result.Add('context', ACase.Context);
  Result.Add('score', ACase.Score);
  Result.Add('details', ACase.Details);
  A := TJSONArray.Create;
  for I := 0 to ACase.Sources.Count - 1 do A.Add(ACase.Sources[I]);
  Result.Add('sources', A);
  A := TJSONArray.Create;
  for I := 0 to ACase.Chunks.Count - 1 do A.Add(ACase.Chunks[I]);
  Result.Add('chunks', A);
end;

procedure JSONToCase(AObject: TJSONObject; ACase: TAIEvaluationCase);
var
  A: TJSONArray;
  D: TJSONData;
  I: Integer;
begin
  ACase.Name := JSONString(AObject, 'name');
  ACase.Input := JSONString(AObject, 'input');
  ACase.Expected := JSONString(AObject, 'expected');
  ACase.Actual := JSONString(AObject, 'actual');
  ACase.Context := JSONString(AObject, 'context');
  ACase.Score := JSONFloat(AObject, 'score', 0);
  ACase.Details := JSONString(AObject, 'details');
  ACase.Sources.Clear;
  D := AObject.Find('sources');
  if Assigned(D) and (D.JSONType = jtArray) then
  begin
    A := TJSONArray(D);
    for I := 0 to A.Count - 1 do ACase.Sources.Add(A.Strings[I]);
  end;
  ACase.Chunks.Clear;
  D := AObject.Find('chunks');
  if Assigned(D) and (D.JSONType = jtArray) then
  begin
    A := TJSONArray(D);
    for I := 0 to A.Count - 1 do ACase.Chunks.Add(A.Strings[I]);
  end;
end;

procedure Register;
begin
  RegisterComponents('AI Evaluation', [TAIEvaluationDataset,
    TAILexicalEvaluator, TAILLMJudge, TAIRegressionReporter]);
end;

constructor TAIEvaluationCase.Create;
begin
  inherited Create;
  FSources := TStringList.Create;
  FChunks := TStringList.Create;
end;

destructor TAIEvaluationCase.Destroy;
begin
  FChunks.Free;
  FSources.Free;
  inherited Destroy;
end;

constructor TAIEvaluationDataset.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FCases := TObjectList.Create(True);
end;

destructor TAIEvaluationDataset.Destroy;
begin
  FCases.Free;
  inherited Destroy;
end;

function TAIEvaluationDataset.GetCount: Integer;
begin Result := FCases.Count; end;

function TAIEvaluationDataset.GetCase(AIndex: Integer): TAIEvaluationCase;
begin Result := TAIEvaluationCase(FCases[AIndex]); end;

function TAIEvaluationDataset.AddCase(const AName, AInput,
  AExpected: string): TAIEvaluationCase;
begin
  Result := TAIEvaluationCase.Create;
  Result.Name := AName;
  Result.Input := AInput;
  Result.Expected := AExpected;
  FCases.Add(Result);
end;

procedure TAIEvaluationDataset.Clear;
begin FCases.Clear; end;

procedure TAIEvaluationDataset.SaveToFile(const AFileName: string);
var
  Root: TJSONArray;
  Lines: TStringList;
  I: Integer;
  Obj: TJSONObject;
begin
  ForceDirectories(ExtractFileDir(ExpandFileName(AFileName)));
  if SameText(ExtractFileExt(AFileName), '.jsonl') then
  begin
    Lines := TStringList.Create;
    try
      for I := 0 to Count - 1 do
      begin
        Obj := CaseToJSON(Cases[I]);
        try Lines.Add(Obj.AsJSON); finally Obj.Free; end;
      end;
      Lines.SaveToFile(AFileName);
    finally
      Lines.Free;
    end;
  end
  else
  begin
    Root := TJSONArray.Create;
    try
      for I := 0 to Count - 1 do Root.Add(CaseToJSON(Cases[I]));
      Lines := TStringList.Create;
      try Lines.Text := Root.FormatJSON; Lines.SaveToFile(AFileName); finally Lines.Free; end;
    finally
      Root.Free;
    end;
  end;
end;

procedure TAIEvaluationDataset.LoadFromFile(const AFileName: string);
var
  Lines: TStringList;
  Data: TJSONData;
  Arr: TJSONArray;
  Obj: TJSONObject;
  C: TAIEvaluationCase;
  I: Integer;
begin
  Clear;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(AFileName);
    if SameText(ExtractFileExt(AFileName), '.jsonl') then
    begin
      for I := 0 to Lines.Count - 1 do
        if Trim(Lines[I]) <> '' then
        begin
          Data := GetJSON(Lines[I]);
          try
            if Data.JSONType <> jtObject then
              raise Exception.CreateFmt('Linha JSONL %d nao e um objeto.', [I + 1]);
            C := AddCase('', '', '');
            JSONToCase(TJSONObject(Data), C);
          finally Data.Free; end;
        end;
    end
    else
    begin
      Data := GetJSON(Lines.Text);
      try
        if Data.JSONType <> jtArray then
          raise Exception.Create('Dataset JSON deve ser um array.');
        Arr := TJSONArray(Data);
        for I := 0 to Arr.Count - 1 do
        begin
          if Arr.Items[I].JSONType <> jtObject then Continue;
          Obj := TJSONObject(Arr.Items[I]);
          C := AddCase('', '', '');
          JSONToCase(Obj, C);
        end;
      finally Data.Free; end;
    end;
  finally
    Lines.Free;
  end;
end;

constructor TAILexicalEvaluator.Create(AOwner: TComponent);
begin inherited Create(AOwner); FCategory := ccModel; end;

procedure BuildTokenSet(const AText: string; ATokens: TStringList);
var
  S, Token: string;
  C: Char;
  I: Integer;
begin
  ATokens.Clear;
  ATokens.Sorted := True;
  ATokens.Duplicates := dupIgnore;
  S := LowerCase(AText);
  Token := '';
  for I := 1 to Length(S) do
  begin
    C := S[I];
    if C in ['a'..'z', '0'..'9'] then Token := Token + C
    else if Token <> '' then begin ATokens.Add(Token); Token := ''; end;
  end;
  if Token <> '' then ATokens.Add(Token);
end;

function TAILexicalEvaluator.EvaluateText(const AExpected,
  AActual: string): Double;
var
  E, A: TStringList;
  I, Common: Integer;
  Precision, Recall: Double;
begin
  E := TStringList.Create;
  A := TStringList.Create;
  try
    BuildTokenSet(AExpected, E);
    BuildTokenSet(AActual, A);
    if (E.Count = 0) and (A.Count = 0) then Exit(1);
    if (E.Count = 0) or (A.Count = 0) then Exit(0);
    Common := 0;
    for I := 0 to E.Count - 1 do if A.IndexOf(E[I]) >= 0 then Inc(Common);
    Precision := Common / A.Count;
    Recall := Common / E.Count;
    if Precision + Recall = 0 then Result := 0
    else Result := 2 * Precision * Recall / (Precision + Recall);
  finally
    A.Free;
    E.Free;
  end;
end;

function TAILexicalEvaluator.EvaluateCase(ACase: TAIEvaluationCase): Double;
begin
  Result := EvaluateText(ACase.Expected, ACase.Actual);
  ACase.Score := Result;
  ACase.Details := 'lexical_f1';
end;

function TAILexicalEvaluator.EvaluateDataset(
  ADataset: TAIEvaluationDataset): Double;
var I: Integer;
begin
  Result := 0;
  if ADataset.Count = 0 then Exit;
  for I := 0 to ADataset.Count - 1 do Result := Result + EvaluateCase(ADataset[I]);
  Result := Result / ADataset.Count;
end;

function TAILexicalEvaluator.EvaluateRAG(ACase: TAIEvaluationCase): Double;
var
  Evidence, SourcesText: string;
  I: Integer;
  AnswerScore, EvidenceScore: Double;
begin
  Evidence := ACase.Context;
  for I := 0 to ACase.Chunks.Count - 1 do Evidence := Evidence + ' ' + ACase.Chunks[I];
  SourcesText := '';
  for I := 0 to ACase.Sources.Count - 1 do SourcesText := SourcesText + ' ' + ACase.Sources[I];
  AnswerScore := EvaluateText(ACase.Expected, ACase.Actual);
  EvidenceScore := EvaluateText(ACase.Expected, Evidence + SourcesText);
  Result := ClampScore((AnswerScore * 0.7) + (EvidenceScore * 0.3));
  ACase.Score := Result;
  ACase.Details := Format('rag(answer=%.4f,evidence=%.4f,chunks=%d,sources=%d)',
    [AnswerScore, EvidenceScore, ACase.Chunks.Count, ACase.Sources.Count]);
end;

constructor TAILLMJudge.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccModel;
  FFallback := TAILexicalEvaluator.Create(nil);
end;

destructor TAILLMJudge.Destroy;
begin FFallback.Free; inherited Destroy; end;

procedure TAILLMJudge.SetChatGPT(AValue: TCHATGPT);
begin
  if FChatGPT = AValue then Exit;
  if Assigned(FChatGPT) then FChatGPT.RemoveFreeNotification(Self);
  FChatGPT := AValue;
  if Assigned(FChatGPT) then FChatGPT.FreeNotification(Self);
end;

procedure TAILLMJudge.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FChatGPT) then FChatGPT := nil;
end;

function TAILLMJudge.EvaluateCase(ACase: TAIEvaluationCase): Double;
var
  LJudgePrompt: string;
  Data: TJSONData;
  Obj: TJSONObject;
begin
  if not Assigned(FChatGPT) then
  begin
    Result := FFallback.EvaluateCase(ACase);
    ACase.Details := 'fallback:' + ACase.Details;
    Exit;
  end;
  LJudgePrompt := 'Avalie de 0 a 1. Retorne somente JSON {"score":0.0,"reason":"..."}.' +
    LineEnding + 'Entrada: ' + ACase.Input + LineEnding + 'Esperado: ' +
    ACase.Expected + LineEnding + 'Obtido: ' + ACase.Actual;
  if not FChatGPT.SendQuestion(LJudgePrompt) then
  begin
    Result := FFallback.EvaluateCase(ACase);
    ACase.Details := 'fallback:llm_error';
    Exit;
  end;
  try
    Data := GetJSON(FChatGPT.Response);
    try
      if Data.JSONType <> jtObject then raise Exception.Create('judge_not_object');
      Obj := TJSONObject(Data);
      Result := ClampScore(JSONFloat(Obj, 'score', -1));
      if JSONFloat(Obj, 'score', -1) < 0 then raise Exception.Create('judge_no_score');
      ACase.Score := Result;
      ACase.Details := 'llm_judge:' + JSONString(Obj, 'reason');
    finally Data.Free; end;
  except
    Result := FFallback.EvaluateCase(ACase);
    ACase.Details := 'fallback:invalid_llm_response';
  end;
end;

constructor TAIRegressionReporter.Create(AOwner: TComponent);
begin inherited Create(AOwner); FCategory := ccModel; end;

function TAIRegressionReporter.BuildReport(ABaseline,
  ACurrent: TAIEvaluationDataset; out ARawJSON: string): string;
var
  Root, Item: TJSONObject;
  Items: TJSONArray;
  I, PairCount, Regressions, Improvements: Integer;
  BaseScore, CurrentScore, Delta, TotalDelta: Double;
  Lines: TStringList;
begin
  PairCount := Min(ABaseline.Count, ACurrent.Count);
  Regressions := 0;
  Improvements := 0;
  TotalDelta := 0;
  Root := TJSONObject.Create;
  Lines := TStringList.Create;
  try
    Items := TJSONArray.Create;
    Root.Add('cases', Items);
    for I := 0 to PairCount - 1 do
    begin
      BaseScore := ABaseline[I].Score;
      CurrentScore := ACurrent[I].Score;
      Delta := CurrentScore - BaseScore;
      TotalDelta := TotalDelta + Delta;
      if Delta < -0.000001 then Inc(Regressions)
      else if Delta > 0.000001 then Inc(Improvements);
      Item := TJSONObject.Create;
      Item.Add('name', ACurrent[I].Name);
      Item.Add('baseline', BaseScore);
      Item.Add('current', CurrentScore);
      Item.Add('delta', Delta);
      Items.Add(Item);
      Lines.Add(Format('%s: %.4f -> %.4f (%+.4f)',
        [ACurrent[I].Name, BaseScore, CurrentScore, Delta]));
    end;
    Root.Add('pair_count', PairCount);
    Root.Add('regressions', Regressions);
    Root.Add('improvements', Improvements);
    if PairCount > 0 then Root.Add('mean_delta', TotalDelta / PairCount)
    else Root.Add('mean_delta', 0.0);
    ARawJSON := Root.FormatJSON;
    Result := Format('Regression report: %d cases, %d regressions, %d improvements.',
      [PairCount, Regressions, Improvements]);
    if Lines.Count > 0 then Result := Result + LineEnding + Lines.Text;
  finally
    Lines.Free;
    Root.Free;
  end;
end;

initialization
  {$I aievaluation_icon.lrs}

end.
