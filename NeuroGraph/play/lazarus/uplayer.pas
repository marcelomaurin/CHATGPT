unit uplayer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, Controls, StdCtrls, ExtCtrls, Dialogs,
  Process, fpjson, jsonparser, IniFiles;

type
  { TfrmPlayer - Interface Lazarus Desktop para tocar/executar o modelo NeuroGraph }
  TfrmPlayer = class(TForm)
  private
    // Top Bar (Seleção de Modelo)
    PnlTop: TPanel;
    FCmbModelos: TComboBox;
    FBtnProcurarModelo: TButton;
    FOpenDialogModelo: TOpenDialog;
    FLblStatusModelo: TLabel;

    // Chat / Histórico de Diálogo
    FMemoChat: TMemo;

    // Bottom Bar (Input de Pergunta e Ações)
    PnlBottom: TPanel;
    FEditPergunta: TEdit;
    FBtnPerguntar: TButton;
    FBtnLimparChat: TButton;
    FChkManterContexto: TCheckBox;

    // Métodos
    procedure BuildUI;
    procedure PopularModelos;
    function ObterPythonExe: string;
    function ObterCaminhoPlayPy: string;
    function ObterCaminhoIni: string;
    procedure CarregarConfiguracoes;
    procedure SalvarConfiguracoes;

    // Eventos
    procedure OnProcurarModeloClick(Sender: TObject);
    procedure OnCmbModelosChange(Sender: TObject);
    procedure OnPerguntarClick(Sender: TObject);
    procedure OnPerguntaKeyPress(Sender: TObject; var Key: char);
    procedure OnLimparChatClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);

    procedure ExecutarPergunta(const APergunta: string);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmPlayer: TfrmPlayer;

implementation

constructor TfrmPlayer.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := 'NeuroGraph Player — Execução & Incerência do Modelo';
  Width := 860;
  Height := 620;
  Position := poScreenCenter;

  BuildUI;
  PopularModelos;
  CarregarConfiguracoes;
  OnClose := @FormClose;
end;

destructor TfrmPlayer.Destroy;
begin
  SalvarConfiguracoes;
  inherited Destroy;
end;

procedure TfrmPlayer.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  SalvarConfiguracoes;
  CloseAction := caFree;
end;

function TfrmPlayer.ObterCaminhoIni: string;
begin
  Result := ExtractFilePath(ParamStr(0)) + 'neurograph_player.ini';
end;

procedure TfrmPlayer.SalvarConfiguracoes;
var
  Ini: TIniFile;
begin
  try
    Ini := TIniFile.Create(ObterCaminhoIni);
    try
      Ini.WriteString('Player', 'UltimoModelo', FCmbModelos.Text);
      Ini.WriteBool('Player', 'ManterContexto', FChkManterContexto.Checked);
    finally
      Ini.Free;
    end;
  except
  end;
end;

procedure TfrmPlayer.CarregarConfiguracoes;
var
  Ini: TIniFile;
  ModSalvo: string;
  Idx: Integer;
begin
  if not FileExists(ObterCaminhoIni) then
    Exit;

  try
    Ini := TIniFile.Create(ObterCaminhoIni);
    try
      ModSalvo := Ini.ReadString('Player', 'UltimoModelo', '');
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
        OnCmbModelosChange(FCmbModelos);
      end;
      FChkManterContexto.Checked := Ini.ReadBool('Player', 'ManterContexto', True);
    finally
      Ini.Free;
    end;
  except
  end;
end;

function TfrmPlayer.ObterPythonExe: string;
begin
  if FileExists('C:\Python312\python.exe') then
    Result := 'C:\Python312\python.exe'
  else
    Result := 'python.exe';
end;

function TfrmPlayer.ObterCaminhoPlayPy: string;
var
  Base: string;
