{
  fgxcli.lpr — AI Framework Graph Explorer (nucleo factual, modo console)

  Executa o recorte da "primeira sessao" da especificacao, secao 16:
    scan -> classificar -> parser LPK -> nos de pacote/unit -> requires_package
    -> validar -> exportar inventory.json, factual_graph.json, graph.dot

  SEM LLM. SEM LCL. SEM dependencia dos pacotes openai_*.
  Compila com: fpc -Fu<src> fgxcli.lpr

  Uso: fgxcli <raiz-do-repositorio> [pasta-de-saida]
}
program fgxcli;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, fgl,
  fgx_graph, fgx_lpk, fgx_scan, fgx_pascal;

type
  TLPKList = specialize TFPGObjectList<TLPKPackage>;

function RelToRoot(const ARoot, APath: string): string;
var
  R, P: string;
begin
  R := IncludeTrailingPathDelimiter(ExpandFileName(ARoot));
  P := ExpandFileName(APath);
  if CompareText(Copy(P, 1, Length(R)), R) = 0 then
    Result := Copy(P, Length(R) + 1, MaxInt)
  else
    Result := P;
  Result := StringReplace(Result, '\', '/', [rfReplaceAll]);
  if Result = '' then Result := '.';
end;

function IsSamplePath(const ARelPath: string): Boolean;
begin
  Result := Pos('pacote/samples/', LowerCase(ARelPath)) = 1;
end;

function DirPart(const ARelPath: string): string;
begin
  Result := StringReplace(ExtractFileDir(StringReplace(ARelPath, '/',
    PathDelim, [rfReplaceAll])), PathDelim, '/', [rfReplaceAll]);
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

procedure WriteStabilityReport(const AFileName: string; AGraph: TFGXGraph);
var
  Root: TJSONObject;
  OrphanComponents, UnusedUnits, PackageDeps: TJSONArray;
  O, P: TJSONObject;
  Arr: TJSONArray;
  I, J: Integer;
  N: TFGXNode;
  E: TFGXEdge;
  HasDemo, HasIncomingUse: Boolean;
  SL: TStringList;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('schema', 'fgx-stability-report-v1');
    Root.Add('warning', 'Conservative static analysis; false positives and false negatives are possible. Every item includes factual evidence.');
    OrphanComponents := TJSONArray.Create;
    UnusedUnits := TJSONArray.Create;
    PackageDeps := TJSONArray.Create;

    for I := 0 to AGraph.Nodes.Count - 1 do
    begin
      N := AGraph.Nodes[I];
      if N.NodeType = NT_COMPONENT then
      begin
        HasDemo := False;
        for J := 0 to AGraph.Edges.Count - 1 do
          if (AGraph.Edges[J].FromId = N.Id) and
             (AGraph.Edges[J].EdgeType = ET_DEMONSTRATED_BY) then HasDemo := True;
        if not HasDemo then
        begin
          O := TJSONObject.Create;
          O.Add('component', N.Name);
          O.Add('file', N.Evidence.SourceFile);
          O.Add('line', N.Evidence.Line);
          OrphanComponents.Add(O);
        end;
      end
      else if N.NodeType = NT_UNIT then
      begin
        HasIncomingUse := False;
        for J := 0 to AGraph.Edges.Count - 1 do
          if (AGraph.Edges[J].ToId = N.Id) and
             (AGraph.Edges[J].EdgeType = ET_USES_UNIT) then HasIncomingUse := True;
        if not HasIncomingUse then
        begin
          O := TJSONObject.Create;
          O.Add('unit', N.Name);
          O.Add('file', N.Evidence.SourceFile);
          O.Add('line', N.Evidence.Line);
          UnusedUnits.Add(O);
        end;
      end;
    end;

    for I := 0 to AGraph.Nodes.Count - 1 do
      if AGraph.Nodes[I].NodeType = NT_PACKAGE then
      begin
        N := AGraph.Nodes[I];
        P := TJSONObject.Create;
        P.Add('package', N.Name);
        Arr := TJSONArray.Create;
        for J := 0 to AGraph.Edges.Count - 1 do
        begin
          E := AGraph.Edges[J];
          if (E.FromId = N.Id) and (E.EdgeType = ET_REQUIRES_PACKAGE) then
          begin
            O := TJSONObject.Create;
            O.Add('target', AGraph.FindNode(E.ToId).Name);
            O.Add('file', E.Evidence.SourceFile);
            O.Add('line', E.Evidence.Line);
            Arr.Add(O);
          end;
        end;
        P.Add('dependencies', Arr);
        PackageDeps.Add(P);
      end;

    Root.Add('components_without_sample', OrphanComponents);
    Root.Add('units_without_incoming_use', UnusedUnits);
    Root.Add('package_dependencies', PackageDeps);
    SL := TStringList.Create;
    try
      SL.Text := Root.FormatJSON();
      SL.SaveToFile(AFileName);
    finally
      SL.Free;
    end;
  finally
    Root.Free;
  end;
end;

procedure WriteInventory(const AFileName: string; AList: TArtifactList;
                         const AStats: TScanStats);
var
  Root: TJSONObject;
  Arr: TJSONArray;
  Counts: TJSONObject;
  O: TJSONObject;
  I: Integer;
  K: TArtifactKind;
  N: Integer;
  SL: TStringList;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('schema', 'fgx-inventory-v1');
    Root.Add('generated_at', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
    Root.Add('dirs', AStats.Dirs);
    Root.Add('files', AStats.Files);
    Root.Add('skipped_dirs', AStats.Skipped);

    Counts := TJSONObject.Create;
    for K := Low(TArtifactKind) to High(TArtifactKind) do
    begin
      N := 0;
      for I := 0 to AList.Count - 1 do
        if AList[I].Kind = K then
          Inc(N);
      Counts.Add(KindName(K), N);
    end;
    Root.Add('counts_by_kind', Counts);

    Arr := TJSONArray.Create;
    for I := 0 to AList.Count - 1 do
    begin
      O := TJSONObject.Create;
      O.Add('path', AList[I].RelPath);
      O.Add('kind', KindName(AList[I].Kind));
      Arr.Add(O);
    end;
    Root.Add('items', Arr);

    SL := TStringList.Create;
    try
      SL.Text := Root.FormatJSON();
      SL.SaveToFile(AFileName);
    finally
      SL.Free;
    end;
  finally
    Root.Free;
  end;
end;

var
  Root, OutDir: string;
  Artifacts: TArtifactList;
  Stats: TScanStats;
  Pkgs: TLPKList;
  Graph: TFGXGraph;
  I, J: Integer;
  Pkg: TLPKPackage;
  U: TLPKUnit;
  Ev: TFGXEvidence;
  RepoId, PkgId, UnitId, DepId: string;
  Known: TStringList;
  V: TFGXValidation;
  ParseErrCount, PartialCount: Integer;
  ReqName: string;
  UnitFiles, UnitPkgs, SampleDirs: TStringList;
  Info: TPascalUnitInfo;
  Ref: TPascalRef;
  Reg: TComponentRegistration;
  C: TPascalClass;
  UnitName, SourcePath, SourceRel, TargetId, ComponentId: string;
  SampleDir, SampleId: string;
  LineNo, K: Integer;
  N: TFGXNode;
  Identifiers: TStringList;

begin
  if ParamCount < 1 then
  begin
    WriteLn('Uso: fgxcli <raiz-do-repositorio> [pasta-de-saida]');
    Halt(2);
  end;

  Root := ExpandFileName(ParamStr(1));
  if ParamCount >= 2 then
    OutDir := ExpandFileName(ParamStr(2))
  else
    OutDir := IncludeTrailingPathDelimiter(GetCurrentDir) + 'output';

  ForceDirectories(OutDir);
  OutDir := IncludeTrailingPathDelimiter(OutDir);

  WriteLn('== AI Framework Graph Explorer (nucleo factual) ==');
  WriteLn('Raiz : ', Root);
  WriteLn('Saida: ', OutDir);
  WriteLn;

  Artifacts := TArtifactList.Create(True);
  Pkgs := TLPKList.Create(True);
  Graph := TFGXGraph.Create;
  Known := TStringList.Create;
  Known.Sorted := True;
  Known.Duplicates := dupIgnore;
  Known.CaseSensitive := False;
  UnitFiles := TStringList.Create;
  UnitFiles.NameValueSeparator := '=';
  UnitFiles.CaseSensitive := False;
  UnitPkgs := TStringList.Create;
  UnitPkgs.NameValueSeparator := '=';
  UnitPkgs.CaseSensitive := False;
  SampleDirs := TStringList.Create;
  SampleDirs.Sorted := True;
  SampleDirs.Duplicates := dupIgnore;
  SampleDirs.CaseSensitive := False;
  Identifiers := TStringList.Create;
  Identifiers.NameValueSeparator := '=';
  Identifiers.CaseSensitive := False;

  try
    { ---- 1. Varredura e classificacao (G009-G011) ---- }
    ScanTree(Root, Artifacts, Stats);
    WriteLn(Format('[scan] %d diretorios, %d arquivos, %d dirs ignorados',
      [Stats.Dirs, Stats.Files, Stats.Skipped]));

    WriteInventory(OutDir + 'inventory.json', Artifacts, Stats);
    WriteLn('[scan] inventory.json gravado');

    { ---- 2. Parser de LPK (G015) ---- }
    ParseErrCount := 0;
    PartialCount := 0;

    for I := 0 to Artifacts.Count - 1 do
      if Artifacts[I].Kind = akPackage then
      begin
        Pkg := ParseLPK(Artifacts[I].FullPath);
        Pkgs.Add(Pkg);
        Known.Add(Pkg.Name);

        if Pkg.Partial then
        begin
          Inc(PartialCount);
          Inc(ParseErrCount, Pkg.ParseErrors.Count);
        end;
      end;

    WriteLn(Format('[lpk ] %d pacotes lidos (%d parciais, %d erros)',
      [Pkgs.Count, PartialCount, ParseErrCount]));

    if Pkgs.Count = 0 then
    begin
      WriteLn;
      WriteLn('ERRO: nenhum .lpk encontrado. Raiz correta?');
      Halt(1);
    end;

    { ---- 3. Grafo factual (G032 / G033 / G037) ---- }
    RepoId := MakeNodeId(NT_REPOSITORY, ExtractFileName(
                ExcludeTrailingPathDelimiter(Root)));
    Ev := MakeEvidence('.', 0, 'fgx_scan');
    Graph.AddNode(RepoId, NT_REPOSITORY,
      ExtractFileName(ExcludeTrailingPathDelimiter(Root)), '.', Ev);

    WriteLn('[graph] criando pacotes e units');
    for I := 0 to Pkgs.Count - 1 do
    begin
      Pkg := Pkgs[I];
      WriteLn(Format('[graph] pacote %d/%d: %s (%d units)',
        [I + 1, Pkgs.Count, Pkg.Name, Pkg.Units.Count]));

      { G032: no de pacote }
      PkgId := MakeNodeId(NT_PACKAGE, Pkg.Name);
      Ev := MakeEvidence(RelToRoot(Root, Pkg.LPKPath), 0, 'fgx_lpk');
      with Graph.AddNode(PkgId, NT_PACKAGE, Pkg.Name,
        RelToRoot(Root, Pkg.LPKPath), Ev) do
      begin
        Attrs.Values['package_type'] := Pkg.PackageType;
        Attrs.Values['unit_count'] := IntToStr(Pkg.Units.Count);
        if Pkg.Partial then
          Attrs.Values['parse_status'] := 'partial'
        else
          Attrs.Values['parse_status'] := 'ok';
      end;

      Graph.AddEdge(RepoId, PkgId, ET_CONTAINS, Ev);

      { G033: nos de unit + aresta contains }
      for J := 0 to Pkg.Units.Count - 1 do
      begin
        U := Pkg.Units[J];
        if Trim(U.UnitIdent) = '' then
          Continue;

        UnitId := MakeNodeId(NT_UNIT, U.UnitIdent);
        SourcePath := ExpandFileName(IncludeTrailingPathDelimiter(
          ExtractFileDir(Pkg.LPKPath)) + StringReplace(U.FileName, '/',
          PathDelim, [rfReplaceAll]));
        SourceRel := RelToRoot(Root, SourcePath);
        Ev := MakeEvidence(RelToRoot(Root, Pkg.LPKPath), 0, 'fgx_lpk');

        with Graph.AddNode(UnitId, NT_UNIT, U.UnitIdent, SourceRel, Ev) do
        begin
          Attrs.Values['package'] := Pkg.Name;
          if U.HasRegisterProc then
            Attrs.Values['has_register_proc'] := 'true'
          else
            Attrs.Values['has_register_proc'] := 'false';
        end;

        Graph.AddEdge(PkgId, UnitId, ET_CONTAINS, Ev);
        UnitFiles.Values[LowerCase(U.UnitIdent)] := SourcePath;
        UnitPkgs.Values[LowerCase(U.UnitIdent)] := Pkg.Name;
      end;
    end;

    WriteLn('[graph] criando dependencias de pacotes');
    { G037: requires_package, direto do RequiredPkgs do LPK }
    for I := 0 to Pkgs.Count - 1 do
    begin
      Pkg := Pkgs[I];
      PkgId := MakeNodeId(NT_PACKAGE, Pkg.Name);

      for J := 0 to Pkg.RequiredPkgs.Count - 1 do
      begin
        ReqName := Pkg.RequiredPkgs[J];
        Ev := MakeEvidence(RelToRoot(Root, Pkg.LPKPath), 0, 'fgx_lpk');

        if Known.IndexOf(ReqName) >= 0 then
          DepId := MakeNodeId(NT_PACKAGE, ReqName)
        else
        begin
          { Dependencia fora do repositorio: LCL, FCL, etc. Marcada como
            externa, nao inventada como pacote da suite. }
          DepId := MakeNodeId(NT_EXTERNAL, ReqName);
          Graph.AddNode(DepId, NT_EXTERNAL, ReqName, '', Ev);
        end;

        Graph.AddEdge(PkgId, DepId, ET_REQUIRES_PACKAGE, Ev);
      end;
    end;

    WriteLn('[graph] analisando Pascal');
    { ---- 4. Pascal: uses, classes publicas e RegisterComponents ---- }
    for I := 0 to UnitFiles.Count - 1 do
    begin
      UnitName := UnitFiles.Names[I];
      SourcePath := UnitFiles.ValueFromIndex[I];
      if not FileExists(SourcePath) then Continue;
      WriteLn(Format('[pas ] unit %d/%d: %s', [I + 1, UnitFiles.Count, UnitName]));
      SourceRel := RelToRoot(Root, SourcePath);
      UnitId := MakeNodeId(NT_UNIT, UnitName);
      Info := ParsePascalUnit(SourcePath);
      try
        for K := 0 to Info.InterfaceUses.Count + Info.ImplementationUses.Count - 1 do
        begin
          if K < Info.InterfaceUses.Count then Ref := Info.InterfaceUses[K]
          else Ref := Info.ImplementationUses[K - Info.InterfaceUses.Count];
          Ev := MakeEvidence(SourceRel, Ref.Line, 'fgx_pascal.uses');
          if UnitFiles.IndexOfName(LowerCase(Ref.Name)) >= 0 then
            TargetId := MakeNodeId(NT_UNIT, Ref.Name)
          else
          begin
            TargetId := MakeNodeId(NT_EXTERNAL, 'unit:' + Ref.Name);
            N := Graph.AddNode(TargetId, NT_EXTERNAL, Ref.Name, '', Ev);
            N.Attrs.Values['resolution'] := 'unresolved';
            N.Attrs.Values['reference_kind'] := 'pascal_unit';
          end;
          Graph.AddEdge(UnitId, TargetId, ET_USES_UNIT, Ev);
        end;

        for K := 0 to Info.Registrations.Count - 1 do
        begin
          Reg := Info.Registrations[K];
          C := FindClass(Info, Reg.RegisteredClass);
          if C = nil then Continue;
          ComponentId := MakeNodeId(NT_COMPONENT, Reg.RegisteredClass);
          Ev := MakeEvidence(SourceRel, C.Line, 'fgx_pascal.class');
          N := Graph.AddNode(ComponentId, NT_COMPONENT, Reg.RegisteredClass, SourceRel, Ev);
          N.Attrs.Values['ancestor'] := C.Ancestor;
          N.Attrs.Values['palette'] := Reg.Palette;
          N.Attrs.Values['package'] := UnitPkgs.Values[UnitName];
          Graph.AddEdge(UnitId, ComponentId, ET_DECLARES, Ev);
          Ev := MakeEvidence(SourceRel, Reg.Line, 'fgx_pascal.registercomponents');
          Graph.AddEdge(MakeNodeId(NT_PACKAGE, UnitPkgs.Values[UnitName]),
            ComponentId, ET_REGISTERS, Ev);
        end;
      finally
        Info.Free;
      end;
    end;

    { ---- 5. Samples e evidencia de uso ---- }
    for I := 0 to Artifacts.Count - 1 do
      if IsSamplePath(Artifacts[I].RelPath) and
         (Artifacts[I].Kind in [akProject, akProjectSrc]) then
        SampleDirs.Add(DirPart(Artifacts[I].RelPath));

    for I := 0 to SampleDirs.Count - 1 do
    begin
      SampleDir := SampleDirs[I];
      SampleId := MakeNodeId(NT_SAMPLE, SampleDir);
      Ev := MakeEvidence(SampleDir, 0, 'fgx_sample');
      Graph.AddNode(SampleId, NT_SAMPLE, ExtractFileName(StringReplace(
        SampleDir, '/', PathDelim, [rfReplaceAll])), SampleDir, Ev);
      Graph.AddEdge(RepoId, SampleId, ET_CONTAINS, Ev);

      for K := 0 to Artifacts.Count - 1 do
        if (Pos(LowerCase(SampleDir) + '/', LowerCase(Artifacts[K].RelPath)) = 1) and
           (Artifacts[K].Kind in [akPascal, akForm, akProjectSrc]) then
        begin
          CollectFileIdentifiers(Artifacts[K].FullPath, Identifiers);
          for J := 0 to Graph.Nodes.Count - 1 do
          begin
            N := Graph.Nodes[J];
            if N.NodeType <> NT_COMPONENT then Continue;
            if Identifiers.IndexOfName(LowerCase(N.Name)) >= 0 then
            begin
              LineNo := StrToIntDef(Identifiers.Values[LowerCase(N.Name)], 0);
              Ev := MakeEvidence(Artifacts[K].RelPath, LineNo,
                'fgx_sample.identifier');
              Graph.AddEdge(N.Id, SampleId, ET_DEMONSTRATED_BY, Ev);
            end;
          end;
        end;
    end;

    WriteLn(Format('[graph] %d nos, %d arestas', [Graph.NodeCount, Graph.EdgeCount]));
    WriteLn(Format('        packages=%d  units=%d  external=%d',
      [Graph.CountNodesOfType(NT_PACKAGE),
       Graph.CountNodesOfType(NT_UNIT),
       Graph.CountNodesOfType(NT_EXTERNAL)]));
    WriteLn(Format('        contains=%d  requires_package=%d',
      [Graph.CountEdgesOfType(ET_CONTAINS),
       Graph.CountEdgesOfType(ET_REQUIRES_PACKAGE)]));

    { ---- 6. Validacao (G040) ---- }
    V := Graph.Validate;
    WriteLn;
    WriteLn('[valid] arestas quebradas : ', V.BrokenEdges);
    WriteLn('[valid] sem evidencia     : ', V.NoEvidence);
    WriteLn('[valid] auto-arestas      : ', V.SelfEdges);
    WriteLn('[valid] nos orfaos        : ', V.OrphanNodes);
    if V.Passed then
      WriteLn('[valid] RESULTADO: PASS')
    else
      WriteLn('[valid] RESULTADO: FAIL');

    { ---- 7. Exportacao (G012 / G043 / E9) ---- }
    Graph.SaveJSON(OutDir + 'factual_graph.json');
    Graph.SaveDOT(OutDir + 'graph.dot');
    WriteStabilityReport(OutDir + 'stability_report.json', Graph);
    WriteLn;
    WriteLn('[out ] factual_graph.json');
    WriteLn('[out ] graph.dot');
    WriteLn('[out ] inventory.json');
    WriteLn('[out ] stability_report.json');

    if not V.Passed then
      Halt(1);

  finally
    Identifiers.Free;
    SampleDirs.Free;
    UnitPkgs.Free;
    UnitFiles.Free;
    Known.Free;
    Graph.Free;
    Pkgs.Free;
    Artifacts.Free;
  end;
end.
