{
  fgx_lpk.pas — Parser determinista de pacotes Lazarus (.lpk)   [G015]

  Extrai: Name, Type, Files (Filename/UnitIdent/HasRegisterProc) e RequiredPkgs.

  REGRA: nada e inventado. Arquivo ilegivel vira Partial=True com o motivo
  registrado em ParseErrors, e o pipeline prossegue (G026).

  Dependencias: apenas FPC (DOM, XMLRead de fcl-xml). Sem LCL.
}
unit fgx_lpk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, DOM, XMLRead;

type
  TLPKUnit = class
  public
    FileName: string;       // como consta no LPK (relativo)
    UnitIdent: string;
    HasRegisterProc: Boolean;
  end;

  TLPKUnitList = specialize TFPGObjectList<TLPKUnit>;

  TLPKPackage = class
  public
    Name: string;
    LPKPath: string;        // caminho completo do .lpk
    PackageType: string;
    Units: TLPKUnitList;
    RequiredPkgs: TStringList;
    ParseErrors: TStringList;
    Partial: Boolean;
    constructor Create;
    destructor Destroy; override;
  end;

{ Retorna sempre um objeto (nunca nil). Verifique Partial/ParseErrors. }
function ParseLPK(const AFileName: string): TLPKPackage;
function ParseProjectRequiredPackages(const AFileName: string;
  APackages, AErrors: TStrings): Boolean;

implementation

constructor TLPKPackage.Create;
begin
  inherited Create;
  Units := TLPKUnitList.Create(True);
  RequiredPkgs := TStringList.Create;
  RequiredPkgs.Duplicates := dupIgnore;
  ParseErrors := TStringList.Create;
  Partial := False;
end;

destructor TLPKPackage.Destroy;
begin
  ParseErrors.Free;
  RequiredPkgs.Free;
  Units.Free;
  inherited Destroy;
end;

{ Le o atributo Value de um filho direto com o nome dado.
  Ex.: <Name Value="openai_core"/>  ->  GetChildValue(Pkg, 'Name') = 'openai_core' }
function GetChildValue(ANode: TDOMNode; const AChildName: string): string;
var
  Child: TDOMNode;
  Attr: TDOMNode;
begin
  Result := '';
  if ANode = nil then
    Exit;

  Child := ANode.FindNode(UTF8Decode(AChildName));
  if Child = nil then
    Exit;

  if Child.Attributes = nil then
    Exit;

  Attr := Child.Attributes.GetNamedItem(UTF8Decode('Value'));
  if Attr <> nil then
    Result := UTF8Encode(Attr.NodeValue);
end;

function IsItemNode(ANode: TDOMNode): Boolean;
begin
  Result := (ANode <> nil) and
            (ANode.NodeType = ELEMENT_NODE) and
            (Copy(UTF8Encode(ANode.NodeName), 1, 4) = 'Item');
end;

procedure ParseFilesSection(APkg: TLPKPackage; AFilesNode: TDOMNode);
var
  Item: TDOMNode;
  U: TLPKUnit;
  S: string;
