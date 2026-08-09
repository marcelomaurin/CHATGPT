program eval_demo;

{$mode objfpc}{$H+}
{$APPTYPE CONSOLE}

uses
  Interfaces, SysUtils, aievaluation;

var
  Data: TAIEvaluationDataset;
  Eval: TAILexicalEvaluator;
  C: TAIEvaluationCase;
begin
  Data := TAIEvaluationDataset.Create(nil);
  Eval := TAILexicalEvaluator.Create(nil);
  try
    C := Data.AddCase('capital', 'Capital da Franca?', 'Paris');
    C.Actual := 'A capital da Franca e Paris.';
    Writeln('lexical score=', FormatFloat('0.0000', Eval.EvaluateCase(C)));
    C.Context := 'Franca e um pais europeu.';
    C.Chunks.Add('Paris e a capital da Franca.');
    C.Sources.Add('atlas.txt');
    Writeln('rag score=', FormatFloat('0.0000', Eval.EvaluateRAG(C)));
  finally Eval.Free; Data.Free; end;
end.
