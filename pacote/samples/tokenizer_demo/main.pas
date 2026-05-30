unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  tokenizer;

type

  { TfrmTokenizerDemo }

  TfrmTokenizerDemo = class(TForm)
    pnlAdd: TPanel;
    lblAddTitle: TLabel;
    lblKey: TLabel;
    edKey: TEdit;
    lblTokenVal: TLabel;
    edTokenVal: TEdit;
    btnAdd: TButton;
    btnFind: TButton;
    
    pnlJSON: TPanel;
    lblJSONTitle: TLabel;
    meJSON: TMemo;
    btnLoadJSON: TButton;
    
    pnlEncode: TPanel;
    lblEncodeTitle: TLabel;
    meInputText: TMemo;
    btnEncodeText: TButton;
    
    pnlList: TPanel;
    lblListTitle: TLabel;
    lstTokens: TListBox;
    lblCount: TLabel;
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnFindClick(Sender: TObject);
    procedure btnLoadJSONClick(Sender: TObject);
    procedure btnEncodeTextClick(Sender: TObject);
  private
    FTokenList: TTokenList;
    procedure LogMsg(const AMsg: string);
    procedure SyncListUI;
  public

  end;

var
  frmTokenizerDemo: TfrmTokenizerDemo;

implementation

{$R *.lfm}

{ TfrmTokenizerDemo }

procedure TfrmTokenizerDemo.FormCreate(Sender: TObject);
begin
  // TTokenList é uma subclasse de TCustomControl, podemos instanciá-la com o formulário
  FTokenList := TTokenList.Create(Self);
  FTokenList.Parent := Self;
  FTokenList.Visible := False; // Não precisamos desenhar o painel vermelho padrão na tela
  
  // JSON padrão compatível com a rotina LoadFromJSON do componente
  meJSON.Text := '{' + sLineBreak +
                 '  "Lazarus": [{"token": "IDE_OPEN_SOURCE"}],' + sLineBreak +
                 '  "Pascal": [{"token": "LINGUAGEM_COMPILADA"}],' + sLineBreak +
                 '  "IA": [{"token": "INTELIGENCIA_ARTIFICIAL"}]' + sLineBreak +
                 '}';
                 
  meInputText.Text := 'Lazarus Pascal IA inteligência artificial aprendizado de máquina';
  
  LogMsg('Token List inicializado com sucesso.');
  SyncListUI;
end;

procedure TfrmTokenizerDemo.FormDestroy(Sender: TObject);
begin
  // FTokenList é auto-liberado pelo Owner (Self)
end;

procedure TfrmTokenizerDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmTokenizerDemo.SyncListUI;
var
  i: Integer;
  Key, Token: string;
begin
  lstTokens.Items.Clear;
  for i := 0 to FTokenList.Count - 1 do
  begin
    Key := FTokenList.Item(i);
    Token := FTokenList.GetToken(Key);
    lstTokens.Items.Add(Format('%d: Chave: "%s" -> Token: "%s"', [i + 1, Key, Token]));
  end;
  lblCount.Caption := 'Total de Tokens em memória: ' + IntToStr(FTokenList.Count);
end;

procedure TfrmTokenizerDemo.btnAddClick(Sender: TObject);
var
  K, T: string;
begin
  K := Trim(edKey.Text);
  T := Trim(edTokenVal.Text);
  if K = '' then
  begin
    ShowMessage('Informe a chave!');
    Exit;
  end;
  
  FTokenList.AddToken(K, T);
  LogMsg('Adicionado token: "' + K + '" -> "' + T + '"');
  SyncListUI;
end;

procedure TfrmTokenizerDemo.btnFindClick(Sender: TObject);
var
  K, T: string;
begin
  K := Trim(edKey.Text);
  if K = '' then
  begin
    ShowMessage('Informe a chave para pesquisa!');
    Exit;
  end;
  
  T := FTokenList.Find(K);
  if T = K then
  begin
    LogMsg('Pesquisa de "' + K + '": Token NÃO encontrado (retornada a própria chave).');
    ShowMessage('Token não encontrado! Retornada a chave: ' + T);
  end
  else
  begin
    LogMsg('Pesquisa de "' + K + '": Token ENCONTRADO -> "' + T + '"');
    ShowMessage('Token encontrado: ' + T);
  end;
end;

procedure TfrmTokenizerDemo.btnLoadJSONClick(Sender: TObject);
begin
  try
    FTokenList.LoadFromJSON(meJSON.Text);
    LogMsg('Lista de tokens importada com sucesso a partir do formato JSON estruturado!');
    SyncListUI;
  except
    on E: Exception do
    begin
      LogMsg('Erro ao ler JSON: ' + E.Message);
      ShowMessage('Erro de parse no JSON: ' + E.Message);
    end;
  end;
end;

procedure TfrmTokenizerDemo.btnEncodeTextClick(Sender: TObject);
var
  List: TStringList;
begin
  List := TStringList.Create;
  try
    List.Text := meInputText.Text;
    LogMsg('Segmentando e codificando lista de palavras via método Encode...');
    FTokenList.Encode(List);
    LogMsg('Codificação concluída.');
    SyncListUI;
  finally
    List.Free;
  end;
end;

end.
