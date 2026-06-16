unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  ai_docfilesmanager;

type

  { TfrmDocFilesManagerDemo }

  TfrmDocFilesManagerDemo = class(TForm)
    lblStoragePath: TLabel;
    edtStoragePath: TEdit;
    btnSelectPath: TButton;
    btnInitialize: TButton;

    lblGrupo: TLabel;
    edtGrupo: TEdit;
    btnAddGrupo: TButton;
    btnDelGrupo: TButton;
    btnListGrupos: TButton;
    lstGrupos: TListBox;

    lblSubGrupo: TLabel;
    edtSubGrupo: TEdit;
    btnAddSubGrupo: TButton;
    btnDelSubGrupo: TButton;
    btnListSubGrupos: TButton;
    lstSubGrupos: TListBox;

    lblArquivos: TLabel;
    btnUploadFile: TButton;
    btnListFiles: TButton;
    btnDeleteFile: TButton;
    btnGetDocument: TButton;
    btnGetFullDocument: TButton;
    lstFiles: TListBox;

    lblLog: TLabel;
    memoLog: TMemo;
    btnClearLog: TButton;

    OpenDialog1: TOpenDialog;
    SelectDirectoryDialog1: TSelectDirectoryDialog;
    AI_DOCFILESMANAGER1: TAI_DOCFILESMANAGER;

    procedure FormCreate(Sender: TObject);
    procedure btnSelectPathClick(Sender: TObject);
    procedure btnInitializeClick(Sender: TObject);
    procedure btnAddGrupoClick(Sender: TObject);
    procedure btnDelGrupoClick(Sender: TObject);
    procedure btnListGruposClick(Sender: TObject);
    procedure btnAddSubGrupoClick(Sender: TObject);
    procedure btnDelSubGrupoClick(Sender: TObject);
    procedure btnListSubGruposClick(Sender: TObject);
    procedure btnUploadFileClick(Sender: TObject);
    procedure btnListFilesClick(Sender: TObject);
    procedure btnGetDocumentClick(Sender: TObject);
    procedure btnGetFullDocumentClick(Sender: TObject);
    procedure btnDeleteFileClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure lstGruposSelectionChange(Sender: TObject; User: Boolean);
    procedure lstSubGruposSelectionChange(Sender: TObject; User: Boolean);

  private
    procedure AddLog(const AMsg: string);
  public

  end;

var
  frmDocFilesManagerDemo: TfrmDocFilesManagerDemo;

implementation

{$R *.lfm}

{ TfrmDocFilesManagerDemo }

procedure TfrmDocFilesManagerDemo.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

procedure TfrmDocFilesManagerDemo.FormCreate(Sender: TObject);
begin
  edtStoragePath.Text := IncludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName)) + 'storage_docs';
  AddLog('[INFO] AI_DOCFILESMANAGER Demo iniciado.');
  AddLog('[INFO] StoragePath padrão: ' + edtStoragePath.Text);
end;

procedure TfrmDocFilesManagerDemo.btnSelectPathClick(Sender: TObject);
begin
  SelectDirectoryDialog1.InitialDir := edtStoragePath.Text;
  if SelectDirectoryDialog1.Execute then
  begin
    edtStoragePath.Text := SelectDirectoryDialog1.FileName;
    AddLog('[INFO] StoragePath selecionado: ' + edtStoragePath.Text);
  end;
end;

procedure TfrmDocFilesManagerDemo.btnInitializeClick(Sender: TObject);
begin
  AI_DOCFILESMANAGER1.StoragePath := edtStoragePath.Text;
  AI_DOCFILESMANAGER1.AutoCreateDirs := True;
  AI_DOCFILESMANAGER1.AllowOverwrite := False;

  AddLog('[INFO] Inicializando AI_DOCFILESMANAGER...');

  if AI_DOCFILESMANAGER1.Initialize then
  begin
    AddLog('[OK] Componente inicializado com sucesso.');
    btnListGruposClick(Sender);
  end
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnAddGrupoClick(Sender: TObject);
var
  IdGrupo: Integer;
begin
  IdGrupo := AI_DOCFILESMANAGER1.AddGrupo(edtGrupo.Text);

  if IdGrupo >= 0 then
  begin
    AddLog('[OK] Grupo criado: ' + edtGrupo.Text);
    btnListGruposClick(Sender);
  end
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnDelGrupoClick(Sender: TObject);
var
  Grupo: string;
begin
  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;
  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];
  // Attempt without force, if it fails, ask the user or just delete with force
  if AI_DOCFILESMANAGER1.DelGrupo(Grupo, True) then
  begin
    AddLog('[OK] Grupo excluído (force): ' + Grupo);
    btnListGruposClick(Sender);
    lstSubGrupos.Clear;
    lstFiles.Clear;
  end
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnListGruposClick(Sender: TObject);
begin
  lstGrupos.Clear;
  AI_DOCFILESMANAGER1.ListGrupos(lstGrupos.Items);
  AddLog('[INFO] Grupos listados.');
end;

procedure TfrmDocFilesManagerDemo.btnAddSubGrupoClick(Sender: TObject);
var
  IdSubGrupo: Integer;
  Grupo: string;
