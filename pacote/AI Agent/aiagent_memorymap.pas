unit aiagent_memorymap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, fpjson, jsonparser, TypInfo, aibase,
  aiagent_flowevents, LResources;

type
  { Status of map step }
  TAIAgentMemoryStepStatus = (
    semIniciada,
    semEmAnalise,
    semAguardandoInformacao,
    semConcluida,
    semExecutada,
    semFalhou,
    semCancelada
  );

  { TAIAnalysisQuestionItem }
  TAIAnalysisQuestionItem = class(TCollectionItem)
  private
    FOrdem: Integer;
    FPergunta: string;
    FResposta: string;
    FAnalise: string;
    FConfianca: Double;
    FOrigem: string;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property Ordem: Integer read FOrdem write FOrdem;
    property Pergunta: string read FPergunta write FPergunta;
    property Resposta: string read FResposta write FResposta;
    property Analise: string read FAnalise write FAnalise;
    property Confianca: Double read FConfianca write FConfianca;
    property Origem: string read FOrigem write FOrigem;
  end;

  { TAIAnalysisQuestionCollection }
  TAIAnalysisQuestionCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIAnalysisQuestionItem;
    procedure SetItem(Index: Integer; Value: TAIAnalysisQuestionItem);
  public
    constructor Create;
    function Add: TAIAnalysisQuestionItem;
    function AddPergunta(
      const APergunta: string;
      const AResposta: string;
      const AAnalise: string;
      const AOrigem: string = 'LLM';
      const AConfianca: Double = 0
    ): TAIAnalysisQuestionItem;
    function AsText: string;
    property Items[Index: Integer]: TAIAnalysisQuestionItem read GetItem write SetItem; default;
  end;

  { TAIAgentMemoryMapItem }
  TAIAgentMemoryMapItem = class(TCollectionItem)
  private
    FOrdem: Integer;
    FOrdemPai: Integer;
    FDataHoraInicio: TDateTime;
    FDataHoraFim: TDateTime;
    FNomeAgente: string;
    FTipoAgente: TAITipoAgenteMapa;
    FStatus: TAIAgentMemoryStepStatus;
    FSolicitacaoOriginal: string;
    FPedidoRecebido: string;
    FPedidoNormalizado: string;
    FContextoRecebido: string;
    FAnalise: string;
    FExplicacao: string;
    FAcaoTomada: string;
    FParametrosAcao: TStrings;
    FSaidaGerada: string;
    FResumoParaProximoAgente: string;
    FInformacoesPreservadas: TStrings;
    FInformacoesPerdidas: TStrings;
    FInformacoesNovas: TStrings;
    FAlertas: TStrings;
    FPerguntasAnalises: TAIAnalysisQuestionCollection;
    FConfianca: Double;
    FErro: string;
    FRawJSON: string;
    procedure SetParametrosAcao(AValue: TStrings);
    procedure SetInformacoesPreservadas(AValue: TStrings);
    procedure SetInformacoesPerdidas(AValue: TStrings);
    procedure SetInformacoesNovas(AValue: TStrings);
    procedure SetAlertas(AValue: TStrings);
    procedure SetPerguntasAnalises(AValue: TAIAnalysisQuestionCollection);
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    procedure Clear;
    function AsText: string;
    function AsJSON: string;
    function HasInformationLoss: Boolean;
    procedure AddPerguntaAnalise(
      const APergunta: string;
      const AResposta: string;
      const AAnalise: string;
      const AOrigem: string = 'LLM';
      const AConfianca: Double = 0
    );
    procedure AddInformacaoPreservada(const AInfo: string);
    procedure AddInformacaoPerdida(const AInfo: string);
    procedure AddInformacaoNova(const AInfo: string);
    procedure AddAlerta(const AAlerta: string);
  published
    property Ordem: Integer read FOrdem write FOrdem;
    property OrdemPai: Integer read FOrdemPai write FOrdemPai;
    property DataHoraInicio: TDateTime read FDataHoraInicio write FDataHoraInicio;
    property DataHoraFim: TDateTime read FDataHoraFim write FDataHoraFim;
    property NomeAgente: string read FNomeAgente write FNomeAgente;
    property TipoAgente: TAITipoAgenteMapa read FTipoAgente write FTipoAgente;
    property Status: TAIAgentMemoryStepStatus read FStatus write FStatus;
    property SolicitacaoOriginal: string read FSolicitacaoOriginal write FSolicitacaoOriginal;
    property PedidoRecebido: string read FPedidoRecebido write FPedidoRecebido;
    property PedidoNormalizado: string read FPedidoNormalizado write FPedidoNormalizado;
    property ContextoRecebido: string read FContextoRecebido write FContextoRecebido;
    property Analise: string read FAnalise write FAnalise;
    property Explicacao: string read FExplicacao write FExplicacao;
    property AcaoTomada: string read FAcaoTomada write FAcaoTomada;
    property ParametrosAcao: TStrings read FParametrosAcao write SetParametrosAcao;
    property SaidaGerada: string read FSaidaGerada write FSaidaGerada;
    property ResumoParaProximoAgente: string read FResumoParaProximoAgente write FResumoParaProximoAgente;
    property InformacoesPreservadas: TStrings read FInformacoesPreservadas write SetInformacoesPreservadas;
    property InformacoesPerdidas: TStrings read FInformacoesPerdidas write SetInformacoesPerdidas;
    property InformacoesNovas: TStrings read FInformacoesNovas write SetInformacoesNovas;
    property Alertas: TStrings read FAlertas write SetAlertas;
    property PerguntasAnalises: TAIAnalysisQuestionCollection read FPerguntasAnalises write SetPerguntasAnalises;
    property Confianca: Double read FConfianca write FConfianca;
    property Erro: string read FErro write FErro;
    property RawJSON: string read FRawJSON write FRawJSON;
  end;

  { TAIAgentMemoryMapCollection }
  TAIAgentMemoryMapCollection = class(TCollection)
  private
    FOwnerComponent: TComponent;
    function GetItem(Index: Integer): TAIAgentMemoryMapItem;
    procedure SetItem(Index: Integer; Value: TAIAgentMemoryMapItem);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    function Add: TAIAgentMemoryMapItem;
    function FindByOrder(AOrdem: Integer): TAIAgentMemoryMapItem;
    function FindLastByAgentName(const ANomeAgente: string): TAIAgentMemoryMapItem;
    function FindLastByAgentType(ATipo: TAITipoAgenteMapa): TAIAgentMemoryMapItem;
    function AsText: string;
    property Items[Index: Integer]: TAIAgentMemoryMapItem read GetItem write SetItem; default;
  end;

  { Events for TAIAgentMemoryMap }
  TAIMapaBeforeCreateStepEvent = procedure(
    Sender: TObject;
    const ANomeAgente: string;
    ATipoAgente: TAITipoAgenteMapa;
    var ACanCreate: Boolean
  ) of object;

  TAIMapaStepEvent = procedure(
    Sender: TObject;
    AItem: TAIAgentMemoryMapItem
  ) of object;

  TAIMapaInformationLossEvent = procedure(
    Sender: TObject;
    AItem: TAIAgentMemoryMapItem;
    const ALostInfo: string
  ) of object;

  TAIMapaLogEvent = procedure(
    Sender: TObject;
    const AMessage: string
  ) of object;

  { TAIAgentMemoryMap Component }
  TAIAgentMemoryMap = class(TAIBaseComponent)
  private
    FSessionId: string;
    FFlowName: string;
    FSolicitacaoOriginal: string;
    FUsuario: string;
    FOrigem: string;
    FAutoIncrementOrder: Boolean;
    FCurrentOrder: Integer;
    FMaxItems: Integer;
    FStoreRawJSON: Boolean;
    FStoreFullPrompt: Boolean;
    FStoreFullResponse: Boolean;
    FDetectInformationLoss: Boolean;
    FRedactSensitiveData: Boolean;
    FItems: TAIAgentMemoryMapCollection;
    FLastItem: TAIAgentMemoryMapItem;
    FLastWarning: string;
    // Events
    FOnBeforeCreateStep: TAIMapaBeforeCreateStepEvent;
    FOnAfterCreateStep: TAIMapaStepEvent;
    FOnBeforeCloseStep: TAIMapaStepEvent;
    FOnAfterCloseStep: TAIMapaStepEvent;
    FOnInformationLossDetected: TAIMapaInformationLossEvent;
    FOnMemoryMapLog: TAIMapaLogEvent;
    procedure SetItems(AValue: TAIAgentMemoryMapCollection);
    procedure SetMaxItems(AValue: Integer);
    procedure TrimItemsToMax;
    procedure UpdateCurrentOrderFromItems;
    function NewSessionId: string;
    function SafeText(const AText: string): string;
    procedure DoMapLog(const AMessage: string);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StartFlow(
      const ASolicitacaoOriginal: string;
      const AFlowName: string = '';
      const AUsuario: string = '';
      const AOrigem: string = ''
    );
    function BeginAgentStep(
      const ANomeAgente: string;
      ATipoAgente: TAITipoAgenteMapa;
      const APedidoRecebido: string;
      const AContextoRecebido: string = '';
      AOrdemPai: Integer = 0
    ): TAIAgentMemoryMapItem;
    procedure EndAgentStep(
      AItem: TAIAgentMemoryMapItem;
      const AAnalise: string;
      const AExplicacao: string;
      const AAcaoTomada: string;
      const ASaidaGerada: string;
      const AResumoParaProximoAgente: string = ''
    );
    procedure AddQuestion(
      AItem: TAIAgentMemoryMapItem;
      const APergunta: string;
      const AResposta: string;
      const AAnalise: string;
      const AOrigem: string = 'LLM';
      const AConfianca: Double = 0
    );
    procedure AddActionParam(
      AItem: TAIAgentMemoryMapItem;
      const AName: string;
      const AValue: string
    );
    function CheckInformationLoss(
      AItem: TAIAgentMemoryMapItem;
      out ALostInfo: string
    ): Boolean;
    function BuildContextForAgent(
      const ANomeAgente: string;
      ATipoAgente: TAITipoAgenteMapa;
      const AMaxSteps: Integer = 10
    ): string;
    function AsText: string;
    function AsJSON: string;
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromFile(const AFileName: string);
    // Runtime properties (not serialized in LFM)
    property SessionId: string read FSessionId write FSessionId;
    property FlowName: string read FFlowName write FFlowName;
    property SolicitacaoOriginal: string read FSolicitacaoOriginal write FSolicitacaoOriginal;
    property Usuario: string read FUsuario write FUsuario;
    property Origem: string read FOrigem write FOrigem;
    property CurrentOrder: Integer read FCurrentOrder write FCurrentOrder;
    property Items: TAIAgentMemoryMapCollection read FItems write SetItems;
    property LastItem: TAIAgentMemoryMapItem read FLastItem;
    property LastWarning: string read FLastWarning write FLastWarning;
  published
    property AutoIncrementOrder: Boolean read FAutoIncrementOrder write FAutoIncrementOrder default True;
    property MaxItems: Integer read FMaxItems write SetMaxItems default 100;
    property StoreRawJSON: Boolean read FStoreRawJSON write FStoreRawJSON default True;
    property StoreFullPrompt: Boolean read FStoreFullPrompt write FStoreFullPrompt default False;
    property StoreFullResponse: Boolean read FStoreFullResponse write FStoreFullResponse default False;
    property DetectInformationLoss: Boolean read FDetectInformationLoss write FDetectInformationLoss default True;
    property RedactSensitiveData: Boolean read FRedactSensitiveData write FRedactSensitiveData default True;
    // Events
    property OnBeforeCreateStep: TAIMapaBeforeCreateStepEvent read FOnBeforeCreateStep write FOnBeforeCreateStep;
    property OnAfterCreateStep: TAIMapaStepEvent read FOnAfterCreateStep write FOnAfterCreateStep;
    property OnBeforeCloseStep: TAIMapaStepEvent read FOnBeforeCloseStep write FOnBeforeCloseStep;
    property OnAfterCloseStep: TAIMapaStepEvent read FOnAfterCloseStep write FOnAfterCloseStep;
    property OnInformationLossDetected: TAIMapaInformationLossEvent read FOnInformationLossDetected write FOnInformationLossDetected;
    property OnMemoryMapLog: TAIMapaLogEvent read FOnMemoryMapLog write FOnMemoryMapLog;
  end;


