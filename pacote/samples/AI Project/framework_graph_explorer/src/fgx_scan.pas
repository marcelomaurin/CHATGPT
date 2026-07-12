{
  fgx_scan.pas — Descoberta e classificacao de artefatos   [G008 / G010 / G011]

  Substituto de console para o TAIDiskTreeScanner. A logica de classificacao
  aqui e a mesma que o componente devera usar; quando o pipeline estiver
  provado, isto migra para openai_files.

  Dependencias: apenas FPC. Sem LCL.
}
unit fgx_scan;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl;

type
  TArtifactKind = (akUnknown, akPackage, akPascal, akForm, akProject,
                   akProjectSrc, akDoc, akData);

  TArtifact = class
  public
    FullPath: string;
    RelPath: string;
    Kind: TArtifactKind;
  end;

  TArtifactList = specialize TFPGObjectList<TArtifact>;

  TScanStats = record
    Dirs: Integer;
    Files: Integer;
    Skipped: Integer;
  end;

function ClassifyExt(const AExt: string): TArtifactKind;
function KindName(AKind: TArtifactKind): string;

{ Varre ARoot recursivamente, ignorando diretorios de build/VCS.
  Preenche AList (que deve ja existir). }
procedure ScanTree(const ARoot: string; AList: TArtifactList;
                   out AStats: TScanStats);

implementation

const
  EXCLUDED_DIRS: array[0..8] of string = (
    '.git', 'lib', 'bin', 'backup', 'output', '__pycache__',
    'node_modules', '.vscode', 'dist'
  );

function ClassifyExt(const AExt: string): TArtifactKind;
var
  E: string;
begin
  E := LowerCase(AExt);
  if E = '.lpk' then
    Result := akPackage
  else if (E = '.pas') or (E = '.pp') or (E = '.inc') then
    Result := akPascal
  else if E = '.lfm' then
    Result := akForm
  else if E = '.lpi' then
    Result := akProject
  else if E = '.lpr' then
    Result := akProjectSrc
  else if (E = '.md') or (E = '.txt') then
    Result := akDoc
  else if (E = '.json') or (E = '.csv') then
    Result := akData
  else
    Result := akUnknown;
end;

function KindName(AKind: TArtifactKind): string;
begin
  case AKind of
    akPackage:    Result := 'package';
    akPascal:     Result := 'pascal';
    akForm:       Result := 'form';
    akProject:    Result := 'project';
    akProjectSrc: Result := 'project_source';
    akDoc:        Result := 'document';
    akData:       Result := 'data';
  else
    Result := 'unknown';
  end;
end;

function IsExcludedDir(const AName: string): Boolean;
var
  I: Integer;
  L: string;
begin
  L := LowerCase(AName);
  for I := Low(EXCLUDED_DIRS) to High(EXCLUDED_DIRS) do
    if L = EXCLUDED_DIRS[I] then
      Exit(True);
  Result := False;
end;

procedure ScanDir(const ARoot, ADir: string; AList: TArtifactList;
                  var AStats: TScanStats);
var
  SR: TSearchRec;
  Full: string;
  A: TArtifact;
begin
  if FindFirst(IncludeTrailingPathDelimiter(ADir) + '*', faAnyFile, SR) <> 0 then
    Exit;
  try
    repeat
      if (SR.Name = '.') or (SR.Name = '..') then
        Continue;

      Full := IncludeTrailingPathDelimiter(ADir) + SR.Name;

      if (SR.Attr and faDirectory) <> 0 then
      begin
        if IsExcludedDir(SR.Name) then
        begin
          Inc(AStats.Skipped);
          Continue;
        end;
        Inc(AStats.Dirs);
        ScanDir(ARoot, Full, AList, AStats);
      end
      else
      begin
        Inc(AStats.Files);
        A := TArtifact.Create;
        A.FullPath := Full;
        A.RelPath := StringReplace(
          Copy(Full, Length(IncludeTrailingPathDelimiter(ARoot)) + 1, MaxInt),
          PathDelim, '/', [rfReplaceAll]);
        A.Kind := ClassifyExt(ExtractFileExt(SR.Name));
        AList.Add(A);
      end;
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
end;

procedure ScanTree(const ARoot: string; AList: TArtifactList;
                   out AStats: TScanStats);
begin
  AStats.Dirs := 0;
  AStats.Files := 0;
  AStats.Skipped := 0;

  if not DirectoryExists(ARoot) then
    raise Exception.CreateFmt('Raiz inexistente: %s', [ARoot]);

  ScanDir(ARoot, ExcludeTrailingPathDelimiter(ARoot), AList, AStats);
end;

end.
