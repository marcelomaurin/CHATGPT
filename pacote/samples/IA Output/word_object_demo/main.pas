unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, ComCtrls,
  aiworddocument, aiwordtypes, aiwordobjects, aiwordviewer;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    // PageControl tabs
    pgControl: TPageControl;
    tabPrincipal: TTabSheet;
    tabComandos: TTabSheet;
    tabPreview: TTabSheet;

    // Panel & Buttons on TabPrincipal
    pnlLeft: TPanel;
    btnNew: TButton;
    btnLoad: TButton;
    btnSave: TButton;
    btnGenerate: TButton;
    btnClearLog: TButton;
    memLog: TMemo;

    // Panels on TabComandos
    pnlCmdLeft: TPanel;
    pnlCmdRight: TPanel;

    // GroupBox Texto & buttons
    grpTexto: TGroupBox;
    lblTexto: TLabel;
    edtTexto: TEdit;
    btnAddRun: TButton;
    btnAddParagraph: TButton;
    btnAddHeading: TButton;
    lblHeadingLevel: TLabel;
    cbHeadingLevel: TComboBox;

    // GroupBox Fonte & controls
    grpFonte: TGroupBox;
    lblFonte: TLabel;
    cbFontName: TComboBox;
    lblTamanho: TLabel;
    cbFontSize: TComboBox;
    chkBold: TCheckBox;
    chkItalic: TCheckBox;
    chkUnderline: TCheckBox;
    btnChooseColor: TButton;
    btnChooseBgColor: TButton;
    btnFormatLine: TButton;

    // GroupBox Alinhamento
    grpAlinhamento: TGroupBox;
    btnAlignLeft: TButton;
    btnAlignCenter: TButton;
    btnAlignRight: TButton;
    btnAlignJustify: TButton;

    // Page Break button
    btnCmdPageBreak: TButton;

    // GroupBox Tabela
    grpTabela: TGroupBox;
    lblLinhas: TLabel;
    cbRows: TComboBox;
    lblColunas: TLabel;
    cbCols: TComboBox;
    chkHeader: TCheckBox;
    lblCellText: TLabel;
    edtCellText: TEdit;
    btnAddCustomTable: TButton;

    // GroupBox Imagem
    grpImagem: TGroupBox;
    lblImgInfo: TLabel;
    btnAddCustomImage: TButton;

    // Preview container
    pnPreview: TPanel;

    // Core Components
    WordDoc: TAIWordDocument;
    WordViewer: TAIWordViewer;

    // Form Event Handlers
    procedure FormCreate(Sender: TObject);
    procedure btnNewClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);

    // Document Commands Event Handlers
    procedure btnAddRunClick(Sender: TObject);
    procedure btnAddParagraphClick(Sender: TObject);
    procedure btnAddHeadingClick(Sender: TObject);
    procedure btnChooseColorClick(Sender: TObject);
    procedure btnChooseBgColorClick(Sender: TObject);
    procedure btnFormatLineClick(Sender: TObject);
    procedure btnAlignLeftClick(Sender: TObject);
    procedure btnAlignCenterClick(Sender: TObject);
    procedure btnAlignRightClick(Sender: TObject);
    procedure btnAlignJustifyClick(Sender: TObject);
    procedure btnCmdPageBreakClick(Sender: TObject);
    procedure btnAddCustomTableClick(Sender: TObject);
    procedure btnAddCustomImageClick(Sender: TObject);
  private
    FSelectedColor: TColor;
    FSelectedBgColor: TColor;
    procedure AddLog(const Msg: string);
    procedure UpdatePreview;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FSelectedColor := clBlack;
  FSelectedBgColor := clWhite;
  WordViewer.AttachToPanel(pnPreview);
  WordViewer.Zoom := 100;
  AddLog('Word Object Demo inicializado.');
  AddLog('Componente TAIWordDocument e TAIWordViewer prontos.');
end;

procedure TfrmMain.AddLog(const Msg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + Msg);
end;

procedure TfrmMain.UpdatePreview;
begin
  if WordViewer.LoadFromDocument(WordDoc) then
    AddLog('Visualização gráfica atualizada.')
  else
    AddLog('Erro ao atualizar visualização: ' + WordViewer.LastError);
end;

procedure TfrmMain.btnNewClick(Sender: TObject);
begin
  WordDoc.NewDocument;
  AddLog('Novo documento inicializado na memória.');
  UpdatePreview;
end;

