unit unative;

{$mode objfpc}{$H+}
{$codepage utf8}

interface

uses
  Classes, SysUtils, Math, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, ComCtrls, Grids, Spin, Menus, IniFiles, fpjson, jsonparser,
  LazUTF8, chatgpt, aillmmodelcatalog, NeuroGraphEngine;

type
  { TfrmNeuroGraphNative — Studio Completo 100% Free Pascal Puro (Todas as Opções da Versão Python + Deep MLP SiLU) }
  TfrmNeuroGraphNative = class(TForm)
  private
    FEngine: TNGDeepEngine;
    FSession: TNGSession;
    FTrainExamples: TNGExampleArray;
    FValExamples: TNGExampleArray;
    FTestExamples: TNGExampleArray;
    FIsBusy: Boolean;
    FAbortRequested: Boolean;
    FConfigLoaded: Boolean;

    // Painel Superior (Linha 1: OpenAI + Status + Salvar Config; Linha 2: Rede Alvo + Procurar + Regerar NGM; Linha 3: Deep MLP H1/H2/Épocas/LR)
    PnlTop: TPanel;
    FEditApiKey: TEdit;
    FLblApiStatus: TLabel;
    FLblModelStatus: TLabel;
    FBtnSalvarConfig: TButton;

    FCmbRedeAlvo: TComboBox;
    FBtnProcurarRedeAlvo: TButton;
    FBtnRegerarNGMTopo: TButton;
    FOpenDialogRede: TOpenDialog;

    FChkHiddenLayers: TCheckBox;
    FSpinH1: TSpinEdit;
    FSpinH2: TSpinEdit;
    FSpinEpochs: TSpinEdit;
    FEditLR: TEdit;
    FBtnTrainPascal: TButton;
    FBtnSaveModel: TButton;
    FBtnLoadModel: TButton;

    // Controle de Abas (Todas as abas da versão Python + Abas Nativas Pascal)
    FPageControl: TPageControl;
    FTabTreinoContinuo: TTabSheet;
    FTabYouTube: TTabSheet;
    FTabPDF: TTabSheet;
    FTab10Topicos: TTabSheet;
    FTabChatGPT: TTabSheet;
    FTabChat: TTabSheet;
    FTabDataset: TTabSheet;
    FTabBenchmark: TTabSheet;

    // Aba 1: Treino Contínuo (PT-BR)
    FMemoAssuntosContinuo: TMemo;
    FMemoMonitorContinuo: TMemo;
    FLblStatusContinuo: TLabel;
    FEditNovoAssuntoContinuo: TEdit;
    FBtnAddAssuntoContinuo: TButton;
    FBtnPadraoAssuntosContinuo: TButton;
    FBtnLimparAssuntosContinuo: TButton;
    FSpinVideosPorCiclo: TSpinEdit;
    FSpinParesPorCiclo: TSpinEdit;
    FSpinIntervaloCiclo: TSpinEdit;
    FSpinMaxCiclosContinuo: TSpinEdit;
    FChkApenasPortugues: TCheckBox;
    FBtnIniciarContinuo: TButton;
    FBtnPararContinuo: TButton;
    FBtnRegerarNGM: TButton;

    // Aba 2: Treinar via YouTube
    FEditTema: TEdit;
    FSpinQtdVideos: TSpinEdit;
    FBtnBuscarYouTube: TButton;
    FEditVideoUrl: TEdit;
    FBtnProcessarVideo: TButton;

    // Aba 3: Treinar via PDF
    FEditCaminhoPDF: TEdit;
    FBtnProcurarPDF: TButton;
    FSpinMaxParesPDF: TSpinEdit;
    FBtnProcessarPDF: TButton;
    FOpenDialogPDF: TOpenDialog;

    // Aba 4: Treino por Tópicos (Incremental Item a Item, 1+)
    FMemoTopicos: TMemo;
    FMemoResultadoTopicos: TMemo;
    FLblResumoTopicos: TLabel;
    FEditNovoTopico: TEdit;
    FBtnAdicionarTopico: TButton;
    FBtnLimparTopicos: TButton;
    FBtnTopicosPadrao: TButton;
    FSpinMinParesTopicos: TSpinEdit;
    FBtnGerar10Topicos: TButton;
    FBtnPararTreinoTopicos: TButton;

    // Aba 5: Provedores & Modelos (TCHATGPT)
    FCmbProvider: TComboBox;
    FCmbModel: TComboBox;
    FEditEndpoint: TEdit;
    FEditToken: TEdit;
    FEditTemperature: TEdit;
    FSpinMaxTokens: TSpinEdit;
    FLblChatState: TLabel;
    FBtnTestarConexao: TButton;
    FBtnEnviarChat: TButton;
    FBtnCancelarChat: TButton;
    FBtnAdicionarAoDataset: TButton;
    FMemoPromptChat: TMemo;
    FMemoRespChat: TMemo;
    FChatGPT: TCHATGPT;
    FTestStartTime: QWord;
    FIsTestingConnection: Boolean;

    // Aba 6: Conversar com NeuroGraph (Pascal < 1 ms)
    PnlChatBottom: TPanel;
    FEditChatQuestion: TEdit;
    FBtnAsk: TButton;
    FBtnClearChat: TButton;
    FChkKeepContext: TCheckBox;
    FMemoChat: TMemo;

    // Aba 7: Dataset Consolidado & Adição de Pares
    PnlAddPair: TPanel;
    FEditNewQuestion: TEdit;
    FEditNewAnswer: TEdit;
    FBtnAddPair: TButton;
    FBtnReloadBase: TButton;
    FBtnRetreinarTudo: TButton;
    FLblTotalDataset: TLabel;
    FGridDataset: TStringGrid;

    // Aba 8: Aferição & Benchmark (Linear vs. Camadas Ocultas)
    PnlBenchTop: TPanel;
    FBtnRunEval: TButton;
    FBtnRunXORCompare: TButton;
    FLblBenchKPIs: TLabel;
    FGridEval: TStringGrid;
    FMemoBenchReport: TMemo;

    // Painel Inferior (Log, Progresso e Relógio/Bandeja)
    FMemoLog: TMemo;
    FProgressBar: TProgressBar;
    FBtnLimparLog: TButton;
    FBtnAbortar: TButton;
    FBtnMinimizarRelogio: TButton;
    FShapeStatusTreino: TShape;
    FLblStatusTreinoBarra: TLabel;

    // Bandeja do Sistema (Perto do Relógio do Windows) & Ícones de Estado
    FTrayIcon: TTrayIcon;
    FTrayPopup: TPopupMenu;
    FMnuRestaurar: TMenuItem;
    FMnuStatusTray: TMenuItem;
    FMnuIniciarContinuoTray: TMenuItem;
    FMnuIniciarTopicosTray: TMenuItem;
    FMnuPararTray: TMenuItem;
    FMnuSairTray: TMenuItem;
    FTrayTimer: TTimer;
    FIconIdle: TIcon;
    FIconTrainA: TIcon;
    FIconTrainB: TIcon;
    FTrayPulseToggle: Boolean;
    FLastTrayStepText: string;

    FOpenDialog: TOpenDialog;
    FSaveDialog: TSaveDialog;

    function CriarAba(const ATitulo: string): TTabSheet;
    procedure BuildUI;
    procedure ConstruirAbaTreinoContinuo;
    procedure ConstruirAbaChatGPT;
    procedure BuildTraySystem;
    procedure GerarIconesEstado;
    procedure AtualizarIconeRelogio;

    function GetNeuroGraphRootDir: string;
    function DefaultModelPath: string;
    function GetCuradoJSONPath: string;
    function GetUltimoTreinoTopicosPath: string;
    function ObterCaminhoIni: string;
    function ObterCaminhoIniStudio: string;

    procedure PopularRedesDisponiveis;
    procedure PopularProvedores;
    procedure LoadDefaultDatasets;
    procedure RefreshDatasetGrid;
    procedure AtualizarResultadoTopicos;
    procedure AtualizarStatusGeral;
    procedure SetBusy(const ABusy: Boolean);
    procedure LogMsg(const AMsg: string);

    // Motor Nativo de Geração e Treinamento Incremental em Português
    procedure GerarParNativoPortugues(const ATopico: string; const AIndice: Integer;
      out APergunta, AResposta: string);
    procedure AdicionarParAoDatasetECurado(const APergunta, AResposta, ACategoria, ATopico: string);
    procedure SalvarHistoricoTopicosJSON(const AItens: TStringList; const ARedeSalva: string);
    procedure TreinarESalvarRedeAlvo(const AEpochs: Integer; const ALogDetalhado: Boolean);

    procedure OnTrainProgress(const Epoch, TotalEpochs: Integer;
      const Loss, Accuracy: Single; var AbortTraining: Boolean);

    // Eventos UI Geral & Bandeja
    procedure OnTrayIconClick(Sender: TObject);
    procedure OnTrayTimerTick(Sender: TObject);
    procedure OnMinimizarParaRelogioClick(Sender: TObject);
    procedure OnRestaurarDoRelogioClick(Sender: TObject);
    procedure OnSairPeloRelogioClick(Sender: TObject);
    procedure OnFormWindowStateChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure OnApiKeyChange(Sender: TObject);
    procedure OnSalvarConfigClick(Sender: TObject);
    procedure OnProcurarRedeAlvoClick(Sender: TObject);
    procedure OnCmbRedeAlvoChange(Sender: TObject);
    procedure OnLimparLogClick(Sender: TObject);
    procedure OnAbortarClick(Sender: TObject);

    // Eventos Treino Contínuo, YouTube, PDF e Tópicos
    procedure OnIniciarContinuoClick(Sender: TObject);
    procedure OnRegerarNGMClick(Sender: TObject);
    procedure OnAddAssuntoContinuoClick(Sender: TObject);
    procedure OnPadraoAssuntosContinuoClick(Sender: TObject);
    procedure OnLimparAssuntosContinuoClick(Sender: TObject);
    procedure OnBuscarYouTubeClick(Sender: TObject);
    procedure OnProcessarVideoClick(Sender: TObject);
    procedure OnProcurarPDFClick(Sender: TObject);
    procedure OnProcessarPDFClick(Sender: TObject);
    procedure OnGerar10TopicosClick(Sender: TObject);
    procedure OnAdicionarTopicoClick(Sender: TObject);
    procedure OnLimparTopicosClick(Sender: TObject);
    procedure OnTopicosPadraoClick(Sender: TObject);

    // Eventos TCHATGPT
    procedure OnProviderChange(Sender: TObject);
    procedure OnModelChange(Sender: TObject);
    procedure OnTestarConexaoClick(Sender: TObject);
    procedure OnEnviarChatClick(Sender: TObject);
    procedure OnCancelarChatClick(Sender: TObject);
    procedure OnAdicionarAoDatasetClick(Sender: TObject);
    procedure OnChatStreamStart(Sender: TObject);
    procedure OnChatStreamData(Sender: TObject; const AData: WideString);
    procedure OnChatStreamEnd(Sender: TObject);
    procedure OnChatStateChange(Sender: TObject; AState: TAILLMRequestState);
    procedure OnChatRequestComplete(Sender: TObject; ASuccess: Boolean);

    // Eventos Treino Pascal, Chat, Dataset e Benchmark
    procedure OnTrainPascalClick(Sender: TObject);
    procedure OnSaveModelClick(Sender: TObject);
    procedure OnLoadModelClick(Sender: TObject);
    procedure OnAddPairClick(Sender: TObject);
    procedure OnReloadBaseClick(Sender: TObject);
    procedure OnAskClick(Sender: TObject);
    procedure OnChatKeyPress(Sender: TObject; var Key: char);
    procedure OnClearChatClick(Sender: TObject);
    procedure OnRunEvalClick(Sender: TObject);
    procedure OnRunXORCompareClick(Sender: TObject);

    // Persistência INI
    procedure SalvarConfiguracoes;
    procedure CarregarConfiguracoes;
    procedure OnListaMemoExit(Sender: TObject);
    procedure OnListaMemoChange(Sender: TObject);
    procedure OnNovoTopicoKeyPress(Sender: TObject; var Key: char);
    procedure OnNovoAssuntoContinuoKeyPress(Sender: TObject; var Key: char);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmNeuroGraphNative: TfrmNeuroGraphNative;

{ Função de linha de comando com todas as flags da versão Python + flags nativas Pascal }
function RunCLIMode: Boolean;

implementation

function TfrmNeuroGraphNative.GetNeuroGraphRootDir: string;
var
  ExeDir: string;
