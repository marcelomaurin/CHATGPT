unit main;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Dialogs, Forms, StdCtrls, SysUtils,
  aibase,
  aillamacppquantizer,
  aillamacppruntime;

type
  TfrmMain = class(TForm)
    btnExecute: TButton;
    btnSelectDestination: TButton;
    btnSelectSource: TButton;
    cmbQuantization: TComboBox;
    edtDestination: TEdit;
    edtSource: TEdit;
    lblDestination: TLabel;
    lblQuantization: TLabel;
    lblSource: TLabel;
    LlamaQuantizer: TAILlamaCppQuantizer;
    LlamaRuntime: TAILlamaCppRuntime;
    memLog: TMemo;
    OpenSourceDialog: TOpenDialog;
    SaveDestinationDialog: TSaveDialog;
    procedure btnExecuteClick(Sender: TObject);
    procedure btnSelectDestinationClick(Sender: TObject);
    procedure btnSelectSourceClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure ConfigureDevelopmentRuntime;
    procedure QuantizerLog(Sender: TObject; Level: TAILogLevel;
      const Message: string);
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
  LType: TAILlamaQuantizationType;
begin
  ConfigureDevelopmentRuntime;
  for LType := Low(TAILlamaQuantizationType) to High(TAILlamaQuantizationType) do
    cmbQuantization.Items.Add(
      TAILlamaCppQuantizer.QuantizationTypeToString(LType));
  cmbQuantization.ItemIndex := Ord(lqtQ4_K_M);
  LlamaQuantizer.OnLog := @QuantizerLog;
end;

procedure TfrmMain.QuantizerLog(Sender: TObject; Level: TAILogLevel;
  const Message: string);
const
  LEVEL_NAMES: array[TAILogLevel] of string =
    ('DEBUG', 'INFO', 'WARN', 'ERROR');
begin
  memLog.Lines.Add(Format('[%s] %s', [LEVEL_NAMES[Level], Message]));
  Application.ProcessMessages;
end;

procedure TfrmMain.btnExecuteClick(Sender: TObject);
begin
  LlamaQuantizer.SourceFile := edtSource.Text;
  LlamaQuantizer.DestinationFile := edtDestination.Text;
  if cmbQuantization.ItemIndex >= 0 then
    LlamaQuantizer.QuantizationType :=
      TAILlamaQuantizationType(cmbQuantization.ItemIndex);
  memLog.Lines.Add('Iniciando quantizacao...');
  if LlamaQuantizer.Execute then
    memLog.Lines.Add('Quantizacao concluida: ' + edtDestination.Text)
  else
    memLog.Lines.Add('Erro: ' + LlamaQuantizer.LastError);
end;

procedure TfrmMain.btnSelectSourceClick(Sender: TObject);
begin
  if OpenSourceDialog.Execute then
  begin
    edtSource.Text := OpenSourceDialog.FileName;
    edtDestination.Text := ChangeFileExt(OpenSourceDialog.FileName, '') +
      '-' + LowerCase(cmbQuantization.Text) + '.gguf';
  end;
end;

procedure TfrmMain.btnSelectDestinationClick(Sender: TObject);
begin
  SaveDestinationDialog.FileName := edtDestination.Text;
  if SaveDestinationDialog.Execute then
    edtDestination.Text := SaveDestinationDialog.FileName;
end;

end.