type
  TAIMapaDeMemoria = TAIAgentMemoryMap;
  TAIMapaDeMemoriaItem = TAIAgentMemoryMapItem;
  TAIMapaDeMemoriaCollection = TAIAgentMemoryMapCollection;
  TAIStatusEtapaMapa = TAIAgentMemoryStepStatus;
  TAIPerguntaAnaliseItem = TAIAnalysisQuestionItem;
  TAIPerguntaAnaliseCollection = TAIAnalysisQuestionCollection;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIAgentMemoryMap]);
  RegisterClassAlias(TAIAgentMemoryMap, 'TAIMapaDeMemoria');
end;

function DateTimeToJSONText(const AValue: TDateTime): string;
begin
  if AValue <= 0 then
    Result := ''
  else
    Result := FormatDateTime('yyyy"-"mm"-"dd"T"hh":"nn":"ss', AValue);
end;

function NormalizeForCompare(const S: string): string;
var
  R: string;
  I: Integer;
begin
  R := UTF8LowerCase(S);

  R := StringReplace(R, 'á', 'a', [rfReplaceAll]);
  R := StringReplace(R, 'à', 'a', [rfReplaceAll]);
  R := StringReplace(R, 'ã', 'a', [rfReplaceAll]);
  R := StringReplace(R, 'â', 'a', [rfReplaceAll]);
  R := StringReplace(R, 'ä', 'a', [rfReplaceAll]);

  R := StringReplace(R, 'é', 'e', [rfReplaceAll]);
  R := StringReplace(R, 'è', 'e', [rfReplaceAll]);
  R := StringReplace(R, 'ê', 'e', [rfReplaceAll]);
  R := StringReplace(R, 'ë', 'e', [rfReplaceAll]);

  R := StringReplace(R, 'í', 'i', [rfReplaceAll]);
  R := StringReplace(R, 'ì', 'i', [rfReplaceAll]);
  R := StringReplace(R, 'î', 'i', [rfReplaceAll]);
  R := StringReplace(R, 'ï', 'i', [rfReplaceAll]);

  R := StringReplace(R, 'ó', 'o', [rfReplaceAll]);
  R := StringReplace(R, 'ò', 'o', [rfReplaceAll]);
  R := StringReplace(R, 'õ', 'o', [rfReplaceAll]);
  R := StringReplace(R, 'ô', 'o', [rfReplaceAll]);
  R := StringReplace(R, 'ö', 'o', [rfReplaceAll]);

  R := StringReplace(R, 'ú', 'u', [rfReplaceAll]);
  R := StringReplace(R, 'ù', 'u', [rfReplaceAll]);
  R := StringReplace(R, 'û', 'u', [rfReplaceAll]);
  R := StringReplace(R, 'ü', 'u', [rfReplaceAll]);

  R := StringReplace(R, 'ç', 'c', [rfReplaceAll]);

  for I := 1 to Length(R) do
  begin
    if not (R[I] in ['a'..'z', '0'..'9']) then
      R[I] := ' ';
  end;

  while Pos('  ', R) > 0 do
    R := StringReplace(R, '  ', ' ', [rfReplaceAll]);

  Result := Trim(R);
