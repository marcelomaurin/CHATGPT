unit ustudio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Dialogs, Spin, Process, fpjson, jsonparser, IniFiles, LazUTF8, chatgpt, aillmmodelcatalog;

type
  { TfrmStudio - Interface Desktop Lazarus para Treinamento do NeuroGraph & Provedores ChatGPT }
  TfrmStudio = class(TForm)
  private
    FPageControl: TPageControl;
    FTabYouTube, FTabPDF, FTab10Topicos, FTabChatGPT, FTabChat, FTabDataset: TTabSheet;

    // Top Bar (Configuração / Status Geral)
    FEditApiKey: TEdit;
    FLblApiStatus, FLblModelStatus: TLabel;
    FBtnSalvarConfig: TButton;

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
    FEditNovoTopico: TEdit;
    FBtnAdicionarTopico: TButton;
    FBtnLimparTopicos: TButton;
    FBtnTopicosPadrao: TButton;
    FSpinMinParesTopicos: TSpinEdit;
    FBtnGerar10Topicos: TButton;

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

    // Controle de Processo
    FCurrentProcess: TProcess;
    FIsBusy: Boolean;
    FAbortRequested: Boolean;

    procedure BuildUI;
    function CriarAba(const ATitulo: string): TTabSheet;
    procedure LogMsg(const AMsg: string);
    procedure SetBusy(const ABusy: Boolean);
    function ObterCaminhoAppTreino: string;
    function ObterPythonExe: string;
    procedure ExecutarComandoTreino(const AParametros: array of string);

    // Eventos Aba YouTube & PDF
    procedure OnBuscarYouTubeClick(Sender: TObject);
    procedure OnProcessarVideoClick(Sender: TObject);
    procedure OnProcurarPDFClick(Sender: TObject);
    procedure OnProcessarPDFClick(Sender: TObject);
    procedure OnGerar10TopicosClick(Sender: TObject);
    procedure OnAdicionarTopicoClick(Sender: TObject);
    procedure OnLimparTopicosClick(Sender: TObject);
    procedure OnTopicosPadraoClick(Sender: TObject);

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
  CarregarConfiguracoes;
  AtualizarStatusGeral;
  OnClose := @FormClose;
end;

procedure TfrmStudio.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SalvarConfiguracoes;
  CloseAction := caFree;
end;

