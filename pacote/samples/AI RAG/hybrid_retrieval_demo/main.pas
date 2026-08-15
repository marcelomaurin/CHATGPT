unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ComCtrls, aigraphmap, airetrieval, airag;

type

  { TfrmHybridRetrievalDemo }

  TfrmHybridRetrievalDemo = class(TForm)
    AIBM25Retriever1: TAIBM25Retriever;
    AIGraphMap1: TAIGraphMap;
    AILocalEmbeddingProvider1: TAILocalEmbeddingProvider;
    AIRAG1: TAIRAG;
    AIVectorRetriever1: TAIVectorRetriever;
    AIVectorStore1: TAIVectorStore;
    btnAddDoc: TButton;
    btnBuildIndex: TButton;
    btnClearDocs: TButton;
    btnLoadDefaults: TButton;
    btnRetrieve: TButton;
    cbRetrievalMode: TComboBox;
    edtDocName: TEdit;
    edtQuery: TEdit;
    edtTopK: TEdit;
    gbDocuments: TGroupBox;
    gbQuery: TGroupBox;
    lblDetail: TLabel;
    lblDocContent: TLabel;
    lblDocName: TLabel;
    lblIndexedList: TLabel;
    lblMode: TLabel;
    lblQuery: TLabel;
    lblResults: TLabel;
    lblStatus: TLabel;
    lblSubtitle: TLabel;
    lblTitle: TLabel;
    lblTopK: TLabel;
    lbDocs: TListBox;
    lvResults: TListView;
    mmoDetail: TMemo;
    mmoDocContent: TMemo;
    pnlMain: TPanel;
    pnlStatus: TPanel;
    pnlTop: TPanel;
    splVertical: TSplitter;
    procedure btnAddDocClick(Sender: TObject);
    procedure btnBuildIndexClick(Sender: TObject);
    procedure btnClearDocsClick(Sender: TObject);
    procedure btnLoadDefaultsClick(Sender: TObject);
    procedure btnRetrieveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvResultsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
  private
    FIndexedDocs: TStringList;
    procedure LoadSampleDocs;
    procedure UpdateDocsList;
  public
  end;

var
  frmHybridRetrievalDemo: TfrmHybridRetrievalDemo;

implementation

{$R *.lfm}

{ TfrmHybridRetrievalDemo }

procedure TfrmHybridRetrievalDemo.FormCreate(Sender: TObject);
begin
  FIndexedDocs := TStringList.Create;
  LoadSampleDocs;
  btnBuildIndexClick(nil);
  btnRetrieveClick(nil);
end;

procedure TfrmHybridRetrievalDemo.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FIndexedDocs);
end;

procedure TfrmHybridRetrievalDemo.LoadSampleDocs;
begin
  FIndexedDocs.Clear;
  FIndexedDocs.AddPair('lazarus.txt',
    'Lazarus cria aplicativos nativos usando o compilador Free Pascal.');
  FIndexedDocs.AddPair('python.txt',
    'Python executa codigo por um interpretador e oferece ambientes virtuais.');
  FIndexedDocs.AddPair('postgresql.txt',
    'PostgreSQL e um banco relacional com transacoes e indices SQL.');
  UpdateDocsList;
end;

procedure TfrmHybridRetrievalDemo.UpdateDocsList;
var
  I: Integer;
begin
  lbDocs.Items.Clear;
  for I := 0 to FIndexedDocs.Count - 1 do
    lbDocs.Items.Add(Format('%s (%d chars)', [FIndexedDocs.Names[I], Length(FIndexedDocs.ValueFromIndex[I])]));
end;

procedure TfrmHybridRetrievalDemo.btnAddDocClick(Sender: TObject);
var
  DocName, Content: string;
begin
  DocName := Trim(edtDocName.Text);
  Content := Trim(mmoDocContent.Text);
  if DocName = '' then
  begin
    ShowMessage('Informe o nome do documento.');
    edtDocName.SetFocus;
    Exit;
  end;
  if Content = '' then
  begin
    ShowMessage('Informe o conteúdo do documento.');
    mmoDocContent.SetFocus;
    Exit;
  end;

  FIndexedDocs.Values[DocName] := Content;
  UpdateDocsList;
  lblStatus.Caption := Format('Documento "%s" adicionado. Clique em "Construir Índice" para atualizar.', [DocName]);
end;

procedure TfrmHybridRetrievalDemo.btnLoadDefaultsClick(Sender: TObject);
begin
  LoadSampleDocs;
  btnBuildIndexClick(nil);