begin
  if AFilesNode = nil then
    Exit;

  Item := AFilesNode.FirstChild;
  while Item <> nil do
  begin
    if IsItemNode(Item) then
    begin
      U := TLPKUnit.Create;
      U.FileName := GetChildValue(Item, 'Filename');
      U.UnitIdent := GetChildValue(Item, 'UnitName');

      S := LowerCase(GetChildValue(Item, 'HasRegisterProc'));
      U.HasRegisterProc := (S = 'true');

      { Sem UnitIdent explicito, derivar do nome do arquivo. Isso e deducao
        deterministica do proprio dado, nao invencao. }
      if (U.UnitIdent = '') and (U.FileName <> '') then
        U.UnitIdent := ChangeFileExt(ExtractFileName(
          StringReplace(U.FileName, '\', '/', [rfReplaceAll])), '');

      if (U.FileName <> '') or (U.UnitIdent <> '') then
        APkg.Units.Add(U)
      else
      begin
        U.Free;
        APkg.ParseErrors.Add('Item de <Files> sem Filename nem UnitName');
        APkg.Partial := True;
      end;
    end;
    Item := Item.NextSibling;
  end;
end;

procedure ParseRequiredSection(APkg: TLPKPackage; AReqNode: TDOMNode);
var
  Item: TDOMNode;
  PkgName: string;
begin
  if AReqNode = nil then
    Exit;

  Item := AReqNode.FirstChild;
  while Item <> nil do
  begin
    if IsItemNode(Item) then
    begin
      PkgName := Trim(GetChildValue(Item, 'PackageName'));
      if PkgName <> '' then
        APkg.RequiredPkgs.Add(PkgName)
      else
      begin
        APkg.ParseErrors.Add('Item de <RequiredPkgs> sem PackageName');
        APkg.Partial := True;
      end;
    end;
    Item := Item.NextSibling;
  end;
end;

function ParseLPK(const AFileName: string): TLPKPackage;
var
  Doc: TXMLDocument;
  Root, PkgNode: TDOMNode;
begin
  Result := TLPKPackage.Create;
  Result.LPKPath := AFileName;
  Result.Name := ChangeFileExt(ExtractFileName(AFileName), '');

  Doc := nil;
  try
    try
      ReadXMLFile(Doc, AFileName);
    except
      on E: Exception do
      begin
        Result.ParseErrors.Add('XML invalido: ' + E.Message);
        Result.Partial := True;
        Exit;
      end;
    end;

    Root := Doc.DocumentElement;          // <CONFIG>
    if Root = nil then
    begin
      Result.ParseErrors.Add('LPK sem elemento raiz');
      Result.Partial := True;
      Exit;
    end;

    PkgNode := Root.FindNode(UTF8Decode('Package'));
    if PkgNode = nil then
    begin
      Result.ParseErrors.Add('LPK sem secao <Package>');
      Result.Partial := True;
      Exit;
    end;

    { O nome declarado no LPK prevalece sobre o nome do arquivo. }
    if Trim(GetChildValue(PkgNode, 'Name')) <> '' then
      Result.Name := Trim(GetChildValue(PkgNode, 'Name'))
    else
    begin
      Result.ParseErrors.Add('Package sem <Name>; usando nome do arquivo');
      Result.Partial := True;
    end;

    Result.PackageType := GetChildValue(PkgNode, 'Type');

    ParseFilesSection(Result, PkgNode.FindNode(UTF8Decode('Files')));
    ParseRequiredSection(Result, PkgNode.FindNode(UTF8Decode('RequiredPkgs')));

  finally
    Doc.Free;
  end;
end;

function ParseProjectRequiredPackages(const AFileName: string;
  APackages, AErrors: TStrings): Boolean;
var
  Doc: TXMLDocument;
  ProjectOptions, RequiredNode, Item: TDOMNode;
  PackageName: string;
begin
  Result := False;
  if Assigned(APackages) then APackages.Clear;
  if Assigned(AErrors) then AErrors.Clear;
  Doc := nil;
  try
    try
      ReadXMLFile(Doc, AFileName);
    except
      on E: Exception do
      begin
        if Assigned(AErrors) then AErrors.Add(E.Message);
        Exit;
      end;
    end;
    if not Assigned(Doc.DocumentElement) then Exit;
    ProjectOptions := Doc.DocumentElement.FindNode(UTF8Decode('ProjectOptions'));
    if not Assigned(ProjectOptions) then Exit;
    RequiredNode := ProjectOptions.FindNode(UTF8Decode('RequiredPackages'));
    if not Assigned(RequiredNode) then
      Exit(True);
    Item := RequiredNode.FirstChild;
    while Assigned(Item) do
    begin
      if IsItemNode(Item) then
      begin
        PackageName := Trim(GetChildValue(Item, 'PackageName'));
        if PackageName <> '' then
          APackages.Add(PackageName)
        else if Assigned(AErrors) then
          AErrors.Add('RequiredPackages item without PackageName');
      end;
      Item := Item.NextSibling;
    end;
    Result := not Assigned(AErrors) or (AErrors.Count = 0);
  finally
    Doc.Free;
  end;
end;

end.
