unit aipdfinput;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, aibase, aidocumentreader;

type
  { TAIDocumentPage }
  TAIDocumentPage = record
    PageNumber: Integer;
    Text: string;
  end;

  { IAIPDFTextEngine }
  IAIPDFTextEngine = interface
    ['{C7A8B9D0-1E2F-3A4B-5C6D-7E8F9A0B1C2D}']
    function ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
  end;

  { TAIPDFToTextProcessEngine }

  TAIPDFToTextProcessEngine = class(TInterfacedObject, IAIPDFTextEngine)
  private
    FExecutablePath: string;
    FTimeout: Integer;
  public
    constructor Create;
    function ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
    property ExecutablePath: string read FExecutablePath write FExecutablePath;
    property Timeout: Integer read FTimeout write FTimeout;
  end;

  { TAIPDFInput }

  TAIPDFInput = class(TAIBaseComponent)
  private
    FFileName: string;
    FPages: array of TAIDocumentPage;
    FEngine: IAIPDFTextEngine;
    FExecutablePath: string;
    FMetadata: TAIDocumentMetadata;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    function LoadFromFile(const AFileName: string): Boolean;
    function Load: Boolean;
    function FullText: string;
    function PageCount: Integer;
    function GetPageText(APageIndex: Integer): string;

    property Engine: IAIPDFTextEngine read FEngine write FEngine;
    property Metadata: TAIDocumentMetadata read FMetadata;
  published
    property FileName: string read FFileName write FFileName;
    property ExecutablePath: string read FExecutablePath write FExecutablePath;
  end;

implementation

{ TAIPDFToTextProcessEngine }

constructor TAIPDFToTextProcessEngine.Create;
begin
  FExecutablePath := 'pdftotext';
  FTimeout := 10000;
end;

function TAIPDFToTextProcessEngine.ExtractText(const AFileName: string; out AText: string; out AError: string): Boolean;
var
  AProcess: TProcess;
  TempOutputFile: string;
  OutputList: TStringList;
begin
  Result := False;
  AText := '';
  AError := '';

  TempOutputFile := GetTempFileName + '.txt';
  AProcess := TProcess.Create(nil);
  try
    try
      AProcess.Executable := FExecutablePath;
      AProcess.Parameters.Add(AFileName);
      AProcess.Parameters.Add(TempOutputFile);
      AProcess.Options := [poWaitOnExit, poNoConsole];
      AProcess.Execute;

      if (AProcess.ExitCode = 0) and FileExists(TempOutputFile) then
      begin
        OutputList := TStringList.Create;
        try
          OutputList.LoadFromFile(TempOutputFile);
          AText := OutputList.Text;
          Result := True;
        finally
          OutputList.Free;
        end;
      end
      else
        AError := 'pdftotext executou com erro ou não produziu saída.';
    except
      on E: Exception do
        AError := 'Exceção ao executar pdftotext: ' + E.Message;
    end;
  finally
    AProcess.Free;
    if FileExists(TempOutputFile) then
      DeleteFile(TempOutputFile);
  end;
end;

{ TAIPDFInput }

constructor TAIPDFInput.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIPDFInput extracts text natively or via pdftotext engine from PDF files. Properties: FileName: string, ExecutablePath: string. Methods: LoadFromFile, Load, FullText, Clear.';
  FFileName := '';
  FExecutablePath := 'pdftotext';
  FEngine := TAIPDFToTextProcessEngine.Create;
  InitDocumentMetadata(FMetadata);
  Clear;
end;

destructor TAIPDFInput.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAIPDFInput.Clear;
begin
  SetLength(FPages, 0);
  InitDocumentMetadata(FMetadata);
  ClearError;
end;

function TAIPDFInput.FullText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FPages) do
  begin
    if I > 0 then Result := Result + #13#10 + '--- Page ' + IntToStr(I + 1) + ' ---' + #13#10;
    Result := Result + FPages[I].Text;
  end;
end;

function TAIPDFInput.PageCount: Integer;
begin
  Result := Length(FPages);
end;

function TAIPDFInput.GetPageText(APageIndex: Integer): string;
begin
  if (APageIndex >= 0) and (APageIndex <= High(FPages)) then
    Result := FPages[APageIndex].Text
  else
    Result := '';
end;

function TAIPDFInput.LoadFromFile(const AFileName: string): Boolean;
var
  Ext, ExtractedText, ErrorStr: string;
begin
  FFileName := AFileName;
  Result := False;
  Clear;

  if Trim(FFileName) = '' then
  begin
    SetError('Nome de arquivo PDF não especificado.');
    Exit;
  end;

  if not FileExists(FFileName) then
  begin
    SetError('Arquivo PDF não encontrado: ' + FFileName);
    Exit;
  end;

  if not Assigned(FEngine) then
  begin
    SetError('Nenhum engine de extração de texto PDF associado ao componente.');
    Exit;
  end;

  if FExecutablePath <> '' then
  begin
    // Update path if process engine is used
  end;

  Ext := LowerCase(ExtractFileExt(FFileName));
  FMetadata.FileName := FFileName;
  FMetadata.Extension := Ext;

  if FEngine.ExtractText(FFileName, ExtractedText, ErrorStr) then
  begin
    SetLength(FPages, 1);
    FPages[0].PageNumber := 1;
    FPages[0].Text := ExtractedText;
    FMetadata.PageCount := 1;

    FLastResult := 'PDF Loaded successfully: ' + FFileName;
    FLastSuccess := True;
    Result := True;
  end
  else
    SetError('Falha ao extrair texto do PDF: ' + ErrorStr);
end;

function TAIPDFInput.Load: Boolean;
begin
  Result := LoadFromFile(FFileName);
end;

end.
