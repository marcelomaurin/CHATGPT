unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Math, iaschedule;

type
  { TFormMain }
  TFormMain = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Top Header }
    pnlHeader: TPanel;
    
    { Split Client Area }
    pnlLeft: TPanel;
    pnlRight: TPanel;
    splitterMain: TSplitter;
    
    { JSON Group Storage Controls (Left) }
    lblStorageTitle: TLabel;
    lblStorageFile: TLabel;
    edtStorageFile: TEdit;
    btnStorageLoad: TButton;
    btnStorageSave: TButton;
    
    gbGroup: TGroupBox;
    lblGroup: TLabel;
    edtGroup: TEdit;
    btnGroupSelect: TButton;
    
    lblActiveGroup: TLabel;
    
    lblKey: TLabel;
    edtKey: TEdit;
    lblValue: TLabel;
    memValue: TMemo;
    btnKeyFind: TButton;
    btnKeySet: TButton;
    
    { Schedule Controls (Right) }
    lblScheduleTitle: TLabel;
    lblScheduleFile: TLabel;
    edtScheduleFile: TEdit;
    btnScheduleLoad: TButton;
    btnScheduleSave: TButton;
    
    gbNewTask: TGroupBox;
    lblTaskName: TLabel;
    edtTaskName: TEdit;
    lblTaskDesc: TLabel;
    edtTaskDesc: TEdit;
    lblTaskParent: TLabel;
    cbTaskParent: TComboBox;
    btnAddTask: TButton;
    
    gbDependencies: TGroupBox;
    lblDepTask: TLabel;
    cbDepTask: TComboBox;
    lblDepTarget: TLabel;
    cbDepTarget: TComboBox;
    btnLinkDependency: TButton;
    
    gbTasksList: TGroupBox;
    lbTasks: TListBox;
    btnMarkDone: TButton;
    btnMarkPending: TButton;
    memTaskDetails: TMemo;
    lblReadyStatus: TLabel;
    
    { Components (Instantiated dynamically at runtime) }
    FGroupStorage: TJSONGroupStorage;
    FSchedule: TIASchedule;
    
    procedure CreateLayout;
    
    { Storage Events }
    procedure StorageLoadClick(Sender: TObject);
    procedure StorageSaveClick(Sender: TObject);
    procedure GroupSelectClick(Sender: TObject);
    procedure KeyFindClick(Sender: TObject);
    procedure KeySetClick(Sender: TObject);
    
    { Schedule Events }
    procedure ScheduleLoadClick(Sender: TObject);
    procedure ScheduleSaveClick(Sender: TObject);
    procedure AddTaskClick(Sender: TObject);
    procedure LinkDependencyClick(Sender: TObject);
    procedure MarkDoneClick(Sender: TObject);
    procedure MarkPendingClick(Sender: TObject);
    procedure TasksSelectionChanged(Sender: TObject);
    
    { Auxiliary helpers }
    procedure PopulateComboboxes;
    procedure UpdateTasksList;
    procedure ShowTaskDetails;
  public
  end;

var
  FormMain: TFormMain;

implementation

{$R *.lfm}

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
begin
  Caption := 'IA Schedulle & JSON Config Storage Showcase Playground';
  Width := 1050;
  Height := 680;
  Position := poScreenCenter;
  Color := $F9FAFB;
  
  CreateLayout;
  
  { Dynamically instantiate components }
  FGroupStorage := TJSONGroupStorage.Create(Self);
  FGroupStorage.FileName := edtStorageFile.Text;
  
  FSchedule := TIASchedule.Create(Self);
  FSchedule.FileName := edtScheduleFile.Text;
  
  { Load or initialize mock data }
  FGroupStorage.Select('ConfiguracaoGeral');
  FGroupStorage.SetVal('Tema', 'Escuro');
  FGroupStorage.SetVal('Fonte', '12pt');
  FGroupStorage.SetVal('ChaveGeral', 'ValorGrandeDeDemonstracaoContendoChaveValor JSON');
  FGroupStorage.Select('BancoDados');
  FGroupStorage.SetVal('Servidor', 'localhost');
  FGroupStorage.SetVal('Porta', '5432');
  
  lblActiveGroup.Caption := 'Grupo Ativo: BancoDados';
  edtGroup.Text := 'BancoDados';
  
  { Seed default tasks }
  FSchedule.NewTask('Projeto_Backend', '');
  FSchedule.NewTask('Projeto_Frontend', '');
  FSchedule.NewTask('Modulo_BancoDados', 'Projeto_Backend');
  FSchedule.NewTask('Integracao_APIs', 'Projeto_Backend');
  FSchedule.NewTask('Pagina_Login', 'Projeto_Frontend');
  FSchedule.NewTask('Dashboard', 'Projeto_Frontend');
  
  { Seed dependencies }
  FSchedule.FindTask('Integracao_APIs').DependsOn('Modulo_BancoDados');
  FSchedule.FindTask('Dashboard').DependsOn('Integracao_APIs');
  FSchedule.FindTask('Dashboard').DependsOn('Pagina_Login');
  
  PopulateComboboxes;
  UpdateTasksList;
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  { Self takes care of destroying FGroupStorage and FSchedule }
end;

