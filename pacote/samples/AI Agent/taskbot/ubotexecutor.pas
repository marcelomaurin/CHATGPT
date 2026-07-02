unit ubotexecutor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ubottasks, ubotactions;

type
  TLogEvent = procedure(const AMsg: string) of object;
  TReplanEvent = procedure(ATask: TBotTask; AContext: TExecContext) of object;

  { TTaskExecutor }

  TTaskExecutor = class
  private
    FOnLog: TLogEvent;
    FOnReplan: TReplanEvent;
    procedure Log(const AMsg: string);
    function CheckDependencies(ATask: TBotTask; ATasks: TList; out AFailedDep: string): Boolean;
  public
    constructor Create;
    function Run(ATasks: TList; AContext: TExecContext; ARegistry: TActionRegistry): Boolean;

    property OnLog: TLogEvent read FOnLog write FOnLog;
    property OnReplan: TReplanEvent read FOnReplan write FOnReplan;
  end;

implementation

{ TTaskExecutor }

constructor TTaskExecutor.Create;
begin
  inherited Create;
end;

procedure TTaskExecutor.Log(const AMsg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(AMsg);
end;

function TTaskExecutor.CheckDependencies(ATask: TBotTask; ATasks: TList; out AFailedDep: string): Boolean;
var
  DepList: TStringList;
  i, j: Integer;
  DepId: string;
  DepTask: TBotTask;
  Found: Boolean;
begin
  Result := True;
  AFailedDep := '';
  if Trim(ATask.DependsOn) = '' then
    Exit;

  DepList := TStringList.Create;
  try
    DepList.CommaText := ATask.DependsOn;
    for i := 0 to DepList.Count - 1 do
    begin
      DepId := Trim(DepList[i]);
      if DepId = '' then
        Continue;

      Found := False;
      for j := 0 to ATasks.Count - 1 do
      begin
        DepTask := TBotTask(ATasks[j]);
        if SameText(DepTask.Id, DepId) then
        begin
          Found := True;
          if (DepTask.Status = tsFailed) or (DepTask.Status = tsCanceled) then
          begin
            AFailedDep := DepTask.Id;
            Result := False;
            Exit;
          end;
          if DepTask.Status <> tsCompleted then
          begin
            AFailedDep := DepTask.Id + ' (not completed)';
            Result := False;
            Exit;
          end;
          Break;
        end;
      end;
      if not Found then
      begin
        AFailedDep := DepId + ' (missing)';
        Result := False;
        Exit;
      end;
    end;
  finally
    DepList.Free;
  end;
end;

function TTaskExecutor.Run(ATasks: TList; AContext: TExecContext; ARegistry: TActionRegistry): Boolean;
var
  i, j: Integer;
  Task: TBotTask;
  Action: TBotAction;
  FailedDep: string;
  ActionResult: TActionResult;
  RenderedParams: TStringList;
  Key, Val: string;
begin
  Result := True;
  Log('Iniciando execução do plano com ' + IntToStr(ATasks.Count) + ' tarefas.');

  for i := 0 to ATasks.Count - 1 do
  begin
    Task := TBotTask(ATasks[i]);

    Log(Format('Processando tarefa %s (Ordem: %d, Ação: %s)...', [Task.Id, Task.Order, Task.Action]));

    // Verificar dependências
    if not CheckDependencies(Task, ATasks, FailedDep) then
    begin
      Task.Status := tsCanceled;
      Task.ResultMsg := 'Cancelada devido à falha/pendência da dependência: ' + FailedDep;
      Log(Format('Tarefa %s CANCELADA: dependência %s falhou ou não foi concluída.', [Task.Id, FailedDep]));
      Continue;
    end;

    if Task.Status <> tsPending then
      Continue;

    // Verificar allowlist
    Action := ARegistry.Find(Task.Action);
    if Action = nil then
    begin
      Task.Status := tsFailed;
      Task.ResultMsg := 'Ação recusada (não está na allowlist): ' + Task.Action;
      Log(Format('Tarefa %s FALHOU: ação %s recusada pela allowlist.', [Task.Id, Task.Action]));
      Result := False;
      Continue;
    end;

    // Resolver placeholders nos parâmetros da tarefa antes de executar
    RenderedParams := TStringList.Create;
    try
      for j := 0 to Task.Params.Count - 1 do
      begin
        Key := Task.Params.Names[j];
        Val := Task.Params.ValueFromIndex[j];
        RenderedParams.Values[Key] := AContext.Render(Val);
      end;
      Task.Params.Assign(RenderedParams);
    finally
      RenderedParams.Free;
    end;

    Task.Status := tsRunning;
    try
      ActionResult := Action.Execute(Task, AContext);
      case ActionResult of
        aoSuccess:
          begin
            Task.Status := tsCompleted;
            Log(Format('Tarefa %s concluída com sucesso: %s', [Task.Id, Task.ResultMsg]));
          end;
        aoFailed:
          begin
            Task.Status := tsFailed;
            Log(Format('Tarefa %s falhou: %s', [Task.Id, Task.ResultMsg]));
            Result := False;
          end;
        aoBlocked:
          begin
            Task.Status := tsFailed; // Blocked is also a failure of execution path
            Log(Format('Tarefa %s bloqueada por guardas de segurança: %s', [Task.Id, Task.ResultMsg]));
            Result := False;
          end;
      end;
    except
      on E: Exception do
      begin
        Task.Status := tsFailed;
        Task.ResultMsg := 'Exceção durante execução: ' + E.Message;
        Log(Format('Tarefa %s falhou com exceção: %s', [Task.Id, E.Message]));
        Result := False;
      end;
    end;
  end;

  Log('Execução do plano finalizada.');
end;

end.
