program taskbot;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, ubottasks, ubotactions, ubotplanner, ubotexecutor;

type
  { TLogHelper }
  TLogHelper = class
  public
    procedure LogToConsole(const AMsg: string);
  end;

  { TMockSearchAction }
  TMockSearchAction = class(TBotAction)
  private
    FFailSim: Boolean;
  public
    constructor Create(const AName: string; AFailSim: Boolean); reintroduce;
    function Execute(ATask: TBotTask; AContext: TExecContext): TActionResult; override;
  end;

  { TMockExtractAction }
  TMockExtractAction = class(TBotAction)
  public
    function Execute(ATask: TBotTask; AContext: TExecContext): TActionResult; override;
  end;

  { TMockEmailAction }
  TMockEmailAction = class(TBotAction)
  public
    function Execute(ATask: TBotTask; AContext: TExecContext): TActionResult; override;
  end;

var
  LogHelper: TLogHelper;

{ TLogHelper }

procedure TLogHelper.LogToConsole(const AMsg: string);
begin
  WriteLn('[LOG] ' + AMsg);
end;

{ TMockSearchAction }

constructor TMockSearchAction.Create(const AName: string; AFailSim: Boolean);
begin
  inherited Create(AName);
  FFailSim := AFailSim;
end;

function TMockSearchAction.Execute(ATask: TBotTask; AContext: TExecContext): TActionResult;
begin
  if FFailSim then
  begin
    ATask.ResultMsg := 'Simulação de erro na busca do produto.';
    Result := aoFailed;
  end
  else
  begin
    AContext.SetValue('busca.termo', ATask.Params.Values['termo']);
    ATask.ResultMsg := 'Busca realizada com sucesso para: ' + ATask.Params.Values['termo'];
    Result := aoSuccess;
  end;
end;

{ TMockExtractAction }

function TMockExtractAction.Execute(ATask: TBotTask; AContext: TExecContext): TActionResult;
begin
  // Simular extração
  AContext.SetValue('produto.link', 'https://loja.com/produto123');
  AContext.SetValue('produto.preco', 'R$ 99,90');
  ATask.ResultMsg := 'Extraído produto.link=https://loja.com/produto123, produto.preco=R$ 99,90';
  Result := aoSuccess;
end;

{ TMockEmailAction }

function TMockEmailAction.Execute(ATask: TBotTask; AContext: TExecContext): TActionResult;
var
  Dest, Subject, Body: string;
begin
  Dest := ATask.Params.Values['destino'];
  Subject := ATask.Params.Values['assunto'];
  Body := ATask.Params.Values['corpo'];

  // Validar se tem placeholders não resolvidos
  if (Pos('{{', Body) > 0) or (Pos('}}', Body) > 0) then
  begin
    ATask.ResultMsg := 'Bloqueado: Corpo do e-mail contém placeholders não resolvidos.';
    Result := aoBlocked;
    Exit;
  end;

  // Validar se tem link real
  if (Pos('http://', Body) = 0) and (Pos('https://', Body) = 0) then
  begin
    ATask.ResultMsg := 'Bloqueado: Nenhuma URL real encontrada no corpo do e-mail.';
    Result := aoBlocked;
    Exit;
  end;

  ATask.ResultMsg := Format('E-mail real simulado enviado para %s (Assunto: %s).', [Dest, Subject]);
  Result := aoSuccess;
end;

// Helper simple implementation of IfThen for console output
function IfThen(Val: Boolean; const A, B: string): string;
begin
  if Val then Result := A else Result := B;
end;

procedure RunScenarioA;
var
  Context: TExecContext;
  Registry: TActionRegistry;
  Executor: TTaskExecutor;
  Tasks: TList;
  T1, T2, T3: TBotTask;
  Success: Boolean;
