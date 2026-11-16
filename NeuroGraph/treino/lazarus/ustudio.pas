unit ustudio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Dialogs, Spin, Menus, Process, fpjson, jsonparser, IniFiles, LazUTF8, chatgpt, aillmmodelcatalog;

type
  { TfrmStudio - Interface Desktop Lazarus para Treinamento do NeuroGraph & Provedores ChatGPT }
  TfrmStudio = class(TForm)
  private
    FPageControl: TPageControl;
    FTabTreinoContinuo, FTabYouTube, FTabPDF, FTab10Topicos, FTabChatGPT, FTabChat, FTabDataset: TTabSheet;

    FTabProfessora: TTabSheet;
    FEditTemaProfessora: TEdit;
    FSpinParesProfessora, FSpinEpocasProfessora: TSpinEdit;
    FMemoProfessora: TMemo;
    FBtnGerarProfessora, FBtnTreinarProfessora, FBtnCancelarProfessora: TButton;
    FLblProfessora: TLabel;
    FProfessora: TCHATGPT;
    FProfessoraGerando: Boolean;

    // Top Bar (Configuração / Status Geral)
    FEditApiKey: TEdit;
    FLblApiStatus, FLblModelStatus: TLabel;
    FBtnSalvarConfig: TButton;

    // Seleção da Rede Alvo em Treinamento
    FCmbRedeAlvo: TComboBox;
    FBtnProcurarRedeAlvo: TButton;
    FBtnRegerarNGMTopo: TButton;
    FOpenDialogRede: TOpenDialog;

    // Aba Treino Contínuo (IA + YouTube em Português)
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

    // Aba YouTube
    FEditTema: TEdit;
    FSpinQtdVideos: TSpinEdit;
    FBtnBuscarYouTube: TButton;
    FEditVideoUrl: TEdit;
    FBtnProcessarVideo: TButton;

    // Aba PDF
    FEditCaminhoPDF: TEdit;
    FBtnProcurarPDF: TButton;
    FSpinMaxParesPDF: TSpinEdit;
    FBtnProcessarPDF: TButton;
    FOpenDialogPDF: TOpenDialog;

    // Aba Treinamento 10 Tópicos (Mínimo 1000 pares)
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

    // Aba TCHATGPT (Provedores, Modelos, URL e Teste)
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

    // Aba Chat / Teste do NeuroGraph
    FEditPergunta: TEdit;
    FBtnPerguntar: TButton;
    FMemoChat: TMemo;

    // Aba Dataset
    FMemoDataset: TMemo;
    FBtnAtualizarDataset: TButton;
    FBtnRetreinarTudo: TButton;
    FLblTotalDataset: TLabel;

    // Painel Inferior (Log e Progresso)
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

    // Controle de Processo
    FCurrentProcess: TProcess;
    FIsBusy: Boolean;
    FAbortRequested: Boolean;
    FConfigLoaded: Boolean;

    procedure ConstruirAbaProfessora;
    procedure OnGerarProfessoraClick(Sender: TObject);
    procedure OnTreinarProfessoraClick(Sender: TObject);
    procedure OnCancelarProfessoraClick(Sender: TObject);
    procedure OnProfessoraCompleta(Sender: TObject; ASuccess: Boolean);
    procedure BuildUI;
    procedure BuildTraySystem;
    procedure GerarIconesEstado;
    procedure AtualizarIconeRelogio;
    procedure OnTrayIconClick(Sender: TObject);
    procedure OnTrayTimerTick(Sender: TObject);
    procedure OnMinimizarParaRelogioClick(Sender: TObject);
    procedure OnRestaurarDoRelogioClick(Sender: TObject);
    procedure OnSairPeloRelogioClick(Sender: TObject);
    procedure OnFormWindowStateChange(Sender: TObject);
    function CriarAba(const ATitulo: string): TTabSheet;
    procedure LogMsg(const AMsg: string);
    procedure SetBusy(const ABusy: Boolean);
    function ObterCaminhoAppTreino: string;
    function ObterPythonExe: string;
    procedure ExecutarComandoTreino(const AParametros: array of string);

    // Eventos Aba Treino Contínuo & Regeneração NGM
    procedure ConstruirAbaTreinoContinuo;
    procedure OnIniciarContinuoClick(Sender: TObject);
    procedure OnRegerarNGMClick(Sender: TObject);
    procedure OnAddAssuntoContinuoClick(Sender: TObject);
    procedure OnPadraoAssuntosContinuoClick(Sender: TObject);
    procedure OnLimparAssuntosContinuoClick(Sender: TObject);

    // Eventos Aba YouTube & PDF
    procedure OnBuscarYouTubeClick(Sender: TObject);
    procedure OnProcessarVideoClick(Sender: TObject);
    procedure OnProcurarPDFClick(Sender: TObject);
    procedure OnProcessarPDFClick(Sender: TObject);
    procedure OnGerar10TopicosClick(Sender: TObject);
    procedure OnAdicionarTopicoClick(Sender: TObject);
    procedure OnLimparTopicosClick(Sender: TObject);
    procedure OnTopicosPadraoClick(Sender: TObject);
    procedure OnProcurarRedeAlvoClick(Sender: TObject);
    procedure OnCmbRedeAlvoChange(Sender: TObject);
    procedure PopularRedesDisponiveis;
    procedure AtualizarResultadoTopicos;

    // Eventos Aba TCHATGPT
    procedure ConstruirAbaChatGPT;
    procedure PopularProvedores;
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

    // Eventos Aba Chat NeuroGraph & Dataset
    procedure OnPerguntarClick(Sender: TObject);
    procedure OnPerguntaKeyPress(Sender: TObject; var Key: char);
    procedure OnAtualizarDatasetClick(Sender: TObject);
    procedure OnRetreinarTudoClick(Sender: TObject);
    procedure OnLimparLogClick(Sender: TObject);
    procedure OnAbortarClick(Sender: TObject);
    procedure OnApiKeyChange(Sender: TObject);
    procedure OnSalvarConfigClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    // Persistência de Configurações (INI)
    function ObterCaminhoIni: string;
    procedure SalvarConfiguracoes;
    procedure CarregarConfiguracoes;
    procedure OnListaMemoExit(Sender: TObject);
    procedure OnListaMemoChange(Sender: TObject);
    procedure OnNovoTopicoKeyPress(Sender: TObject; var Key: char);
    procedure OnNovoAssuntoContinuoKeyPress(Sender: TObject; var Key: char);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AtualizarStatusGeral;
  end;

var
  frmStudio: TfrmStudio;

implementation

constructor TfrmStudio.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'NeuroGraph Studio — Treinador & Curador (Lazarus Desktop)';
  Width := 1020;
  Height := 750;
  Position := poScreenCenter;
  FIsBusy := False;
  FAbortRequested := False;
  FConfigLoaded := False;
  FCurrentProcess := nil;
  FIsTestingConnection := False;

  // Instancia componente TCHATGPT
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
  AtualizarStatusGeral;
  AtualizarIconeRelogio;
  OnClose := @FormClose;
  OnWindowStateChange := @OnFormWindowStateChange;
end;

procedure TfrmStudio.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var
  StopFile: string;
  SL: TStringList;
begin
  if Assigned(FProfessora) then FProfessora.Cancel;
  SalvarConfiguracoes;
  if Assigned(FTrayTimer) then
    FTrayTimer.Enabled := False;
  if Assigned(FTrayIcon) then
    FTrayIcon.Visible := False;
  if Assigned(FCurrentProcess) and FCurrentProcess.Running then
  begin
    FAbortRequested := True;
    try
      StopFile := ExtractFilePath(ObterCaminhoAppTreino) + '.stop_training';
      SL := TStringList.Create;
      try
        SL.Text := 'stop';
        SL.SaveToFile(StopFile);
      finally
        SL.Free;
      end;
      FCurrentProcess.Terminate(1);
    except
    end;
  end;
  CloseAction := caFree;
end;

destructor TfrmStudio.Destroy;
begin
  SalvarConfiguracoes;
  if Assigned(FTrayIcon) then
    FTrayIcon.Visible := False;
  if Assigned(FIconIdle) then FIconIdle.Free;
  if Assigned(FIconTrainA) then FIconTrainA.Free;
  if Assigned(FIconTrainB) then FIconTrainB.Free;
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

procedure TfrmStudio.BuildUI;
var
  PnlTop, PnlBottom, PnlBtnsLog: TPanel;
  GrpBuscaYT, GrpVideoYT, GrpPDF: TGroupBox;
  PnlInputChat, PnlDatasetTop: TPanel;
  Lbl: TLabel;