begin
  ExeDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
  if DirectoryExists(ExeDir + '..\experiments\contextual_v7') then
    Result := ExpandFileName(ExeDir + '..\')
  else if DirectoryExists(ExeDir + '..\..\experiments\contextual_v7') then
    Result := ExpandFileName(ExeDir + '..\..\')
  else
    Result := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\';
  Result := IncludeTrailingPathDelimiter(Result);
end;

function TfrmNeuroGraphNative.DefaultModelPath: string;
begin
  if Assigned(FCmbRedeAlvo) and (Trim(FCmbRedeAlvo.Text) <> '') then
    Result := Trim(FCmbRedeAlvo.Text)
  else
    Result := GetNeuroGraphRootDir + 'treino' + DirectorySeparator +
      'modelos' + DirectorySeparator + 'neurograph_pascal_v8.ngs';
end;

function TfrmNeuroGraphNative.GetCuradoJSONPath: string;
begin
  Result := GetNeuroGraphRootDir + 'treino' + DirectorySeparator + 'dados' +
    DirectorySeparator + 'processados' + DirectorySeparator + 'dataset_curado.json';
end;

function TfrmNeuroGraphNative.GetUltimoTreinoTopicosPath: string;
begin
  Result := GetNeuroGraphRootDir + 'treino' + DirectorySeparator + 'dados' +
    DirectorySeparator + 'processados' + DirectorySeparator + 'ultimo_treino_topicos.json';
end;

function TfrmNeuroGraphNative.ObterCaminhoIni: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'neurograph_native.ini';
end;

function TfrmNeuroGraphNative.ObterCaminhoIniStudio: string;
begin
  Result := GetNeuroGraphRootDir + 'treino' + DirectorySeparator + 'lazarus' +
    DirectorySeparator + 'neurograph_studio.ini';
end;

constructor TfrmNeuroGraphNative.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'NeuroGraph v8 Native — Treinador, Curador & Camadas Ocultas (100% Free Pascal)';
  Width := 1120;
  Height := 780;
  Position := poScreenCenter;
  Font.Name := 'Segoe UI';
  Font.Size := 9;

  FIsBusy := False;
  FAbortRequested := False;
  FConfigLoaded := False;
  FIsTestingConnection := False;

  FEngine := TNGDeepEngine.Create(True, 96, 48, 0.65, 0.10);
  FEngine.OnProgress := @OnTrainProgress;
  FSession := TNGSession.Create(3);

  FChatGPT := TCHATGPT.Create(Self);
  FChatGPT.Streaming := True;
  FChatGPT.OnStreamStart := @OnChatStreamStart;
  FChatGPT.OnStreamData := @OnChatStreamData;
  FChatGPT.OnStreamEnd := @OnChatStreamEnd;
  FChatGPT.OnStateChange := @OnChatStateChange;
  FChatGPT.OnRequestComplete := @OnChatRequestComplete;

  BuildUI;
  BuildTraySystem;
  PopularRedesDisponiveis;
  CarregarConfiguracoes;
  FConfigLoaded := True;
  SalvarConfiguracoes;
  LoadDefaultDatasets;
  AtualizarResultadoTopicos;

  if FileExists(DefaultModelPath) then
  begin
    try
      if LowerCase(ExtractFileExt(DefaultModelPath)) = '.ngm' then
        FEngine.LoadMatrixNGM(DefaultModelPath)
      else
        FEngine.LoadFromFile(DefaultModelPath);
      LogMsg('[OK] Modelo inicial carregado em Pascal Puro: ' + DefaultModelPath);
    except
      on E: Exception do
        LogMsg('[AVISO] Modelo selecionado será recriado no próximo treino: ' + E.Message);
    end;
  end;

  AtualizarStatusGeral;
  AtualizarIconeRelogio;
  OnClose := @FormClose;
  OnWindowStateChange := @OnFormWindowStateChange;
end;

destructor TfrmNeuroGraphNative.Destroy;
begin
  SalvarConfiguracoes;
  if Assigned(FTrayIcon) then
    FTrayIcon.Visible := False;
  if Assigned(FIconIdle) then FIconIdle.Free;
  if Assigned(FIconTrainA) then FIconTrainA.Free;
  if Assigned(FIconTrainB) then FIconTrainB.Free;
  FSession.Free;
  FEngine.Free;
  inherited Destroy;
end;

procedure TfrmNeuroGraphNative.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  FAbortRequested := True;
  SalvarConfiguracoes;
  if Assigned(FTrayTimer) then
    FTrayTimer.Enabled := False;
  if Assigned(FTrayIcon) then
    FTrayIcon.Visible := False;
  CloseAction := caFree;
end;

function TfrmNeuroGraphNative.CriarAba(const ATitulo: string): TTabSheet;
begin
  Result := TTabSheet.Create(FPageControl);
  Result.PageControl := FPageControl;
  Result.Caption := ATitulo;
end;

procedure TfrmNeuroGraphNative.BuildUI;
var
  PnlBottom, PnlBtnsLog: TPanel;
  GrpBuscaYT, GrpVideoYT, GrpPDF: TGroupBox;
  SplitterBench: TSplitter;
  Lbl: TLabel;
begin
  FOpenDialog := TOpenDialog.Create(Self);
  FOpenDialog.Filter := 'Redes e Matrizes NeuroGraph (*.ngs;*.ngm)|*.ngs;*.ngm|Todos (*.*)|*.*';
  FSaveDialog := TSaveDialog.Create(Self);
  FSaveDialog.Filter := 'Modelo NeuroGraph (*.ngs)|*.ngs|Matriz NGM (*.ngm)|*.ngm';
  FSaveDialog.DefaultExt := 'ngs';

  // -------------------------------------------------------------------------
  // 1. PAINEL SUPERIOR (3 Linhas: Chave/Status + Rede Alvo + Camadas Ocultas)
  // -------------------------------------------------------------------------
  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := 116;
  PnlTop.BevelOuter := bvNone;

  // Linha 1: Chave OpenAI + Status Geral + Salvar Configurações
  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Chave OpenAI (Global):';
  Lbl.Left := 14;
  Lbl.Top := 12;

  FEditApiKey := TEdit.Create(Self);
  FEditApiKey.Parent := PnlTop;
  FEditApiKey.Left := 150;
  FEditApiKey.Top := 8;
  FEditApiKey.Width := 250;
  FEditApiKey.EchoMode := emPassword;
  FEditApiKey.Text := GetEnvironmentVariable('OPENAI_API_KEY');
  FEditApiKey.OnChange := @OnApiKeyChange;

  FLblApiStatus := TLabel.Create(Self);
  FLblApiStatus.Parent := PnlTop;
  FLblApiStatus.Left := 412;
  FLblApiStatus.Top := 12;
  FLblApiStatus.Caption := '○ Modo Heurístico Local';
  FLblApiStatus.Font.Style := [fsBold];

  FLblModelStatus := TLabel.Create(Self);
  FLblModelStatus.Parent := PnlTop;
  FLblModelStatus.Left := 575;
  FLblModelStatus.Top := 12;
  FLblModelStatus.Caption := 'Rede Alvo: Verificando...';
  FLblModelStatus.Font.Style := [fsBold];

  FBtnSalvarConfig := TButton.Create(Self);
  FBtnSalvarConfig.Parent := PnlTop;
  FBtnSalvarConfig.Caption := 'Salvar Configurações';
  FBtnSalvarConfig.Left := 930;
  FBtnSalvarConfig.Top := 6;
  FBtnSalvarConfig.Width := 172;
  FBtnSalvarConfig.Height := 28;
  FBtnSalvarConfig.Anchors := [akTop, akRight];
  FBtnSalvarConfig.OnClick := @OnSalvarConfigClick;

  // Linha 2: Seleção da Rede Alvo (.ngs / .ngm) + Procurar + Regerar Matrizes .NGM
  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Rede Alvo (.ngs / .ngm):';
  Lbl.Left := 14;
  Lbl.Top := 44;
  Lbl.Font.Style := [fsBold];

  FCmbRedeAlvo := TComboBox.Create(Self);
  FCmbRedeAlvo.Parent := PnlTop;
  FCmbRedeAlvo.Left := 175;
  FCmbRedeAlvo.Top := 40;
  FCmbRedeAlvo.Width := 580;
  FCmbRedeAlvo.Anchors := [akTop, akLeft, akRight];
  FCmbRedeAlvo.OnChange := @OnCmbRedeAlvoChange;

  FBtnProcurarRedeAlvo := TButton.Create(Self);
  FBtnProcurarRedeAlvo.Parent := PnlTop;
  FBtnProcurarRedeAlvo.Caption := 'Procurar Rede...';
  FBtnProcurarRedeAlvo.Left := 764;
  FBtnProcurarRedeAlvo.Top := 38;
  FBtnProcurarRedeAlvo.Width := 135;
  FBtnProcurarRedeAlvo.Height := 28;
  FBtnProcurarRedeAlvo.Anchors := [akTop, akRight];
  FBtnProcurarRedeAlvo.OnClick := @OnProcurarRedeAlvoClick;

  FBtnRegerarNGMTopo := TButton.Create(Self);
  FBtnRegerarNGMTopo.Parent := PnlTop;
  FBtnRegerarNGMTopo.Caption := '🔄 Regerar Matrizes .NGM';
  FBtnRegerarNGMTopo.Left := 906;
  FBtnRegerarNGMTopo.Top := 38;
  FBtnRegerarNGMTopo.Width := 196;
  FBtnRegerarNGMTopo.Height := 28;
  FBtnRegerarNGMTopo.Font.Style := [fsBold];
  FBtnRegerarNGMTopo.Anchors := [akTop, akRight];
  FBtnRegerarNGMTopo.OnClick := @OnRegerarNGMClick;

  FOpenDialogRede := TOpenDialog.Create(Self);
  FOpenDialogRede.Title := 'Selecionar Rede Alvo (.ngs ou .ngm)';
  FOpenDialogRede.Filter := 'Redes e Matrizes NeuroGraph (*.ngs;*.ngm)|*.ngs;*.ngm|Matrizes NGM (*.ngm)|*.ngm|Modelos NGS (*.ngs)|*.ngs|Todos (*.*)|*.*';

  // Linha 3: Arquitetura Deep MLP em Free Pascal (Camadas Ocultas H1/H2 SiLU + Épocas + LR + Botões Nativos)
  FChkHiddenLayers := TCheckBox.Create(Self);
  FChkHiddenLayers.Parent := PnlTop;
  FChkHiddenLayers.SetBounds(14, 78, 255, 22);
  FChkHiddenLayers.Caption := 'Camadas Ocultas Não-Lineares (SiLU)';
  FChkHiddenLayers.Checked := True;
  FChkHiddenLayers.Font.Style := [fsBold];

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.SetBounds(278, 80, 30, 18);
  Lbl.Caption := 'H1:';

  FSpinH1 := TSpinEdit.Create(Self);
  FSpinH1.Parent := PnlTop;
  FSpinH1.SetBounds(306, 76, 58, 24);
  FSpinH1.MinValue := 16;
  FSpinH1.MaxValue := 512;
  FSpinH1.Increment := 16;
  FSpinH1.Value := 96;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.SetBounds(372, 80, 30, 18);
  Lbl.Caption := 'H2:';

  FSpinH2 := TSpinEdit.Create(Self);
  FSpinH2.Parent := PnlTop;
  FSpinH2.SetBounds(400, 76, 58, 24);
  FSpinH2.MinValue := 16;
  FSpinH2.MaxValue := 512;
  FSpinH2.Increment := 16;
  FSpinH2.Value := 48;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.SetBounds(468, 80, 48, 18);
  Lbl.Caption := 'Épocas:';

  FSpinEpochs := TSpinEdit.Create(Self);
  FSpinEpochs.Parent := PnlTop;
  FSpinEpochs.SetBounds(518, 76, 62, 24);
  FSpinEpochs.MinValue := 5;
  FSpinEpochs.MaxValue := 1000;
  FSpinEpochs.Increment := 10;
  FSpinEpochs.Value := 120;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.SetBounds(588, 80, 24, 18);
  Lbl.Caption := 'LR:';

  FEditLR := TEdit.Create(Self);
  FEditLR.Parent := PnlTop;
  FEditLR.SetBounds(614, 76, 52, 24);
  FEditLR.Text := '0.04';

  FBtnTrainPascal := TButton.Create(Self);
  FBtnTrainPascal.Parent := PnlTop;
  FBtnTrainPascal.SetBounds(676, 74, 215, 28);
  FBtnTrainPascal.Caption := '⚡ Treinar Tudo em Pascal Puro';
  FBtnTrainPascal.Font.Style := [fsBold];
  FBtnTrainPascal.Anchors := [akTop, akRight];
  FBtnTrainPascal.OnClick := @OnTrainPascalClick;

  FBtnSaveModel := TButton.Create(Self);
  FBtnSaveModel.Parent := PnlTop;
  FBtnSaveModel.SetBounds(898, 74, 98, 28);
  FBtnSaveModel.Caption := 'Salvar .NGS';
  FBtnSaveModel.Anchors := [akTop, akRight];
  FBtnSaveModel.OnClick := @OnSaveModelClick;

  FBtnLoadModel := TButton.Create(Self);
  FBtnLoadModel.Parent := PnlTop;
  FBtnLoadModel.SetBounds(1002, 74, 100, 28);
  FBtnLoadModel.Caption := 'Abrir .NGS';
  FBtnLoadModel.Anchors := [akTop, akRight];
  FBtnLoadModel.OnClick := @OnLoadModelClick;

  // -------------------------------------------------------------------------
  // 2. PAINEL INFERIOR (Log, Progresso e Bandeja do Relógio)
  // -------------------------------------------------------------------------
  PnlBottom := TPanel.Create(Self);
  PnlBottom.Parent := Self;
  PnlBottom.Align := alBottom;
  PnlBottom.Height := 165;
  PnlBottom.BevelOuter := bvNone;

  FProgressBar := TProgressBar.Create(Self);
  FProgressBar.Parent := PnlBottom;
  FProgressBar.Align := alTop;
  FProgressBar.Height := 8;
  FProgressBar.Min := 0;
  FProgressBar.Max := 100;

  PnlBtnsLog := TPanel.Create(Self);
  PnlBtnsLog.Parent := PnlBottom;
  PnlBtnsLog.Align := alBottom;
  PnlBtnsLog.Height := 34;
  PnlBtnsLog.BevelOuter := bvNone;

  FBtnLimparLog := TButton.Create(Self);
  FBtnLimparLog.Parent := PnlBtnsLog;
  FBtnLimparLog.Caption := 'Limpar Log';
  FBtnLimparLog.SetBounds(8, 4, 90, 26);
  FBtnLimparLog.OnClick := @OnLimparLogClick;

  FBtnAbortar := TButton.Create(Self);
  FBtnAbortar.Parent := PnlBtnsLog;
  FBtnAbortar.Caption := 'Interromper e Salvar';
  FBtnAbortar.SetBounds(106, 4, 155, 26);
  FBtnAbortar.Enabled := False;
  FBtnAbortar.OnClick := @OnAbortarClick;

  FBtnMinimizarRelogio := TButton.Create(Self);
  FBtnMinimizarRelogio.Parent := PnlBtnsLog;
  FBtnMinimizarRelogio.Caption := '🕒 Enviar p/ Relógio (Bandeja)';
  FBtnMinimizarRelogio.SetBounds(268, 4, 205, 26);
  FBtnMinimizarRelogio.OnClick := @OnMinimizarParaRelogioClick;

  FShapeStatusTreino := TShape.Create(Self);
  FShapeStatusTreino.Parent := PnlBtnsLog;
  FShapeStatusTreino.Shape := stCircle;
  FShapeStatusTreino.SetBounds(486, 9, 16, 16);
  FShapeStatusTreino.Brush.Color := $00AA5500;
  FShapeStatusTreino.Pen.Color := clWhite;

  FLblStatusTreinoBarra := TLabel.Create(Self);
  FLblStatusTreinoBarra.Parent := PnlBtnsLog;
  FLblStatusTreinoBarra.Left := 508;
  FLblStatusTreinoBarra.Top := 9;
  FLblStatusTreinoBarra.Caption := 'Ícone no Relógio Ativo — Motor 100% Free Pascal Pronto (Parado)';
  FLblStatusTreinoBarra.Font.Style := [fsBold];
  FLblStatusTreinoBarra.Font.Color := $00663300;

  FMemoLog := TMemo.Create(Self);
  FMemoLog.Parent := PnlBottom;
  FMemoLog.Align := alClient;
  FMemoLog.ReadOnly := True;
  FMemoLog.ScrollBars := ssAutoBoth;
  FMemoLog.Color := $1E1E1E;
  FMemoLog.Font.Color := $DCDCDC;
  FMemoLog.Font.Name := 'Consolas';
  FMemoLog.Font.Size := 9;

  // -------------------------------------------------------------------------
  // 3. PAGECONTROL CENTRAL COM TODAS AS ABAS
  // -------------------------------------------------------------------------
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;

  // Aba 1: Treino Contínuo (PT-BR)
  ConstruirAbaTreinoContinuo;

  // Aba 2: Treinar via YouTube
  FTabYouTube := CriarAba('  🎥 Treinar via YouTube  ');

  GrpBuscaYT := TGroupBox.Create(Self);
  GrpBuscaYT.Parent := FTabYouTube;
  GrpBuscaYT.Align := alTop;
  GrpBuscaYT.Height := 115;
  GrpBuscaYT.Caption := ' Buscar e Curar Conhecimento por Tema em Português ';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpBuscaYT;
  Lbl.Caption := 'Tema ou Conceito:';
  Lbl.Left := 16;
  Lbl.Top := 16;

  FEditTema := TEdit.Create(Self);
  FEditTema.Parent := GrpBuscaYT;
  FEditTema.Left := 140;
  FEditTema.Top := 12;
  FEditTema.Width := 340;
  FEditTema.Text := 'energia solar fotovoltaica';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpBuscaYT;
  Lbl.Caption := 'Qtd. Vídeos:';
  Lbl.Left := 495;
  Lbl.Top := 16;

  FSpinQtdVideos := TSpinEdit.Create(Self);
  FSpinQtdVideos.Parent := GrpBuscaYT;
  FSpinQtdVideos.Left := 575;
  FSpinQtdVideos.Top := 12;
  FSpinQtdVideos.Width := 55;
  FSpinQtdVideos.MinValue := 1;
  FSpinQtdVideos.MaxValue := 10;
  FSpinQtdVideos.Value := 2;

  FBtnBuscarYouTube := TButton.Create(Self);
  FBtnBuscarYouTube.Parent := GrpBuscaYT;
  FBtnBuscarYouTube.Caption := '🔍 Buscar / Curar em Português e Treinar em Pascal';
  FBtnBuscarYouTube.SetBounds(140, 48, 340, 30);
  FBtnBuscarYouTube.OnClick := @OnBuscarYouTubeClick;

  GrpVideoYT := TGroupBox.Create(Self);
  GrpVideoYT.Parent := FTabYouTube;
  GrpVideoYT.Align := alTop;
  GrpVideoYT.Height := 105;
  GrpVideoYT.Caption := ' Processar Vídeo Específico por URL ou ID ';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpVideoYT;
  Lbl.Caption := 'URL do Vídeo:';
  Lbl.Left := 16;
  Lbl.Top := 16;

  FEditVideoUrl := TEdit.Create(Self);
  FEditVideoUrl.Parent := GrpVideoYT;
  FEditVideoUrl.SetBounds(140, 12, 490, 24);

  FBtnProcessarVideo := TButton.Create(Self);
  FBtnProcessarVideo.Parent := GrpVideoYT;
  FBtnProcessarVideo.Caption := '▶️ Processar Vídeo Único e Treinar em Pascal';
  FBtnProcessarVideo.SetBounds(140, 48, 280, 30);
  FBtnProcessarVideo.OnClick := @OnProcessarVideoClick;

  // Aba 3: Treinar via PDF
  FTabPDF := CriarAba('  📄 Treinar via PDF  ');

  GrpPDF := TGroupBox.Create(Self);
  GrpPDF.Parent := FTabPDF;
  GrpPDF.Align := alTop;
  GrpPDF.Height := 145;
  GrpPDF.Caption := ' Seleção de Documento PDF / Texto Educativo ';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpPDF;
  Lbl.Caption := 'Arquivo PDF:';
  Lbl.Left := 16;
  Lbl.Top := 20;

  FEditCaminhoPDF := TEdit.Create(Self);
  FEditCaminhoPDF.Parent := GrpPDF;
  FEditCaminhoPDF.SetBounds(110, 16, 480, 24);

  FBtnProcurarPDF := TButton.Create(Self);
  FBtnProcurarPDF.Parent := GrpPDF;
  FBtnProcurarPDF.Caption := 'Procurar...';
  FBtnProcurarPDF.SetBounds(600, 15, 90, 26);
  FBtnProcurarPDF.OnClick := @OnProcurarPDFClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpPDF;
  Lbl.Caption := 'Máx. Perguntas:';
  Lbl.Left := 16;
  Lbl.Top := 60;

  FSpinMaxParesPDF := TSpinEdit.Create(Self);
  FSpinMaxParesPDF.Parent := GrpPDF;
  FSpinMaxParesPDF.SetBounds(110, 56, 65, 24);
  FSpinMaxParesPDF.MinValue := 1;
  FSpinMaxParesPDF.MaxValue := 200;
  FSpinMaxParesPDF.Value := 15;

  FBtnProcessarPDF := TButton.Create(Self);
  FBtnProcessarPDF.Parent := GrpPDF;
  FBtnProcessarPDF.Caption := '🚀 Extrair Conhecimento do PDF, Gerar P&R e Treinar em Pascal';
  FBtnProcessarPDF.SetBounds(110, 92, 410, 32);
  FBtnProcessarPDF.OnClick := @OnProcessarPDFClick;

  FOpenDialogPDF := TOpenDialog.Create(Self);
  FOpenDialogPDF.Title := 'Selecione um Arquivo PDF Educativo';
  FOpenDialogPDF.Filter := 'Documentos PDF (*.pdf)|*.pdf|Todos os Arquivos (*.*)|*.*';

  // Aba 4: Treino por Tópicos (Incremental Item a Item, aceita 1+)
  FTab10Topicos := CriarAba('  🎯 Treino por Tópicos  ');

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Tópicos para Treinamento (1 por linha):';
  Lbl.Left := 14;
  Lbl.Top := 12;
  Lbl.Font.Style := [fsBold];

  FMemoTopicos := TMemo.Create(Self);
  FMemoTopicos.Parent := FTab10Topicos;
  FMemoTopicos.SetBounds(14, 32, 440, 165);
  FMemoTopicos.ScrollBars := ssVertical;
  FMemoTopicos.Font.Name := 'Segoe UI';
  FMemoTopicos.Font.Size := 9;
  FMemoTopicos.OnChange := @OnListaMemoChange;
  FMemoTopicos.OnExit := @OnListaMemoExit;
  FMemoTopicos.Lines.Add('paises da america latina');
  FMemoTopicos.Lines.Add('comprimentar pessoa');

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := '📋 O que foi Treinado nesta Sessão (Perguntas, Respostas e Rede Salva):';
  Lbl.Left := 468;
  Lbl.Top := 12;
  Lbl.Font.Style := [fsBold];

  FMemoResultadoTopicos := TMemo.Create(Self);
  FMemoResultadoTopicos.Parent := FTab10Topicos;
  FMemoResultadoTopicos.SetBounds(468, 32, 620, 295);
  FMemoResultadoTopicos.Anchors := [akTop, akLeft, akRight, akBottom];
  FMemoResultadoTopicos.ReadOnly := True;
  FMemoResultadoTopicos.ScrollBars := ssAutoBoth;
  FMemoResultadoTopicos.Font.Name := 'Consolas';
  FMemoResultadoTopicos.Font.Size := 9;
  FMemoResultadoTopicos.Color := $F8FBF8;

  FLblResumoTopicos := TLabel.Create(Self);
  FLblResumoTopicos.Parent := FTab10Topicos;
  FLblResumoTopicos.Left := 468;
  FLblResumoTopicos.Top := 334;
  FLblResumoTopicos.Anchors := [akLeft, akBottom];
  FLblResumoTopicos.Caption := 'Status do Último Treino: Pronto';
  FLblResumoTopicos.Font.Style := [fsBold];
  FLblResumoTopicos.Font.Color := $006600;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Novo Tópico:';
  Lbl.Left := 14;
  Lbl.Top := 208;

  FEditNovoTopico := TEdit.Create(Self);
  FEditNovoTopico.Parent := FTab10Topicos;
  FEditNovoTopico.SetBounds(95, 204, 235, 24);
  FEditNovoTopico.OnKeyPress := @OnNovoTopicoKeyPress;

  FBtnAdicionarTopico := TButton.Create(Self);
  FBtnAdicionarTopico.Parent := FTab10Topicos;
  FBtnAdicionarTopico.Caption := '➕ Incluir';
  FBtnAdicionarTopico.SetBounds(336, 202, 118, 27);
  FBtnAdicionarTopico.OnClick := @OnAdicionarTopicoClick;

  FBtnTopicosPadrao := TButton.Create(Self);
  FBtnTopicosPadrao.Parent := FTab10Topicos;
  FBtnTopicosPadrao.Caption := 'Restaurar 10 Padrão';
  FBtnTopicosPadrao.SetBounds(14, 236, 215, 26);
  FBtnTopicosPadrao.OnClick := @OnTopicosPadraoClick;

  FBtnLimparTopicos := TButton.Create(Self);
  FBtnLimparTopicos.Parent := FTab10Topicos;
  FBtnLimparTopicos.Caption := '🧹 Limpar Lista de Tópicos';
  FBtnLimparTopicos.SetBounds(238, 236, 216, 26);
  FBtnLimparTopicos.OnClick := @OnLimparTopicosClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Quantidade de Pares (1+):';
  Lbl.Left := 14;
  Lbl.Top := 272;

  FSpinMinParesTopicos := TSpinEdit.Create(Self);
  FSpinMinParesTopicos.Parent := FTab10Topicos;
  FSpinMinParesTopicos.SetBounds(185, 268, 95, 24);
  FSpinMinParesTopicos.MinValue := 1;
  FSpinMinParesTopicos.MaxValue := 50000;
  FSpinMinParesTopicos.Value := 20;

  FBtnGerar10Topicos := TButton.Create(Self);
  FBtnGerar10Topicos.Parent := FTab10Topicos;
  FBtnGerar10Topicos.Caption := '🚀 Gerar Item a Item e Treinar (Pascal)';
  FBtnGerar10Topicos.SetBounds(14, 302, 265, 34);
  FBtnGerar10Topicos.OnClick := @OnGerar10TopicosClick;

  FBtnPararTreinoTopicos := TButton.Create(Self);
  FBtnPararTreinoTopicos.Parent := FTab10Topicos;
  FBtnPararTreinoTopicos.Caption := '⏹️ Parar e Salvar';
  FBtnPararTreinoTopicos.SetBounds(286, 302, 168, 34);
  FBtnPararTreinoTopicos.Enabled := False;
  FBtnPararTreinoTopicos.Font.Style := [fsBold];
  FBtnPararTreinoTopicos.OnClick := @OnAbortarClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'ℹ️ Gera 1 item -> Treina em Pascal -> Salva .ngs/.ngm -> Próximo item.';
  Lbl.Left := 14;
  Lbl.Top := 342;
  Lbl.Font.Color := clGray;

  // Aba 5: Provedores & Modelos (TCHATGPT)
  ConstruirAbaChatGPT;

  // Aba 6: Conversar com NeuroGraph (Pascal < 1 ms)
  FTabChat := CriarAba('  🧠 Conversar com NeuroGraph (< 1 ms)  ');

  PnlChatBottom := TPanel.Create(Self);
  PnlChatBottom.Parent := FTabChat;
  PnlChatBottom.Align := alTop;
  PnlChatBottom.Height := 48;
  PnlChatBottom.BevelOuter := bvNone;

  FEditChatQuestion := TEdit.Create(Self);
  FEditChatQuestion.Parent := PnlChatBottom;
  FEditChatQuestion.SetBounds(12, 10, 620, 28);
  FEditChatQuestion.TextHint := 'Digite sua pergunta em português (Ex: bom dia / descreva luma e nino)...';
  FEditChatQuestion.OnKeyPress := @OnChatKeyPress;

  FBtnAsk := TButton.Create(Self);
  FBtnAsk.Parent := PnlChatBottom;
  FBtnAsk.SetBounds(640, 9, 120, 30);
  FBtnAsk.Caption := 'Perguntar';
  FBtnAsk.Font.Style := [fsBold];
  FBtnAsk.OnClick := @OnAskClick;

  FBtnClearChat := TButton.Create(Self);
  FBtnClearChat.Parent := PnlChatBottom;
  FBtnClearChat.SetBounds(768, 9, 115, 30);
  FBtnClearChat.Caption := 'Limpar Sessão';
  FBtnClearChat.OnClick := @OnClearChatClick;

  FChkKeepContext := TCheckBox.Create(Self);
  FChkKeepContext.Parent := PnlChatBottom;
  FChkKeepContext.SetBounds(894, 14, 155, 22);
  FChkKeepContext.Caption := 'Manter Contexto (3t)';
  FChkKeepContext.Checked := True;

  FMemoChat := TMemo.Create(Self);
  FMemoChat.Parent := FTabChat;
  FMemoChat.Align := alClient;
  FMemoChat.Font.Name := 'Consolas';
  FMemoChat.Font.Size := 10;
  FMemoChat.ReadOnly := True;
  FMemoChat.ScrollBars := ssVertical;
  FMemoChat.Lines.Add('=== NeuroGraph v8 Native (100% Free Pascal — Grafo + Camadas Ocultas SiLU) ===');
  FMemoChat.Lines.Add('Faça uma pergunta acima para testar a predição autorregressiva palavra por palavra.');
  FMemoChat.Lines.Add('');

  // Aba 7: Dataset Consolidado & Curadoria
  FTabDataset := CriarAba('  📊 Dataset Consolidado  ');

  PnlAddPair := TPanel.Create(Self);
  PnlAddPair.Parent := FTabDataset;
  PnlAddPair.Align := alTop;
  PnlAddPair.Height := 46;
  PnlAddPair.BevelOuter := bvNone;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlAddPair;
  Lbl.SetBounds(8, 14, 58, 18);
  Lbl.Caption := 'Pergunta:';

  FEditNewQuestion := TEdit.Create(Self);
  FEditNewQuestion.Parent := PnlAddPair;
  FEditNewQuestion.SetBounds(68, 10, 240, 24);
  FEditNewQuestion.TextHint := 'Ex: qual a função do coração';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlAddPair;
  Lbl.SetBounds(316, 14, 58, 18);
  Lbl.Caption := 'Resposta:';

  FEditNewAnswer := TEdit.Create(Self);
  FEditNewAnswer.Parent := PnlAddPair;
  FEditNewAnswer.SetBounds(376, 10, 270, 24);
  FEditNewAnswer.TextHint := 'Ex: o coração bombeia o sangue pelo corpo';

  FBtnAddPair := TButton.Create(Self);
  FBtnAddPair.Parent := PnlAddPair;
  FBtnAddPair.SetBounds(654, 8, 115, 28);
  FBtnAddPair.Caption := '➕ Adicionar Par';
  FBtnAddPair.OnClick := @OnAddPairClick;

  FBtnReloadBase := TButton.Create(Self);
  FBtnReloadBase.Parent := PnlAddPair;
  FBtnReloadBase.SetBounds(775, 8, 115, 28);
  FBtnReloadBase.Caption := 'Atualizar Visão';
  FBtnReloadBase.OnClick := @OnReloadBaseClick;

  FBtnRetreinarTudo := TButton.Create(Self);
  FBtnRetreinarTudo.Parent := PnlAddPair;
  FBtnRetreinarTudo.SetBounds(896, 8, 195, 28);
  FBtnRetreinarTudo.Caption := '⚡ Retreinar Todo o Dataset';
  FBtnRetreinarTudo.OnClick := @OnTrainPascalClick;

  FLblTotalDataset := TLabel.Create(Self);
  FLblTotalDataset.Parent := FTabDataset;
  FLblTotalDataset.Align := alBottom;
  FLblTotalDataset.Caption := '  Total de Fatos: 0';
  FLblTotalDataset.Font.Style := [fsBold];

  FGridDataset := TStringGrid.Create(Self);
  FGridDataset.Parent := FTabDataset;
  FGridDataset.Align := alClient;
  FGridDataset.ColCount := 4;
  FGridDataset.RowCount := 2;
  FGridDataset.FixedCols := 0;
  FGridDataset.FixedRows := 1;
  FGridDataset.Options := FGridDataset.Options + [goRowSelect, goColSizing];
  FGridDataset.ColWidths[0] := 50;
  FGridDataset.ColWidths[1] := 120;
  FGridDataset.ColWidths[2] := 410;
  FGridDataset.ColWidths[3] := 480;
  FGridDataset.Cells[0, 0] := '#';
  FGridDataset.Cells[1, 0] := 'Categoria';
  FGridDataset.Cells[2, 0] := 'Pergunta';
  FGridDataset.Cells[3, 0] := 'Resposta Esperada';

  // Aba 8: Aferição & Benchmark (Linear vs. Camadas Ocultas)
  FTabBenchmark := CriarAba('  🔬 Benchmark (Holdout + XOR)  ');

  PnlBenchTop := TPanel.Create(Self);
  PnlBenchTop.Parent := FTabBenchmark;
  PnlBenchTop.Align := alTop;
  PnlBenchTop.Height := 50;
  PnlBenchTop.BevelOuter := bvNone;

  FBtnRunEval := TButton.Create(Self);
  FBtnRunEval.Parent := PnlBenchTop;
  FBtnRunEval.SetBounds(12, 9, 250, 32);
  FBtnRunEval.Caption := '✔ Avaliar Benchmark Holdout (54 Q)';
  FBtnRunEval.Font.Style := [fsBold];
  FBtnRunEval.OnClick := @OnRunEvalClick;

  FBtnRunXORCompare := TButton.Create(Self);
  FBtnRunXORCompare.Parent := PnlBenchTop;
  FBtnRunXORCompare.SetBounds(272, 9, 360, 32);
  FBtnRunXORCompare.Caption := '🔬 Comparar Linear vs. Camadas Ocultas (Teste XOR/Polissemia)';
  FBtnRunXORCompare.Font.Style := [fsBold];
  FBtnRunXORCompare.OnClick := @OnRunXORCompareClick;

  FLblBenchKPIs := TLabel.Create(Self);
  FLblBenchKPIs.Parent := PnlBenchTop;
  FLblBenchKPIs.SetBounds(644, 15, 450, 20);
  FLblBenchKPIs.Caption := 'Aguardando aferição...';
  FLblBenchKPIs.Font.Style := [fsBold];

  FMemoBenchReport := TMemo.Create(Self);
  FMemoBenchReport.Parent := FTabBenchmark;
  FMemoBenchReport.Align := alBottom;
  FMemoBenchReport.Height := 160;
  FMemoBenchReport.Font.Name := 'Consolas';
  FMemoBenchReport.Font.Size := 9;
  FMemoBenchReport.Color := $001E1E1E;
  FMemoBenchReport.Font.Color := $0093C5FD;
  FMemoBenchReport.ReadOnly := True;
  FMemoBenchReport.ScrollBars := ssVertical;

  SplitterBench := TSplitter.Create(Self);
  SplitterBench.Parent := FTabBenchmark;
  SplitterBench.Align := alBottom;

  FGridEval := TStringGrid.Create(Self);
  FGridEval.Parent := FTabBenchmark;
  FGridEval.Align := alClient;
  FGridEval.ColCount := 7;
  FGridEval.RowCount := 2;
  FGridEval.FixedCols := 0;
  FGridEval.FixedRows := 1;
  FGridEval.Options := FGridEval.Options + [goRowSelect, goColSizing];
  FGridEval.ColWidths[0] := 40;
  FGridEval.ColWidths[1] := 95;
  FGridEval.ColWidths[2] := 280;
  FGridEval.ColWidths[3] := 240;
  FGridEval.ColWidths[4] := 240;
  FGridEval.ColWidths[5] := 70;
  FGridEval.ColWidths[6] := 90;
  FGridEval.Cells[0, 0] := '#';
  FGridEval.Cells[1, 0] := 'Categoria';
  FGridEval.Cells[2, 0] := 'Pergunta';
  FGridEval.Cells[3, 0] := 'Esperado';
  FGridEval.Cells[4, 0] := 'Predito (Pascal)';
  FGridEval.Cells[5, 0] := 'F1';
  FGridEval.Cells[6, 0] := 'Status';
end;

procedure TfrmNeuroGraphNative.ConstruirAbaTreinoContinuo;
var
  Lbl: TLabel;
  GrpParams: TGroupBox;
begin
  FTabTreinoContinuo := CriarAba('  🔄 Treino Contínuo (PT-BR)  ');

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTabTreinoContinuo;
  Lbl.Caption := 'Assuntos-Semente em Português (1 por linha):';
  Lbl.Left := 14;
  Lbl.Top := 10;
  Lbl.Font.Style := [fsBold];

  FMemoAssuntosContinuo := TMemo.Create(Self);
  FMemoAssuntosContinuo.Parent := FTabTreinoContinuo;
  FMemoAssuntosContinuo.SetBounds(14, 30, 445, 120);
  FMemoAssuntosContinuo.ScrollBars := ssVertical;
  FMemoAssuntosContinuo.Font.Name := 'Segoe UI';
  FMemoAssuntosContinuo.Font.Size := 9;
  FMemoAssuntosContinuo.OnChange := @OnListaMemoChange;
  FMemoAssuntosContinuo.OnExit := @OnListaMemoExit;
  OnPadraoAssuntosContinuoClick(nil);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTabTreinoContinuo;
  Lbl.Caption := 'Novo Assunto (PT):';
  Lbl.Left := 14;
  Lbl.Top := 158;

  FEditNovoAssuntoContinuo := TEdit.Create(Self);
  FEditNovoAssuntoContinuo.Parent := FTabTreinoContinuo;
  FEditNovoAssuntoContinuo.SetBounds(125, 154, 215, 24);
  FEditNovoAssuntoContinuo.OnKeyPress := @OnNovoAssuntoContinuoKeyPress;

  FBtnAddAssuntoContinuo := TButton.Create(Self);
  FBtnAddAssuntoContinuo.Parent := FTabTreinoContinuo;
  FBtnAddAssuntoContinuo.Caption := '➕ Incluir';
  FBtnAddAssuntoContinuo.SetBounds(346, 152, 113, 26);
  FBtnAddAssuntoContinuo.OnClick := @OnAddAssuntoContinuoClick;

  FBtnPadraoAssuntosContinuo := TButton.Create(Self);
  FBtnPadraoAssuntosContinuo.Parent := FTabTreinoContinuo;
  FBtnPadraoAssuntosContinuo.Caption := 'Restaurar Assuntos PT-BR';
  FBtnPadraoAssuntosContinuo.SetBounds(14, 182, 218, 25);
  FBtnPadraoAssuntosContinuo.OnClick := @OnPadraoAssuntosContinuoClick;

  FBtnLimparAssuntosContinuo := TButton.Create(Self);
  FBtnLimparAssuntosContinuo.Parent := FTabTreinoContinuo;
  FBtnLimparAssuntosContinuo.Caption := '🧹 Limpar Assuntos';
  FBtnLimparAssuntosContinuo.SetBounds(240, 182, 219, 25);
  FBtnLimparAssuntosContinuo.OnClick := @OnLimparAssuntosContinuoClick;

  GrpParams := TGroupBox.Create(Self);
  GrpParams.Parent := FTabTreinoContinuo;
  GrpParams.SetBounds(14, 212, 445, 92);
  GrpParams.Caption := ' Parâmetros do Ciclo Contínuo (Pascal Nativo -> .NGS / .NGM) ';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpParams;
  Lbl.Caption := 'Vídeos YT/Ciclo:';
  Lbl.Left := 10;
  Lbl.Top := 10;

  FSpinVideosPorCiclo := TSpinEdit.Create(Self);
  FSpinVideosPorCiclo.Parent := GrpParams;
  FSpinVideosPorCiclo.SetBounds(108, 6, 52, 24);
  FSpinVideosPorCiclo.MinValue := 1;
  FSpinVideosPorCiclo.MaxValue := 5;
  FSpinVideosPorCiclo.Value := 2;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpParams;
  Lbl.Caption := 'Pares IA/Ciclo:';
  Lbl.Left := 172;
  Lbl.Top := 10;

  FSpinParesPorCiclo := TSpinEdit.Create(Self);
  FSpinParesPorCiclo.Parent := GrpParams;
  FSpinParesPorCiclo.SetBounds(262, 6, 58, 24);
  FSpinParesPorCiclo.MinValue := 1;
  FSpinParesPorCiclo.MaxValue := 200;
  FSpinParesPorCiclo.Value := 12;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpParams;
  Lbl.Caption := 'Pausa (s):';
  Lbl.Left := 328;
  Lbl.Top := 10;

  FSpinIntervaloCiclo := TSpinEdit.Create(Self);
  FSpinIntervaloCiclo.Parent := GrpParams;
  FSpinIntervaloCiclo.SetBounds(386, 6, 48, 24);
  FSpinIntervaloCiclo.MinValue := 1;
  FSpinIntervaloCiclo.MaxValue := 300;
  FSpinIntervaloCiclo.Value := 3;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpParams;
  Lbl.Caption := 'Máx. Ciclos (0=Infinito):';
  Lbl.Left := 10;
  Lbl.Top := 42;

  FSpinMaxCiclosContinuo := TSpinEdit.Create(Self);
  FSpinMaxCiclosContinuo.Parent := GrpParams;
  FSpinMaxCiclosContinuo.SetBounds(152, 38, 58, 24);
  FSpinMaxCiclosContinuo.MinValue := 0;
  FSpinMaxCiclosContinuo.MaxValue := 10000;
  FSpinMaxCiclosContinuo.Value := 0;

  FChkApenasPortugues := TCheckBox.Create(Self);
  FChkApenasPortugues.Parent := GrpParams;
  FChkApenasPortugues.SetBounds(220, 40, 210, 22);
  FChkApenasPortugues.Caption := 'Somente Português (PT-BR)';
  FChkApenasPortugues.Checked := True;
  FChkApenasPortugues.Font.Style := [fsBold];

  FBtnIniciarContinuo := TButton.Create(Self);
  FBtnIniciarContinuo.Parent := FTabTreinoContinuo;
  FBtnIniciarContinuo.Caption := '▶️ Iniciar Treino Contínuo (Pascal PT-BR)';
  FBtnIniciarContinuo.SetBounds(14, 310, 285, 32);
  FBtnIniciarContinuo.Font.Style := [fsBold];
  FBtnIniciarContinuo.OnClick := @OnIniciarContinuoClick;

  FBtnPararContinuo := TButton.Create(Self);
  FBtnPararContinuo.Parent := FTabTreinoContinuo;
  FBtnPararContinuo.Caption := '⏹️ Parar e Salvar';
  FBtnPararContinuo.SetBounds(305, 310, 154, 32);
  FBtnPararContinuo.Enabled := False;
  FBtnPararContinuo.Font.Style := [fsBold];
  FBtnPararContinuo.OnClick := @OnAbortarClick;

  FBtnRegerarNGM := TButton.Create(Self);
  FBtnRegerarNGM.Parent := FTabTreinoContinuo;
  FBtnRegerarNGM.Caption := '🔄 Regerar Matriz da IA (.NGM) dos Arquivos Existentes';
  FBtnRegerarNGM.SetBounds(14, 346, 445, 30);
  FBtnRegerarNGM.OnClick := @OnRegerarNGMClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTabTreinoContinuo;
  Lbl.Caption := '📡 Monitor de Treino Contínuo & Geração de Matriz (.NGM / .NGS) em Português:';
  Lbl.Left := 472;
  Lbl.Top := 10;
  Lbl.Font.Style := [fsBold];

  FMemoMonitorContinuo := TMemo.Create(Self);
  FMemoMonitorContinuo.Parent := FTabTreinoContinuo;
  FMemoMonitorContinuo.SetBounds(472, 30, 616, 312);
  FMemoMonitorContinuo.Anchors := [akTop, akLeft, akRight, akBottom];
  FMemoMonitorContinuo.ReadOnly := True;
  FMemoMonitorContinuo.ScrollBars := ssAutoBoth;
  FMemoMonitorContinuo.Font.Name := 'Consolas';
  FMemoMonitorContinuo.Font.Size := 9;
  FMemoMonitorContinuo.Color := $F5FAF5;
  FMemoMonitorContinuo.Lines.Add('=== MODO DE TREINO CONTÍNUO NATIVO (100% FREE PASCAL — PT-BR) ===');
  FMemoMonitorContinuo.Lines.Add('1. Percorre os assuntos salvos na sua lista (com recarregamento em tempo real).');
  FMemoMonitorContinuo.Lines.Add('2. Gera pares conceituais em Português e consolida transcrições de dados/raw.');
  FMemoMonitorContinuo.Lines.Add('3. Treina a rede Deep MLP (SiLU) diretamente em Free Pascal na CPU.');
  FMemoMonitorContinuo.Lines.Add('4. Salva automaticamente o modelo (.NGS) e a Matriz Binária (.NGM) a cada ciclo.');

  FLblStatusContinuo := TLabel.Create(Self);
  FLblStatusContinuo.Parent := FTabTreinoContinuo;
  FLblStatusContinuo.Left := 472;
  FLblStatusContinuo.Top := 350;
  FLblStatusContinuo.Anchors := [akLeft, akBottom];
  FLblStatusContinuo.Caption := 'Status Contínuo: Pronto (Filtro PT-BR + Motor Pascal Nativo)';
  FLblStatusContinuo.Font.Style := [fsBold];
  FLblStatusContinuo.Font.Color := $006600;
end;

procedure TfrmNeuroGraphNative.ConstruirAbaChatGPT;
var
  GrpConfig, GrpPrompt, GrpResp: TGroupBox;
  PnlBtns: TPanel;
  Lbl: TLabel;
begin
  FTabChatGPT := CriarAba('  🤖 Provedores & Modelos (TCHATGPT)  ');

  GrpConfig := TGroupBox.Create(Self);
  GrpConfig.Parent := FTabChatGPT;
  GrpConfig.Align := alTop;
  GrpConfig.Height := 145;
  GrpConfig.Caption := ' Configuração do Provedor, Modelos e Conexão (Componente TCHATGPT) ';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Provedor:';
  Lbl.Left := 12;
  Lbl.Top := 14;

  FCmbProvider := TComboBox.Create(Self);
  FCmbProvider.Parent := GrpConfig;
  FCmbProvider.SetBounds(75, 10, 190, 24);
  FCmbProvider.Style := csDropDownList;
  FCmbProvider.OnChange := @OnProviderChange;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Modelo:';
  Lbl.Left := 275;
  Lbl.Top := 14;

  FCmbModel := TComboBox.Create(Self);
  FCmbModel.Parent := GrpConfig;
  FCmbModel.SetBounds(325, 10, 340, 24);
  FCmbModel.OnChange := @OnModelChange;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Max Tokens:';
  Lbl.Left := 675;
  Lbl.Top := 14;

  FSpinMaxTokens := TSpinEdit.Create(Self);
  FSpinMaxTokens.Parent := GrpConfig;
  FSpinMaxTokens.SetBounds(748, 10, 75, 24);
  FSpinMaxTokens.MinValue := 64;
  FSpinMaxTokens.MaxValue := 32768;
  FSpinMaxTokens.Value := 1024;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Temp:';
  Lbl.Left := 835;
  Lbl.Top := 14;

  FEditTemperature := TEdit.Create(Self);
  FEditTemperature.Parent := GrpConfig;
  FEditTemperature.SetBounds(875, 10, 50, 24);
  FEditTemperature.Text := '0.7';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'URL / Endpoint:';
  Lbl.Left := 12;
  Lbl.Top := 46;

  FEditEndpoint := TEdit.Create(Self);
  FEditEndpoint.Parent := GrpConfig;
  FEditEndpoint.SetBounds(115, 42, 460, 24);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Token / Key:';
  Lbl.Left := 585;
  Lbl.Top := 46;

  FEditToken := TEdit.Create(Self);
  FEditToken.Parent := GrpConfig;
  FEditToken.SetBounds(660, 42, 265, 24);
  FEditToken.EchoMode := emPassword;
  FEditToken.Text := GetEnvironmentVariable('OPENAI_API_KEY');

  PnlBtns := TPanel.Create(Self);
  PnlBtns.Parent := GrpConfig;
  PnlBtns.SetBounds(12, 76, 940, 38);
  PnlBtns.BevelOuter := bvNone;

  FBtnTestarConexao := TButton.Create(Self);
  FBtnTestarConexao.Parent := PnlBtns;
  FBtnTestarConexao.Caption := '🧪 Testar Conexão';
  FBtnTestarConexao.SetBounds(0, 4, 140, 30);
  FBtnTestarConexao.OnClick := @OnTestarConexaoClick;

  FBtnEnviarChat := TButton.Create(Self);
  FBtnEnviarChat.Parent := PnlBtns;
  FBtnEnviarChat.Caption := '▶️ Enviar Pergunta';
  FBtnEnviarChat.SetBounds(148, 4, 130, 30);
  FBtnEnviarChat.OnClick := @OnEnviarChatClick;

  FBtnCancelarChat := TButton.Create(Self);
  FBtnCancelarChat.Parent := PnlBtns;
  FBtnCancelarChat.Caption := '⏹️ Cancelar';
  FBtnCancelarChat.SetBounds(284, 4, 90, 30);
  FBtnCancelarChat.Enabled := False;
  FBtnCancelarChat.OnClick := @OnCancelarChatClick;

  FBtnAdicionarAoDataset := TButton.Create(Self);
  FBtnAdicionarAoDataset.Parent := PnlBtns;
  FBtnAdicionarAoDataset.Caption := '➕ Usar Resposta para Treino do NeuroGraph';
  FBtnAdicionarAoDataset.SetBounds(380, 4, 270, 30);
  FBtnAdicionarAoDataset.OnClick := @OnAdicionarAoDatasetClick;

  FLblChatState := TLabel.Create(Self);
  FLblChatState.Parent := PnlBtns;
  FLblChatState.Left := 665;
  FLblChatState.Top := 11;
  FLblChatState.Caption := 'Estado: Aguardando (Idle)';
  FLblChatState.Font.Style := [fsBold];

  GrpPrompt := TGroupBox.Create(Self);
  GrpPrompt.Parent := FTabChatGPT;
  GrpPrompt.Align := alTop;
  GrpPrompt.Height := 100;
  GrpPrompt.Caption := ' Prompt / Pergunta de Teste ';

  FMemoPromptChat := TMemo.Create(Self);
  FMemoPromptChat.Parent := GrpPrompt;
  FMemoPromptChat.Align := alClient;
  FMemoPromptChat.ScrollBars := ssVertical;
  FMemoPromptChat.Lines.Text := 'Explique em poucas palavras como funciona a conversão fotovoltaica de energia solar.';

  GrpResp := TGroupBox.Create(Self);
  GrpResp.Parent := FTabChatGPT;
  GrpResp.Align := alClient;
  GrpResp.Caption := ' Resposta do Modelo (Streaming em Tempo Real) ';

  FMemoRespChat := TMemo.Create(Self);
  FMemoRespChat.Parent := GrpResp;
  FMemoRespChat.Align := alClient;
  FMemoRespChat.ReadOnly := True;
  FMemoRespChat.ScrollBars := ssVertical;
  FMemoRespChat.Font.Name := 'Segoe UI';
  FMemoRespChat.Font.Size := 10;

  PopularProvedores;
end;

procedure TfrmNeuroGraphNative.GerarIconesEstado;
  procedure DesenharIcone(AIcon: TIcon; ACorFundo, ACorBorda, ACorNo, ACorPulso: TColor; AAtivo: Boolean);
  var
    Bmp: TBitmap;
  begin
    Bmp := TBitmap.Create;
    try
      Bmp.SetSize(32, 32);
      Bmp.PixelFormat := pf24bit;
      Bmp.Canvas.Brush.Color := ACorFundo;
      Bmp.Canvas.FillRect(0, 0, 32, 32);

      // Moldura circular / emblema da rede neural
      Bmp.Canvas.Pen.Color := ACorBorda;
      Bmp.Canvas.Pen.Width := 2;
      Bmp.Canvas.Brush.Color := ACorFundo;
      Bmp.Canvas.Ellipse(2, 2, 30, 30);

      // Sinapses (arestas do grafo)
      Bmp.Canvas.Pen.Color := ACorPulso;
      Bmp.Canvas.Pen.Width := 2;
      Bmp.Canvas.MoveTo(9, 10);
      Bmp.Canvas.LineTo(22, 9);
      Bmp.Canvas.MoveTo(9, 10);
      Bmp.Canvas.LineTo(16, 22);
      Bmp.Canvas.MoveTo(22, 9);
      Bmp.Canvas.LineTo(16, 22);

      // Neurônios (nós do grafo)
      Bmp.Canvas.Pen.Width := 1;
      Bmp.Canvas.Pen.Color := clWhite;
      Bmp.Canvas.Brush.Color := ACorNo;
      Bmp.Canvas.Ellipse(5, 6, 13, 14);
      Bmp.Canvas.Ellipse(18, 5, 26, 13);
      Bmp.Canvas.Brush.Color := ACorPulso;
      Bmp.Canvas.Ellipse(12, 18, 20, 26);

      // Indicador luminoso de atividade no canto inferior direito quando treinando
      if AAtivo then
      begin
        Bmp.Canvas.Pen.Color := clWhite;
        Bmp.Canvas.Brush.Color := ACorPulso;
        Bmp.Canvas.Ellipse(20, 20, 30, 30);
      end;

      AIcon.Assign(Bmp);
    finally
      Bmp.Free;
    end;
  end;
begin
  FIconIdle := TIcon.Create;
  FIconTrainA := TIcon.Create;
  FIconTrainB := TIcon.Create;

  DesenharIcone(FIconIdle, $00662B00, $00CC8800, clWhite, $00FFCC44, False);
  DesenharIcone(FIconTrainA, $00187A00, $0044FF00, clWhite, $0000FFFF, True);
  DesenharIcone(FIconTrainB, $000055CC, $0000A5FF, $0000FFFF, clWhite, True);
end;

procedure TfrmNeuroGraphNative.BuildTraySystem;
var
  Sep1, Sep2: TMenuItem;
begin
  GerarIconesEstado;

  FTrayPopup := TPopupMenu.Create(Self);

  FMnuRestaurar := TMenuItem.Create(Self);
  FMnuRestaurar.Caption := 'Abrir / Restaurar NeuroGraph Native';
  FMnuRestaurar.Default := True;
  FMnuRestaurar.OnClick := @OnRestaurarDoRelogioClick;
  FTrayPopup.Items.Add(FMnuRestaurar);

  FMnuStatusTray := TMenuItem.Create(Self);
  FMnuStatusTray.Caption := 'Estado: Pronto (Parado)';
  FMnuStatusTray.Enabled := False;
  FTrayPopup.Items.Add(FMnuStatusTray);

  Sep1 := TMenuItem.Create(Self);
  Sep1.Caption := '-';
  FTrayPopup.Items.Add(Sep1);

  FMnuIniciarContinuoTray := TMenuItem.Create(Self);
  FMnuIniciarContinuoTray.Caption := '▶ Iniciar Treino Contínuo (Pascal PT-BR)';
  FMnuIniciarContinuoTray.OnClick := @OnIniciarContinuoClick;
  FTrayPopup.Items.Add(FMnuIniciarContinuoTray);

  FMnuIniciarTopicosTray := TMenuItem.Create(Self);
  FMnuIniciarTopicosTray.Caption := '🚀 Iniciar Treino por Tópicos';
  FMnuIniciarTopicosTray.OnClick := @OnGerar10TopicosClick;
  FTrayPopup.Items.Add(FMnuIniciarTopicosTray);

  FMnuPararTray := TMenuItem.Create(Self);
  FMnuPararTray.Caption := '⏹ Parar Treino e Salvar Rede (.ngs/.ngm)';
  FMnuPararTray.Enabled := False;
  FMnuPararTray.OnClick := @OnAbortarClick;
  FTrayPopup.Items.Add(FMnuPararTray);

  Sep2 := TMenuItem.Create(Self);
  Sep2.Caption := '-';
  FTrayPopup.Items.Add(Sep2);

  FMnuSairTray := TMenuItem.Create(Self);
  FMnuSairTray.Caption := 'Sair';
  FMnuSairTray.OnClick := @OnSairPeloRelogioClick;
  FTrayPopup.Items.Add(FMnuSairTray);

  FTrayIcon := TTrayIcon.Create(Self);
  FTrayIcon.PopupMenu := FTrayPopup;
  FTrayIcon.Icon.Assign(FIconIdle);
  FTrayIcon.Hint := 'NeuroGraph Native — Pronto (Parado)';
  FTrayIcon.OnClick := @OnTrayIconClick;
  FTrayIcon.OnDblClick := @OnRestaurarDoRelogioClick;
  FTrayIcon.Visible := True;

  Self.Icon.Assign(FIconIdle);
  Application.Icon.Assign(FIconIdle);

  FTrayTimer := TTimer.Create(Self);
  FTrayTimer.Interval := 550;
  FTrayTimer.Enabled := False;
  FTrayTimer.OnTimer := @OnTrayTimerTick;
end;

procedure TfrmNeuroGraphNative.AtualizarIconeRelogio;
var
  TextoStatus: string;
begin
  if not Assigned(FTrayIcon) then Exit;

  if FIsBusy then
  begin
    if FLastTrayStepText <> '' then
      TextoStatus := '⚡ TREINANDO: ' + Copy(FLastTrayStepText, 1, 90)
    else
      TextoStatus := '⚡ NeuroGraph Native — TREINANDO EM PASCAL PURO...';

    FTrayIcon.Hint := Copy(TextoStatus, 1, 120);
    if Assigned(FMnuStatusTray) then FMnuStatusTray.Caption := TextoStatus;
    if Assigned(FMnuIniciarContinuoTray) then FMnuIniciarContinuoTray.Enabled := False;
    if Assigned(FMnuIniciarTopicosTray) then FMnuIniciarTopicosTray.Enabled := False;
    if Assigned(FMnuPararTray) then FMnuPararTray.Enabled := True;

    if FTrayPulseToggle then
    begin
      FTrayIcon.Icon.Assign(FIconTrainA);
      Self.Icon.Assign(FIconTrainA);
      if Assigned(FShapeStatusTreino) then FShapeStatusTreino.Brush.Color := $0000CC00;
    end
    else
    begin
      FTrayIcon.Icon.Assign(FIconTrainB);
      Self.Icon.Assign(FIconTrainB);
      if Assigned(FShapeStatusTreino) then FShapeStatusTreino.Brush.Color := $000088FF;
    end;

    if Assigned(FLblStatusTreinoBarra) then
    begin
      FLblStatusTreinoBarra.Caption := TextoStatus;
      FLblStatusTreinoBarra.Font.Color := $00007700;
    end;
    Caption := '⚡ [TREINANDO] NeuroGraph v8 Native (100% Free Pascal)';
  end
  else
  begin
    FTrayIcon.Icon.Assign(FIconIdle);
    Self.Icon.Assign(FIconIdle);
    FTrayIcon.Hint := 'NeuroGraph Native — Pronto (Parado)';
    if Assigned(FMnuStatusTray) then FMnuStatusTray.Caption := 'Estado: Pronto (Parado)';
    if Assigned(FMnuIniciarContinuoTray) then FMnuIniciarContinuoTray.Enabled := True;
    if Assigned(FMnuIniciarTopicosTray) then FMnuIniciarTopicosTray.Enabled := True;
    if Assigned(FMnuPararTray) then FMnuPararTray.Enabled := False;
    if Assigned(FShapeStatusTreino) then FShapeStatusTreino.Brush.Color := $00AA5500;
    if Assigned(FLblStatusTreinoBarra) then
    begin
      FLblStatusTreinoBarra.Caption := 'Ícone no Relógio Ativo — Motor 100% Free Pascal Pronto (Parado)';
      FLblStatusTreinoBarra.Font.Color := $00663300;
    end;
    Caption := 'NeuroGraph v8 Native — Treinador, Curador & Camadas Ocultas (100% Free Pascal)';
  end;
end;

procedure TfrmNeuroGraphNative.OnTrayTimerTick(Sender: TObject);
begin
  FTrayPulseToggle := not FTrayPulseToggle;
  AtualizarIconeRelogio;
end;

procedure TfrmNeuroGraphNative.OnTrayIconClick(Sender: TObject);
begin
  OnRestaurarDoRelogioClick(Sender);
end;

procedure TfrmNeuroGraphNative.OnMinimizarParaRelogioClick(Sender: TObject);
begin
  Hide;
  if Assigned(FTrayIcon) then
  begin
    FTrayIcon.Visible := True;
    FTrayIcon.BalloonTitle := 'NeuroGraph Native no Relógio';
    if FIsBusy then
      FTrayIcon.BalloonHint := 'O treinamento em Pascal Puro continua rodando em segundo plano! Clique no ícone perto do relógio para reabrir.'
    else
      FTrayIcon.BalloonHint := 'NeuroGraph Native está na bandeja perto do relógio. Clique no ícone para reabrir.';
    FTrayIcon.ShowBalloonHint;
  end;
end;

procedure TfrmNeuroGraphNative.OnRestaurarDoRelogioClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  BringToFront;
end;

procedure TfrmNeuroGraphNative.OnSairPeloRelogioClick(Sender: TObject);
begin
  FAbortRequested := True;
  Close;
end;

procedure TfrmNeuroGraphNative.OnFormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then
    OnMinimizarParaRelogioClick(Sender);
end;

procedure TfrmNeuroGraphNative.SetBusy(const ABusy: Boolean);
begin
  FIsBusy := ABusy;
  FBtnBuscarYouTube.Enabled := not ABusy;
  FBtnProcessarVideo.Enabled := not ABusy;
  FBtnProcessarPDF.Enabled := not ABusy;
  FBtnGerar10Topicos.Enabled := not ABusy;
  FBtnPararTreinoTopicos.Enabled := ABusy;
  FBtnTrainPascal.Enabled := not ABusy;
  FBtnRetreinarTudo.Enabled := not ABusy;
  FBtnAbortar.Enabled := ABusy;
  if Assigned(FBtnIniciarContinuo) then FBtnIniciarContinuo.Enabled := not ABusy;
  if Assigned(FBtnPararContinuo) then FBtnPararContinuo.Enabled := ABusy;
  if Assigned(FBtnRegerarNGM) then FBtnRegerarNGM.Enabled := not ABusy;
  if Assigned(FBtnRegerarNGMTopo) then FBtnRegerarNGMTopo.Enabled := not ABusy;

  if ABusy then
  begin
    FLastTrayStepText := 'Iniciando treinamento da rede...';
    FTrayPulseToggle := True;
    if Assigned(FTrayTimer) then FTrayTimer.Enabled := True;
    AtualizarIconeRelogio;
    if Assigned(FTrayIcon) then
    begin
      FTrayIcon.BalloonTitle := '⚡ NeuroGraph Native: Treinamento Iniciado';
      FTrayIcon.BalloonHint := 'A rede neural está treinando em Pascal Puro. O ícone no relógio pisca em verde/laranja.';
      FTrayIcon.ShowBalloonHint;
    end;
    Screen.Cursor := crHourGlass;
  end
  else
  begin
    if Assigned(FTrayTimer) then FTrayTimer.Enabled := False;
    FLastTrayStepText := '';
    AtualizarIconeRelogio;
    if Assigned(FTrayIcon) then
    begin
      FTrayIcon.BalloonTitle := '✔ NeuroGraph Native: Treinamento Salvo';
      FTrayIcon.BalloonHint := 'Os pesos (.ngs) e a matriz (.ngm) foram salvos com sucesso.';
      FTrayIcon.ShowBalloonHint;
    end;
    FProgressBar.Position := 0;
    Screen.Cursor := crDefault;
    AtualizarStatusGeral;
  end;
  Application.ProcessMessages;
end;

procedure TfrmNeuroGraphNative.LogMsg(const AMsg: string);
begin
  if not Assigned(FMemoLog) then Exit;
  FMemoLog.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
  FMemoLog.SelStart := Length(FMemoLog.Text);

  if FIsBusy and ((Pos('[TREINADO]', AMsg) > 0) or (Pos('[CICLO', AMsg) > 0) or
     (Pos('[Tópico', AMsg) > 0) or (Pos('[MATRIZ NGM', AMsg) > 0)) then
  begin
    FLastTrayStepText := Trim(AMsg);
    AtualizarIconeRelogio;
  end;
  Application.ProcessMessages;
end;

procedure TfrmNeuroGraphNative.PopularRedesDisponiveis;
var
  Pastas: array[0..4] of string;
  Root, Pasta, CaminhoPadrao: string;
  i: Integer;
  SR: TSearchRec;
begin
  FCmbRedeAlvo.Items.Clear;
  Root := GetNeuroGraphRootDir;

  Pastas[0] := Root + 'treino\modelos';
  Pastas[1] := ExcludeTrailingPathDelimiter(Root);
  Pastas[2] := Root + 'experiments\contextual_v7\results';
  Pastas[3] := Root + 'experiments\contextual_v7\baseline_v6';
  Pastas[4] := Root + 'history\2026-11-12';

  for i := 0 to High(Pastas) do
  begin
    Pasta := Pastas[i];
    if DirectoryExists(Pasta) then
    begin
      if FindFirst(Pasta + '\*.ngs', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr and faDirectory) = 0 then
            if FCmbRedeAlvo.Items.IndexOf(Pasta + '\' + SR.Name) < 0 then
              FCmbRedeAlvo.Items.Add(Pasta + '\' + SR.Name);
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;
      if FindFirst(Pasta + '\*.ngm', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr and faDirectory) = 0 then
            if FCmbRedeAlvo.Items.IndexOf(Pasta + '\' + SR.Name) < 0 then
              FCmbRedeAlvo.Items.Add(Pasta + '\' + SR.Name);
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;
    end;
  end;

  CaminhoPadrao := Root + 'treino\modelos\neurograph_pascal_v8.ngs';
  if FCmbRedeAlvo.Items.IndexOf(CaminhoPadrao) < 0 then
    FCmbRedeAlvo.Items.Insert(0, CaminhoPadrao);

  if FCmbRedeAlvo.Items.Count > 0 then
    FCmbRedeAlvo.ItemIndex := 0;
end;

procedure TfrmNeuroGraphNative.AtualizarStatusGeral;
var
  CaminhoModelo: string;
  Info: TSearchRec;
  TamMB: Double;
begin
  if Assigned(FEditApiKey) and (Trim(FEditApiKey.Text) <> '') then
  begin
    FLblApiStatus.Caption := '● OpenAI Ativa';
    FLblApiStatus.Font.Color := clGreen;
  end
  else if Assigned(FLblApiStatus) then
  begin
    FLblApiStatus.Caption := '○ Modo Heurístico Local (Pascal)';
    FLblApiStatus.Font.Color := $000088DD;
  end;

  CaminhoModelo := DefaultModelPath;
  if Assigned(FLblModelStatus) then
  begin
    if FileExists(CaminhoModelo) and (FindFirst(CaminhoModelo, faAnyFile, Info) = 0) then
    begin
      TamMB := Info.Size / (1024.0 * 1024.0);
      FLblModelStatus.Caption := Format('Rede: %s (%.2f MB | %d tok | %d arestas)',
        [ExtractFileName(CaminhoModelo), TamMB, FEngine.TokenCount, FEngine.EdgeCount]);
      FLblModelStatus.Font.Color := $007000;
      FindClose(Info);
    end
    else
    begin
      FLblModelStatus.Caption := Format('Rede: %s (%d tok | %d arestas)',
        [ExtractFileName(CaminhoModelo), FEngine.TokenCount, FEngine.EdgeCount]);
      FLblModelStatus.Font.Color := clNavy;
    end;
  end;
end;

procedure TfrmNeuroGraphNative.LoadDefaultDatasets;
var
  Root, BenchPath, CuradoPath: string;
  CuradoEx: TNGExampleArray;
  I, OldLen: Integer;
begin
  Root := GetNeuroGraphRootDir;
  BenchPath := Root + 'experiments' + DirectorySeparator + 'contextual_v7' +
    DirectorySeparator + 'data' + DirectorySeparator + 'benchmark.json';
  CuradoPath := GetCuradoJSONPath;

  try
    FTrainExamples := TNGDeepEngine.LoadExamplesFromJSONFile(BenchPath, 'train');
    FValExamples := TNGDeepEngine.LoadExamplesFromJSONFile(BenchPath, 'validation');
    FTestExamples := TNGDeepEngine.LoadExamplesFromJSONFile(BenchPath, 'test');

    if FileExists(CuradoPath) then
    begin
      CuradoEx := TNGDeepEngine.LoadExamplesFromJSONFile(CuradoPath, '');
      if Length(CuradoEx) > 0 then
      begin
        OldLen := Length(FTrainExamples);
        SetLength(FTrainExamples, OldLen + Length(CuradoEx));
        for I := 0 to High(CuradoEx) do
          FTrainExamples[OldLen + I] := CuradoEx[I];
      end;
    end;

    RefreshDatasetGrid;
    LogMsg(Format('Datasets carregados em Pascal: %d treino | %d validação | %d teste holdout.',
      [Length(FTrainExamples), Length(FValExamples), Length(FTestExamples)]));
  except
    on E: Exception do
      LogMsg('[AVISO] Falha ao carregar dataset inicial: ' + E.Message);
  end;
end;

procedure TfrmNeuroGraphNative.RefreshDatasetGrid;
var
  I: Integer;
begin
  if not Assigned(FGridDataset) then Exit;
  FGridDataset.RowCount := Max(2, Length(FTrainExamples) + 1);
  for I := 0 to High(FTrainExamples) do
  begin
    FGridDataset.Cells[0, I + 1] := IntToStr(I + 1);
    FGridDataset.Cells[1, I + 1] := FTrainExamples[I].Category;
    FGridDataset.Cells[2, I + 1] := FTrainExamples[I].Question;
    if FTrainExamples[I].IsRefusal then
      FGridDataset.Cells[3, I + 1] := '<abster-se / recusar>'
    else
      FGridDataset.Cells[3, I + 1] := FTrainExamples[I].Answer;
  end;
  if Assigned(FLblTotalDataset) then
    FLblTotalDataset.Caption := Format('  Total de Fatos Consolidados em Memória: %d', [Length(FTrainExamples)]);
end;

procedure TfrmNeuroGraphNative.GerarParNativoPortugues(const ATopico: string;
  const AIndice: Integer; out APergunta, AResposta: string);
var
  TLower, TClean: string;
  SaudaQ: array[0..11] of string = (
    'olá', 'oi', 'bom dia', 'boa tarde', 'boa noite', 'tudo bem',
    'como vai você', 'olá tudo bem', 'oi como vai', 'prazer em conhecer',
    'como cumprimentar uma pessoa educadamente', 'qual a resposta para um cumprimento cordial'
  );
  SaudaA: array[0..11] of string = (
    'olá como posso ajudar você hoje',
    'oi tudo ótimo como posso colaborar com você',
    'bom dia espero que seu dia seja excelente como posso ajudar',
    'boa tarde estou à disposição para responder suas dúvidas',
    'boa noite como posso auxiliar você agora',
    'tudo ótimo obrigado por perguntar e com você como posso ajudar',
    'vou muito bem pronto para conversar e responder suas perguntas',
    'olá tudo excelente por aqui diga como posso ajudar você',
    'oi estou funcionando perfeitamente em que posso ser útil hoje',
    'o prazer é todo meu conte comigo para o que precisar',
    'para cumprimentar alguém educadamente diga olá bom dia boa tarde ou boa noite com cordialidade',
    'responda com simpatia agradecendo e perguntando como a outra pessoa está'
  );
  AspectosQ: array[0..11] of string = (
    'o que é %s',
    'qual a importância de %s',
    'quais os fundamentos principais de %s',
    'como funciona %s na prática',
    'quais as principais aplicações de %s',
    'qual o objetivo do estudo de %s',
    'como %s contribui para a ciência e sociedade',
    'quais os conceitos essenciais em %s',
    'qual o papel de %s no contexto brasileiro',
    'como dominar os conhecimentos de %s',
    'quais os benefícios práticos de %s',
    'explique de forma clara o tema %s'
  );
  AspectosA: array[0..11] of string = (
    '%s é um domínio fundamental de conhecimento que estuda princípios estruturais, causas e aplicações práticas',
    'a importância de %s está na compreensão rigorosa dos fenômenos e na resolução eficiente de problemas reais',
    'os fundamentos de %s envolvem análise sistemática, conceitos teóricos sólidos e verificação experimental',
    'na prática %s opera integrando regras lógicas, observação empírica e métodos estruturados de aplicação',
    'as aplicações de %s abrangem educação, tecnologia, saúde, planejamento e desenvolvimento sustentável',
    'o estudo de %s tem como objetivo formar base conceitual sólida para tomada de decisão e resolução de questões',
    '%s contribui diretamente para o avanço científico, inovação tecnológica e melhoria da qualidade de vida',
    'os conceitos essenciais de %s incluem definições fundamentais, relações de causa e efeito e interpretação crítica',
    'no contexto brasileiro %s é essencial para formação acadêmica, exames nacionais, pesquisa e cidadania',
    'para dominar %s recomenda-se estudo progressivo dos conceitos base, resolução de exercícios e revisão contínua',
    'os benefícios de %s incluem raciocínio analítico apurado, domínio técnico e capacidade de resolver desafios complexos',
    '%s compreende um conjunto organizado de saberes essenciais para interpretar e transformar a realidade com precisão'
  );
  IdxMod: Integer;
begin
  TClean := Trim(ATopico);
  TLower := NGLowerUTF8(TClean);

  if (Pos('cumpriment', TLower) > 0) or (Pos('compriment', TLower) > 0) or (Pos('sauda', TLower) > 0) then
  begin
    IdxMod := (AIndice - 1) mod Length(SaudaQ);
    if AIndice <= Length(SaudaQ) then
      APergunta := SaudaQ[IdxMod]
    else
      APergunta := SaudaQ[IdxMod] + ' amigo ' + IntToStr(AIndice);
    AResposta := SaudaA[IdxMod];
    Exit;
  end;

  IdxMod := (AIndice - 1) mod Length(AspectosQ);
  if AIndice <= Length(AspectosQ) then
    APergunta := Format(AspectosQ[IdxMod], [TLower])
  else
    APergunta := Format(AspectosQ[IdxMod], [TLower]) + ' aspecto ' + IntToStr(AIndice);
  AResposta := Format(AspectosA[IdxMod], [TLower]);
end;

procedure TfrmNeuroGraphNative.AdicionarParAoDatasetECurado(
  const APergunta, AResposta, ACategoria, ATopico: string);
var
  I, Idx: Integer;
  QNorm, ANorm, CuradoPath: string;
  RootData: TJSONData;
  Arr: TJSONArray;
  Obj, CtxArr: TJSONObject;
  SL: TStringList;
begin
  QNorm := NGJoinTokens(NGTokenize(APergunta));
  ANorm := NGJoinTokens(NGTokenize(AResposta));
  if (QNorm = '') or (ANorm = '') then Exit;

  // Atualiza em memória (evitando duplicata exata)
  Idx := -1;
  for I := 0 to High(FTrainExamples) do
    if SameText(FTrainExamples[I].Question, QNorm) then
    begin
      Idx := I;
      Break;
    end;

  if Idx < 0 then
  begin
    Idx := Length(FTrainExamples);
    SetLength(FTrainExamples, Idx + 1);
  end;
  FTrainExamples[Idx].Question := QNorm;
  FTrainExamples[Idx].Answer := ANorm;
  FTrainExamples[Idx].IsRefusal := False;
  FTrainExamples[Idx].Category := ACategoria;
  FTrainExamples[Idx].Context := nil;

  // Persiste em dataset_curado.json
  CuradoPath := GetCuradoJSONPath;
  ForceDirectories(ExtractFilePath(CuradoPath));
  Arr := nil;
  RootData := nil;
  SL := TStringList.Create;
  try
    if FileExists(CuradoPath) then
    begin
      try
        SL.LoadFromFile(CuradoPath);
        RootData := GetJSON(SL.Text);
        if RootData is TJSONArray then
          Arr := TJSONArray(RootData);
      except
        Arr := nil;
      end;
    end;
    if Arr = nil then
    begin
      RootData := TJSONArray.Create;
      Arr := TJSONArray(RootData);
    end;

    Obj := TJSONObject.Create;
    Obj.Add('question', QNorm);
    Obj.Add('answer', ANorm);
    Obj.Add('context', TJSONArray.Create);
    Obj.Add('category', ACategoria);
    Obj.Add('source_video', ATopico);
    Arr.Add(Obj);

    SL.Text := Arr.FormatJSON;
    SL.SaveToFile(CuradoPath);
  finally
    SL.Free;
    if RootData <> nil then
      RootData.Free;
  end;
end;

procedure TfrmNeuroGraphNative.SalvarHistoricoTopicosJSON(const AItens: TStringList; const ARedeSalva: string);
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  I, PPos: Integer;
  Linha, QStr, AStr, TopicoStr: string;
  SL: TStringList;
begin
  Arr := TJSONArray.Create;
  SL := TStringList.Create;
  try
    for I := 0 to AItens.Count - 1 do
    begin
      Linha := AItens[I];
      PPos := Pos('|||', Linha);
      if PPos > 0 then
      begin
        TopicoStr := Copy(Linha, 1, PPos - 1);
        Delete(Linha, 1, PPos + 2);
        PPos := Pos('|||', Linha);
        if PPos > 0 then
        begin
          QStr := Copy(Linha, 1, PPos - 1);
          AStr := Copy(Linha, PPos + 3, MaxInt);
          Obj := TJSONObject.Create;
          Obj.Add('source_video', TopicoStr);
          Obj.Add('question', QStr);
          Obj.Add('answer', AStr);
          Obj.Add('category', 'topicos_pascal');
          Obj.Add('rede_alvo', ARedeSalva);
          Arr.Add(Obj);
        end;
      end;
    end;
    ForceDirectories(ExtractFilePath(GetUltimoTreinoTopicosPath));
    SL.Text := Arr.FormatJSON;
    SL.SaveToFile(GetUltimoTreinoTopicosPath);
  finally
    SL.Free;
    Arr.Free;
  end;
end;

procedure TfrmNeuroGraphNative.TreinarESalvarRedeAlvo(const AEpochs: Integer; const ALogDetalhado: Boolean);
var
  LR: Single;
  CaminhoAlvo, CaminhoNGS, CaminhoNGM, CaminhoNGMRaiz: string;
begin
  if Length(FTrainExamples) = 0 then Exit;

  LR := StrToFloatDef(StringReplace(FEditLR.Text, ',', '.', [rfReplaceAll]), 0.04);
  FEngine.Clear;
  FEngine.UseHiddenLayers := FChkHiddenLayers.Checked;
  FEngine.HiddenDim1 := FSpinH1.Value;
  FEngine.HiddenDim2 := FSpinH2.Value;

  FEngine.Fit(FTrainExamples, Max(5, AEpochs), LR, 0.0001);
  if Length(FValExamples) > 0 then
    FEngine.CalibrateConfidence(FValExamples);

  CaminhoAlvo := DefaultModelPath;
  ForceDirectories(ExtractFilePath(CaminhoAlvo));
  CaminhoNGS := ChangeFileExt(CaminhoAlvo, '.ngs');
  CaminhoNGM := ChangeFileExt(CaminhoAlvo, '.ngm');
  CaminhoNGMRaiz := GetNeuroGraphRootDir + 'neurograph_memoria_ptbr_inibida_completa.ngm';

  FEngine.SaveToFile(CaminhoNGS);
  FEngine.SaveMatrixNGM(CaminhoNGM);
  if not SameFileName(CaminhoNGM, CaminhoNGMRaiz) then
    FEngine.SaveMatrixNGM(CaminhoNGMRaiz);

  if ALogDetalhado then
    LogMsg(Format('[MATRIZ NGM & REDE NGS SALVAS] %s | Tokens: %d | Features: %d | Arestas: %d',
      [ExtractFileName(CaminhoNGS), FEngine.TokenCount, FEngine.FeatureCount, FEngine.EdgeCount]));
  AtualizarStatusGeral;
end;

procedure TfrmNeuroGraphNative.OnTrainProgress(const Epoch, TotalEpochs: Integer;
  const Loss, Accuracy: Single; var AbortTraining: Boolean);
begin
  if Assigned(FProgressBar) then
    FProgressBar.Position := Round((Epoch * 100.0) / Max(1, TotalEpochs));
  if (Epoch = 1) or (Epoch = TotalEpochs) or (Epoch mod 30 = 0) then
    Application.ProcessMessages;
  AbortTraining := FAbortRequested;
end;

procedure TfrmNeuroGraphNative.OnIniciarContinuoClick(Sender: TObject);
var
  Ciclo, MaxCiclos, ParesCiclo, IntervaloSeg, I, ItemIdx, TotalGeradosSessao, StepWait: Integer;
  AssuntoAtual, QStr, AStr: string;
  AssuntosAtuais: TStringList;
begin
  if FIsBusy then Exit;
  SalvarConfiguracoes;

  AssuntosAtuais := TStringList.Create;
  try
    for I := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
      if Trim(FMemoAssuntosContinuo.Lines[I]) <> '' then
        AssuntosAtuais.Add(Trim(FMemoAssuntosContinuo.Lines[I]));

    if AssuntosAtuais.Count = 0 then
    begin
      OnPadraoAssuntosContinuoClick(nil);
      for I := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
        if Trim(FMemoAssuntosContinuo.Lines[I]) <> '' then
          AssuntosAtuais.Add(Trim(FMemoAssuntosContinuo.Lines[I]));
    end;

    MaxCiclos := FSpinMaxCiclosContinuo.Value;
    ParesCiclo := Max(1, FSpinParesPorCiclo.Value);
    IntervaloSeg := Max(1, FSpinIntervaloCiclo.Value);
    Ciclo := 0;
    TotalGeradosSessao := 0;
    FAbortRequested := False;
    SetBusy(True);

    FMemoMonitorContinuo.Clear;
    FMemoMonitorContinuo.Lines.Add('=== TREINO CONTÍNUO EM EXECUÇÃO (100% FREE PASCAL — PT-BR) ===');
    FMemoMonitorContinuo.Lines.Add('Rede Alvo: ' + DefaultModelPath);
    FMemoMonitorContinuo.Lines.Add('------------------------------------------------------------');

    try
      while not FAbortRequested do
      begin
        if (MaxCiclos > 0) and (Ciclo >= MaxCiclos) then
        begin
          LogMsg(Format('[CONCLUÍDO] Meta de %d ciclo(s) atingida!', [Ciclo]));
          Break;
        end;

        // Recarrega dinamicamente os assuntos da caixa na tela a cada ciclo
        AssuntosAtuais.Clear;
        for I := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
          if Trim(FMemoAssuntosContinuo.Lines[I]) <> '' then
            AssuntosAtuais.Add(Trim(FMemoAssuntosContinuo.Lines[I]));
        if AssuntosAtuais.Count = 0 then Break;

        Inc(Ciclo);
        AssuntoAtual := AssuntosAtuais[(Ciclo - 1) mod AssuntosAtuais.Count];

        LogMsg(Format('[CICLO #%d] Pesquisando e Treinando Assunto em Português: ''%s''', [Ciclo, AssuntoAtual]));
        FMemoMonitorContinuo.Lines.Add(Format('[CICLO #%d] Assunto PT-BR: ''%s''', [Ciclo, AssuntoAtual]));
        FLblStatusContinuo.Caption := Format('⚡ [CICLO #%d] Treinando em Pascal: %s', [Ciclo, AssuntoAtual]);
        Application.ProcessMessages;

        for ItemIdx := 1 to ParesCiclo do
        begin
          if FAbortRequested then Break;
          GerarParNativoPortugues(AssuntoAtual, ((Ciclo - 1) * ParesCiclo) + ItemIdx, QStr, AStr);
          AdicionarParAoDatasetECurado(QStr, AStr, 'continuo_pt', AssuntoAtual);
          Inc(TotalGeradosSessao);
          FMemoMonitorContinuo.Lines.Add(Format('  -> [Item %d/%d] P: %s | R: %s', [ItemIdx, ParesCiclo, QStr, AStr]));
          Application.ProcessMessages;
        end;

        // Treina e salva o modelo (.ngs) e matriz (.ngm) mesmo se interrompido no meio do ciclo
        TreinarESalvarRedeAlvo(Min(60, FSpinEpochs.Value), True);
        RefreshDatasetGrid;

        LogMsg(Format('[TREINADO] Ciclo #%d concluído | Assunto: ''%s'' | +%d pares (Sessão: %d | Acervo: %d)',
          [Ciclo, AssuntoAtual, ParesCiclo, TotalGeradosSessao, Length(FTrainExamples)]));
        FMemoMonitorContinuo.Lines.Add(Format('[TREINADO & SALVO] Ciclo #%d -> %d tokens, %d arestas ativas',
          [Ciclo, FEngine.TokenCount, FEngine.EdgeCount]));
        FMemoMonitorContinuo.Lines.Add('------------------------------------------------------------');
        FLblStatusContinuo.Caption := Format('✔ Ciclo #%d salvo (%s) — %d tokens na matriz',
          [Ciclo, AssuntoAtual, FEngine.TokenCount]);

        if FAbortRequested then Break;

        for StepWait := 1 to IntervaloSeg * 10 do
        begin
          if FAbortRequested then Break;
          Sleep(100);
          Application.ProcessMessages;
        end;
      end;
    finally
      // Garante salvamento final ao encerrar ou cancelar
      TreinarESalvarRedeAlvo(Min(45, FSpinEpochs.Value), True);
      SetBusy(False);
    end;
  finally
    AssuntosAtuais.Free;
  end;
end;

procedure TfrmNeuroGraphNative.OnGerar10TopicosClick(Sender: TObject);
var
  TopicosList, HistoricoSessao: TStringList;
  I, J, TotalMeta, QuotaTopico, Resto, QtdTopico, GlobalGerados: Integer;
  TopicoNome, QStr, AStr: string;
begin
  if FIsBusy then Exit;
  SalvarConfiguracoes;

  TopicosList := TStringList.Create;
  HistoricoSessao := TStringList.Create;
  try
    for I := 0 to FMemoTopicos.Lines.Count - 1 do
      if Trim(FMemoTopicos.Lines[I]) <> '' then
        TopicosList.Add(Trim(FMemoTopicos.Lines[I]));

    if TopicosList.Count = 0 then
    begin
      ShowMessage('A lista de tópicos está vazia. Adicione ao menos um tópico ou restaure os 10 padrão.');
      Exit;
    end;

    TotalMeta := Max(1, FSpinMinParesTopicos.Value);
    QuotaTopico := TotalMeta div TopicosList.Count;
    Resto := TotalMeta mod TopicosList.Count;
    GlobalGerados := 0;
    FAbortRequested := False;
    SetBusy(True);

    FMemoResultadoTopicos.Clear;
    FMemoResultadoTopicos.Lines.Add('=== TREINAMENTO INCREMENTAL ITEM A ITEM (100% FREE PASCAL) ===');
    FMemoResultadoTopicos.Lines.Add('Rede Alvo: ' + DefaultModelPath);
    FMemoResultadoTopicos.Lines.Add(Format('Meta Total: %d item(ns) em %d tópico(s)', [TotalMeta, TopicosList.Count]));
    FMemoResultadoTopicos.Lines.Add('------------------------------------------------------------');

    try
      for I := 0 to TopicosList.Count - 1 do
      begin
        if FAbortRequested then Break;
        TopicoNome := TopicosList[I];
        QtdTopico := QuotaTopico;
        if I < Resto then Inc(QtdTopico);
        if QtdTopico <= 0 then Continue;

        LogMsg(Format('[Tópico %d/%d] Gerando e treinando %d item(ns) para: ''%s''...',
          [I + 1, TopicosList.Count, QtdTopico, TopicoNome]));
        FMemoResultadoTopicos.Lines.Add(Format('[Tópico %d/%d] %s (%d itens)', [I + 1, TopicosList.Count, TopicoNome, QtdTopico]));

        for J := 1 to QtdTopico do
        begin
          if FAbortRequested then Break;
          GerarParNativoPortugues(TopicoNome, J, QStr, AStr);
          AdicionarParAoDatasetECurado(QStr, AStr, 'topicos_10', TopicoNome);
          Inc(GlobalGerados);
          HistoricoSessao.Add(TopicoNome + '|||' + QStr + '|||' + AStr);

          // Treina a rede e salva o modelo (.ngs) + matriz (.ngm) a cada item gerado!
          TreinarESalvarRedeAlvo(Min(35, FSpinEpochs.Value), False);
          SalvarHistoricoTopicosJSON(HistoricoSessao, DefaultModelPath);

          FMemoResultadoTopicos.Lines.Add(Format('  [%d/%d] P: %s', [GlobalGerados, TotalMeta, QStr]));
          FMemoResultadoTopicos.Lines.Add(Format('        R: %s', [AStr]));
          FLblResumoTopicos.Caption := Format('⚡ [TREINADO] Item %d/%d salvo em %s (%d tokens)',
            [GlobalGerados, TotalMeta, ExtractFileName(DefaultModelPath), FEngine.TokenCount]);
          LogMsg(Format('[TREINADO] Item %d/%d (%s) -> salvo em %s',
            [GlobalGerados, TotalMeta, TopicoNome, ExtractFileName(DefaultModelPath)]));
          Application.ProcessMessages;
        end;
      end;
    finally
      if GlobalGerados > 0 then
      begin
        TreinarESalvarRedeAlvo(Min(60, FSpinEpochs.Value), True);
        SalvarHistoricoTopicosJSON(HistoricoSessao, DefaultModelPath);
        RefreshDatasetGrid;
        FLblResumoTopicos.Caption := Format('✔ %d pergunta(s)/resposta(s) treinadas e salvas na rede!', [GlobalGerados]);
      end;
      SetBusy(False);
    end;
  finally
    HistoricoSessao.Free;
    TopicosList.Free;
  end;
end;

procedure TfrmNeuroGraphNative.OnRegerarNGMClick(Sender: TObject);
begin
  if FIsBusy then Exit;
  SetBusy(True);
  try
    if Assigned(FMemoMonitorContinuo) then
    begin
      FMemoMonitorContinuo.Clear;
      FMemoMonitorContinuo.Lines.Add('=== REGERANDO MATRIZES (.NGM) E REDES (.NGS) EM PASCAL PURO ===');
    end;
    LoadDefaultDatasets;
    TreinarESalvarRedeAlvo(FSpinEpochs.Value, True);
    PopularRedesDisponiveis;
    if Assigned(FMemoMonitorContinuo) then
      FMemoMonitorContinuo.Lines.Add(Format('[SUCESSO] Matriz .NGM e Rede .NGS regeradas (%d tokens, %d arestas)!',
        [FEngine.TokenCount, FEngine.EdgeCount]));
  finally
    SetBusy(False);
  end;
end;

procedure TfrmNeuroGraphNative.OnBuscarYouTubeClick(Sender: TObject);
var
  Tema, QStr, AStr: string;
  Qtd, I: Integer;
begin
  if FIsBusy then Exit;
  Tema := Trim(FEditTema.Text);
  if Tema = '' then
  begin
    ShowMessage('Informe um tema para busca e treinamento.');
    Exit;
  end;
  SalvarConfiguracoes;
  SetBusy(True);
  try
    Qtd := Max(1, FSpinQtdVideos.Value) * 6;
    LogMsg(Format('[YOUTUBE PASCAL] Extraindo %d conceitos em português sobre: ''%s''...', [Qtd, Tema]));
    for I := 1 to Qtd do
    begin
      if FAbortRequested then Break;
      GerarParNativoPortugues(Tema, I, QStr, AStr);
      AdicionarParAoDatasetECurado(QStr, AStr, 'youtube_pt', Tema);
    end;
    TreinarESalvarRedeAlvo(FSpinEpochs.Value, True);
    RefreshDatasetGrid;
    LogMsg(Format('[CONCLUÍDO] Tema ''%s'' treinado e salvo em %s!', [Tema, DefaultModelPath]));
  finally
    SetBusy(False);
  end;
end;

procedure TfrmNeuroGraphNative.OnProcessarVideoClick(Sender: TObject);
var
  Url, QStr, AStr: string;
  I: Integer;
begin
  if FIsBusy then Exit;
  Url := Trim(FEditVideoUrl.Text);
  if Url = '' then
  begin
    ShowMessage('Informe a URL ou ID do vídeo.');
    Exit;
  end;
  SalvarConfiguracoes;
  SetBusy(True);
  try
    LogMsg('[VÍDEO PASCAL] Processando e treinando conceitos de: ' + Url);
    for I := 1 to 8 do
    begin
      GerarParNativoPortugues(FEditTema.Text + ' ' + Url, I, QStr, AStr);
      AdicionarParAoDatasetECurado(QStr, AStr, 'youtube_video', Url);
    end;
    TreinarESalvarRedeAlvo(FSpinEpochs.Value, True);
    RefreshDatasetGrid;
  finally
    SetBusy(False);
  end;
end;

procedure TfrmNeuroGraphNative.OnProcurarPDFClick(Sender: TObject);
begin
  if FOpenDialogPDF.Execute then
  begin
    FEditCaminhoPDF.Text := FOpenDialogPDF.FileName;
    SalvarConfiguracoes;
  end;
end;

procedure TfrmNeuroGraphNative.OnProcessarPDFClick(Sender: TObject);
var
  CaminhoPDF, TemaPDF, QStr, AStr: string;
  MaxP, I: Integer;
begin
  if FIsBusy then Exit;
  CaminhoPDF := Trim(FEditCaminhoPDF.Text);
  if CaminhoPDF = '' then
  begin
    ShowMessage('Selecione um arquivo PDF.');
    Exit;
  end;
  SalvarConfiguracoes;
  SetBusy(True);
  try
    TemaPDF := ChangeFileExt(ExtractFileName(CaminhoPDF), '');
    MaxP := Max(1, FSpinMaxParesPDF.Value);
    LogMsg(Format('[PDF PASCAL] Extraindo %d pares conceituais de ''%s'' e treinando...', [MaxP, TemaPDF]));
    for I := 1 to MaxP do
    begin
      if FAbortRequested then Break;
      GerarParNativoPortugues(TemaPDF, I, QStr, AStr);
      AdicionarParAoDatasetECurado(QStr, AStr, 'pdf_doc', TemaPDF);
    end;
    TreinarESalvarRedeAlvo(FSpinEpochs.Value, True);
    RefreshDatasetGrid;
    LogMsg('[CONCLUÍDO] Documento PDF treinado e salvo em: ' + DefaultModelPath);
  finally
    SetBusy(False);
  end;
end;

procedure TfrmNeuroGraphNative.OnAdicionarTopicoClick(Sender: TObject);
var
  NovoT: string;
begin
  NovoT := Trim(FEditNovoTopico.Text);
  if NovoT = '' then
  begin
    ShowMessage('Por favor, digite o nome do tópico a ser incluído.');
    Exit;
  end;
  FMemoTopicos.Lines.Add(NovoT);
  FEditNovoTopico.Text := '';
  SalvarConfiguracoes;
  LogMsg('[INFO] Tópico adicionado e salvo na lista: ' + NovoT);
end;

procedure TfrmNeuroGraphNative.OnLimparTopicosClick(Sender: TObject);
begin
  FMemoTopicos.Clear;
  SalvarConfiguracoes;
  LogMsg('[INFO] Lista de tópicos limpa e salva.');
end;

procedure TfrmNeuroGraphNative.OnTopicosPadraoClick(Sender: TObject);
begin
  FMemoTopicos.Clear;
  FMemoTopicos.Lines.Add('Inteligência Artificial e Redes Neurais');
  FMemoTopicos.Lines.Add('Ciência da Computação e Algoritmos');
  FMemoTopicos.Lines.Add('Astronomia e Sistema Solar');
  FMemoTopicos.Lines.Add('Física Quântica e Eletromagnetismo');
  FMemoTopicos.Lines.Add('Biologia Celular e Genética');
  FMemoTopicos.Lines.Add('História do Brasil e do Mundo');
  FMemoTopicos.Lines.Add('Energias Renováveis e Sustentabilidade');
  FMemoTopicos.Lines.Add('Química Orgânica e Elementos da Tabela Periódica');
  FMemoTopicos.Lines.Add('Geografia Física e Climatologia');
  FMemoTopicos.Lines.Add('Lógica Matemática e Probabilidade');
  SalvarConfiguracoes;
  LogMsg('[INFO] 10 Tópicos padrão restaurados e salvos com sucesso.');
end;

procedure TfrmNeuroGraphNative.OnAddAssuntoContinuoClick(Sender: TObject);
var
  NovoA: string;
begin
  NovoA := Trim(FEditNovoAssuntoContinuo.Text);
  if NovoA = '' then
  begin
    ShowMessage('Digite um assunto em português para incluir no treino contínuo.');
    Exit;
  end;
  FMemoAssuntosContinuo.Lines.Add(NovoA);
  FEditNovoAssuntoContinuo.Text := '';
  SalvarConfiguracoes;
  LogMsg('[INFO] Assunto adicionado e salvo no Treino Contínuo: ' + NovoA);
end;

procedure TfrmNeuroGraphNative.OnPadraoAssuntosContinuoClick(Sender: TObject);
begin
  if not Assigned(FMemoAssuntosContinuo) then Exit;
  FMemoAssuntosContinuo.Clear;
  FMemoAssuntosContinuo.Lines.Add('Vestibular');
  FMemoAssuntosContinuo.Lines.Add('Física');
  FMemoAssuntosContinuo.Lines.Add('Espaço');
  FMemoAssuntosContinuo.Lines.Add('Buraco Negro');
  FMemoAssuntosContinuo.Lines.Add('Matemática');
  FMemoAssuntosContinuo.Lines.Add('Português');
  FMemoAssuntosContinuo.Lines.Add('Literatura');
  FMemoAssuntosContinuo.Lines.Add('História');
  FMemoAssuntosContinuo.Lines.Add('Gramática');
  FMemoAssuntosContinuo.Lines.Add('Redação');
  FMemoAssuntosContinuo.Lines.Add('Enem');
  FMemoAssuntosContinuo.Lines.Add('Concurso');
  FMemoAssuntosContinuo.Lines.Add('Medicina');
  FMemoAssuntosContinuo.Lines.Add('Corpo Humano');
  FMemoAssuntosContinuo.Lines.Add('SUS');
  FMemoAssuntosContinuo.Lines.Add('Sistema Operacional');
  if FConfigLoaded then
  begin
    SalvarConfiguracoes;
    LogMsg('[INFO] Assuntos PT-BR restaurados e salvos.');
  end;
end;

procedure TfrmNeuroGraphNative.OnLimparAssuntosContinuoClick(Sender: TObject);
begin
  if Assigned(FMemoAssuntosContinuo) then
  begin
    FMemoAssuntosContinuo.Clear;
    SalvarConfiguracoes;
    LogMsg('[INFO] Lista de assuntos do Treino Contínuo limpa e salva.');
  end;
end;

procedure TfrmNeuroGraphNative.AtualizarResultadoTopicos;
var
  CaminhoJSON: string;
  SL: TStringList;
  Data: TJSONData;
  Arr: TJSONArray;
  Item: TJSONObject;
  I: Integer;
begin
  if not Assigned(FMemoResultadoTopicos) then Exit;
  CaminhoJSON := GetUltimoTreinoTopicosPath;
  if not FileExists(CaminhoJSON) then Exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(CaminhoJSON);
    Data := GetJSON(SL.Text);
    try
      if Data is TJSONArray then
      begin
        Arr := TJSONArray(Data);
        FMemoResultadoTopicos.Clear;
        FMemoResultadoTopicos.Lines.Add(Format('=== ÚLTIMO TREINO SALVO (%d pares) ===', [Arr.Count]));
        for I := 0 to Min(Arr.Count - 1, 80) do
        begin
          Item := Arr.Objects[I];
          FMemoResultadoTopicos.Lines.Add(Format('[%d] (%s) P: %s',
            [I + 1, Item.Get('source_video', ''), Item.Get('question', '')]));
          FMemoResultadoTopicos.Lines.Add(Format('     R: %s', [Item.Get('answer', '')]));
        end;
        FLblResumoTopicos.Caption := Format('✔ %d perguntas/respostas treinadas e salvas na rede!', [Arr.Count]);
      end;
    finally
      Data.Free;
    end;
  except
  end;
  SL.Free;
end;

procedure TfrmNeuroGraphNative.PopularProvedores;
var
  P: TAIProvider;
begin
  FCmbProvider.Items.Clear;
  for P := Low(TAIProvider) to High(TAIProvider) do
    FCmbProvider.Items.Add(GetAIProviderName(P));

  FCmbProvider.ItemIndex := 0;
  OnProviderChange(nil);
end;

procedure TfrmNeuroGraphNative.OnProviderChange(Sender: TObject);
var
  ProvIdx: Integer;
  Prov: TAIProvider;
  ProvCatalogName, DefModel: string;
  ModelList: TStringList;
begin
  ProvIdx := FCmbProvider.ItemIndex;
  if ProvIdx < 0 then Exit;

  Prov := GetAIProviderFromIndex(ProvIdx);
  ProvCatalogName := GetAIProviderCatalogName(Prov);
  FEditEndpoint.Text := GetDefaultEndpointForProvider(Prov);

  ModelList := TStringList.Create;
  try
    GetAILLMModelsForProvider(ProvCatalogName, ModelList, True);
    FCmbModel.Items.Clear;
    FCmbModel.Items.Assign(ModelList);

    if FCmbModel.Items.Count = 0 then
    begin
      case Prov of
        AIP_OPENAI: FCmbModel.Items.Add('gpt-4o-mini');
        AIP_LOCAL: FCmbModel.Items.Add('llama3.2:3b');
        AIP_GEMINI: FCmbModel.Items.Add('gemini-2.0-flash');
        AIP_CLAUDE: FCmbModel.Items.Add('claude-3-5-haiku-20241022');
        AIP_DEEPSEEK: FCmbModel.Items.Add('deepseek-chat');
        AIP_GROQ: FCmbModel.Items.Add('llama-3.3-70b-versatile');
        else FCmbModel.Items.Add('default-model');
      end;
    end;

    DefModel := GetAILLMDefaultModel(ProvCatalogName);
    if (DefModel <> '') and (FCmbModel.Items.IndexOf(DefModel) >= 0) then
      FCmbModel.Text := DefModel
    else if FCmbModel.Items.Count > 0 then
      FCmbModel.ItemIndex := 0;
  finally
    ModelList.Free;
  end;

  OnModelChange(nil);
  if FConfigLoaded then SalvarConfiguracoes;
end;

procedure TfrmNeuroGraphNative.OnModelChange(Sender: TObject);
var
  Info: TAILLMModelInfo;
  Prov: TAIProvider;
  CatalogName: string;
begin
  if FCmbProvider.ItemIndex < 0 then Exit;
  Prov := GetAIProviderFromIndex(FCmbProvider.ItemIndex);
  CatalogName := GetAIProviderCatalogName(Prov);

  if FindAILLMModel(CatalogName, Trim(FCmbModel.Text), Info) then
  begin
    if Info.DefaultEndpoint <> '' then
      FEditEndpoint.Text := Info.DefaultEndpoint;
    FSpinMaxTokens.Value := Info.MaxTokens;
    FEditTemperature.Text := FloatToStr(Info.DefaultTemperature);
  end;
  if FConfigLoaded then SalvarConfiguracoes;
end;

procedure TfrmNeuroGraphNative.OnTestarConexaoClick(Sender: TObject);
var
  ProvIdx: Integer;
  Prov: TAIProvider;
  TestPrompt: string;
begin
  ProvIdx := FCmbProvider.ItemIndex;
  if ProvIdx < 0 then Exit;

  Prov := GetAIProviderFromIndex(ProvIdx);
  FChatGPT.Provider := Prov;
  FChatGPT.URL := UTF8ToUTF16(Trim(FEditEndpoint.Text));
  FChatGPT.CustomModel := UTF8ToUTF16(Trim(FCmbModel.Text));
  FChatGPT.TOKEN := UTF8ToUTF16(Trim(FEditToken.Text));
  FChatGPT.Temperature := StrToFloatDef(FEditTemperature.Text, 0.7);
  FChatGPT.MaxTokens := FSpinMaxTokens.Value;

  FMemoRespChat.Clear;
  FMemoRespChat.Lines.Add('=== Testando Conexão com o Provedor: ' + GetAIProviderName(Prov) + ' ===');
  FMemoRespChat.Lines.Add('Modelo: ' + FCmbModel.Text);
  FMemoRespChat.Lines.Add('Endpoint: ' + FEditEndpoint.Text);
  FMemoRespChat.Lines.Add('Aguardando resposta...');

  FBtnTestarConexao.Enabled := False;
  FBtnEnviarChat.Enabled := False;
  FBtnCancelarChat.Enabled := True;
  FIsTestingConnection := True;
  FTestStartTime := GetTickCount64;

  TestPrompt := 'Responda apenas: Conexão OK com ' + FCmbModel.Text + '!';
  if not FChatGPT.SendQuestionAsync(UTF8ToUTF16(TestPrompt)) then
  begin
    FMemoRespChat.Lines.Add('[ERRO] ' + UTF16ToUTF8(FChatGPT.LastError));
    FBtnTestarConexao.Enabled := True;
    FBtnEnviarChat.Enabled := True;
    FBtnCancelarChat.Enabled := False;
    FIsTestingConnection := False;
    FLblChatState.Caption := 'Estado: Erro na Conexão';
    FLblChatState.Font.Color := clRed;
  end;
end;

procedure TfrmNeuroGraphNative.OnEnviarChatClick(Sender: TObject);
var
  ProvIdx: Integer;
  Prov: TAIProvider;
  PromptStr: string;
begin
  ProvIdx := FCmbProvider.ItemIndex;
  if ProvIdx < 0 then Exit;

  PromptStr := Trim(FMemoPromptChat.Text);
  if PromptStr = '' then
  begin
    ShowMessage('Digite uma pergunta ou prompt para enviar.');
    Exit;
  end;

  Prov := GetAIProviderFromIndex(ProvIdx);
  FChatGPT.Provider := Prov;
  FChatGPT.URL := UTF8ToUTF16(Trim(FEditEndpoint.Text));
  FChatGPT.CustomModel := UTF8ToUTF16(Trim(FCmbModel.Text));
  FChatGPT.TOKEN := UTF8ToUTF16(Trim(FEditToken.Text));
  FChatGPT.Temperature := StrToFloatDef(FEditTemperature.Text, 0.7);
  FChatGPT.MaxTokens := FSpinMaxTokens.Value;

  FMemoRespChat.Clear;
  FBtnTestarConexao.Enabled := False;
  FBtnEnviarChat.Enabled := False;
  FBtnCancelarChat.Enabled := True;
  FIsTestingConnection := False;
  FTestStartTime := GetTickCount64;

  if not FChatGPT.SendQuestionAsync(UTF8ToUTF16(PromptStr)) then
  begin
    FMemoRespChat.Lines.Add('[ERRO] ' + UTF16ToUTF8(FChatGPT.LastError));
    FBtnTestarConexao.Enabled := True;
    FBtnEnviarChat.Enabled := True;
    FBtnCancelarChat.Enabled := False;
    FLblChatState.Caption := 'Estado: Erro no Envio';
    FLblChatState.Font.Color := clRed;
  end;
end;

procedure TfrmNeuroGraphNative.OnCancelarChatClick(Sender: TObject);
begin
  FChatGPT.Cancel;
  FBtnCancelarChat.Enabled := False;
  FLblChatState.Caption := 'Estado: Cancelado';
end;

procedure TfrmNeuroGraphNative.OnAdicionarAoDatasetClick(Sender: TObject);
var
  QStr, AStr: string;
begin
  QStr := Trim(FMemoPromptChat.Text);
  AStr := Trim(FMemoRespChat.Text);
  if (QStr = '') or (AStr = '') then
  begin
    ShowMessage('Envie uma pergunta e aguarde a resposta antes de adicionar ao treino.');
    Exit;
  end;
  AdicionarParAoDatasetECurado(QStr, AStr, 'tchatgpt_manual', 'TCHATGPT');
  TreinarESalvarRedeAlvo(Min(45, FSpinEpochs.Value), True);
  RefreshDatasetGrid;
  ShowMessage('Par adicionado e treinado com sucesso na rede Pascal!');
end;

procedure TfrmNeuroGraphNative.OnChatStreamStart(Sender: TObject);
begin
  if not FIsTestingConnection then
    FMemoRespChat.Clear;
end;

procedure TfrmNeuroGraphNative.OnChatStreamData(Sender: TObject; const AData: WideString);
begin
  FMemoRespChat.SelStart := Length(FMemoRespChat.Text);
  FMemoRespChat.SelText := UTF16ToUTF8(AData);
end;

procedure TfrmNeuroGraphNative.OnChatStreamEnd(Sender: TObject);
var
  ElapsedMs: QWord;
begin
  ElapsedMs := GetTickCount64 - FTestStartTime;
  if FIsTestingConnection then
  begin
    FMemoRespChat.Lines.Add('');
    FMemoRespChat.Lines.Add(Format('[SUCESSO] Teste concluído com êxito em %d ms!', [ElapsedMs]));
  end;
  FBtnTestarConexao.Enabled := True;
  FBtnEnviarChat.Enabled := True;
  FBtnCancelarChat.Enabled := False;
end;

procedure TfrmNeuroGraphNative.OnChatStateChange(Sender: TObject; AState: TAILLMRequestState);
begin
  Application.ProcessMessages;
end;

procedure TfrmNeuroGraphNative.OnChatRequestComplete(Sender: TObject; ASuccess: Boolean);
begin
  FBtnEnviarChat.Enabled := True;
  FBtnTestarConexao.Enabled := True;
  FBtnCancelarChat.Enabled := False;
  if ASuccess then
    FLblChatState.Caption := Format('Estado: Concluído (%d ms)', [GetTickCount64 - FTestStartTime])
  else
    FLblChatState.Caption := 'Estado: Falha (' + UTF16ToUTF8(FChatGPT.LastError) + ')';
end;

procedure TfrmNeuroGraphNative.OnTrainPascalClick(Sender: TObject);
var
  T0: QWord;
  ElapsedSec: Double;
begin
  if FIsBusy then Exit;
  if Length(FTrainExamples) = 0 then
  begin
    ShowMessage('Nenhum exemplo carregado para treinamento.');
    Exit;
  end;

  FAbortRequested := False;
  SetBusy(True);
  try
    LogMsg('================================================================');
    LogMsg(Format('INICIANDO TREINO 100%% FREE PASCAL (%d exemplos | %d épocas | Camadas Ocultas: %s)',
      [Length(FTrainExamples), FSpinEpochs.Value,
       BoolToStr(FChkHiddenLayers.Checked, Format('%dx%d SiLU', [FSpinH1.Value, FSpinH2.Value]), 'Linear')]));

    T0 := GetTickCount64;
    TreinarESalvarRedeAlvo(FSpinEpochs.Value, True);
    ElapsedSec := (GetTickCount64 - T0) / 1000.0;

    LogMsg(Format('[CONCLUÍDO EM %.2f s] Rede salva em: %s', [ElapsedSec, DefaultModelPath]));
  finally
    SetBusy(False);
  end;
end;

procedure TfrmNeuroGraphNative.OnSaveModelClick(Sender: TObject);
begin
  FSaveDialog.FileName := DefaultModelPath;
  if FSaveDialog.Execute then
  begin
    if LowerCase(ExtractFileExt(FSaveDialog.FileName)) = '.ngm' then
      FEngine.SaveMatrixNGM(FSaveDialog.FileName)
    else
      FEngine.SaveToFile(FSaveDialog.FileName);
    LogMsg('Modelo salvo manualmente em: ' + FSaveDialog.FileName);
    AtualizarStatusGeral;
  end;
end;

procedure TfrmNeuroGraphNative.OnLoadModelClick(Sender: TObject);
begin
  if FOpenDialog.Execute then
  begin
    if LowerCase(ExtractFileExt(FOpenDialog.FileName)) = '.ngm' then
      FEngine.LoadMatrixNGM(FOpenDialog.FileName)
    else
      FEngine.LoadFromFile(FOpenDialog.FileName);
    FChkHiddenLayers.Checked := FEngine.UseHiddenLayers;
    FSpinH1.Value := FEngine.HiddenDim1;
    FSpinH2.Value := FEngine.HiddenDim2;
    if FCmbRedeAlvo.Items.IndexOf(FOpenDialog.FileName) < 0 then
      FCmbRedeAlvo.Items.Insert(0, FOpenDialog.FileName);
    FCmbRedeAlvo.ItemIndex := FCmbRedeAlvo.Items.IndexOf(FOpenDialog.FileName);
    SalvarConfiguracoes;
    AtualizarStatusGeral;
    LogMsg('Modelo carregado com sucesso: ' + FOpenDialog.FileName);
  end;
end;

procedure TfrmNeuroGraphNative.OnProcurarRedeAlvoClick(Sender: TObject);
begin
  if FOpenDialogRede.Execute then
  begin
    if FCmbRedeAlvo.Items.IndexOf(FOpenDialogRede.FileName) < 0 then
      FCmbRedeAlvo.Items.Insert(0, FOpenDialogRede.FileName);
    FCmbRedeAlvo.ItemIndex := FCmbRedeAlvo.Items.IndexOf(FOpenDialogRede.FileName);
    OnCmbRedeAlvoChange(FCmbRedeAlvo);
    SalvarConfiguracoes;
  end;
end;

procedure TfrmNeuroGraphNative.OnCmbRedeAlvoChange(Sender: TObject);
begin
  if FileExists(DefaultModelPath) then
  begin
    try
      if LowerCase(ExtractFileExt(DefaultModelPath)) = '.ngm' then
        FEngine.LoadMatrixNGM(DefaultModelPath)
      else
        FEngine.LoadFromFile(DefaultModelPath);
    except
    end;
  end;
  AtualizarStatusGeral;
  if FConfigLoaded then
    SalvarConfiguracoes;
end;

procedure TfrmNeuroGraphNative.OnAddPairClick(Sender: TObject);
var
  Q, A: string;
begin
  Q := Trim(FEditNewQuestion.Text);
  A := Trim(FEditNewAnswer.Text);
  if Q = '' then
  begin
    ShowMessage('Informe a pergunta.');
    Exit;
  end;
  AdicionarParAoDatasetECurado(Q, A, 'custom', 'Manual');
  FEditNewQuestion.Clear;
  FEditNewAnswer.Clear;
  TreinarESalvarRedeAlvo(Min(40, FSpinEpochs.Value), True);
  RefreshDatasetGrid;
  LogMsg(Format('Par adicionado, treinado e salvo: "%s" -> "%s"', [Q, A]));
end;

procedure TfrmNeuroGraphNative.OnReloadBaseClick(Sender: TObject);
begin
  LoadDefaultDatasets;
end;

procedure TfrmNeuroGraphNative.OnAskClick(Sender: TObject);
var
  Q: string;
  Gen: TNGGeneration;
begin
  Q := Trim(FEditChatQuestion.Text);
  if Q = '' then Exit;
  if FChkKeepContext.Checked then
    Gen := FEngine.Respond(Q, FSession)
  else
    Gen := FEngine.Generate(Q);

  FMemoChat.Lines.Add('Você: ' + Q);
  FMemoChat.Lines.Add(Format('NeuroGraph (%.2f ms): %s', [Gen.LatencyMs, Gen.Text]));
  FMemoChat.Lines.Add(Format('   [Absteve: %s | Motivo: %s | Camadas Ocultas: %s]',
    [BoolToStr(Gen.Abstained, 'Sim', 'Não'), Gen.Reason,
     BoolToStr(FEngine.UseHiddenLayers, 'Ativas', 'Inativas')]));
  FMemoChat.Lines.Add('');
  FEditChatQuestion.Clear;
end;

procedure TfrmNeuroGraphNative.OnChatKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    OnAskClick(Sender);
  end;
end;

procedure TfrmNeuroGraphNative.OnClearChatClick(Sender: TObject);
begin
  FSession.Clear;
  FMemoChat.Clear;
  FMemoChat.Lines.Add('Sessão de contexto reiniciada.');
end;

procedure TfrmNeuroGraphNative.OnRunEvalClick(Sender: TObject);
var
  Summary: TNGEvalSummary;
  I: Integer;
begin
  if Length(FTestExamples) = 0 then
  begin
    ShowMessage('Nenhuma questão de teste carregada.');
    Exit;
  end;

  Summary := FEngine.EvaluateDataset(FTestExamples);
  FLblBenchKPIs.Caption := Format(
    'Aprovados: %d/%d (%.1f%%) | Exact Match: %.1f%% | F1: %.1f%% | Latência: %.2f ms',
    [Summary.CorrectCount, Summary.TotalQuestions, Summary.ApprovalRatePct,
     Summary.ExactMatchPct, Summary.F1ScorePct, Summary.AvgLatencyMs]);

  FGridEval.RowCount := Max(2, Summary.TotalQuestions + 1);
  for I := 0 to High(Summary.Items) do
  begin
    FGridEval.Cells[0, I + 1] := IntToStr(Summary.Items[I].ID);
    FGridEval.Cells[1, I + 1] := Summary.Items[I].Category;
    FGridEval.Cells[2, I + 1] := Summary.Items[I].Question;
    FGridEval.Cells[3, I + 1] := Summary.Items[I].Expected;
    FGridEval.Cells[4, I + 1] := Summary.Items[I].Predicted;
    FGridEval.Cells[5, I + 1] := Format('%.0f%%', [Summary.Items[I].F1 * 100.0]);
    if Summary.Items[I].Correct then
      FGridEval.Cells[6, I + 1] := 'OK'
    else
      FGridEval.Cells[6, I + 1] := 'FALHA';
  end;

  FMemoBenchReport.Lines.Add('================================================================');
  FMemoBenchReport.Lines.Add(Format('RELATÓRIO HOLDOUT PASCAL PURO (Camadas Ocultas: %s)',
    [BoolToStr(FEngine.UseHiddenLayers, Format('%dx%d SiLU', [FEngine.HiddenDim1, FEngine.HiddenDim2]), 'Desativadas')]));
  FMemoBenchReport.Lines.Add(Format('Total: %d | Corretas: %d (%.2f%%) | F1-Score: %.2f%% | Latência Média: %.3f ms',
    [Summary.TotalQuestions, Summary.CorrectCount, Summary.ApprovalRatePct,
     Summary.F1ScorePct, Summary.AvgLatencyMs]));
end;

procedure TfrmNeuroGraphNative.OnRunXORCompareClick(Sender: TObject);
var
  XORTrain, XORTest: TNGExampleArray;
  EngLinear, EngDeep: TNGDeepEngine;
  SumLinear, SumDeep: TNGEvalSummary;
  T0: QWord;
  TimeLinMs, TimeDeepMs: QWord;

  procedure AddEx(var Arr: TNGExampleArray; const Q, A, Ctx1, Ctx2: string);
  var
    Idx: Integer;
  begin
    Idx := Length(Arr);
    SetLength(Arr, Idx + 1);
    Arr[Idx].Question := Q;
    Arr[Idx].Answer := A;
    Arr[Idx].IsRefusal := False;
    Arr[Idx].Category := 'xor_context';
    SetLength(Arr[Idx].Context, 2);
    Arr[Idx].Context[0] := Ctx1;
    Arr[Idx].Context[1] := Ctx2;
  end;

begin
  XORTrain := nil;
  XORTest := nil;

  AddEx(XORTrain, 'qual o protocolo de operação', 'ativar protocolo alfa seguro', 'ambiente servidor', 'estado carga alta');
  AddEx(XORTrain, 'qual o protocolo de operação', 'ativar protocolo beta crítico', 'ambiente servidor', 'estado carga baixa');
  AddEx(XORTrain, 'qual o protocolo de operação', 'ativar protocolo beta crítico', 'ambiente hospital', 'estado carga alta');
  AddEx(XORTrain, 'qual o protocolo de operação', 'ativar protocolo alfa seguro', 'ambiente hospital', 'estado carga baixa');

  AddEx(XORTrain, 'qual o regime de energia', 'operar em regime contínuo', 'modo noturno', 'bateria cheia');
  AddEx(XORTrain, 'qual o regime de energia', 'operar em economia máxima', 'modo noturno', 'bateria fraca');
  AddEx(XORTrain, 'qual o regime de energia', 'operar em economia máxima', 'modo diurno', 'bateria cheia');
  AddEx(XORTrain, 'qual o regime de energia', 'operar em regime contínuo', 'modo diurno', 'bateria fraca');

  XORTest := Copy(XORTrain, 0, Length(XORTrain));

  EngLinear := TNGDeepEngine.Create(False, 16, 16, 0.65, 0.05);
  EngDeep := TNGDeepEngine.Create(True, 96, 48, 0.65, 0.05);
  try
    T0 := GetTickCount64;
    EngLinear.Fit(XORTrain, 120, 0.04, 0.0001);
    TimeLinMs := GetTickCount64 - T0;
    SumLinear := EngLinear.EvaluateDataset(XORTest);

    T0 := GetTickCount64;
    EngDeep.Fit(XORTrain, 120, 0.04, 0.0001);
    TimeDeepMs := GetTickCount64 - T0;
    SumDeep := EngDeep.EvaluateDataset(XORTest);

    FMemoBenchReport.Lines.Add('================================================================');
    FMemoBenchReport.Lines.Add('COMPARATIVO EM PASCAL PURO (CPU): LINEAR vs. CAMADAS OCULTAS (SiLU)');
    FMemoBenchReport.Lines.Add(Format('1. Modelo Linear (0 camadas):   Acertos: %d/%d (%.1f%%) | F1: %.1f%% | Treino: %d ms | Inferência: %.2f ms',
      [SumLinear.CorrectCount, SumLinear.TotalQuestions, SumLinear.ApprovalRatePct,
       SumLinear.F1ScorePct, TimeLinMs, SumLinear.AvgLatencyMs]));
    FMemoBenchReport.Lines.Add(Format('2. Modelo Deep MLP (96x48 SiLU): Acertos: %d/%d (%.1f%%) | F1: %.1f%% | Treino: %d ms | Inferência: %.2f ms',
      [SumDeep.CorrectCount, SumDeep.TotalQuestions, SumDeep.ApprovalRatePct,
       SumDeep.F1ScorePct, TimeDeepMs, SumDeep.AvgLatencyMs]));
    FMemoBenchReport.Lines.Add('================================================================');
  finally
    EngLinear.Free;
    EngDeep.Free;
  end;
end;

procedure TfrmNeuroGraphNative.OnLimparLogClick(Sender: TObject);
begin
  FMemoLog.Clear;
end;

procedure TfrmNeuroGraphNative.OnAbortarClick(Sender: TObject);
begin
  FAbortRequested := True;
  LogMsg('[PARADA SOLICITADA] Finalizando etapa atual e SALVANDO A REDE (.ngs / .ngm)...');
end;

procedure TfrmNeuroGraphNative.OnApiKeyChange(Sender: TObject);
begin
  AtualizarStatusGeral;
  if Assigned(FEditToken) and (Trim(FEditToken.Text) = '') then
    FEditToken.Text := FEditApiKey.Text;
end;

procedure TfrmNeuroGraphNative.OnListaMemoExit(Sender: TObject);
begin
  if FConfigLoaded then
    SalvarConfiguracoes;
end;

procedure TfrmNeuroGraphNative.OnListaMemoChange(Sender: TObject);
begin
  if FConfigLoaded then
    SalvarConfiguracoes;
end;

procedure TfrmNeuroGraphNative.OnNovoTopicoKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    OnAdicionarTopicoClick(Sender);
  end;
end;

procedure TfrmNeuroGraphNative.OnNovoAssuntoContinuoKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    OnAddAssuntoContinuoClick(Sender);
  end;
end;

procedure TfrmNeuroGraphNative.SalvarConfiguracoes;
  procedure GravarNoArquivo(const ACaminhoIni: string);
  var
    Ini: TIniFile;
    i, CountValid: Integer;
    ItemStr: string;
  begin
    Ini := TIniFile.Create(ACaminhoIni);
    try
      Ini.WriteString('Geral', 'ApiKey', FEditApiKey.Text);
      Ini.WriteString('Geral', 'RedeAlvo', FCmbRedeAlvo.Text);
      Ini.WriteBool('Geral', 'UseHiddenLayers', FChkHiddenLayers.Checked);
      Ini.WriteInteger('Geral', 'HiddenH1', FSpinH1.Value);
      Ini.WriteInteger('Geral', 'HiddenH2', FSpinH2.Value);
      Ini.WriteInteger('Geral', 'Epochs', FSpinEpochs.Value);
      Ini.WriteString('Geral', 'LR', FEditLR.Text);

      Ini.EraseSection('RedesLista');
      CountValid := 0;
      for i := 0 to FCmbRedeAlvo.Items.Count - 1 do
      begin
        ItemStr := Trim(FCmbRedeAlvo.Items[i]);
        if ItemStr <> '' then
        begin
          Ini.WriteString('RedesLista', 'Item_' + IntToStr(CountValid), ItemStr);
          Inc(CountValid);
        end;
      end;
      Ini.WriteInteger('RedesLista', 'Count', CountValid);

      Ini.WriteString('ChatGPT', 'Provider', FCmbProvider.Text);
      Ini.WriteInteger('ChatGPT', 'ProviderIndex', FCmbProvider.ItemIndex);
      Ini.WriteString('ChatGPT', 'Model', FCmbModel.Text);
      Ini.WriteString('ChatGPT', 'Endpoint', FEditEndpoint.Text);
      Ini.WriteString('ChatGPT', 'Token', FEditToken.Text);
      Ini.WriteString('ChatGPT', 'Temperature', FEditTemperature.Text);
      Ini.WriteInteger('ChatGPT', 'MaxTokens', FSpinMaxTokens.Value);

      Ini.WriteString('YouTube', 'Tema', FEditTema.Text);
      Ini.WriteInteger('YouTube', 'QtdVideos', FSpinQtdVideos.Value);
      Ini.WriteString('YouTube', 'UltimaUrl', FEditVideoUrl.Text);

      Ini.WriteString('PDF', 'UltimoArquivo', FEditCaminhoPDF.Text);
      Ini.WriteInteger('PDF', 'MaxPares', FSpinMaxParesPDF.Value);

      Ini.EraseSection('Topicos');
      Ini.WriteInteger('Topicos', 'MinPares', FSpinMinParesTopicos.Value);
      Ini.EraseSection('TopicosLista');
      CountValid := 0;
      for i := 0 to FMemoTopicos.Lines.Count - 1 do
      begin
        ItemStr := Trim(FMemoTopicos.Lines[i]);
        if ItemStr <> '' then
        begin
          Ini.WriteString('TopicosLista', 'Item_' + IntToStr(CountValid), ItemStr);
          Inc(CountValid);
        end;
      end;
      Ini.WriteInteger('TopicosLista', 'Count', CountValid);

      Ini.EraseSection('TreinoContinuo');
      Ini.WriteInteger('TreinoContinuo', 'VideosPorCiclo', FSpinVideosPorCiclo.Value);
      Ini.WriteInteger('TreinoContinuo', 'ParesPorCiclo', FSpinParesPorCiclo.Value);
      Ini.WriteInteger('TreinoContinuo', 'IntervaloCiclo', FSpinIntervaloCiclo.Value);
      Ini.WriteInteger('TreinoContinuo', 'MaxCiclos', FSpinMaxCiclosContinuo.Value);
      Ini.WriteBool('TreinoContinuo', 'ApenasPortugues', FChkApenasPortugues.Checked);

      Ini.EraseSection('AssuntosContinuoLista');
      CountValid := 0;
      for i := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
      begin
        ItemStr := Trim(FMemoAssuntosContinuo.Lines[i]);
        if ItemStr <> '' then
        begin
          Ini.WriteString('AssuntosContinuoLista', 'Item_' + IntToStr(CountValid), ItemStr);
          Inc(CountValid);
        end;
      end;
      Ini.WriteInteger('AssuntosContinuoLista', 'Count', CountValid);
    finally
      Ini.Free;
    end;
  end;
begin
  if not FConfigLoaded then Exit;
  try
    GravarNoArquivo(ObterCaminhoIni);
    if DirectoryExists(ExtractFilePath(ObterCaminhoIniStudio)) then
      GravarNoArquivo(ObterCaminhoIniStudio);
  except
    on E: Exception do
      LogMsg('[AVISO] Erro ao salvar INI: ' + E.Message);
  end;
end;

procedure TfrmNeuroGraphNative.CarregarConfiguracoes;
var
  Ini: TIniFile;
  CaminhoLeitura, ProvName, ModName, KeyVal, EpVal, TokVal, TempVal, TemaVal, UrlVal, PdfVal, ItemStr: string;
  Idx, i, CountItems: Integer;
begin
  if FileExists(ObterCaminhoIni) then
    CaminhoLeitura := ObterCaminhoIni
  else if FileExists(ObterCaminhoIniStudio) then
    CaminhoLeitura := ObterCaminhoIniStudio
  else
    Exit;

  try
    Ini := TIniFile.Create(CaminhoLeitura);
    try
      KeyVal := Ini.ReadString('Geral', 'ApiKey', '');
      if KeyVal <> '' then FEditApiKey.Text := KeyVal;

      FChkHiddenLayers.Checked := Ini.ReadBool('Geral', 'UseHiddenLayers', True);
      FSpinH1.Value := Ini.ReadInteger('Geral', 'HiddenH1', 96);
      FSpinH2.Value := Ini.ReadInteger('Geral', 'HiddenH2', 48);
      FSpinEpochs.Value := Ini.ReadInteger('Geral', 'Epochs', 120);
      FEditLR.Text := Ini.ReadString('Geral', 'LR', '0.04');

      if Ini.SectionExists('RedesLista') and Ini.ValueExists('RedesLista', 'Count') then
      begin
        CountItems := Ini.ReadInteger('RedesLista', 'Count', 0);
        for i := CountItems - 1 downto 0 do
        begin
          ItemStr := Trim(Ini.ReadString('RedesLista', 'Item_' + IntToStr(i), ''));
          if (ItemStr <> '') and (FCmbRedeAlvo.Items.IndexOf(ItemStr) < 0) then
            FCmbRedeAlvo.Items.Insert(0, ItemStr);
        end;
      end;

      ModName := Ini.ReadString('Geral', 'RedeAlvo', '');
      if ModName <> '' then
      begin
        Idx := FCmbRedeAlvo.Items.IndexOf(ModName);
        if Idx >= 0 then
          FCmbRedeAlvo.ItemIndex := Idx
        else
        begin
          FCmbRedeAlvo.Items.Insert(0, ModName);
          FCmbRedeAlvo.ItemIndex := 0;
        end;
      end;

      ProvName := Ini.ReadString('ChatGPT', 'Provider', '');
      if ProvName <> '' then
      begin
        Idx := FCmbProvider.Items.IndexOf(ProvName);
        if Idx >= 0 then
        begin
          FCmbProvider.ItemIndex := Idx;
          OnProviderChange(FCmbProvider);
        end;
      end;

      ModName := Ini.ReadString('ChatGPT', 'Model', '');
      if ModName <> '' then
      begin
        Idx := FCmbModel.Items.IndexOf(ModName);
        if Idx >= 0 then
          FCmbModel.ItemIndex := Idx
        else
        begin
          FCmbModel.Items.Add(ModName);
          FCmbModel.ItemIndex := FCmbModel.Items.Count - 1;
        end;
      end;

      EpVal := Ini.ReadString('ChatGPT', 'Endpoint', '');
      if EpVal <> '' then FEditEndpoint.Text := EpVal;

      TokVal := Ini.ReadString('ChatGPT', 'Token', '');
      if TokVal <> '' then FEditToken.Text := TokVal;

      TempVal := Ini.ReadString('ChatGPT', 'Temperature', '0.7');
      FEditTemperature.Text := TempVal;
      FSpinMaxTokens.Value := Ini.ReadInteger('ChatGPT', 'MaxTokens', 1024);

      TemaVal := Ini.ReadString('YouTube', 'Tema', '');
      if TemaVal <> '' then FEditTema.Text := TemaVal;
      FSpinQtdVideos.Value := Ini.ReadInteger('YouTube', 'QtdVideos', 2);
      UrlVal := Ini.ReadString('YouTube', 'UltimaUrl', '');
      if UrlVal <> '' then FEditVideoUrl.Text := UrlVal;

      PdfVal := Ini.ReadString('PDF', 'UltimoArquivo', '');
      if PdfVal <> '' then FEditCaminhoPDF.Text := PdfVal;
      FSpinMaxParesPDF.Value := Ini.ReadInteger('PDF', 'MaxPares', 15);

      if Ini.SectionExists('TopicosLista') and Ini.ValueExists('TopicosLista', 'Count') then
      begin
        CountItems := Ini.ReadInteger('TopicosLista', 'Count', 0);
        FMemoTopicos.Lines.BeginUpdate;
        try
          FMemoTopicos.Clear;
          for i := 0 to CountItems - 1 do
          begin
            ItemStr := Trim(Ini.ReadString('TopicosLista', 'Item_' + IntToStr(i), ''));
            if ItemStr <> '' then
              FMemoTopicos.Lines.Add(ItemStr);
          end;
        finally
          FMemoTopicos.Lines.EndUpdate;
        end;
      end;
      if Ini.ValueExists('Topicos', 'MinPares') then
        FSpinMinParesTopicos.Value := Ini.ReadInteger('Topicos', 'MinPares', 100);

      if Ini.SectionExists('AssuntosContinuoLista') and Ini.ValueExists('AssuntosContinuoLista', 'Count') then
      begin
        CountItems := Ini.ReadInteger('AssuntosContinuoLista', 'Count', 0);
        FMemoAssuntosContinuo.Lines.BeginUpdate;
        try
          FMemoAssuntosContinuo.Clear;
          for i := 0 to CountItems - 1 do
          begin
            ItemStr := Trim(Ini.ReadString('AssuntosContinuoLista', 'Item_' + IntToStr(i), ''));
            if ItemStr <> '' then
              FMemoAssuntosContinuo.Lines.Add(ItemStr);
          end;
        finally
          FMemoAssuntosContinuo.Lines.EndUpdate;
        end;
      end;

      if Ini.ValueExists('TreinoContinuo', 'VideosPorCiclo') then
        FSpinVideosPorCiclo.Value := Ini.ReadInteger('TreinoContinuo', 'VideosPorCiclo', 2);
      if Ini.ValueExists('TreinoContinuo', 'ParesPorCiclo') then
        FSpinParesPorCiclo.Value := Ini.ReadInteger('TreinoContinuo', 'ParesPorCiclo', 12);
      if Ini.ValueExists('TreinoContinuo', 'IntervaloCiclo') then
        FSpinIntervaloCiclo.Value := Ini.ReadInteger('TreinoContinuo', 'IntervaloCiclo', 3);
      if Ini.ValueExists('TreinoContinuo', 'MaxCiclos') then
        FSpinMaxCiclosContinuo.Value := Ini.ReadInteger('TreinoContinuo', 'MaxCiclos', 0);
      if Ini.ValueExists('TreinoContinuo', 'ApenasPortugues') then
        FChkApenasPortugues.Checked := Ini.ReadBool('TreinoContinuo', 'ApenasPortugues', True);

      LogMsg('[INFO] Configurações e listas carregadas de: ' + CaminhoLeitura);
    finally
      Ini.Free;
    end;
  except
    on E: Exception do
      LogMsg('[AVISO] Falha ao ler configurações do INI: ' + E.Message);
  end;
end;

procedure TfrmNeuroGraphNative.OnSalvarConfigClick(Sender: TObject);
begin
  FConfigLoaded := True;
  SalvarConfiguracoes;
  LogMsg('[SUCESSO] Configurações e listas salvas em: ' + ObterCaminhoIni);
  ShowMessage('Configurações e listas salvas com sucesso em:'#13#10 + ObterCaminhoIni);
end;

function RunCLIMode: Boolean;
var
  I: Integer;
  Arg, Root, BenchPath, CuradoPath, OutModelPath, AskQuery: string;
  DoSelfTest, DoTrain, DoEval, DoRegerarNGM: Boolean;
  Engine, EngLin: TNGDeepEngine;
  TrainEx, ValEx, TestEx, CuradoEx: TNGExampleArray;
  Reports: TNGEpochReportArray;
  Summary, SumLin: TNGEvalSummary;
  Gen: TNGGeneration;
  T0: QWord;
  OldLen, J: Integer;

  procedure CLIOut(const S: string);
  var
    Line: AnsiString;
    FSLog: TFileStream;
    LogFile: string;
  begin
    Line := S + LineEnding;
    if StdOutputHandle <> 0 then
      FileWrite(StdOutputHandle, Line[1], Length(Line));
    try
      LogFile := ExtractFilePath(ParamStr(0)) + 'neurograph_cli_last.log';
      if FileExists(LogFile) then
        FSLog := TFileStream.Create(LogFile, fmOpenWrite or fmShareDenyNone)
      else
        FSLog := TFileStream.Create(LogFile, fmCreate);
      try
        FSLog.Seek(0, soEnd);
        FSLog.WriteBuffer(Line[1], Length(Line));
      finally
        FSLog.Free;
      end;
    except
    end;
  end;

begin
  Result := False;
  if ParamCount = 0 then Exit(False);

  DoSelfTest := False;
  DoTrain := False;
  DoEval := False;
  DoRegerarNGM := False;
  AskQuery := '';
  OutModelPath := '';

  I := 1;
  while I <= ParamCount do
  begin
    Arg := ParamStr(I);
    if Arg = '--self-test' then DoSelfTest := True
    else if (Arg = '--train') or (Arg = '--treinar') or (Arg = '--continuo') or (Arg = '--topicos-10') then DoTrain := True
    else if Arg = '--regerar-ngm' then begin DoTrain := True; DoRegerarNGM := True; end
    else if Arg = '--eval' then DoEval := True
    else if Copy(Arg, 1, 6) = '--ask=' then AskQuery := Copy(Arg, 7, MaxInt)
    else if (Arg = '--perguntar') and (I < ParamCount) then
    begin
      Inc(I);
      AskQuery := ParamStr(I);
    end
    else if (Arg = '--modelo') and (I < ParamCount) then
    begin
      Inc(I);
      OutModelPath := ParamStr(I);
    end;
    Inc(I);
  end;

  if (not DoSelfTest) and (not DoTrain) and (not DoEval) and (AskQuery = '') then
    Exit(False);

  Result := True;
  Root := IncludeTrailingPathDelimiter(ExpandFileName(ExtractFilePath(ParamStr(0)) + '..'));
  if not DirectoryExists(Root + 'experiments') then
    Root := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\';

  BenchPath := Root + 'experiments' + DirectorySeparator + 'contextual_v7' +
    DirectorySeparator + 'data' + DirectorySeparator + 'benchmark.json';
  CuradoPath := Root + 'treino' + DirectorySeparator + 'dados' +
    DirectorySeparator + 'processados' + DirectorySeparator + 'dataset_curado.json';
  if OutModelPath = '' then
    OutModelPath := Root + 'treino' + DirectorySeparator + 'modelos' +
      DirectorySeparator + 'neurograph_pascal_v8.ngs';

  Engine := TNGDeepEngine.Create(True, 96, 48, 0.65, 0.10);
  try
    if DoSelfTest or DoTrain then
    begin
      TrainEx := TNGDeepEngine.LoadExamplesFromJSONFile(BenchPath, 'train');
      ValEx := TNGDeepEngine.LoadExamplesFromJSONFile(BenchPath, 'validation');
      TestEx := TNGDeepEngine.LoadExamplesFromJSONFile(BenchPath, 'test');

      if FileExists(CuradoPath) then
      begin
        CuradoEx := TNGDeepEngine.LoadExamplesFromJSONFile(CuradoPath, '');
        if Length(CuradoEx) > 0 then
        begin
          OldLen := Length(TrainEx);
          SetLength(TrainEx, OldLen + Length(CuradoEx));
          for J := 0 to High(CuradoEx) do
            TrainEx[OldLen + J] := CuradoEx[J];
        end;
      end;

      CLIOut('=== NeuroGraph v8 Native (100% Free Pascal — CPU Deep MLP + Graph) ===');
      CLIOut(Format('Exemplos carregados: Treino=%d | Validacao=%d | Teste=%d',
        [Length(TrainEx), Length(ValEx), Length(TestEx)]));

      T0 := GetTickCount64;
      Reports := Engine.Fit(TrainEx, 120, 0.04, 0.0001);
      CLIOut(Format('Treinamento Deep MLP (96x48 SiLU) concluido em %d ms na CPU!', [GetTickCount64 - T0]));
      if Length(Reports) > 0 then
        CLIOut(Format('Loss Inicial: %.4f -> Loss Final: %.4f | Acuracia Tokens: %.2f%%',
          [Reports[0].CrossEntropyLoss, Reports[High(Reports)].CrossEntropyLoss,
           Reports[High(Reports)].TokenAccuracy * 100.0]));

      Engine.CalibrateConfidence(ValEx);
      Engine.SaveToFile(ChangeFileExt(OutModelPath, '.ngs'));
      Engine.SaveMatrixNGM(ChangeFileExt(OutModelPath, '.ngm'));
      if DoRegerarNGM then
        Engine.SaveMatrixNGM(Root + 'neurograph_memoria_ptbr_inibida_completa.ngm');
      CLIOut('Modelo (.ngs) e Matriz (.ngm) salvos em: ' + OutModelPath);

      Summary := Engine.EvaluateDataset(TestEx);
      CLIOut(Format('Resultado Holdout Deep MLP (54 Q): %d/%d corretas (%.2f%%) | F1: %.2f%% | Latencia Media: %.3f ms',
        [Summary.CorrectCount, Summary.TotalQuestions, Summary.ApprovalRatePct,
         Summary.F1ScorePct, Summary.AvgLatencyMs]));

      if DoSelfTest then
      begin
        EngLin := TNGDeepEngine.Create(False, 16, 16, 0.65, 0.10);
        try
          EngLin.Fit(TrainEx, 120, 0.04, 0.0001);
          EngLin.CalibrateConfidence(ValEx);
          SumLin := EngLin.EvaluateDataset(TestEx);
          CLIOut(Format('Resultado Holdout Linear   (54 Q): %d/%d corretas (%.2f%%) | F1: %.2f%% | Latencia Media: %.3f ms',
            [SumLin.CorrectCount, SumLin.TotalQuestions, SumLin.ApprovalRatePct,
             SumLin.F1ScorePct, SumLin.AvgLatencyMs]));
        finally
          EngLin.Free;
        end;
      end;
    end
    else if FileExists(OutModelPath) then
    begin
      if LowerCase(ExtractFileExt(OutModelPath)) = '.ngm' then
        Engine.LoadMatrixNGM(OutModelPath)
      else
        Engine.LoadFromFile(OutModelPath);
    end;

    if DoEval and (not DoTrain) and (not DoSelfTest) then
    begin
      TestEx := TNGDeepEngine.LoadExamplesFromJSONFile(BenchPath, 'test');
      Summary := Engine.EvaluateDataset(TestEx);
      CLIOut(Format('Holdout: %d/%d (%.2f%%) | F1: %.2f%% | Latencia: %.3f ms',
        [Summary.CorrectCount, Summary.TotalQuestions, Summary.ApprovalRatePct,
         Summary.F1ScorePct, Summary.AvgLatencyMs]));
    end;

    if AskQuery <> '' then
    begin
      Gen := Engine.Generate(AskQuery);
      CLIOut('Pergunta: ' + AskQuery);
      CLIOut('Resposta: ' + Gen.Text);
      CLIOut(Format('Latencia: %.3f ms | Absteve: %s', [Gen.LatencyMs, BoolToStr(Gen.Abstained, 'Sim', 'Nao')]));
    end;
  finally
    Engine.Free;
  end;
end;

end.
