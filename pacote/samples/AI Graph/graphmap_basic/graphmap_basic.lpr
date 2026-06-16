program graphmap_basic;

{$mode objfpc}{$H+}

uses
  Interfaces, Classes, SysUtils, aigraphmap;

var
  GraphMap: TAIGraphMap;
  Item: TAITrainingItem;
  ResultCat: string;
  Explanation: TStringList;
  I: Integer;
begin
  WriteLn('--- TAIGraphMap Basic Sample ---');
  GraphMap := TAIGraphMap.Create(nil);
  try
    // Configure synonyms
    GraphMap.Synonyms.Add('db=banco');
    GraphMap.Synonyms.Add('database=banco');
    GraphMap.Synonyms.Add('postgresql=postgres');
    
    // Add training items
    WriteLn('Adding training examples...');
    Item := GraphMap.Training.Add;
    Item.InputText := 'erro ao conectar no postgres';
    Item.OutputCategory := 'banco_dados';
    Item.Weight := 1.0;
    
    Item := GraphMap.Training.Add;
    Item.InputText := 'falha na impressora sem papel';
    Item.OutputCategory := 'impressora';
    Item.Weight := 1.0;
    
    Item := GraphMap.Training.Add;
    Item.InputText := 'cabo de rede desconectado';
    Item.OutputCategory := 'rede';
    Item.Weight := 1.0;
    
    WriteLn('Training graph...');
    GraphMap.Train;
    
    WriteLn('Nodes created: ', GraphMap.NodeCount);
    WriteLn('Edges created: ', GraphMap.EdgeCount);
    
    // Predict
    WriteLn('Predicting text: "erro no db postgresql"');
    ResultCat := GraphMap.Predict('erro no db postgresql');
    WriteLn('Selected Category: ', ResultCat);
    WriteLn('Ranking:');
    for I := 0 to GraphMap.LastRanking.Count - 1 do
      WriteLn('  ', GraphMap.LastRanking[I]);
      
    // Explanation
    WriteLn;
    WriteLn('Explanation:');
    Explanation := TStringList.Create;
    try
      GraphMap.ExplainPrediction('erro no db postgresql', Explanation);
      WriteLn(Explanation.Text);
    finally
      Explanation.Free;
    end;
    
  finally
    GraphMap.Free;
  end;
  WriteLn('Press enter to exit.');
end.
