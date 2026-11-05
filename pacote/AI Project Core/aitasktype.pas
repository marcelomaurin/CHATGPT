unit aitasktype;

{ Lazarus AI Suite - AI Project Core
  Tipo de tarefa no estilo do Microsoft Project (generico, sem LCL).

  Formula: Trabalho = Duracao x Unidades
    Duracao  minutos (Int64)
    Unidades soma das unidades dos recursos de trabalho (1 = 100%)
    Trabalho minutos de trabalho (Int64)

  O tipo diz qual das tres grandezas fica fixa quando outra muda:
    fixed_units     unidades fixas: mudar a duracao muda o trabalho; mudar o
                    trabalho ou as unidades muda a duracao
    fixed_duration  duracao fixa: mudar o trabalho ou as unidades nao mexe na
                    duracao; mudar o trabalho muda as unidades
    fixed_work      trabalho fixo (sempre controlada pelo empenho): mudar a
                    duracao muda as unidades; mudar as unidades muda a duracao

  Controlada pelo empenho: ao incluir ou retirar recursos, o trabalho total
  se mantem. Unidades e trabalho fixo encurtam ou alongam a duracao; duracao
  fixa redistribui as unidades. Sem empenho, incluir um recurso soma
  trabalho e a duracao fica.

  As funcoes sao puras: recebem o estado antigo e devolvem a duracao nova e um
  fator para multiplicar as unidades de cada atribuicao (1 = nao mexer).
  Tarefa sem recurso de trabalho (unidades 0) nao tem trabalho: nada muda. }

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Math;

type
  TAITaskType = (attFixedDuration, attFixedUnits, attFixedWork);

  { resultado de um recalculo }
  TAITaskTypeResult = record
    Ok: Boolean;
    Duration: Int64;      // minutos
    UnitScale: Double;    // multiplicar as unidades de cada atribuicao
    Work: Int64;          // minutos
    Error: string;
  end;

const
  { unidades abaixo disso sao tratadas como zero (0,1% de uma pessoa) }
  AI_MIN_UNITS = 0.001;

function AITaskTypeName(T: TAITaskType): string;
function AITryTaskTypeFromName(const S: string; out T: TAITaskType): Boolean;
function AITaskTypeCaption(T: TAITaskType): string;

{ trabalho = duracao x unidades, arredondado ao minuto }
function AIWorkOf(ADuration: Int64; AUnits: Double): Int64;

{ trabalho fixo e sempre controlado pelo empenho }
function AIIsEffortDriven(T: TAITaskType; AEffortDriven: Boolean): Boolean;

{ a duracao mudou de AOld para ANew }
function AIOnDurationChange(T: TAITaskType; AOldDuration, ANewDuration: Int64;
  AUnits: Double): TAITaskTypeResult;

{ o trabalho foi digitado; recusa tarefa sem recurso de trabalho }
function AIOnWorkChange(T: TAITaskType; ADuration: Int64; AUnits: Double;
  ANewWork: Int64): TAITaskTypeResult;

{ as unidades mudaram de AOldUnits para ANewUnits.
  AResourceSetChanged = recursos incluidos ou retirados (vale o empenho);
  False = so as unidades de quem ja estava mudaram. }
function AIOnUnitsChange(T: TAITaskType; AEffortDriven, AResourceSetChanged: Boolean;
  ADuration: Int64; AOldUnits, ANewUnits: Double): TAITaskTypeResult;

implementation

const
  TYPE_NAMES: array[TAITaskType] of string = ('fixed_duration', 'fixed_units', 'fixed_work');
  TYPE_CAPTIONS: array[TAITaskType] of string = ('Duracao fixa', 'Unidades fixas', 'Trabalho fixo');

function AITaskTypeName(T: TAITaskType): string;
begin
  Result := TYPE_NAMES[T];
end;

function AITryTaskTypeFromName(const S: string; out T: TAITaskType): Boolean;
var I: TAITaskType;
begin
  for I := Low(I) to High(I) do
    if SameText(Trim(S), TYPE_NAMES[I]) then begin T := I; Exit(True); end;
  T := attFixedDuration;
  Result := False;
end;

function AITaskTypeCaption(T: TAITaskType): string;
begin
  Result := TYPE_CAPTIONS[T];
end;

function AIWorkOf(ADuration: Int64; AUnits: Double): Int64;
begin
  if (ADuration <= 0) or (AUnits < AI_MIN_UNITS) then Exit(0);
  Result := Round(ADuration * AUnits);
end;

