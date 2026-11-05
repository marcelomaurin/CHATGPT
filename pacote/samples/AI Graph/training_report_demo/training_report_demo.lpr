program training_report_demo;
{$mode objfpc}{$H+}
{$codepage utf8}
uses {$IFDEF UNIX}cthreads,{$ENDIF} Interfaces, Classes, SysUtils, aigraphmap, aitrainingreport;
var Graph: TAIGraphMap; Report: TAITrainingReport; Item: TAITrainingItem; Directory: string;
begin
  Directory := ParamStr(1);
  if Directory = '' then Directory := 'output';
  Directory := IncludeTrailingPathDelimiter(ExpandFileName(Directory));
  if not ForceDirectories(Directory) then raise Exception.Create('Pasta de saída indisponível.');
  Graph := TAIGraphMap.Create(nil);
  Report := TAITrainingReport.Create(nil);
  try
    Item := Graph.Training.Add; Item.InputText := 'bom dia obrigado';
    Item.OutputCategory := 'saudacao'; Item.Weight := 1;
    Item := Graph.Training.Add; Item.InputText := 'erro conectar servidor';
    Item.OutputCategory := 'suporte'; Item.Weight := 1;
    Graph.Train;
    Report.GraphMap := Graph;
    Report.GenerateReportText;
    if not Report.LastSuccess then raise Exception.Create(Report.LastError);
    if Report.ReportText.Count = 0 then raise Exception.Create('Relatório vazio.');
    Report.SaveReport(Directory + 'training_report.txt');
    if not Report.LastSuccess then raise Exception.Create(Report.LastError);
    WriteLn(Report.ReportText.Text);
    WriteLn('PASS: relatório salvo em ', Directory, 'training_report.txt');
  finally Report.Free; Graph.Free; end;
end.