end;

function IsStopWord(const AWord: string): Boolean;
const
  STOP_WORDS: array[0..45] of string = (
    'para', 'como', 'mais', 'esta', 'este', 'pela', 'pelo', 'pelos',
    'pelas', 'isso', 'esse', 'essa', 'aquele', 'aquela', 'uma', 'umas',
    'uns', 'com', 'sem', 'que', 'por', 'das', 'dos', 'nas', 'nos',
    'lhe', 'seu', 'sua', 'seus', 'suas', 'meu', 'minha', 'meus',
    'minhas', 'foi', 'era', 'ser', 'ter', 'tem', 'deve', 'deveria',
    'antes', 'depois', 'muito', 'pouco', 'sobre'
  );
var
  I: Integer;
begin
  Result := False;
  for I := Low(STOP_WORDS) to High(STOP_WORDS) do
  begin
    if AWord = STOP_WORDS[I] then
      Exit(True);
  end;
end;

function JSONStringArrayFromStrings(AStrings: TStrings): TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;
  if not Assigned(AStrings) then
    Exit;

  for I := 0 to AStrings.Count - 1 do
    Result.Add(AStrings[I]);
end;

procedure LoadStringsFromJSONArray(AStrings: TStrings; AData: TJSONData);
var
  I: Integer;
  Arr: TJSONArray;
begin
  if not Assigned(AStrings) then
    Exit;

  AStrings.Clear;

  if (AData = nil) or (AData.JSONType <> jtArray) then
    Exit;

  Arr := TJSONArray(AData);
  for I := 0 to Arr.Count - 1 do
    AStrings.Add(Arr.Items[I].AsString);
end;

function JSONGetString(AObj: TJSONObject; const AName, ADefault: string): string;
var
  D: TJSONData;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  D := AObj.Find(AName);
  if D <> nil then
    Result := D.AsString;
end;

function JSONGetInteger(AObj: TJSONObject; const AName: string; ADefault: Integer): Integer;
var
  D: TJSONData;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  D := AObj.Find(AName);
  if D <> nil then
    Result := D.AsInteger;
end;

function JSONGetFloat(AObj: TJSONObject; const AName: string; ADefault: Double): Double;
var
  D: TJSONData;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  D := AObj.Find(AName);
  if D <> nil then
    Result := D.AsFloat;
end;

function JSONGetBool(AObj: TJSONObject; const AName: string; ADefault: Boolean): Boolean;
var
  D: TJSONData;
begin
  Result := ADefault;
  if AObj = nil then
    Exit;

  D := AObj.Find(AName);
  if D <> nil then
    Result := D.AsBoolean;
end;

function CreatePerguntaJSONObject(AItem: TAIAnalysisQuestionItem): TJSONObject;
begin
  Result := TJSONObject.Create;
  if AItem = nil then
    Exit;

  Result.Add('ordem', AItem.Ordem);
  Result.Add('pergunta', AItem.Pergunta);
  Result.Add('resposta', AItem.Resposta);
  Result.Add('analise', AItem.Analise);
  Result.Add('origem', AItem.Origem);
  Result.Add('confianca', AItem.Confianca);
end;

function CreateMapaItemJSONObject(AItem: TAIAgentMemoryMapItem): TJSONObject;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  if AItem = nil then
    Exit;

  Result.Add('ordem', AItem.Ordem);
  Result.Add('ordem_pai', AItem.OrdemPai);
  Result.Add('data_hora_inicio', DateTimeToJSONText(AItem.DataHoraInicio));
  Result.Add('data_hora_inicio_value', AItem.DataHoraInicio);
  Result.Add('data_hora_fim', DateTimeToJSONText(AItem.DataHoraFim));
  Result.Add('data_hora_fim_value', AItem.DataHoraFim);
  Result.Add('nome_agente', AItem.NomeAgente);
  Result.Add('tipo_agente', Ord(AItem.TipoAgente));
  Result.Add('status', Ord(AItem.Status));
  Result.Add('solicitacao_original', AItem.SolicitacaoOriginal);
  Result.Add('pedido_recebido', AItem.PedidoRecebido);
  Result.Add('pedido_normalizado', AItem.PedidoNormalizado);
  Result.Add('contexto_recebido', AItem.ContextoRecebido);
  Result.Add('analise', AItem.Analise);
  Result.Add('explicacao', AItem.Explicacao);
  Result.Add('acao_tomada', AItem.AcaoTomada);
  Result.Add('saida_gerada', AItem.SaidaGerada);
  Result.Add('resumo_para_proximo_agente', AItem.ResumoParaProximoAgente);
  Result.Add('resumo', AItem.ResumoParaProximoAgente);
  Result.Add('confianca', AItem.Confianca);
  Result.Add('erro', AItem.Erro);
  Result.Add('raw_json', AItem.RawJSON);

  Result.Add('parametros_acao', JSONStringArrayFromStrings(AItem.ParametrosAcao));
  Result.Add('informacoes_preservadas', JSONStringArrayFromStrings(AItem.InformacoesPreservadas));
  Result.Add('informacoes_perdidas', JSONStringArrayFromStrings(AItem.InformacoesPerdidas));
  Result.Add('informacoes_novas', JSONStringArrayFromStrings(AItem.InformacoesNovas));
  Result.Add('alertas', JSONStringArrayFromStrings(AItem.Alertas));

  Arr := TJSONArray.Create;
  for I := 0 to AItem.PerguntasAnalises.Count - 1 do
    Arr.Add(CreatePerguntaJSONObject(AItem.PerguntasAnalises[I]));
  Result.Add('perguntas', Arr);
end;

procedure LoadPerguntasFromJSONArray(ACollection: TAIAnalysisQuestionCollection; AData: TJSONData);
var
  I: Integer;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Item: TAIAnalysisQuestionItem;
begin
  if not Assigned(ACollection) then
    Exit;

  ACollection.Clear;

  if (AData = nil) or (AData.JSONType <> jtArray) then
    Exit;

  Arr := TJSONArray(AData);
  for I := 0 to Arr.Count - 1 do
  begin
    if Arr.Items[I].JSONType <> jtObject then
      Continue;

    Obj := TJSONObject(Arr.Items[I]);
    Item := ACollection.Add;
    Item.Ordem := JSONGetInteger(Obj, 'ordem', I + 1);
    Item.Pergunta := JSONGetString(Obj, 'pergunta', '');
    Item.Resposta := JSONGetString(Obj, 'resposta', '');
    Item.Analise := JSONGetString(Obj, 'analise', '');
    Item.Origem := JSONGetString(Obj, 'origem', 'LLM');
    Item.Confianca := JSONGetFloat(Obj, 'confianca', 0.0);
  end;
end;