begin
  // 1. Painel Superior de Configurações Gerais
  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := 84;
  PnlTop.BevelOuter := bvNone;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Chave OpenAI (Global):';
  Lbl.Left := 16;
  Lbl.Top := 14;

  FEditApiKey := TEdit.Create(Self);
  FEditApiKey.Parent := PnlTop;
  FEditApiKey.Left := 155;
  FEditApiKey.Top := 10;
  FEditApiKey.Width := 260;
  FEditApiKey.EchoMode := emPassword;
  FEditApiKey.Text := GetEnvironmentVariable('OPENAI_API_KEY');
  FEditApiKey.OnChange := @OnApiKeyChange;

  FLblApiStatus := TLabel.Create(Self);
  FLblApiStatus.Parent := PnlTop;
  FLblApiStatus.Left := 425;
  FLblApiStatus.Top := 14;
  FLblApiStatus.Caption := '● OpenAI Ativa';
  FLblApiStatus.Font.Style := [fsBold];

  FLblModelStatus := TLabel.Create(Self);
  FLblModelStatus.Parent := PnlTop;
  FLblModelStatus.Left := 575;
  FLblModelStatus.Top := 14;
  FLblModelStatus.Caption := 'Modelo: Verificando...';

  FBtnSalvarConfig := TButton.Create(Self);
  FBtnSalvarConfig.Parent := PnlTop;
  FBtnSalvarConfig.Caption := 'Salvar Configurações';
  FBtnSalvarConfig.Left := 820;
  FBtnSalvarConfig.Top := 8;
  FBtnSalvarConfig.Width := 160;
  FBtnSalvarConfig.Height := 28;
  FBtnSalvarConfig.Anchors := [akTop, akRight];
  FBtnSalvarConfig.OnClick := @OnSalvarConfigClick;

  // Linha 2 do Painel Superior: Apontamento da Rede em Treinamento (.ngs / .ngm)
  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Rede Alvo (.ngs / .ngm):';
  Lbl.Left := 16;
  Lbl.Top := 48;
  Lbl.Font.Style := [fsBold];

  FCmbRedeAlvo := TComboBox.Create(Self);
  FCmbRedeAlvo.Parent := PnlTop;
  FCmbRedeAlvo.Left := 180;
  FCmbRedeAlvo.Top := 44;
  FCmbRedeAlvo.Width := 465;
  FCmbRedeAlvo.Anchors := [akTop, akLeft, akRight];
  FCmbRedeAlvo.OnChange := @OnCmbRedeAlvoChange;

  FBtnProcurarRedeAlvo := TButton.Create(Self);
  FBtnProcurarRedeAlvo.Parent := PnlTop;
  FBtnProcurarRedeAlvo.Caption := 'Procurar Rede...';
  FBtnProcurarRedeAlvo.Left := 652;
  FBtnProcurarRedeAlvo.Top := 42;
  FBtnProcurarRedeAlvo.Width := 130;
  FBtnProcurarRedeAlvo.Height := 28;
  FBtnProcurarRedeAlvo.Anchors := [akTop, akRight];
  FBtnProcurarRedeAlvo.OnClick := @OnProcurarRedeAlvoClick;

  FBtnRegerarNGMTopo := TButton.Create(Self);
  FBtnRegerarNGMTopo.Parent := PnlTop;
  FBtnRegerarNGMTopo.Caption := '🔄 Regerar Matrizes .NGM';
  FBtnRegerarNGMTopo.Left := 790;
  FBtnRegerarNGMTopo.Top := 42;
  FBtnRegerarNGMTopo.Width := 190;
  FBtnRegerarNGMTopo.Height := 28;
  FBtnRegerarNGMTopo.Font.Style := [fsBold];
  FBtnRegerarNGMTopo.Anchors := [akTop, akRight];
  FBtnRegerarNGMTopo.OnClick := @OnRegerarNGMClick;

  FOpenDialogRede := TOpenDialog.Create(Self);
  FOpenDialogRede.Title := 'Selecionar Rede Alvo (.ngs ou .ngm)';
  FOpenDialogRede.Filter := 'Redes e Matrizes NeuroGraph (*.ngs;*.ngm)|*.ngs;*.ngm|Matrizes NGM (*.ngm)|*.ngm|Modelos NGS (*.ngs)|*.ngs|Todos os Arquivos (*.*)|*.*';

  // 2. Painel Inferior (Log e Progresso)
  PnlBottom := TPanel.Create(Self);
  PnlBottom.Parent := Self;
  PnlBottom.Align := alBottom;
  PnlBottom.Height := 170;
  PnlBottom.BevelOuter := bvNone;

  FProgressBar := TProgressBar.Create(Self);
  FProgressBar.Parent := PnlBottom;
  FProgressBar.Align := alTop;
  FProgressBar.Height := 8;

  PnlBtnsLog := TPanel.Create(Self);
  PnlBtnsLog.Parent := PnlBottom;
  PnlBtnsLog.Align := alBottom;
  PnlBtnsLog.Height := 34;
  PnlBtnsLog.BevelOuter := bvNone;

  FBtnLimparLog := TButton.Create(Self);
  FBtnLimparLog.Parent := PnlBtnsLog;
  FBtnLimparLog.Caption := 'Limpar Log';
  FBtnLimparLog.Left := 8;
  FBtnLimparLog.Top := 4;
  FBtnLimparLog.Width := 90;
  FBtnLimparLog.OnClick := @OnLimparLogClick;

  FBtnAbortar := TButton.Create(Self);
  FBtnAbortar.Parent := PnlBtnsLog;
  FBtnAbortar.Caption := 'Interromper Execução';
  FBtnAbortar.Left := 106;
  FBtnAbortar.Top := 4;
  FBtnAbortar.Width := 150;
  FBtnAbortar.Enabled := False;
  FBtnAbortar.OnClick := @OnAbortarClick;

  FBtnMinimizarRelogio := TButton.Create(Self);
  FBtnMinimizarRelogio.Parent := PnlBtnsLog;
  FBtnMinimizarRelogio.Caption := '🕒 Enviar p/ Relógio (Bandeja)';
  FBtnMinimizarRelogio.Left := 264;
  FBtnMinimizarRelogio.Top := 4;
  FBtnMinimizarRelogio.Width := 205;
  FBtnMinimizarRelogio.OnClick := @OnMinimizarParaRelogioClick;

  FShapeStatusTreino := TShape.Create(Self);
  FShapeStatusTreino.Parent := PnlBtnsLog;
  FShapeStatusTreino.Shape := stCircle;
  FShapeStatusTreino.Left := 482;
  FShapeStatusTreino.Top := 9;
  FShapeStatusTreino.Width := 16;
  FShapeStatusTreino.Height := 16;
  FShapeStatusTreino.Brush.Color := $00AA5500;
  FShapeStatusTreino.Pen.Color := clWhite;

  FLblStatusTreinoBarra := TLabel.Create(Self);
  FLblStatusTreinoBarra.Parent := PnlBtnsLog;
  FLblStatusTreinoBarra.Left := 504;
  FLblStatusTreinoBarra.Top := 9;
  FLblStatusTreinoBarra.Caption := 'Ícone no Relógio Ativo — Estado: Pronto (Parado)';
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

  // 3. PageControl Central
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;

  // Aba Treino Contínuo (IA + YouTube estritamente em Português)
  ConstruirAbaTreinoContinuo;
  ConstruirAbaProfessora;

  // Aba YouTube
  FTabYouTube := CriarAba('  🎥 Treinar via YouTube  ');

  GrpBuscaYT := TGroupBox.Create(Self);
  GrpBuscaYT.Parent := FTabYouTube;
  GrpBuscaYT.Align := alTop;
  GrpBuscaYT.Height := 105;
  GrpBuscaYT.Caption := ' Busca por Tema Didático em Português ';

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
  FSpinQtdVideos.MaxValue := 5;
  FSpinQtdVideos.Value := 2;

  FBtnBuscarYouTube := TButton.Create(Self);
  FBtnBuscarYouTube.Parent := GrpBuscaYT;
  FBtnBuscarYouTube.Caption := '🔍 Buscar no YouTube, Curar com IA e Treinar';
  FBtnBuscarYouTube.Left := 140;
  FBtnBuscarYouTube.Top := 48;
  FBtnBuscarYouTube.Width := 310;
  FBtnBuscarYouTube.Height := 30;
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
  FEditVideoUrl.Left := 140;
  FEditVideoUrl.Top := 12;
  FEditVideoUrl.Width := 490;

  FBtnProcessarVideo := TButton.Create(Self);
  FBtnProcessarVideo.Parent := GrpVideoYT;
  FBtnProcessarVideo.Caption := '▶️ Processar Vídeo Único e Treinar';
  FBtnProcessarVideo.Left := 140;
  FBtnProcessarVideo.Top := 48;
  FBtnProcessarVideo.Width := 250;
  FBtnProcessarVideo.Height := 30;
  FBtnProcessarVideo.OnClick := @OnProcessarVideoClick;

  // Aba PDF
  FTabPDF := CriarAba('  📄 Treinar via PDF  ');

  GrpPDF := TGroupBox.Create(Self);
  GrpPDF.Parent := FTabPDF;
  GrpPDF.Align := alTop;
  GrpPDF.Height := 145;
  GrpPDF.Caption := ' Seleção de Documento PDF ';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpPDF;
  Lbl.Caption := 'Arquivo PDF:';
  Lbl.Left := 16;
  Lbl.Top := 20;

  FEditCaminhoPDF := TEdit.Create(Self);
  FEditCaminhoPDF.Parent := GrpPDF;
  FEditCaminhoPDF.Left := 110;
  FEditCaminhoPDF.Top := 16;
  FEditCaminhoPDF.Width := 480;

  FBtnProcurarPDF := TButton.Create(Self);
  FBtnProcurarPDF.Parent := GrpPDF;
  FBtnProcurarPDF.Caption := 'Procurar...';
  FBtnProcurarPDF.Left := 600;
  FBtnProcurarPDF.Top := 15;
  FBtnProcurarPDF.Width := 90;
  FBtnProcurarPDF.OnClick := @OnProcurarPDFClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpPDF;
  Lbl.Caption := 'Máx. Perguntas:';
  Lbl.Left := 16;
  Lbl.Top := 60;

  FSpinMaxParesPDF := TSpinEdit.Create(Self);
  FSpinMaxParesPDF.Parent := GrpPDF;
  FSpinMaxParesPDF.Left := 110;
  FSpinMaxParesPDF.Top := 56;
  FSpinMaxParesPDF.Width := 60;
  FSpinMaxParesPDF.MinValue := 5;
  FSpinMaxParesPDF.MaxValue := 60;
  FSpinMaxParesPDF.Value := 15;

  FBtnProcessarPDF := TButton.Create(Self);
  FBtnProcessarPDF.Parent := GrpPDF;
  FBtnProcessarPDF.Caption := '🚀 Extrair Texto do PDF, Gerar P&R e Treinar NeuroGraph';
  FBtnProcessarPDF.Left := 110;
  FBtnProcessarPDF.Top := 92;
  FBtnProcessarPDF.Width := 380;
  FBtnProcessarPDF.Height := 32;
  FBtnProcessarPDF.OnClick := @OnProcessarPDFClick;

  FOpenDialogPDF := TOpenDialog.Create(Self);
  FOpenDialogPDF.Title := 'Selecione um Arquivo PDF Educativo';
  FOpenDialogPDF.Filter := 'Documentos PDF (*.pdf)|*.pdf|Todos os Arquivos (*.*)|*.*';

  // Aba Treinamento por Tópicos (Incremental Item a Item)
  FTab10Topicos := CriarAba('  🎯 Treino por Tópicos  ');

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Tópicos para Treinamento (1 por linha):';
  Lbl.Left := 14;
  Lbl.Top := 12;
  Lbl.Font.Style := [fsBold];

  FMemoTopicos := TMemo.Create(Self);
  FMemoTopicos.Parent := FTab10Topicos;
  FMemoTopicos.Left := 14;
  FMemoTopicos.Top := 32;
  FMemoTopicos.Width := 440;
  FMemoTopicos.Height := 165;
  FMemoTopicos.ScrollBars := ssVertical;
  FMemoTopicos.Font.Name := 'Segoe UI';
  FMemoTopicos.Font.Size := 9;
  FMemoTopicos.OnChange := @OnListaMemoChange;
  FMemoTopicos.OnExit := @OnListaMemoExit;
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

  // Painel Direito da Aba: Visualização do que foi Treinado
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := '📋 O que foi Treinado nesta Sessão (Perguntas, Respostas e Rede Salva):';
  Lbl.Left := 468;
  Lbl.Top := 12;
  Lbl.Font.Style := [fsBold];

  FMemoResultadoTopicos := TMemo.Create(Self);
  FMemoResultadoTopicos.Parent := FTab10Topicos;
  FMemoResultadoTopicos.Left := 468;
  FMemoResultadoTopicos.Top := 32;
  FMemoResultadoTopicos.Width := 515;
  FMemoResultadoTopicos.Height := 295;
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
  FLblResumoTopicos.Caption := 'Status do Último Treino: Carregando histórico...';
  FLblResumoTopicos.Font.Style := [fsBold];
  FLblResumoTopicos.Font.Color := $006600;

  // Controles para inclusão de novos tópicos (Coluna Esquerda)
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Novo Tópico:';
  Lbl.Left := 14;
  Lbl.Top := 208;

  FEditNovoTopico := TEdit.Create(Self);
  FEditNovoTopico.Parent := FTab10Topicos;
  FEditNovoTopico.Left := 95;
  FEditNovoTopico.Top := 204;
  FEditNovoTopico.Width := 235;
  FEditNovoTopico.OnKeyPress := @OnNovoTopicoKeyPress;

  FBtnAdicionarTopico := TButton.Create(Self);
  FBtnAdicionarTopico.Parent := FTab10Topicos;
  FBtnAdicionarTopico.Caption := '➕ Incluir';
  FBtnAdicionarTopico.Left := 336;
  FBtnAdicionarTopico.Top := 202;
  FBtnAdicionarTopico.Width := 118;
  FBtnAdicionarTopico.Height := 27;
  FBtnAdicionarTopico.OnClick := @OnAdicionarTopicoClick;

  FBtnTopicosPadrao := TButton.Create(Self);
  FBtnTopicosPadrao.Parent := FTab10Topicos;
  FBtnTopicosPadrao.Caption := 'Restaurar 10 Padrão';
  FBtnTopicosPadrao.Left := 14;
  FBtnTopicosPadrao.Top := 236;
  FBtnTopicosPadrao.Width := 215;
  FBtnTopicosPadrao.Height := 26;
  FBtnTopicosPadrao.OnClick := @OnTopicosPadraoClick;

  FBtnLimparTopicos := TButton.Create(Self);
  FBtnLimparTopicos.Parent := FTab10Topicos;
  FBtnLimparTopicos.Caption := '🧹 Limpar Lista de Tópicos';
  FBtnLimparTopicos.Left := 238;
  FBtnLimparTopicos.Top := 236;
  FBtnLimparTopicos.Width := 216;
  FBtnLimparTopicos.Height := 26;
  FBtnLimparTopicos.OnClick := @OnLimparTopicosClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Quantidade de Pares (1+):';
  Lbl.Left := 14;
  Lbl.Top := 272;

  FSpinMinParesTopicos := TSpinEdit.Create(Self);
  FSpinMinParesTopicos.Parent := FTab10Topicos;
  FSpinMinParesTopicos.Left := 185;
  FSpinMinParesTopicos.Top := 268;
  FSpinMinParesTopicos.Width := 95;
  FSpinMinParesTopicos.MinValue := 1;
  FSpinMinParesTopicos.MaxValue := 50000;
  FSpinMinParesTopicos.Value := 20;

  FBtnGerar10Topicos := TButton.Create(Self);
  FBtnGerar10Topicos.Parent := FTab10Topicos;
  FBtnGerar10Topicos.Caption := '🚀 Gerar P&R e Treinar Rede';
  FBtnGerar10Topicos.Left := 14;
  FBtnGerar10Topicos.Top := 302;
  FBtnGerar10Topicos.Width := 265;
  FBtnGerar10Topicos.Height := 34;
  FBtnGerar10Topicos.OnClick := @OnGerar10TopicosClick;

  FBtnPararTreinoTopicos := TButton.Create(Self);
  FBtnPararTreinoTopicos.Parent := FTab10Topicos;
  FBtnPararTreinoTopicos.Caption := '⏹️ Parar e Salvar';
  FBtnPararTreinoTopicos.Left := 286;
  FBtnPararTreinoTopicos.Top := 302;
  FBtnPararTreinoTopicos.Width := 168;
  FBtnPararTreinoTopicos.Height := 34;
  FBtnPararTreinoTopicos.Enabled := False;
  FBtnPararTreinoTopicos.Font.Style := [fsBold];
  FBtnPararTreinoTopicos.OnClick := @OnAbortarClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'ℹ️ Mesmo se interrompido, o modelo (.ngs) é salvo automaticamente.';
  Lbl.Left := 14;
  Lbl.Top := 342;
  Lbl.Font.Color := clGray;

  // Nova Aba: TCHATGPT (Provedores, Modelos, URL e Teste)
  ConstruirAbaChatGPT;

  // Aba Chat / Teste do NeuroGraph
  FTabChat := CriarAba('  🧠 Conversar com NeuroGraph  ');

  PnlInputChat := TPanel.Create(Self);
  PnlInputChat.Parent := FTabChat;
  PnlInputChat.Align := alTop;
  PnlInputChat.Height := 46;
  PnlInputChat.BevelOuter := bvNone;

  FEditPergunta := TEdit.Create(Self);
  FEditPergunta.Parent := PnlInputChat;
  FEditPergunta.Left := 8;
  FEditPergunta.Top := 8;
  FEditPergunta.Width := 680;
  FEditPergunta.Font.Size := 10;
  FEditPergunta.OnKeyPress := @OnPerguntaKeyPress;

  FBtnPerguntar := TButton.Create(Self);
  FBtnPerguntar.Parent := PnlInputChat;
  FBtnPerguntar.Caption := 'Perguntar';
  FBtnPerguntar.Left := 698;
  FBtnPerguntar.Top := 7;
  FBtnPerguntar.Width := 100;
  FBtnPerguntar.Height := 28;
  FBtnPerguntar.OnClick := @OnPerguntarClick;

  FMemoChat := TMemo.Create(Self);
  FMemoChat.Parent := FTabChat;
  FMemoChat.Align := alClient;
  FMemoChat.ReadOnly := True;
  FMemoChat.ScrollBars := ssAutoBoth;
  FMemoChat.Font.Size := 10;
  FMemoChat.Font.Name := 'Segoe UI';

  // Aba Dataset
  FTabDataset := CriarAba('  📊 Dataset Consolidado  ');

  PnlDatasetTop := TPanel.Create(Self);
  PnlDatasetTop.Parent := FTabDataset;
  PnlDatasetTop.Align := alTop;
  PnlDatasetTop.Height := 42;
  PnlDatasetTop.BevelOuter := bvNone;

  FBtnAtualizarDataset := TButton.Create(Self);
  FBtnAtualizarDataset.Parent := PnlDatasetTop;
  FBtnAtualizarDataset.Caption := 'Atualizar Visão';
  FBtnAtualizarDataset.Left := 8;
  FBtnAtualizarDataset.Top := 8;
  FBtnAtualizarDataset.Width := 120;
  FBtnAtualizarDataset.OnClick := @OnAtualizarDatasetClick;

  FBtnRetreinarTudo := TButton.Create(Self);
  FBtnRetreinarTudo.Parent := PnlDatasetTop;
  FBtnRetreinarTudo.Caption := '⚡ Retreinar com Todo o Dataset';
  FBtnRetreinarTudo.Left := 136;
  FBtnRetreinarTudo.Top := 8;
  FBtnRetreinarTudo.Width := 210;
  FBtnRetreinarTudo.OnClick := @OnRetreinarTudoClick;

  FLblTotalDataset := TLabel.Create(Self);
  FLblTotalDataset.Parent := PnlDatasetTop;
  FLblTotalDataset.Left := 360;
  FLblTotalDataset.Top := 14;
  FLblTotalDataset.Caption := 'Total de Fatos: 0';
  FLblTotalDataset.Font.Style := [fsBold];

  FMemoDataset := TMemo.Create(Self);
  FMemoDataset.Parent := FTabDataset;
  FMemoDataset.Align := alClient;
  FMemoDataset.ReadOnly := True;
  FMemoDataset.ScrollBars := ssAutoBoth;
  FMemoDataset.Font.Name := 'Consolas';
  FMemoDataset.Font.Size := 9;

  OnAtualizarDatasetClick(nil);
