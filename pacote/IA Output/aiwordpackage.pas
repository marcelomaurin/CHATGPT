unit aiwordpackage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Zipper, FileUtil;

type
  { TAIWordPackage }

  TAIWordPackage = class
  private
    FTempDir: string;
    FFileName: string;
    function GenerateUniqueTempDir: string;
    procedure CreateDirectoryTree(const APath: string);
    procedure DeleteDirectoryTree(const APath: string);
    procedure CreateDefaultFiles;
  public
    constructor Create;
    destructor Destroy; override;

    function NewPackage: Boolean;
    function LoadPackage(const AFileName: string): Boolean;
    function SavePackage(const AFileName: string): Boolean;

    property TempDir: string read FTempDir;
    property FileName: string read FFileName;
  end;

implementation

const
  DEFAULT_CONTENT_TYPES = 
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' + #13#10 +
    '  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' + #13#10 +
    '  <Default Extension="xml" ContentType="application/xml"/>' + #13#10 +
    '  <Default Extension="png" ContentType="image/png"/>' + #13#10 +
    '  <Default Extension="jpeg" ContentType="image/jpeg"/>' + #13#10 +
    '  <Default Extension="jpg" ContentType="image/jpeg"/>' + #13#10 +
    '  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' + #13#10 +
    '  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' + #13#10 +
    '  <Override PartName="/word/settings.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.settings+xml"/>' + #13#10 +
    '  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' + #13#10 +
    '  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>' + #13#10 +
    '</Types>';

  DEFAULT_RELS = 
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + #13#10 +
    '  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' + #13#10 +
    '  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' + #13#10 +
    '  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>' + #13#10 +
    '</Relationships>';

  DEFAULT_CORE =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" ' +
    'xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" ' +
    'xmlns:dcmitype="http://purl.org/dc/dcmitype/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' + #13#10 +
    '  <dc:title></dc:title>' + #13#10 +
    '  <dc:creator>Lazarus AI Suite</dc:creator>' + #13#10 +
    '  <cp:lastModifiedBy>Lazarus AI Suite</cp:lastModifiedBy>' + #13#10 +
    '  <dcterms:created xsi:type="dcterms:W3CDTF">2026-06-15T12:00:00Z</dcterms:created>' + #13#10 +
    '  <dcterms:modified xsi:type="dcterms:W3CDTF">2026-06-15T12:00:00Z</dcterms:modified>' + #13#10 +
    '</cp:coreProperties>';

  DEFAULT_APP =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties" xmlns:vt="http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes">' + #13#10 +
    '  <Template>Normal</Template>' + #13#10 +
    '  <TotalTime>0</TotalTime>' + #13#10 +
    '  <Pages>1</Pages>' + #13#10 +
    '  <Words>0</Words>' + #13#10 +
    '  <Characters>0</Characters>' + #13#10 +
    '  <Application>Lazarus AI Suite (TAIWordDocument)</Application>' + #13#10 +
    '  <DocSecurity>0</DocSecurity>' + #13#10 +
    '  <Lines>1</Lines>' + #13#10 +
    '  <Paragraphs>1</Paragraphs>' + #13#10 +
    '  <ScaleCrop>false</ScaleCrop>' + #13#10 +
    '  <Company>Maurinsoft</Company>' + #13#10 +
    '  <LinksUpToDate>false</LinksUpToDate>' + #13#10 +
    '  <SharedDoc>false</SharedDoc>' + #13#10 +
    '  <HyperlinksChanged>false</HyperlinksChanged>' + #13#10 +
    '  <AppVersion>1.10</AppVersion>' + #13#10 +
    '</Properties>';

  DEFAULT_STYLES =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' + #13#10 +
    '  <w:docDefaults>' + #13#10 +
    '    <w:rPrDefault>' + #13#10 +
    '      <w:rPr>' + #13#10 +
    '        <w:rFonts w:ascii="Arial" w:eastAsia="Arial" w:hAnsi="Arial" w:cs="Arial"/>' + #13#10 +
    '        <w:sz w:val="24"/>' + #13#10 +
    '        <w:szCs w:val="24"/>' + #13#10 +
    '        <w:lang w:val="pt-BR"/>' + #13#10 +
    '      </w:rPr>' + #13#10 +
    '    </w:rPrDefault>' + #13#10 +
    '  </w:docDefaults>' + #13#10 +
    '  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">' + #13#10 +
    '    <w:name w:val="Normal"/>' + #13#10 +
    '    <w:qFormat/>' + #13#10 +
    '  </w:style>' + #13#10 +
    '  <w:style w:type="paragraph" w:styleId="Heading1">' + #13#10 +
    '    <w:name w:val="heading 1"/>' + #13#10 +
    '    <w:basedOn w:val="Normal"/>' + #13#10 +
    '    <w:next w:val="Normal"/>' + #13#10 +
    '    <w:uiPriority w:val="9"/>' + #13#10 +
    '    <w:qFormat/>' + #13#10 +
    '    <w:pPr>' + #13#10 +
    '      <w:keepNext/>' + #13#10 +
    '      <w:spacing w:before="240" w:after="0"/>' + #13#10 +
    '    </w:pPr>' + #13#10 +
    '    <w:rPr>' + #13#10 +
    '      <w:rFonts w:ascii="Arial" w:hAnsi="Arial"/>' + #13#10 +
    '      <w:b/>' + #13#10 +
    '      <w:sz w:val="36"/>' + #13#10 +
    '      <w:color w:val="2E74B5"/>' + #13#10 +
    '    </w:rPr>' + #13#10 +
    '  </w:style>' + #13#10 +
    '  <w:style w:type="paragraph" w:styleId="Heading2">' + #13#10 +
    '    <w:name w:val="heading 2"/>' + #13#10 +
    '    <w:basedOn w:val="Normal"/>' + #13#10 +
    '    <w:next w:val="Normal"/>' + #13#10 +
    '    <w:uiPriority w:val="10"/>' + #13#10 +
    '    <w:qFormat/>' + #13#10 +
    '    <w:pPr>' + #13#10 +
    '      <w:keepNext/>' + #13#10 +
    '      <w:spacing w:before="240" w:after="0"/>' + #13#10 +
    '    </w:pPr>' + #13#10 +
    '    <w:rPr>' + #13#10 +
    '      <w:rFonts w:ascii="Arial" w:hAnsi="Arial"/>' + #13#10 +
    '      <w:b/>' + #13#10 +
    '      <w:sz w:val="28"/>' + #13#10 +
    '      <w:color w:val="2E74B5"/>' + #13#10 +
    '    </w:rPr>' + #13#10 +
    '  </w:style>' + #13#10 +
    '</w:styles>';

  DEFAULT_SETTINGS =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<w:settings xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' + #13#10 +
    '  <w:defaultTabStop w:val="720"/>' + #13#10 +
    '  <w:characterSpacingControl w:val="doNotCompress"/>' + #13#10 +
    '  <w:compat/>' + #13#10 +
    '</w:settings>';

  DEFAULT_DOC_RELS =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + #13#10 +
    '  <Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' + #13#10 +
    '  <Relationship Id="rIdSettings" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/settings" Target="settings.xml"/>' + #13#10 +
    '</Relationships>';

  DEFAULT_DOCUMENT =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' + #13#10 +
    '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" ' +
    'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' + #13#10 +
    '  <w:body>' + #13#10 +
    '    <w:sectPr>' + #13#10 +
    '      <w:pgSz w:w="11906" w:h="16838"/>' + #13#10 +
    '      <w:pgMar w:top="1134" w:right="1417" w:bottom="1134" w:left="1417" w:header="708" w:footer="708" w:gutter="0"/>' + #13#10 +
    '    </w:sectPr>' + #13#10 +
    '  </w:body>' + #13#10 +
    '</w:document>';

