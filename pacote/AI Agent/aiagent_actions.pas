unit aiagent_actions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aiagent_flowevents, aiagent_memorymap;

type
  { TAICustomAgentAction }
  TAICustomAgentAction = class(TComponent)
  private
    FMemoryMap: TAIAgentMemoryMap;
    FActionName: string;
    FLastError: string;
    // Events
    FOnBeforeRun: TAIFluxoEtapaControlEvent;
    FOnAfterRun: TAIFluxoEtapaEvent;
    FOnBeforeValidate: TAIFluxoEtapaControlEvent;
    FOnAfterValidate: TAIFluxoEtapaEvent;
    FOnBeforePrepare: TAIFluxoEtapaControlEvent;
    FOnAfterPrepare: TAIFluxoEtapaEvent;
    FOnBeforeSimulate: TAIFluxoEtapaControlEvent;
    FOnAfterSimulate: TAIFluxoEtapaEvent;
    FOnBeforeExecute: TAIFluxoEtapaControlEvent;
    FOnAfterExecute: TAIFluxoEtapaEvent;
    FOnActionBlocked: TAIFluxoEtapaEvent;
    FOnActionError: TAIFluxoEtapaEvent;
  protected
    procedure SetError(const AMsg: string);
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure SetMemoryMap(AValue: TAIAgentMemoryMap);
  public
    property LastError: string read FLastError;
    property MapaDeMemoria: TAIAgentMemoryMap read FMemoryMap write SetMemoryMap;
    constructor Create(AOwner: TComponent); override;
    function RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean; virtual;
  published
    property ActionName: string read FActionName write FActionName;
    property MemoryMap: TAIAgentMemoryMap read FMemoryMap write SetMemoryMap;
    // Events
    property OnBeforeRun: TAIFluxoEtapaControlEvent read FOnBeforeRun write FOnBeforeRun;
    property OnAfterRun: TAIFluxoEtapaEvent read FOnAfterRun write FOnAfterRun;
    property OnBeforeValidate: TAIFluxoEtapaControlEvent read FOnBeforeValidate write FOnBeforeValidate;
    property OnAfterValidate: TAIFluxoEtapaEvent read FOnAfterValidate write FOnAfterValidate;
    property OnBeforePrepare: TAIFluxoEtapaControlEvent read FOnBeforePrepare write FOnBeforePrepare;
    property OnAfterPrepare: TAIFluxoEtapaEvent read FOnAfterPrepare write FOnAfterPrepare;
    property OnBeforeSimulate: TAIFluxoEtapaControlEvent read FOnBeforeSimulate write FOnBeforeSimulate;
    property OnAfterSimulate: TAIFluxoEtapaEvent read FOnAfterSimulate write FOnAfterSimulate;
    property OnBeforeExecute: TAIFluxoEtapaControlEvent read FOnBeforeExecute write FOnBeforeExecute;
    property OnAfterExecute: TAIFluxoEtapaEvent read FOnAfterExecute write FOnAfterExecute;
    property OnActionBlocked: TAIFluxoEtapaEvent read FOnActionBlocked write FOnActionBlocked;
    property OnActionError: TAIFluxoEtapaEvent read FOnActionError write FOnActionError;
  end;

implementation

{ TAICustomAgentAction }


procedure TAICustomAgentAction.SetMemoryMap(AValue: TAIAgentMemoryMap);
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

constructor TAICustomAgentAction.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActionName := '';
  FMemoryMap := nil;
  FLastError := '';
end;

procedure TAICustomAgentAction.SetError(const AMsg: string);
begin
  FLastError := AMsg;
end;

procedure TAICustomAgentAction.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FMemoryMap then FMemoryMap := nil;
  end;
end;

function TAICustomAgentAction.RunAction(const AParams: TStrings; ASimulate: Boolean): Boolean;
var
  Ctx: TAIFluxoEtapaContexto;
  CanContinue: Boolean;
begin
  Result := False;
  Ctx := TAIFluxoEtapaContexto.Create;
  try
    Ctx.SessionId := '';
    if Assigned(MapaDeMemoria) then
      Ctx.SessionId := MemoryMap.SessionId;
    Ctx.FlowName := 'Execução de Ação Individual';
    Ctx.AcaoTomada := FActionName;
    Ctx.Parametros := AParams;
    Ctx.ForcarSimulacao := ASimulate;

    // Trigger BeforeRun
    CanContinue := True;
    if Assigned(FOnBeforeRun) then
      FOnBeforeRun(Self, Ctx, CanContinue);

    if not CanContinue then
    begin
      if Assigned(FOnActionBlocked) then
        FOnActionBlocked(Self, Ctx);
      Exit;
    end;

    // Validate
    CanContinue := True;
    if Assigned(FOnBeforeValidate) then
      FOnBeforeValidate(Self, Ctx, CanContinue);

    if not CanContinue then
    begin
      if Assigned(FOnActionBlocked) then
        FOnActionBlocked(Self, Ctx);
      Exit;
    end;

    if Assigned(FOnAfterValidate) then
      FOnAfterValidate(Self, Ctx);

    // Prepare
    CanContinue := True;
    if Assigned(FOnBeforePrepare) then
      FOnBeforePrepare(Self, Ctx, CanContinue);

    if Assigned(FOnAfterPrepare) then
      FOnAfterPrepare(Self, Ctx);

    // Simulate or Execute
    if ASimulate or Ctx.ForcarSimulacao then
    begin
      CanContinue := True;
      if Assigned(FOnBeforeSimulate) then
        FOnBeforeSimulate(Self, Ctx, CanContinue);
      
      // Simulation logic
      Ctx.SaidaAtual := 'Simulated action execution successfully.';
      
      if Assigned(FOnAfterSimulate) then
        FOnAfterSimulate(Self, Ctx);
    end;

    if not ASimulate and not Ctx.ForcarSimulacao then
    begin
      CanContinue := True;
      if Assigned(FOnBeforeExecute) then
        FOnBeforeExecute(Self, Ctx, CanContinue);
      
      // Real Execution logic
      Ctx.SaidaAtual := 'Real action execution completed.';
      
      if Assigned(FOnAfterExecute) then
        FOnAfterExecute(Self, Ctx);
    end;

    Result := True;

    if Assigned(FOnAfterRun) then
      FOnAfterRun(Self, Ctx);

  finally
    Ctx.Free;
  end;
end;

end.