procedure TFormMain.CreateLayout;
var
  pnlSep: TPanel;
begin
  { Header }
  pnlHeader := TPanel.Create(Self);
  pnlHeader.Parent := Self;
  pnlHeader.Align := alTop;
  pnlHeader.Height := 50;
  pnlHeader.Color := clHighlight;
  pnlHeader.BevelOuter := bvNone;
  
  with TLabel.Create(Self) do
  begin
    Parent := pnlHeader;
    Align := alClient;
    Alignment := taCenter;
    Layout := tlCenter;
    Caption := '🔌 Painel de Sincronização IA Schedulle & Armazenamento JSON';
    Font.Color := clWhite;
    Font.Size := 14;
    Font.Style := [fsBold];
  end;
  
  { Left Panel: JSON Storage }
  pnlLeft := TPanel.Create(Self);
  pnlLeft.Parent := Self;
  pnlLeft.Align := alLeft;
  pnlLeft.Width := 450;
  pnlLeft.BorderWidth := 15;
  pnlLeft.BevelOuter := bvNone;
  pnlLeft.Color := clWhite;
  
  lblStorageTitle := TLabel.Create(Self);
  lblStorageTitle.Parent := pnlLeft;
  lblStorageTitle.Align := alTop;
  lblStorageTitle.Caption := '1. TJSONGroupStorage (Chave / Valor)';
  lblStorageTitle.Font.Size := 12;
  lblStorageTitle.Font.Style := [fsBold];
  lblStorageTitle.Font.Color := clHighlight;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  lblStorageFile := TLabel.Create(Self);
  lblStorageFile.Parent := pnlLeft;
  lblStorageFile.Align := alTop;
  lblStorageFile.Caption := 'Arquivo de Configuração (JSON):';
  
  edtStorageFile := TEdit.Create(Self);
  edtStorageFile.Parent := pnlLeft;
  edtStorageFile.Align := alTop;
  edtStorageFile.Text := 'storage_config_demo.json';
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 5;
    BevelOuter := bvNone;
  end;
  
  { File Buttons Panel }
  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alTop;
  pnlSep.Height := 30;
  pnlSep.BevelOuter := bvNone;
  
  btnStorageLoad := TButton.Create(Self);
  btnStorageLoad.Parent := pnlSep;
  btnStorageLoad.Align := alLeft;
  btnStorageLoad.Width := 190;
  btnStorageLoad.Caption := '📂 Carregar JSON';
  btnStorageLoad.OnClick := @StorageLoadClick;
  
  btnStorageSave := TButton.Create(Self);
  btnStorageSave.Parent := pnlSep;
  btnStorageSave.Align := alRight;
  btnStorageSave.Width := 190;
  btnStorageSave.Caption := '💾 Gravar no Arquivo';
  btnStorageSave.OnClick := @StorageSaveClick;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 15;
    BevelOuter := bvNone;
  end;
  
  { Group Selector Group Box }
  gbGroup := TGroupBox.Create(Self);
  gbGroup.Parent := pnlLeft;
  gbGroup.Align := alTop;
  gbGroup.Height := 80;
  gbGroup.Caption := ' Gerenciamento de Grupo ';
  gbGroup.Font.Style := [fsBold];
  gbGroup.BorderWidth := 5;
  
  lblGroup := TLabel.Create(Self);
  lblGroup.Parent := gbGroup;
  lblGroup.Align := alLeft;
  lblGroup.Layout := tlCenter;
  lblGroup.Caption := 'Nome do Grupo:  ';
  
  edtGroup := TEdit.Create(Self);
  edtGroup.Parent := gbGroup;
  edtGroup.Align := alClient;
  
  btnGroupSelect := TButton.Create(Self);
  btnGroupSelect.Parent := gbGroup;
  btnGroupSelect.Align := alRight;
  btnGroupSelect.Width := 120;
  btnGroupSelect.Caption := '🔍 Selecionar';
  btnGroupSelect.OnClick := @GroupSelectClick;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  lblActiveGroup := TLabel.Create(Self);
  lblActiveGroup.Parent := pnlLeft;
  lblActiveGroup.Align := alTop;
  lblActiveGroup.Caption := 'Grupo Ativo: (Nenhum)';
  lblActiveGroup.Font.Color := clHighlight;
  lblActiveGroup.Font.Style := [fsBold];
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  { Key/Value Entries }
  lblKey := TLabel.Create(Self);
  lblKey.Parent := pnlLeft;
  lblKey.Align := alTop;
  lblKey.Caption := 'Chave (Key):';
  
  edtKey := TEdit.Create(Self);
  edtKey.Parent := pnlLeft;
  edtKey.Align := alTop;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  lblValue := TLabel.Create(Self);
  lblValue.Parent := pnlLeft;
  lblValue.Align := alTop;
  lblValue.Caption := 'Valor (Value - Suporta textos longos/grandes):';
  
  memValue := TMemo.Create(Self);
  memValue.Parent := pnlLeft;
  memValue.Align := alClient;
  memValue.ScrollBars := ssAutoVertical;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlLeft;
    Align := alBottom;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  { Query Actions }
  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlLeft;
  pnlSep.Align := alBottom;
  pnlSep.Height := 38;
  pnlSep.BevelOuter := bvNone;
  
  btnKeyFind := TButton.Create(Self);
  btnKeyFind.Parent := pnlSep;
  btnKeyFind.Align := alLeft;
  btnKeyFind.Width := 190;
  btnKeyFind.Caption := '🔎 Buscar Chave (Find)';
  btnKeyFind.OnClick := @KeyFindClick;
  
  btnKeySet := TButton.Create(Self);
  btnKeySet.Parent := pnlSep;
  btnKeySet.Align := alRight;
  btnKeySet.Width := 190;
  btnKeySet.Caption := '✍️ Gravar Chave (SetVal)';
  btnKeySet.OnClick := @KeySetClick;
  
  { Splitter }
  splitterMain := TSplitter.Create(Self);
  splitterMain.Parent := Self;
  splitterMain.Align := alLeft;
  splitterMain.Color := $E5E7EB;
  
  { Right Panel: Tasks and Dependencies Schedule }
  pnlRight := TPanel.Create(Self);
  pnlRight.Parent := Self;
  pnlRight.Align := alClient;
  pnlRight.BorderWidth := 15;
  pnlRight.BevelOuter := bvNone;
  pnlRight.Color := clWhite;
  
  lblScheduleTitle := TLabel.Create(Self);
  lblScheduleTitle.Parent := pnlRight;
  lblScheduleTitle.Align := alTop;
  lblScheduleTitle.Caption := '2. TIASchedule (Gerenciador de Tarefas e Dependências)';
  lblScheduleTitle.Font.Size := 12;
  lblScheduleTitle.Font.Style := [fsBold];
  lblScheduleTitle.Font.Color := clHighlight;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlRight;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  lblScheduleFile := TLabel.Create(Self);
  lblScheduleFile.Parent := pnlRight;
  lblScheduleFile.Align := alTop;
  lblScheduleFile.Caption := 'Arquivo do Cronograma (JSON):';
  
  edtScheduleFile := TEdit.Create(Self);
  edtScheduleFile.Parent := pnlRight;
  edtScheduleFile.Align := alTop;
  edtScheduleFile.Text := 'schedule_workflow_demo.json';
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlRight;
    Align := alTop;
    Height := 5;
    BevelOuter := bvNone;
  end;
  
  { File Schedule Buttons }
  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := pnlRight;
  pnlSep.Align := alTop;
  pnlSep.Height := 30;
  pnlSep.BevelOuter := bvNone;
  
  btnScheduleLoad := TButton.Create(Self);
  btnScheduleLoad.Parent := pnlSep;
  btnScheduleLoad.Align := alLeft;
  btnScheduleLoad.Width := 250;
  btnScheduleLoad.Caption := '📂 Carregar Lista de Tarefas';
  btnScheduleLoad.OnClick := @ScheduleLoadClick;
  
  btnScheduleSave := TButton.Create(Self);
  btnScheduleSave.Parent := pnlSep;
  btnScheduleSave.Align := alRight;
  btnScheduleSave.Width := 250;
  btnScheduleSave.Caption := '💾 Gravar Cronograma';
  btnScheduleSave.OnClick := @ScheduleSaveClick;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlRight;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  { GroupBox Insert Task }
  gbNewTask := TGroupBox.Create(Self);
  gbNewTask.Parent := pnlRight;
  gbNewTask.Align := alTop;
  gbNewTask.Height := 115;
  gbNewTask.Caption := ' Nova Tarefa (NewTask) ';
  gbNewTask.Font.Style := [fsBold];
  gbNewTask.BorderWidth := 5;
  
  lblTaskName := TLabel.Create(Self);
  lblTaskName.Parent := gbNewTask;
  lblTaskName.Left := 10;
  lblTaskName.Top := 5;
  lblTaskName.Caption := 'ID / Nome:';
  
  edtTaskName := TEdit.Create(Self);
  edtTaskName.Parent := gbNewTask;
  edtTaskName.Left := 10;
  edtTaskName.Top := 22;
  edtTaskName.Width := 150;
  
  lblTaskDesc := TLabel.Create(Self);
  lblTaskDesc.Parent := gbNewTask;
  lblTaskDesc.Left := 170;
  lblTaskDesc.Top := 5;
  lblTaskDesc.Caption := 'Descrição:';
  
  edtTaskDesc := TEdit.Create(Self);
  edtTaskDesc.Parent := gbNewTask;
  edtTaskDesc.Left := 170;
  edtTaskDesc.Top := 22;
  edtTaskDesc.Width := 200;
  
  lblTaskParent := TLabel.Create(Self);
  lblTaskParent.Parent := gbNewTask;
  lblTaskParent.Left := 380;
  lblTaskParent.Top := 5;
  lblTaskParent.Caption := 'Tarefa Pai (Hierarquia):';
  
  cbTaskParent := TComboBox.Create(Self);
  cbTaskParent.Parent := gbNewTask;
  cbTaskParent.Left := 380;
  cbTaskParent.Top := 22;
  cbTaskParent.Width := 150;
  cbTaskParent.Style := csDropDownList;
  
  btnAddTask := TButton.Create(Self);
  btnAddTask.Parent := gbNewTask;
  btnAddTask.Left := 10;
  btnAddTask.Top := 55;
  btnAddTask.Width := 520;
  btnAddTask.Height := 28;
  btnAddTask.Caption := '➕ Inserir Tarefa na Lista';
  btnAddTask.OnClick := @AddTaskClick;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlRight;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  { GroupBox Dependencies }
  gbDependencies := TGroupBox.Create(Self);
  gbDependencies.Parent := pnlRight;
  gbDependencies.Align := alTop;
  gbDependencies.Height := 85;
  gbDependencies.Caption := ' Vincular Dependências (DependsOn) ';
  gbDependencies.Font.Style := [fsBold];
  gbDependencies.BorderWidth := 5;
  
  lblDepTask := TLabel.Create(Self);
  lblDepTask.Parent := gbDependencies;
  lblDepTask.Left := 10;
  lblDepTask.Top := 5;
  lblDepTask.Caption := 'Esta Tarefa:';
  
  cbDepTask := TComboBox.Create(Self);
  cbDepTask.Parent := gbDependencies;
  cbDepTask.Left := 10;
  cbDepTask.Top := 22;
  cbDepTask.Width := 180;
  cbDepTask.Style := csDropDownList;
  
  lblDepTarget := TLabel.Create(Self);
  lblDepTarget.Parent := gbDependencies;
  lblDepTarget.Left := 205;
  lblDepTarget.Top := 5;
  lblDepTarget.Caption := 'Depende de (Outra Tarefa):';
  
  cbDepTarget := TComboBox.Create(Self);
  cbDepTarget.Parent := gbDependencies;
  cbDepTarget.Left := 205;
  cbDepTarget.Top := 22;
  cbDepTarget.Width := 180;
  cbDepTarget.Style := csDropDownList;
  
  btnLinkDependency := TButton.Create(Self);
  btnLinkDependency.Parent := gbDependencies;
  btnLinkDependency.Left := 395;
  btnLinkDependency.Top := 20;
  btnLinkDependency.Width := 135;
  btnLinkDependency.Height := 28;
  btnLinkDependency.Caption := '🔗 Lincar Dependência';
  btnLinkDependency.OnClick := @LinkDependencyClick;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlRight;
    Align := alTop;
    Height := 10;
    BevelOuter := bvNone;
  end;
  
  { Tasks Grid List }
  gbTasksList := TGroupBox.Create(Self);
  gbTasksList.Parent := pnlRight;
  gbTasksList.Align := alClient;
  gbTasksList.Caption := ' Cronograma e Visualizador de Fluxo ';
  gbTasksList.Font.Style := [fsBold];
  gbTasksList.BorderWidth := 5;
  
  lbTasks := TListBox.Create(Self);
  lbTasks.Parent := gbTasksList;
  lbTasks.Align := alLeft;
  lbTasks.Width := 220;
  lbTasks.OnClick := @TasksSelectionChanged;
  
  { Details and control panel for selected task }
  pnlSep := TPanel.Create(Self);
  pnlSep.Parent := gbTasksList;
  pnlSep.Align := alClient;
  pnlSep.BevelOuter := bvNone;
  pnlSep.BorderWidth := 8;
  
  memTaskDetails := TMemo.Create(Self);
  memTaskDetails.Parent := pnlSep;
  memTaskDetails.Align := alClient;
  memTaskDetails.ReadOnly := True;
  memTaskDetails.ScrollBars := ssAutoVertical;
  memTaskDetails.Color := $F9FAFB;
  
  lblReadyStatus := TLabel.Create(Self);
  lblReadyStatus.Parent := pnlSep;
  lblReadyStatus.Align := alTop;
  lblReadyStatus.Height := 30;
  lblReadyStatus.Alignment := taCenter;
  lblReadyStatus.Layout := tlCenter;
  lblReadyStatus.Caption := 'Selecione uma tarefa para ver se está pronta!';
  lblReadyStatus.Font.Style := [fsBold];
  lblReadyStatus.Font.Color := clGray;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlSep;
    Align := alTop;
    Height := 8;
    BevelOuter := bvNone;
  end;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlSep;
    Align := alBottom;
    Height := 8;
    BevelOuter := bvNone;
  end;
  
  with TPanel.Create(Self) do
  begin
    Parent := pnlSep;
    Align := alBottom;
    Height := 30;
    BevelOuter := bvNone;
    
    btnMarkDone := TButton.Create(Self);
    btnMarkDone.Parent := Parent as TWinControl;
    btnMarkDone.Align := alLeft;
    btnMarkDone.Width := 130;
    btnMarkDone.Caption := '✔️ Feito (MarkAsDone)';
    btnMarkDone.OnClick := @MarkDoneClick;
    
    btnMarkPending := TButton.Create(Self);
    btnMarkPending.Parent := Parent as TWinControl;
    btnMarkPending.Align := alRight;
    btnMarkPending.Width := 130;
    btnMarkPending.Caption := '⏳ Pendente (Pending)';
    btnMarkPending.OnClick := @MarkPendingClick;
  end;
