unit aiagent_memorymap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser, TypInfo, aibase, aiagent_flowevents, LResources;

type
  { Status of map step }
  TAIStatusEtapaMapa = (
    semIniciada,
    semEmAnalise,
    semAguardandoInformacao,
    semConcluida,
    semExecutada,
    semFalhou,
    semCancelada
  );

  { TAIPerguntaAnaliseItem }
  TAIPerguntaAnaliseItem = class(TCollectionItem)
  private
    FOrdem: Integer;
    FPergunta: string;
    FResposta: string;
    FAnalise: string;
    FConfianca: Double;
    FOrigem: string;
  published
    property Ordem: Integer read FOrdem write FOrdem;
    property Pergunta: string read FPergunta write FPergunta;
    property Resposta: string read FResposta write FResposta;
    property Analise: string read FAnalise write FAnalise;
    property Confianca: Double read FConfianca write FConfianca;
    property Origem: string read FOrigem write FOrigem;
  end;

  { TAIPerguntaAnaliseCollection }
  TAIPerguntaAnaliseCollection = class(TCollection)
  private
    function GetItem(Index: Integer): TAIPerguntaAnaliseItem;
    procedure SetItem(Index: Integer; Value: TAIPerguntaAnaliseItem);
  public
    constructor Create;
    function Add: TAIPerguntaAnaliseItem;
    function AddPergunta(
      const APergunta: string;
      const AResposta: string;
      const AAnalise: string;
      const AOrigem: string = 'LLM';
      const AConfianca: Double = 0
    ): TAIPerguntaAnaliseItem;
    function AsText: string;
    property Items[Index: Integer]: TAIPerguntaAnaliseItem read GetItem write SetItem; default;
  end;

  { TAIMapaDeMemoriaItem }
  TAIMapaDeMemoriaItem = class(TCollectionItem)
  private
    FOrdem: Integer;
    FOrdemPai: Integer;
    FDataHoraInicio: TDateTime;
    FDataHoraFim: TDateTime;
    FNomeAgente: string;
    FTipoAgente: TAITipoAgenteMapa;
    FStatus: TAIStatusEtapaMapa;
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
    FPerguntasAnalises: TAIPerguntaAnaliseCollection;
    FConfianca: Double;
    FErro: string;
    FRawJSON: string;
    procedure SetParametrosAcao(AValue: TStrings);
    procedure SetInformacoesPreservadas(AValue: TStrings);
    procedure SetInformacoesPerdidas(AValue: TStrings);
    procedure SetInformacoesNovas(AValue: TStrings);
    procedure SetAlertas(AValue: TStrings);
    procedure SetPerguntasAnalises(AValue: TAIPerguntaAnaliseCollection);
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
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
    property Status: TAIStatusEtapaMapa read FStatus write FStatus;
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
    property PerguntasAnalises: TAIPerguntaAnaliseCollection read FPerguntasAnalises write SetPerguntasAnalises;
    property Confianca: Double read FConfianca write FConfianca;
    property Erro: string read FErro write FErro;
    property RawJSON: string read FRawJSON write FRawJSON;
  end;

  { TAIMapaDeMemoriaCollection }
  TAIMapaDeMemoriaCollection = class(TCollection)
  private
    FOwnerComponent: TComponent;
    function GetItem(Index: Integer): TAIMapaDeMemoriaItem;
    procedure SetItem(Index: Integer; Value: TAIMapaDeMemoriaItem);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TComponent);
    function Add: TAIMapaDeMemoriaItem;
    function FindByOrder(AOrdem: Integer): TAIMapaDeMemoriaItem;
    function FindLastByAgentName(const ANomeAgente: string): TAIMapaDeMemoriaItem;
    function FindLastByAgentType(ATipo: TAITipoAgenteMapa): TAIMapaDeMemoriaItem;
    function AsText: string;
    property Items[Index: Integer]: TAIMapaDeMemoriaItem read GetItem write SetItem; default;
  end;

  { Events for TAIMapaDeMemoria }
  TAIMapaBeforeCreateStepEvent = procedure(
    Sender: TObject;
    const ANomeAgente: string;
    ATipoAgente: TAITipoAgenteMapa;
    var ACanCreate: Boolean
  ) of object;

  TAIMapaStepEvent = procedure(
    Sender: TObject;
    AItem: TAIMapaDeMemoriaItem
  ) of object;

  TAIMapaInformationLossEvent = procedure(
    Sender: TObject;
    AItem: TAIMapaDeMemoriaItem;
    const ALostInfo: string
  ) of object;

  TAIMapaLogEvent = procedure(
    Sender: TObject;
    const AMessage: string
  ) of object;

  { TAIMapaDeMemoria Component }
  TAIMapaDeMemoria = class(TAIBaseComponent)
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
    FItems: TAIMapaDeMemoriaCollection;
    FLastItem: TAIMapaDeMemoriaItem;
    FLastWarning: string;
    // Events
    FOnBeforeCreateStep: TAIMapaBeforeCreateStepEvent;
    FOnAfterCreateStep: TAIMapaStepEvent;
    FOnBeforeCloseStep: TAIMapaStepEvent;
    FOnAfterCloseStep: TAIMapaStepEvent;
    FOnInformationLossDetected: TAIMapaInformationLossEvent;
    FOnMemoryMapLog: TAIMapaLogEvent;
    procedure SetItems(AValue: TAIMapaDeMemoriaCollection);
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
    ): TAIMapaDeMemoriaItem;
    procedure EndAgentStep(
      AItem: TAIMapaDeMemoriaItem;
      const AAnalise: string;
      const AExplicacao: string;
      const AAcaoTomada: string;
      const ASaidaGerada: string;
      const AResumoParaProximoAgente: string = ''
    );
    procedure AddQuestion(
      AItem: TAIMapaDeMemoriaItem;
      const APergunta: string;
      const AResposta: string;
      const AAnalise: string;
      const AOrigem: string = 'LLM';
      const AConfianca: Double = 0
    );
    procedure AddActionParam(
      AItem: TAIMapaDeMemoriaItem;
      const AName: string;
      const AValue: string
    );
    function CheckInformationLoss(
      AItem: TAIMapaDeMemoriaItem;
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
  published
    property SessionId: string read FSessionId write FSessionId;
    property FlowName: string read FFlowName write FFlowName;
    property SolicitacaoOriginal: string read FSolicitacaoOriginal write FSolicitacaoOriginal;
    property Usuario: string read FUsuario write FUsuario;
    property Origem: string read FOrigem write FOrigem;
    property AutoIncrementOrder: Boolean read FAutoIncrementOrder write FAutoIncrementOrder default True;
    property CurrentOrder: Integer read FCurrentOrder write FCurrentOrder default 0;
    property MaxItems: Integer read FMaxItems write FMaxItems default 100;
    property StoreRawJSON: Boolean read FStoreRawJSON write FStoreRawJSON default True;
    property StoreFullPrompt: Boolean read FStoreFullPrompt write FStoreFullPrompt default False;
    property StoreFullResponse: Boolean read FStoreFullResponse write FStoreFullResponse default False;
    property DetectInformationLoss: Boolean read FDetectInformationLoss write FDetectInformationLoss default True;
    property RedactSensitiveData: Boolean read FRedactSensitiveData write FRedactSensitiveData default True;
    property Items: TAIMapaDeMemoriaCollection read FItems write SetItems;
    property LastItem: TAIMapaDeMemoriaItem read FLastItem;
    property LastWarning: string read FLastWarning write FLastWarning;
    // Events
    property OnBeforeCreateStep: TAIMapaBeforeCreateStepEvent read FOnBeforeCreateStep write FOnBeforeCreateStep;
    property OnAfterCreateStep: TAIMapaStepEvent read FOnAfterCreateStep write FOnAfterCreateStep;
    property OnBeforeCloseStep: TAIMapaStepEvent read FOnBeforeCloseStep write FOnBeforeCloseStep;
    property OnAfterCloseStep: TAIMapaStepEvent read FOnAfterCloseStep write FOnAfterCloseStep;
    property OnInformationLossDetected: TAIMapaInformationLossEvent read FOnInformationLossDetected write FOnInformationLossDetected;
    property OnMemoryMapLog: TAIMapaLogEvent read FOnMemoryMapLog write FOnMemoryMapLog;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Agents', [TAIMapaDeMemoria]);
end;

{ TAIPerguntaAnaliseCollection }

constructor TAIPerguntaAnaliseCollection.Create;
begin
  inherited Create(TAIPerguntaAnaliseItem);
end;

function TAIPerguntaAnaliseCollection.GetItem(Index: Integer): TAIPerguntaAnaliseItem;
begin
  Result := TAIPerguntaAnaliseItem(inherited GetItem(Index));
end;

procedure TAIPerguntaAnaliseCollection.SetItem(Index: Integer; Value: TAIPerguntaAnaliseItem);
begin
  inherited SetItem(Index, Value);
end;

function TAIPerguntaAnaliseCollection.Add: TAIPerguntaAnaliseItem;
begin
  Result := TAIPerguntaAnaliseItem(inherited Add);
  Result.Ordem := Count;
end;

function TAIPerguntaAnaliseCollection.AddPergunta(
  const APergunta: string;
  const AResposta: string;
  const AAnalise: string;
  const AOrigem: string;
  const AConfianca: Double
): TAIPerguntaAnaliseItem;
begin
  Result := Add;
  Result.Pergunta := APergunta;
  Result.Resposta := AResposta;
  Result.Analise := AAnalise;
  Result.Origem := AOrigem;
  Result.Confianca := AConfianca;
end;

function TAIPerguntaAnaliseCollection.AsText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
  begin
    Result := Result + Format('  Pergunta %d: %s' + sLineBreak + '  Resposta: %s' + sLineBreak + '  Análise: %s' + sLineBreak,
      [Items[I].Ordem, Items[I].Pergunta, Items[I].Resposta, Items[I].Analise]);
  end;
end;

{ TAIMapaDeMemoriaItem }

constructor TAIMapaDeMemoriaItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FParametrosAcao := TStringList.Create;
  FInformacoesPreservadas := TStringList.Create;
  FInformacoesPerdidas := TStringList.Create;
  FInformacoesNovas := TStringList.Create;
  FAlertas := TStringList.Create;
  FPerguntasAnalises := TAIPerguntaAnaliseCollection.Create;
  Clear;
end;

destructor TAIMapaDeMemoriaItem.Destroy;
begin
  FParametrosAcao.Free;
  FInformacoesPreservadas.Free;
  FInformacoesPerdidas.Free;
  FInformacoesNovas.Free;
  FAlertas.Free;
  FPerguntasAnalises.Free;
  inherited Destroy;
end;

procedure TAIMapaDeMemoriaItem.Clear;
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

function TAIMapaDeMemoriaItem.AsText: string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine(Format('Ordem: %d (Pai: %d)', [FOrdem, FOrdemPai]));
    SB.AppendLine(Format('Agente: %s [Tipo: %d]', [FNomeAgente, Ord(FTipoAgente)]));
    SB.AppendLine('Status: ' + GetEnumName(TypeInfo(TAIStatusEtapaMapa), Ord(FStatus)));
    SB.AppendLine('Pedido Recebido: ' + FPedidoRecebido);
    if FAnalise <> '' then SB.AppendLine('Análise: ' + FAnalise);
    if FExplicacao <> '' then SB.AppendLine('Explicação: ' + FExplicacao);
    if FAcaoTomada <> '' then SB.AppendLine('Ação Tomada: ' + FAcaoTomada);
    if FParametrosAcao.Count > 0 then SB.AppendLine('Parâmetros: ' + FParametrosAcao.CommaText);
    if FResumoParaProximoAgente <> '' then SB.AppendLine('Resumo: ' + FResumoParaProximoAgente);
    if FPerguntasAnalises.Count > 0 then
    begin
      SB.AppendLine('Perguntas Internas:');
      SB.Append(FPerguntasAnalises.AsText);
    end;
    if FInformacoesPerdidas.Count > 0 then
      SB.AppendLine('ALERT: Perdas de informação: ' + FInformacoesPerdidas.CommaText);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TAIMapaDeMemoriaItem.AsJSON: string;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  PItem: TAIPerguntaAnaliseItem;
  I: Integer;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('ordem', FOrdem);
    Obj.Add('ordem_pai', FOrdemPai);
    Obj.Add('nome_agente', FNomeAgente);
    Obj.Add('tipo_agente', Ord(FTipoAgente));
    Obj.Add('status', Ord(FStatus));
    Obj.Add('pedido_recebido', FPedidoRecebido);
    Obj.Add('analise', FAnalise);
    Obj.Add('explicacao', FExplicacao);
    Obj.Add('acao_tomada', FAcaoTomada);
    Obj.Add('saida_gerada', FSaidaGerada);
    Obj.Add('resumo', FResumoParaProximoAgente);
    
    // Add arrays
    Arr := TJSONArray.Create;
    for I := 0 to FPerguntasAnalises.Count - 1 do
    begin
      PItem := FPerguntasAnalises[I];
      Arr.Add(TJSONObject.Create([
        'ordem', PItem.Ordem,
        'pergunta', PItem.Pergunta,
        'resposta', PItem.Resposta,
        'analise', PItem.Analise,
        'origem', PItem.Origem,
        'confianca', PItem.Confianca
      ]));
    end;
    Obj.Add('perguntas', Arr);

    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

function TAIMapaDeMemoriaItem.HasInformationLoss: Boolean;
begin
  Result := FInformacoesPerdidas.Count > 0;
end;

procedure TAIMapaDeMemoriaItem.AddPerguntaAnalise(
  const APergunta: string;
  const AResposta: string;
  const AAnalise: string;
  const AOrigem: string;
  const AConfianca: Double
);
begin
  FPerguntasAnalises.AddPergunta(APergunta, AResposta, AAnalise, AOrigem, AConfianca);
end;

procedure TAIMapaDeMemoriaItem.AddInformacaoPreservada(const AInfo: string);
begin
  if FInformacoesPreservadas.IndexOf(AInfo) < 0 then
    FInformacoesPreservadas.Add(AInfo);
end;

procedure TAIMapaDeMemoriaItem.AddInformacaoPerdida(const AInfo: string);
begin
  if FInformacoesPerdidas.IndexOf(AInfo) < 0 then
    FInformacoesPerdidas.Add(AInfo);
end;

procedure TAIMapaDeMemoriaItem.AddInformacaoNova(const AInfo: string);
begin
  if FInformacoesNovas.IndexOf(AInfo) < 0 then
    FInformacoesNovas.Add(AInfo);
end;

procedure TAIMapaDeMemoriaItem.AddAlerta(const AAlerta: string);
begin
  if FAlertas.IndexOf(AAlerta) < 0 then
    FAlertas.Add(AAlerta);
end;

procedure TAIMapaDeMemoriaItem.SetParametrosAcao(AValue: TStrings);
begin
  FParametrosAcao.Assign(AValue);
end;

procedure TAIMapaDeMemoriaItem.SetInformacoesPreservadas(AValue: TStrings);
begin
  FInformacoesPreservadas.Assign(AValue);
end;

procedure TAIMapaDeMemoriaItem.SetInformacoesPerdidas(AValue: TStrings);
begin
  FInformacoesPerdidas.Assign(AValue);
end;

procedure TAIMapaDeMemoriaItem.SetInformacoesNovas(AValue: TStrings);
begin
  FInformacoesNovas.Assign(AValue);
end;

procedure TAIMapaDeMemoriaItem.SetAlertas(AValue: TStrings);
begin
  FAlertas.Assign(AValue);
end;

procedure TAIMapaDeMemoriaItem.SetPerguntasAnalises(AValue: TAIPerguntaAnaliseCollection);
begin
  FPerguntasAnalises.Assign(AValue);
end;

{ TAIMapaDeMemoriaCollection }

constructor TAIMapaDeMemoriaCollection.Create(AOwner: TComponent);
begin
  inherited Create(TAIMapaDeMemoriaItem);
  FOwnerComponent := AOwner;
end;

function TAIMapaDeMemoriaCollection.GetItem(Index: Integer): TAIMapaDeMemoriaItem;
begin
  Result := TAIMapaDeMemoriaItem(inherited GetItem(Index));
end;

procedure TAIMapaDeMemoriaCollection.SetItem(Index: Integer; Value: TAIMapaDeMemoriaItem);
begin
  inherited SetItem(Index, Value);
end;

function TAIMapaDeMemoriaCollection.GetOwner: TPersistent;
begin
  Result := FOwnerComponent;
end;

function TAIMapaDeMemoriaCollection.Add: TAIMapaDeMemoriaItem;
begin
  Result := TAIMapaDeMemoriaItem(inherited Add);
end;

function TAIMapaDeMemoriaCollection.FindByOrder(AOrdem: Integer): TAIMapaDeMemoriaItem;
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

function TAIMapaDeMemoriaCollection.FindLastByAgentName(const ANomeAgente: string): TAIMapaDeMemoriaItem;
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

function TAIMapaDeMemoriaCollection.FindLastByAgentType(ATipo: TAITipoAgenteMapa): TAIMapaDeMemoriaItem;
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

function TAIMapaDeMemoriaCollection.AsText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Count - 1 do
    Result := Result + Items[I].AsText + sLineBreak + '--------------------' + sLineBreak;
end;

{ TAIMapaDeMemoria }

constructor TAIMapaDeMemoria.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FItems := TAIMapaDeMemoriaCollection.Create(Self);
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

destructor TAIMapaDeMemoria.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TAIMapaDeMemoria.SetItems(AValue: TAIMapaDeMemoriaCollection);
begin
  FItems.Assign(AValue);
end;

procedure TAIMapaDeMemoria.DoMapLog(const AMessage: string);
begin
  if Assigned(FOnMemoryMapLog) then
    FOnMemoryMapLog(Self, AMessage);
  Log(llInfo, AMessage);
end;

procedure TAIMapaDeMemoria.StartFlow(
  const ASolicitacaoOriginal: string;
  const AFlowName: string;
  const AUsuario: string;
  const AOrigem: string
);
begin
  FItems.Clear;
  FSolicitacaoOriginal := ASolicitacaoOriginal;
  FFlowName := AFlowName;
  FUsuario := AUsuario;
  FOrigem := AOrigem;
  FCurrentOrder := 0;
  FLastItem := nil;

  if FSessionId = '' then
    FSessionId := FormatDateTime('yyyymmddhhnnss', Now) + '-' + IntToStr(Random(1000));

  DoMapLog(Format('Fluxo iniciado: %s (Sessão: %s)', [FFlowName, FSessionId]));
end;

function TAIMapaDeMemoria.BeginAgentStep(
  const ANomeAgente: string;
  ATipoAgente: TAITipoAgenteMapa;
  const APedidoRecebido: string;
  const AContextoRecebido: string;
  AOrdemPai: Integer
): TAIMapaDeMemoriaItem;
var
  CanCreate: Boolean;
begin
  Result := nil;
  CanCreate := True;
  
  if Assigned(FOnBeforeCreateStep) then
    FOnBeforeCreateStep(Self, ANomeAgente, ATipoAgente, CanCreate);

  if not CanCreate then
  begin
    DoMapLog('Criação da etapa bloqueada pelo evento OnBeforeCreateStep.');
    Exit;
  end;

  if FAutoIncrementOrder then
    Inc(FCurrentOrder);

  Result := FItems.Add;
  Result.Ordem := FCurrentOrder;
  Result.OrdemPai := AOrdemPai;
  Result.DataHoraInicio := Now;
  Result.NomeAgente := ANomeAgente;
  Result.TipoAgente := ATipoAgente;
  Result.PedidoRecebido := APedidoRecebido;
  Result.ContextoRecebido := AContextoRecebido;
  Result.SolicitacaoOriginal := FSolicitacaoOriginal;
  Result.Status := semEmAnalise;
  FLastItem := Result;

  DoMapLog(Format('Etapa iniciada: %s (%s)', [ANomeAgente, GetEnumName(TypeInfo(TAITipoAgenteMapa), Ord(ATipoAgente))]));

  if Assigned(FOnAfterCreateStep) then
    FOnAfterCreateStep(Self, Result);
end;

procedure TAIMapaDeMemoria.EndAgentStep(
  AItem: TAIMapaDeMemoriaItem;
  const AAnalise: string;
  const AExplicacao: string;
  const AAcaoTomada: string;
  const ASaidaGerada: string;
  const AResumoParaProximoAgente: string
);
var
  LostInfo: string;
begin
  if not Assigned(AItem) then Exit;

  if Assigned(FOnBeforeCloseStep) then
    FOnBeforeCloseStep(Self, AItem);

  AItem.Analise := AAnalise;
  AItem.Explicacao := AExplicacao;
  AItem.AcaoTomada := AAcaoTomada;
  AItem.SaidaGerada := ASaidaGerada;
  AItem.ResumoParaProximoAgente := AResumoParaProximoAgente;
  AItem.DataHoraFim := Now;
  AItem.Status := semConcluida;

  DoMapLog(Format('Etapa finalizada: %s', [AItem.NomeAgente]));

  if FDetectInformationLoss then
  begin
    if CheckInformationLoss(AItem, LostInfo) then
    begin
      AItem.AddInformacaoPerdida(LostInfo);
      if Assigned(FOnInformationLossDetected) then
        FOnInformationLossDetected(Self, AItem, LostInfo);
    end;
  end;

  if Assigned(FOnAfterCloseStep) then
    FOnAfterCloseStep(Self, AItem);
end;

procedure TAIMapaDeMemoria.AddQuestion(
  AItem: TAIMapaDeMemoriaItem;
  const APergunta: string;
  const AResposta: string;
  const AAnalise: string;
  const AOrigem: string;
  const AConfianca: Double
);
begin
  if Assigned(AItem) then
    AItem.AddPerguntaAnalise(APergunta, AResposta, AAnalise, AOrigem, AConfianca);
end;

procedure TAIMapaDeMemoria.AddActionParam(
  AItem: TAIMapaDeMemoriaItem;
  const AName: string;
  const AValue: string
);
begin
  if Assigned(AItem) then
    AItem.ParametrosAcao.Values[AName] := AValue;
end;

function TAIMapaDeMemoria.CheckInformationLoss(
  AItem: TAIMapaDeMemoriaItem;
  out ALostInfo: string
): Boolean;
var
  OrigText, OutText: string;
  I: Integer;
  Keywords: TStringList;
  Word: string;
begin
  Result := False;
  ALostInfo := '';
  if not Assigned(AItem) then Exit;

  OrigText := LowerCase(FSolicitacaoOriginal);
  OutText := LowerCase(AItem.SaidaGerada) + ' ' + LowerCase(AItem.ResumoParaProximoAgente) + ' ' + LowerCase(AItem.Analise);

  Keywords := TStringList.Create;
  try
    // Simple word extractor
    Keywords.Delimiter := ' ';
    Keywords.DelimitedText := OrigText;
    for I := 0 to Keywords.Count - 1 do
    begin
      Word := Keywords[I];
      // Clean word
      Word := StringReplace(Word, '.', '', [rfReplaceAll]);
      Word := StringReplace(Word, ',', '', [rfReplaceAll]);
      Word := StringReplace(Word, ';', '', [rfReplaceAll]);
      
      // Basic check for important words (length > 3 and not common Portuguese stopwords)
      if (Length(Word) > 3) and 
         (Word <> 'para') and (Word <> 'como') and (Word <> 'mais') and 
         (Word <> 'esta') and (Word <> 'pela') and (Word <> 'pelos') then
      begin
        if Pos(Word, OutText) = 0 then
        begin
          AItem.AddInformacaoPerdida(Word);
          if ALostInfo <> '' then ALostInfo := ALostInfo + ', ';
          ALostInfo := ALostInfo + Word;
          Result := True;
        end
        else
        begin
          AItem.AddInformacaoPreservada(Word);
        end;
      end;
    end;
  finally
    Keywords.Free;
  end;
end;

function TAIMapaDeMemoria.BuildContextForAgent(
  const ANomeAgente: string;
  ATipoAgente: TAITipoAgenteMapa;
  const AMaxSteps: Integer
): string;
var
  SB: TStringBuilder;
  I, StartIdx: Integer;
  Item: TAIMapaDeMemoriaItem;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('=== SOLICITAÇÃO ORIGINAL ===');
    SB.AppendLine(FSolicitacaoOriginal);
    SB.AppendLine('');
    SB.AppendLine('=== CAMINHO ATÉ AQUI ===');
    
    StartIdx := FItems.Count - AMaxSteps;
    if StartIdx < 0 then StartIdx := 0;

    for I := StartIdx to FItems.Count - 1 do
    begin
      Item := FItems[I];
      SB.AppendLine(Format('%d. %s [%s]', [Item.Ordem, Item.NomeAgente, GetEnumName(TypeInfo(TAITipoAgenteMapa), Ord(Item.TipoAgente))]));
      if Item.Analise <> '' then
        SB.AppendLine('   Análise: ' + Item.Analise);
      if Item.AcaoTomada <> '' then
        SB.AppendLine('   Ação tomada: ' + Item.AcaoTomada);
      if Item.InformacoesPreservadas.Count > 0 then
        SB.AppendLine('   Informações preservadas: ' + Item.InformacoesPreservadas.CommaText);
      if Item.InformacoesPerdidas.Count > 0 then
        SB.AppendLine('   Informações perdidas: ' + Item.InformacoesPerdidas.CommaText);
      SB.AppendLine('');
    end;

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function TAIMapaDeMemoria.AsText: string;
begin
  Result := '=== MEMORY MAP ===' + sLineBreak +
            'Session: ' + FSessionId + sLineBreak +
            'Flow: ' + FFlowName + sLineBreak +
            'Original Request: ' + FSolicitacaoOriginal + sLineBreak +
            '--------------------' + sLineBreak +
            FItems.AsText;
end;

function TAIMapaDeMemoria.AsJSON: string;
var
  Obj: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  Parser: TJSONParser;
  ItemJSON: TJSONData;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('session_id', FSessionId);
    Obj.Add('flow_name', FFlowName);
    Obj.Add('original_request', FSolicitacaoOriginal);
    Obj.Add('user', FUsuario);
    Obj.Add('origin', FOrigem);
    
    Arr := TJSONArray.Create;
    for I := 0 to FItems.Count - 1 do
    begin
      Parser := TJSONParser.Create(FItems[I].AsJSON);
      try
        ItemJSON := Parser.Parse;
        Arr.Add(ItemJSON);
      finally
        Parser.Free;
      end;
    end;
    Obj.Add('steps', Arr);
    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

procedure TAIMapaDeMemoria.SaveToFile(const AFileName: string);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.Text := AsJSON;
    L.SaveToFile(AFileName);
  finally
    L.Free;
  end;
end;

procedure TAIMapaDeMemoria.LoadFromFile(const AFileName: string);
var
  L: TStringList;
  Parser: TJSONParser;
  JSONData: TJSONData;
  Obj, StepObj: TJSONObject;
  Arr: TJSONArray;
  I, J: Integer;
  Item: TAIMapaDeMemoriaItem;
  PArr: TJSONArray;
  PObj: TJSONObject;
begin
  if not FileExists(AFileName) then Exit;
  L := TStringList.Create;
  try
    L.LoadFromFile(AFileName);
    Parser := TJSONParser.Create(L.Text);
    try
      JSONData := Parser.Parse;
      if JSONData is TJSONObject then
      begin
        Obj := TJSONObject(JSONData);
        FSessionId := Obj.Get('session_id', '');
        FFlowName := Obj.Get('flow_name', '');
        FSolicitacaoOriginal := Obj.Get('original_request', '');
        FUsuario := Obj.Get('user', '');
        FOrigem := Obj.Get('origin', '');
        
        FItems.Clear;
        Arr := Obj.Arrays['steps'];
        if Assigned(Arr) then
        begin
          for I := 0 to Arr.Count - 1 do
          begin
            StepObj := Arr.Objects[I];
            Item := FItems.Add;
            Item.Ordem := StepObj.Get('ordem', 0);
            Item.OrdemPai := StepObj.Get('ordem_pai', 0);
            Item.NomeAgente := StepObj.Get('nome_agente', '');
            Item.TipoAgente := TAITipoAgenteMapa(StepObj.Get('tipo_agente', 0));
            Item.Status := TAIStatusEtapaMapa(StepObj.Get('status', 0));
            Item.PedidoRecebido := StepObj.Get('pedido_recebido', '');
            Item.Analise := StepObj.Get('analise', '');
            Item.Explicacao := StepObj.Get('explicacao', '');
            Item.AcaoTomada := StepObj.Get('acao_tomada', '');
            Item.SaidaGerada := StepObj.Get('saida_gerada', '');
            Item.ResumoParaProximoAgente := StepObj.Get('resumo', '');
            
            PArr := StepObj.Arrays['perguntas'];
            if Assigned(PArr) then
            begin
              for J := 0 to PArr.Count - 1 do
              begin
                PObj := PArr.Objects[J];
                Item.AddPerguntaAnalise(
                  PObj.Get('pergunta', ''),
                  PObj.Get('resposta', ''),
                  PObj.Get('analise', ''),
                  PObj.Get('origem', 'LLM'),
                  PObj.Get('confianca', 0.0)
                );
              end;
            end;
          end;
        end;
      end;
    finally
      Parser.Free;
    end;
  finally
    L.Free;
  end;
end;

initialization
  {$I taimapadememoria_icon.lrs}

end.