end;

procedure TfrmHybridRetrievalDemo.btnClearDocsClick(Sender: TObject);
begin
  FIndexedDocs.Clear;
  UpdateDocsList;
  AIRAG1.Clear;
  lvResults.Items.Clear;
  mmoDetail.Clear;
  lblStatus.Caption := 'Base de documentos limpa.';
end;

procedure TfrmHybridRetrievalDemo.btnBuildIndexClick(Sender: TObject);
var
  I: Integer;
  StartTick: QWord;
begin
  if FIndexedDocs.Count = 0 then
  begin
    lblStatus.Caption := 'Nenhum documento para indexar.';
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    StartTick := GetTickCount64;
    AIRAG1.Clear;
    for I := 0 to FIndexedDocs.Count - 1 do
      AIRAG1.AddText(FIndexedDocs.Names[I], FIndexedDocs.ValueFromIndex[I]);

    if not AIRAG1.BuildIndex then
    begin
      ShowMessage('Erro ao construir índice: ' + AIRAG1.LastError);
      lblStatus.Caption := 'Falha na indexação: ' + AIRAG1.LastError;
      Exit;
    end;

    lblStatus.Caption := Format('Índice construído com sucesso! %d documento(s) indexados em %d ms.',
      [FIndexedDocs.Count, GetTickCount64 - StartTick]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmHybridRetrievalDemo.btnRetrieveClick(Sender: TObject);
var
  QueryText: string;
  K: Integer;
  Results: TStringList;
  I: Integer;
  Item: TAIRetrievalResult;
  ListItem: TListItem;
  StartTick: QWord;
begin
  QueryText := Trim(edtQuery.Text);
  if QueryText = '' then
  begin
    ShowMessage('Digite uma pergunta para buscar.');
    edtQuery.SetFocus;
    Exit;
  end;

  K := StrToIntDef(Trim(edtTopK.Text), 3);
  if K < 1 then K := 1;
  AIRAG1.TopK := K;

  case cbRetrievalMode.ItemIndex of
    0: AIRAG1.RetrievalMode := rrmVector;
    1: AIRAG1.RetrievalMode := rrmBM25;
    else
      AIRAG1.RetrievalMode := rrmHybrid;
  end;

  Results := TStringList.Create;
  Screen.Cursor := crHourGlass;
  try
    StartTick := GetTickCount64;
    lvResults.Items.BeginUpdate;
    try
      lvResults.Items.Clear;
      mmoDetail.Clear;

      if not AIRAG1.Retrieve(QueryText, Results) then
      begin
        ShowMessage('Erro na recuperação: ' + AIRAG1.LastError);
        lblStatus.Caption := 'Erro na busca: ' + AIRAG1.LastError;
        Exit;
      end;

      for I := 0 to Results.Count - 1 do
      begin
        Item := TAIRetrievalResult(Results.Objects[I]);
        ListItem := lvResults.Items.Add;
        ListItem.Caption := IntToStr(I + 1);
        ListItem.SubItems.Add(Item.Source);
        ListItem.SubItems.Add(Format('%.5f', [Item.Score]));
        ListItem.SubItems.Add(Item.Text);
      end;

      if lvResults.Items.Count > 0 then
      begin
        lvResults.Items[0].Selected := True;
        lvResultsSelectItem(lvResults, lvResults.Items[0], True);
      end;

      lblStatus.Caption := Format('%d resultado(s) recuperados em %d ms (Modo: %s, TopK: %d)',
        [Results.Count, GetTickCount64 - StartTick, cbRetrievalMode.Text, K]);
    finally
      lvResults.Items.EndUpdate;
    end;
  finally
    FreeRetrievalResults(Results);
    Results.Free;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmHybridRetrievalDemo.lvResultsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) and (Item.SubItems.Count >= 3) then
  begin
    mmoDetail.Text := Format('Posição: %s'#13#10 +
      'Documento: %s'#13#10 +
      'Score de Relevância: %s'#13#10#13#10 +
      'Texto do Trecho Recuperado:'#13#10 +
      '%s',
      [Item.Caption, Item.SubItems[0], Item.SubItems[1], Item.SubItems[2]]);
  end;
end;

initialization
  RegisterClasses([
    TAIGraphMap,
    TAILocalEmbeddingProvider,
    TAIVectorStore,
    TAIVectorRetriever,
    TAIBM25Retriever,
    TAIRAG
  ]);

end.
