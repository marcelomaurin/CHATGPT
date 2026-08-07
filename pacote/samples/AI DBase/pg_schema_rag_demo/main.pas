unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, IniFiles, Forms, Controls, Graphics, Dialogs,
  StdCtrls, ExtCtrls, ComCtrls, DBGrids, DB,
  ZConnection, ZDataset,
  chatgpt, aigraphmap, airag,
  aidb_types, aidb_dictionary_base, aidb_postgresql_dictionary,
  aiagent_flowevents, aiagent_memorymap;

type

  { TfrmPGSchemaRAG }

  TfrmPGSchemaRAG = class(TForm)
    pcMain: TPageControl;

    // --- Aba Conexao ---
    tsConexao: TTabSheet;
    pnlConexao: TPanel;
    lblHost: TLabel;
    edtHost: TEdit;
    lblPorta: TLabel;
    edtPorta: TEdit;
    lblDatabase: TLabel;
    edtDatabase: TEdit;
    lblSchema: TLabel;
    edtSchema: TEdit;
    lblUsuario: TLabel;
    edtUsuario: TEdit;
    lblSenha: TLabel;
    edtSenha: TEdit;
    chkSalvarSenha: TCheckBox;
    btnTestarConexao: TButton;
    btnConectar: TButton;
    btnDesconectar: TButton;
    btnSalvarConexao: TButton;
    lblStatusConexao: TLabel;
    memConexao: TMemo;

    // --- Aba Dicionario ---
    tsDicionario: TTabSheet;
    pnlDicTop: TPanel;
    btnGerarDicionario: TButton;
    chkCarregarComentarios: TCheckBox;
    lblResumoDic: TLabel;
    lstTabelas: TListBox;
    memChunkTabela: TMemo;

    // --- Aba Indice ---
    tsIndice: TTabSheet;
    pnlIdxTop: TPanel;
    btnConstruirIndice: TButton;
    btnSalvarIndice: TButton;
    btnCarregarIndice: TButton;
    lblIndiceInfo: TLabel;
    memIndice: TMemo;

    // --- Aba Consulta ---
    tsConsulta: TTabSheet;
    pnlPergunta: TPanel;
    lblPergunta: TLabel;
    edtPergunta: TEdit;
    btnRecuperar: TButton;
    btnGerarSQL: TButton;
    btnExecutarSQL: TButton;
    btnLimparConsulta: TButton;
    pnlRecuperadas: TPanel;
    lblRecuperadas: TLabel;
    memRecuperadas: TMemo;
    pnlSQL: TPanel;
    lblSQL: TLabel;
    memSQL: TMemo;
    dbgResultado: TDBGrid;

    // --- Aba Config IA ---
    tsConfigIA: TTabSheet;
    pnlConfigIA: TPanel;
    lblProvider: TLabel;
    cmbProvider: TComboBox;
    lblApiKey: TLabel;
    edtApiKey: TEdit;
    lblModel: TLabel;
    cmbModel: TComboBox;
    lblURL: TLabel;
    edtURL: TEdit;
    lblTimeout: TLabel;
    edtTimeout: TEdit;
    lblTopK: TLabel;
    edtTopK: TEdit;
    lblMaxTokens: TLabel;
    edtMaxTokens: TEdit;
    lblInstrucoes: TLabel;
    memInstrucoes: TMemo;
    btnSalvarConfigIA: TButton;

    // --- Aba Logs ---
    tsLogs: TTabSheet;
    memLogs: TMemo;

    // --- Aba Mapa de Memoria ---
    tsMapaMemoria: TTabSheet;
    memMapaMemoria: TMemo;

    // --- Nao visuais ---
    ZConnection1: TZConnection;
    ZQuery1: TZQuery;
    DataSource1: TDataSource;
    OpenDialog1: TOpenDialog;
    SaveDialog1: TSaveDialog;
    CHATGPT1: TCHATGPT;
    AIGraphMap1: TAIGraphMap;
    AIRAG1: TAIRAG;
    AIPostgreSQLDictionary1: TAIPostgreSQLDictionary;
    AIAgentMemoryMap1: TAIAgentMemoryMap;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnTestarConexaoClick(Sender: TObject);
    procedure btnConectarClick(Sender: TObject);
    procedure btnDesconectarClick(Sender: TObject);
    procedure btnSalvarConexaoClick(Sender: TObject);
    procedure btnGerarDicionarioClick(Sender: TObject);
    procedure lstTabelasClick(Sender: TObject);
    procedure btnConstruirIndiceClick(Sender: TObject);
    procedure btnSalvarIndiceClick(Sender: TObject);
    procedure btnCarregarIndiceClick(Sender: TObject);
    procedure btnRecuperarClick(Sender: TObject);
    procedure btnGerarSQLClick(Sender: TObject);
    procedure btnExecutarSQLClick(Sender: TObject);
    procedure btnLimparConsultaClick(Sender: TObject);
    procedure btnSalvarConfigIAClick(Sender: TObject);
    procedure cmbProviderChange(Sender: TObject);
    procedure AIRAGLog(Sender: TObject; const AMessage: string);
  private
    procedure Log(const AMensagem: string);
    procedure LogExcecao(const AContexto: string; E: Exception);
    procedure SetOcupado(AOcupado: Boolean);

    function CaminhoConfig: string;
    procedure CarregarConfig;
    procedure SalvarConfig;
    procedure AplicarConfigIA;
    procedure AtualizarModelosDoProvedor;

    procedure AplicarParametrosConexao;
    function EstaConectado: Boolean;
    procedure AtualizarStatusConexao;

    function GarantirConexao: Boolean;
    function GarantirDicionario: Boolean;
    function GarantirIndiceRAG: Boolean;
    function GarantirPipelineCompleto: Boolean;
    function ExecutarSQLComAutoCorrecao(var ASQL: string; const AFontes: TStrings): Boolean;
    procedure AtualizarExibicaoMapaMemoria;

    function SerializarTabela(ATable: TAIDBTableInfo): string;
    procedure EnriquecerComComentarios;
    function LocalizarTabelaPorFonte(const AFonte: string): TAIDBTableInfo;
    function MontarContextoDDL(AFontes: TStrings): string;

    function LimparCercaMarkdown(const ATexto: string): string;
    function SQLSomenteSelect(const ASQL: string; out AMotivo: string): Boolean;
  public

  end;

var
  frmPGSchemaRAG: TfrmPGSchemaRAG;

implementation

{$R *.lfm}

const
  NOME_APP = 'pg_schema_rag_demo';

{ Verifica se APalavra aparece em ATexto como palavra inteira (delimitada por
  caracteres nao alfanumericos). Evita falso positivo do tipo "created_at"
  disparar a proibicao da palavra CREATE. }
function ContemPalavraInteira(const ATexto, APalavra: string): Boolean;
var
  LPos, LFim, LBusca: Integer;
  LAntes, LDepois: Char;
begin
  Result := False;
  LBusca := 1;
  repeat
    LPos := PosEx(APalavra, ATexto, LBusca);
    if LPos = 0 then
      Exit(False);

    LFim := LPos + Length(APalavra);

    if LPos = 1 then
      LAntes := ' '
    else
      LAntes := ATexto[LPos - 1];

    if LFim > Length(ATexto) then
      LDepois := ' '
    else
      LDepois := ATexto[LFim];

    if (not (LAntes in ['A'..'Z', 'a'..'z', '0'..'9', '_'])) and
       (not (LDepois in ['A'..'Z', 'a'..'z', '0'..'9', '_'])) then
      Exit(True);

    LBusca := LPos + 1;
  until False;
end;

{ TfrmPGSchemaRAG }

