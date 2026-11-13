unit utester;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Grids, Dialogs, Spin, Process, fpjson, jsonparser, IniFiles;

type
  { TfrmTester - Suite Desktop Lazarus para Aferição e Avaliação de Respostas do NeuroGraph }
  TfrmTester = class(TForm)
  private
    // Painel Superior (Seleção de Rede e Base de Benchmark)
    PnlTop: TPanel;
    FCmbModelos: TComboBox;
    FBtnProcurarModelo: TButton;
    FCmbBenchmarks: TComboBox;
    FBtnProcurarBenchmark: TButton;
    FBtnBaixarInternet: TButton;
    FSpinMaxQuestoes: TSpinEdit;
    FChkCalibrarAntes: TCheckBox;
    FBtnRodarAfericao: TButton;
    FBtnPararTeste: TButton;
    FOpenDialogModelo: TOpenDialog;
    FOpenDialogBenchmark: TOpenDialog;

    // Painel de Indicadores (KPIs de Aferição)
    PnlKPIs: TPanel;
    FLblKpiTotal: TLabel;
    FLblKpiAprovados: TLabel;
    FLblKpiExactMatch: TLabel;
    FLblKpiF1Score: TLabel;
    FLblKpiLatencia: TLabel;

    // Abas Principais
    FPageControl: TPageControl;
    FTabGrade, FTabRelacional, FTabLog: TTabSheet;

    // Aba 1: Grade Comparativa (Pergunta x Esperado x Resposta do Modelo x F1 x Status)
    FGridResultados: TStringGrid;
    PnlDetalheItem: TPanel;
    FMemoDetalheItem: TMemo;

    // Aba 2: Teste de Propagação Relacional (Holdout)
    PnlRelTop: TPanel;
    FBtnRodarRelacional: TButton;
    FMemoRelacional: TMemo;

    // Aba 3: Log de Execução e Progresso
    FMemoLog: TMemo;
    FProgressBar: TProgressBar;

    // Controle de Processo
    FCurrentProcess: TProcess;
    FIsBusy: Boolean;
    FAbortRequested: Boolean;

    // Métodos Internos
    procedure BuildUI;
    procedure PopularModelos;
    procedure PopularBenchmarks;
    function ObterPythonExe: string;
    function ObterCaminhoAvaliadorPy: string;
    function ObterCaminhoIni: string;
    procedure CarregarConfiguracoes;
    procedure SalvarConfiguracoes;
    procedure LogMsg(const AMsg: string);
    procedure SetBusy(const ABusy: Boolean);
    procedure ExecutarScript(const AParametros: array of string; const ACarregarRelatorioAoFinal: Boolean);
    procedure CarregarUltimoRelatorioJSON;

    // Eventos
    procedure OnProcurarModeloClick(Sender: TObject);
    procedure OnProcurarBenchmarkClick(Sender: TObject);
    procedure OnBaixarInternetClick(Sender: TObject);
    procedure OnRodarAfericaoClick(Sender: TObject);
    procedure OnPararTesteClick(Sender: TObject);
    procedure OnRodarRelacionalClick(Sender: TObject);
    procedure OnGridSelection(Sender: TObject; aCol, aRow: Integer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmTester: TfrmTester;

implementation

constructor TfrmTester.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'NeuroGraph Tester — Suite de Testes, Benchmarks & Aferição de Respostas (Lazarus)';
  Width := 1080;
  Height := 760;
  Position := poScreenCenter;
  FIsBusy := False;
  FAbortRequested := False;
  FCurrentProcess := nil;

  BuildUI;
  PopularModelos;
  PopularBenchmarks;
  CarregarConfiguracoes;
  CarregarUltimoRelatorioJSON;
  OnClose := @FormClose;
end;

destructor TfrmTester.Destroy;
begin
  SalvarConfiguracoes;
  if Assigned(FCurrentProcess) then
  begin
    try
      if FCurrentProcess.Running then
        FCurrentProcess.Terminate(1);
    except
    end;
    FCurrentProcess.Free;
  end;
  inherited Destroy;
end;

procedure TfrmTester.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SalvarConfiguracoes;
  CloseAction := caFree;
end;

function TfrmTester.ObterCaminhoIni: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'neurograph_tester.ini';
end;

procedure TfrmTester.SalvarConfiguracoes;
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(ObterCaminhoIni);
    try
      Ini.WriteString('Tester', 'Modelo', FCmbModelos.Text);
      Ini.WriteString('Tester', 'Benchmark', FCmbBenchmarks.Text);
      Ini.WriteInteger('Tester', 'MaxQuestoes', FSpinMaxQuestoes.Value);
      Ini.WriteBool('Tester', 'CalibrarAntes', FChkCalibrarAntes.Checked);
    finally
      Ini.Free;
    end;
  except
  end;
end;

procedure TfrmTester.CarregarConfiguracoes;
var
  Ini: TIniFile;
  ModSalvo, BenchSalvo: string;
  Idx: Integer;
begin
  if not FileExists(ObterCaminhoIni) then Exit;

  try
    Ini := TIniFile.Create(ObterCaminhoIni);
    try
      ModSalvo := Ini.ReadString('Tester', 'Modelo', '');
      if ModSalvo <> '' then
      begin
        Idx := FCmbModelos.Items.IndexOf(ModSalvo);
        if Idx >= 0 then
          FCmbModelos.ItemIndex := Idx
        else
        begin
          FCmbModelos.Items.Insert(0, ModSalvo);
          FCmbModelos.ItemIndex := 0;
        end;
      end;

      BenchSalvo := Ini.ReadString('Tester', 'Benchmark', '');
      if BenchSalvo <> '' then
      begin
        Idx := FCmbBenchmarks.Items.IndexOf(BenchSalvo);
        if Idx >= 0 then
          FCmbBenchmarks.ItemIndex := Idx
        else
        begin
          FCmbBenchmarks.Items.Insert(0, BenchSalvo);
          FCmbBenchmarks.ItemIndex := 0;
        end;
      end;

      FSpinMaxQuestoes.Value := Ini.ReadInteger('Tester', 'MaxQuestoes', 100);
      FChkCalibrarAntes.Checked := Ini.ReadBool('Tester', 'CalibrarAntes', False);
    finally
      Ini.Free;
    end;
  except
  end;
end;

function TfrmTester.ObterPythonExe: string;
begin
  if FileExists('C:\Python312\python.exe') then
    Result := 'C:\Python312\python.exe'
  else
    Result := 'python.exe';
end;

function TfrmTester.ObterCaminhoAvaliadorPy: string;
var
  Base: string;
begin
  Base := ExtractFilePath(ParamStr(0));
  if FileExists(Base + 'avaliador_qa.py') then
    Exit(Base + 'avaliador_qa.py');
  if FileExists(ExpandFileName(Base + '..\avaliador_qa.py')) then
    Exit(ExpandFileName(Base + '..\avaliador_qa.py'));
  Result := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\tests\avaliador_qa.py';
end;

procedure TfrmTester.BuildUI;
var
  Lbl: TLabel;
begin
  // 1. Painel Superior (Controles de Seleção e Execução)
  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := 118;
  PnlTop.BevelOuter := bvNone;

  // Linha 1: Modelo (.ngs)
  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Rede / Modelo (.ngs):';
  Lbl.Left := 14;
  Lbl.Top := 14;
  Lbl.Font.Style := [fsBold];

  FCmbModelos := TComboBox.Create(Self);
  FCmbModelos.Parent := PnlTop;
  FCmbModelos.Left := 165;
  FCmbModelos.Top := 10;
  FCmbModelos.Width := 560;

  FBtnProcurarModelo := TButton.Create(Self);
  FBtnProcurarModelo.Parent := PnlTop;
  FBtnProcurarModelo.Caption := 'Procurar Rede...';
  FBtnProcurarModelo.Left := 735;
  FBtnProcurarModelo.Top := 8;
  FBtnProcurarModelo.Width := 130;
  FBtnProcurarModelo.Height := 28;
  FBtnProcurarModelo.OnClick := @OnProcurarModeloClick;

  // Linha 2: Base de Teste / Benchmark (.json)
  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Base de Teste (QA):';
  Lbl.Left := 14;
  Lbl.Top := 48;
  Lbl.Font.Style := [fsBold];

  FCmbBenchmarks := TComboBox.Create(Self);
  FCmbBenchmarks.Parent := PnlTop;
  FCmbBenchmarks.Left := 165;
  FCmbBenchmarks.Top := 44;
  FCmbBenchmarks.Width := 560;

  FBtnProcurarBenchmark := TButton.Create(Self);
  FBtnProcurarBenchmark.Parent := PnlTop;
  FBtnProcurarBenchmark.Caption := 'Abrir JSON...';
  FBtnProcurarBenchmark.Left := 735;
  FBtnProcurarBenchmark.Top := 42;
  FBtnProcurarBenchmark.Width := 130;
  FBtnProcurarBenchmark.Height := 28;
  FBtnProcurarBenchmark.OnClick := @OnProcurarBenchmarkClick;

  FBtnBaixarInternet := TButton.Create(Self);
  FBtnBaixarInternet.Parent := PnlTop;
  FBtnBaixarInternet.Caption := '🌐 Baixar Base FaQuAD (Internet)';
  FBtnBaixarInternet.Left := 872;
  FBtnBaixarInternet.Top := 8;
  FBtnBaixarInternet.Width := 195;
  FBtnBaixarInternet.Height := 62;
  FBtnBaixarInternet.OnClick := @OnBaixarInternetClick;

  // Linha 3: Opções e Botão de Aferição
  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Máx. Questões:';
  Lbl.Left := 14;
  Lbl.Top := 84;

  FSpinMaxQuestoes := TSpinEdit.Create(Self);
  FSpinMaxQuestoes.Parent := PnlTop;
  FSpinMaxQuestoes.Left := 115;
  FSpinMaxQuestoes.Top := 80;
  FSpinMaxQuestoes.Width := 75;
  FSpinMaxQuestoes.MinValue := 10;
  FSpinMaxQuestoes.MaxValue := 5000;
  FSpinMaxQuestoes.Value := 100;

  FChkCalibrarAntes := TCheckBox.Create(Self);
  FChkCalibrarAntes.Parent := PnlTop;
  FChkCalibrarAntes.Left := 205;
  FChkCalibrarAntes.Top := 83;
  FChkCalibrarAntes.Caption := 'Calibrar/Treinar Rede com esta Base antes de Aferir (Validação de Capacidade)';
  FChkCalibrarAntes.Checked := False;

  FBtnRodarAfericao := TButton.Create(Self);
  FBtnRodarAfericao.Parent := PnlTop;
  FBtnRodarAfericao.Caption := '🚀 Rodar Aferição de Respostas';
  FBtnRodarAfericao.Left := 685;
  FBtnRodarAfericao.Top := 76;
  FBtnRodarAfericao.Width := 230;
  FBtnRodarAfericao.Height := 34;
  FBtnRodarAfericao.Font.Style := [fsBold];
  FBtnRodarAfericao.OnClick := @OnRodarAfericaoClick;

  FBtnPararTeste := TButton.Create(Self);
  FBtnPararTeste.Parent := PnlTop;
  FBtnPararTeste.Caption := '⏹️ Parar';
  FBtnPararTeste.Left := 922;
  FBtnPararTeste.Top := 76;
  FBtnPararTeste.Width := 145;
  FBtnPararTeste.Height := 34;
  FBtnPararTeste.Enabled := False;
  FBtnPararTeste.OnClick := @OnPararTesteClick;

  FOpenDialogModelo := TOpenDialog.Create(Self);
  FOpenDialogModelo.Title := 'Selecionar Modelo NeuroGraph (.ngs)';
  FOpenDialogModelo.Filter := 'Redes NeuroGraph (*.ngs)|*.ngs|Todos (*.*)|*.*';

  FOpenDialogBenchmark := TOpenDialog.Create(Self);
  FOpenDialogBenchmark.Title := 'Selecionar Base de Teste QA (.json)';
  FOpenDialogBenchmark.Filter := 'Arquivos JSON (*.json)|*.json|Todos (*.*)|*.*';

  // 2. Painel de KPIs (Métricas de Aferição)
  PnlKPIs := TPanel.Create(Self);
  PnlKPIs.Parent := Self;
  PnlKPIs.Align := alTop;
  PnlKPIs.Height := 46;
  PnlKPIs.Color := $F0F4F8;
  PnlKPIs.BevelOuter := bvLowered;

  FLblKpiTotal := TLabel.Create(Self);
  FLblKpiTotal.Parent := PnlKPIs;
  FLblKpiTotal.Left := 16;
  FLblKpiTotal.Top := 14;
  FLblKpiTotal.Caption := 'Questões Avaliadas: 0';
  FLblKpiTotal.Font.Style := [fsBold];

  FLblKpiAprovados := TLabel.Create(Self);
  FLblKpiAprovados.Parent := PnlKPIs;
  FLblKpiAprovados.Left := 210;
  FLblKpiAprovados.Top := 14;
  FLblKpiAprovados.Caption := 'Aprovadas: 0 (0.0%)';
  FLblKpiAprovados.Font.Style := [fsBold];
  FLblKpiAprovados.Font.Color := $007000;

  FLblKpiExactMatch := TLabel.Create(Self);
  FLblKpiExactMatch.Parent := PnlKPIs;
  FLblKpiExactMatch.Left := 430;
  FLblKpiExactMatch.Top := 14;
  FLblKpiExactMatch.Caption := 'Exact Match (EM): 0.00%';
  FLblKpiExactMatch.Font.Style := [fsBold];
  FLblKpiExactMatch.Font.Color := clNavy;

  FLblKpiF1Score := TLabel.Create(Self);
  FLblKpiF1Score.Parent := PnlKPIs;
  FLblKpiF1Score.Left := 650;
  FLblKpiF1Score.Top := 14;
  FLblKpiF1Score.Caption := 'Token F1-Score: 0.00%';
  FLblKpiF1Score.Font.Style := [fsBold];
  FLblKpiF1Score.Font.Color := $800080;

  FLblKpiLatencia := TLabel.Create(Self);
  FLblKpiLatencia.Parent := PnlKPIs;
  FLblKpiLatencia.Left := 870;
  FLblKpiLatencia.Top := 14;
  FLblKpiLatencia.Caption := 'Latência Média: 0.0 ms';
  FLblKpiLatencia.Font.Style := [fsBold];

  // 3. Barra de Progresso Inferior
  FProgressBar := TProgressBar.Create(Self);
  FProgressBar.Parent := Self;
  FProgressBar.Align := alBottom;
  FProgressBar.Height := 10;

  // 4. PageControl Central
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;

  // Aba 1: Tabela de Aferição de Perguntas e Respostas
  FTabGrade := TTabSheet.Create(FPageControl);
  FTabGrade.PageControl := FPageControl;
  FTabGrade.Caption := '  📊 Aferição Detalhada (Pergunta vs. Gabarito vs. Modelo)  ';

  PnlDetalheItem := TPanel.Create(Self);
  PnlDetalheItem.Parent := FTabGrade;
  PnlDetalheItem.Align := alBottom;
  PnlDetalheItem.Height := 125;
  PnlDetalheItem.BevelOuter := bvNone;

  FMemoDetalheItem := TMemo.Create(Self);
  FMemoDetalheItem.Parent := PnlDetalheItem;
  FMemoDetalheItem.Align := alClient;
  FMemoDetalheItem.ReadOnly := True;
  FMemoDetalheItem.ScrollBars := ssAutoVertical;
  FMemoDetalheItem.Font.Name := 'Consolas';
  FMemoDetalheItem.Font.Size := 9;
  FMemoDetalheItem.Color := $FAFAFA;
  FMemoDetalheItem.Lines.Add('Selecione uma linha na tabela acima para inspecionar a pergunta completa, a resposta esperada da base e a resposta gerada pelo NeuroGraph.');

  FGridResultados := TStringGrid.Create(Self);
  FGridResultados.Parent := FTabGrade;
  FGridResultados.Align := alClient;
  FGridResultados.ColCount := 7;
  FGridResultados.RowCount := 1;
  FGridResultados.FixedCols := 0;
  FGridResultados.Options := FGridResultados.Options + [goRowSelect, goColSizing, goThumbTracking];
  FGridResultados.OnSelection := @OnGridSelection;

  FGridResultados.Cells[0, 0] := '#';
  FGridResultados.Cells[1, 0] := 'Pergunta';
  FGridResultados.Cells[2, 0] := 'Resposta Esperada (Gabarito)';
  FGridResultados.Cells[3, 0] := 'Resposta do Modelo (NeuroGraph)';
  FGridResultados.Cells[4, 0] := 'F1-Score';
  FGridResultados.Cells[5, 0] := 'Status da Aferição';
  FGridResultados.Cells[6, 0] := 'Tempo (ms)';

  FGridResultados.ColWidths[0] := 45;
  FGridResultados.ColWidths[1] := 270;
  FGridResultados.ColWidths[2] := 260;
  FGridResultados.ColWidths[3] := 260;
  FGridResultados.ColWidths[4] := 75;
  FGridResultados.ColWidths[5] := 140;
  FGridResultados.ColWidths[6] := 75;

  // Aba 2: Teste de Propagação Relacional (Holdout Baseline)
  FTabRelacional := TTabSheet.Create(FPageControl);
  FTabRelacional.PageControl := FPageControl;
  FTabRelacional.Caption := '  🔗 Teste de Propagação Relacional (Holdout)  ';

  PnlRelTop := TPanel.Create(Self);
  PnlRelTop.Parent := FTabRelacional;
  PnlRelTop.Align := alTop;
  PnlRelTop.Height := 46;
  PnlRelTop.BevelOuter := bvNone;

  FBtnRodarRelacional := TButton.Create(Self);
  FBtnRodarRelacional.Parent := PnlRelTop;
  FBtnRodarRelacional.Caption := '▶️ Executar Benchmark Relacional (1-Hop e 2-Hop)';
  FBtnRodarRelacional.Left := 12;
  FBtnRodarRelacional.Top := 8;
  FBtnRodarRelacional.Width := 320;
  FBtnRodarRelacional.Height := 30;
  FBtnRodarRelacional.OnClick := @OnRodarRelacionalClick;

  FMemoRelacional := TMemo.Create(Self);
  FMemoRelacional.Parent := FTabRelacional;
  FMemoRelacional.Align := alClient;
  FMemoRelacional.ReadOnly := True;
  FMemoRelacional.ScrollBars := ssAutoBoth;
  FMemoRelacional.Font.Name := 'Consolas';
  FMemoRelacional.Font.Size := 10;

  // Aba 3: Console / Log de Execução
  FTabLog := TTabSheet.Create(FPageControl);
  FTabLog.PageControl := FPageControl;
  FTabLog.Caption := '  🖥️ Log de Execução Python  ';

  FMemoLog := TMemo.Create(Self);
  FMemoLog.Parent := FTabLog;
  FMemoLog.Align := alClient;
  FMemoLog.ReadOnly := True;
  FMemoLog.ScrollBars := ssAutoBoth;
  FMemoLog.Color := $1E1E1E;
  FMemoLog.Font.Color := $DCDCDC;
  FMemoLog.Font.Name := 'Consolas';
  FMemoLog.Font.Size := 9;
end;

procedure TfrmTester.PopularModelos;
var
  Pastas: array[0..3] of string;
  i: Integer;
  SR: TSearchRec;
begin
  FCmbModelos.Items.Clear;
  Pastas[0] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\treino\modelos';
  Pastas[1] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\results';
  Pastas[2] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\baseline_v6';
  Pastas[3] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\history\2026-11-12';

  for i := 0 to High(Pastas) do
  begin
    if DirectoryExists(Pastas[i]) then
    begin
      if FindFirst(Pastas[i] + '\*.ngs', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr and faDirectory) = 0 then
            FCmbModelos.Items.Add(Pastas[i] + '\' + SR.Name);
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;
    end;
  end;

  if FCmbModelos.Items.Count > 0 then
    FCmbModelos.ItemIndex := 0;
end;

procedure TfrmTester.PopularBenchmarks;
var
  Pastas: array[0..2] of string;
  i: Integer;
  SR: TSearchRec;
begin
  FCmbBenchmarks.Items.Clear;
  Pastas[0] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\tests\benchmarks';
  Pastas[1] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\treino\dados\processados';
  Pastas[2] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\data';

  for i := 0 to High(Pastas) do
  begin
    if DirectoryExists(Pastas[i]) then
    begin
      if FindFirst(Pastas[i] + '\*.json', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr and faDirectory) = 0 then
            FCmbBenchmarks.Items.Add(Pastas[i] + '\' + SR.Name);
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;
    end;
  end;

  if FCmbBenchmarks.Items.Count > 0 then
    FCmbBenchmarks.ItemIndex := 0;
end;

procedure TfrmTester.LogMsg(const AMsg: string);
begin
  FMemoLog.Lines.Add(AMsg);
  FMemoLog.SelStart := Length(FMemoLog.Text);
  Application.ProcessMessages;
end;

procedure TfrmTester.SetBusy(const ABusy: Boolean);
begin
  FIsBusy := ABusy;
  FBtnRodarAfericao.Enabled := not ABusy;
  FBtnBaixarInternet.Enabled := not ABusy;
  FBtnRodarRelacional.Enabled := not ABusy;
  FBtnPararTeste.Enabled := ABusy;

  if ABusy then
  begin
    FProgressBar.Style := pbstMarquee;
    Screen.Cursor := crHourGlass;
  end
  else
  begin
    FProgressBar.Style := pbstNormal;
    FProgressBar.Position := 0;
    Screen.Cursor := crDefault;
  end;
  Application.ProcessMessages;
end;

procedure TfrmTester.ExecutarScript(const AParametros: array of string; const ACarregarRelatorioAoFinal: Boolean);
var
  P: TProcess;
  ScriptPy, LinhaAcumulada: string;
  Buffer: array[0..2047] of Byte;
  BytesRead, I: Integer;
begin
  if FIsBusy then Exit;
  ScriptPy := ObterCaminhoAvaliadorPy;
  if not FileExists(ScriptPy) then
  begin
    ShowMessage('Script avaliador_qa.py não encontrado em: ' + ScriptPy);
    Exit;
  end;

  SetBusy(True);
  FAbortRequested := False;
  LinhaAcumulada := '';

  P := TProcess.Create(nil);
  FCurrentProcess := P;
  try
    P.Executable := ObterPythonExe;
    P.Parameters.Add('-X');
    P.Parameters.Add('utf8');
    P.Parameters.Add('-u');
    P.Parameters.Add(ScriptPy);

    for I := Low(AParametros) to High(AParametros) do
      P.Parameters.Add(AParametros[I]);

    P.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    P.CurrentDirectory := ExtractFilePath(ScriptPy);

    LogMsg('============================================================');
    LogMsg('Executando: ' + P.Executable + ' ' + ScriptPy);
    P.Execute;

    while P.Running or (P.Output.NumBytesAvailable > 0) do
    begin
      if FAbortRequested then
      begin
        try
          P.Terminate(1);
          LogMsg('[AVISO] Execução interrompida pelo usuário.');
        except
        end;
        Break;
      end;

      while P.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := P.Output.Read(Buffer, SizeOf(Buffer) - 1);
        if BytesRead > 0 then
        begin
          Buffer[BytesRead] := 0;
          LinhaAcumulada := LinhaAcumulada + StrPas(PChar(@Buffer[0]));
          while Pos(#10, LinhaAcumulada) > 0 do
          begin
            LogMsg(TrimRight(Copy(LinhaAcumulada, 1, Pos(#10, LinhaAcumulada) - 1)));
            Delete(LinhaAcumulada, 1, Pos(#10, LinhaAcumulada));
          end;
        end;
      end;
      Sleep(15);
      Application.ProcessMessages;
    end;

    if Trim(LinhaAcumulada) <> '' then
      LogMsg(TrimRight(LinhaAcumulada));

  finally
    FCurrentProcess := nil;
    P.Free;
    SetBusy(False);
    if ACarregarRelatorioAoFinal then
      CarregarUltimoRelatorioJSON;
  end;
end;

procedure TfrmTester.CarregarUltimoRelatorioJSON;
var
  CaminhoRel: string;
  F: TFileStream;
  Parser: TJSONParser;
  Data: TJSONData;
  Root, Item: TJSONObject;
  Arr: TJSONArray;
  I, RowIdx: Integer;
begin
  CaminhoRel := ExtractFilePath(ObterCaminhoAvaliadorPy) + 'ultimo_relatorio_afericao.json';
  if not FileExists(CaminhoRel) then Exit;

  try
    F := TFileStream.Create(CaminhoRel, fmOpenRead or fmShareDenyNone);
    try
      Parser := TJSONParser.Create(F);
      try
        Data := Parser.Parse;
        if Assigned(Data) and (Data is TJSONObject) then
        begin
          Root := TJSONObject(Data);

          FLblKpiTotal.Caption := Format('Questões Avaliadas: %d', [Root.Get('total_questoes', 0)]);
          FLblKpiAprovados.Caption := Format('Aprovadas: %d (%.1f%%)', [
            Root.Get('aprovados', 0),
            Root.Get('taxa_aprovacao', 0.0)
          ]);
          FLblKpiExactMatch.Caption := Format('Exact Match (EM): %.2f%%', [Root.Get('exact_match_pct', 0.0)]);
          FLblKpiF1Score.Caption := Format('Token F1-Score: %.2f%%', [Root.Get('f1_score_pct', 0.0)]);
          FLblKpiLatencia.Caption := Format('Latência Média: %.2f ms', [Root.Get('latencia_media_ms', 0.0)]);

          Arr := Root.Find('resultados', jtArray) as TJSONArray;
          if Assigned(Arr) then
          begin
            FGridResultados.BeginUpdate;
            try
              FGridResultados.RowCount := Arr.Count + 1;
              for I := 0 to Arr.Count - 1 do
              begin
                Item := TJSONObject(Arr.Items[I]);
                RowIdx := I + 1;
                FGridResultados.Cells[0, RowIdx] := IntToStr(Item.Get('id', RowIdx));
                FGridResultados.Cells[1, RowIdx] := Item.Get('question', '');
                FGridResultados.Cells[2, RowIdx] := Item.Get('expected', '');
                FGridResultados.Cells[3, RowIdx] := Item.Get('predicted', '');
                FGridResultados.Cells[4, RowIdx] := Format('%.1f%%', [Item.Get('f1', 0.0) * 100.0]);
                FGridResultados.Cells[5, RowIdx] := Item.Get('status', '');
                FGridResultados.Cells[6, RowIdx] := Format('%.2f', [Item.Get('latency_ms', 0.0)]);
              end;
            finally
              FGridResultados.EndUpdate;
            end;

            if FGridResultados.RowCount > 1 then
              OnGridSelection(FGridResultados, 0, 1);
          end;
        end;
      finally
        Parser.Free;
        if Assigned(Data) then Data.Free;
      end;
    finally
      F.Free;
    end;
  except
    on E: Exception do
      LogMsg('[ERRO] Falha ao ler relatório de aferição: ' + E.Message);
  end;
end;

procedure TfrmTester.OnGridSelection(Sender: TObject; aCol, aRow: Integer);
begin
  if (aRow < 1) or (aRow >= FGridResultados.RowCount) then Exit;

  FMemoDetalheItem.Lines.BeginUpdate;
  try
    FMemoDetalheItem.Clear;
    FMemoDetalheItem.Lines.Add(Format('QUESTÃO #%s | Status: %s | Token F1-Score: %s | Tempo: %s ms', [
      FGridResultados.Cells[0, aRow],
      FGridResultados.Cells[5, aRow],
      FGridResultados.Cells[4, aRow],
      FGridResultados.Cells[6, aRow]
    ]));
    FMemoDetalheItem.Lines.Add('--------------------------------------------------------------------------------');
    FMemoDetalheItem.Lines.Add('PERGUNTA           : ' + FGridResultados.Cells[1, aRow]);
    FMemoDetalheItem.Lines.Add('GABARITO ESPERADO  : ' + FGridResultados.Cells[2, aRow]);
    FMemoDetalheItem.Lines.Add('RESPOSTA DO MODELO : ' + FGridResultados.Cells[3, aRow]);
  finally
    FMemoDetalheItem.Lines.EndUpdate;
  end;
end;

procedure TfrmTester.OnProcurarModeloClick(Sender: TObject);
begin
  if FOpenDialogModelo.Execute then
  begin
    FCmbModelos.Items.Insert(0, FOpenDialogModelo.FileName);
    FCmbModelos.ItemIndex := 0;
  end;
end;

procedure TfrmTester.OnProcurarBenchmarkClick(Sender: TObject);
begin
  if FOpenDialogBenchmark.Execute then
  begin
    FCmbBenchmarks.Items.Insert(0, FOpenDialogBenchmark.FileName);
    FCmbBenchmarks.ItemIndex := 0;
  end;
end;

procedure TfrmTester.OnBaixarInternetClick(Sender: TObject);
begin
  FPageControl.ActivePage := FTabLog;
  ExecutarScript(['--baixar-internet'], False);
  PopularBenchmarks;
  ShowMessage('Bases públicas de QA em português (FaQuAD - UFMS) baixadas e atualizadas com sucesso!');
end;

procedure TfrmTester.OnRodarAfericaoClick(Sender: TObject);
var
  ModPath, BenchPath: string;
  Params: array of string;
begin
  ModPath := Trim(FCmbModelos.Text);
  BenchPath := Trim(FCmbBenchmarks.Text);

  if (ModPath = '') or not FileExists(ModPath) then
  begin
    ShowMessage('Selecione um arquivo de modelo (.ngs) válido.');
    Exit;
  end;

  if (BenchPath = '') or not FileExists(BenchPath) then
  begin
    ShowMessage('Selecione uma base de teste JSON válida (ou clique em Baixar Base FaQuAD).');
    Exit;
  end;

  if FChkCalibrarAntes.Checked then
  begin
    SetLength(Params, 7);
    Params[0] := '--modelo';
    Params[1] := ModPath;
    Params[2] := '--benchmark';
    Params[3] := BenchPath;
    Params[4] := '--max-itens';
    Params[5] := IntToStr(FSpinMaxQuestoes.Value);
    Params[6] := '--calibrar-antes';
  end
  else
  begin
    SetLength(Params, 6);
    Params[0] := '--modelo';
    Params[1] := ModPath;
    Params[2] := '--benchmark';
    Params[3] := BenchPath;
    Params[4] := '--max-itens';
    Params[5] := IntToStr(FSpinMaxQuestoes.Value);
  end;

  ExecutarScript(Params, True);
  FPageControl.ActivePage := FTabGrade;
end;

procedure TfrmTester.OnPararTesteClick(Sender: TObject);
begin
  FAbortRequested := True;
end;

procedure TfrmTester.OnRodarRelacionalClick(Sender: TObject);
begin
  FMemoRelacional.Clear;
  ExecutarScript(['--relacional'], False);
  FMemoRelacional.Lines.Assign(FMemoLog.Lines);
end;

end.
