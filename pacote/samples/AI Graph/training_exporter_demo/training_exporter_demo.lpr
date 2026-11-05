program training_exporter_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Interfaces, Classes, SysUtils, aigraphmap, aitrainingexporter;
var Exporter: TAITrainingExporter; Item: TAITrainingItem; Directory, MessageText: string;
    Count, Categories, Tokens: Integer;
begin
  Directory := ParamStr(1);
  if Directory = '' then Directory := 'output';
  Directory := IncludeTrailingPathDelimiter(ExpandFileName(Directory));
  if not ForceDirectories(Directory) then raise Exception.Create('Não foi possível criar a pasta de saída.');
  Exporter := TAITrainingExporter.Create(nil);
  try
    Item := Exporter.TrainingItems.Add; Item.InputText := 'bom dia obrigado';
    Item.OutputCategory := 'saudacao'; Item.Weight := 1;
    Item := Exporter.TrainingItems.Add; Item.InputText := 'erro ao conectar servidor';
    Item.OutputCategory := 'suporte'; Item.Weight := 1;
    if not Exporter.ValidateDataset(MessageText) then raise Exception.Create(MessageText);
    Exporter.GetDatasetStats(Count, Categories, Tokens);
    WriteLn('Itens: ', Count, '; categorias: ', Categories, '; tokens: ', Tokens);
    Exporter.ExportFormat := efCSV;
    if not Exporter.ExportToFile(Directory + 'training.csv') then raise Exception.Create(Exporter.LastError);
    Exporter.ExportFormat := efJSONL;
    if not Exporter.ExportToFile(Directory + 'training.jsonl') then raise Exception.Create(Exporter.LastError);
    WriteLn('PASS: CSV e JSONL exportados para ', Directory);
  finally Exporter.Free; end;
end.