begin
  Base := ExtractFilePath(ParamStr(0));
  // 1. Mesmo diretório
  if FileExists(Base + 'play.py') then
    Exit(Base + 'play.py');
  // 2. Pasta pai (D:\projetos\maurinsoft\CHATGPT\NeuroGraph\play)
  if FileExists(ExtractFilePath(ExcludeTrailingPathDelimiter(Base)) + 'play.py') then
    Exit(ExtractFilePath(ExcludeTrailingPathDelimiter(Base)) + 'play.py');
  // 3. Caminho absoluto padrão
  Result := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\play\play.py';
end;

procedure TfrmPlayer.BuildUI;
var
  LblMod, LblDica: TLabel;
begin
  // Painel Superior (Seleção de Modelo)
  PnlTop := TPanel.Create(Self);
  PnlTop.Parent := Self;
  PnlTop.Align := alTop;
  PnlTop.Height := 58;
  PnlTop.BevelOuter := bvNone;

  LblMod := TLabel.Create(Self);
  LblMod.Parent := PnlTop;
  LblMod.Caption := 'Modelo NeuroGraph (.ngs):';
  LblMod.Left := 14;
  LblMod.Top := 18;
  LblMod.Font.Style := [fsBold];

  FCmbModelos := TComboBox.Create(Self);
  FCmbModelos.Parent := PnlTop;
  FCmbModelos.Left := 195;
  FCmbModelos.Top := 14;
  FCmbModelos.Width := 460;
  FCmbModelos.OnChange := @OnCmbModelosChange;

  FBtnProcurarModelo := TButton.Create(Self);
  FBtnProcurarModelo.Parent := PnlTop;
  FBtnProcurarModelo.Caption := 'Procurar...';
  FBtnProcurarModelo.Left := 665;
  FBtnProcurarModelo.Top := 12;
  FBtnProcurarModelo.Width := 90;
  FBtnProcurarModelo.Height := 30;
  FBtnProcurarModelo.OnClick := @OnProcurarModeloClick;

  FOpenDialogModelo := TOpenDialog.Create(Self);
  FOpenDialogModelo.Title := 'Selecionar Modelo NeuroGraph';
  FOpenDialogModelo.Filter := 'Modelos NeuroGraph (*.ngs)|*.ngs|Todos os Arquivos (*.*)|*.*';

  FLblStatusModelo := TLabel.Create(Self);
  FLblStatusModelo.Parent := PnlTop;
  FLblStatusModelo.Left := 195;
  FLblStatusModelo.Top := 40;
  FLblStatusModelo.Caption := 'Pronto.';
  FLblStatusModelo.Font.Color := clGray;

  // Painel Inferior (Entrada da pergunta e botões)
  PnlBottom := TPanel.Create(Self);
  PnlBottom.Parent := Self;
  PnlBottom.Align := alBottom;
  PnlBottom.Height := 92;
  PnlBottom.BevelOuter := bvNone;

  LblDica := TLabel.Create(Self);
  LblDica.Parent := PnlBottom;
  LblDica.Caption := 'Faça sua pergunta ao modelo (Pressione Enter para enviar):';
  LblDica.Left := 14;
  LblDica.Top := 8;
  LblDica.Font.Style := [fsBold];

  FEditPergunta := TEdit.Create(Self);
  FEditPergunta.Parent := PnlBottom;
  FEditPergunta.Left := 14;
  FEditPergunta.Top := 28;
  FEditPergunta.Width := 650;
  FEditPergunta.Height := 28;
  FEditPergunta.OnKeyPress := @OnPerguntaKeyPress;

  FBtnPerguntar := TButton.Create(Self);
  FBtnPerguntar.Parent := PnlBottom;
  FBtnPerguntar.Caption := 'Perguntar';
  FBtnPerguntar.Left := 672;
  FBtnPerguntar.Top := 26;
  FBtnPerguntar.Width := 90;
  FBtnPerguntar.Height := 30;
  FBtnPerguntar.OnClick := @OnPerguntarClick;

  FBtnLimparChat := TButton.Create(Self);
  FBtnLimparChat.Parent := PnlBottom;
  FBtnLimparChat.Caption := 'Limpar Chat';
  FBtnLimparChat.Left := 768;
  FBtnLimparChat.Top := 26;
  FBtnLimparChat.Width := 80;
  FBtnLimparChat.Height := 30;
  FBtnLimparChat.OnClick := @OnLimparChatClick;

  FChkManterContexto := TCheckBox.Create(Self);
  FChkManterContexto.Parent := PnlBottom;
  FChkManterContexto.Left := 14;
  FChkManterContexto.Top := 64;
  FChkManterContexto.Caption := 'Manter Contexto de Sessão (Sessão de Conversa Ativa)';
  FChkManterContexto.Checked := True;

  // Memo Central de Chat
  FMemoChat := TMemo.Create(Self);
  FMemoChat.Parent := Self;
  FMemoChat.Align := alClient;
  FMemoChat.ReadOnly := True;
  FMemoChat.ScrollBars := ssAutoBoth;
  FMemoChat.Font.Name := 'Segoe UI';
  FMemoChat.Font.Size := 10;
  FMemoChat.Color := $FAFAFA;

  FMemoChat.Lines.Add('=== NeuroGraph Player Inicializado ===');
  FMemoChat.Lines.Add('Digite uma pergunta abaixo para que o modelo processe pelo grafo associativo e retorne a resposta.');
  FMemoChat.Lines.Add('');
