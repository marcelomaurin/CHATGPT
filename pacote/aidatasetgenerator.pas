unit aidatasetgenerator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, NeuralNetwork;

type
  TDatasetItem = class
  private
    FInput: string;
    FOutput: string;
  public
    constructor Create(const AInput, AOutput: string);
    property Input: string read FInput write FInput;
    property Output: string read FOutput write FOutput;
  end;

  { TAIDatasetGenerator }

  TAIDatasetGenerator = class(TComponent)
  private
    FItems: TList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    // Métodos para gerenciamento de linhas de treino
    procedure AddDataRow(const AInput, AOutput: string);
    procedure Clear;
    function Count: Integer;

    // Salva no formato padrão JSONL (JSON Lines) para Fine-Tuning de LLMs (OpenAI, Ollama)
    procedure SaveAsJSONL(const AFileName: string);

    // Salva no formato padrão CSV para uso em Redes Neurais clássicas
    procedure SaveAsCSV(const AFileName: string; const ADelimiter: Char = ';');

    // Carrega dados de um arquivo CSV diretamente para matrizes de treinamento compatíveis com TNeuralNetwork
    procedure LoadFromCSV(const AFileName: string; out LInputs, LTargets: TMatrix;
      LInputCols, LTargetCols: Integer; const ADelimiter: Char = ';');
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA', [TAIDatasetGenerator]);
end;

constructor TDatasetItem.Create(const AInput, AOutput: string);
begin
  inherited Create;
  FInput := AInput;
  FOutput := AOutput;
end;

constructor TAIDatasetGenerator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TList.Create;
end;

destructor TAIDatasetGenerator.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TAIDatasetGenerator.AddDataRow(const AInput, AOutput: string);
begin
  FItems.Add(TDatasetItem.Create(AInput, AOutput));
end;

procedure TAIDatasetGenerator.Clear;
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    TDatasetItem(FItems[i]).Free;
  FItems.Clear;
end;

function TAIDatasetGenerator.Count: Integer;
begin
  Result := FItems.Count;
end;

procedure TAIDatasetGenerator.SaveAsJSONL(const AFileName: string);
var
  F: TextFile;
  i: Integer;
  Item: TDatasetItem;
  RootObj, MsgSystem, MsgUser, MsgAssistant: TJSONObject;
  MsgsArray: TJSONArray;
  JSONLine: string;
begin
  AssignFile(F, AFileName);
  Rewrite(F);
  try
    for i := 0 to FItems.Count - 1 do
    begin
      Item := TDatasetItem(FItems[i]);

      // Formato oficial do OpenAI fine-tuning: {"messages": [{"role": "system", "content": "You are..."}, {"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]}
      RootObj := TJSONObject.Create;
      try
        MsgsArray := TJSONArray.Create;
        RootObj.Add('messages', MsgsArray);

        MsgSystem := TJSONObject.Create;
        MsgSystem.Add('role', 'system');
        MsgSystem.Add('content', 'Você é um assistente de IA.');
        MsgsArray.Add(MsgSystem);

        MsgUser := TJSONObject.Create;
        MsgUser.Add('role', 'user');
        MsgUser.Add('content', Item.Input);
        MsgsArray.Add(MsgUser);

        MsgAssistant := TJSONObject.Create;
        MsgAssistant.Add('role', 'assistant');
        MsgAssistant.Add('content', Item.Output);
        MsgsArray.Add(MsgAssistant);

        JSONLine := RootObj.AsJSON;
        Writeln(F, JSONLine);
      finally
        RootObj.Free;
      end;
    end;
  finally
    CloseFile(F);
  end;
end;

procedure TAIDatasetGenerator.SaveAsCSV(const AFileName: string; const ADelimiter: Char);
var
  F: TextFile;
  i: Integer;
  Item: TDatasetItem;
begin
  AssignFile(F, AFileName);
  Rewrite(F);
  try
    // Cabeçalho
    Writeln(F, 'input' + ADelimiter + 'output');
    for i := 0 to FItems.Count - 1 do
    begin
      Item := TDatasetItem(FItems[i]);
      Writeln(F, StringReplace(Item.Input, ADelimiter, ' ', [rfReplaceAll]) +
        ADelimiter +
        StringReplace(Item.Output, ADelimiter, ' ', [rfReplaceAll]));
    end;
  finally
    CloseFile(F);
  end;
end;

procedure TAIDatasetGenerator.LoadFromCSV(const AFileName: string; out LInputs, LTargets: TMatrix;
  LInputCols, LTargetCols: Integer; const ADelimiter: Char);
var
  F: TextFile;
  Line: string;
  Parts: TStringList;
  RowIndex, Col: Integer;
begin
  SetLength(LInputs, 0);
  SetLength(LTargets, 0);

  if not FileExists(AFileName) then
    raise Exception.CreateFmt('Arquivo de treino CSV não encontrado: %s', [AFileName]);

  Parts := TStringList.Create;
  try
    AssignFile(F, AFileName);
    Reset(F);
    try
      // Pula a primeira linha de cabeçalho
      if not Eof(F) then
        Readln(F, Line);

      RowIndex := 0;
      while not Eof(F) do
      begin
        Readln(F, Line);
        if Trim(Line) = '' then
          Continue;

        Parts.Clear;
        ExtractStrings([ADelimiter], [], PChar(Line), Parts);
        if Parts.Count < (LInputCols + LTargetCols) then
          Continue;

        SetLength(LInputs, RowIndex + 1);
        SetLength(LInputs[RowIndex], LInputCols);

        SetLength(LTargets, RowIndex + 1);
        SetLength(LTargets[RowIndex], LTargetCols);

        for Col := 0 to LInputCols - 1 do
          LInputs[RowIndex, Col] := StrToFloatDef(Parts[Col], 0.0);

        for Col := 0 to LTargetCols - 1 do
          LTargets[RowIndex, Col] := StrToFloatDef(Parts[LInputCols + Col], 0.0);

        Inc(RowIndex);
      end;
    finally
      CloseFile(F);
    end;
  finally
    Parts.Free;
  end;
end;

end.
