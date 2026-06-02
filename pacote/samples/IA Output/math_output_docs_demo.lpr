program math_output_docs_demo;

{$mode objfpc}{$H+}

uses
  SysUtils, Classes, aioutput_docs;

var
  PDFOut: TAIPDFOutput;
  WordOut: TAIWordOutput;
  ExcelOut: TAIExcelOutput;
  TxtOut: TAITXTOutput;
  DocsOut: TAIOutputDocs;
  
  Headers: array[0..2] of string;
  Rows: array[0..5] of string;
  
  Headers2: array[0..1] of string;
  Rows2: array[0..1] of string;
begin
  Writeln('=== Exemplo de Uso da Suite de Documentos (IA Output) ===');
  Writeln;

  // 1. PDF Generation
  Writeln('1. Gerando documento PDF NATIVO...');
  PDFOut := TAIPDFOutput.Create(nil);
  try
    Writeln('  [IA PROMPT] -> ', PDFOut.Prompt);
    PDFOut.FileName := 'relatorio_ia_gerado.pdf';
    PDFOut.Title := 'Relatorio de Inteligencia Artificial';
    PDFOut.StartDocument;
    PDFOut.AddPage;
    PDFOut.AddText('RELATORIO ANALITICO DE MODELOS DE IA', 50, 50, 18);
    PDFOut.AddText('Autor: Suite Antigravity AI para Lazarus', 50, 80, 12);
    PDFOut.AddText('Este documento foi gerado de forma 100% nativa em Pascal.', 50, 120, 10);
    PDFOut.AddText('Resultados preditivos convergem para a classe Cachorro (98.4%).', 50, 140, 10);
    
    if PDFOut.SavePDF then
      Writeln('  -> PDF salvo com sucesso em: ', PDFOut.FileName)
    else
      Writeln('  -> Erro ao salvar PDF.');
  finally
    PDFOut.Free;
  end;
  Writeln;

  // 2. Word Generation
  Writeln('2. Gerando documento Word (.docx)...');
  WordOut := TAIWordOutput.Create(nil);
  try
    Writeln('  [IA PROMPT] -> ', WordOut.Prompt);
    WordOut.FileName := 'relatorio_ia_gerado.docx';
    WordOut.Title := 'Relatorio de IA';
    WordOut.AddHeading('Relatorio Analitico de Classificacao', 1);
    WordOut.AddParagraph('Este e um relatorio formal gerado de forma automatica.');
    
    Headers[0] := 'Classe';
    Headers[1] := 'Logit Bruto';
    Headers[2] := 'Probabilidade';
    
    Rows[0] := 'Cachorro'; Rows[1] := '2.0'; Rows[2] := '70.5%';
    Rows[3] := 'Gato';     Rows[4] := '0.8'; Rows[5] := '29.5%';
    
    WordOut.AddTable(Headers, Rows, 3);
    
    if WordOut.SaveWord then
      Writeln('  -> Word (.docx) salvo com sucesso em: ', WordOut.FileName)
    else
      Writeln('  -> Erro ao salvar Word.');
  finally
    WordOut.Free;
  end;
  Writeln;

  // 3. Excel Generation
  Writeln('3. Gerando Planilha Excel (.xlsx)...');
  ExcelOut := TAIExcelOutput.Create(nil);
  try
    Writeln('  [IA PROMPT] -> ', ExcelOut.Prompt);
    ExcelOut.FileName := 'dados_ia_gerados.xlsx';
    ExcelOut.SetCell(0, 0, 'Metrica');
    ExcelOut.SetCell(0, 1, 'Valor Obtido');
    ExcelOut.SetCell(1, 0, 'Precisao (Accuracy)');
    ExcelOut.SetCell(1, 1, '97.2%');
    ExcelOut.SetCell(2, 0, 'Perda de Treino (Loss)');
    ExcelOut.SetCell(2, 1, '0.042');
    ExcelOut.SetCell(3, 0, 'Epocas de Processamento');
    ExcelOut.SetCell(3, 1, '500');
    
    if ExcelOut.SaveExcel then
      Writeln('  -> Excel (.xlsx) salvo com sucesso em: ', ExcelOut.FileName)
    else
      Writeln('  -> Erro ao salvar Excel.');
  finally
    ExcelOut.Free;
  end;
  Writeln;

  // 4. Plain Text Generation
  Writeln('4. Gerando Arquivo de Texto plano (.txt)...');
  TxtOut := TAITXTOutput.Create(nil);
  try
    Writeln('  [IA PROMPT] -> ', TxtOut.Prompt);
    TxtOut.FileName := 'relatorio_ia_gerado.txt';
    TxtOut.AddHeader('Resumo de Execucao do Pipeline de IA');
    TxtOut.AddLine('Data: ' + DateTimeToStr(Now));
    TxtOut.AddLine('Status do Servidor: ATIVO');
    TxtOut.AddLine('Porta de Entrada: 8080');
    TxtOut.AddLine('Mensagens Processadas: 1420');
    TxtOut.AddLine('Ultimo log registrado com sucesso.');
    
    if TxtOut.SaveText then
      Writeln('  -> TXT salvo com sucesso em: ', TxtOut.FileName)
    else
      Writeln('  -> Erro ao salvar TXT.');
  finally
    TxtOut.Free;
  end;
  Writeln;

  // 5. Unified Document Output Suite Generation
  Writeln('5. Gerando documentos unificados simultaneos (.pdf, .docx, .xlsx, .txt) via TAIOutputDocs...');
  DocsOut := TAIOutputDocs.Create(nil);
  try
    Writeln('  [IA PROMPT] -> ', DocsOut.Prompt);
    DocsOut.Title := 'Relatorio Unificado de Inteligencia Artificial';
    DocsOut.Author := 'Suite Antigravity AI';
    DocsOut.Subject := 'Resultados do Pipeline';
    DocsOut.Clear;
    DocsOut.AddParagraph('Este e um relatorio unificado exportado simultaneamente para quatro formatos.');
    DocsOut.AddParagraph('Processamento concluido de forma 100% nativa e multiplataforma.');
    
    Headers2[0] := 'Metrica'; Headers2[1] := 'Resultado';
    Rows2[0] := 'Acuracia'; Rows2[1] := '98.5%';
    DocsOut.AddTable(Headers2, Rows2, 2);
    
    if DocsOut.SaveAll('relatorio_ia_unificado') then
      Writeln('  -> Todos os relatorios unificados (.pdf, .docx, .xlsx, .txt) foram gerados com sucesso!')
    else
      Writeln('  -> Erro ao gerar relatorios unificados.');
  finally
    DocsOut.Free;
  end;
  Writeln;

  Writeln('Sucesso absoluto na geracao da suite de documentos!');
  Writeln('Pressione [Enter] para finalizar.');
  Readln;
end.