begin
  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];

  IdSubGrupo := AI_DOCFILESMANAGER1.AddSubGrupo(
    Grupo,
    edtSubGrupo.Text
  );

  if IdSubGrupo >= 0 then
  begin
    AddLog('[OK] SubGrupo criado: ' + edtSubGrupo.Text);
    btnListSubGruposClick(Sender);
  end
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnDelSubGrupoClick(Sender: TObject);
var
  Grupo, SubGrupo: string;
begin
  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;
  if lstSubGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um subgrupo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];
  SubGrupo := lstSubGrupos.Items[lstSubGrupos.ItemIndex];

  if AI_DOCFILESMANAGER1.DelSubGrupo(Grupo, SubGrupo, True) then
  begin
    AddLog('[OK] SubGrupo excluído (force): ' + SubGrupo);
    btnListSubGruposClick(Sender);
    lstFiles.Clear;
  end
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnListSubGruposClick(Sender: TObject);
var
  Grupo: string;
begin
  lstSubGrupos.Clear;

  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];

  AI_DOCFILESMANAGER1.ListSubGrupo(
    Grupo,
    lstSubGrupos.Items
  );

  AddLog('[INFO] SubGrupos listados do grupo: ' + Grupo);
end;

procedure TfrmDocFilesManagerDemo.btnUploadFileClick(Sender: TObject);
var
  Grupo: string;
  SubGrupo: string;
begin
  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;

  if lstSubGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um subgrupo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];
  SubGrupo := lstSubGrupos.Items[lstSubGrupos.ItemIndex];

  if OpenDialog1.Execute then
  begin
    if AI_DOCFILESMANAGER1.UploadSubGrupo(
      Grupo,
      SubGrupo,
      OpenDialog1.FileName
    ) then
    begin
      AddLog('[OK] Arquivo enviado: ' + ExtractFileName(OpenDialog1.FileName));
      btnListFilesClick(Sender);
    end
    else
      AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
  end;
end;

procedure TfrmDocFilesManagerDemo.btnListFilesClick(Sender: TObject);
var
  Grupo: string;
  SubGrupo: string;
begin
  lstFiles.Clear;

  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;

  if lstSubGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um subgrupo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];
  SubGrupo := lstSubGrupos.Items[lstSubGrupos.ItemIndex];

  AI_DOCFILESMANAGER1.GetFilesSubGrupo(
    Grupo,
    SubGrupo,
    lstFiles.Items
  );

  AddLog('[INFO] Arquivos listados de: ' + Grupo + '/' + SubGrupo);
end;

procedure TfrmDocFilesManagerDemo.btnGetDocumentClick(Sender: TObject);
var
  Grupo: string;
  SubGrupo: string;
  FileName: string;
  DocName: string;
begin
  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;

  if lstSubGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um subgrupo.');
    Exit;
  end;

  if lstFiles.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um arquivo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];
  SubGrupo := lstSubGrupos.Items[lstSubGrupos.ItemIndex];
  FileName := lstFiles.Items[lstFiles.ItemIndex];

  DocName := AI_DOCFILESMANAGER1.GetDocument(
    Grupo,
    SubGrupo,
    FileName
  );

  if DocName <> '' then
    AddLog('[INFO] GetDocument retornou: ' + DocName)
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnGetFullDocumentClick(Sender: TObject);
var
  Grupo: string;
  SubGrupo: string;
  FileName: string;
  FullDoc: string;
begin
  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;

  if lstSubGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um subgrupo.');
    Exit;
  end;

  if lstFiles.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um arquivo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];
  SubGrupo := lstSubGrupos.Items[lstSubGrupos.ItemIndex];
  FileName := lstFiles.Items[lstFiles.ItemIndex];

  FullDoc := AI_DOCFILESMANAGER1.GetFullDocument(
    Grupo,
    SubGrupo,
    FileName
  );

  if FullDoc <> '' then
    AddLog('[INFO] GetFullDocument retornou: ' + FullDoc)
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnDeleteFileClick(Sender: TObject);
var
  Grupo: string;
  SubGrupo: string;
  FileName: string;
begin
  if lstGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um grupo.');
    Exit;
  end;

  if lstSubGrupos.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um subgrupo.');
    Exit;
  end;

  if lstFiles.ItemIndex < 0 then
  begin
    AddLog('[ERRO] Selecione um arquivo.');
    Exit;
  end;

  Grupo := lstGrupos.Items[lstGrupos.ItemIndex];
  SubGrupo := lstSubGrupos.Items[lstSubGrupos.ItemIndex];
  FileName := lstFiles.Items[lstFiles.ItemIndex];

  if AI_DOCFILESMANAGER1.DelFileSubGrupo(
    Grupo,
    SubGrupo,
    FileName
  ) then
  begin
    AddLog('[OK] Arquivo removido: ' + FileName);
    btnListFilesClick(Sender);
  end
  else
    AddLog('[ERRO] ' + AI_DOCFILESMANAGER1.LastError);
end;

procedure TfrmDocFilesManagerDemo.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmDocFilesManagerDemo.lstGruposSelectionChange(Sender: TObject; User: Boolean);
begin
  if lstGrupos.ItemIndex >= 0 then
  begin
    btnListSubGruposClick(Sender);
    lstFiles.Clear;
  end;
end;

procedure TfrmDocFilesManagerDemo.lstSubGruposSelectionChange(Sender: TObject; User: Boolean);
begin
  if lstSubGrupos.ItemIndex >= 0 then
  begin
    btnListFilesClick(Sender);
  end;
end;

end.