// ---------------------------------------------------------------------------
// Infraestrutura
// ---------------------------------------------------------------------------

procedure TfrmPGSchemaRAG.Log(const AMensagem: string);
begin
  memLogs.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), AMensagem]));
end;

procedure TfrmPGSchemaRAG.LogExcecao(const AContexto: string; E: Exception);
begin
  Log(Format('[EXCECAO %s] %s: %s', [AContexto, E.ClassName, E.Message]));
  ShowMessage(Format('Falha em %s:'#13#10'%s', [AContexto, E.Message]));
end;

procedure TfrmPGSchemaRAG.SetOcupado(AOcupado: Boolean);
begin
  btnTestarConexao.Enabled   := not AOcupado;
  btnConectar.Enabled        := not AOcupado;
  btnDesconectar.Enabled     := not AOcupado;
  btnGerarDicionario.Enabled := not AOcupado;
  btnConstruirIndice.Enabled := not AOcupado;
  btnSalvarIndice.Enabled    := not AOcupado;
  btnCarregarIndice.Enabled  := not AOcupado;
  btnRecuperar.Enabled       := not AOcupado;
  btnGerarSQL.Enabled        := not AOcupado;
  btnExecutarSQL.Enabled     := not AOcupado;

  if AOcupado then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;

  Application.ProcessMessages;
end;

procedure TfrmPGSchemaRAG.AIRAGLog(Sender: TObject; const AMessage: string);
begin
  Log('[RAG] ' + AMessage);
end;

procedure TfrmPGSchemaRAG.FormCreate(Sender: TObject);
begin
  CarregarConfig;
  AplicarConfigIA;
  AtualizarStatusConexao;
  Log('Aplicacao iniciada. Configure a conexao na aba Conexao.');
end;

procedure TfrmPGSchemaRAG.FormDestroy(Sender: TObject);
begin
  try
    SalvarConfig;
  except
    // Destrutor nao propaga excecao.
    on E: Exception do ;
  end;

  try
    if ZConnection1.Connected then
      ZConnection1.Disconnect;
  except
    on E: Exception do ;
  end;
end;

// ---------------------------------------------------------------------------
// Configuracao persistida
// ---------------------------------------------------------------------------

function TfrmPGSchemaRAG.CaminhoConfig: string;
var
  LDir: string;
begin
  LDir := GetEnvironmentVariable('APPDATA');
  if LDir <> '' then
    LDir := IncludeTrailingPathDelimiter(LDir) + 'maurinsoft' + DirectorySeparator + NOME_APP
  else
    LDir := GetAppConfigDir(False);

  if not DirectoryExists(LDir) then
    ForceDirectories(LDir);
  Result := IncludeTrailingPathDelimiter(LDir) + NOME_APP + '.ini';
end;

procedure TfrmPGSchemaRAG.AtualizarModelosDoProvedor;
var
  LProvider: TAIProvider;
  LModeloAtual: string;
begin
  LModeloAtual := cmbModel.Text;
  LProvider := GetAIProviderFromIndex(cmbProvider.ItemIndex);

  cmbModel.Items.Clear;
  GetAIModelListForProvider(LProvider, cmbModel.Items);

  if cmbModel.Items.Count > 0 then
  begin
    if cmbModel.Items.IndexOf(LModeloAtual) >= 0 then
      cmbModel.Text := LModeloAtual
    else
      cmbModel.ItemIndex := 0;
  end;

  if Trim(edtURL.Text) = '' then
    edtURL.Text := GetDefaultEndpointForProvider(LProvider);
end;

procedure TfrmPGSchemaRAG.cmbProviderChange(Sender: TObject);
begin
  edtURL.Text := GetDefaultEndpointForProvider(GetAIProviderFromIndex(cmbProvider.ItemIndex));
  AtualizarModelosDoProvedor;
end;

procedure TfrmPGSchemaRAG.CarregarConfig;
var
  LIni: TIniFile;
  LNomeProvedor: string;
  LIdx: Integer;
begin
  LIni := TIniFile.Create(CaminhoConfig);
  try
    edtHost.Text     := LIni.ReadString('Conexao', 'Host', 'localhost');
    edtPorta.Text    := LIni.ReadString('Conexao', 'Porta', '5432');
    edtDatabase.Text := LIni.ReadString('Conexao', 'Database', '');
    edtSchema.Text   := LIni.ReadString('Conexao', 'Schema', 'public');
    edtUsuario.Text  := LIni.ReadString('Conexao', 'Usuario', '');
    chkSalvarSenha.Checked := LIni.ReadBool('Conexao', 'SalvarSenha', False);
    if chkSalvarSenha.Checked then
      edtSenha.Text := LIni.ReadString('Conexao', 'Senha', '')
    else
      edtSenha.Text := '';

    GetAIProviderList(cmbProvider.Items);
    LNomeProvedor := LIni.ReadString('IA', 'ProviderName', '');
    LIdx := -1;
    if LNomeProvedor <> '' then
      LIdx := cmbProvider.Items.IndexOf(LNomeProvedor);
    if LIdx < 0 then
      LIdx := LIni.ReadInteger('IA', 'ProviderIndex', 0);
    if (LIdx >= 0) and (LIdx < cmbProvider.Items.Count) then
      cmbProvider.ItemIndex := LIdx
    else
      cmbProvider.ItemIndex := 0;

    AtualizarModelosDoProvedor;

    edtApiKey.Text    := LIni.ReadString('IA', 'ApiKey', '');
    cmbModel.Text     := LIni.ReadString('IA', 'Model', cmbModel.Text);
    edtURL.Text       := LIni.ReadString('IA', 'URL',
                           GetDefaultEndpointForProvider(GetAIProviderFromIndex(cmbProvider.ItemIndex)));
    edtTimeout.Text   := LIni.ReadString('IA', 'TimeoutSegundos', '120');
    edtMaxTokens.Text := LIni.ReadString('IA', 'MaxTokens', '1200');
    edtTopK.Text      := LIni.ReadString('RAG', 'TopK', '8');

    memInstrucoes.Text := LIni.ReadString('IA', 'Instrucoes',
      'Voce e um especialista em PostgreSQL. Gere consultas SELECT corretas, ' +
      'usando exclusivamente as tabelas e colunas descritas no esquema fornecido.');

    Log('Configuracoes carregadas de: ' + CaminhoConfig);
  finally
    LIni.Free;
  end;
end;

procedure TfrmPGSchemaRAG.SalvarConfig;
var
  LIni: TIniFile;
begin
  LIni := TIniFile.Create(CaminhoConfig);
  try
    LIni.WriteString('Conexao', 'Host', edtHost.Text);
    LIni.WriteString('Conexao', 'Porta', edtPorta.Text);
    LIni.WriteString('Conexao', 'Database', edtDatabase.Text);
    LIni.WriteString('Conexao', 'Schema', edtSchema.Text);
    LIni.WriteString('Conexao', 'Usuario', edtUsuario.Text);
    LIni.WriteBool('Conexao', 'SalvarSenha', chkSalvarSenha.Checked);
    if chkSalvarSenha.Checked then
      LIni.WriteString('Conexao', 'Senha', edtSenha.Text)
    else
      LIni.DeleteKey('Conexao', 'Senha');

    LIni.WriteInteger('IA', 'ProviderIndex', cmbProvider.ItemIndex);
    LIni.WriteString('IA', 'ProviderName', cmbProvider.Text);
    LIni.WriteString('IA', 'ApiKey', edtApiKey.Text);
    LIni.WriteString('IA', 'Model', cmbModel.Text);
    LIni.WriteString('IA', 'URL', edtURL.Text);
    LIni.WriteString('IA', 'TimeoutSegundos', edtTimeout.Text);
    LIni.WriteString('IA', 'MaxTokens', edtMaxTokens.Text);
    LIni.WriteString('IA', 'Instrucoes', memInstrucoes.Text);
    LIni.WriteString('RAG', 'TopK', edtTopK.Text);
  finally
    LIni.Free;
  end;
end;

procedure TfrmPGSchemaRAG.AplicarConfigIA;
begin
  if Assigned(CHATGPT1) then
  begin
    CHATGPT1.Provider := GetAIProviderFromIndex(cmbProvider.ItemIndex);
    CHATGPT1.TOKEN := Trim(edtApiKey.Text);
    CHATGPT1.TipoChat := VCT_CUSTOM;
    CHATGPT1.CustomModel := Trim(cmbModel.Text);
    CHATGPT1.URL := Trim(edtURL.Text);
    CHATGPT1.Timeout := StrToIntDef(edtTimeout.Text, 120) * 1000;
    CHATGPT1.MaxTokens := StrToIntDef(edtMaxTokens.Text, 1200);
  end;

  if Assigned(AIRAG1) then
    AIRAG1.TopK := StrToIntDef(edtTopK.Text, 8);
end;

procedure TfrmPGSchemaRAG.btnSalvarConfigIAClick(Sender: TObject);
begin
  AplicarConfigIA;
  SalvarConfig;
  ShowMessage('Configuracoes da IA salvas.');
end;

// ---------------------------------------------------------------------------
// Conexao
// ---------------------------------------------------------------------------

procedure TfrmPGSchemaRAG.AplicarParametrosConexao;
var
  LAppDir, LLibPath: string;
begin
  ZConnection1.Protocol := 'postgresql';
  ZConnection1.HostName := Trim(edtHost.Text);
  ZConnection1.Port     := StrToIntDef(edtPorta.Text, 5432);
  ZConnection1.Database := Trim(edtDatabase.Text);
  ZConnection1.User     := Trim(edtUsuario.Text);
  ZConnection1.Password := edtSenha.Text;

  // Garante busca das DLLs de conexao (ex: libpq.dll) no mesmo diretorio da aplicacao
  LAppDir := ExtractFilePath(ParamStr(0));
  LLibPath := IncludeTrailingPathDelimiter(LAppDir) + 'libpq.dll';
  if FileExists(LLibPath) then
    ZConnection1.LibraryLocation := LLibPath
  else
    ZConnection1.LibraryLocation := LAppDir;
end;

function TfrmPGSchemaRAG.EstaConectado: Boolean;
begin
  Result := ZConnection1.Connected;
end;

procedure TfrmPGSchemaRAG.AtualizarStatusConexao;
begin
  if EstaConectado then
    lblStatusConexao.Caption := 'Status: CONECTADO a ' + ZConnection1.Database
  else
    lblStatusConexao.Caption := 'Status: desconectado';
end;

procedure TfrmPGSchemaRAG.btnTestarConexaoClick(Sender: TObject);
begin
  SetOcupado(True);
  try
    try
      AplicarParametrosConexao;
      memConexao.Lines.Clear;
      memConexao.Lines.Add('Testando conexao com ' + ZConnection1.HostName + ':' +
        IntToStr(ZConnection1.Port) + '/' + ZConnection1.Database + ' ...');

      ZConnection1.Connect;
      try
        memConexao.Lines.Add('SUCESSO. Conexao estabelecida.');
        Log('Teste de conexao bem sucedido.');
      finally
        ZConnection1.Disconnect;
      end;
      memConexao.Lines.Add('Conexao de teste encerrada.');
    except
      on E: Exception do
      begin
        memConexao.Lines.Add('FALHA: ' + E.Message);
        LogExcecao('TESTE DE CONEXAO', E);
      end;
    end;
  finally
    AtualizarStatusConexao;
    SetOcupado(False);
  end;
end;

procedure TfrmPGSchemaRAG.btnConectarClick(Sender: TObject);
begin
  SetOcupado(True);
  try
    try
      if ZConnection1.Connected then
        ZConnection1.Disconnect;

      AplicarParametrosConexao;
      ZConnection1.Connect;

      memConexao.Lines.Add('Conectado a ' + ZConnection1.Database);
      Log('Conectado ao banco ' + ZConnection1.Database);
    except
      on E: Exception do
        LogExcecao('CONECTAR', E);
    end;
  finally
    AtualizarStatusConexao;
    SetOcupado(False);
  end;
end;

procedure TfrmPGSchemaRAG.btnDesconectarClick(Sender: TObject);
begin
  try
    if ZQuery1.Active then
      ZQuery1.Close;
    if ZConnection1.Connected then
      ZConnection1.Disconnect;
    Log('Desconectado.');
  except
    on E: Exception do
      LogExcecao('DESCONECTAR', E);
  end;
  AtualizarStatusConexao;
end;

procedure TfrmPGSchemaRAG.btnSalvarConexaoClick(Sender: TObject);
begin
  SalvarConfig;
  ShowMessage('Parametros de conexao salvos em:'#13#10 + CaminhoConfig);
end;

// ---------------------------------------------------------------------------
// Auto-Pipeline & Memory Map Helpers
// ---------------------------------------------------------------------------

function TfrmPGSchemaRAG.GarantirConexao: Boolean;
var
  LStep: TAIAgentMemoryMapItem;
begin
  if not EstaConectado then
  begin
    Log('Auto-Pipeline: Etapa 1 - Conectando ao Banco de Dados...');
    if Assigned(AIAgentMemoryMap1) then
      LStep := AIAgentMemoryMap1.BeginAgentStep('Etapa1_Conexao', tamExecutor, 'Conectar ao PostgreSQL')
    else
      LStep := nil;
    btnConectarClick(nil);
    if EstaConectado then
    begin
      if Assigned(AIAgentMemoryMap1) and (LStep <> nil) then
        AIAgentMemoryMap1.EndAgentStep(LStep, 'Conexao estabelecida com sucesso', '', 'SUCCESS', 'Conectado');
    end
    else
    begin
      if Assigned(AIAgentMemoryMap1) and (LStep <> nil) then
        AIAgentMemoryMap1.EndAgentStep(LStep, 'Falha ao conectar no PostgreSQL', ZConnection1.HostName, 'ERROR', 'Desconectado');
    end;
  end;
  Result := EstaConectado;
end;

function TfrmPGSchemaRAG.GarantirDicionario: Boolean;
var
  LStep: TAIAgentMemoryMapItem;
begin
  if not GarantirConexao then
    Exit(False);

  if AIPostgreSQLDictionary1.DataDictionary.Tables.Count = 0 then
  begin
    Log('Auto-Pipeline: Etapa 2 - Gerando Dicionario de Dados...');
    if Assigned(AIAgentMemoryMap1) then
      LStep := AIAgentMemoryMap1.BeginAgentStep('Etapa2_Dicionario', tamCustom, 'Gerar Dicionario')
    else
      LStep := nil;
    btnGerarDicionarioClick(nil);
    if AIPostgreSQLDictionary1.DataDictionary.Tables.Count > 0 then
    begin
      if Assigned(AIAgentMemoryMap1) and (LStep <> nil) then
        AIAgentMemoryMap1.EndAgentStep(LStep, Format('Dicionario gerado: %d tabelas', [AIPostgreSQLDictionary1.DataDictionary.Tables.Count]), '', 'SUCCESS', Format('%d tabelas', [AIPostgreSQLDictionary1.DataDictionary.Tables.Count]));
    end
    else
    begin
      if Assigned(AIAgentMemoryMap1) and (LStep <> nil) then
        AIAgentMemoryMap1.EndAgentStep(LStep, 'Falha ao gerar dicionario', AIPostgreSQLDictionary1.LastError, 'ERROR', '');
    end;
  end;
  Result := AIPostgreSQLDictionary1.DataDictionary.Tables.Count > 0;
end;

function TfrmPGSchemaRAG.GarantirIndiceRAG: Boolean;
var
  LStep: TAIAgentMemoryMapItem;
begin
  if not GarantirDicionario then
    Exit(False);

  if AIGraphMap1.NodeCount = 0 then
  begin
    Log('Auto-Pipeline: Etapa 3 - Construindo Indice RAG...');
    if Assigned(AIAgentMemoryMap1) then
      LStep := AIAgentMemoryMap1.BeginAgentStep('Etapa3_IndiceRAG', tamCustom, 'Construir Indice RAG')
    else
      LStep := nil;
    btnConstruirIndiceClick(nil);
    if AIGraphMap1.NodeCount > 0 then
    begin
      if Assigned(AIAgentMemoryMap1) and (LStep <> nil) then
        AIAgentMemoryMap1.EndAgentStep(LStep, Format('Indice RAG construido: %d nos, %d arestas', [AIGraphMap1.NodeCount, AIGraphMap1.EdgeCount]), '', 'SUCCESS', Format('%d nos', [AIGraphMap1.NodeCount]));
    end
    else
    begin
      if Assigned(AIAgentMemoryMap1) and (LStep <> nil) then
        AIAgentMemoryMap1.EndAgentStep(LStep, 'Falha ao construir indice RAG', AIRAG1.LastError, 'ERROR', '');
    end;
  end;
  Result := AIGraphMap1.NodeCount > 0;
end;

function TfrmPGSchemaRAG.GarantirPipelineCompleto: Boolean;
begin
  Result := GarantirIndiceRAG;
end;

procedure TfrmPGSchemaRAG.AtualizarExibicaoMapaMemoria;
begin
  if Assigned(AIAgentMemoryMap1) then
    memMapaMemoria.Text := AIAgentMemoryMap1.AsText;
end;

function TfrmPGSchemaRAG.ExecutarSQLComAutoCorrecao(var ASQL: string; const AFontes: TStrings): Boolean;
var
  LAttempt: Integer;
  LMotivo, LErro, LPromptFix, LRespostaIA: string;
  LStepExec, LStepFix: TAIAgentMemoryMapItem;
begin
  Result := False;
  ASQL := Trim(ASQL);

  for LAttempt := 1 to 3 do
  begin
    if ASQL = '' then
      Exit;

    if not SQLSomenteSelect(ASQL, LMotivo) then
    begin
      Log('[BLOQUEADO] ' + LMotivo);
      ShowMessage('Execucao bloqueada.'#13#10#13#10 + LMotivo);
      Exit;
    end;

    Log(Format('Executando SQL (Tentativa %d de 3)...', [LAttempt]));
    memSQL.Text := ASQL;

    if Assigned(AIAgentMemoryMap1) then
      LStepExec := AIAgentMemoryMap1.BeginAgentStep('ExecutarSQL', tamExecutor, ASQL)
    else
      LStepExec := nil;

    try
      if ZQuery1.Active then
        ZQuery1.Close;

      ZConnection1.ExecuteDirect('SET statement_timeout = 30000');
      ZQuery1.SQL.Text := ASQL;
      ZQuery1.Open;

      if Assigned(AIAgentMemoryMap1) and (LStepExec <> nil) then
        AIAgentMemoryMap1.EndAgentStep(LStepExec,
          Format('SQL executado com sucesso na tentativa %d (%d registros)', [LAttempt, ZQuery1.RecordCount]),
          '', 'SUCCESS', ASQL);

      Log(Format('Consulta executada com SUCESSO na tentativa %d. Registros: %d', [LAttempt, ZQuery1.RecordCount]));
      pcMain.ActivePage := tsConsulta;
      Result := True;
      Break;
    except
      on E: Exception do
      begin
        LErro := E.Message;
        Log(Format('[ERRO EXECUCAO - Tentativa %d/3]: %s', [LAttempt, LErro]));
        if Assigned(AIAgentMemoryMap1) and (LStepExec <> nil) then
          AIAgentMemoryMap1.EndAgentStep(LStepExec,
            Format('Falha na tentativa %d: %s', [LAttempt, LErro]),
            LErro, 'ERROR', ASQL);

        if LAttempt < 3 then
        begin
          Log('Enviando erro para a IA corrigir o SQL...');
          if Assigned(AIAgentMemoryMap1) then
            LStepFix := AIAgentMemoryMap1.BeginAgentStep('IA_SelfCorrection', tamDecisor, LErro)
          else
            LStepFix := nil;

          LPromptFix :=
            memInstrucoes.Text + sLineBreak + sLineBreak +
            'A instrucao SQL anterior gerou um erro no PostgreSQL.' + sLineBreak + sLineBreak +
            'REGRAS DE CORRECAO:' + sLineBreak +
            '1. Retorne APENAS o comando SQL corrigido sem explicacoes nem cerca de markdown.' + sLineBreak +
            '2. Corrija o nome de colunas, tabelas, JOINs ou tipos de dados com base no erro retornado.' + sLineBreak +
            '3. Qualifique tabelas como esquema.tabela.' + sLineBreak + sLineBreak +
            '=== ESQUEMA DISPONIVEL ===' + sLineBreak +
            MontarContextoDDL(AFontes) + sLineBreak +
            '=== FIM DO ESQUEMA ===' + sLineBreak + sLineBreak +
            'Pergunta Original: ' + edtPergunta.Text + sLineBreak + sLineBreak +
            'SQL com erro:' + sLineBreak + ASQL + sLineBreak + sLineBreak +
            'Erro PostgreSQL:' + sLineBreak + LErro;

          CHATGPT1.Prompt := LPromptFix;
          if CHATGPT1.SendQuestion(LPromptFix) then
          begin
            LRespostaIA := CHATGPT1.Response;
            if Trim(LRespostaIA) = '' then
              LRespostaIA := CHATGPT1.LastResult;

            ASQL := LimparCercaMarkdown(LRespostaIA);
            if Assigned(AIAgentMemoryMap1) and (LStepFix <> nil) then
              AIAgentMemoryMap1.EndAgentStep(LStepFix,
                'SQL Corrigido recebido da IA', '', 'FIX_GENERATED', ASQL);
            Log('IA retornou SQL corrigido:' + sLineBreak + ASQL);
          end
          else
          begin
            Log('[ERRO IA CORRECAO] ' + CHATGPT1.LastError);
            if Assigned(AIAgentMemoryMap1) and (LStepFix <> nil) then
              AIAgentMemoryMap1.EndAgentStep(LStepFix,
                'Falha na chamada da IA para correcao', CHATGPT1.LastError, 'ERROR', '');
            Break;
          end;
        end
        else
        begin
          Log('[FALHA FINAL] Limite de 3 tentativas atingido sem sucesso.');
          ShowMessage('Falha ao executar o SQL apos 3 tentativas.'#13#10#13#10 + LErro);
        end;
      end;
    end;
  end;
end;

// ---------------------------------------------------------------------------
// Dicionario
// ---------------------------------------------------------------------------

{ O componente TAIPostgreSQLDictionary nao preenche o campo Description de
  tabelas, colunas e views (atribui string vazia). Como o comentario e o melhor
  sinal semantico para o RAG achar a tabela certa, este metodo busca os
  comentarios diretamente no catalogo e os injeta no dicionario ja carregado. }
procedure TfrmPGSchemaRAG.EnriquecerComComentarios;
var
  LQuery: TZQuery;
  LTabela: TAIDBTableInfo;
  LView: TAIDBViewInfo;
  LNomeObjeto, LNomeColuna, LComentario: string;
  I, LTotalTabelas, LTotalColunas: Integer;
begin
  LTotalTabelas := 0;
  LTotalColunas := 0;

  LQuery := TZQuery.Create(nil);
  try
    LQuery.Connection := ZConnection1;
    LQuery.SQL.Text :=
      'SELECT n.nspname        AS esquema, ' +
      '       c.relname        AS objeto, ' +
      '       a.attname        AS coluna, ' +
      '       obj_description(c.oid, ''pg_class'') AS coment_objeto, ' +
      '       col_description(c.oid, a.attnum)    AS coment_coluna ' +
      'FROM pg_class c ' +
      '  JOIN pg_namespace n ON n.oid = c.relnamespace ' +
      '  LEFT JOIN pg_attribute a ON a.attrelid = c.oid ' +
      '       AND a.attnum > 0 AND NOT a.attisdropped ' +
      'WHERE c.relkind IN (''r'', ''v'', ''m'', ''p'') ' +
      '  AND n.nspname NOT IN (''pg_catalog'', ''information_schema'') ' +
      '  AND (:esq = '''' OR n.nspname = :esq) ' +
      'ORDER BY n.nspname, c.relname, a.attnum';
    LQuery.ParamByName('esq').AsString := Trim(edtSchema.Text);
    LQuery.Open;

    while not LQuery.EOF do
    begin
      LNomeObjeto := LQuery.FieldByName('objeto').AsString;
      LNomeColuna := LQuery.FieldByName('coluna').AsString;

      LTabela := AIPostgreSQLDictionary1.DataDictionary.Tables.FindTable(LNomeObjeto);

      // Comentario do objeto
      LComentario := LQuery.FieldByName('coment_objeto').AsString;
      if LComentario <> '' then
      begin
        if Assigned(LTabela) and (LTabela.Description = '') then
        begin
          LTabela.Description := LComentario;
          Inc(LTotalTabelas);
        end;

        for I := 0 to AIPostgreSQLDictionary1.DataDictionary.Views.Count - 1 do
        begin
          LView := AIPostgreSQLDictionary1.DataDictionary.Views[I];
          if SameText(LView.ViewName, LNomeObjeto) and (LView.Description = '') then
            LView.Description := LComentario;
        end;
      end;

      // Comentario da coluna
      LComentario := LQuery.FieldByName('coment_coluna').AsString;
      if (LComentario <> '') and (LNomeColuna <> '') and Assigned(LTabela) then
      begin
        for I := 0 to LTabela.Columns.Count - 1 do
        begin
          if SameText(LTabela.Columns[I].ColumnName, LNomeColuna) then
          begin
            LTabela.Columns[I].Description := LComentario;
            Inc(LTotalColunas);
            Break;
          end;
        end;
      end;

      LQuery.Next;
    end;

    LQuery.Close;
    Log(Format('Comentarios aplicados: %d tabelas, %d colunas.',
      [LTotalTabelas, LTotalColunas]));

    if (LTotalTabelas = 0) and (LTotalColunas = 0) then
      Log('[AVISO] Nenhum comentario encontrado no banco. A qualidade da ' +
          'recuperacao depende fortemente de COMMENT ON em tabelas e colunas.');
  finally
    LQuery.Free;
  end;
end;

function TfrmPGSchemaRAG.SerializarTabela(ATable: TAIDBTableInfo): string;
var
  LSaida: TStringList;
  LCol: TAIDBColumnInfo;
  LFK: TAIDBForeignKeyInfo;
  LLinha, LTipo, LPKs: string;
  I: Integer;
  LTemFKSaida, LTemFKEntrada: Boolean;
begin
  LSaida := TStringList.Create;
  try
    LSaida.Add('TABELA: ' + ATable.SchemaName + '.' + ATable.TableName);

    if Trim(ATable.Description) <> '' then
      LSaida.Add('DESCRICAO: ' + ATable.Description);

    LSaida.Add('COLUNAS:');
    LPKs := '';
    for I := 0 to ATable.Columns.Count - 1 do
    begin
      LCol := ATable.Columns[I];

      LTipo := LCol.DataType;
      if (LCol.Size > 0) and
         (Pos('char', LowerCase(LCol.DataType)) > 0) then
        LTipo := LTipo + '(' + IntToStr(LCol.Size) + ')'
      else if (LCol.Precision > 0) and
              (Pos('numeric', LowerCase(LCol.DataType)) > 0) then
        LTipo := LTipo + '(' + IntToStr(LCol.Precision) + ',' + IntToStr(LCol.Scale) + ')';

      LLinha := '  - ' + LCol.ColumnName + ' (' + LTipo;
      if not LCol.Nullable then
        LLinha := LLinha + ', NOT NULL';
      if LCol.IsPrimaryKey then
      begin
        LLinha := LLinha + ', PK';
        if LPKs <> '' then
          LPKs := LPKs + ', ';
        LPKs := LPKs + LCol.ColumnName;
      end;
      if LCol.IsForeignKey then
        LLinha := LLinha + ', FK';
      LLinha := LLinha + ')';

      if Trim(LCol.Description) <> '' then
        LLinha := LLinha + ' : ' + LCol.Description;

      LSaida.Add(LLinha);
    end;

    if LPKs <> '' then
      LSaida.Add('CHAVE PRIMARIA: ' + LPKs);

    // FKs que saem desta tabela
    LTemFKSaida := False;
    for I := 0 to AIPostgreSQLDictionary1.DataDictionary.ForeignKeys.Count - 1 do
    begin
      LFK := AIPostgreSQLDictionary1.DataDictionary.ForeignKeys[I];
      if SameText(LFK.TableName, ATable.TableName) then
      begin
        if not LTemFKSaida then
        begin
          LSaida.Add('RELACIONA-SE COM:');
          LTemFKSaida := True;
        end;
        LSaida.Add(Format('  - %s.%s -> %s.%s',
          [ATable.TableName, LFK.ColumnName, LFK.RefTableName, LFK.RefColumnName]));
      end;
    end;

    // FKs que apontam para esta tabela
    LTemFKEntrada := False;
    for I := 0 to AIPostgreSQLDictionary1.DataDictionary.ForeignKeys.Count - 1 do
    begin
      LFK := AIPostgreSQLDictionary1.DataDictionary.ForeignKeys[I];
      if SameText(LFK.RefTableName, ATable.TableName) then
      begin
        if not LTemFKEntrada then
        begin
          LSaida.Add('REFERENCIADA POR:');
          LTemFKEntrada := True;
        end;
        LSaida.Add(Format('  - %s.%s', [LFK.TableName, LFK.ColumnName]));
      end;
    end;

    Result := LSaida.Text;
  finally
    LSaida.Free;
  end;
end;

procedure TfrmPGSchemaRAG.btnGerarDicionarioClick(Sender: TObject);
var
  I: Integer;
  LTabela: TAIDBTableInfo;
begin
  if not EstaConectado then
  begin
    ShowMessage('Conecte-se ao banco antes de gerar o dicionario.');
    Exit;
  end;

  SetOcupado(True);
  try
    try
      lstTabelas.Items.Clear;
      memChunkTabela.Lines.Clear;

      AIPostgreSQLDictionary1.SchemaName := Trim(edtSchema.Text);
      AIPostgreSQLDictionary1.Clear;

      Log('Gerando dicionario de dados do esquema "' + AIPostgreSQLDictionary1.SchemaName + '"...');

      if not AIPostgreSQLDictionary1.Generate then
      begin
        Log('[ERRO] Falha ao gerar dicionario: ' + AIPostgreSQLDictionary1.LastError);
        ShowMessage('Falha ao gerar dicionario: ' + AIPostgreSQLDictionary1.LastError);
        Exit;
      end;

      if chkCarregarComentarios.Checked then
        EnriquecerComComentarios;

      for I := 0 to AIPostgreSQLDictionary1.DataDictionary.Tables.Count - 1 do
      begin
        LTabela := AIPostgreSQLDictionary1.DataDictionary.Tables[I];
        lstTabelas.Items.Add(LTabela.SchemaName + '.' + LTabela.TableName);
      end;

      lblResumoDic.Caption := Format('Tabelas: %d   Colunas: %d   Views: %d   FKs: %d',
        [AIPostgreSQLDictionary1.DataDictionary.TableCount,
         AIPostgreSQLDictionary1.DataDictionary.ColumnCount,
         AIPostgreSQLDictionary1.DataDictionary.Views.Count,
         AIPostgreSQLDictionary1.DataDictionary.ForeignKeys.Count]);

      Log('Dicionario gerado. ' + lblResumoDic.Caption);

      if lstTabelas.Items.Count > 0 then
      begin
        lstTabelas.ItemIndex := 0;
        lstTabelasClick(nil);
      end;
    except
      on E: Exception do
        LogExcecao('GERAR DICIONARIO', E);
    end;
  finally
    SetOcupado(False);
  end;
end;

procedure TfrmPGSchemaRAG.lstTabelasClick(Sender: TObject);
var
  LTabela: TAIDBTableInfo;
begin
  memChunkTabela.Lines.Clear;
  if lstTabelas.ItemIndex < 0 then
    Exit;
  if lstTabelas.ItemIndex >= AIPostgreSQLDictionary1.DataDictionary.Tables.Count then
    Exit;

  LTabela := AIPostgreSQLDictionary1.DataDictionary.Tables[lstTabelas.ItemIndex];
  memChunkTabela.Text := SerializarTabela(LTabela);
end;

// ---------------------------------------------------------------------------
// Indice RAG
// ---------------------------------------------------------------------------

procedure TfrmPGSchemaRAG.btnConstruirIndiceClick(Sender: TObject);
var
  I, LChunks: Integer;
  LTabela: TAIDBTableInfo;
  LFonte, LTexto: string;
begin
  if AIPostgreSQLDictionary1.DataDictionary.Tables.Count = 0 then
  begin
    ShowMessage('Gere o dicionario de dados antes de construir o indice.');
    Exit;
  end;

  SetOcupado(True);
  try
    try
      AplicarConfigIA;
      memIndice.Lines.Clear;
      AIRAG1.Clear;

      Log('Construindo indice de esquema...');

      for I := 0 to AIPostgreSQLDictionary1.DataDictionary.Tables.Count - 1 do
      begin
        LTabela := AIPostgreSQLDictionary1.DataDictionary.Tables[I];

        // Nome de fonte com PONTO, nao barra. Isso atravessa NormalizeSourceName
        // sem perder informacao e nao depende de nenhuma alteracao no core.
        LFonte := LTabela.SchemaName + '.' + LTabela.TableName;
        LTexto := SerializarTabela(LTabela);

        LChunks := AIRAG1.AddText(LFonte, LTexto);
        memIndice.Lines.Add(Format('%-40s %d chunk(s)', [LFonte, LChunks]));
      end;

      memIndice.Lines.Add('');
      memIndice.Lines.Add(Format('Total de itens de treino: %d', [AIGraphMap1.Training.Count]));

      if AIGraphMap1.Training.Count <> AIPostgreSQLDictionary1.DataDictionary.Tables.Count then
        memIndice.Lines.Add(Format(
          '[ATENCAO] %d tabelas geraram %d itens. Se forem numeros diferentes, ' +
          'ha tabela vazia ou colisao de nome de fonte.',
          [AIPostgreSQLDictionary1.DataDictionary.Tables.Count, AIGraphMap1.Training.Count]));

      if not AIRAG1.BuildIndex then
      begin
        Log('[ERRO] Falha ao treinar o grafo: ' + AIRAG1.LastError);
        ShowMessage('Falha ao construir indice: ' + AIRAG1.LastError);
        Exit;
      end;

      lblIndiceInfo.Caption := Format('Nos: %d   Arestas: %d   Chunks: %d',
        [AIGraphMap1.NodeCount, AIGraphMap1.EdgeCount, AIGraphMap1.Training.Count]);

      memIndice.Lines.Add('');
      memIndice.Lines.Add('Indice construido com sucesso. ' + lblIndiceInfo.Caption);
      Log('Indice de esquema construido. ' + lblIndiceInfo.Caption);
    except
      on E: Exception do
        LogExcecao('CONSTRUIR INDICE', E);
    end;
  finally
    SetOcupado(False);
  end;
end;

procedure TfrmPGSchemaRAG.btnSalvarIndiceClick(Sender: TObject);
begin
  if AIGraphMap1.Training.Count = 0 then
  begin
    ShowMessage('Nao ha indice para salvar.');
    Exit;
  end;

  SaveDialog1.Title := 'Salvar indice de esquema';
  SaveDialog1.Filter := 'Grafo RAG (*.bin)|*.bin';
  SaveDialog1.DefaultExt := 'bin';
  if not SaveDialog1.Execute then
    Exit;

  SetOcupado(True);
  try
    try
      if AIRAG1.SaveIndex(SaveDialog1.FileName,
                          ChangeFileExt(SaveDialog1.FileName, '.json')) then
      begin
        Log('Indice salvo em: ' + SaveDialog1.FileName);
        ShowMessage('Indice salvo.');
      end
      else
      begin
        Log('[ERRO] ' + AIRAG1.LastError);
        ShowMessage('Falha ao salvar: ' + AIRAG1.LastError);
      end;
    except
      on E: Exception do
        LogExcecao('SALVAR INDICE', E);
    end;
  finally
    SetOcupado(False);
  end;
end;

procedure TfrmPGSchemaRAG.btnCarregarIndiceClick(Sender: TObject);
begin
  OpenDialog1.Title := 'Carregar indice de esquema';
  OpenDialog1.Filter := 'Grafo RAG (*.bin)|*.bin';
  if not OpenDialog1.Execute then
    Exit;

  SetOcupado(True);
  try
    try
      if AIRAG1.LoadIndex(OpenDialog1.FileName,
                          ChangeFileExt(OpenDialog1.FileName, '.json')) then
      begin
        lblIndiceInfo.Caption := Format('Nos: %d   Arestas: %d   Chunks: %d',
          [AIGraphMap1.NodeCount, AIGraphMap1.EdgeCount, AIGraphMap1.Training.Count]);
        Log('Indice carregado. ' + lblIndiceInfo.Caption);
        memIndice.Lines.Add('Indice carregado de: ' + OpenDialog1.FileName);

        ShowMessage('Indice carregado.'#13#10 +
          'Atencao: o indice reflete o esquema no momento em que foi salvo. ' +
          'Se o DDL mudou desde entao, gere o dicionario e reconstrua.');
      end
      else
      begin
        Log('[ERRO] ' + AIRAG1.LastError);
        ShowMessage('Falha ao carregar: ' + AIRAG1.LastError);
      end;
    except
      on E: Exception do
        LogExcecao('CARREGAR INDICE', E);
    end;
  finally
    SetOcupado(False);
  end;
end;

// ---------------------------------------------------------------------------
// Consulta
// ---------------------------------------------------------------------------

function TfrmPGSchemaRAG.LocalizarTabelaPorFonte(const AFonte: string): TAIDBTableInfo;
var
  I: Integer;
  LTabela: TAIDBTableInfo;
begin
  Result := nil;
  for I := 0 to AIPostgreSQLDictionary1.DataDictionary.Tables.Count - 1 do
  begin
    LTabela := AIPostgreSQLDictionary1.DataDictionary.Tables[I];
    if SameText(LTabela.SchemaName + '.' + LTabela.TableName, AFonte) then
      Exit(LTabela);
  end;
end;

function TfrmPGSchemaRAG.MontarContextoDDL(AFontes: TStrings): string;
var
  LSaida: TStringList;
  LTabela: TAIDBTableInfo;
  LFK: TAIDBForeignKeyInfo;
  I, J: Integer;
  LTemLigacao: Boolean;

  function FonteSelecionada(const ANomeTabela: string): Boolean;
  var
    K: Integer;
    LT: TAIDBTableInfo;
  begin
    Result := False;
    for K := 0 to AFontes.Count - 1 do
    begin
      LT := LocalizarTabelaPorFonte(AFontes[K]);
      if Assigned(LT) and SameText(LT.TableName, ANomeTabela) then
        Exit(True);
    end;
  end;

begin
  LSaida := TStringList.Create;
  try
    for I := 0 to AFontes.Count - 1 do
    begin
      LTabela := LocalizarTabelaPorFonte(AFontes[I]);
      if Assigned(LTabela) then
      begin
        LSaida.Add(SerializarTabela(LTabela));
        LSaida.Add('');
      end;
    end;

    // Bloco explicito de ligacoes entre as tabelas recuperadas: o LLM erra
    // muito menos o JOIN quando o par de colunas vem escrito.
    LTemLigacao := False;
    for J := 0 to AIPostgreSQLDictionary1.DataDictionary.ForeignKeys.Count - 1 do
    begin
      LFK := AIPostgreSQLDictionary1.DataDictionary.ForeignKeys[J];
      if FonteSelecionada(LFK.TableName) and FonteSelecionada(LFK.RefTableName) then
      begin
        if not LTemLigacao then
        begin
          LSaida.Add('LIGACOES ENTRE AS TABELAS ACIMA:');
          LTemLigacao := True;
        end;
        LSaida.Add(Format('  %s.%s = %s.%s',
          [LFK.TableName, LFK.ColumnName, LFK.RefTableName, LFK.RefColumnName]));
      end;
    end;

    Result := LSaida.Text;
  finally
    LSaida.Free;
  end;
end;

procedure TfrmPGSchemaRAG.btnRecuperarClick(Sender: TObject);
var
  LResultados, LFontes: TStringList;
  LChunk: TRAGRetrievedChunk;
  I: Integer;
  LStepRAG, LStepGen: TAIAgentMemoryMapItem;
  LSQL: string;
begin
  if Trim(edtPergunta.Text) = '' then
  begin
    ShowMessage('Digite uma pergunta.');
    Exit;
  end;

  // Garante automaticamente Conexao -> Dicionario -> Indice RAG
  if not GarantirPipelineCompleto then
  begin
    ShowMessage('Nao foi possivel concluir as etapas previas (Conexao/Dicionario/Indice RAG).');
    Exit;
  end;

  SetOcupado(True);
  try
    try
      AplicarConfigIA;
      if Assigned(AIAgentMemoryMap1) then
        AIAgentMemoryMap1.StartFlow(edtPergunta.Text, 'Consulta Schema RAG e Execucao Auto-Corrigida');

      if Assigned(AIAgentMemoryMap1) then
        LStepRAG := AIAgentMemoryMap1.BeginAgentStep('AIRAG_Retrieve', tamCustom, edtPergunta.Text)
      else
        LStepRAG := nil;

      memRecuperadas.Lines.Clear;

      LResultados := TStringList.Create;
      LFontes := TStringList.Create;
      try
        if not AIRAG1.Retrieve(edtPergunta.Text, LResultados) then
        begin
          memRecuperadas.Lines.Add('Nenhuma tabela relevante encontrada.');
          memRecuperadas.Lines.Add('Erro: ' + AIRAG1.LastError);
          Log('[AVISO] Recuperacao vazia: ' + AIRAG1.LastError);
          if Assigned(AIAgentMemoryMap1) and (LStepRAG <> nil) then
            AIAgentMemoryMap1.EndAgentStep(LStepRAG, 'Recuperacao RAG vazia', AIRAG1.LastError, 'ERROR', '');
          AtualizarExibicaoMapaMemoria;
          Exit;
        end;

        memRecuperadas.Lines.Add(Format('%d tabela(s) recuperada(s) para: "%s"',
          [LResultados.Count, edtPergunta.Text]));
        memRecuperadas.Lines.Add('');

        for I := 0 to LResultados.Count - 1 do
        begin
          LChunk := TRAGRetrievedChunk(LResultados.Objects[I]);
          if LChunk = nil then
            Continue;
          LFontes.Add(LChunk.Source);
          memRecuperadas.Lines.Add(Format('%d. %-35s score %.4f',
            [I + 1, LChunk.Source, LChunk.Score]));
        end;

        Log(Format('Recuperacao concluida: %d tabelas.', [LResultados.Count]));
        if Assigned(AIAgentMemoryMap1) and (LStepRAG <> nil) then
          AIAgentMemoryMap1.EndAgentStep(LStepRAG,
            Format('RAG recuperou %d tabelas', [LFontes.Count]), '', 'SUCCESS', LFontes.Text);

        // --- GERACAO E EXECUCAO AUTOMATICA DO SQL ---
        Log('Iniciando geracao e execucao automatica do SQL...');
        if Assigned(AIAgentMemoryMap1) then
          LStepGen := AIAgentMemoryMap1.BeginAgentStep('IA_GerarSQL', tamDecisor, edtPergunta.Text)
        else
          LStepGen := nil;

        btnGerarSQLClick(nil);
        LSQL := Trim(memSQL.Text);

        if LSQL <> '' then
        begin
          if Assigned(AIAgentMemoryMap1) and (LStepGen <> nil) then
            AIAgentMemoryMap1.EndAgentStep(LStepGen, 'SQL Gerado com sucesso pela IA', '', 'SUCCESS', LSQL);

          // Executa com autocorrecao (ate 3 tentativas)
          ExecutarSQLComAutoCorrecao(LSQL, LFontes);
        end
        else
        begin
          if Assigned(AIAgentMemoryMap1) and (LStepGen <> nil) then
            AIAgentMemoryMap1.EndAgentStep(LStepGen, 'Falha ao gerar SQL pela IA', CHATGPT1.LastError, 'ERROR', '');
        end;

      finally
        for I := 0 to LResultados.Count - 1 do
          if LResultados.Objects[I] <> nil then
            LResultados.Objects[I].Free;
        LResultados.Clear;
        LResultados.Free;
        LFontes.Free;
      end;
    except
      on E: Exception do
        LogExcecao('RECUPERAR TABELAS E EXECUTAR', E);
    end;
  finally
    AtualizarExibicaoMapaMemoria;
    SetOcupado(False);
  end;
end;

function TfrmPGSchemaRAG.LimparCercaMarkdown(const ATexto: string): string;
var
  S: string;
  P: Integer;
begin
  S := Trim(ATexto);

  if Pos('```', S) = 1 then
  begin
    Delete(S, 1, 3);
    // remove um eventual rotulo de linguagem na primeira linha
    P := Pos(#10, S);
    if (P > 0) and (P <= 12) then
      Delete(S, 1, P);
  end;

  P := Pos('```', S);
  if P > 0 then
    S := Copy(S, 1, P - 1);

  Result := Trim(S);
end;

function TfrmPGSchemaRAG.SQLSomenteSelect(const ASQL: string; out AMotivo: string): Boolean;
const
  PROIBIDOS: array[0..14] of string = (
    'INSERT', 'UPDATE', 'DELETE', 'DROP', 'ALTER', 'CREATE', 'TRUNCATE',
    'GRANT', 'REVOKE', 'COPY', 'VACUUM', 'CALL', 'MERGE', 'REFRESH', 'SET');
var
  S, U: string;
  I: Integer;
begin
  Result := False;
  AMotivo := '';

  S := Trim(ASQL);
  if S = '' then
  begin
    AMotivo := 'O comando esta vazio.';
    Exit;
  end;

  // remove ponto e virgula final, que e legitimo
  while (S <> '') and (S[Length(S)] = ';') do
    Delete(S, Length(S), 1);
  S := Trim(S);

  U := UpperCase(S);

  if (Pos('SELECT', U) <> 1) and (Pos('WITH', U) <> 1) then
  begin
    AMotivo := 'O comando precisa comecar com SELECT ou WITH.';
    Exit;
  end;

  if Pos(';', S) > 0 then
  begin
    AMotivo := 'Mais de um comando detectado (ponto e virgula no meio).';
    Exit;
  end;

  if (Pos('--', S) > 0) or (Pos('/*', S) > 0) then
  begin
    AMotivo := 'Comentarios SQL nao sao aceitos neste modo de execucao.';
    Exit;
  end;

  for I := Low(PROIBIDOS) to High(PROIBIDOS) do
  begin
    if ContemPalavraInteira(U, PROIBIDOS[I]) then
    begin
      AMotivo := 'Palavra-chave nao permitida encontrada: ' + PROIBIDOS[I];
      Exit;
    end;
  end;

  Result := True;
end;

procedure TfrmPGSchemaRAG.btnGerarSQLClick(Sender: TObject);
var
  LResultados: TStringList;
  LFontes: TStringList;
  LChunk: TRAGRetrievedChunk;
  LContexto, LPrompt, LResposta: string;
  I: Integer;
begin
  if Trim(edtPergunta.Text) = '' then
  begin
    ShowMessage('Digite uma pergunta.');
    Exit;
  end;

  if AIGraphMap1.NodeCount = 0 then
  begin
    ShowMessage('Construa ou carregue o indice antes de gerar SQL.');
    Exit;
  end;

  if Trim(edtApiKey.Text) = '' then
  begin
    ShowMessage('Informe a chave de API na aba Configuracao IA.');
    Exit;
  end;

  SetOcupado(True);
  try
    try
      AplicarConfigIA;
      memSQL.Lines.Clear;

      LResultados := TStringList.Create;
      LFontes := TStringList.Create;
      try
        if not AIRAG1.Retrieve(edtPergunta.Text, LResultados) then
        begin
          ShowMessage('Nenhuma tabela relevante foi recuperada. ' +
                      'Reformule a pergunta ou revise os comentarios do banco.');
          Log('[AVISO] Geracao abortada: recuperacao vazia.');
          Exit;
        end;

        memRecuperadas.Lines.Clear;
        for I := 0 to LResultados.Count - 1 do
        begin
          LChunk := TRAGRetrievedChunk(LResultados.Objects[I]);
          if LChunk = nil then
            Continue;
          LFontes.Add(LChunk.Source);
          memRecuperadas.Lines.Add(Format('%d. %-35s score %.4f',
            [I + 1, LChunk.Source, LChunk.Score]));
        end;

        LContexto := MontarContextoDDL(LFontes);

        if Trim(LContexto) = '' then
        begin
          ShowMessage('As tabelas recuperadas nao foram encontradas no dicionario ' +
                      'atual. Gere o dicionario novamente.');
          Log('[ERRO] Contexto DDL vazio apos recuperacao.');
          Exit;
        end;

        LPrompt :=
          memInstrucoes.Text + sLineBreak + sLineBreak +
          'REGRAS DE SAIDA:' + sLineBreak +
          '1. Responda APENAS com o comando SQL. Sem explicacao, sem comentarios, ' +
             'sem cerca de markdown.' + sLineBreak +
          '2. Use exclusivamente as tabelas e colunas listadas abaixo. Nunca invente nomes.' + sLineBreak +
          '3. Gere somente SELECT. Nunca gere INSERT, UPDATE, DELETE ou DDL.' + sLineBreak +
          '4. Use a sintaxe do PostgreSQL.' + sLineBreak +
          '5. Qualifique as tabelas com o esquema (ex.: public.clientes).' + sLineBreak +
          '6. Se o esquema fornecido nao permitir responder, devolva exatamente: ' +
             'SELECT ''esquema insuficiente'' AS aviso' + sLineBreak + sLineBreak +
          '=== ESQUEMA DISPONIVEL ===' + sLineBreak +
          LContexto + sLineBreak +
          '=== FIM DO ESQUEMA ===' + sLineBreak + sLineBreak +
          'Pergunta: ' + edtPergunta.Text;

        Log(Format('Enviando prompt de %d caracteres com %d tabelas.',
          [Length(LPrompt), LFontes.Count]));

        CHATGPT1.Prompt := LPrompt;
        if not CHATGPT1.SendQuestion(LPrompt) then
        begin
          Log('[ERRO IA] ' + CHATGPT1.LastError);
          ShowMessage('Falha na chamada a IA: ' + CHATGPT1.LastError);
          Exit;
        end;

        LResposta := CHATGPT1.Response;
        if Trim(LResposta) = '' then
          LResposta := CHATGPT1.LastResult;

        memSQL.Text := LimparCercaMarkdown(LResposta);
        Log('SQL gerado com sucesso.');
      finally
        for I := 0 to LResultados.Count - 1 do
          if LResultados.Objects[I] <> nil then
            LResultados.Objects[I].Free;
        LResultados.Clear;
        LResultados.Free;
        LFontes.Free;
      end;
    except
      on E: Exception do
        LogExcecao('GERAR SQL', E);
    end;
  finally
    SetOcupado(False);
  end;
end;

procedure TfrmPGSchemaRAG.btnExecutarSQLClick(Sender: TObject);
var
  LSQL: string;
  LFontes: TStringList;
  I: Integer;
begin
  if not GarantirConexao then
  begin
    ShowMessage('Conecte-se ao banco antes de executar.');
    Exit;
  end;

  LSQL := Trim(memSQL.Text);
  if LSQL = '' then
  begin
    ShowMessage('Nao ha SQL para executar.');
    Exit;
  end;

  LFontes := TStringList.Create;
  try
    if Assigned(AIPostgreSQLDictionary1.DataDictionary) then
    begin
      for I := 0 to AIPostgreSQLDictionary1.DataDictionary.Tables.Count - 1 do
        LFontes.Add(AIPostgreSQLDictionary1.DataDictionary.Tables[I].SchemaName + '.' +
                   AIPostgreSQLDictionary1.DataDictionary.Tables[I].TableName);
    end;

    SetOcupado(True);
    try
      ExecutarSQLComAutoCorrecao(LSQL, LFontes);
    finally
      SetOcupado(False);
      AtualizarExibicaoMapaMemoria;
    end;
  finally
    LFontes.Free;
  end;
end;

procedure TfrmPGSchemaRAG.btnLimparConsultaClick(Sender: TObject);
begin
  if ZQuery1.Active then
    ZQuery1.Close;
  memRecuperadas.Lines.Clear;
  memSQL.Lines.Clear;
  Log('Painel de consulta limpo.');
end;

end.