end;

procedure TfrmStudio.ConstruirAbaProfessora;
var
  Painel: TPanel;
  Lbl: TLabel;
begin
  FProfessoraGerando := False;
  FProfessora := TCHATGPT.Create(Self);
  FProfessora.Streaming := False;
  FProfessora.OnRequestComplete := @OnProfessoraCompleta;
  FTabProfessora := CriarAba('  IA Professora → Aluna  ');
  Painel := TPanel.Create(Self);
  Painel.Parent := FTabProfessora;
  Painel.Align := alTop;
  Painel.Height := 188;
  Painel.BevelOuter := bvNone;
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Painel;
  Lbl.SetBounds(12, 8, 900, 20);
  Lbl.Caption := 'Professora: provedor/modelo da aba Provedores & Modelos. Aluna: rede .ngs selecionada no topo.';
  FEditTemaProfessora := TEdit.Create(Self);
  FEditTemaProfessora.Parent := Painel;
  FEditTemaProfessora.SetBounds(12, 34, 530, 28);
  FEditTemaProfessora.Text := 'Conceitos básicos de energia solar';
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Painel;
  Lbl.SetBounds(12, 74, 80, 20);
  Lbl.Caption := 'Pares treino:';
  FSpinParesProfessora := TSpinEdit.Create(Self);
  FSpinParesProfessora.Parent := Painel;
  FSpinParesProfessora.SetBounds(100, 70, 72, 28);
  FSpinParesProfessora.MinValue := 2;
  FSpinParesProfessora.MaxValue := 100;
  FSpinParesProfessora.Value := 10;
  Lbl := TLabel.Create(Self);
  Lbl.Parent := Painel;
  Lbl.SetBounds(190, 74, 60, 20);
  Lbl.Caption := 'Épocas:';
  FSpinEpocasProfessora := TSpinEdit.Create(Self);
  FSpinEpocasProfessora.Parent := Painel;
  FSpinEpocasProfessora.SetBounds(254, 70, 72, 28);
  FSpinEpocasProfessora.MinValue := 1;
  FSpinEpocasProfessora.MaxValue := 1000;
  FSpinEpocasProfessora.Value := 60;
  FBtnGerarProfessora := TButton.Create(Self);
  FBtnGerarProfessora.Parent := Painel;
  FBtnGerarProfessora.SetBounds(12, 108, 170, 32);
  FBtnGerarProfessora.Caption := '1. Gerar exemplos';
  FBtnGerarProfessora.OnClick := @OnGerarProfessoraClick;
  FBtnTreinarProfessora := TButton.Create(Self);
  FBtnTreinarProfessora.Parent := Painel;
  FBtnTreinarProfessora.SetBounds(192, 108, 240, 32);
  FBtnTreinarProfessora.Caption := '2. Treinar com exemplos revisados';
  FBtnTreinarProfessora.OnClick := @OnTreinarProfessoraClick;
  FBtnCancelarProfessora := TButton.Create(Self);
  FBtnCancelarProfessora.Parent := Painel;
  FBtnCancelarProfessora.SetBounds(442, 108, 160, 32);
  FBtnCancelarProfessora.Caption := 'Cancelar geração';
  FBtnCancelarProfessora.Enabled := False;
  FBtnCancelarProfessora.OnClick := @OnCancelarProfessoraClick;
  FLblProfessora := TLabel.Create(Self);
  FLblProfessora.Parent := Painel;
  FLblProfessora.SetBounds(12, 148, 940, 36);
  FLblProfessora.WordWrap := True;
  FLblProfessora.Caption := 'Revise o JSON abaixo. Validação fica fora do treino. Só promove pesos com melhoria e sem regressão na base; mantém backup e relatório. Use Parar no console para interromper.';
  FMemoProfessora := TMemo.Create(Self);
  FMemoProfessora.Parent := FTabProfessora;
  FMemoProfessora.Align := alClient;
  FMemoProfessora.ScrollBars := ssBoth;
  FMemoProfessora.WordWrap := False;
  FMemoProfessora.Font.Name := 'Consolas';
end;

procedure TfrmStudio.OnGerarProfessoraClick(Sender: TObject);
var
  Prompt: string;
begin
  if FIsBusy or FProfessoraGerando then Exit;
  if (FCmbProvider.ItemIndex < 0) or (Trim(FEditTemaProfessora.Text) = '') then
  begin
    ShowMessage('Configure o provedor/modelo e informe um tema.');
    Exit;
  end;
  FProfessora.Provider := GetAIProviderFromIndex(FCmbProvider.ItemIndex);
  FProfessora.URL := UTF8ToUTF16(Trim(FEditEndpoint.Text));
  FProfessora.CustomModel := UTF8ToUTF16(Trim(FCmbModel.Text));
  FProfessora.TOKEN := UTF8ToUTF16(Trim(FEditToken.Text));
  FProfessora.Temperature := StrToFloatDef(FEditTemperature.Text, 0.7);
  FProfessora.MaxTokens := FSpinMaxTokens.Value;
  Prompt := 'Crie exemplos corretos em português para uma IA aluna sobre: ' + FEditTemaProfessora.Text +
    '. Retorne SOMENTE um objeto JSON, sem markdown, com train e validation. ' +
    'Cada item contém question e answer, textos não vazios, resposta de até 60 tokens. ' +
    'Gere ' + IntToStr(FSpinParesProfessora.Value) + ' pares em train e pelo menos 4 em validation. ' +
    'Use perguntas distintas; validation deve testar o mesmo tema com perguntas inéditas. ' +
    'Não invente fatos. Formato: {"train":[{"question":"...","answer":"..."}],"validation":[{"question":"...","answer":"..."}]}';
  FProfessoraGerando := True;
  FBtnGerarProfessora.Enabled := False;
  FBtnTreinarProfessora.Enabled := False;
  FBtnCancelarProfessora.Enabled := True;
  FLblProfessora.Caption := 'Gerando com ' + FCmbModel.Text + '. Aguarde e revise os exemplos antes de treinar.';
  if not FProfessora.SendQuestionAsync(UTF8ToUTF16(Prompt)) then
    OnProfessoraCompleta(FProfessora, False);
end;

procedure TfrmStudio.OnCancelarProfessoraClick(Sender: TObject);
begin
  FProfessora.Cancel;
end;

procedure TfrmStudio.OnProfessoraCompleta(Sender: TObject; ASuccess: Boolean);
begin
  FProfessoraGerando := False;
  FBtnGerarProfessora.Enabled := not FIsBusy;
  FBtnTreinarProfessora.Enabled := not FIsBusy;
  FBtnCancelarProfessora.Enabled := False;
  if ASuccess then
  begin
    FMemoProfessora.Text := UTF16ToUTF8(FProfessora.Response);
    FLblProfessora.Caption := 'Exemplos recebidos. Confira os fatos e o JSON antes de clicar em Treinar. Resultados aparecerão no console inferior.';
  end
  else
    FLblProfessora.Caption := 'Geração cancelada ou falhou: ' + UTF16ToUTF8(FProfessora.LastError);
end;

procedure TfrmStudio.OnTreinarProfessoraClick(Sender: TObject);
var
  Dados: TJSONData;
  Arquivo: string;
begin
  if FIsBusy or FProfessoraGerando then Exit;
  if not SameText(ExtractFileExt(Trim(FCmbRedeAlvo.Text)), '.ngs') then
  begin
    ShowMessage('Selecione uma rede TokenGraph .ngs no topo. Esta aba não treina matrizes .ngm.');
    Exit;
  end;
  try
    Dados := GetJSON(FMemoProfessora.Text);
    try
      if Dados.JSONType <> jtObject then
        raise Exception.Create('Informe um objeto com train e validation.');
    finally
      Dados.Free;
    end;
    Arquivo := ExtractFilePath(ObterCaminhoAppTreino) + 'dados' + PathDelim + 'processados' + PathDelim + 'professora_revisado.json';
    ForceDirectories(ExtractFilePath(Arquivo));
    FMemoProfessora.Lines.SaveToFile(Arquivo);
    ExecutarComandoTreino(['--professora-dataset', Arquivo, '--professora-epocas', IntToStr(FSpinEpocasProfessora.Value)]);
  except
    on E: Exception do ShowMessage('Não foi possível iniciar: ' + E.Message);
  end;
end;