procedure TfrmMain.btnLoadClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Filter := 'Documentos Word (*.docx)|*.docx';
    OpenDlg.InitialDir := ExtractFilePath(Application.ExeName);
    if OpenDlg.Execute then
    begin
      if WordDoc.LoadFromFile(OpenDlg.FileName) then
      begin
        AddLog('Documento carregado com sucesso: ' + OpenDlg.FileName);
        UpdatePreview;
      end
      else
        AddLog('Erro ao carregar documento: ' + WordDoc.LastError);
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
var
  SaveDlg: TSaveDialog;
begin
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Filter := 'Documento Word (*.docx)|*.docx';
    SaveDlg.FileName := WordDoc.FileName;
    if SaveDlg.Execute then
    begin
      if WordDoc.SaveToFile(SaveDlg.FileName) then
        AddLog('Documento salvo: ' + SaveDlg.FileName)
      else
        AddLog('Erro ao salvar documento: ' + WordDoc.LastError);
    end;
  finally
    SaveDlg.Free;
  end;
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
var
  P: TAIWordParagraph;
  R: TAIWordRun;
  T: TAIWordTable;
  LogoPath: string;
  SavePath: string;
begin
  WordDoc.NewDocument;

  WordDoc.Title := 'Documento Exemplo de 3 Páginas';
  WordDoc.Author := 'Lazarus AI Suite';

  WordDoc.PageSetup.PaperSize := wpsA4;
  WordDoc.PageSetup.MarginLeftMM := 25;
  WordDoc.PageSetup.MarginRightMM := 25;

  // Cabeçalho e Rodapé Padrão
  WordDoc.Header.AddParagraph('Lazarus AI Suite - TAIWordDocument Demo');
  WordDoc.Footer.AddParagraph('Página ');
  WordDoc.Footer.AddPageNumber;

  // --- FOLHA 1: Título e Texto Padrão com Imagem ---
  WordDoc.AddTitle('Relatório Técnico Automatizado');
  
  P := WordDoc.AddParagraph('Este documento de demonstração foi gerado pelo componente ');
  R := P.AddRun('TAIWordDocument');
  R.Bold := True;
  R.Color := clBlue;
  P.AddRun(' e ilustra a capacidade de criação de documentos DOCX nativos em ambiente Lazarus/Free Pascal sem dependências externas.');
  P.Alignment := waJustify;
  P.FontName := 'Arial';
  P.FontSize := 11;

  P := WordDoc.AddParagraph('Abaixo, apresentamos o logotipo oficial da suíte, que serve como imagem padrão de teste e validação de importação de mídias no WordprocessingML.');
  P.Alignment := waJustify;
  P.FontName := 'Arial';
  P.FontSize := 11;

  // Busca imagem padrão
  LogoPath := ExtractFilePath(Application.ExeName) + 'imagem' + PathDelim + 'logo.png';
  if not FileExists(LogoPath) then
    LogoPath := 'imagem/logo.png';

  if FileExists(LogoPath) then
  begin
    WordDoc.AddImage(LogoPath, 60, 45, wipInline);
    AddLog('Imagem padrão (logo.png) adicionada à Folha 1.');
  end
  else
    AddLog('Aviso: imagem/logo.png não foi localizado para inclusão.');

  // --- FOLHA 2: Tabela Padrão ---
  WordDoc.AddPageBreak;
  WordDoc.AddHeading('Tabela de Dados e Métricas', 1);

  P := WordDoc.AddParagraph('Esta página demonstra o suporte a tabelas nativas com bordas e preenchimento de células, permitindo estruturar relatórios com facilidade:');
  P.Alignment := waJustify;
  P.FontName := 'Arial';
  P.FontSize := 11;

  // Tabela padrão 4 linhas x 3 colunas
  T := WordDoc.AddTable(4, 3);
  
  // Cabeçalho da Tabela
  T.Cell(0, 0).Text := 'Módulo';
  T.Cell(0, 1).Text := 'Status';
  T.Cell(0, 2).Text := 'Métrica de Performance';

  // Linha 1
  T.Cell(1, 0).Text := 'Leitor XML';
  T.Cell(1, 1).Text := 'Homologado';
  T.Cell(1, 2).Text := '99.8% de Precisão';

  // Linha 2
  T.Cell(2, 0).Text := 'Renderizador LCL';
  T.Cell(2, 1).Text := 'Estável';
  T.Cell(2, 2).Text := '120 FPS';

  // Linha 3
  T.Cell(3, 0).Text := 'Empacotador ZIP';
  T.Cell(3, 1).Text := 'OK';
  T.Cell(3, 2).Text := 'Compactação Máxima';

  P := WordDoc.AddParagraph('');

  // --- FOLHA 3: Texto de Conclusão e Teste Adicional ---
  WordDoc.AddPageBreak;
  WordDoc.AddHeading('Conclusão do Relatório', 1);

  P := WordDoc.AddParagraph('O teste padrão foi concluído com sucesso em todas as três folhas propostas. O documento agora conta com cabeçalho, rodapé com número de página dinâmico, parágrafos formatados, imagem inserida nativamente e uma tabela estruturada.');
  P.Alignment := waJustify;
  P.FontName := 'Arial';
  P.FontSize := 11;

  P := WordDoc.AddParagraph('Este arquivo foi gerado de forma totalmente em conformidade com o padrão OpenXML (ISO/IEC 29500), garantindo portabilidade entre o Microsoft Word, LibreOffice Writer e o visualizador integrado TAIWordViewer.');
  P.Alignment := waJustify;
  P.FontName := 'Arial';
  P.FontSize := 11;
  P.Italic := True;

  SavePath := ExtractFilePath(Application.ExeName) + 'saida_word_object_demo.docx';
  if WordDoc.SaveToFile(SavePath) then
  begin
    AddLog('DOCX gerado e salvo com sucesso em: ' + SavePath);
    UpdatePreview;
    pgControl.ActivePage := tabPreview;
  end
  else
    AddLog('Erro ao gerar/salvar DOCX: ' + WordDoc.LastError);
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memLog.Clear;
end;

