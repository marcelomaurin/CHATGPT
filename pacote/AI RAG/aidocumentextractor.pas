unit aidocumentextractor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aidocumentreader, aipdfinput, aidocxinput, aiexcelinput;

type
  { IAIDocumentTextExtractor }
  IAIDocumentTextExtractor = interface
    ['{D9E8F7A6-5B4C-3D2E-1F0A-9B8C7D6E5F4A}']
    function SupportsExtension(const AExtension: string): Boolean;
    function ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
  end;

  { TAIDocumentExtractorRegistry }

  TAIDocumentExtractorRegistry = class
  private
    FExtractors: array of IAIDocumentTextExtractor;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterExtractor(const AExtractor: IAIDocumentTextExtractor);
    function ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
  end;

  { TBuiltInDocumentTextExtractor }

  TBuiltInDocumentTextExtractor = class(TInterfacedObject, IAIDocumentTextExtractor)
  public
    function SupportsExtension(const AExtension: string): Boolean;
    function ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
  end;

function GlobalExtractorRegistry: TAIDocumentExtractorRegistry;

implementation

var
  GRegistry: TAIDocumentExtractorRegistry = nil;

function GlobalExtractorRegistry: TAIDocumentExtractorRegistry;
begin
  if GRegistry = nil then
  begin
    GRegistry := TAIDocumentExtractorRegistry.Create;
    GRegistry.RegisterExtractor(TBuiltInDocumentTextExtractor.Create);
  end;
  Result := GRegistry;
end;

{ TBuiltInDocumentTextExtractor }

function TBuiltInDocumentTextExtractor.SupportsExtension(const AExtension: string): Boolean;
var
  Ext: string;
begin
  Ext := LowerCase(AExtension);
  Result := (Ext = '.pdf') or (Ext = '.docx') or (Ext = '.xlsx') or (Ext = '.txt');
end;

function TBuiltInDocumentTextExtractor.ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
var
  Ext: string;
  PDFIn: TAIPDFInput;
  DOCXIn: TAIDOCXInput;
  XLSIn: TAIExcelInput;
  TXTIn: TAIDocumentInput;
begin
  Result := False;
  AText := '';
  AError := '';
  Ext := LowerCase(ExtractFileExt(AFileName));

  if Ext = '.pdf' then
  begin
    PDFIn := TAIPDFInput.Create(nil);
    try
      if PDFIn.LoadFromFile(AFileName) then
      begin
        AText := PDFIn.FullText;
        Result := True;
      end;
    finally
      PDFIn.Free;
    end;
  end;

  if (not Result) and (Ext = '.docx') then
  begin
    DOCXIn := TAIDOCXInput.Create(nil);
    try
      if DOCXIn.LoadFromFile(AFileName) then
      begin
        AText := DOCXIn.Text;
        Result := True;
      end;
    finally
      DOCXIn.Free;
    end;
  end;

  if (not Result) and (Ext = '.xlsx') then
  begin
    XLSIn := TAIExcelInput.Create(nil);
    try
      if XLSIn.LoadFromFile(AFileName) then
      begin
        AText := XLSIn.ToText;
        Result := True;
      end;
    finally
      XLSIn.Free;
    end;
  end;

  if (not Result) then
  begin
    TXTIn := TAIDocumentInput.Create(nil);
    try
      if TXTIn.LoadFromFile(AFileName) then
      begin
        AText := TXTIn.Text;
        Result := True;
      end;
    finally
      TXTIn.Free;
    end;
  end;

  if not Result then
    AError := 'Não foi possível extrair texto do documento: ' + AFileName;
end;

{ TAIDocumentExtractorRegistry }

constructor TAIDocumentExtractorRegistry.Create;
begin
  SetLength(FExtractors, 0);
end;

destructor TAIDocumentExtractorRegistry.Destroy;
begin
  SetLength(FExtractors, 0);
  inherited Destroy;
end;

procedure TAIDocumentExtractorRegistry.RegisterExtractor(const AExtractor: IAIDocumentTextExtractor);
var
  Idx: Integer;
begin
  Idx := Length(FExtractors);
  SetLength(FExtractors, Idx + 1);
  FExtractors[Idx] := AExtractor;
end;

function TAIDocumentExtractorRegistry.ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
var
  Ext: string;
  I: Integer;
begin
  Result := False;
  AText := '';
  AError := '';
  Ext := LowerCase(ExtractFileExt(AFileName));

  for I := 0 to High(FExtractors) do
  begin
    if FExtractors[I].SupportsExtension(Ext) then
    begin
      if FExtractors[I].ExtractText(AFileName, AText, AError) then
      begin
        Result := True;
        Exit;
      end;
    end;
  end;

  if not Result then
    AError := 'Nenhum leitor registrado para a extensão: ' + Ext;
end;

initialization

finalization
  if GRegistry <> nil then
  begin
    GRegistry.Free;
    GRegistry := nil;
  end;

end.