procedure TfrmStudio.ConstruirAbaTreinoContinuo;
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
  FMemoAssuntosContinuo.Left := 14;
  FMemoAssuntosContinuo.Top := 30;
  FMemoAssuntosContinuo.Width := 445;
  FMemoAssuntosContinuo.Height := 120;
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
  FEditNovoAssuntoContinuo.Left := 125;
  FEditNovoAssuntoContinuo.Top := 154;
  FEditNovoAssuntoContinuo.Width := 215;
  FEditNovoAssuntoContinuo.OnKeyPress := @OnNovoAssuntoContinuoKeyPress;

  FBtnAddAssuntoContinuo := TButton.Create(Self);
  FBtnAddAssuntoContinuo.Parent := FTabTreinoContinuo;
  FBtnAddAssuntoContinuo.Caption := '➕ Incluir';
  FBtnAddAssuntoContinuo.Left := 346;
  FBtnAddAssuntoContinuo.Top := 152;
  FBtnAddAssuntoContinuo.Width := 113;
  FBtnAddAssuntoContinuo.Height := 26;
  FBtnAddAssuntoContinuo.OnClick := @OnAddAssuntoContinuoClick;

  FBtnPadraoAssuntosContinuo := TButton.Create(Self);
  FBtnPadraoAssuntosContinuo.Parent := FTabTreinoContinuo;
  FBtnPadraoAssuntosContinuo.Caption := 'Restaurar Assuntos PT-BR';
  FBtnPadraoAssuntosContinuo.Left := 14;
  FBtnPadraoAssuntosContinuo.Top := 182;
  FBtnPadraoAssuntosContinuo.Width := 218;
  FBtnPadraoAssuntosContinuo.Height := 25;
  FBtnPadraoAssuntosContinuo.OnClick := @OnPadraoAssuntosContinuoClick;

  FBtnLimparAssuntosContinuo := TButton.Create(Self);
  FBtnLimparAssuntosContinuo.Parent := FTabTreinoContinuo;
  FBtnLimparAssuntosContinuo.Caption := '🧹 Limpar Assuntos';
  FBtnLimparAssuntosContinuo.Left := 240;
  FBtnLimparAssuntosContinuo.Top := 182;
  FBtnLimparAssuntosContinuo.Width := 219;
  FBtnLimparAssuntosContinuo.Height := 25;
  FBtnLimparAssuntosContinuo.OnClick := @OnLimparAssuntosContinuoClick;

  GrpParams := TGroupBox.Create(Self);
  GrpParams.Parent := FTabTreinoContinuo;
  GrpParams.Left := 14;
  GrpParams.Top := 212;
  GrpParams.Width := 445;
  GrpParams.Height := 92;
  GrpParams.Caption := ' Parâmetros do Ciclo Contínuo (IA + YouTube -> Equipamento .NGM) ';

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpParams;
  Lbl.Caption := 'Vídeos YT/Ciclo:';
  Lbl.Left := 10;
  Lbl.Top := 10;

  FSpinVideosPorCiclo := TSpinEdit.Create(Self);
  FSpinVideosPorCiclo.Parent := GrpParams;
  FSpinVideosPorCiclo.Left := 108;
  FSpinVideosPorCiclo.Top := 6;
  FSpinVideosPorCiclo.Width := 52;
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
  FSpinParesPorCiclo.Left := 262;
  FSpinParesPorCiclo.Top := 6;
  FSpinParesPorCiclo.Width := 58;
  FSpinParesPorCiclo.MinValue := 4;
  FSpinParesPorCiclo.MaxValue := 100;
  FSpinParesPorCiclo.Value := 12;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpParams;
  Lbl.Caption := 'Pausa (s):';
  Lbl.Left := 328;
  Lbl.Top := 10;

  FSpinIntervaloCiclo := TSpinEdit.Create(Self);
  FSpinIntervaloCiclo.Parent := GrpParams;
  FSpinIntervaloCiclo.Left := 386;
  FSpinIntervaloCiclo.Top := 6;
  FSpinIntervaloCiclo.Width := 48;
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
  FSpinMaxCiclosContinuo.Left := 152;
  FSpinMaxCiclosContinuo.Top := 38;
  FSpinMaxCiclosContinuo.Width := 58;
  FSpinMaxCiclosContinuo.MinValue := 0;
  FSpinMaxCiclosContinuo.MaxValue := 10000;
  FSpinMaxCiclosContinuo.Value := 0;

  FChkApenasPortugues := TCheckBox.Create(Self);
  FChkApenasPortugues.Parent := GrpParams;
  FChkApenasPortugues.Left := 220;
  FChkApenasPortugues.Top := 40;
  FChkApenasPortugues.Caption := 'Somente Português (PT-BR)';
  FChkApenasPortugues.Checked := True;
  FChkApenasPortugues.Font.Style := [fsBold];

  FBtnIniciarContinuo := TButton.Create(Self);
  FBtnIniciarContinuo.Parent := FTabTreinoContinuo;
  FBtnIniciarContinuo.Caption := '▶️ Iniciar Treino Contínuo (IA + YouTube PT)';
  FBtnIniciarContinuo.Left := 14;
  FBtnIniciarContinuo.Top := 310;
  FBtnIniciarContinuo.Width := 285;
  FBtnIniciarContinuo.Height := 32;
  FBtnIniciarContinuo.Font.Style := [fsBold];
  FBtnIniciarContinuo.OnClick := @OnIniciarContinuoClick;

  FBtnPararContinuo := TButton.Create(Self);
  FBtnPararContinuo.Parent := FTabTreinoContinuo;
  FBtnPararContinuo.Caption := '⏹️ Parar e Salvar';
  FBtnPararContinuo.Left := 305;
  FBtnPararContinuo.Top := 310;
  FBtnPararContinuo.Width := 154;
  FBtnPararContinuo.Height := 32;
  FBtnPararContinuo.Enabled := False;
  FBtnPararContinuo.Font.Style := [fsBold];
  FBtnPararContinuo.OnClick := @OnAbortarClick;

  FBtnRegerarNGM := TButton.Create(Self);
  FBtnRegerarNGM.Parent := FTabTreinoContinuo;
  FBtnRegerarNGM.Caption := '🔄 Regerar Matriz da IA (.NGM) dos Arquivos Existentes';
  FBtnRegerarNGM.Left := 14;
  FBtnRegerarNGM.Top := 346;
  FBtnRegerarNGM.Width := 445;
  FBtnRegerarNGM.Height := 30;
  FBtnRegerarNGM.OnClick := @OnRegerarNGMClick;

  // Painel Direito: Monitor de Ciclos Contínuos e Matriz NGM do Equipamento
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTabTreinoContinuo;
  Lbl.Caption := '📡 Monitor de Treino Contínuo & Geração de Matriz (.NGM / .NGS) em Português:';
  Lbl.Left := 472;
  Lbl.Top := 10;
  Lbl.Font.Style := [fsBold];

  FMemoMonitorContinuo := TMemo.Create(Self);
  FMemoMonitorContinuo.Parent := FTabTreinoContinuo;
  FMemoMonitorContinuo.Left := 472;
  FMemoMonitorContinuo.Top := 30;
  FMemoMonitorContinuo.Width := 512;
  FMemoMonitorContinuo.Height := 312;
  FMemoMonitorContinuo.Anchors := [akTop, akLeft, akRight, akBottom];
  FMemoMonitorContinuo.ReadOnly := True;
  FMemoMonitorContinuo.ScrollBars := ssAutoBoth;
  FMemoMonitorContinuo.Font.Name := 'Consolas';
  FMemoMonitorContinuo.Font.Size := 9;
  FMemoMonitorContinuo.Color := $F5FAF5;
  FMemoMonitorContinuo.Lines.Add('=== MODO DE TREINO CONTÍNUO (IA + YOUTUBE PT-BR) ===');
  FMemoMonitorContinuo.Lines.Add('1. Pesquisa vídeos didáticos no YouTube em Português (hl=pt&gl=BR).');
  FMemoMonitorContinuo.Lines.Add('2. Filtra títulos, legendas e perguntas/respostas estritamente em Português.');
  FMemoMonitorContinuo.Lines.Add('3. Usa a IA para gerar pares conceituais e sugerir o próximo assunto.');
  FMemoMonitorContinuo.Lines.Add('4. Treina a rede e exporta automaticamente a Matriz .NGM para o equipamento.');

  FLblStatusContinuo := TLabel.Create(Self);
  FLblStatusContinuo.Parent := FTabTreinoContinuo;
  FLblStatusContinuo.Left := 472;
  FLblStatusContinuo.Top := 350;
  FLblStatusContinuo.Anchors := [akLeft, akBottom];
  FLblStatusContinuo.Caption := 'Status Contínuo: Pronto para pesquisar (Filtro PT-BR ativo)';
  FLblStatusContinuo.Font.Style := [fsBold];
  FLblStatusContinuo.Font.Color := $006600;
end;

procedure TfrmStudio.ConstruirAbaChatGPT;
var
  GrpConfig, GrpPrompt, GrpResp: TGroupBox;
  PnlBtns: TPanel;
  Lbl: TLabel;
begin
  FTabChatGPT := CriarAba('  🤖 Provedores & Modelos (TCHATGPT)  ');

  // 1. GroupBox Configurações do Provedor e Modelo
  GrpConfig := TGroupBox.Create(Self);
  GrpConfig.Parent := FTabChatGPT;
  GrpConfig.Align := alTop;
  GrpConfig.Height := 145;
  GrpConfig.Caption := ' Configuração do Provedor, Modelos e Conexão (Componente TCHATGPT) ';

  // Linha 1: Provedor, Modelo, MaxTokens, Temp
  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Provedor:';
  Lbl.Left := 12;
  Lbl.Top := 14;

  FCmbProvider := TComboBox.Create(Self);
  FCmbProvider.Parent := GrpConfig;
  FCmbProvider.Left := 75;
  FCmbProvider.Top := 10;
  FCmbProvider.Width := 190;
  FCmbProvider.Style := csDropDownList;
  FCmbProvider.OnChange := @OnProviderChange;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Modelo:';
  Lbl.Left := 275;
  Lbl.Top := 14;

  FCmbModel := TComboBox.Create(Self);
  FCmbModel.Parent := GrpConfig;
  FCmbModel.Left := 325;
  FCmbModel.Top := 10;
  FCmbModel.Width := 340;
  FCmbModel.OnChange := @OnModelChange;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Max Tokens:';
  Lbl.Left := 675;
  Lbl.Top := 14;

  FSpinMaxTokens := TSpinEdit.Create(Self);
  FSpinMaxTokens.Parent := GrpConfig;
  FSpinMaxTokens.Left := 748;
  FSpinMaxTokens.Top := 10;
  FSpinMaxTokens.Width := 75;
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
  FEditTemperature.Left := 875;
  FEditTemperature.Top := 10;
  FEditTemperature.Width := 50;
  FEditTemperature.Text := '0.7';

  // Linha 2: URL / Endpoint e Chave Token
  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'URL / Endpoint:';
  Lbl.Left := 12;
  Lbl.Top := 46;

  FEditEndpoint := TEdit.Create(Self);
  FEditEndpoint.Parent := GrpConfig;
  FEditEndpoint.Left := 115;
  FEditEndpoint.Top := 42;
  FEditEndpoint.Width := 460;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := GrpConfig;
  Lbl.Caption := 'Token / Key:';
  Lbl.Left := 585;
  Lbl.Top := 46;

  FEditToken := TEdit.Create(Self);
  FEditToken.Parent := GrpConfig;
  FEditToken.Left := 660;
  FEditToken.Top := 42;
  FEditToken.Width := 265;
  FEditToken.EchoMode := emPassword;
  FEditToken.Text := GetEnvironmentVariable('OPENAI_API_KEY');

  // Linha 3: Barra de Ações do TCHATGPT
  PnlBtns := TPanel.Create(Self);
  PnlBtns.Parent := GrpConfig;
  PnlBtns.Left := 12;
  PnlBtns.Top := 76;
  PnlBtns.Width := 940;
  PnlBtns.Height := 38;
  PnlBtns.BevelOuter := bvNone;

  FBtnTestarConexao := TButton.Create(Self);
  FBtnTestarConexao.Parent := PnlBtns;
  FBtnTestarConexao.Caption := '🧪 Testar Conexão';
  FBtnTestarConexao.Left := 0;
  FBtnTestarConexao.Top := 4;
  FBtnTestarConexao.Width := 140;
  FBtnTestarConexao.Height := 30;
  FBtnTestarConexao.OnClick := @OnTestarConexaoClick;

  FBtnEnviarChat := TButton.Create(Self);
  FBtnEnviarChat.Parent := PnlBtns;
  FBtnEnviarChat.Caption := '▶️ Enviar Pergunta';
  FBtnEnviarChat.Left := 148;
  FBtnEnviarChat.Top := 4;
  FBtnEnviarChat.Width := 130;
  FBtnEnviarChat.Height := 30;
  FBtnEnviarChat.OnClick := @OnEnviarChatClick;

  FBtnCancelarChat := TButton.Create(Self);
  FBtnCancelarChat.Parent := PnlBtns;
  FBtnCancelarChat.Caption := '⏹️ Cancelar';
  FBtnCancelarChat.Left := 284;
  FBtnCancelarChat.Top := 4;
  FBtnCancelarChat.Width := 90;
  FBtnCancelarChat.Height := 30;
  FBtnCancelarChat.Enabled := False;
  FBtnCancelarChat.OnClick := @OnCancelarChatClick;

  FBtnAdicionarAoDataset := TButton.Create(Self);
  FBtnAdicionarAoDataset.Parent := PnlBtns;
  FBtnAdicionarAoDataset.Caption := '➕ Usar Resposta para Treino do NeuroGraph';
  FBtnAdicionarAoDataset.Left := 380;
  FBtnAdicionarAoDataset.Top := 4;
  FBtnAdicionarAoDataset.Width := 270;
  FBtnAdicionarAoDataset.Height := 30;
  FBtnAdicionarAoDataset.OnClick := @OnAdicionarAoDatasetClick;

  FLblChatState := TLabel.Create(Self);
  FLblChatState.Parent := PnlBtns;
  FLblChatState.Left := 665;
  FLblChatState.Top := 11;
  FLblChatState.Caption := 'Estado: Aguardando (Idle)';
  FLblChatState.Font.Style := [fsBold];

  // 2. GroupBox Prompt (Pergunta)
  GrpPrompt := TGroupBox.Create(Self);
  GrpPrompt.Parent := FTabChatGPT;
  GrpPrompt.Align := alTop;
  GrpPrompt.Height := 110;
  GrpPrompt.Caption := ' Prompt / Pergunta para o Modelo ';

  FMemoPromptChat := TMemo.Create(Self);
  FMemoPromptChat.Parent := GrpPrompt;
  FMemoPromptChat.Align := alClient;
  FMemoPromptChat.ScrollBars := ssAutoVertical;
  FMemoPromptChat.Text := 'Explique em duas frases: o que é energia solar fotovoltaica?';

  // 3. GroupBox Resposta
  GrpResp := TGroupBox.Create(Self);
  GrpResp.Parent := FTabChatGPT;
  GrpResp.Align := alClient;
  GrpResp.Caption := ' Resposta Retornada pela IA (Streaming / Direta) ';

  FMemoRespChat := TMemo.Create(Self);
  FMemoRespChat.Parent := GrpResp;
  FMemoRespChat.Align := alClient;
  FMemoRespChat.ReadOnly := True;
  FMemoRespChat.ScrollBars := ssAutoBoth;
  FMemoRespChat.Font.Name := 'Segoe UI';
  FMemoRespChat.Font.Size := 10;

  PopularProvedores;