end;

{ Storage Operations }

procedure TFormMain.StorageLoadClick(Sender: TObject);
begin
  FGroupStorage.FileName := edtStorageFile.Text;
  FGroupStorage.Load;
  ShowMessage('Dados de Configurações JSON Carregados com Sucesso!');
  GroupSelectClick(nil);
end;

procedure TFormMain.StorageSaveClick(Sender: TObject);
begin
  FGroupStorage.FileName := edtStorageFile.Text;
  FGroupStorage.Save;
  ShowMessage('Dados de Configurações salvos no arquivo JSON: ' + edtStorageFile.Text);
end;

procedure TFormMain.GroupSelectClick(Sender: TObject);
begin
  if Trim(edtGroup.Text) = '' then Exit;
  FGroupStorage.Select(edtGroup.Text);
  lblActiveGroup.Caption := 'Grupo Ativo: ' + FGroupStorage.ActiveGroup;
  
  { Clear key/value fields }
  edtKey.Text := '';
  memValue.Clear;
end;

procedure TFormMain.KeyFindClick(Sender: TObject);
var
  Val: string;
begin
  if Trim(edtKey.Text) = '' then Exit;
  Val := FGroupStorage.Find(edtKey.Text);
  memValue.Text := Val;
  if Val = '' then
    ShowMessage('Chave não encontrada neste grupo!')
  else
    ShowMessage('Chave "' + edtKey.Text + '" encontrada com sucesso!');