procedure TfrmMain.btnAddRunClick(Sender: TObject);
var
  P: TAIWordParagraph;
  R: TAIWordRun;
begin
  if WordDoc.Paragraphs.Count = 0 then
    WordDoc.AddParagraph('');
    
  P := WordDoc.Paragraphs[WordDoc.Paragraphs.Count - 1];
  R := P.AddRun(edtTexto.Text);
  R.FontName := cbFontName.Text;
  R.FontSize := StrToIntDef(cbFontSize.Text, 12);
  R.Bold := chkBold.Checked;
  R.Italic := chkItalic.Checked;
  R.Underline := chkUnderline.Checked;
  R.Color := FSelectedColor;
  if FSelectedBgColor <> clWhite then
    R.HighlightColor := FSelectedBgColor;

  AddLog('Linha (Run) adicionada ao parágrafo atual: "' + edtTexto.Text + '"');
  UpdatePreview;
end;

procedure TfrmMain.btnAddParagraphClick(Sender: TObject);
var
  P: TAIWordParagraph;
begin
  P := WordDoc.AddParagraph(edtTexto.Text);
  P.FontName := cbFontName.Text;
  P.FontSize := StrToIntDef(cbFontSize.Text, 12);
  P.Bold := chkBold.Checked;
  P.Italic := chkItalic.Checked;
  P.Underline := chkUnderline.Checked;
  
  AddLog('Parágrafo adicionado: "' + edtTexto.Text + '"');
  UpdatePreview;
end;

procedure TfrmMain.btnAddHeadingClick(Sender: TObject);
var
  Level: Integer;
begin
  Level := StrToIntDef(cbHeadingLevel.Text, 1);
  WordDoc.AddHeading(edtTexto.Text, Level);
  AddLog('Título (Heading ' + IntToStr(Level) + ') adicionado: "' + edtTexto.Text + '"');
  UpdatePreview;
end;

procedure TfrmMain.btnChooseColorClick(Sender: TObject);
var
  CDlg: TColorDialog;
begin
  CDlg := TColorDialog.Create(Self);
  try
    CDlg.Color := FSelectedColor;
    if CDlg.Execute then
    begin
      FSelectedColor := CDlg.Color;
      AddLog('Cor de letra selecionada.');
    end;
  finally
    CDlg.Free;
  end;
end;

procedure TfrmMain.btnChooseBgColorClick(Sender: TObject);
var
  CDlg: TColorDialog;
begin
  CDlg := TColorDialog.Create(Self);
  try
    CDlg.Color := FSelectedBgColor;
    if CDlg.Execute then
    begin
      FSelectedBgColor := CDlg.Color;
      AddLog('Cor de fundo selecionada.');
    end;
  finally
    CDlg.Free;
  end;