function RedactSensitiveText(const AText: string): string;
const
  SENSITIVE_KEYS: array[0..14] of string = (
    'token', 'password', 'senha', 'apikey', 'api_key', 'secret',
    'privatekey', 'private_key', 'authorization', 'cpf', 'cns',
    'rg', 'cartao', 'prontuario', 'paciente'
  );
var
  I, J, K, DigitCount: Integer;
  R, LowerLine, Key, Sequence, OutText: string;
  Lines: TStringList;
  Ch: Char;
  HasAt, HasDot: Boolean;
begin
  R := AText;

  Lines := TStringList.Create;
  try
    Lines.Text := R;
    for I := 0 to Lines.Count - 1 do
    begin
      LowerLine := UTF8LowerCase(Trim(Lines[I]));
      for J := Low(SENSITIVE_KEYS) to High(SENSITIVE_KEYS) do
      begin
        Key := SENSITIVE_KEYS[J];

        if (Pos(Key + '=', LowerLine) = 1) or
           (Pos(Key + ':', LowerLine) = 1) or
           (Pos(Key + ' =', LowerLine) = 1) or
           (Pos(Key + ' :', LowerLine) = 1) then
        begin
          if Pos('=', Lines[I]) > 0 then
            Lines[I] := Copy(Lines[I], 1, Pos('=', Lines[I])) + ' [REDACTED]'
          else if Pos(':', Lines[I]) > 0 then
            Lines[I] := Copy(Lines[I], 1, Pos(':', Lines[I])) + ' [REDACTED]'
          else
            Lines[I] := '[REDACTED]';
        end;
      end;
    end;
    R := Lines.Text;
  finally
    Lines.Free;
  end;

  { Redact e-mails in whitespace-delimited tokens. }
  Lines := TStringList.Create;
  try
    ExtractStrings([' ', #9, #10, #13], [], PChar(R), Lines);
    for I := 0 to Lines.Count - 1 do
    begin
      HasAt := Pos('@', Lines[I]) > 0;
      HasDot := Pos('.', Lines[I]) > 0;
      if HasAt and HasDot then
        R := StringReplace(R, Lines[I], '[EMAIL]', [rfReplaceAll]);
    end;
  finally
    Lines.Free;
  end;

  { Redact long numeric sequences such as CPF, CNS, phone, card and IDs. }
  OutText := '';
  I := 1;
  while I <= Length(R) do
  begin
    Ch := R[I];

    if Ch in ['0'..'9'] then
    begin
      Sequence := '';
      DigitCount := 0;
      K := I;

      while (K <= Length(R)) and (R[K] in ['0'..'9', '.', '-', '/', '(', ')', '+', ' ']) do
      begin
        Sequence := Sequence + R[K];
        if R[K] in ['0'..'9'] then
          Inc(DigitCount);
        Inc(K);
      end;

      if DigitCount >= 11 then
        OutText := OutText + '[DADO_NUMERICO]'
      else
        OutText := OutText + Sequence;

      I := K;
    end
    else
    begin
      OutText := OutText + Ch;
      Inc(I);
    end;
  end;

  Result := OutText;
end;

{ TAIAnalysisQuestionItem }

procedure TAIAnalysisQuestionItem.Assign(Source: TPersistent);
var
  S: TAIAnalysisQuestionItem;
begin
  if Source is TAIAnalysisQuestionItem then
  begin
    S := TAIAnalysisQuestionItem(Source);
    FOrdem := S.Ordem;
    FPergunta := S.Pergunta;
    FResposta := S.Resposta;
    FAnalise := S.Analise;
    FConfianca := S.Confianca;
    FOrigem := S.Origem;
  end
  else
    inherited Assign(Source);
end;

{ TAIAnalysisQuestionCollection }

constructor TAIAnalysisQuestionCollection.Create;
begin
  inherited Create(TAIAnalysisQuestionItem);
end;

function TAIAnalysisQuestionCollection.GetItem(Index: Integer): TAIAnalysisQuestionItem;
begin
  Result := TAIAnalysisQuestionItem(inherited GetItem(Index));
end;

procedure TAIAnalysisQuestionCollection.SetItem(Index: Integer; Value: TAIAnalysisQuestionItem);
begin
  inherited SetItem(Index, Value);
end;

function TAIAnalysisQuestionCollection.Add: TAIAnalysisQuestionItem;
begin
  Result := TAIAnalysisQuestionItem(inherited Add);
  Result.Ordem := Count;
end;

function TAIAnalysisQuestionCollection.AddPergunta(
  const APergunta: string;
  const AResposta: string;
  const AAnalise: string;
  const AOrigem: string;
  const AConfianca: Double
): TAIAnalysisQuestionItem;
begin
  Result := Add;
  Result.Pergunta := APergunta;
  Result.Resposta := AResposta;
  Result.Analise := AAnalise;
  Result.Origem := AOrigem;
  Result.Confianca := AConfianca;
end;

function TAIAnalysisQuestionCollection.AsText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
  begin
    Result := Result + Format(
      '  Question %d: %s' + sLineBreak +
      '  Answer: %s' + sLineBreak +
      '  Analysis: %s' + sLineBreak +
      '  Source: %s | Confidence: %.2f' + sLineBreak,
      [Items[I].Ordem, Items[I].Pergunta, Items[I].Resposta,
       Items[I].Analise, Items[I].Origem, Items[I].Confianca]
    );
  end;
end;

{ TAIAgentMemoryMapItem }

constructor TAIAgentMemoryMapItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FParametrosAcao := TStringList.Create;
  FInformacoesPreservadas := TStringList.Create;
  FInformacoesPerdidas := TStringList.Create;
  FInformacoesNovas := TStringList.Create;
  FAlertas := TStringList.Create;
  FPerguntasAnalises := TAIAnalysisQuestionCollection.Create;
  Clear;
end;

destructor TAIAgentMemoryMapItem.Destroy;
begin
  FParametrosAcao.Free;
  FInformacoesPreservadas.Free;
  FInformacoesPerdidas.Free;
  FInformacoesNovas.Free;
  FAlertas.Free;
  FPerguntasAnalises.Free;
  inherited Destroy;
end;

procedure TAIAgentMemoryMapItem.Assign(Source: TPersistent);
var
  S: TAIAgentMemoryMapItem;
begin
  if Source is TAIAgentMemoryMapItem then
  begin
    S := TAIAgentMemoryMapItem(Source);
    FOrdem := S.Ordem;
    FOrdemPai := S.OrdemPai;
    FDataHoraInicio := S.DataHoraInicio;
    FDataHoraFim := S.DataHoraFim;
    FNomeAgente := S.NomeAgente;
    FTipoAgente := S.TipoAgente;
    FStatus := S.Status;
    FSolicitacaoOriginal := S.SolicitacaoOriginal;
    FPedidoRecebido := S.PedidoRecebido;
    FPedidoNormalizado := S.PedidoNormalizado;
    FContextoRecebido := S.ContextoRecebido;
    FAnalise := S.Analise;
    FExplicacao := S.Explicacao;
    FAcaoTomada := S.AcaoTomada;
    FParametrosAcao.Assign(S.ParametrosAcao);
    FSaidaGerada := S.SaidaGerada;
    FResumoParaProximoAgente := S.ResumoParaProximoAgente;
    FInformacoesPreservadas.Assign(S.InformacoesPreservadas);
    FInformacoesPerdidas.Assign(S.InformacoesPerdidas);
    FInformacoesNovas.Assign(S.InformacoesNovas);
    FAlertas.Assign(S.Alertas);
    FPerguntasAnalises.Assign(S.PerguntasAnalises);
    FConfianca := S.Confianca;
    FErro := S.Erro;
    FRawJSON := S.RawJSON;
  end
  else
    inherited Assign(Source);
end;

procedure TAIAgentMemoryMapItem.Clear;
begin
  FOrdem := 0;
  FOrdemPai := 0;
  FDataHoraInicio := 0;
  FDataHoraFim := 0;
  FNomeAgente := '';
  FTipoAgente := tamIndefinido;
  FStatus := semIniciada;
  FSolicitacaoOriginal := '';
  FPedidoRecebido := '';
  FPedidoNormalizado := '';
  FContextoRecebido := '';
  FAnalise := '';
  FExplicacao := '';
  FAcaoTomada := '';
  FParametrosAcao.Clear;
  FSaidaGerada := '';
  FResumoParaProximoAgente := '';
  FInformacoesPreservadas.Clear;
  FInformacoesPerdidas.Clear;
  FInformacoesNovas.Clear;
  FAlertas.Clear;
  FPerguntasAnalises.Clear;
  FConfianca := 0.0;
  FErro := '';
  FRawJSON := '';
end;

function TAIAgentMemoryMapItem.AsText: string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine(Format('Order: %d (Parent: %d)', [FOrdem, FOrdemPai]));
    SB.AppendLine(Format('Agent: %s [Type: %d]', [FNomeAgente, Ord(FTipoAgente)]));
    SB.AppendLine('Status: ' + GetEnumName(TypeInfo(TAIAgentMemoryStepStatus), Ord(FStatus)));
    if FDataHoraInicio > 0 then SB.AppendLine('Start: ' + DateTimeToStr(FDataHoraInicio));
    if FDataHoraFim > 0 then SB.AppendLine('Fim: ' + DateTimeToStr(FDataHoraFim));
    if FSolicitacaoOriginal <> '' then SB.AppendLine('Original Request: ' + FSolicitacaoOriginal);
    if FPedidoRecebido <> '' then SB.AppendLine('Received Request: ' + FPedidoRecebido);
    if FPedidoNormalizado <> '' then SB.AppendLine('Normalized Request: ' + FPedidoNormalizado);
    if FContextoRecebido <> '' then SB.AppendLine('Contexto Recebido: ' + FContextoRecebido);
    if FAnalise <> '' then SB.AppendLine('Analysis: ' + FAnalise);
    if FExplicacao <> '' then SB.AppendLine('Explanation: ' + FExplicacao);
    if FAcaoTomada <> '' then SB.AppendLine('Action Taken: ' + FAcaoTomada);
    if FParametrosAcao.Count > 0 then SB.AppendLine('Parameters: ' + FParametrosAcao.CommaText);
    if FSaidaGerada <> '' then SB.AppendLine('Generated Output: ' + FSaidaGerada);
    if FResumoParaProximoAgente <> '' then SB.AppendLine('Summary: ' + FResumoParaProximoAgente);
    if FConfianca > 0 then SB.AppendLine(Format('Confidence: %.2f', [FConfianca]));
    if FErro <> '' then SB.AppendLine('Error: ' + FErro);
    if FInformacoesPreservadas.Count > 0 then
      SB.AppendLine('Preserved information: ' + FInformacoesPreservadas.CommaText);
    if FInformacoesNovas.Count > 0 then
      SB.AppendLine('New information: ' + FInformacoesNovas.CommaText);
    if FInformacoesPerdidas.Count > 0 then
      SB.AppendLine('WARNING: Information loss: ' + FInformacoesPerdidas.CommaText);
    if FAlertas.Count > 0 then
      SB.AppendLine('Warnings: ' + FAlertas.CommaText);
    if FPerguntasAnalises.Count > 0 then
    begin
      SB.AppendLine('Internal Questions:');
      SB.Append(FPerguntasAnalises.AsText);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TAIAgentMemoryMapItem.AsJSON: string;
var
  Obj: TJSONObject;
begin
  Obj := CreateMapaItemJSONObject(Self);
  try
    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

function TAIAgentMemoryMapItem.HasInformationLoss: Boolean;
begin
  Result := FInformacoesPerdidas.Count > 0;
end;

procedure TAIAgentMemoryMapItem.AddPerguntaAnalise(
  const APergunta: string;
  const AResposta: string;
  const AAnalise: string;
  const AOrigem: string;
  const AConfianca: Double
);
begin
  FPerguntasAnalises.AddPergunta(APergunta, AResposta, AAnalise, AOrigem, AConfianca);
end;

procedure TAIAgentMemoryMapItem.AddInformacaoPreservada(const AInfo: string);
begin
  if (Trim(AInfo) <> '') and (FInformacoesPreservadas.IndexOf(AInfo) < 0) then
    FInformacoesPreservadas.Add(AInfo);
end;

procedure TAIAgentMemoryMapItem.AddInformacaoPerdida(const AInfo: string);
begin
  if (Trim(AInfo) <> '') and (FInformacoesPerdidas.IndexOf(AInfo) < 0) then
    FInformacoesPerdidas.Add(AInfo);
end;

procedure TAIAgentMemoryMapItem.AddInformacaoNova(const AInfo: string);
begin
  if (Trim(AInfo) <> '') and (FInformacoesNovas.IndexOf(AInfo) < 0) then
    FInformacoesNovas.Add(AInfo);
end;

procedure TAIAgentMemoryMapItem.AddAlerta(const AAlerta: string);
begin
  if (Trim(AAlerta) <> '') and (FAlertas.IndexOf(AAlerta) < 0) then
    FAlertas.Add(AAlerta);
end;

procedure TAIAgentMemoryMapItem.SetParametrosAcao(AValue: TStrings);
begin
  if Assigned(AValue) then
    FParametrosAcao.Assign(AValue)
  else
    FParametrosAcao.Clear;
end;

procedure TAIAgentMemoryMapItem.SetInformacoesPreservadas(AValue: TStrings);
begin
  if Assigned(AValue) then
    FInformacoesPreservadas.Assign(AValue)
  else
    FInformacoesPreservadas.Clear;
end;

procedure TAIAgentMemoryMapItem.SetInformacoesPerdidas(AValue: TStrings);
begin
  if Assigned(AValue) then
    FInformacoesPerdidas.Assign(AValue)
  else
    FInformacoesPerdidas.Clear;
end;

procedure TAIAgentMemoryMapItem.SetInformacoesNovas(AValue: TStrings);
begin
  if Assigned(AValue) then
    FInformacoesNovas.Assign(AValue)
  else
    FInformacoesNovas.Clear;
end;

procedure TAIAgentMemoryMapItem.SetAlertas(AValue: TStrings);
begin
  if Assigned(AValue) then
    FAlertas.Assign(AValue)
  else
    FAlertas.Clear;
end;

procedure TAIAgentMemoryMapItem.SetPerguntasAnalises(AValue: TAIAnalysisQuestionCollection);
begin
  if Assigned(AValue) then
    FPerguntasAnalises.Assign(AValue)
  else
    FPerguntasAnalises.Clear;
end;

{ TAIAgentMemoryMapCollection }

constructor TAIAgentMemoryMapCollection.Create(AOwner: TComponent);
begin
  inherited Create(TAIAgentMemoryMapItem);
  FOwnerComponent := AOwner;
end;

function TAIAgentMemoryMapCollection.GetItem(Index: Integer): TAIAgentMemoryMapItem;
begin
  Result := TAIAgentMemoryMapItem(inherited GetItem(Index));
end;

procedure TAIAgentMemoryMapCollection.SetItem(Index: Integer; Value: TAIAgentMemoryMapItem);
begin
  inherited SetItem(Index, Value);
end;

function TAIAgentMemoryMapCollection.GetOwner: TPersistent;
begin
  Result := FOwnerComponent;
end;

function TAIAgentMemoryMapCollection.Add: TAIAgentMemoryMapItem;
begin
  Result := TAIAgentMemoryMapItem(inherited Add);
end;

function TAIAgentMemoryMapCollection.FindByOrder(AOrdem: Integer): TAIAgentMemoryMapItem;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to Count - 1 do
  begin
    if Items[I].Ordem = AOrdem then
    begin
      Result := Items[I];
      Break;
    end;
  end;
end;

function TAIAgentMemoryMapCollection.FindLastByAgentName(const ANomeAgente: string): TAIAgentMemoryMapItem;
var
  I: Integer;
begin
  Result := nil;
  for I := Count - 1 downto 0 do
  begin
    if SameText(Items[I].NomeAgente, ANomeAgente) then
    begin
      Result := Items[I];
      Break;
    end;
  end;
end;

function TAIAgentMemoryMapCollection.FindLastByAgentType(ATipo: TAITipoAgenteMapa): TAIAgentMemoryMapItem;
var
  I: Integer;
begin
  Result := nil;
  for I := Count - 1 downto 0 do
  begin
    if Items[I].TipoAgente = ATipo then
    begin
      Result := Items[I];
      Break;
    end;
  end;
end;

function TAIAgentMemoryMapCollection.AsText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
    Result := Result + Items[I].AsText + sLineBreak + '--------------------' + sLineBreak;
end;

{ TAIAgentMemoryMap }

constructor TAIAgentMemoryMap.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FItems := TAIAgentMemoryMapCollection.Create(Self);
  FAutoIncrementOrder := True;
  FCurrentOrder := 0;
  FMaxItems := 100;
  FStoreRawJSON := True;
  FStoreFullPrompt := False;
  FStoreFullResponse := False;
  FDetectInformationLoss := True;
  FRedactSensitiveData := True;
  FLastItem := nil;
  FLastWarning := '';
  FSessionId := '';
  FFlowName := '';
  FSolicitacaoOriginal := '';
  FUsuario := '';
  FOrigem := '';
end;

destructor TAIAgentMemoryMap.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TAIAgentMemoryMap.NewSessionId: string;
var
  G: TGUID;
begin
  if CreateGUID(G) = 0 then
    Result := GUIDToString(G)
  else
    Result := FormatDateTime('yyyymmddhhnnsszzz', Now) + '-' + IntToStr(Random(1000000));
end;

function TAIAgentMemoryMap.SafeText(const AText: string): string;
begin
  if FRedactSensitiveData then
    Result := RedactSensitiveText(AText)
  else
    Result := AText;
end;

procedure TAIAgentMemoryMap.SetItems(AValue: TAIAgentMemoryMapCollection);
begin
  if Assigned(AValue) then
    FItems.Assign(AValue)
  else
    FItems.Clear;

  TrimItemsToMax;
  UpdateCurrentOrderFromItems;
end;

procedure TAIAgentMemoryMap.SetMaxItems(AValue: Integer);
begin
  if AValue < 1 then
    AValue := 1;

  FMaxItems := AValue;
  TrimItemsToMax;
end;

procedure TAIAgentMemoryMap.TrimItemsToMax;
begin
  if not Assigned(FItems) then
    Exit;

  while (FMaxItems > 0) and (FItems.Count > FMaxItems) do
    FItems.Delete(0);

  if FItems.Count > 0 then
    FLastItem := FItems[FItems.Count - 1]
  else
    FLastItem := nil;
end;

procedure TAIAgentMemoryMap.UpdateCurrentOrderFromItems;
var
  I: Integer;
begin
  FCurrentOrder := 0;
  if not Assigned(FItems) then
    Exit;

  for I := 0 to FItems.Count - 1 do
  begin
    if FItems[I].Ordem > FCurrentOrder then
      FCurrentOrder := FItems[I].Ordem;
  end;
end;

procedure TAIAgentMemoryMap.DoMapLog(const AMessage: string);
begin
  if Assigned(FOnMemoryMapLog) then
    FOnMemoryMapLog(Self, AMessage);
  Log(llInfo, AMessage);
end;

procedure TAIAgentMemoryMap.StartFlow(
  const ASolicitacaoOriginal: string;
  const AFlowName: string;
  const AUsuario: string;
  const AOrigem: string
);
begin
  ClearError;
  FItems.Clear;
  FSolicitacaoOriginal := SafeText(ASolicitacaoOriginal);
  FFlowName := SafeText(AFlowName);
  FUsuario := SafeText(AUsuario);
  FOrigem := SafeText(AOrigem);
  FCurrentOrder := 0;
  FLastItem := nil;
  FLastWarning := '';

  FSessionId := NewSessionId;

  DoMapLog(Format('Flow started: %s (Session: %s)', [FFlowName, FSessionId]));
end;

function TAIAgentMemoryMap.BeginAgentStep(
  const ANomeAgente: string;
  ATipoAgente: TAITipoAgenteMapa;
  const APedidoRecebido: string;
  const AContextoRecebido: string;
  AOrdemPai: Integer
): TAIAgentMemoryMapItem;
var
  CanCreate: Boolean;
  ProposedOrder: Integer;
begin
  Result := nil;
  ClearError;
  CanCreate := True;

  if Assigned(FOnBeforeCreateStep) then
    FOnBeforeCreateStep(Self, ANomeAgente, ATipoAgente, CanCreate);

  if not CanCreate then
  begin
    DoMapLog('Step creation blocked by the OnBeforeCreateStep event.');
    Exit;
  end;

  if FAutoIncrementOrder then
  begin
    Inc(FCurrentOrder);
    ProposedOrder := FCurrentOrder;
  end
  else
  begin
    if FCurrentOrder <= 0 then
      ProposedOrder := FItems.Count + 1
    else
      ProposedOrder := FCurrentOrder;

    while Assigned(FItems.FindByOrder(ProposedOrder)) do
      Inc(ProposedOrder);

    FCurrentOrder := ProposedOrder;
  end;

  Result := FItems.Add;
  Result.Ordem := ProposedOrder;
  Result.OrdemPai := AOrdemPai;
  Result.DataHoraInicio := Now;
  Result.NomeAgente := SafeText(ANomeAgente);
  Result.TipoAgente := ATipoAgente;
  Result.PedidoRecebido := SafeText(APedidoRecebido);
  Result.PedidoNormalizado := NormalizeForCompare(APedidoRecebido);
  Result.ContextoRecebido := SafeText(AContextoRecebido);
  Result.SolicitacaoOriginal := FSolicitacaoOriginal;
  Result.Status := semEmAnalise;

  FLastItem := Result;
  TrimItemsToMax;

  DoMapLog(Format('Step started: %s (%s)', [
    Result.NomeAgente,
    GetEnumName(TypeInfo(TAITipoAgenteMapa), Ord(ATipoAgente))
  ]));

  if Assigned(FOnAfterCreateStep) then
    FOnAfterCreateStep(Self, Result);
end;

procedure TAIAgentMemoryMap.EndAgentStep(
  AItem: TAIAgentMemoryMapItem;
  const AAnalise: string;
  const AExplicacao: string;
  const AAcaoTomada: string;
  const ASaidaGerada: string;
  const AResumoParaProximoAgente: string
);
var
  LostInfo: string;
begin
  ClearError;

  if not Assigned(AItem) then
  begin
    SetError('EndAgentStep received AItem=nil.');
    Exit;
  end;

  if Assigned(FOnBeforeCloseStep) then
    FOnBeforeCloseStep(Self, AItem);

  AItem.Analise := SafeText(AAnalise);
  AItem.Explicacao := SafeText(AExplicacao);
  AItem.AcaoTomada := SafeText(AAcaoTomada);
  AItem.SaidaGerada := SafeText(ASaidaGerada);
  AItem.ResumoParaProximoAgente := SafeText(AResumoParaProximoAgente);
  AItem.DataHoraFim := Now;
  AItem.Status := semConcluida;

  if FStoreRawJSON and (AItem.RawJSON = '') then
  begin
    { RawJSON is intentionally not invented here. It must be supplied by the caller
      when the LLM raw response is available. }
  end
  else if not FStoreRawJSON then
    AItem.RawJSON := '';

  DoMapLog(Format('Step finished: %s', [AItem.NomeAgente]));

  if FDetectInformationLoss then
  begin
    if CheckInformationLoss(AItem, LostInfo) then
    begin
      FLastWarning := 'Possible information loss: ' + LostInfo;
      AItem.AddAlerta(FLastWarning);

      if Assigned(FOnInformationLossDetected) then
        FOnInformationLossDetected(Self, AItem, LostInfo);
    end;
  end;

  FLastItem := AItem;

  if Assigned(FOnAfterCloseStep) then
    FOnAfterCloseStep(Self, AItem);
end;

procedure TAIAgentMemoryMap.AddQuestion(
  AItem: TAIAgentMemoryMapItem;
  const APergunta: string;
  const AResposta: string;
  const AAnalise: string;
  const AOrigem: string;
  const AConfianca: Double
);
begin
  ClearError;

  if Assigned(AItem) then
    AItem.AddPerguntaAnalise(
      SafeText(APergunta),
      SafeText(AResposta),
      SafeText(AAnalise),
      SafeText(AOrigem),
      AConfianca
    )
  else
    SetError('AddQuestion received AItem=nil.');
end;

procedure TAIAgentMemoryMap.AddActionParam(
  AItem: TAIAgentMemoryMapItem;
  const AName: string;
  const AValue: string
);
begin
  ClearError;

  if Assigned(AItem) then
    AItem.ParametrosAcao.Values[SafeText(AName)] := SafeText(AValue)
  else
    SetError('AddActionParam received AItem=nil.');
end;

function TAIAgentMemoryMap.CheckInformationLoss(
  AItem: TAIAgentMemoryMapItem;
  out ALostInfo: string
): Boolean;
var
  OrigText, OutText: string;
  Tokens: TStringList;
  I: Integer;
  Word: string;
begin
  Result := False;
  ALostInfo := '';

  if not Assigned(AItem) then
    Exit;

  AItem.InformacoesPreservadas.Clear;
  AItem.InformacoesPerdidas.Clear;

  OrigText := NormalizeForCompare(FSolicitacaoOriginal);
  OutText := NormalizeForCompare(
    AItem.SaidaGerada + ' ' +
    AItem.ResumoParaProximoAgente + ' ' +
    AItem.Analise + ' ' +
    AItem.Explicacao + ' ' +
    AItem.AcaoTomada
  );

  Tokens := TStringList.Create;
  try
    Tokens.Sorted := True;
    Tokens.Duplicates := dupIgnore;
    ExtractStrings([' ', #9, #10, #13], [], PChar(OrigText), Tokens);

    for I := 0 to Tokens.Count - 1 do
    begin
      Word := Trim(Tokens[I]);

      if (Length(Word) <= 3) or IsStopWord(Word) then
        Continue;

      if Pos(Word, OutText) = 0 then
      begin
        AItem.AddInformacaoPerdida(Word);
        if ALostInfo <> '' then
          ALostInfo := ALostInfo + ', ';
        ALostInfo := ALostInfo + Word;
        Result := True;
      end
      else
        AItem.AddInformacaoPreservada(Word);
    end;
  finally
    Tokens.Free;
  end;
end;

function TAIAgentMemoryMap.BuildContextForAgent(
  const ANomeAgente: string;
  ATipoAgente: TAITipoAgenteMapa;
  const AMaxSteps: Integer
): string;
var
  SB: TStringBuilder;
  I, StartIdx, MaxSteps: Integer;
  Item: TAIAgentMemoryMapItem;
begin
  SB := TStringBuilder.Create;
  try
    MaxSteps := AMaxSteps;
    if MaxSteps < 1 then
      MaxSteps := 1;

    SB.AppendLine('=== ORIGINAL REQUEST ===');
    SB.AppendLine(FSolicitacaoOriginal);
    SB.AppendLine('');
    SB.AppendLine('=== CURRENT AGENT ===');
    SB.AppendLine('Name: ' + SafeText(ANomeAgente));
    SB.AppendLine('Type: ' + GetEnumName(TypeInfo(TAITipoAgenteMapa), Ord(ATipoAgente)));
    SB.AppendLine('');
    SB.AppendLine('=== PATH SO FAR ===');

    StartIdx := FItems.Count - MaxSteps;
    if StartIdx < 0 then
      StartIdx := 0;

    for I := StartIdx to FItems.Count - 1 do
    begin
      Item := FItems[I];
      SB.AppendLine(Format('%d. %s [%s]', [
        Item.Ordem,
        Item.NomeAgente,
        GetEnumName(TypeInfo(TAITipoAgenteMapa), Ord(Item.TipoAgente))
      ]));

      if Item.PedidoRecebido <> '' then
        SB.AppendLine('   Request: ' + Item.PedidoRecebido);
      if Item.Analise <> '' then
        SB.AppendLine('   Analysis: ' + Item.Analise);
      if Item.Explicacao <> '' then
        SB.AppendLine('   Explanation: ' + Item.Explicacao);
      if Item.AcaoTomada <> '' then
        SB.AppendLine('   Action taken: ' + Item.AcaoTomada);
      if Item.ResumoParaProximoAgente <> '' then
        SB.AppendLine('   Summary for next agent: ' + Item.ResumoParaProximoAgente);
      if Item.InformacoesPreservadas.Count > 0 then
        SB.AppendLine('   Preserved information: ' + Item.InformacoesPreservadas.CommaText);
      if Item.InformacoesPerdidas.Count > 0 then
        SB.AppendLine('   Lost information: ' + Item.InformacoesPerdidas.CommaText);
      if Item.Alertas.Count > 0 then
        SB.AppendLine('   Warnings: ' + Item.Alertas.CommaText);

      SB.AppendLine('');
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TAIAgentMemoryMap.AsText: string;
begin
  Result :=
    '=== MEMORY MAP ===' + sLineBreak +
    'Session: ' + FSessionId + sLineBreak +
    'Flow: ' + FFlowName + sLineBreak +
    'User: ' + FUsuario + sLineBreak +
    'Origin: ' + FOrigem + sLineBreak +
    'Original Request: ' + FSolicitacaoOriginal + sLineBreak +
    '--------------------' + sLineBreak +
    FItems.AsText;
end;

function TAIAgentMemoryMap.AsJSON: string;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('session_id', FSessionId);
    Obj.Add('flow_name', FFlowName);
    Obj.Add('original_request', FSolicitacaoOriginal);
    Obj.Add('user', FUsuario);
    Obj.Add('origin', FOrigem);
    Obj.Add('auto_increment_order', FAutoIncrementOrder);
    Obj.Add('current_order', FCurrentOrder);
    Obj.Add('max_items', FMaxItems);
    Obj.Add('store_raw_json', FStoreRawJSON);
    Obj.Add('store_full_prompt', FStoreFullPrompt);
    Obj.Add('store_full_response', FStoreFullResponse);
    Obj.Add('detect_information_loss', FDetectInformationLoss);
    Obj.Add('redact_sensitive_data', FRedactSensitiveData);
    Obj.Add('last_warning', FLastWarning);

    Arr := TJSONArray.Create;
    for I := 0 to FItems.Count - 1 do
      Arr.Add(CreateMapaItemJSONObject(FItems[I]));
    Obj.Add('steps', Arr);

    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

procedure TAIAgentMemoryMap.SaveToFile(const AFileName: string);
var
  L: TStringList;
begin
  ClearError;

  if Trim(AFileName) = '' then
  begin
    SetError('Invalid file name in SaveToFile.');
    Exit;
  end;

  L := TStringList.Create;
  try
    try
      L.Text := AsJSON;
      L.SaveToFile(AFileName);
      DoMapLog('Memory map saved to: ' + AFileName);
    except
      on E: Exception do
        SetError('Error saving memory map: ' + E.Message);
    end;
  finally
    L.Free;
  end;
end;

procedure TAIAgentMemoryMap.LoadFromFile(const AFileName: string);
var
  L: TStringList;
  Parser: TJSONParser;
  JSONData, StepsData, PData: TJSONData;
  Obj, StepObj: TJSONObject;
  Arr: TJSONArray;
  I, MaxOrder: Integer;
  Item: TAIAgentMemoryMapItem;
begin
  ClearError;

  if Trim(AFileName) = '' then
  begin
    SetError('Invalid file name in LoadFromFile.');
    Exit;
  end;

  if not FileExists(AFileName) then
  begin
    SetError('File not found: ' + AFileName);
    Exit;
  end;

  L := TStringList.Create;
  Parser := nil;
  JSONData := nil;
  try
    try
      L.LoadFromFile(AFileName);
      Parser := TJSONParser.Create(L.Text);
      JSONData := Parser.Parse;

      if (JSONData = nil) or (JSONData.JSONType <> jtObject) then
      begin
        SetError('Invalid JSON: root is not an object.');
        Exit;
      end;

      Obj := TJSONObject(JSONData);

      FSessionId := JSONGetString(Obj, 'session_id', '');
      FFlowName := JSONGetString(Obj, 'flow_name', '');
      FSolicitacaoOriginal := JSONGetString(Obj, 'original_request', '');
      FUsuario := JSONGetString(Obj, 'user', '');
      FOrigem := JSONGetString(Obj, 'origin', '');
      FAutoIncrementOrder := JSONGetBool(Obj, 'auto_increment_order', True);
      FCurrentOrder := JSONGetInteger(Obj, 'current_order', 0);
      FMaxItems := JSONGetInteger(Obj, 'max_items', 100);
      if FMaxItems < 1 then
        FMaxItems := 1;
      FStoreRawJSON := JSONGetBool(Obj, 'store_raw_json', True);
      FStoreFullPrompt := JSONGetBool(Obj, 'store_full_prompt', False);
      FStoreFullResponse := JSONGetBool(Obj, 'store_full_response', False);
      FDetectInformationLoss := JSONGetBool(Obj, 'detect_information_loss', True);
      FRedactSensitiveData := JSONGetBool(Obj, 'redact_sensitive_data', True);
      FLastWarning := JSONGetString(Obj, 'last_warning', '');

      FItems.Clear;
      MaxOrder := 0;

      StepsData := Obj.Find('steps');
      if Assigned(StepsData) and (StepsData.JSONType = jtArray) then
      begin
        Arr := TJSONArray(StepsData);
        for I := 0 to Arr.Count - 1 do
        begin
          if Arr.Items[I].JSONType <> jtObject then
            Continue;

          StepObj := TJSONObject(Arr.Items[I]);
          Item := FItems.Add;

          Item.Ordem := JSONGetInteger(StepObj, 'ordem', 0);
          Item.OrdemPai := JSONGetInteger(StepObj, 'ordem_pai', 0);
          Item.DataHoraInicio := JSONGetFloat(StepObj, 'data_hora_inicio_value', 0);
          Item.DataHoraFim := JSONGetFloat(StepObj, 'data_hora_fim_value', 0);
          Item.NomeAgente := JSONGetString(StepObj, 'nome_agente', '');
          Item.TipoAgente := TAITipoAgenteMapa(JSONGetInteger(StepObj, 'tipo_agente', Ord(tamIndefinido)));
          Item.Status := TAIAgentMemoryStepStatus(JSONGetInteger(StepObj, 'status', Ord(semIniciada)));
          Item.SolicitacaoOriginal := JSONGetString(StepObj, 'solicitacao_original', FSolicitacaoOriginal);
          Item.PedidoRecebido := JSONGetString(StepObj, 'pedido_recebido', '');
          Item.PedidoNormalizado := JSONGetString(StepObj, 'pedido_normalizado', '');
          Item.ContextoRecebido := JSONGetString(StepObj, 'contexto_recebido', '');
          Item.Analise := JSONGetString(StepObj, 'analise', '');
          Item.Explicacao := JSONGetString(StepObj, 'explicacao', '');
          Item.AcaoTomada := JSONGetString(StepObj, 'acao_tomada', '');
          Item.SaidaGerada := JSONGetString(StepObj, 'saida_gerada', '');
          Item.ResumoParaProximoAgente := JSONGetString(
            StepObj,
            'resumo_para_proximo_agente',
            JSONGetString(StepObj, 'resumo', '')
          );
          Item.Confianca := JSONGetFloat(StepObj, 'confianca', 0.0);
          Item.Erro := JSONGetString(StepObj, 'erro', '');
          Item.RawJSON := JSONGetString(StepObj, 'raw_json', '');

          LoadStringsFromJSONArray(Item.ParametrosAcao, StepObj.Find('parametros_acao'));
          LoadStringsFromJSONArray(Item.InformacoesPreservadas, StepObj.Find('informacoes_preservadas'));
          LoadStringsFromJSONArray(Item.InformacoesPerdidas, StepObj.Find('informacoes_perdidas'));
          LoadStringsFromJSONArray(Item.InformacoesNovas, StepObj.Find('informacoes_novas'));
          LoadStringsFromJSONArray(Item.Alertas, StepObj.Find('alertas'));

          PData := StepObj.Find('perguntas');
          LoadPerguntasFromJSONArray(Item.PerguntasAnalises, PData);

          if Item.Ordem > MaxOrder then
            MaxOrder := Item.Ordem;
        end;
      end;

      if FCurrentOrder < MaxOrder then
        FCurrentOrder := MaxOrder;

      TrimItemsToMax;
      UpdateCurrentOrderFromItems;

      if FItems.Count > 0 then
        FLastItem := FItems[FItems.Count - 1]
      else
        FLastItem := nil;

      DoMapLog('Memory map loaded from: ' + AFileName);
    except
      on E: Exception do
        SetError('Error loading memory map: ' + E.Message);
    end;
  finally
    JSONData.Free;
    Parser.Free;
    L.Free;
  end;
end;

initialization
  {$I taiagentmemorymap_icon.lrs}

end.