end;

procedure TFormMain.KeySetClick(Sender: TObject);
begin
  if Trim(edtKey.Text) = '' then Exit;
  FGroupStorage.SetVal(edtKey.Text, memValue.Text);
  ShowMessage('Chave "' + edtKey.Text + '" gravada com sucesso em memória!');
end;

{ Schedule Operations }

procedure TFormMain.ScheduleLoadClick(Sender: TObject);
begin
  FSchedule.FileName := edtScheduleFile.Text;
  FSchedule.Load;
  PopulateComboboxes;
  UpdateTasksList;
  ShowMessage('Cronograma carregado com sucesso!');
end;

procedure TFormMain.ScheduleSaveClick(Sender: TObject);
begin
  FSchedule.FileName := edtScheduleFile.Text;
  FSchedule.Save;
  ShowMessage('Cronograma salvo com sucesso no arquivo JSON!');
end;

procedure TFormMain.AddTaskClick(Sender: TObject);
var
  TName, TDesc, TParent: string;
  T: TScheduleTask;
begin
  TName := Trim(edtTaskName.Text);
  TDesc := Trim(edtTaskDesc.Text);
  
  if cbTaskParent.ItemIndex > 0 then
    TParent := cbTaskParent.Text
  else
    TParent := '';

  if TName = '' then
  begin
    ShowMessage('Digite o ID/Nome da Tarefa!');
    Exit;
  end;

  T := FSchedule.NewTask(TName, TParent);
  T.Description := TDesc;

  PopulateComboboxes;
  UpdateTasksList;
  
  edtTaskName.Text := '';
  edtTaskDesc.Text := '';
