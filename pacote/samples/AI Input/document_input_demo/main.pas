unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls, Buttons,
  aidocumentreader, aipdfinput, aidocxinput, aiexcelinput, aidocumentextractor;

type

  { TfrmDocInputDemo }

  TfrmDocInputDemo = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblFile: TLabel;
    edtFileName: TEdit;
    btnBrowse: TButton;
    btnLoad: TButton;
    btnClear: TButton;
    lblDocType: TLabel;
    cboDocType: TComboBox;
    memoText: TMemo;
    openDlg: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
  private
    procedure LoadSelectedFile;
  public

  end;

var
  frmDocInputDemo: TfrmDocInputDemo;

implementation

{$R *.lfm}

{ TfrmDocInputDemo }

procedure TfrmDocInputDemo.FormCreate(Sender: TObject);
begin
  Caption := 'AI Document Input Demo';
  SetBounds(100, 100, 800, 600);
end;

procedure TfrmDocInputDemo.btnBrowseClick(Sender: TObject);
begin
  if openDlg.Execute then
  begin
    edtFileName.Text := openDlg.FileName;
    LoadSelectedFile;
  end;
end;

procedure TfrmDocInputDemo.btnLoadClick(Sender: TObject);
begin
  LoadSelectedFile;
end;

procedure TfrmDocInputDemo.btnClearClick(Sender: TObject);
begin
  edtFileName.Text := '';
  memoText.Clear;
  lblDocType.Caption := 'Tipo: -';
end;

procedure TfrmDocInputDemo.LoadSelectedFile;
var
  Ext, ExtractedText, ErrorStr: string;
  Reg: TAIDocumentExtractorRegistry;
begin
  memoText.Clear;
  if Trim(edtFileName.Text) = '' then
  begin
    ShowMessage('Selecione um arquivo primeiro.');
    Exit;
  end;

  Ext := LowerCase(ExtractFileExt(edtFileName.Text));
  lblDocType.Caption := 'Tipo: ' + UpperCase(Copy(Ext, 2, Length(Ext)));

  Reg := GlobalExtractorRegistry;
  if Reg.ExtractText(edtFileName.Text, ExtractedText, ErrorStr) then
  begin
    memoText.Text := ExtractedText;
  end
  else
  begin
    memoText.Text := 'Erro ao carregar documento: ' + ErrorStr;
  end;
end;

end.