end;

procedure TfrmStudio.PopularProvedores;
var
  P: TAIProvider;
begin
  FCmbProvider.Items.Clear;
  for P := Low(TAIProvider) to High(TAIProvider) do
    FCmbProvider.Items.Add(GetAIProviderName(P));

  FCmbProvider.ItemIndex := 0; // OpenAI por padrão
  OnProviderChange(nil);
end;

procedure TfrmStudio.OnProviderChange(Sender: TObject);
var
  ProvIdx: Integer;
  Prov: TAIProvider;
  ProvCatalogName: string;
  ModelList: TStringList;
  DefModel: string;
begin
  ProvIdx := FCmbProvider.ItemIndex;
  if ProvIdx < 0 then Exit;

  Prov := GetAIProviderFromIndex(ProvIdx);
  ProvCatalogName := GetAIProviderCatalogName(Prov);

  // 1. Atualiza endpoint padrão do provedor
  FEditEndpoint.Text := GetDefaultEndpointForProvider(Prov);

  // 2. Carrega todos os modelos oficiais associados a este provedor pelo catálogo
  ModelList := TStringList.Create;
  try
    GetAILLMModelsForProvider(ProvCatalogName, ModelList, True);

    FCmbModel.Items.Clear;
    FCmbModel.Items.Assign(ModelList);

    // Se o catálogo não listar modelos para provedores customizados, adiciona sugestões
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
end;

procedure TfrmStudio.OnModelChange(Sender: TObject);
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
end;

procedure TfrmStudio.OnTestarConexaoClick(Sender: TObject);
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

procedure TfrmStudio.OnEnviarChatClick(Sender: TObject);
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

procedure TfrmStudio.OnCancelarChatClick(Sender: TObject);
begin
  FChatGPT.Cancel;
  FBtnCancelarChat.Enabled := False;
  FLblChatState.Caption := 'Estado: Cancelado';
end;

procedure TfrmStudio.OnChatStreamStart(Sender: TObject);
begin
  if not FIsTestingConnection then
    FMemoRespChat.Clear;
end;

procedure TfrmStudio.OnChatStreamData(Sender: TObject; const AData: WideString);
begin
  FMemoRespChat.SelStart := Length(FMemoRespChat.Text);
  FMemoRespChat.SelText := UTF16ToUTF8(AData);
end;

procedure TfrmStudio.OnChatStreamEnd(Sender: TObject);
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

procedure TfrmStudio.OnChatStateChange(Sender: TObject; AState: TAILLMRequestState);
begin
  case AState of
    lrsIdle:
    begin
      FLblChatState.Caption := 'Estado: Aguardando (Idle)';
      FLblChatState.Font.Color := clDefault;
    end;
    lrsConnecting:
    begin
      FLblChatState.Caption := 'Estado: Conectando ao Provedor...';
      FLblChatState.Font.Color := $000088DD;
    end;
    lrsReceiving:
    begin
      FLblChatState.Caption := 'Estado: Recebendo Resposta...';
      FLblChatState.Font.Color := clBlue;
    end;
    lrsCompleted:
    begin
      FLblChatState.Caption := 'Estado: Concluído com Sucesso!';
      FLblChatState.Font.Color := clGreen;
    end;
    lrsCancelled:
    begin
      FLblChatState.Caption := 'Estado: Cancelado';
      FLblChatState.Font.Color := clMaroon;
    end;
    lrsError:
    begin
      FLblChatState.Caption := 'Estado: Erro na Requisição';
      FLblChatState.Font.Color := clRed;
    end;
  end;
end;

procedure TfrmStudio.OnChatRequestComplete(Sender: TObject; ASuccess: Boolean);
begin
  FBtnTestarConexao.Enabled := True;
  FBtnEnviarChat.Enabled := True;
  FBtnCancelarChat.Enabled := False;

  if not ASuccess then
  begin
    FMemoRespChat.Lines.Add('');
    FMemoRespChat.Lines.Add('[ERRO NA REQUISIÇÃO] ' + UTF16ToUTF8(FChatGPT.LastError));
  end;
end;

procedure TfrmStudio.OnAdicionarAoDatasetClick(Sender: TObject);
var
  Pergunta, Resposta: string;
  CaminhoJson: string;
  F: TFileStream;
  Parser: TJSONParser;
  Data: TJSONData;
  Arr: TJSONArray;
  NovoItem: TJSONObject;
begin
  Pergunta := Trim(FMemoPromptChat.Text);
  Resposta := Trim(FMemoRespChat.Text);

  if (Pergunta = '') or (Resposta = '') then
  begin
    ShowMessage('É necessário ter uma pergunta e uma resposta válidas para adicionar ao dataset.');
    Exit;
  end;

  CaminhoJson := ExtractFilePath(ObterCaminhoAppTreino) + 'dados\processados\dataset_curado.json';
  Arr := nil;

  if FileExists(CaminhoJson) then
  begin
    try
      F := TFileStream.Create(CaminhoJson, fmOpenReadWrite or fmShareDenyNone);
      try
        Parser := TJSONParser.Create(F);
        try
          Data := Parser.Parse;
          if Assigned(Data) and (Data.JSONType = jtArray) then
            Arr := TJSONArray(Data);
        finally
          Parser.Free;
        end;
      finally
        F.Free;
      end;
    except
      Arr := nil;
    end;
  end;

  if not Assigned(Arr) then
    Arr := TJSONArray.Create;

  try
    NovoItem := TJSONObject.Create;
    NovoItem.Add('question', LowerCase(Pergunta));
    NovoItem.Add('answer', LowerCase(Resposta));
    NovoItem.Add('context', TJSONArray.Create);
    NovoItem.Add('category', 'chatgpt_direct');
    NovoItem.Add('origem', FCmbModel.Text);
    Arr.Add(NovoItem);

    ForceDirectories(ExtractFilePath(CaminhoJson));
    F := TFileStream.Create(CaminhoJson, fmCreate);
    try
      F.WriteBuffer(Arr.FormatJSON[1], Length(Arr.FormatJSON));
    finally
      F.Free;
    end;

    ShowMessage('Fato adicionado com sucesso ao dataset do NeuroGraph!');
    OnAtualizarDatasetClick(nil);

  finally
    Arr.Free;
  end;
end;

function TfrmStudio.CriarAba(const ATitulo: string): TTabSheet;
begin
  Result := TTabSheet.Create(FPageControl);
  Result.PageControl := FPageControl;
  Result.Caption := ATitulo;
end;

procedure TfrmStudio.GerarIconesEstado;
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

  // Estado Parado (Azul Escuro / Ciano)
  DesenharIcone(FIconIdle, $00662B00, $00CC8800, clWhite, $00FFCC44, False);
  // Estado Treinando Pulso A (Verde Vibrante + Amarelo)
  DesenharIcone(FIconTrainA, $00187A00, $0044FF00, clWhite, $0000FFFF, True);
  // Estado Treinando Pulso B (Laranja / Âmbar Vibrante + Branco)
  DesenharIcone(FIconTrainB, $000055CC, $0000A5FF, $0000FFFF, clWhite, True);
end;

procedure TfrmStudio.BuildTraySystem;
var
  Sep1, Sep2: TMenuItem;
begin
  GerarIconesEstado;

  FTrayPopup := TPopupMenu.Create(Self);

  FMnuRestaurar := TMenuItem.Create(Self);
  FMnuRestaurar.Caption := 'Abrir / Restaurar NeuroGraph Studio';
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
  FMnuIniciarContinuoTray.Caption := '▶ Iniciar Treino Contínuo (IA + YouTube PT-BR)';
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
  FTrayIcon.Hint := 'NeuroGraph Studio — Pronto (Parado)';
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

procedure TfrmStudio.AtualizarIconeRelogio;
var
  TextoStatus: string;
begin
  if not Assigned(FTrayIcon) then Exit;

  if FIsBusy then
  begin
    if FLastTrayStepText <> '' then
      TextoStatus := '⚡ TREINANDO: ' + Copy(FLastTrayStepText, 1, 90)
    else
      TextoStatus := '⚡ NeuroGraph Studio — TREINANDO REDE NEURAL...';

    FTrayIcon.Hint := Copy(TextoStatus, 1, 120);
    if Assigned(FMnuStatusTray) then
      FMnuStatusTray.Caption := TextoStatus;
    if Assigned(FMnuIniciarContinuoTray) then
      FMnuIniciarContinuoTray.Enabled := False;
    if Assigned(FMnuIniciarTopicosTray) then
      FMnuIniciarTopicosTray.Enabled := False;
    if Assigned(FMnuPararTray) then
      FMnuPararTray.Enabled := True;

    if FTrayPulseToggle then
    begin
      FTrayIcon.Icon.Assign(FIconTrainA);
      Self.Icon.Assign(FIconTrainA);
      if Assigned(FShapeStatusTreino) then
        FShapeStatusTreino.Brush.Color := $0000CC00;
    end
    else
    begin
      FTrayIcon.Icon.Assign(FIconTrainB);
      Self.Icon.Assign(FIconTrainB);
      if Assigned(FShapeStatusTreino) then
        FShapeStatusTreino.Brush.Color := $000088FF;
    end;

    if Assigned(FLblStatusTreinoBarra) then
    begin
      FLblStatusTreinoBarra.Caption := TextoStatus;
      FLblStatusTreinoBarra.Font.Color := $00007700;
    end;
    Caption := '⚡ [TREINANDO] NeuroGraph Studio — Treinador & Curador';
  end
  else
  begin
    FTrayIcon.Icon.Assign(FIconIdle);
    Self.Icon.Assign(FIconIdle);
    FTrayIcon.Hint := 'NeuroGraph Studio — Pronto (Parado)';
    if Assigned(FMnuStatusTray) then
      FMnuStatusTray.Caption := 'Estado: Pronto (Parado)';
    if Assigned(FMnuIniciarContinuoTray) then
      FMnuIniciarContinuoTray.Enabled := True;
    if Assigned(FMnuIniciarTopicosTray) then
      FMnuIniciarTopicosTray.Enabled := True;
    if Assigned(FMnuPararTray) then
      FMnuPararTray.Enabled := False;
    if Assigned(FShapeStatusTreino) then
      FShapeStatusTreino.Brush.Color := $00AA5500;
    if Assigned(FLblStatusTreinoBarra) then
    begin
      FLblStatusTreinoBarra.Caption := 'Ícone no Relógio Ativo — Estado: Pronto (Parado)';
      FLblStatusTreinoBarra.Font.Color := $00663300;
    end;
    Caption := 'NeuroGraph Studio — Treinador & Curador (Lazarus Desktop)';
  end;
end;

procedure TfrmStudio.OnTrayTimerTick(Sender: TObject);
begin
  FTrayPulseToggle := not FTrayPulseToggle;
  AtualizarIconeRelogio;
end;

procedure TfrmStudio.OnTrayIconClick(Sender: TObject);
begin
  OnRestaurarDoRelogioClick(Sender);
end;

procedure TfrmStudio.OnMinimizarParaRelogioClick(Sender: TObject);
begin
  Hide;
  if Assigned(FTrayIcon) then
  begin
    FTrayIcon.Visible := True;
    FTrayIcon.BalloonTitle := 'NeuroGraph Studio no Relógio';
    if FIsBusy then
      FTrayIcon.BalloonHint := 'O treinamento continua rodando em segundo plano! Clique no ícone perto do relógio para reabrir.'
    else
      FTrayIcon.BalloonHint := 'NeuroGraph Studio está na bandeja perto do relógio. Clique no ícone para reabrir.';
    FTrayIcon.ShowBalloonHint;
  end;
end;

procedure TfrmStudio.OnRestaurarDoRelogioClick(Sender: TObject);
begin
  Show;
  WindowState := wsNormal;
  BringToFront;
end;

procedure TfrmStudio.OnSairPeloRelogioClick(Sender: TObject);
begin
  if FIsBusy then
    OnAbortarClick(Sender);
  Close;
end;

procedure TfrmStudio.OnFormWindowStateChange(Sender: TObject);
begin
  if WindowState = wsMinimized then
    OnMinimizarParaRelogioClick(Sender);
end;