end;

procedure TFormMain.LinkDependencyClick(Sender: TObject);
var
  SrcTask, TargetTask: string;
  T: TScheduleTask;
begin
  if cbDepTask.ItemIndex < 0 then Exit;
  if cbDepTarget.ItemIndex < 0 then Exit;

  SrcTask := cbDepTask.Text;
  TargetTask := cbDepTarget.Text;

  if SrcTask = TargetTask then
  begin
    ShowMessage('Uma tarefa não pode depender dela mesma!');
    Exit;
  end;

  T := FSchedule.FindTask(SrcTask);
  if T <> nil then
  begin
    T.DependsOn(TargetTask);
    ShowTaskDetails;
    ShowMessage('Vínculo de dependência criado: "' + SrcTask + '" agora depende de "' + TargetTask + '"!');
  end;
end;

procedure TFormMain.MarkDoneClick(Sender: TObject);
var
  TName: string;
  T: TScheduleTask;
begin
  if lbTasks.ItemIndex < 0 then Exit;
  
  // Extract task name (ignoring formatting prefix)
  TName := lbTasks.Items[lbTasks.ItemIndex];
  if Pos(' ', TName) > 0 then
    TName := Copy(TName, Pos(' ', TName) + 1, Length(TName));
    
  T := FSchedule.FindTask(TName);
  if T <> nil then
  begin
    T.MarkAsDone;
    UpdateTasksList;
    ShowTaskDetails;
  end;