constructor TAIWordPackage.Create;
begin
  FTempDir := '';
  FFileName := '';
end;

destructor TAIWordPackage.Destroy;
begin
  if FTempDir <> '' then
  begin
    DeleteDirectoryTree(FTempDir);
    FTempDir := '';
  end;
  inherited Destroy;
end;

function TAIWordPackage.GenerateUniqueTempDir: string;
var
  GUID: TGUID;
  GUIDStr: string;
begin
  CreateGUID(GUID);
  GUIDStr := GUIDToString(GUID);
  // remove curly braces
  Delete(GUIDStr, 1, 1);
  Delete(GUIDStr, Length(GUIDStr), 1);
  // combine with temp path
  Result := IncludeTrailingPathDelimiter(GetTempDir) + 'aiword_temp_' + GUIDStr;
end;

procedure TAIWordPackage.CreateDirectoryTree(const APath: string);
begin
  if not DirectoryExists(APath) then
    if not ForceDirectories(APath) then
      raise Exception.Create('Falha ao criar diretório temporário: ' + APath);
end;

procedure TAIWordPackage.DeleteDirectoryTree(const APath: string);
begin
  if DirectoryExists(APath) then
    DeleteDirectory(APath, True);
end;

procedure TAIWordPackage.CreateDefaultFiles;
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    CreateDirectoryTree(FTempDir);
    CreateDirectoryTree(FTempDir + PathDelim + '_rels');
    CreateDirectoryTree(FTempDir + PathDelim + 'docProps');
    CreateDirectoryTree(FTempDir + PathDelim + 'word');
    CreateDirectoryTree(FTempDir + PathDelim + 'word' + PathDelim + '_rels');
    CreateDirectoryTree(FTempDir + PathDelim + 'word' + PathDelim + 'media');

    // [Content_Types].xml
    List.Text := DEFAULT_CONTENT_TYPES;
    List.SaveToFile(FTempDir + PathDelim + '[Content_Types].xml', TEncoding.UTF8);

    // _rels/.rels
    List.Text := DEFAULT_RELS;
    List.SaveToFile(FTempDir + PathDelim + '_rels' + PathDelim + '.rels', TEncoding.UTF8);

    // docProps/core.xml
    List.Text := DEFAULT_CORE;
    List.SaveToFile(FTempDir + PathDelim + 'docProps' + PathDelim + 'core.xml', TEncoding.UTF8);

    // docProps/app.xml
    List.Text := DEFAULT_APP;
    List.SaveToFile(FTempDir + PathDelim + 'docProps' + PathDelim + 'app.xml', TEncoding.UTF8);

    // word/styles.xml
    List.Text := DEFAULT_STYLES;
    List.SaveToFile(FTempDir + PathDelim + 'word' + PathDelim + 'styles.xml', TEncoding.UTF8);

    // word/settings.xml
    List.Text := DEFAULT_SETTINGS;
    List.SaveToFile(FTempDir + PathDelim + 'word' + PathDelim + 'settings.xml', TEncoding.UTF8);

    // word/_rels/document.xml.rels
    List.Text := DEFAULT_DOC_RELS;
    List.SaveToFile(FTempDir + PathDelim + 'word' + PathDelim + '_rels' + PathDelim + 'document.xml.rels', TEncoding.UTF8);

    // word/document.xml
    List.Text := DEFAULT_DOCUMENT;
    List.SaveToFile(FTempDir + PathDelim + 'word' + PathDelim + 'document.xml', TEncoding.UTF8);
  finally
    List.Free;
  end;