destructor TfrmStudio.Destroy;
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
  PnlTop.Height := 52;
  PnlTop.BevelOuter := bvNone;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := PnlTop;
  Lbl.Caption := 'Chave OpenAI (Global):';
  Lbl.Left := 16;
  Lbl.Top := 16;

  FEditApiKey := TEdit.Create(Self);
  FEditApiKey.Parent := PnlTop;
  FEditApiKey.Left := 155;
  FEditApiKey.Top := 12;
  FEditApiKey.Width := 260;
  FEditApiKey.EchoMode := emPassword;
  FEditApiKey.Text := GetEnvironmentVariable('OPENAI_API_KEY');
  FEditApiKey.OnChange := @OnApiKeyChange;

  FLblApiStatus := TLabel.Create(Self);
  FLblApiStatus.Parent := PnlTop;
  FLblApiStatus.Left := 425;
  FLblApiStatus.Top := 16;
  FLblApiStatus.Caption := '● OpenAI Ativa';
  FLblApiStatus.Font.Style := [fsBold];

  FLblModelStatus := TLabel.Create(Self);
  FLblModelStatus.Parent := PnlTop;
  FLblModelStatus.Left := 620;
  FLblModelStatus.Top := 16;
  FLblModelStatus.Caption := 'Modelo: Verificando...';

  FBtnSalvarConfig := TButton.Create(Self);
  FBtnSalvarConfig.Parent := PnlTop;
  FBtnSalvarConfig.Caption := 'Salvar Configurações';
  FBtnSalvarConfig.Left := 820;
  FBtnSalvarConfig.Top := 10;
  FBtnSalvarConfig.Width := 160;
  FBtnSalvarConfig.Height := 30;
  FBtnSalvarConfig.OnClick := @OnSalvarConfigClick;

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

  // Aba Treinamento Massivo 10 Tópicos (Mínimo 1000 pares)
  FTab10Topicos := CriarAba('  🎯 Treino 10 Tópicos (>=1000)  ');

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := '10 Tópicos Educativos para Geração de Perguntas e Respostas (um por linha):';
  Lbl.Left := 16;
  Lbl.Top := 14;
  Lbl.Font.Style := [fsBold];

  FMemoTopicos := TMemo.Create(Self);
  FMemoTopicos.Parent := FTab10Topicos;
  FMemoTopicos.Left := 16;
  FMemoTopicos.Top := 36;
  FMemoTopicos.Width := 650;
  FMemoTopicos.Height := 170;
  FMemoTopicos.ScrollBars := ssVertical;
  FMemoTopicos.Font.Name := 'Segoe UI';
  FMemoTopicos.Font.Size := 9;
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

  // Controles para inclusão de novos tópicos
  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Incluir Tópico Personalizado:';
  Lbl.Left := 16;
  Lbl.Top := 216;

  FEditNovoTopico := TEdit.Create(Self);
  FEditNovoTopico.Parent := FTab10Topicos;
  FEditNovoTopico.Left := 180;
  FEditNovoTopico.Top := 212;
  FEditNovoTopico.Width := 270;

  FBtnAdicionarTopico := TButton.Create(Self);
  FBtnAdicionarTopico.Parent := FTab10Topicos;
  FBtnAdicionarTopico.Caption := '➕ Incluir Tópico';
  FBtnAdicionarTopico.Left := 458;
  FBtnAdicionarTopico.Top := 210;
  FBtnAdicionarTopico.Width := 115;
  FBtnAdicionarTopico.Height := 28;
  FBtnAdicionarTopico.OnClick := @OnAdicionarTopicoClick;

  FBtnTopicosPadrao := TButton.Create(Self);
  FBtnTopicosPadrao.Parent := FTab10Topicos;
  FBtnTopicosPadrao.Caption := 'Restaurar 10 Padrão';
  FBtnTopicosPadrao.Left := 580;
  FBtnTopicosPadrao.Top := 210;
  FBtnTopicosPadrao.Width := 130;
  FBtnTopicosPadrao.Height := 28;
  FBtnTopicosPadrao.OnClick := @OnTopicosPadraoClick;

  FBtnLimparTopicos := TButton.Create(Self);
  FBtnLimparTopicos.Parent := FTab10Topicos;
  FBtnLimparTopicos.Caption := 'Limpar Lista';
  FBtnLimparTopicos.Left := 718;
  FBtnLimparTopicos.Top := 210;
  FBtnLimparTopicos.Width := 90;
  FBtnLimparTopicos.Height := 28;
  FBtnLimparTopicos.OnClick := @OnLimparTopicosClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'Total Mínimo de Pares (Regra: Nunca menor que 1000):';
  Lbl.Left := 16;
  Lbl.Top := 256;

  FSpinMinParesTopicos := TSpinEdit.Create(Self);
  FSpinMinParesTopicos.Parent := FTab10Topicos;
  FSpinMinParesTopicos.Left := 330;
  FSpinMinParesTopicos.Top := 252;
  FSpinMinParesTopicos.Width := 90;
  FSpinMinParesTopicos.MinValue := 1000;
  FSpinMinParesTopicos.MaxValue := 50000;
  FSpinMinParesTopicos.Value := 1000;

  FBtnGerar10Topicos := TButton.Create(Self);
  FBtnGerar10Topicos.Parent := FTab10Topicos;
  FBtnGerar10Topicos.Caption := '🚀 Gerar Perguntas/Respostas com IA e Treinar Rede';
  FBtnGerar10Topicos.Left := 16;
  FBtnGerar10Topicos.Top := 290;
  FBtnGerar10Topicos.Width := 405;
  FBtnGerar10Topicos.Height := 34;
  FBtnGerar10Topicos.OnClick := @OnGerar10TopicosClick;

  Lbl := TLabel.Create(Self);
  Lbl.Parent := FTab10Topicos;
  Lbl.Caption := 'ℹ️ A IA distribuirá aleatoriamente a quantidade de perguntas por tópico garantindo a soma >= 1000.'#13#10'Todos os pares gerados serão integrados ao dataset e usados para retreinar o TokenGraph.';
  Lbl.Left := 16;
  Lbl.Top := 334;
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