end;

procedure TFormMain.MarkPendingClick(Sender: TObject);
var
  TName: string;
  T: TScheduleTask;
begin
  if lbTasks.ItemIndex < 0 then Exit;
  
  TName := lbTasks.Items[lbTasks.ItemIndex];
  if Pos(' ', TName) > 0 then
    TName := Copy(TName, Pos(' ', TName) + 1, Length(TName));
    
  T := FSchedule.FindTask(TName);
  if T <> nil then
  begin
    T.MarkAsPending;
    UpdateTasksList;
    ShowTaskDetails;
  end;
end;

procedure TFormMain.TasksSelectionChanged(Sender: TObject);
begin
  ShowTaskDetails;
end;

procedure TFormMain.PopulateComboboxes;
var
  I: Integer;
  Task: TScheduleTask;
begin
  cbTaskParent.Clear;
  cbTaskParent.Items.Add('(Nenhum - Raiz)');
  
  cbDepTask.Clear;
  cbDepTarget.Clear;

  for I := 0 to FSchedule.Tasks.Count - 1 do
  begin
    Task := FSchedule.Tasks[I];
    cbTaskParent.Items.Add(Task.Name);
    cbDepTask.Items.Add(Task.Name);
    cbDepTarget.Items.Add(Task.Name);
  end;
  
  if cbTaskParent.Items.Count > 0 then cbTaskParent.ItemIndex := 0;
  if cbDepTask.Items.Count > 0 then cbDepTask.ItemIndex := 0;
  if cbDepTarget.Items.Count > 0 then cbDepTarget.ItemIndex := 0;