end;

function TAIWordPackage.NewPackage: Boolean;
begin
  if FTempDir <> '' then
  begin
    DeleteDirectoryTree(FTempDir);
    FTempDir := '';
  end;
  
  try
    FTempDir := GenerateUniqueTempDir;
    CreateDefaultFiles;
    FFileName := '';
    Result := True;
  except
    FTempDir := '';
    Result := False;
  end;
end;

function TAIWordPackage.LoadPackage(const AFileName: string): Boolean;
var
  UnZip: TUnZipper;
begin
  if FTempDir <> '' then
  begin
    DeleteDirectoryTree(FTempDir);
    FTempDir := '';
  end;

  if not FileExists(AFileName) then
    Exit(False);

  try
    FTempDir := GenerateUniqueTempDir;
    CreateDirectoryTree(FTempDir);

    UnZip := TUnZipper.Create;
    try
      UnZip.FileName := AFileName;
      UnZip.OutputPath := FTempDir;
      UnZip.UnZipAllFiles;
    finally
      UnZip.Free;
    end;

    FFileName := AFileName;
    Result := True;
  except
    if FTempDir <> '' then
    begin
      DeleteDirectoryTree(FTempDir);
      FTempDir := '';
    end;
    Result := False;
  end;
end;

procedure GetFilesRecursive(const APath: string; AList: TStrings; const ARootPath: string);
var
  SR: TSearchRec;
  RelPath: string;
begin
  if FindFirst(APath + PathDelim + '*', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Name <> '.') and (SR.Name <> '..') then
        begin
          if (SR.Attr and faDirectory) <> 0 then
          begin
            GetFilesRecursive(APath + PathDelim + SR.Name, AList, ARootPath);
          end
          else
          begin
            RelPath := ExtractRelativePath(ARootPath, APath + PathDelim + SR.Name);
            // Replace path delimiters for internal ZIP usage (always forward slash)
            RelPath := StringReplace(RelPath, PathDelim, '/', [rfReplaceAll]);
            AList.Add(RelPath);
          end;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;
end;

function TAIWordPackage.SavePackage(const AFileName: string): Boolean;
var
  Zip: TZipper;
  FileList: TStringList;
  I: Integer;
begin
  if FTempDir = '' then
    Exit(False);

  FileList := TStringList.Create;
  try
    try
      // Recursively collect all files under FTempDir
      GetFilesRecursive(FTempDir, FileList, IncludeTrailingPathDelimiter(FTempDir));

      if FileExists(AFileName) then
        DeleteFile(AFileName);

      Zip := TZipper.Create;
      try
        Zip.FileName := AFileName;
        
        // We must change the active directory temporarily or specify absolute path source
        // to pack correctly. Standard TZipper usage allows adding files with paths:
        for I := 0 to FileList.Count - 1 do
        begin
          // Add file with its disk location and target inside the ZIP
          Zip.Entries.AddFileEntry(
            FTempDir + PathDelim + StringReplace(FileList[I], '/', PathDelim, [rfReplaceAll]),
            FileList[I]
          );
        end;
        
        Zip.ZipAllFiles;
      finally
        Zip.Free;
      end;
      FFileName := AFileName;
      Result := True;
    except
      Result := False;
    end;
  finally
    FileList.Free;
  end;
end;

end.