procedure TfrmStudio.LogMsg(const AMsg: string);
begin
  FMemoLog.Lines.Add(AMsg);
  FMemoLog.SelStart := Length(FMemoLog.Text);
  Application.ProcessMessages;
end;

procedure TfrmStudio.SetBusy(const ABusy: Boolean);
begin
  FIsBusy := ABusy;
  FBtnBuscarYouTube.Enabled := not ABusy;
  FBtnProcessarVideo.Enabled := not ABusy;
  FBtnProcessarPDF.Enabled := not ABusy;
  FBtnGerar10Topicos.Enabled := not ABusy;
  FBtnAdicionarTopico.Enabled := not ABusy;
  FBtnRetreinarTudo.Enabled := not ABusy;
  FBtnAbortar.Enabled := ABusy;

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
  else
  begin
    FLblApiStatus.Caption := '○ Modo Heurístico Local';
    FLblApiStatus.Font.Color := $000088DD;
  end;

  CaminhoModelo := ExtractFilePath(ObterCaminhoAppTreino) + 'modelos\neurograph_youtube.ngs';
  if FindFirst(CaminhoModelo, faAnyFile, Info) = 0 then
  begin
    TamMB := Info.Size / (1024 * 1024);
    FLblModelStatus.Caption := Format('Modelo: neurograph_youtube.ngs (%.2f MB)', [TamMB]);
    FindClose(Info);
  end
  else
    FLblModelStatus.Caption := 'Modelo: Não treinado ainda';
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
      if FAbortRequested then
      begin
        try
          P.Terminate(1);
          LogMsg('[AVISO] Processo abortado pelo usuário.');
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
  LogMsg('[INFO] Tópico adicionado à lista: ' + NovoT);
end;

procedure TfrmStudio.OnLimparTopicosClick(Sender: TObject);
begin
  FMemoTopicos.Clear;
  LogMsg('[INFO] Lista de tópicos limpa.');
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
  LogMsg('[INFO] 10 Tópicos padrão restaurados com sucesso.');
end;

procedure TfrmStudio.OnGerar10TopicosClick(Sender: TObject);
var
  Params: array of string;
  i, TopicosCount: Integer;
  Linha: string;
begin
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
begin
  FAbortRequested := True;
  LogMsg('[AVISO] Solicitando cancelamento...');
end;

procedure TfrmStudio.OnApiKeyChange(Sender: TObject);
begin
  AtualizarStatusGeral;
  if Trim(FEditToken.Text) = '' then
    FEditToken.Text := FEditApiKey.Text;
end;

function TfrmStudio.ObterCaminhoIni: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'neurograph_studio.ini';
end;

procedure TfrmStudio.SalvarConfiguracoes;
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(ObterCaminhoIni);
    try
      // Seção Geral
      Ini.WriteString('Geral', 'ApiKey', FEditApiKey.Text);

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
  ProvName, ModName, KeyVal, EpVal, TokVal, TempVal, TemaVal, UrlVal, PdfVal: string;
  Idx, MaxT, QtdV, MaxP: Integer;
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

      LogMsg('[INFO] Configurações carregadas com sucesso de: ' + ObterCaminhoIni);
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
  SalvarConfiguracoes;
  LogMsg('[SUCESSO] Configurações salvas manualmente em: ' + ObterCaminhoIni);
  ShowMessage('Configurações salvas com sucesso em:'#13#10 + ObterCaminhoIni);
end;

end.