end;

procedure TFormMain.UpdateTasksList;
var
  I, SelIdx: Integer;
  Task: TScheduleTask;
  Prefix: string;
  Indent: string;
begin
  SelIdx := lbTasks.ItemIndex;
  lbTasks.Clear;

  for I := 0 to FSchedule.Tasks.Count - 1 do
  begin
    Task := FSchedule.Tasks[I];
    
    if Task.Status = tsDone then
      Prefix := '🟢 '
    else
      Prefix := '⏳ ';

    if Task.ParentName <> '' then
      Indent := '  └─ '
    else
      Indent := '';

    lbTasks.Items.Add(Indent + Prefix + Task.Name);
  end;
  
  if (SelIdx >= 0) and (SelIdx < lbTasks.Count) then
    lbTasks.ItemIndex := SelIdx;
end;

procedure TFormMain.ShowTaskDetails;
var
  TName: string;
  T: TScheduleTask;
  Details: TStringList;
  I: Integer;
  Deps: TStringList;
begin
  if lbTasks.ItemIndex < 0 then
  begin
    memTaskDetails.Clear;
    lblReadyStatus.Caption := 'Selecione uma tarefa para ver se está pronta!';
    lblReadyStatus.Font.Color := clGray;
    Exit;
  end;

  TName := lbTasks.Items[lbTasks.ItemIndex];
  
  // Strip indent and symbol
  if Pos('🟢 ', TName) > 0 then
    TName := Copy(TName, Pos('🟢 ', TName) + 4, Length(TName))
  else if Pos('⏳ ', TName) > 0 then
    TName := Copy(TName, Pos('⏳ ', TName) + 4, Length(TName));

  TName := Trim(TName);
  T := FSchedule.FindTask(TName);
  if T = nil then Exit;

  Details := TStringList.Create;
  try
    Details.Add('==================================================');
    Details.Add(' DETALHES DA TAREFA: ' + T.Name);
    Details.Add('==================================================');
    Details.Add('Descrição  : ' + T.Description);
    
    if T.Status = tsDone then
      Details.Add('Status     : FEITO (Done)')
    else
      Details.Add('Status     : PENDENTE (Pending)');

    if T.ParentName <> '' then
      Details.Add('Tarefa Pai : ' + T.ParentName)
    else
      Details.Add('Tarefa Pai : (Nenhum - Root Task)');

    Details.Add('');
    Details.Add('--- Vínculos de Dependência ---');
    Deps := T.GetDependencies;
    if Deps.Count = 0 then
      Details.Add('(Esta tarefa não possui dependências)')
    else
    begin
      for I := 0 to Deps.Count - 1 do
        Details.Add(' - Depende de: ' + Deps[I]);
    end;

    memTaskDetails.Text := Details.Text;
    
    { Update dynamic status label }
    if T.IsReady then
    begin
      lblReadyStatus.Caption := '✅ PRONTA PARA EXECUÇÃO (Dependências Satisfeitas!)';
      lblReadyStatus.Font.Color := $228B22; // Forest Green
    end
    else
    begin
      lblReadyStatus.Caption := '⚠️ BLOQUEADA (Aguardando tarefas dependentes...)';
      lblReadyStatus.Font.Color := $D2691E; // Chocolate / Orange
    end;
  finally
    Details.Free;
  end;
end;

end.