begin
  WriteLn('=== EXECUÇÃO DO CENÁRIO A: SUCESSO COMPLETO ===');
  Context := TExecContext.Create;
  Registry := TActionRegistry.Create;
  Executor := TTaskExecutor.Create;
  Executor.OnLog := @LogHelper.LogToConsole;
  Tasks := TList.Create;
  try
    // Registrar ações mockadas
    Registry.Add(TMockSearchAction.Create('SEARCH', False));
    Registry.Add(TMockExtractAction.Create('EXTRACT'));
    Registry.Add(TMockEmailAction.Create('SEND_EMAIL'));

    // Criar tarefas
    T1 := NewTask('T01', 1, 'SEARCH', 'Buscar produto mais barato', '');
    T1.Params.Values['termo'] := 'Celular barato';
    Tasks.Add(T1);

    T2 := NewTask('T02', 2, 'EXTRACT', 'Extrair link e preco', 'T01');
    Tasks.Add(T2);

    T3 := NewTask('T03', 3, 'SEND_EMAIL', 'Enviar link por e-mail', 'T02');
    T3.Params.Values['destino'] := 'user@teste.com';
    T3.Params.Values['assunto'] := 'Oferta encontrada';
    T3.Params.Values['corpo'] := 'Confira o link do produto: {{produto.link}} com preco {{produto.preco}}';
    Tasks.Add(T3);

    Success := Executor.Run(Tasks, Context, Registry);

    WriteLn('Status Final das Tarefas:');
    WriteLn(Format('T01 Status: %d, Msg: %s', [Ord(T1.Status), T1.ResultMsg]));
    WriteLn(Format('T02 Status: %d, Msg: %s', [Ord(T2.Status), T2.ResultMsg]));
    WriteLn(Format('T03 Status: %d, Msg: %s', [Ord(T3.Status), T3.ResultMsg]));
    WriteLn(Format('Execução geral: %s', [IfThen(Success, 'SUCESSO', 'FALHA')]));
  finally
    T1.Free;
    T2.Free;
    T3.Free;
    Tasks.Free;
    Executor.Free;
    Registry.Free;
    Context.Free;
  end;
end;

procedure RunScenarioB;
var
  Context: TExecContext;
  Registry: TActionRegistry;
  Executor: TTaskExecutor;
  Tasks: TList;
  T1, T2, T3: TBotTask;
  Success: Boolean;
begin
  WriteLn('=== EXECUÇÃO DO CENÁRIO B: FALHA E CANCELAMENTO EM CASCATA ===');
  Context := TExecContext.Create;
  Registry := TActionRegistry.Create;
  Executor := TTaskExecutor.Create;
  Executor.OnLog := @LogHelper.LogToConsole;
  Tasks := TList.Create;
  try
    // Registrar ações mockadas (Search vai falhar!)
    Registry.Add(TMockSearchAction.Create('SEARCH', True));
    Registry.Add(TMockExtractAction.Create('EXTRACT'));
    Registry.Add(TMockEmailAction.Create('SEND_EMAIL'));

    // Criar tarefas
    T1 := NewTask('T01', 1, 'SEARCH', 'Buscar produto mais barato', '');
    T1.Params.Values['termo'] := 'Celular barato';
    Tasks.Add(T1);

    T2 := NewTask('T02', 2, 'EXTRACT', 'Extrair link e preco', 'T01');
    Tasks.Add(T2);

    T3 := NewTask('T03', 3, 'SEND_EMAIL', 'Enviar link por e-mail', 'T02');
    T3.Params.Values['destino'] := 'user@teste.com';
    T3.Params.Values['assunto'] := 'Oferta encontrada';
    T3.Params.Values['corpo'] := 'Confira o link do produto: {{produto.link}}';
    Tasks.Add(T3);

    Success := Executor.Run(Tasks, Context, Registry);

    WriteLn('Status Final das Tarefas:');
    WriteLn(Format('T01 Status: %d, Msg: %s', [Ord(T1.Status), T1.ResultMsg]));
    WriteLn(Format('T02 Status: %d, Msg: %s', [Ord(T2.Status), T2.ResultMsg]));
    WriteLn(Format('T03 Status: %d, Msg: %s', [Ord(T3.Status), T3.ResultMsg]));
    WriteLn(Format('Execução geral: %s', [IfThen(Success, 'SUCESSO', 'FALHA')]));
  finally
    T1.Free;
    T2.Free;
    T3.Free;
    Tasks.Free;
    Executor.Free;
    Registry.Free;
    Context.Free;
  end;
end;

begin
  LogHelper := TLogHelper.Create;
  try
    RunScenarioA;
    WriteLn;
    RunScenarioB;
  finally
    LogHelper.Free;
  end;
end.