end;

procedure TfrmPlayer.PopularModelos;
var
  Caminhos: array[0..3] of string;
  i: Integer;
  SR: TSearchRec;
  Pasta: string;
begin
  FCmbModelos.Items.Clear;

  Caminhos[0] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\treino\modelos';
  Caminhos[1] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\results';
  Caminhos[2] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\experiments\contextual_v7\baseline_v6';
  Caminhos[3] := 'D:\projetos\maurinsoft\CHATGPT\NeuroGraph\history\2026-11-12';

  for i := 0 to High(Caminhos) do
  begin
    Pasta := Caminhos[i];
    if DirectoryExists(Pasta) then
    begin
      if FindFirst(Pasta + '\*.ngs', faAnyFile, SR) = 0 then
      begin
        repeat
          if (SR.Attr and faDirectory) = 0 then
            FCmbModelos.Items.Add(Pasta + '\' + SR.Name);
        until FindNext(SR) <> 0;
        FindClose(SR);
      end;
    end;
  end;

  if FCmbModelos.Items.Count > 0 then
  begin
    FCmbModelos.ItemIndex := 0;
    OnCmbModelosChange(FCmbModelos);
  end;
end;

procedure TfrmPlayer.OnProcurarModeloClick(Sender: TObject);
begin
  if FOpenDialogModelo.Execute then
  begin
    FCmbModelos.Items.Insert(0, FOpenDialogModelo.FileName);
    FCmbModelos.ItemIndex := 0;
    OnCmbModelosChange(FCmbModelos);
  end;
end;

procedure TfrmPlayer.OnCmbModelosChange(Sender: TObject);
var
  Arq: string;
  FSize: Int64;
begin
  Arq := Trim(FCmbModelos.Text);
  if FileExists(Arq) then
  begin
    FSize := 0;
    with TFileStream.Create(Arq, fmOpenRead or fmShareDenyNone) do
    try
      FSize := Size;
    finally
      Free;
    end;
    FLblStatusModelo.Caption := Format('Arquivo encontrado: %s (%.1f KB)', [ExtractFileName(Arq), FSize / 1024]);
    FLblStatusModelo.Font.Color := $007000;
  end
  else
  begin
    FLblStatusModelo.Caption := 'Arquivo de modelo não encontrado no caminho indicado.';
    FLblStatusModelo.Font.Color := clRed;
  end;
end;

procedure TfrmPlayer.OnPerguntarClick(Sender: TObject);
var
  Pergunta: string;
begin
  Pergunta := Trim(FEditPergunta.Text);
  if Pergunta = '' then
  begin
    ShowMessage('Por favor, informe uma pergunta.');
    Exit;
  end;

  ExecutarPergunta(Pergunta);
end;

procedure TfrmPlayer.OnPerguntaKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    OnPerguntarClick(Sender);
  end;
end;

procedure TfrmPlayer.OnLimparChatClick(Sender: TObject);
begin
  FMemoChat.Clear;
  FMemoChat.Lines.Add('=== Chat Reiniciado ===');
  FMemoChat.Lines.Add('');
end;

procedure TfrmPlayer.ExecutarPergunta(const APergunta: string);
var
  Proc: TProcess;
  CaminhoPlay, CaminhoModelo: string;
  SaidaString, Linha: string;
  Buffer: array[0..2047] of char;
  BytesRead: Integer;
  Parser: TJSONParser;
  Data: TJSONData;
  Obj: TJSONObject;
  RespostaTexto: string;
  Abstencao: Boolean;
  Motivo: string;
begin
  CaminhoPlay := ObterCaminhoPlayPy;
  if not FileExists(CaminhoPlay) then
  begin
    ShowMessage('Script play.py não encontrado em: ' + CaminhoPlay);
    Exit;
  end;

  CaminhoModelo := Trim(FCmbModelos.Text);
  if not FileExists(CaminhoModelo) then
  begin
    ShowMessage('Modelo NeuroGraph selecionado não existe: ' + CaminhoModelo);
    Exit;
  end;

  FMemoChat.Lines.Add('Você: ' + APergunta);
  FEditPergunta.Text := '';
  FBtnPerguntar.Enabled := False;
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;

  Proc := TProcess.Create(nil);
  try
    Proc.Executable := ObterPythonExe;
    Proc.Parameters.Add('-X');
    Proc.Parameters.Add('utf8');
    Proc.Parameters.Add('-u');
    Proc.Parameters.Add(CaminhoPlay);
    Proc.Parameters.Add('--modelo');
    Proc.Parameters.Add(CaminhoModelo);
    Proc.Parameters.Add('--pergunta');
    Proc.Parameters.Add(APergunta);
    Proc.Parameters.Add('--json');
    if not FChkManterContexto.Checked then
      Proc.Parameters.Add('--sem-contexto');

    Proc.Options := [poUsePipes, poStderrToOutPut];
    Proc.ShowWindow := swoNone;

    Proc.Execute;

    SaidaString := '';
    while Proc.Running or (Proc.Output.NumBytesAvailable > 0) do
    begin
      if Proc.Output.NumBytesAvailable > 0 then
      begin
        BytesRead := Proc.Output.Read(Buffer[0], SizeOf(Buffer) - 1);
        if BytesRead > 0 then
        begin
          Buffer[BytesRead] := #0;
          SaidaString := SaidaString + StrPas(Buffer);
        end;
      end
      else
        Sleep(20);
      Application.ProcessMessages;
    end;

    // Tenta interpretar como JSON
    RespostaTexto := '';
    Abstencao := False;
    Motivo := '';

    if Trim(SaidaString) <> '' then
    begin
      try
        Parser := TJSONParser.Create(SaidaString);
        try
          Data := Parser.Parse;
          if Assigned(Data) and (Data is TJSONObject) then
          begin
            Obj := TJSONObject(Data);
            RespostaTexto := Obj.Get('resposta', '');
            Abstencao := Obj.Get('abstencao', False);
            Motivo := Obj.Get('motivo', '');
          end;
        finally
          Parser.Free;
          if Assigned(Data) then Data.Free;
        end;
      except
        // Não foi JSON válido, usa a saída bruta
        RespostaTexto := Trim(SaidaString);
      end;
    end;

    if RespostaTexto = '' then
      RespostaTexto := '(Sem resposta gerada pelo modelo)';

    FMemoChat.Lines.Add('NeuroGraph: ' + RespostaTexto);
    if Abstencao and (Motivo <> '') then
      FMemoChat.Lines.Add('  [Nota de Abstenção]: ' + Motivo);
    FMemoChat.Lines.Add('');

    // Rola para o fim
    FMemoChat.SelStart := Length(FMemoChat.Text);
  finally
    Proc.Free;
    FBtnPerguntar.Enabled := True;
    Screen.Cursor := crDefault;
    FEditPergunta.SetFocus;
  end;
end;

end.