function AIIsEffortDriven(T: TAITaskType; AEffortDriven: Boolean): Boolean;
begin
  Result := AEffortDriven or (T = attFixedWork);
end;

function Make(ADuration: Int64; AScale, AUnits: Double): TAITaskTypeResult;
begin
  Result.Ok := True;
  Result.Error := '';
  Result.Duration := Max(Int64(0), ADuration);
  Result.UnitScale := AScale;
  Result.Work := AIWorkOf(Result.Duration, AUnits * AScale);
end;

function Fail(const Msg: string; ADuration: Int64; AUnits: Double): TAITaskTypeResult;
begin
  Result := Make(ADuration, 1, AUnits);
  Result.Ok := False;
  Result.Error := Msg;
end;

{ duracao para um trabalho com estas unidades (minimo 1 min quando ha trabalho) }
function DurationFor(AWork: Int64; AUnits: Double): Int64;
begin
  if AWork <= 0 then Exit(0);
  Result := Max(Int64(1), Round(AWork / AUnits));
end;

function AIOnDurationChange(T: TAITaskType; AOldDuration, ANewDuration: Int64;
  AUnits: Double): TAITaskTypeResult;
begin
  if ANewDuration < 0 then Exit(Fail('duracao negativa', AOldDuration, AUnits));
  if (AUnits < AI_MIN_UNITS) or (T <> attFixedWork) or (AOldDuration <= 0) then
    Exit(Make(ANewDuration, 1, AUnits));
  { trabalho fixo: as unidades absorvem a mudanca }
  if ANewDuration = 0 then
    Exit(Fail('trabalho fixo: a duracao nao pode ser zero com recurso atribuido', AOldDuration, AUnits));
  Result := Make(ANewDuration, AOldDuration / ANewDuration, AUnits);
  { o trabalho continua o mesmo, sem erro de arredondamento }
  Result.Work := AIWorkOf(AOldDuration, AUnits);
end;

function AIOnWorkChange(T: TAITaskType; ADuration: Int64; AUnits: Double;
  ANewWork: Int64): TAITaskTypeResult;
begin
  if ANewWork < 0 then Exit(Fail('trabalho negativo', ADuration, AUnits));
  if AUnits < AI_MIN_UNITS then
    Exit(Fail('atribua um recurso de trabalho (pessoa, IA ou maquina) antes de informar o trabalho',
      ADuration, AUnits));
  if T = attFixedDuration then
  begin
    if ADuration <= 0 then
      Exit(Fail('duracao fixa em zero: informe a duracao antes do trabalho', ADuration, AUnits));
    Result := Make(ADuration, ANewWork / (ADuration * AUnits), AUnits);
    Result.Work := ANewWork;
    if ANewWork = 0 then
      Exit(Fail('duracao fixa: trabalho zero zeraria as unidades; retire o recurso', ADuration, AUnits));
  end
  else
  begin
    Result := Make(DurationFor(ANewWork, AUnits), 1, AUnits);
    Result.Work := ANewWork;
  end;
end;

function AIOnUnitsChange(T: TAITaskType; AEffortDriven, AResourceSetChanged: Boolean;
  ADuration: Int64; AOldUnits, ANewUnits: Double): TAITaskTypeResult;
var OldWork: Int64;
begin
  if ANewUnits < 0 then Exit(Fail('unidades negativas', ADuration, AOldUnits));
  OldWork := AIWorkOf(ADuration, AOldUnits);
  { sem trabalho antes ou depois: so atualiza o trabalho }
  if (AOldUnits < AI_MIN_UNITS) or (ANewUnits < AI_MIN_UNITS) or (ADuration <= 0) then
    Exit(Make(ADuration, 1, ANewUnits));
  if AResourceSetChanged then
  begin
    if not AIIsEffortDriven(T, AEffortDriven) then
      Exit(Make(ADuration, 1, ANewUnits));          // soma trabalho, duracao fica
    if T = attFixedDuration then
    begin
      { mesmo trabalho na mesma duracao: unidades redistribuidas }
      Result := Make(ADuration, AOldUnits / ANewUnits, ANewUnits);
      Result.Work := OldWork;
    end
    else
    begin
      Result := Make(DurationFor(OldWork, ANewUnits), 1, ANewUnits);
      Result.Work := OldWork;
    end;
  end
  else
  begin
    { mudaram as unidades de quem ja estava }
    if T = attFixedDuration then
      Exit(Make(ADuration, 1, ANewUnits));          // trabalho acompanha
    Result := Make(DurationFor(OldWork, ANewUnits), 1, ANewUnits);
    Result.Work := OldWork;
  end;
end;

end.
