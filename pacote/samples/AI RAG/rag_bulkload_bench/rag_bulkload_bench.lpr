program rag_bulkload_bench;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  SysUtils, DateUtils, aigraphmap, airag;

const
  QTD_REGISTROS = 20000;

procedure Medir(AUsarBulk: Boolean);
var
  LGraph: TAIGraphMap;
  LRag: TAIRAG;
  I: Integer;
  LInicio: TDateTime;
  LMs: Int64;
  LRotulo: string;
begin
  if AUsarBulk then
    LRotulo := 'COM BeginBulkLoad'
  else
    LRotulo := 'SEM BeginBulkLoad';

  LGraph := TAIGraphMap.Create(nil);
  LRag := TAIRAG.Create(nil);
  try
    LRag.GraphMap := LGraph;
    LRag.ChunkSize := 4000;
    LRag.ChunkOverlap := 0;

    if AUsarBulk then
      LRag.BeginBulkLoad;

    LInicio := Now;
    for I := 1 to QTD_REGISTROS do
      LRag.AddText(
        Format('row/public.clientes/%d', [I]),
        Format('Cliente numero %d, cidade Ribeirao Preto, situacao ativa.', [I]));
    LMs := MilliSecondsBetween(Now, LInicio);

    if AUsarBulk then
      LRag.EndBulkLoad;

    WriteLn(Format('%-20s | %6d registros | %8d ms | %6d chunks',
      [LRotulo, QTD_REGISTROS, LMs, LGraph.Training.Count]));
  finally
    LRag.Free;
    LGraph.Free;
  end;
end;

begin
  WriteLn('=== Benchmark de carga em massa do TAIRAG ===');
  WriteLn('');
  Medir(False);
  Medir(True);
  WriteLn('');
  WriteLn('Fim.');
end.
