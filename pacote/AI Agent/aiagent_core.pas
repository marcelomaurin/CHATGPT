unit aiagent_core;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, chatgpt, aiagent_flowevents, aiagent_memorymap;

type
  { Event types for agents }
  TAIAgentMemoryStepEvent = procedure(
    Sender: TObject;
    AItem: TAIAgentMemoryMapItem
  ) of object;

  TAIAgentQuestionEvent = procedure(
    Sender: TObject;
    AItem: TAIAgentMemoryMapItem;
    const APergunta: string;
    var AResposta: string
  ) of object;

  { TAICustomAgent }
  TAICustomAgent = class(TAIBaseComponent)
  private
    FChatGPT: TCHATGPT;
    FSystemPrompt: string;
    FMemoryMap: TAIAgentMemoryMap;
    FOrdemAtualMapa: Integer;
    // Events
    FOnBeforeMemoryStep: TAIAgentMemoryStepEvent;
    FOnAfterMemoryStep: TAIAgentMemoryStepEvent;
    FOnAgentQuestion: TAIAgentQuestionEvent;
    // Safety
    FOnBeforeAgentExecute: TAIFluxoEtapaControlEvent;
    FOnAfterAgentExecute: TAIFluxoEtapaEvent;
    FOnBeforeBuildPrompt: TAIFluxoEtapaControlEvent;
    FOnAfterBuildPrompt: TAIFluxoEtapaEvent;
    FOnBeforeLLMCall: TAIFluxoEtapaControlEvent;
    FOnAfterLLMCall: TAIFluxoEtapaEvent;
    FOnBeforeParseResponse: TAIFluxoEtapaControlEvent;
    FOnAfterParseResponse: TAIFluxoEtapaEvent;
    FOnBeforeMemoryWrite: TAIFluxoEtapaControlEvent;
    FOnAfterMemoryWrite: TAIFluxoEtapaEvent;
    FOnAgentError: TAIFluxoEtapaEvent;
    procedure SetMemoryMap(AValue: TAIAgentMemoryMap);
  protected
    FAutoRegistrarNoMapa: Boolean;
    FNomeAgente: string;
    FTipoAgenteMapa: TAITipoAgenteMapa;
    FMinConfidence: Double;
    FMaxPerguntasAnalise: Integer;
    FVerificarPerdaInformacao: Boolean;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    property MapaDeMemoria: TAIAgentMemoryMap read FMemoryMap write SetMemoryMap;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function BeginMemoryStep(const AInput: string): TAIAgentMemoryMapItem; virtual;
    procedure EndMemoryStep(
      AItem: TAIAgentMemoryMapItem;
      const AAnalise: string;
      const AExplicacao: string;
      const AAcaoTomada: string;
      const ASaidaGerada: string
    ); virtual;

    procedure AddMemoryQuestion(
      AItem: TAIAgentMemoryMapItem;
      const APergunta: string;
      const AResposta: string;
      const AAnalise: string;
      const AOrigem: string = 'LLM';
      const AConfianca: Double = 0
    ); virtual;
  published
    property ChatGPT: TCHATGPT read FChatGPT write FChatGPT;
    property SystemPrompt: string read FSystemPrompt write FSystemPrompt;
    property MemoryMap: TAIAgentMemoryMap read FMemoryMap write SetMemoryMap;
    property AutoRegistrarNoMapa: Boolean read FAutoRegistrarNoMapa write FAutoRegistrarNoMapa default True;
    property NomeAgente: string read FNomeAgente write FNomeAgente;
    property TipoAgenteMapa: TAITipoAgenteMapa read FTipoAgenteMapa write FTipoAgenteMapa default tamIndefinido;
    property OrdemAtualMapa: Integer read FOrdemAtualMapa write FOrdemAtualMapa default 0;
    property MaxPerguntasAnalise: Integer read FMaxPerguntasAnalise write FMaxPerguntasAnalise default 5;
    property MinConfidence: Double read FMinConfidence write FMinConfidence;
    property VerificarPerdaInformacao: Boolean read FVerificarPerdaInformacao write FVerificarPerdaInformacao default True;
    // Events
    property OnBeforeMemoryStep: TAIAgentMemoryStepEvent read FOnBeforeMemoryStep write FOnBeforeMemoryStep;
    property OnAfterMemoryStep: TAIAgentMemoryStepEvent read FOnAfterMemoryStep write FOnAfterMemoryStep;
    property OnAgentQuestion: TAIAgentQuestionEvent read FOnAgentQuestion write FOnAgentQuestion;
    // Safety & Control Flow Stage Events
    property OnBeforeAgentExecute: TAIFluxoEtapaControlEvent read FOnBeforeAgentExecute write FOnBeforeAgentExecute;
    property OnAfterAgentExecute: TAIFluxoEtapaEvent read FOnAfterAgentExecute write FOnAfterAgentExecute;
    property OnBeforeBuildPrompt: TAIFluxoEtapaControlEvent read FOnBeforeBuildPrompt write FOnBeforeBuildPrompt;
    property OnAfterBuildPrompt: TAIFluxoEtapaEvent read FOnAfterBuildPrompt write FOnAfterBuildPrompt;
    property OnBeforeLLMCall: TAIFluxoEtapaControlEvent read FOnBeforeLLMCall write FOnBeforeLLMCall;
    property OnAfterLLMCall: TAIFluxoEtapaEvent read FOnAfterLLMCall write FOnAfterLLMCall;
    property OnBeforeParseResponse: TAIFluxoEtapaControlEvent read FOnBeforeParseResponse write FOnBeforeParseResponse;
    property OnAfterParseResponse: TAIFluxoEtapaEvent read FOnAfterParseResponse write FOnAfterParseResponse;
    property OnBeforeMemoryWrite: TAIFluxoEtapaControlEvent read FOnBeforeMemoryWrite write FOnBeforeMemoryWrite;
    property OnAfterMemoryWrite: TAIFluxoEtapaEvent read FOnAfterMemoryWrite write FOnAfterMemoryWrite;
    property OnAgentError: TAIFluxoEtapaEvent read FOnAgentError write FOnAgentError;
  end;