procedure TfrmStudio.LogMsg(const AMsg: string);
begin
  FMemoLog.Lines.Add(AMsg);
  FMemoLog.SelStart := Length(FMemoLog.Text);

  if FIsBusy and ((Pos('[TREINADO]', AMsg) > 0) or (Pos('[CICLO', AMsg) > 0) or
     (Pos('[Tópico', AMsg) > 0) or (Pos('[CONSOLIDAÇÃO', AMsg) > 0)) then
  begin
    FLastTrayStepText := Trim(AMsg);
    AtualizarIconeRelogio;
  end;

  if Assigned(FMemoResultadoTopicos) and FIsBusy then
  begin
    if (Pos('[Tópico', AMsg) > 0) or (Pos('[TREINADO]', AMsg) > 0) or
       (Pos('-> ', AMsg) > 0) or (Pos('[REDE SALVA', AMsg) > 0) or
       (Pos('[PARADA', AMsg) > 0) or (Pos('REDE ALVO', AMsg) > 0) or
       (Pos('CONSOLIDAÇÃO', AMsg) > 0) or (Pos('STATUS ', AMsg) > 0) then
    begin
      FMemoResultadoTopicos.Lines.Add(AMsg);
      FMemoResultadoTopicos.SelStart := Length(FMemoResultadoTopicos.Text);
    end;
    if Pos('[TREINADO]', AMsg) > 0 then
    begin
      FLblResumoTopicos.Caption := '⚡ ' + Trim(AMsg);
      AtualizarStatusGeral;
    end;
  end;

  if Assigned(FMemoMonitorContinuo) and FIsBusy then
  begin
    if (Pos('[CICLO', AMsg) > 0) or (Pos('[YOUTUBE-PT]', AMsg) > 0) or
       (Pos('[IA-PT]', AMsg) > 0) or (Pos('[MATRIZ NGM', AMsg) > 0) or
       (Pos('[REGERAÇÃO', AMsg) > 0) or (Pos('[TREINADO]', AMsg) > 0) or
       (Pos('-> [PT-BR]', AMsg) > 0) or (Pos('-> [YT]', AMsg) > 0) or
       (Pos('-> [IA]', AMsg) > 0) or (Pos('TREINO CONTÍNUO', AMsg) > 0) or
       (Pos('[CONSOLIDAÇÃO', AMsg) > 0) or (Pos('[CONCLUÍDO]', AMsg) > 0) then
    begin
      FMemoMonitorContinuo.Lines.Add(AMsg);
      FMemoMonitorContinuo.SelStart := Length(FMemoMonitorContinuo.Text);
    end;
    if (Pos('[CICLO', AMsg) > 0) or (Pos('[TREINADO]', AMsg) > 0) or (Pos('[MATRIZ NGM', AMsg) > 0) then
    begin
      FLblStatusContinuo.Caption := '⚡ ' + Trim(AMsg);
      AtualizarStatusGeral;
    end;
  end;

  Application.ProcessMessages;
end;

procedure TfrmStudio.SetBusy(const ABusy: Boolean);
begin
  FIsBusy := ABusy;
  if Assigned(FBtnGerarProfessora) then
    FBtnGerarProfessora.Enabled := not ABusy and not FProfessoraGerando;
  if Assigned(FBtnTreinarProfessora) then
    FBtnTreinarProfessora.Enabled := not ABusy and not FProfessoraGerando;
  FBtnBuscarYouTube.Enabled := not ABusy;
  FBtnProcessarVideo.Enabled := not ABusy;
  FBtnProcessarPDF.Enabled := not ABusy;
  FBtnGerar10Topicos.Enabled := not ABusy;
  FBtnAdicionarTopico.Enabled := True;
  FBtnPararTreinoTopicos.Enabled := ABusy;
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
    if Assigned(FTrayTimer) then
      FTrayTimer.Enabled := True;
    AtualizarIconeRelogio;
    if Assigned(FTrayIcon) then
    begin
      FTrayIcon.BalloonTitle := '⚡ NeuroGraph: Treinamento Iniciado';
      FTrayIcon.BalloonHint := 'A rede neural está treinando. O ícone perto do relógio pisca em verde/laranja enquanto treina.';
      FTrayIcon.ShowBalloonHint;
    end;
    FProgressBar.Style := pbstMarquee;
    Screen.Cursor := crHourGlass;
  end
  else
  begin
    if Assigned(FTrayTimer) then
      FTrayTimer.Enabled := False;
    FLastTrayStepText := '';
    AtualizarIconeRelogio;
    if Assigned(FTrayIcon) then
    begin
      FTrayIcon.BalloonTitle := '✔ NeuroGraph: Treinamento Finalizado e Salvo';
      FTrayIcon.BalloonHint := 'Os pesos da rede neural foram atualizados e salvos com sucesso.';
      FTrayIcon.ShowBalloonHint;
    end;
    FProgressBar.Style := pbstNormal;
    FProgressBar.Position := 0;
    Screen.Cursor := crDefault;
    AtualizarStatusGeral;
  end;
  Application.ProcessMessages;
end;

function TfrmStudio.ObterCaminhoAppTreino: string;
var
  BaseDir: string;
begin
  BaseDir := ExtractFilePath(ParamStr(0));
  if FileExists(BaseDir + 'app_treino.py') then
    Exit(BaseDir + 'app_treino.py');
  if FileExists(BaseDir + '..\app_treino.py') then
    Exit(ExpandFileName(BaseDir + '..\app_treino.py'));
  if FileExists(BaseDir + '..\treino\app_treino.py') then
    Exit(ExpandFileName(BaseDir + '..\treino\app_treino.py'));
  Result := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\treino\app_treino.py';
end;

function TfrmStudio.ObterPythonExe: string;
begin
  Result := 'python.exe';
end;

procedure TfrmStudio.AtualizarStatusGeral;
var
  CaminhoModelo: string;
  Info: TSearchRec;
  TamMB: Double;
begin
  if Trim(FEditApiKey.Text) <> '' then
  begin
    FLblApiStatus.Caption := '● OpenAI Ativa';
    FLblApiStatus.Font.Color := clGreen;
  end
  else if Assigned(FEditEndpoint) and (Trim(FEditEndpoint.Text) <> '') and
          (Pos('api.openai.com', LowerCase(FEditEndpoint.Text)) = 0) then
  begin
    FLblApiStatus.Caption := '● IA Configurada (' + Trim(FCmbModel.Text) + ')';
    FLblApiStatus.Font.Color := clGreen;
  end
  else
  begin
    FLblApiStatus.Caption := '○ Modo Heurístico Local';
    FLblApiStatus.Font.Color := $000088DD;
  end;

  if Assigned(FCmbRedeAlvo) and (Trim(FCmbRedeAlvo.Text) <> '') then
    CaminhoModelo := Trim(FCmbRedeAlvo.Text)
  else
    CaminhoModelo := ExtractFilePath(ObterCaminhoAppTreino) + 'modelos\neurograph_youtube.ngs';

  if FileExists(CaminhoModelo) and (FindFirst(CaminhoModelo, faAnyFile, Info) = 0) then
  begin
    TamMB := Info.Size / (1024 * 1024);
    FLblModelStatus.Caption := Format('Rede Alvo: %s (%.2f MB)', [ExtractFileName(CaminhoModelo), TamMB]);
    FLblModelStatus.Font.Color := $007000;
    FindClose(Info);
  end
  else
  begin
    FLblModelStatus.Caption := 'Rede Alvo: Nova / Não compilada';
    FLblModelStatus.Font.Color := clNavy;
  end;
end;

procedure TfrmStudio.ExecutarComandoTreino(const AParametros: array of string);
var
  P: TProcess;
  Buffer: array[0..2047] of Byte;
  BytesRead: Integer;
  LinhaAcumulada: string;
  I: Integer;
  AppScript: string;
begin
  if FIsBusy then Exit;
  AppScript := ObterCaminhoAppTreino;
  if not FileExists(AppScript) then
  begin
    ShowMessage('Arquivo de treinamento app_treino.py não encontrado em: ' + AppScript);
    Exit;
  end;

  SetBusy(True);
  FAbortRequested := False;
  LinhaAcumulada := '';

  // Remove arquivo antigo de parada se existir antes de iniciar novo treino
  if FileExists(ExtractFilePath(AppScript) + '.stop_training') then
  begin
    try
      DeleteFile(ExtractFilePath(AppScript) + '.stop_training');
    except
    end;
  end;

  if Assigned(FMemoResultadoTopicos) then
  begin
    FMemoResultadoTopicos.Clear;
    FMemoResultadoTopicos.Lines.Add('=== TREINAMENTO EM EXECUÇÃO ===');
    if Assigned(FCmbRedeAlvo) then
      FMemoResultadoTopicos.Lines.Add('Rede Alvo: ' + FCmbRedeAlvo.Text);
    FMemoResultadoTopicos.Lines.Add('------------------------------------------------------------');
  end;

  P := TProcess.Create(nil);
  FCurrentProcess := P;
  try
    P.Executable := ObterPythonExe;
    P.Parameters.Add('-X');
    P.Parameters.Add('utf8');
    P.Parameters.Add('-u');
    P.Parameters.Add(AppScript);

    for I := Low(AParametros) to High(AParametros) do
      P.Parameters.Add(AParametros[I]);

    if Assigned(FCmbRedeAlvo) and (Trim(FCmbRedeAlvo.Text) <> '') then
    begin
      P.Parameters.Add('--modelo');
      P.Parameters.Add(Trim(FCmbRedeAlvo.Text));
    end;

    if Trim(FEditApiKey.Text) <> '' then
    begin
      P.Parameters.Add('--api-key');
      P.Parameters.Add(Trim(FEditApiKey.Text));
    end;

    P.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    P.CurrentDirectory := ExtractFilePath(AppScript);

    LogMsg('------------------------------------------------------------');
    LogMsg('Iniciando: ' + P.Executable + ' ' + AppScript);
    P.Execute;

    while P.Running or (P.Output.NumBytesAvailable > 0) do
    begin
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
      Sleep(20);
      Application.ProcessMessages;
    end;

    if Trim(LinhaAcumulada) <> '' then
      LogMsg(TrimRight(LinhaAcumulada));

    LogMsg(Format('Processo concluído com código de saída: %d', [P.ExitStatus]));
    LogMsg('------------------------------------------------------------');

  finally
    FCurrentProcess := nil;
    P.Free;
    SetBusy(False);
    OnAtualizarDatasetClick(nil);
    AtualizarResultadoTopicos;
  end;
end;

procedure TfrmStudio.OnBuscarYouTubeClick(Sender: TObject);
var
  Tema: string;
begin
  Tema := Trim(FEditTema.Text);
  if Tema = '' then
  begin
    ShowMessage('Informe um tema para busca.');
    Exit;
  end;
  ExecutarComandoTreino(['--tema', Tema, '--max-videos', IntToStr(FSpinQtdVideos.Value)]);
end;

procedure TfrmStudio.OnProcessarVideoClick(Sender: TObject);
var
  Url: string;
begin
  Url := Trim(FEditVideoUrl.Text);
  if Url = '' then
  begin
    ShowMessage('Informe a URL ou ID do vídeo.');
    Exit;
  end;
  ExecutarComandoTreino(['--video', Url]);
end;

procedure TfrmStudio.OnProcurarPDFClick(Sender: TObject);
begin
  if FOpenDialogPDF.Execute then
    FEditCaminhoPDF.Text := FOpenDialogPDF.FileName;
end;

procedure TfrmStudio.OnProcessarPDFClick(Sender: TObject);
var
  CaminhoPDF: string;
begin
  CaminhoPDF := Trim(FEditCaminhoPDF.Text);
  if (CaminhoPDF = '') or not FileExists(CaminhoPDF) then
  begin
    ShowMessage('Selecione um arquivo PDF válido.');
    Exit;
  end;
  ExecutarComandoTreino(['--pdf', CaminhoPDF, '--max-pares', IntToStr(FSpinMaxParesPDF.Value)]);
end;

procedure TfrmStudio.OnAdicionarTopicoClick(Sender: TObject);
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

procedure TfrmStudio.OnLimparTopicosClick(Sender: TObject);
begin
  FMemoTopicos.Clear;
  SalvarConfiguracoes;
  LogMsg('[INFO] Lista de tópicos limpa e salva.');
end;

procedure TfrmStudio.OnTopicosPadraoClick(Sender: TObject);
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

procedure TfrmStudio.OnIniciarContinuoClick(Sender: TObject);
var
  Params: array of string;
  i, CountAssuntos: Integer;
  Linha: string;
