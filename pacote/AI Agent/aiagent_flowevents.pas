unit aiagent_flowevents;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  { Enum representing the agent type in the memory map }
  TAITipoAgenteMapa = (
    tamIndefinido,
    tamOrquestrador,
    tamClassificador,
    tamDecisor,
    tamAjustadorAcao,
    tamExecutor,
    tamValidador,
    tamSeguranca,
    tamCustom
  );

  { Enum representing the current flow stage }
  TAIFluxoEtapa = (
    afeIndefinida,

    afeInicioFluxo,
    afeFimFluxo,

    afeAntesCriarMapa,
    afeDepoisCriarMapa,

    afeAntesClassificador,
    afeDepoisClassificador,

    afeAntesSelecionarDecisores,
    afeDepoisSelecionarDecisores,

    afeAntesDecisor,
    afeDepoisDecisor,

    afeAntesMontarPlano,
    afeDepoisMontarPlano,

    afeAntesAjustadorAcao,
    afeDepoisAjustadorAcao,

    afeAntesValidarAcao,
    afeDepoisValidarAcao,

    afeAntesExecutor,
    afeDepoisExecutor,

    afeAntesExecutarAcao,
    afeDepoisExecutarAcao,

    afePerdaInformacaoDetectada,
    afeErro,
    afeCancelado
  );

  { Generic flow stage context }
  TAIFluxoEtapaContexto = class
  private
    FParametros: TStrings;
    FAlertas: TStrings;
    procedure SetParametros(AValue: TStrings);
    procedure SetAlertas(AValue: TStrings);
  public
    Etapa: TAIFluxoEtapa;

    SessionId: string;
    FlowName: string;

    NomeAgenteAtual: string;
    TipoAgenteAtual: TAITipoAgenteMapa;

    NomeProximoAgente: string;
    TipoProximoAgente: TAITipoAgenteMapa;

    PedidoOriginal: string;
    PedidoAtual: string;
    ContextoAtual: string;

    AnaliseAtual: string;
    ExplicacaoAtual: string;
    AcaoTomada: string;
    SaidaAtual: string;

    // Additional fields for classification/decisions
    ClassificationPriority: string;

    // Pointers to memory map items to avoid circular dependencies
    MemoryMapItem: TObject; 
    MemoryMap: TObject; 

    PodeContinuar: Boolean;
    CancelarFluxo: Boolean;
    ForcarSimulacao: Boolean;
    ReexecutarEtapa: Boolean;

    MensagemErro: string;

    property MapaItem: TObject read MemoryMapItem write MemoryMapItem;
    property MapaDeMemoria: TObject read MemoryMap write MemoryMap;

    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AsText: string;

    property Parametros: TStrings read FParametros write SetParametros;
    property Alertas: TStrings read FAlertas write SetAlertas;
  end;

  { Flow stage event definitions }
  TAIFluxoEtapaEvent = procedure(
    Sender: TObject;
    AContexto: TAIFluxoEtapaContexto
  ) of object;

  TAIFluxoEtapaControlEvent = procedure(
    Sender: TObject;
    AContexto: TAIFluxoEtapaContexto;
    var ACanContinue: Boolean
  ) of object;

implementation

{ TAIFluxoEtapaContexto }

constructor TAIFluxoEtapaContexto.Create;
begin
  inherited Create;
  FParametros := TStringList.Create;
  FAlertas := TStringList.Create;
  Clear;
end;

destructor TAIFluxoEtapaContexto.Destroy;
begin
  FParametros.Free;
  FAlertas.Free;
  inherited Destroy;
end;

procedure TAIFluxoEtapaContexto.Clear;
begin
  Etapa := afeIndefinida;
  SessionId := '';
  FlowName := '';
  NomeAgenteAtual := '';
  TipoAgenteAtual := tamIndefinido;
  NomeProximoAgente := '';
  TipoProximoAgente := tamIndefinido;
  PedidoOriginal := '';
  PedidoAtual := '';
  ContextoAtual := '';
  AnaliseAtual := '';
  ExplicacaoAtual := '';
  AcaoTomada := '';
  SaidaAtual := '';
  ClassificationPriority := '';
  FParametros.Clear;
  FAlertas.Clear;
  MemoryMapItem := nil;
  MemoryMap := nil;
  PodeContinuar := True;
  CancelarFluxo := False;
  ForcarSimulacao := False;
  ReexecutarEtapa := False;
  MensagemErro := '';
end;

function TAIFluxoEtapaContexto.AsText: string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine('=== AI FLOW STAGE CONTEXT ===');
    SB.AppendLine(Format('Stage: %d', [Ord(Etapa)]));
    SB.AppendLine('SessionId: ' + SessionId);
    SB.AppendLine('FlowName: ' + FlowName);
    SB.AppendLine('CurrentAgentName: ' + NomeAgenteAtual);
    SB.AppendLine(Format('CurrentAgentType: %d', [Ord(TipoAgenteAtual)]));
    SB.AppendLine('NomeProximoAgente: ' + NomeProximoAgente);
    SB.AppendLine(Format('TipoProximoAgente: %d', [Ord(TipoProximoAgente)]));
    SB.AppendLine('OriginalRequest: ' + PedidoOriginal);
    SB.AppendLine('CurrentRequest: ' + PedidoAtual);
    SB.AppendLine('CurrentAnalysis: ' + AnaliseAtual);
    SB.AppendLine('CurrentExplanation: ' + ExplicacaoAtual);
    SB.AppendLine('ActionTaken: ' + AcaoTomada);
    SB.AppendLine('CurrentOutput: ' + SaidaAtual);
    SB.AppendLine('PodeContinuar: ' + BoolToStr(PodeContinuar, True));
    SB.AppendLine('CancelarFluxo: ' + BoolToStr(CancelarFluxo, True));
    SB.AppendLine('ForcarSimulacao: ' + BoolToStr(ForcarSimulacao, True));
    SB.AppendLine('MensagemErro: ' + MensagemErro);
    if FAlertas.Count > 0 then
      SB.AppendLine('Warnings: ' + FAlertas.CommaText);
      Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TAIFluxoEtapaContexto.SetParametros(AValue: TStrings);
begin
  FParametros.Assign(AValue);
end;

procedure TAIFluxoEtapaContexto.SetAlertas(AValue: TStrings);
begin
  FAlertas.Assign(AValue);
end;

end.
