unit main;

{$mode ObjFPC}{$H+}

interface

uses
  Dialogs,
  Forms,
  StdCtrls,
  SysUtils,
  aillamacpplora,
  aillamacppmodel,
  aillamacppruntime;

type
  TfrmMain = class(TForm)
    btnApply: TButton;
    btnRemove: TButton;
    btnSelectAdapter: TButton;
    btnSelectModel: TButton;
    edtAdapter: TEdit;
    edtModel: TEdit;
    edtScale: TEdit;
    lblAdapter: TLabel;
    lblModel: TLabel;
    lblScale: TLabel;
    LlamaLoRA: TAILlamaCppLoRA;
    LlamaModel: TAILlamaCppModel;
    LlamaRuntime: TAILlamaCppRuntime;
    memLog: TMemo;
    OpenAdapterDialog: TOpenDialog;
    OpenModelDialog: TOpenDialog;
    procedure btnApplyClick(Sender: TObject);
    procedure btnRemoveClick(Sender: TObject);
    procedure btnSelectAdapterClick(Sender: TObject);
    procedure btnSelectModelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure AddLog(const AMessage: string);
    procedure ConfigureDevelopmentRuntime;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.ConfigureDevelopmentRuntime;
var
  LRoot: string;
begin
  LRoot := ExpandFileName(IncludeTrailingPathDelimiter(
    ExtractFilePath(Application.ExeName)) + '..\..\..\..\runtime\windows-x64');
  LlamaRuntime.RuntimeRoot := LRoot;
  LlamaRuntime.BinPath := IncludeTrailingPathDelimiter(LRoot) + 'bin';
  LlamaRuntime.LibraryPath := IncludeTrailingPathDelimiter(LRoot) + 'dll';
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  LDefaultModel: string;
begin
  ConfigureDevelopmentRuntime;
  LDefaultModel := IncludeTrailingPathDelimiter(
    GetEnvironmentVariable('LOCALAPPDATA')) +
    'Maurinsoft\CHATGPT\models\qwen2-0_5b-instruct-q2_k.gguf';
  if FileExists(LDefaultModel) then
    edtModel.Text := LDefaultModel;
end;

procedure TfrmMain.AddLog(const AMessage: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + AMessage);
end;

procedure TfrmMain.btnApplyClick(Sender: TObject);
var
  LScale: Double;
begin
  if not TryStrToFloat(edtScale.Text, LScale) then
  begin
    AddLog('Escala invalida.');
    Exit;
  end;
  LlamaModel.ModelFile := edtModel.Text;
  LlamaLoRA.AdapterFile := edtAdapter.Text;
  LlamaLoRA.Scale := LScale;
  if LlamaLoRA.Apply then
    AddLog('Adaptador aplicado com sucesso.')
  else
    AddLog('Erro: ' + LlamaLoRA.LastError);
end;

procedure TfrmMain.btnRemoveClick(Sender: TObject);
begin
  if LlamaLoRA.Remove then
    AddLog('Adaptador removido.')
  else
    AddLog('Erro: ' + LlamaLoRA.LastError);
end;

procedure TfrmMain.btnSelectModelClick(Sender: TObject);
begin
  if OpenModelDialog.Execute then
    edtModel.Text := OpenModelDialog.FileName;
end;

procedure TfrmMain.btnSelectAdapterClick(Sender: TObject);
begin
  if OpenAdapterDialog.Execute then
    edtAdapter.Text := OpenAdapterDialog.FileName;
end;

end.