begin
  SalvarConfiguracoes;
  CountAssuntos := 0;
  for i := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
    if Trim(FMemoAssuntosContinuo.Lines[i]) <> '' then
      Inc(CountAssuntos);

  if CountAssuntos = 0 then
    OnPadraoAssuntosContinuoClick(nil);

  SalvarConfiguracoes;

  CountAssuntos := 0;
  for i := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
    if Trim(FMemoAssuntosContinuo.Lines[i]) <> '' then
      Inc(CountAssuntos);

  if Assigned(FMemoMonitorContinuo) then
  begin
    FMemoMonitorContinuo.Clear;
    FMemoMonitorContinuo.Lines.Add('=== INICIANDO TREINO CONTÍNUO (IA + YOUTUBE PT-BR) ===');
    FMemoMonitorContinuo.Lines.Add('Rede Alvo (.ngs / .ngm): ' + FCmbRedeAlvo.Text);
    FMemoMonitorContinuo.Lines.Add('Filtro de Idioma: SOMENTE PORTUGUÊS (PT-BR / PT)');
    FMemoMonitorContinuo.Lines.Add('------------------------------------------------------------');
  end;

  SetLength(Params, 10 + CountAssuntos);
  Params[0] := '--continuo';
  Params[1] := '--videos-ciclo';
  Params[2] := IntToStr(FSpinVideosPorCiclo.Value);
  Params[3] := '--pares-ciclo';
  Params[4] := IntToStr(FSpinParesPorCiclo.Value);
  Params[5] := '--intervalo-ciclo';
  Params[6] := IntToStr(FSpinIntervaloCiclo.Value);
  Params[7] := '--max-ciclos';
  Params[8] := IntToStr(FSpinMaxCiclosContinuo.Value);
  Params[9] := '--assuntos-continuo';

  CountAssuntos := 0;
  for i := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
  begin
    Linha := Trim(FMemoAssuntosContinuo.Lines[i]);
    if Linha <> '' then
    begin
      Params[10 + CountAssuntos] := Linha;
      Inc(CountAssuntos);
    end;
  end;

  LogMsg(Format('[TREINO CONTÍNUO] Iniciando com %d assuntos-semente em Português...', [CountAssuntos]));
  ExecutarComandoTreino(Params);
end;

procedure TfrmStudio.OnRegerarNGMClick(Sender: TObject);
begin
  if Assigned(FMemoMonitorContinuo) then
  begin
    FMemoMonitorContinuo.Clear;
    FMemoMonitorContinuo.Lines.Add('=== REGERANDO MATRIZES DA IA (.NGM E .NGS) ===');
    FMemoMonitorContinuo.Lines.Add('Consolidando todos os arquivos existentes em Português e adaptando à nova arquitetura...');
    FMemoMonitorContinuo.Lines.Add('------------------------------------------------------------');
  end;
  LogMsg('[REGERAR NGM] Consolidando arquivos existentes e regerando matrizes .NGM / .NGS...');
  ExecutarComandoTreino(['--regerar-ngm']);
  PopularRedesDisponiveis;
end;

procedure TfrmStudio.OnAddAssuntoContinuoClick(Sender: TObject);
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

procedure TfrmStudio.OnPadraoAssuntosContinuoClick(Sender: TObject);
begin
  if not Assigned(FMemoAssuntosContinuo) then Exit;
  FMemoAssuntosContinuo.Clear;
  FMemoAssuntosContinuo.Lines.Add('Inteligência Artificial e Aprendizado de Máquina');
  FMemoAssuntosContinuo.Lines.Add('Eletrônica Embarcada e Microcontroladores');
  FMemoAssuntosContinuo.Lines.Add('Energia Solar Fotovoltaica e Inversores');
  FMemoAssuntosContinuo.Lines.Add('Automação Industrial e Sensores');
  FMemoAssuntosContinuo.Lines.Add('Ciência da Computação e Estruturas de Dados');
  FMemoAssuntosContinuo.Lines.Add('Física Eletromagnética e Circuitos Elétricos');
  FMemoAssuntosContinuo.Lines.Add('Biologia Celular, Genética e Biotecnologia');
  FMemoAssuntosContinuo.Lines.Add('Astronomia, Astrofísica e Exploração Espacial');
  FMemoAssuntosContinuo.Lines.Add('História e Geografia do Brasil');
  FMemoAssuntosContinuo.Lines.Add('Matemática Aplicada, Estatística e Probabilidade');
  FMemoAssuntosContinuo.Lines.Add('Redes de Computadores e Segurança da Informação');
  FMemoAssuntosContinuo.Lines.Add('Robótica, Controle e Sistemas Embarcados');
  if FConfigLoaded then
  begin
    SalvarConfiguracoes;
    LogMsg('[INFO] Assuntos PT-BR padrão restaurados e salvos.');
  end;
end;

procedure TfrmStudio.OnLimparAssuntosContinuoClick(Sender: TObject);
begin
  if Assigned(FMemoAssuntosContinuo) then
  begin
    FMemoAssuntosContinuo.Clear;
    SalvarConfiguracoes;
    LogMsg('[INFO] Lista de assuntos do Treino Contínuo limpa e salva.');
  end;
end;

procedure TfrmStudio.PopularRedesDisponiveis;
var
  Pastas: array[0..4] of string;
  i: Integer;
  SR: TSearchRec;
  Pasta, CaminhoPadrao: string;
begin
  FCmbRedeAlvo.Items.Clear;

  Pastas[0] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\treino\modelos';
  Pastas[1] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph';
  Pastas[2] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\results';
  Pastas[3] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\baseline_v6';
  Pastas[4] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\history\2026-11-12';

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

  CaminhoPadrao := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\treino\modelos\neurograph_youtube.ngs';
  if FCmbRedeAlvo.Items.IndexOf(CaminhoPadrao) < 0 then
    FCmbRedeAlvo.Items.Insert(0, CaminhoPadrao);

  if FCmbRedeAlvo.Items.Count > 0 then
  begin
    FCmbRedeAlvo.ItemIndex := 0;
    OnCmbRedeAlvoChange(FCmbRedeAlvo);
  end;
end;

procedure TfrmStudio.OnProcurarRedeAlvoClick(Sender: TObject);
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

procedure TfrmStudio.OnCmbRedeAlvoChange(Sender: TObject);
begin
  AtualizarStatusGeral;
  if FConfigLoaded then
    SalvarConfiguracoes;
end;

procedure TfrmStudio.OnGerar10TopicosClick(Sender: TObject);
var
  Params: array of string;
  i, TopicosCount: Integer;
  Linha: string;
begin
  SalvarConfiguracoes;
  // Filtra linhas não vazias
  TopicosCount := 0;
  for i := 0 to FMemoTopicos.Lines.Count - 1 do
    if Trim(FMemoTopicos.Lines[i]) <> '' then
      Inc(TopicosCount);

  if TopicosCount = 0 then
  begin
    ShowMessage('A lista de tópicos está vazia. Adicione ao menos um tópico ou restaure os 10 padrão.');
    Exit;
  end;

  SetLength(Params, 4 + TopicosCount);
  Params[0] := '--topicos-10';
  Params[1] := '--min-pares';
  Params[2] := IntToStr(FSpinMinParesTopicos.Value);
  Params[3] := '--lista-topicos';

  TopicosCount := 0;
  for i := 0 to FMemoTopicos.Lines.Count - 1 do
  begin
    Linha := Trim(FMemoTopicos.Lines[i]);
    if Linha <> '' then
    begin
      Params[4 + TopicosCount] := Linha;
      Inc(TopicosCount);
    end;
  end;

  LogMsg(Format('Iniciando geração para %d tópicos (meta mínima: %d pares)...', [TopicosCount, FSpinMinParesTopicos.Value]));
  ExecutarComandoTreino(Params);
end;

procedure TfrmStudio.OnPerguntarClick(Sender: TObject);
var
  Pergunta, AppScript, Saida: string;
  P: TProcess;
  Buffer: array[0..2047] of Byte;
  BytesRead: Integer;
begin
  Pergunta := Trim(FEditPergunta.Text);
  if Pergunta = '' then Exit;

  AppScript := ObterCaminhoAppTreino;
  if not FileExists(AppScript) then
  begin
    ShowMessage('app_treino.py não encontrado.');
    Exit;
  end;

  FMemoChat.Lines.Add('Você: ' + Pergunta);
  Application.ProcessMessages;

  Saida := '';
  P := TProcess.Create(nil);
  try
    P.Executable := ObterPythonExe;
    P.Parameters.Add('-X');
    P.Parameters.Add('utf8');
    P.Parameters.Add('-u');
    P.Parameters.Add(AppScript);
    P.Parameters.Add('--perguntar');
    P.Parameters.Add(Pergunta);
    P.Options := [poUsePipes, poStderrToOutPut, poNoConsole];
    P.CurrentDirectory := ExtractFilePath(AppScript);
    P.Execute;

    while P.Running or (P.Output.NumBytesAvailable > 0) do
    begin
      while P.Output.NumBytesAvailable > 0 do
      begin
        BytesRead := P.Output.Read(Buffer, SizeOf(Buffer) - 1);
        if BytesRead > 0 then
        begin
          Buffer[BytesRead] := 0;
          Saida := Saida + StrPas(PChar(@Buffer[0]));
        end;
      end;
      Sleep(10);
      Application.ProcessMessages;
    end;

    FMemoChat.Lines.Add(Trim(Saida));
    FMemoChat.Lines.Add('');
    FMemoChat.SelStart := Length(FMemoChat.Text);
    FEditPergunta.Text := '';

  finally
    P.Free;
  end;
end;

procedure TfrmStudio.OnPerguntaKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    OnPerguntarClick(Sender);
  end;
end;

procedure TfrmStudio.OnAtualizarDatasetClick(Sender: TObject);
var
  CaminhoJson: string;
  F: TFileStream;
  Parser: TJSONParser;
  Data: TJSONData;
  Arr: TJSONArray;
  Item: TJSONObject;
  I: Integer;
begin
  CaminhoJson := ExtractFilePath(ObterCaminhoAppTreino) + 'dados\processados\dataset_curado.json';
  FMemoDataset.Clear;

  if not FileExists(CaminhoJson) then
  begin
    FLblTotalDataset.Caption := 'Total de Fatos: 0';
    FMemoDataset.Lines.Add('Nenhum dataset curado encontrado ainda.');
    Exit;
  end;

  try
    F := TFileStream.Create(CaminhoJson, fmOpenRead or fmShareDenyNone);
    try
      Parser := TJSONParser.Create(F);
      try
        Data := Parser.Parse;
        if Assigned(Data) and (Data.JSONType = jtArray) then
        begin
          Arr := TJSONArray(Data);
          FLblTotalDataset.Caption := Format('Total de Fatos: %d', [Arr.Count]);
          for I := 0 to Arr.Count - 1 do
          begin
            Item := TJSONObject(Arr.Items[I]);
            FMemoDataset.Lines.Add(Format('[#%d] %s', [I + 1, Item.Get('question', '')]));
            FMemoDataset.Lines.Add('     -> ' + Item.Get('answer', ''));
            FMemoDataset.Lines.Add(Format('     (Origem: %s | Categoria: %s)', [Item.Get('origem', ''), Item.Get('category', '')]));
            FMemoDataset.Lines.Add('');
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
      FMemoDataset.Lines.Add('Erro ao carregar dataset: ' + E.Message);
  end;
  AtualizarResultadoTopicos;
end;

procedure TfrmStudio.AtualizarResultadoTopicos;
var
  CaminhoJson: string;
  F: TFileStream;
  Parser: TJSONParser;
  Data: TJSONData;
  Arr: TJSONArray;
  Item: TJSONObject;
  I, Limite, Inicio: Integer;
  TopicoAtual, UltimoTopico: string;
begin
  if not Assigned(FMemoResultadoTopicos) then Exit;

  CaminhoJson := ExtractFilePath(ObterCaminhoAppTreino) + 'dados\processados\ultimo_treino_topicos.json';
  if not FileExists(CaminhoJson) then
    CaminhoJson := ExtractFilePath(ObterCaminhoAppTreino) + 'dados\processados\dataset_curado.json';

  if not FileExists(CaminhoJson) then
  begin
    FLblResumoTopicos.Caption := 'Status: Nenhum treinamento executado ainda.';
    Exit;
  end;

  try
    F := TFileStream.Create(CaminhoJson, fmOpenRead or fmShareDenyNone);
    try
      Parser := TJSONParser.Create(F);
      try
        Data := Parser.Parse;
        if Assigned(Data) and (Data.JSONType = jtArray) then
        begin
          Arr := TJSONArray(Data);
          FMemoResultadoTopicos.Lines.BeginUpdate;
          try
            FMemoResultadoTopicos.Clear;
            FMemoResultadoTopicos.Lines.Add('=== RESUMO DO CONTEÚDO TREINADO E SALVO NA REDE ===');
            if Assigned(FCmbRedeAlvo) then
              FMemoResultadoTopicos.Lines.Add('Rede Salva (.ngs): ' + ExtractFileName(FCmbRedeAlvo.Text));
            FMemoResultadoTopicos.Lines.Add(Format('Total de Pares Treinados no Lote: %d', [Arr.Count]));
            FMemoResultadoTopicos.Lines.Add('------------------------------------------------------------');

            UltimoTopico := '';
            // Exibe até os últimos 150 pares para manter fluidez da interface
            Limite := Arr.Count;
            Inicio := 0;
            if Limite > 150 then
            begin
              Inicio := Limite - 150;
              FMemoResultadoTopicos.Lines.Add(Format('... (Exibindo os %d últimos pares de %d)', [150, Limite]));
              FMemoResultadoTopicos.Lines.Add('');
            end;

            for I := Inicio to Limite - 1 do
            begin
              Item := TJSONObject(Arr.Items[I]);
              TopicoAtual := Item.Get('video_id', '');
              if (TopicoAtual <> '') and (TopicoAtual <> UltimoTopico) then
              begin
                UltimoTopico := TopicoAtual;
                FMemoResultadoTopicos.Lines.Add('>>> TÓPICO / FONTE: ' + UpperCase(TopicoAtual));
              end;
              FMemoResultadoTopicos.Lines.Add(Format('  [%d] P: %s', [I + 1, Item.Get('question', '')]));
              FMemoResultadoTopicos.Lines.Add(Format('       R: %s', [Item.Get('answer', '')]));
            end;
          finally
            FMemoResultadoTopicos.Lines.EndUpdate;
          end;

          FLblResumoTopicos.Caption := Format('✔ %d perguntas/respostas treinadas e salvas na rede!', [Arr.Count]);
        end;
      finally
        Parser.Free;
        if Assigned(Data) then Data.Free;
      end;
    finally
      F.Free;
    end;
  except
  end;