implementation

{ TAICustomAgent }

constructor TAICustomAgent.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FChatGPT := nil;
  FSystemPrompt := '';
  FMemoryMap := nil;
  FAutoRegistrarNoMapa := True;
  FNomeAgente := '';
  FTipoAgenteMapa := tamIndefinido;
  FOrdemAtualMapa := 0;
  FMaxPerguntasAnalise := 5;
  FMinConfidence := 0.70;
  FVerificarPerdaInformacao := True;
end;

destructor TAICustomAgent.Destroy;
begin
  inherited Destroy;
end;

procedure TAICustomAgent.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FChatGPT then FChatGPT := nil;
    if AComponent = FMemoryMap then FMemoryMap := nil;
  end;
end;

procedure TAICustomAgent.SetMemoryMap(AValue: TAIAgentMemoryMap);
begin
  if FMemoryMap <> AValue then
  begin
    if Assigned(FMemoryMap) then
      FMemoryMap.RemoveFreeNotification(Self);

    FMemoryMap := AValue;

    if Assigned(FMemoryMap) then
      FMemoryMap.FreeNotification(Self);
  end;
end;

function TAICustomAgent.BeginMemoryStep(const AInput: string): TAIAgentMemoryMapItem;
var
  Ctx: string;
begin
  Result := nil;
  if not Assigned(FMemoryMap) or not FAutoRegistrarNoMapa then Exit;

  Ctx := FMemoryMap.BuildContextForAgent(FNomeAgente, FTipoAgenteMapa);
  Result := FMemoryMap.BeginAgentStep(FNomeAgente, FTipoAgenteMapa, AInput, Ctx);

  if Assigned(Result) then
  begin
    FOrdemAtualMapa := Result.Ordem;
    if Assigned(FOnBeforeMemoryStep) then
      FOnBeforeMemoryStep(Self, Result);
  end;
end;

procedure TAICustomAgent.EndMemoryStep(
  AItem: TAIAgentMemoryMapItem;
  const AAnalise: string;
  const AExplicacao: string;
  const AAcaoTomada: string;
  const ASaidaGerada: string
);
begin
  if not Assigned(FMemoryMap) or not Assigned(AItem) then Exit;

  if Assigned(FOnAfterMemoryStep) then
    FOnAfterMemoryStep(Self, AItem);

  FMemoryMap.EndAgentStep(AItem, AAnalise, AExplicacao, AAcaoTomada, ASaidaGerada);
end;

procedure TAICustomAgent.AddMemoryQuestion(
  AItem: TAIAgentMemoryMapItem;
  const APergunta: string;
  const AResposta: string;
  const AAnalise: string;
  const AOrigem: string;
  const AConfianca: Double
);
begin
  if Assigned(FMemoryMap) and Assigned(AItem) then
    FMemoryMap.AddQuestion(AItem, APergunta, AResposta, AAnalise, AOrigem, AConfianca);
end;

end.