end;

procedure TfrmMain.btnFormatLineClick(Sender: TObject);
var
  P: TAIWordParagraph;
begin
  if WordDoc.Paragraphs.Count > 0 then
  begin
    P := WordDoc.Paragraphs[WordDoc.Paragraphs.Count - 1];
    P.FontName := cbFontName.Text;
    P.FontSize := StrToIntDef(cbFontSize.Text, 12);
    P.Bold := chkBold.Checked;
    P.Italic := chkItalic.Checked;
    P.Underline := chkUnderline.Checked;
    AddLog('Formatado último parágrafo com as configurações da tela.');
    UpdatePreview;
  end
  else
    AddLog('Aviso: Nenhum parágrafo no documento para formatar.');
end;

procedure TfrmMain.btnAlignLeftClick(Sender: TObject);
var
  P: TAIWordParagraph;
begin
  if WordDoc.Paragraphs.Count > 0 then
  begin
    P := WordDoc.Paragraphs[WordDoc.Paragraphs.Count - 1];
    P.Alignment := waLeft;
    AddLog('Alinhamento à esquerda aplicado.');
    UpdatePreview;
  end;
end;

procedure TfrmMain.btnAlignCenterClick(Sender: TObject);
var
  P: TAIWordParagraph;
begin
  if WordDoc.Paragraphs.Count > 0 then
  begin
    P := WordDoc.Paragraphs[WordDoc.Paragraphs.Count - 1];
    P.Alignment := waCenter;
    AddLog('Alinhamento ao centro aplicado.');
    UpdatePreview;
  end;
end;

procedure TfrmMain.btnAlignRightClick(Sender: TObject);
var
  P: TAIWordParagraph;
begin
  if WordDoc.Paragraphs.Count > 0 then
  begin
    P := WordDoc.Paragraphs[WordDoc.Paragraphs.Count - 1];
    P.Alignment := waRight;
    AddLog('Alinhamento à direita aplicado.');
    UpdatePreview;
  end;
end;

procedure TfrmMain.btnAlignJustifyClick(Sender: TObject);
var
  P: TAIWordParagraph;
begin
  if WordDoc.Paragraphs.Count > 0 then
  begin
    P := WordDoc.Paragraphs[WordDoc.Paragraphs.Count - 1];
    P.Alignment := waJustify;
    AddLog('Alinhamento justificado aplicado.');
    UpdatePreview;
  end;
end;

procedure TfrmMain.btnCmdPageBreakClick(Sender: TObject);
begin
  WordDoc.AddPageBreak;
  AddLog('Quebra de página inserida.');
  UpdatePreview;
end;

procedure TfrmMain.btnAddCustomTableClick(Sender: TObject);
var
  Rows, Cols: Integer;
  T: TAIWordTable;
  R, C: Integer;
begin
  Rows := StrToIntDef(cbRows.Text, 3);
  Cols := StrToIntDef(cbCols.Text, 3);
  T := WordDoc.AddTable(Rows, Cols);
  if Assigned(T) then
  begin
    for R := 0 to Rows - 1 do
    begin
      for C := 0 to Cols - 1 do
      begin
        T.Cell(R, C).Text := edtCellText.Text + ' (' + IntToStr(R) + ',' + IntToStr(C) + ')';
        if (R = 0) and chkHeader.Checked then
        begin
          T.Cell(R, C).Bold := True;
          T.Cell(R, C).ShadingColor := clNavy; // Cor azul de preenchimento
        end;
      end;
    end;
    AddLog('Tabela customizada ' + IntToStr(Rows) + 'x' + IntToStr(Cols) + ' inserida com preenchimento.');
    UpdatePreview;
  end
  else
    AddLog('Erro ao criar tabela: ' + WordDoc.LastError);
end;

procedure TfrmMain.btnAddCustomImageClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
  Img: TAIWordImage;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Filter := 'Imagens (*.png;*.jpg;*.jpeg)|*.png;*.jpg;*.jpeg';
    if OpenDlg.Execute then
    begin
      Img := WordDoc.AddImage(OpenDlg.FileName, 60, 45, wipInline);
      if Assigned(Img) then
      begin
        AddLog('Imagem inserida com sucesso: ' + OpenDlg.FileName);
        UpdatePreview;
      end
      else
        AddLog('Erro ao inserir imagem: ' + WordDoc.LastError);
    end;
  finally
    OpenDlg.Free;
  end;
end;

end.