end;

procedure TfrmStudio.OnRetreinarTudoClick(Sender: TObject);
begin
  ExecutarComandoTreino(['--treinar']);
end;

procedure TfrmStudio.OnLimparLogClick(Sender: TObject);
begin
  FMemoLog.Clear;
end;

procedure TfrmStudio.OnAbortarClick(Sender: TObject);
var
  StopFile: string;
  F: TextFile;
begin
  if not FIsBusy then Exit;

  StopFile := ExtractFilePath(ObterCaminhoAppTreino) + '.stop_training';

  if not FAbortRequested then
  begin
    FAbortRequested := True;
    try
      AssignFile(F, StopFile);
      Rewrite(F);
      WriteLn(F, 'STOP');
      CloseFile(F);
    except
    end;
    LogMsg('[AVISO] Parada solicitada! Finalizando etapa atual e SALVANDO A REDE (.ngs)...');
    LogMsg('[DICA] Aguarde a compilação dos pesos ou clique novamente em Parar para forçar encerramento imediato.');
  end
  else
  begin
    LogMsg('[AVISO] Forçando encerramento imediato do processo...');
    if Assigned(FCurrentProcess) and FCurrentProcess.Running then
    begin
      try
        FCurrentProcess.Terminate(1);
        LogMsg('[AVISO] Processo encerrado imediatamente.');
      except
      end;
    end;
  end;
end;

procedure TfrmStudio.OnApiKeyChange(Sender: TObject);
begin
  AtualizarStatusGeral;
  if Trim(FEditToken.Text) = '' then
    FEditToken.Text := FEditApiKey.Text;
end;

function TfrmStudio.ObterCaminhoIni: string;
var
  ExeIni, LegacyIni: string;
begin
  ExeIni := ExtractFilePath(ParamStr(0)) + 'neurograph_studio.ini';
  LegacyIni := ExtractFilePath(ObterCaminhoAppTreino) + 'lazarus\neurograph_studio.ini';
  if (not FileExists(ExeIni)) and FileExists(LegacyIni) then
    Result := LegacyIni
  else
    Result := ExeIni;
end;

procedure TfrmStudio.OnListaMemoExit(Sender: TObject);
begin
  if FConfigLoaded then
    SalvarConfiguracoes;
end;

procedure TfrmStudio.OnListaMemoChange(Sender: TObject);
begin
  if FConfigLoaded then
    SalvarConfiguracoes;
end;

procedure TfrmStudio.OnNovoTopicoKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    OnAdicionarTopicoClick(Sender);
  end;
end;

procedure TfrmStudio.OnNovoAssuntoContinuoKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    OnAddAssuntoContinuoClick(Sender);
  end;
end;

procedure TfrmStudio.SalvarConfiguracoes;
var
  Ini: TIniFile;
  i, CountValid: Integer;
  ItemStr: string;
begin
  if not FConfigLoaded then
    Exit;

  try
    Ini := TIniFile.Create(ObterCaminhoIni);
    try
      // Seção Geral
      Ini.WriteString('Geral', 'ApiKey', FEditApiKey.Text);
      Ini.WriteString('Geral', 'RedeAlvo', FCmbRedeAlvo.Text);

      // Persistência de todas as Redes na Lista (FCmbRedeAlvo)
      Ini.EraseSection('RedesLista');
      CountValid := 0;
      if Assigned(FCmbRedeAlvo) then
      begin
        for i := 0 to FCmbRedeAlvo.Items.Count - 1 do
        begin
          ItemStr := Trim(FCmbRedeAlvo.Items[i]);
          if ItemStr <> '' then
          begin
            Ini.WriteString('RedesLista', 'Item_' + IntToStr(CountValid), ItemStr);
            Inc(CountValid);
          end;
        end;
      end;
      Ini.WriteInteger('RedesLista', 'Count', CountValid);

      // Seção ChatGPT
      Ini.WriteString('ChatGPT', 'Provider', FCmbProvider.Text);
      Ini.WriteInteger('ChatGPT', 'ProviderIndex', FCmbProvider.ItemIndex);
      Ini.WriteString('ChatGPT', 'Model', FCmbModel.Text);
      Ini.WriteString('ChatGPT', 'Endpoint', FEditEndpoint.Text);
      Ini.WriteString('ChatGPT', 'Token', FEditToken.Text);
      Ini.WriteString('ChatGPT', 'Temperature', FEditTemperature.Text);
      Ini.WriteInteger('ChatGPT', 'MaxTokens', FSpinMaxTokens.Value);

      // Seção YouTube
      Ini.WriteString('YouTube', 'Tema', FEditTema.Text);
      Ini.WriteInteger('YouTube', 'QtdVideos', FSpinQtdVideos.Value);
      Ini.WriteString('YouTube', 'UltimaUrl', FEditVideoUrl.Text);

      // Seção PDF
      Ini.WriteString('PDF', 'UltimoArquivo', FEditCaminhoPDF.Text);
      Ini.WriteInteger('PDF', 'MaxPares', FSpinMaxParesPDF.Value);

      // Seção Tópicos de Treinamento (salva cada item individualmente sem perda de linhas)
      Ini.EraseSection('Topicos');
      Ini.WriteInteger('Topicos', 'MinPares', FSpinMinParesTopicos.Value);
      Ini.EraseSection('TopicosLista');
      CountValid := 0;
      if Assigned(FMemoTopicos) then
      begin
        for i := 0 to FMemoTopicos.Lines.Count - 1 do
        begin
          ItemStr := Trim(FMemoTopicos.Lines[i]);
          if ItemStr <> '' then
          begin
            Ini.WriteString('TopicosLista', 'Item_' + IntToStr(CountValid), ItemStr);
            Inc(CountValid);
          end;
        end;
      end;
      Ini.WriteInteger('TopicosLista', 'Count', CountValid);

      // Seção Treino Contínuo (salva cada assunto individualmente sem corromper o INI)
      Ini.EraseSection('TreinoContinuo');
      if Assigned(FSpinVideosPorCiclo) then
        Ini.WriteInteger('TreinoContinuo', 'VideosPorCiclo', FSpinVideosPorCiclo.Value);
      if Assigned(FSpinParesPorCiclo) then
        Ini.WriteInteger('TreinoContinuo', 'ParesPorCiclo', FSpinParesPorCiclo.Value);
      if Assigned(FSpinIntervaloCiclo) then
        Ini.WriteInteger('TreinoContinuo', 'IntervaloCiclo', FSpinIntervaloCiclo.Value);
      if Assigned(FSpinMaxCiclosContinuo) then
        Ini.WriteInteger('TreinoContinuo', 'MaxCiclos', FSpinMaxCiclosContinuo.Value);
      if Assigned(FChkApenasPortugues) then
        Ini.WriteBool('TreinoContinuo', 'ApenasPortugues', FChkApenasPortugues.Checked);

      Ini.EraseSection('AssuntosContinuoLista');
      CountValid := 0;
      if Assigned(FMemoAssuntosContinuo) then
      begin
        for i := 0 to FMemoAssuntosContinuo.Lines.Count - 1 do
        begin
          ItemStr := Trim(FMemoAssuntosContinuo.Lines[i]);
          if ItemStr <> '' then
          begin
            Ini.WriteString('AssuntosContinuoLista', 'Item_' + IntToStr(CountValid), ItemStr);
            Inc(CountValid);
          end;
        end;
      end;
      Ini.WriteInteger('AssuntosContinuoLista', 'Count', CountValid);
    finally
      Ini.Free;
    end;
  except
    on E: Exception do
      LogMsg('[AVISO] Erro ao salvar configurações no INI: ' + E.Message);
  end;
end;

procedure TfrmStudio.CarregarConfiguracoes;
var
  Ini: TIniFile;
  ProvName, ModName, KeyVal, EpVal, TokVal, TempVal, TemaVal, UrlVal, PdfVal, ItemStr: string;
  Idx, i, CountItems, MaxT, QtdV, MaxP: Integer;
begin
  if not FileExists(ObterCaminhoIni) then
    Exit;

  try
    Ini := TIniFile.Create(ObterCaminhoIni);
    try
      // Seção Geral
      KeyVal := Ini.ReadString('Geral', 'ApiKey', '');
      if KeyVal <> '' then
        FEditApiKey.Text := KeyVal;

      // Restaura lista de redes customizadas antes de selecionar a RedeAlvo
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
        OnCmbRedeAlvoChange(FCmbRedeAlvo);
      end;

      // Seção ChatGPT
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
      if EpVal <> '' then
        FEditEndpoint.Text := EpVal;

      TokVal := Ini.ReadString('ChatGPT', 'Token', '');
      if TokVal <> '' then
        FEditToken.Text := TokVal
      else if FEditApiKey.Text <> '' then
        FEditToken.Text := FEditApiKey.Text;

      TempVal := Ini.ReadString('ChatGPT', 'Temperature', '0.7');
      FEditTemperature.Text := TempVal;

      MaxT := Ini.ReadInteger('ChatGPT', 'MaxTokens', 1024);
      FSpinMaxTokens.Value := MaxT;

      // Seção YouTube
      TemaVal := Ini.ReadString('YouTube', 'Tema', '');
      if TemaVal <> '' then
        FEditTema.Text := TemaVal;

      QtdV := Ini.ReadInteger('YouTube', 'QtdVideos', 2);
      FSpinQtdVideos.Value := QtdV;

      UrlVal := Ini.ReadString('YouTube', 'UltimaUrl', '');
      if UrlVal <> '' then
        FEditVideoUrl.Text := UrlVal;

      // Seção PDF
      PdfVal := Ini.ReadString('PDF', 'UltimoArquivo', '');
      if PdfVal <> '' then
        FEditCaminhoPDF.Text := PdfVal;

      MaxP := Ini.ReadInteger('PDF', 'MaxPares', 5);
      FSpinMaxParesPDF.Value := MaxP;

      // Seção Tópicos de Treinamento (lê todos os itens salvos na lista)
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
      end
      else if Ini.ValueExists('Topicos', 'Lista') then
      begin
        ItemStr := Trim(Ini.ReadString('Topicos', 'Lista', ''));
        if ItemStr <> '' then
          FMemoTopicos.Lines.Text := ItemStr;
      end;

      if Ini.ValueExists('Topicos', 'MinPares') then
        FSpinMinParesTopicos.Value := Ini.ReadInteger('Topicos', 'MinPares', 100);

      // Seção Treino Contínuo (lê todos os assuntos salvos na lista)
      if Assigned(FMemoAssuntosContinuo) then
      begin
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
      end;

      if Assigned(FSpinVideosPorCiclo) and Ini.ValueExists('TreinoContinuo', 'VideosPorCiclo') then
        FSpinVideosPorCiclo.Value := Ini.ReadInteger('TreinoContinuo', 'VideosPorCiclo', 2);
      if Assigned(FSpinParesPorCiclo) and Ini.ValueExists('TreinoContinuo', 'ParesPorCiclo') then
        FSpinParesPorCiclo.Value := Ini.ReadInteger('TreinoContinuo', 'ParesPorCiclo', 12);
      if Assigned(FSpinIntervaloCiclo) and Ini.ValueExists('TreinoContinuo', 'IntervaloCiclo') then
        FSpinIntervaloCiclo.Value := Ini.ReadInteger('TreinoContinuo', 'IntervaloCiclo', 3);
      if Assigned(FSpinMaxCiclosContinuo) and Ini.ValueExists('TreinoContinuo', 'MaxCiclos') then
        FSpinMaxCiclosContinuo.Value := Ini.ReadInteger('TreinoContinuo', 'MaxCiclos', 0);
      if Assigned(FChkApenasPortugues) and Ini.ValueExists('TreinoContinuo', 'ApenasPortugues') then
        FChkApenasPortugues.Checked := Ini.ReadBool('TreinoContinuo', 'ApenasPortugues', True);

      LogMsg('[INFO] Configurações e listas carregadas com sucesso de: ' + ObterCaminhoIni);
    finally
      Ini.Free;
    end;
  except
    on E: Exception do
      LogMsg('[AVISO] Falha ao ler configurações do INI: ' + E.Message);
  end;
end;

procedure TfrmStudio.OnSalvarConfigClick(Sender: TObject);
begin
  FConfigLoaded := True;
  SalvarConfiguracoes;
  LogMsg('[SUCESSO] Configurações e listas salvas manualmente em: ' + ObterCaminhoIni);
  ShowMessage('Configurações e listas salvas com sucesso em:'#13#10 + ObterCaminhoIni);
end;

end.
