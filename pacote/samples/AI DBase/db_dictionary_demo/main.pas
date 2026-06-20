unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, ZConnection, aidb_types, aidb_dictionary_base, 
  aidb_postgresql_dictionary, aidb_sqlite_dictionary;

type
  TfrmMain = class(TForm)
    btnConectar: TButton;
    btnGerar: TButton;
    btnSalvarMarkdown: TButton;
    btnSalvarJSON: TButton;
    cbBanco: TComboBox;
    edtHost: TEdit;
    edtPort: TEdit;
    edtDatabase: TEdit;
    edtUser: TEdit;
    edtPassword: TEdit;
    edtSchema: TEdit;
    lblBanco: TLabel;
    lblHost: TLabel;
    lblPort: TLabel;
    lblDatabase: TLabel;
    lblUser: TLabel;
    lblPassword: TLabel;
    lblSchema: TLabel;
    MemoResultado: TMemo;
    pnlConfig: TPanel;
    pnlResult: TPanel;
    ProgressBar1: TProgressBar;
    SaveDialog1: TSaveDialog;
    StatusBar1: TStatusBar;
    procedure btnConectarClick(Sender: TObject);
    procedure btnGerarClick(Sender: TObject);
    procedure btnSalvarJSONClick(Sender: TObject);
    procedure btnSalvarMarkdownClick(Sender: TObject);
    procedure cbBancoChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FZConnection: TZConnection;
    FDictionary: TAICustomDBDictionary;
    procedure DoProgress(Sender: TObject; const AMessage: string; APosition, ATotal: Integer);
    procedure DoError(Sender: TObject; const AMessage: string);
    procedure UpdateUI;
  public
    destructor Destroy; override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FZConnection := TZConnection.Create(Self);
  FDictionary := nil;
  UpdateUI;
end;

destructor TfrmMain.Destroy;
begin
  if Assigned(FDictionary) then
    FDictionary.Free;
  inherited Destroy;
end;

procedure TfrmMain.cbBancoChange(Sender: TObject);
begin
  UpdateUI;
end;

procedure TfrmMain.UpdateUI;
begin
  if cbBanco.Text = 'SQLite' then
  begin
    edtHost.Enabled := False;
    edtPort.Enabled := False;
    edtUser.Enabled := False;
    edtPassword.Enabled := False;
    edtSchema.Enabled := False;
    lblDatabase.Caption := 'SQLite File (.db):';
    if (edtDatabase.Text = 'postgres') or (edtDatabase.Text = 'database.db') then
      edtDatabase.Text := 'database\etiqueta.db';
  end
  else
  begin
    edtHost.Enabled := True;
    edtPort.Enabled := True;
    edtUser.Enabled := True;
    edtPassword.Enabled := True;
    edtSchema.Enabled := True;
    lblDatabase.Caption := 'Database Name:';
    if (edtDatabase.Text = 'database.db') or (edtDatabase.Text = 'database\etiqueta.db') then
      edtDatabase.Text := 'postgres';
  end;
end;

procedure TfrmMain.btnConectarClick(Sender: TObject);
begin
  try
    FZConnection.Connected := False;
    
    if cbBanco.Text = 'PostgreSQL' then
    begin
      FZConnection.Protocol := 'postgresql';
      FZConnection.HostName := edtHost.Text;
      FZConnection.Port := StrToIntDef(edtPort.Text, 5432);
      FZConnection.Database := edtDatabase.Text;
      FZConnection.User := edtUser.Text;
      FZConnection.Password := edtPassword.Text;
    end
    else if cbBanco.Text = 'SQLite' then
    begin
      FZConnection.Protocol := 'sqlite';
      FZConnection.Database := edtDatabase.Text;
    end;

    FZConnection.Connected := True;
    StatusBar1.Panels[0].Text := 'Connected successfully!';
    ShowMessage('Connected successfully!');
  except
    on E: Exception do
    begin
      StatusBar1.Panels[0].Text := 'Error: ' + E.Message;
      ShowMessage('Failed to connect: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.DoProgress(Sender: TObject; const AMessage: string; APosition, ATotal: Integer);
begin
  ProgressBar1.Position := APosition;
  ProgressBar1.Max := ATotal;
  StatusBar1.Panels[0].Text := AMessage;
  Application.ProcessMessages;
end;

procedure TfrmMain.DoError(Sender: TObject; const AMessage: string);
begin
  StatusBar1.Panels[0].Text := 'Error: ' + AMessage;
end;

procedure TfrmMain.btnGerarClick(Sender: TObject);
begin
  if not FZConnection.Connected then
  begin
    ShowMessage('Please connect to the database first.');
    Exit;
  end;

  if Assigned(FDictionary) then
  begin
    FDictionary.Free;
    FDictionary := nil;
  end;

  if cbBanco.Text = 'PostgreSQL' then
  begin
    FDictionary := TAIPostgreSQLDictionary.Create(Self);
    FDictionary.SchemaName := edtSchema.Text;
  end
  else if cbBanco.Text = 'SQLite' then
  begin
    FDictionary := TAISQLiteDictionary.Create(Self);
    FDictionary.SchemaName := '';
  end;

  if Assigned(FDictionary) then
  begin
    FDictionary.Connection := FZConnection;
    FDictionary.OnProgress := @DoProgress;
    FDictionary.OnError := @DoError;
    FDictionary.OutputFormat := dofMarkdown;

    MemoResultado.Clear;
    if FDictionary.Generate then
    begin
      MemoResultado.Text := FDictionary.AsMarkdown;
      ShowMessage('Data dictionary generated successfully!');
    end;
  end;
end;

procedure TfrmMain.btnSalvarMarkdownClick(Sender: TObject);
begin
  if not Assigned(FDictionary) or (FDictionary.DataDictionary.TableCount = 0) then
  begin
    ShowMessage('Please generate the dictionary first.');
    Exit;
  end;

  SaveDialog1.Filter := 'Markdown Files (*.md)|*.md';
  SaveDialog1.DefaultExt := 'md';
  if SaveDialog1.Execute then
  begin
    if FDictionary.SaveToMarkdown(SaveDialog1.FileName) then
      ShowMessage('Saved successfully!')
    else
      ShowMessage('Error saving: ' + FDictionary.LastError);
  end;
end;

procedure TfrmMain.btnSalvarJSONClick(Sender: TObject);
begin
  if not Assigned(FDictionary) or (FDictionary.DataDictionary.TableCount = 0) then
  begin
    ShowMessage('Please generate the dictionary first.');
    Exit;
  end;

  SaveDialog1.Filter := 'JSON Files (*.json)|*.json';
  SaveDialog1.DefaultExt := 'json';
  if SaveDialog1.Execute then
  begin
    if FDictionary.SaveToJSON(SaveDialog1.FileName) then
      ShowMessage('Saved successfully!')
    else
      ShowMessage('Error saving: ' + FDictionary.LastError);
  end;
end;

end.
