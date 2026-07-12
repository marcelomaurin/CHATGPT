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
  fgx_graph, fgx_lpk, fgx_scan;

type
  TLPKList = specialize TFPGObjectList<TLPKPackage>;

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
    Ev := MakeEvidence(Root, 0, 'fgx_scan');
    Graph.AddNode(RepoId, NT_REPOSITORY,
      ExtractFileName(ExcludeTrailingPathDelimiter(Root)), Root, Ev);

    for I := 0 to Pkgs.Count - 1 do
    begin
      Pkg := Pkgs[I];

      { G032: no de pacote }
      PkgId := MakeNodeId(NT_PACKAGE, Pkg.Name);
      Ev := MakeEvidence(Pkg.LPKPath, 0, 'fgx_lpk');
      with Graph.AddNode(PkgId, NT_PACKAGE, Pkg.Name, Pkg.LPKPath, Ev) do
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
        Ev := MakeEvidence(Pkg.LPKPath, 0, 'fgx_lpk');

        with Graph.AddNode(UnitId, NT_UNIT, U.UnitIdent, U.FileName, Ev) do
        begin
          Attrs.Values['package'] := Pkg.Name;
          if U.HasRegisterProc then
            Attrs.Values['has_register_proc'] := 'true'
          else
            Attrs.Values['has_register_proc'] := 'false';
        end;

        Graph.AddEdge(PkgId, UnitId, ET_CONTAINS, Ev);
      end;
    end;

    { G037: requires_package, direto do RequiredPkgs do LPK }
    for I := 0 to Pkgs.Count - 1 do
    begin
      Pkg := Pkgs[I];
      PkgId := MakeNodeId(NT_PACKAGE, Pkg.Name);

      for J := 0 to Pkg.RequiredPkgs.Count - 1 do
      begin
        ReqName := Pkg.RequiredPkgs[J];
        Ev := MakeEvidence(Pkg.LPKPath, 0, 'fgx_lpk');

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

    WriteLn(Format('[graph] %d nos, %d arestas', [Graph.NodeCount, Graph.EdgeCount]));
    WriteLn(Format('        packages=%d  units=%d  external=%d',
      [Graph.CountNodesOfType(NT_PACKAGE),
       Graph.CountNodesOfType(NT_UNIT),
       Graph.CountNodesOfType(NT_EXTERNAL)]));
    WriteLn(Format('        contains=%d  requires_package=%d',
      [Graph.CountEdgesOfType(ET_CONTAINS),
       Graph.CountEdgesOfType(ET_REQUIRES_PACKAGE)]));

    { ---- 4. Validacao (G040) ---- }
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

    { ---- 5. Exportacao (G012 / G043) ---- }
    Graph.SaveJSON(OutDir + 'factual_graph.json');
    Graph.SaveDOT(OutDir + 'graph.dot');
    WriteLn;
    WriteLn('[out ] factual_graph.json');
    WriteLn('[out ] graph.dot');
    WriteLn('[out ] inventory.json');

    if not V.Passed then
      Halt(1);

  finally
    Known.Free;
    Graph.Free;
    Pkgs.Free;
    Artifacts.Free;
  end;
end.
