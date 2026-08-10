unit aidocumentreader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase;

type
  { TAIDocumentMetadata }
  TAIDocumentMetadata = record
    FileName: string;
    Extension: string;
    Size: Int64;
    Title: string;
    Author: string;
    Subject: string;
    CreatedDate: TDateTime;
    ModifiedDate: TDateTime;
    PageCount: Integer;
    SheetCount: Integer;
  end;

  { IAIDocumentReader }
  IAIDocumentReader = interface
    ['{B8A1C5D9-2E3F-4A5B-9C0D-1E2F3A4B5C6D}']
    function SupportsFile(const AFileName: string): Boolean;
    function LoadFromFile(const AFileName: string): Boolean;
    function GetText: string;
    function GetLastError: string;
    function GetMetadata: TAIDocumentMetadata;
  end;

  { TAIDocumentInput }

  TAIDocumentInput = class(TAIBaseComponent)
  private
    FFileName: string;
    FText: string;
    FDocumentType: string;
    FMetadata: TAIDocumentMetadata;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    function LoadFromFile(const AFileName: string): Boolean;
    function Load: Boolean;

    property Text: string read FText;
    property DocumentType: string read FDocumentType;
    property Metadata: TAIDocumentMetadata read FMetadata;
  published
    property FileName: string read FFileName write FFileName;
  end;

procedure InitDocumentMetadata(out AMeta: TAIDocumentMetadata);

implementation

procedure InitDocumentMetadata(out AMeta: TAIDocumentMetadata);
begin
  AMeta.FileName := '';
  AMeta.Extension := '';
  AMeta.Size := 0;
  AMeta.Title := '';
  AMeta.Author := '';
  AMeta.Subject := '';
  AMeta.CreatedDate := 0;
  AMeta.ModifiedDate := 0;
  AMeta.PageCount := 0;
  AMeta.SheetCount := 0;
end;

{ TAIDocumentInput }

constructor TAIDocumentInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIDocumentInput reads text and metadata from structured documents. Properties: FileName: string. Methods: LoadFromFile(const AFileName: string): Boolean, Load: Boolean, Clear. AI Agent: Use this component to ingest document text for context, RAG, or analysis.';
  FFileName := '';
  FText := '';
  FDocumentType := '';
  InitDocumentMetadata(FMetadata);
end;

destructor TAIDocumentInput.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAIDocumentInput.Clear;
begin
  FText := '';
  FDocumentType := '';
  InitDocumentMetadata(FMetadata);
  ClearError;
end;

function TAIDocumentInput.LoadFromFile(const AFileName: string): Boolean;
var
  Lines: TStringList;
  Ext: string;
begin
  FFileName := AFileName;
  Result := False;
  Clear;

  if Trim(FFileName) = '' then
  begin
    SetError('Nome de arquivo não especificado.');
    Exit;
  end;

  if not FileExists(FFileName) then
  begin
    SetError('Arquivo não encontrado: ' + FFileName);
    Exit;
  end;

  Ext := LowerCase(ExtractFileExt(FFileName));
  FDocumentType := UpperCase(Copy(Ext, 2, Length(Ext)));
  FMetadata.FileName := FFileName;
  FMetadata.Extension := Ext;

  Lines := TStringList.Create;
  try
    try
      Lines.LoadFromFile(FFileName);
      FText := Lines.Text;
      FLastResult := 'Document loaded: ' + FFileName;
      FLastSuccess := True;
      Result := True;
    except
      on E: Exception do
      begin
        SetError('Erro ao ler arquivo: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function TAIDocumentInput.Load: Boolean;
begin
  Result := LoadFromFile(FFileName);
end;

end.
