program test_aidocuments;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  aioutput_docs, aidocxwriter, aixlsxwriter,
  aidocumentreader, aipdfinput, aidocxinput, aiexcelinput, aidocumentextractor;

procedure TestDOCOUT001;
var
  Docs: TAIOutputDocs;
begin
  WriteLn('[TEST] DOCOUT-001: Token property isolation');
  Docs := TAIOutputDocs.Create(nil);
  try
    Docs.FileNamePDF := 'teste.pdf';
    Docs.Token := 'abc';
    if (Docs.FileNamePDF = 'teste.pdf') and (Docs.Token = 'abc') then
      WriteLn('  [PASS] FileNamePDF = teste.pdf, Token = abc')
    else
    begin
      WriteLn('  [FAIL] DOCOUT-001 Token failed!');
      Halt(1);
    end;
  finally
    Docs.Free;
  end;
end;

procedure TestWordAndDOCX;
var
  WordOut: TAIWordOutput;
  DOCXIn: TAIDOCXInput;
  FileName: string;
begin
  WriteLn('[TEST] WORD & DOCX Generation / Extraction');
  FileName := 'test_output.docx';
  WordOut := TAIWordOutput.Create(nil);
  try
    WordOut.FileName := FileName;
    WordOut.OutputFormat := wofDOCX;
    WordOut.Title := 'DOCX Test Title';
    WordOut.AddHeading('Main Heading 1', 1);
    WordOut.AddHeading('Sub Heading 2', 2);
    WordOut.AddParagraph('This is paragraph 1 with special chars: & < > " and acentos: João & Maria.');
    WordOut.AddTable(['Col A', 'Col B', 'Col C'], ['Cell 1', 'Cell 2', 'Cell 3', 'Cell 4', 'Cell 5'], 3);

    if not WordOut.SaveWord then
    begin
      WriteLn('  [FAIL] Failed to save DOCX file');
      Halt(1);
    end;
  finally
    WordOut.Free;
  end;

  DOCXIn := TAIDOCXInput.Create(nil);
  try
    if not DOCXIn.LoadFromFile(FileName) then
    begin
      WriteLn('  [FAIL] Failed to load generated DOCX file: ' + DOCXIn.LastError);
      Halt(1);
    end;

    if (Pos('Main Heading 1', DOCXIn.Text) > 0) and (Pos('Cell 1', DOCXIn.Text) > 0) then
      WriteLn('  [PASS] DOCX round-trip text verified successfully.')
    else
    begin
      WriteLn('  [FAIL] DOCX extracted text missing expected content.');
      Halt(1);
    end;
  finally
    DOCXIn.Free;
  end;
end;

procedure TestExcelAndXLSX;
var
  XlsOut: TAIExcelOutput;
  XlsIn: TAIExcelInput;
  FileName: string;
begin
  WriteLn('[TEST] XLS & XLSX Generation / Extraction');
  FileName := 'test_output.xlsx';
  XlsOut := TAIExcelOutput.Create(nil);
  try
    XlsOut.FileName := FileName;
    XlsOut.OutputFormat := eofXLSX;
    XlsOut.SetCell(0, 0, 'Nome');
    XlsOut.SetCell(0, 1, 'Idade');
    XlsOut.SetCell(0, 2, 'Cidade');

    XlsOut.SetCell(1, 0, 'João & Maria');
    XlsOut.SetCell(1, 1, '30');
    XlsOut.SetCell(1, 2, 'Ribeirão Preto');

    if not XlsOut.SaveExcel then
    begin
      WriteLn('  [FAIL] Failed to save XLSX file');
      Halt(1);
    end;
  finally
    XlsOut.Free;
  end;

  XlsIn := TAIExcelInput.Create(nil);
  try
    if not XlsIn.LoadFromFile(FileName) then
    begin
      WriteLn('  [FAIL] Failed to load generated XLSX file: ' + XlsIn.LastError);
      Halt(1);
    end;

    if (XlsIn.GetCell(0, 0) = 'Nome') and (Pos('Ribeirão Preto', XlsIn.ToText) > 0) then
      WriteLn('  [PASS] XLSX round-trip cells verified successfully.')
    else
    begin
      WriteLn('  [FAIL] XLSX extracted cell content mismatch.');
      Halt(1);
    end;
  finally
    XlsIn.Free;
  end;
end;

procedure TestDocumentExtractorRegistry;
var
  ExtractorReg: TAIDocumentExtractorRegistry;
  ExtractedText, ErrorStr: string;
begin
  WriteLn('[TEST] Document Extractor Registry');
  ExtractorReg := GlobalExtractorRegistry;
  if ExtractorReg.ExtractText('test_output.docx', ExtractedText, ErrorStr) then
    WriteLn('  [PASS] Registry extracted text from DOCX.')
  else
    WriteLn('  [WARN] Extractor error: ' + ErrorStr);
end;

begin
  WriteLn('====================================================');
  WriteLn('   RUNNING AI DOCUMENTS UNIT & INTEGRATION TESTS    ');
  WriteLn('====================================================');

  TestDOCOUT001;
  TestWordAndDOCX;
  TestExcelAndXLSX;
  TestDocumentExtractorRegistry;

  WriteLn('====================================================');
  WriteLn('   ALL AI DOCUMENTS TESTS COMPLETED SUCCESSFULLY!   ');
  WriteLn('====================================================');
end.
