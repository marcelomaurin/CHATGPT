unit fgx_analyzer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fgl, aidisktreescanner, aidiskitem, aidependencygraph;

type
  TFGXStageEvent = procedure(AStage, AStageCount: Integer;
    const AName, AStatus: string) of object;

  TFGXAnalysisStats = record
    Packages: Integer;
    Units: Integer;
    Components: Integer;
    Samples: Integer;
    ExternalDependencies: Integer;
    PackageLinks: Integer;
    ComponentSampleLinks: Integer;
    ParseErrors: Integer;
  end;

function BuildFactualGraph(const ARoot: string; AScanner: TAIDiskTreeScanner;
  AGraph: TAIDependencyGraph; ALog: TStrings; AOnStage: TFGXStageEvent;
  out AStats: TFGXAnalysisStats): Boolean;

implementation

uses
  fgx_lpk, fgx_pascal;

type
  TLPKList = specialize TFPGObjectList<TLPKPackage>;

function RelToRoot(const ARoot, APath: string): string;
var
  RootPath, FullPath: string;
begin
  RootPath := IncludeTrailingPathDelimiter(ExpandFileName(ARoot));
  FullPath := ExpandFileName(APath);
  if CompareText(Copy(FullPath, 1, Length(RootPath)), RootPath) = 0 then
    Result := Copy(FullPath, Length(RootPath) + 1, MaxInt)
  else
    Result := FullPath;
  Result := StringReplace(Result, '\', '/', [rfReplaceAll]);
  if Result = '' then
    Result := '.';
end;

function ToFullPath(const ARoot, ARelativePath: string): string;
begin
  Result := ExpandFileName(IncludeTrailingPathDelimiter(ARoot) +
    StringReplace(ARelativePath, '/', PathDelim, [rfReplaceAll]));
end;

function PathStartsWith(const APath, ADirectory: string): Boolean;
var
  PathValue, DirValue: string;
begin
  PathValue := LowerCase(StringReplace(APath, '\', '/', [rfReplaceAll]));
  DirValue := LowerCase(StringReplace(ADirectory, '\', '/', [rfReplaceAll]));
  if (DirValue <> '') and (DirValue[Length(DirValue)] <> '/') then
    DirValue := DirValue + '/';
  Result := Pos(DirValue, PathValue) = 1;
end;

function FindClass(AInfo: TPascalUnitInfo; const AName: string): TPascalClass;
var
  I: Integer;
begin
  Result := nil;
  for I := 0 to AInfo.PublicClasses.Count - 1 do
    if SameText(AInfo.PublicClasses[I].Name, AName) then
      Exit(AInfo.PublicClasses[I]);
end;

procedure LogLine(ALog: TStrings; const AText: string);
begin
  if Assigned(ALog) then
    ALog.Add(FormatDateTime('hh:nn:ss', Now) + '  ' + AText);
end;

procedure NotifyStage(AOnStage: TFGXStageEvent; AStage: Integer;
  const AName, AStatus: string);
begin
  if Assigned(AOnStage) then
    AOnStage(AStage, 10, AName, AStatus);
end;

function BuildFactualGraph(const ARoot: string; AScanner: TAIDiskTreeScanner;
  AGraph: TAIDependencyGraph; ALog: TStrings; AOnStage: TFGXStageEvent;
  out AStats: TFGXAnalysisStats): Boolean;
var
  Packages: TLPKList;
  KnownPackages, UnitFiles, UnitPackages, SampleProjects, Identifiers,
    SampleRequired, SampleErrors: TStringList;
  I, J, K, LineNo: Integer;
  Item: TAIDiskItem;
  Pkg: TLPKPackage;
  PkgUnit: TLPKUnit;
  Info: TPascalUnitInfo;
  Ref: TPascalRef;
  Reg: TComponentRegistration;
  PasClass: TPascalClass;
  Node: TAIDependencyNode;
  Validation: TAIDependencyValidation;
  Evidence: TAIDependencyEvidence;
  RepoId, PkgId, UnitId, DepId, ComponentId, SampleId: string;
  SourcePath, SourceRel, UnitName, PackageName, RequiredName: string;
  SampleProject, SampleRel, SampleDir, FileRel, Ext: string;
begin
  Result := False;
  AStats := Default(TFGXAnalysisStats);
  if (not Assigned(AScanner)) or (not Assigned(AGraph)) then
    Exit;

  Packages := TLPKList.Create(True);
  KnownPackages := TStringList.Create;
  UnitFiles := TStringList.Create;
  UnitPackages := TStringList.Create;
  SampleProjects := TStringList.Create;
  Identifiers := TStringList.Create;
  SampleRequired := TStringList.Create;
  SampleErrors := TStringList.Create;
  try
    KnownPackages.Sorted := True;
    KnownPackages.Duplicates := dupIgnore;
    KnownPackages.CaseSensitive := False;
    UnitFiles.NameValueSeparator := '=';
    UnitFiles.CaseSensitive := False;
    UnitPackages.NameValueSeparator := '=';
    UnitPackages.CaseSensitive := False;
    SampleProjects.Sorted := True;
    SampleProjects.Duplicates := dupIgnore;
    SampleProjects.CaseSensitive := False;
    Identifiers.NameValueSeparator := '=';
    Identifiers.CaseSensitive := False;
    SampleRequired.Sorted := True;
    SampleRequired.Duplicates := dupIgnore;
    SampleRequired.CaseSensitive := False;

    AGraph.Clear;
    RepoId := MakeAIDependencyNodeId(AIDG_NODE_REPOSITORY,
      ExtractFileName(ExcludeTrailingPathDelimiter(ARoot)));
    Evidence := MakeAIDependencyEvidence('.', 0, 'TAIDiskTreeScanner');
    AGraph.AddNode(RepoId, AIDG_NODE_REPOSITORY,
      ExtractFileName(ExcludeTrailingPathDelimiter(ARoot)), '.', Evidence);

    NotifyStage(AOnStage, 2, 'Packages and units', 'RUNNING');
    LogLine(ALog, 'Reading Lazarus packages (.lpk)...');
    for I := 0 to AScanner.ResultCount - 1 do
    begin
      Item := AScanner.GetResult(I);
      if Assigned(Item) and (Item.ItemType <> ditDirectory) and
         SameText(Item.Extension, '.lpk') then
      begin
        Pkg := ParseLPK(Item.FullPath);
        Packages.Add(Pkg);
        KnownPackages.Add(Pkg.Name);
        Inc(AStats.ParseErrors, Pkg.ParseErrors.Count);
      end;
    end;

    if Packages.Count = 0 then
    begin
      LogLine(ALog, 'FAIL: no .lpk package was found.');
      NotifyStage(AOnStage, 2, 'Packages and units', 'FAIL');
      Exit;
    end;

    for I := 0 to Packages.Count - 1 do
    begin
      Pkg := Packages[I];
      PkgId := MakeAIDependencyNodeId(AIDG_NODE_PACKAGE, Pkg.Name);
      SourceRel := RelToRoot(ARoot, Pkg.LPKPath);
      Evidence := MakeAIDependencyEvidence(SourceRel, 0, 'fgx_lpk');
      Node := AGraph.AddNode(PkgId, AIDG_NODE_PACKAGE, Pkg.Name, SourceRel, Evidence);
      if Assigned(Node) then
      begin
        Node.Attrs.Values['package_type'] := Pkg.PackageType;
        if Pkg.Partial then
          Node.Attrs.Values['status'] := 'partial'
        else
          Node.Attrs.Values['status'] := 'complete';
      end;

      for J := 0 to Pkg.Units.Count - 1 do
      begin
        PkgUnit := Pkg.Units[J];
        if Trim(PkgUnit.UnitIdent) = '' then
          Continue;
        UnitName := LowerCase(PkgUnit.UnitIdent);
        UnitId := MakeAIDependencyNodeId(AIDG_NODE_UNIT, PkgUnit.UnitIdent);
        SourcePath := ExpandFileName(IncludeTrailingPathDelimiter(
          ExtractFileDir(Pkg.LPKPath)) + StringReplace(PkgUnit.FileName, '/',
          PathDelim, [rfReplaceAll]));
        SourceRel := RelToRoot(ARoot, SourcePath);
        Node := AGraph.AddNode(UnitId, AIDG_NODE_UNIT, PkgUnit.UnitIdent,
          SourceRel, Evidence);
        if Assigned(Node) then
        begin
          Node.Attrs.Values['package'] := Pkg.Name;
          Node.Attrs.Values['source_file'] := SourcePath;
        end;
        AGraph.AddEdge(PkgId, UnitId, AIDG_EDGE_CONTAINS, Evidence);
        UnitFiles.Values[UnitName] := SourcePath;
        UnitPackages.Values[UnitName] := Pkg.Name;
      end;
    end;
    NotifyStage(AOnStage, 2, 'Packages and units', 'PASS');

    NotifyStage(AOnStage, 3, 'Package dependencies', 'RUNNING');
    LogLine(ALog, 'Resolving package dependencies...');
    for I := 0 to Packages.Count - 1 do
    begin
      Pkg := Packages[I];
      PkgId := MakeAIDependencyNodeId(AIDG_NODE_PACKAGE, Pkg.Name);
      Evidence := MakeAIDependencyEvidence(RelToRoot(ARoot, Pkg.LPKPath), 0,
        'fgx_lpk.requiredpkgs');
      for J := 0 to Pkg.RequiredPkgs.Count - 1 do
      begin
        RequiredName := Pkg.RequiredPkgs[J];
        if KnownPackages.IndexOf(RequiredName) >= 0 then
          DepId := MakeAIDependencyNodeId(AIDG_NODE_PACKAGE, RequiredName)
        else
        begin
          DepId := MakeAIDependencyNodeId(AIDG_NODE_EXTERNAL, RequiredName);
          AGraph.AddNode(DepId, AIDG_NODE_EXTERNAL, RequiredName, '', Evidence);
        end;
        AGraph.AddEdge(PkgId, DepId, AIDG_EDGE_REQUIRES_PACKAGE, Evidence);
      end;
    end;
    NotifyStage(AOnStage, 3, 'Package dependencies', 'PASS');

    NotifyStage(AOnStage, 4, 'Pascal components', 'RUNNING');
    LogLine(ALog, 'Tokenizing Pascal units and locating components...');
    for I := 0 to UnitFiles.Count - 1 do
    begin
      UnitName := UnitFiles.Names[I];
      SourcePath := UnitFiles.ValueFromIndex[I];
      if not FileExists(SourcePath) then
        Continue;
      SourceRel := RelToRoot(ARoot, SourcePath);
      UnitId := MakeAIDependencyNodeId(AIDG_NODE_UNIT, UnitName);
      PackageName := UnitPackages.Values[UnitName];
      Info := ParsePascalUnit(SourcePath);
      try
        Inc(AStats.ParseErrors, Info.ParseErrors.Count);
        for K := 0 to Info.InterfaceUses.Count + Info.ImplementationUses.Count - 1 do
        begin
          if K < Info.InterfaceUses.Count then
            Ref := Info.InterfaceUses[K]
          else
            Ref := Info.ImplementationUses[K - Info.InterfaceUses.Count];
          Evidence := MakeAIDependencyEvidence(SourceRel, Ref.Line,
            'fgx_pascal.uses');
          if UnitFiles.IndexOfName(LowerCase(Ref.Name)) >= 0 then
            DepId := MakeAIDependencyNodeId(AIDG_NODE_UNIT, Ref.Name)
          else
          begin
            DepId := MakeAIDependencyNodeId(AIDG_NODE_EXTERNAL, 'unit:' + Ref.Name);
            Node := AGraph.AddNode(DepId, AIDG_NODE_EXTERNAL, Ref.Name, '', Evidence);
            if Assigned(Node) then
              Node.Attrs.Values['resolution'] := 'unresolved';
          end;
          AGraph.AddEdge(UnitId, DepId, AIDG_EDGE_USES_UNIT, Evidence);
        end;

        for K := 0 to Info.Registrations.Count - 1 do
        begin
          Reg := Info.Registrations[K];
          PasClass := FindClass(Info, Reg.RegisteredClass);
          if not Assigned(PasClass) then
            Continue;
          ComponentId := MakeAIDependencyNodeId(AIDG_NODE_COMPONENT,
            Reg.RegisteredClass);
          Evidence := MakeAIDependencyEvidence(SourceRel, PasClass.Line,
            'fgx_pascal.class');
          Node := AGraph.AddNode(ComponentId, AIDG_NODE_COMPONENT,
            Reg.RegisteredClass, SourceRel, Evidence);
          if Assigned(Node) then
          begin
            Node.Attrs.Values['ancestor'] := PasClass.Ancestor;
            Node.Attrs.Values['palette'] := Reg.Palette;
            Node.Attrs.Values['package'] := PackageName;
          end;
          AGraph.AddEdge(UnitId, ComponentId, AIDG_EDGE_DECLARES, Evidence);
          Evidence := MakeAIDependencyEvidence(SourceRel, Reg.Line,
            'fgx_pascal.registercomponents');
          AGraph.AddEdge(MakeAIDependencyNodeId(AIDG_NODE_PACKAGE, PackageName),
            ComponentId, AIDG_EDGE_REGISTERS, Evidence);
        end;
      finally
        Info.Free;
      end;
    end;
    NotifyStage(AOnStage, 4, 'Pascal components', 'PASS');

    NotifyStage(AOnStage, 5, 'Sample coverage', 'RUNNING');
    LogLine(ALog, 'Identifying sample projects and component usage...');
    for I := 0 to AScanner.ResultCount - 1 do
    begin
      Item := AScanner.GetResult(I);
      if (not Assigned(Item)) or (Item.ItemType = ditDirectory) then
        Continue;
      FileRel := RelToRoot(ARoot, Item.FullPath);
      if PathStartsWith(FileRel, 'pacote/samples') and SameText(Item.Extension, '.lpi') then
        SampleProjects.Add(FileRel);
    end;

    for I := 0 to SampleProjects.Count - 1 do
    begin
      SampleRel := SampleProjects[I];
      SampleProject := ToFullPath(ARoot, SampleRel);
      SampleDir := StringReplace(ExtractFileDir(StringReplace(SampleRel, '/',
        PathDelim, [rfReplaceAll])), PathDelim, '/', [rfReplaceAll]);
      SampleId := MakeAIDependencyNodeId(AIDG_NODE_SAMPLE, SampleRel);
      Evidence := MakeAIDependencyEvidence(SampleRel, 0, 'fgx_sample.lpi');
      Node := AGraph.AddNode(SampleId, AIDG_NODE_SAMPLE,
        ChangeFileExt(ExtractFileName(SampleRel), ''), SampleRel, Evidence);
      if Assigned(Node) then
      begin
        Node.Attrs.Values['project_file'] := SampleRel;
        Node.Attrs.Values['sample_dir'] := SampleDir;
        Node.Attrs.Values['build_status'] := 'NOT TESTED';
        Node.Attrs.Values['run_status'] := 'NOT TESTED';
      end;
      AGraph.AddEdge(RepoId, SampleId, AIDG_EDGE_CONTAINS, Evidence);

      ParseProjectRequiredPackages(SampleProject, SampleRequired, SampleErrors);
      for J := 0 to SampleRequired.Count - 1 do
      begin
        RequiredName := SampleRequired[J];
        Evidence := MakeAIDependencyEvidence(SampleRel, 0,
          'fgx_sample.lpi.required');
        if KnownPackages.IndexOf(RequiredName) >= 0 then
          DepId := MakeAIDependencyNodeId(AIDG_NODE_PACKAGE, RequiredName)
        else
        begin
          DepId := MakeAIDependencyNodeId(AIDG_NODE_EXTERNAL, RequiredName);
          AGraph.AddNode(DepId, AIDG_NODE_EXTERNAL, RequiredName, '', Evidence);
        end;
        AGraph.AddEdge(SampleId, DepId, AIDG_EDGE_REQUIRES_PACKAGE, Evidence);
      end;
      if SampleErrors.Count > 0 then
      begin
        Inc(AStats.ParseErrors, SampleErrors.Count);
        LogLine(ALog, Format('WARN: %s has %d project parse error(s).',
          [SampleRel, SampleErrors.Count]));
      end;

      for K := 0 to AScanner.ResultCount - 1 do
      begin
        Item := AScanner.GetResult(K);
        if (not Assigned(Item)) or (Item.ItemType = ditDirectory) then
          Continue;
        FileRel := RelToRoot(ARoot, Item.FullPath);
        Ext := LowerCase(Item.Extension);
        if PathStartsWith(FileRel, SampleDir) and
           ((Ext = '.pas') or (Ext = '.pp') or (Ext = '.lpr') or (Ext = '.lfm')) then
        begin
          CollectFileIdentifiers(Item.FullPath, Identifiers);
          for J := 0 to AGraph.Nodes.Count - 1 do
          begin
            Node := AGraph.Nodes[J];
            if (Node.NodeType = AIDG_NODE_COMPONENT) and
               (Identifiers.IndexOfName(LowerCase(Node.Name)) >= 0) then
            begin
              LineNo := StrToIntDef(Identifiers.Values[LowerCase(Node.Name)], 0);
              Evidence := MakeAIDependencyEvidence(FileRel, LineNo,
                'fgx_sample.identifier');
              AGraph.AddEdge(Node.Id, SampleId, AIDG_EDGE_DEMONSTRATED_BY, Evidence);
            end;
          end;
        end;
      end;
    end;
    NotifyStage(AOnStage, 5, 'Sample coverage', 'PASS');

    NotifyStage(AOnStage, 6, 'Graph validation', 'RUNNING');
    Validation := AGraph.Validate;
    AStats.Packages := AGraph.CountNodesOfType(AIDG_NODE_PACKAGE);
    AStats.Units := AGraph.CountNodesOfType(AIDG_NODE_UNIT);
    AStats.Components := AGraph.CountNodesOfType(AIDG_NODE_COMPONENT);
    AStats.Samples := AGraph.CountNodesOfType(AIDG_NODE_SAMPLE);
    AStats.ExternalDependencies := AGraph.CountNodesOfType(AIDG_NODE_EXTERNAL);
    AStats.PackageLinks := AGraph.CountEdgesOfType(AIDG_EDGE_REQUIRES_PACKAGE);
    AStats.ComponentSampleLinks := AGraph.CountEdgesOfType(AIDG_EDGE_DEMONSTRATED_BY);
    LogLine(ALog, Format('Graph: %d nodes, %d edges, validation=%s.',
      [AGraph.NodeCount, AGraph.EdgeCount, BoolToStr(Validation.Passed, True)]));
    Result := Validation.Passed;
    if Result then
      NotifyStage(AOnStage, 6, 'Graph validation', 'PASS')
    else
      NotifyStage(AOnStage, 6, 'Graph validation', 'FAIL');
  finally
    SampleErrors.Free;
    SampleRequired.Free;
    Identifiers.Free;
    SampleProjects.Free;
    UnitPackages.Free;
    UnitFiles.Free;
    KnownPackages.Free;
    Packages.Free;
  end;
end;

end.
