unit uinstaller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Dialogs, CheckLst, installer_engine;

type
  TfrmInstaller = class(TForm)
  private
    FEngine: TInstallerEngine;
    FPages: TPageControl;
    FBack: TButton;
    FNext: TButton;
    FCancel: TButton;
    FTitle: TLabel;
    FRepoEdit: TEdit;
    FLazEdit: TEdit;
    FPCPEdit: TEdit;
    FEnvMemo: TMemo;
    FPackageList: TCheckListBox;
    FPrereqMemo: TMemo;
    FReadyMemo: TMemo;
    FLogMemo: TMemo;
    FFinishMemo: TMemo;
    FProgress: TProgressBar;
    FChkUpdate: TCheckBox;
    FChkSamples: TCheckBox;
    FChkDocs: TCheckBox;
    FOrder: TStringList;
    FSamples: TStringList;
    FBackup: string;
    FInstalling: Boolean;
    procedure BuildUI;
    procedure AddWelcomePage;
    procedure AddEnvironmentPage;
    procedure AddPackagesPage;
    procedure AddReadyPage;
    procedure AddProgressPage;
    procedure AddFinishPage;
    procedure UpdateButtons;
    procedure BackClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure EngineLog(Sender: TObject; const AMsg: string);
    function PrepareEnvironment: Boolean;
    function CheckAndUpdateRepository: Boolean;
    function PreparePackages: Boolean;
    function PrepareReady: Boolean;
    procedure SyncPackageSelection;
    procedure ExecuteInstallation;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmInstaller: TfrmInstaller;

implementation

constructor TfrmInstaller.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 1);
  FEngine := TInstallerEngine.Create;
  FEngine.OnLog := @EngineLog;
  FOrder := TStringList.Create;
  FSamples := TStringList.Create;
  BuildUI;
  FRepoEdit.Text := FEngine.RepoRoot;
end;

destructor TfrmInstaller.Destroy;
begin
  FSamples.Free;
  FOrder.Free;
  FEngine.Free;
  inherited Destroy;
end;

procedure TfrmInstaller.BuildUI;
var
  Header, Footer: TPanel;
  SubTitle: TLabel;
begin
  Caption := 'CHATGPT Lazarus Suite Installer';
  Width := 840;
  Height := 620;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMinimize];

  Header := TPanel.Create(Self);
  Header.Parent := Self;
  Header.Align := alTop;
  Header.Height := 82;
  Header.BevelOuter := bvNone;

  FTitle := TLabel.Create(Self);
  FTitle.Parent := Header;
  FTitle.SetBounds(24, 12, 760, 28);
  FTitle.Font.Size := 15;
  FTitle.Font.Style := [fsBold];
  FTitle.Caption := 'Instalação dos componentes CHATGPT';

  SubTitle := TLabel.Create(Self);
  SubTitle.Parent := Header;
  SubTitle.SetBounds(24, 46, 760, 24);
  SubTitle.Caption := 'Lazarus / Free Pascal - packages, samples e documentação';

  Footer := TPanel.Create(Self);
  Footer.Parent := Self;
  Footer.Align := alBottom;
  Footer.Height := 58;

  FBack := TButton.Create(Self);
  FBack.Parent := Footer;
  FBack.SetBounds(518, 14, 90, 30);
  FBack.Caption := '< Voltar';
  FBack.OnClick := @BackClick;

  FNext := TButton.Create(Self);
  FNext.Parent := Footer;
  FNext.SetBounds(614, 14, 100, 30);
  FNext.Caption := 'Avançar >';
  FNext.OnClick := @NextClick;

  FCancel := TButton.Create(Self);
  FCancel.Parent := Footer;
  FCancel.SetBounds(720, 14, 90, 30);
  FCancel.Caption := 'Cancelar';
  FCancel.OnClick := @CancelClick;

  FPages := TPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alClient;
  FPages.ShowTabs := False;

  AddWelcomePage;
  AddEnvironmentPage;
  AddPackagesPage;
  AddReadyPage;
  AddProgressPage;
  AddFinishPage;

  FPages.ActivePageIndex := 0;
  UpdateButtons;
end;

procedure TfrmInstaller.AddWelcomePage;
var
  T: TTabSheet;
  L: TLabel;
begin
  T := TTabSheet.Create(FPages);
  T.PageControl := FPages;
  T.Caption := 'Bem-vindo';

  L := TLabel.Create(T);
  L.Parent := T;
  L.SetBounds(34, 36, 730, 190);
  L.WordWrap := True;
  L.Font.Size := 12;
  L.Caption :=
    'Este assistente instala a suíte CHATGPT no Lazarus.' + LineEnding + LineEnding +
    'Ele detecta Lazarus e FPC, identifica 32 ou 64 bits, verifica os pré-requisitos ' +
    'dos packages, encontra instalações anteriores, calcula a ordem de dependências, ' +
    'compila e instala os componentes e recompila a IDE uma única vez.' + LineEnding + LineEnding +
    'Também pode compilar os samples e validar/copiar a documentação.' + LineEnding + LineEnding +
    'Feche o Lazarus antes de continuar.';

  FChkUpdate := TCheckBox.Create(T);
  FChkUpdate.Parent := T;
  FChkUpdate.SetBounds(34, 270, 700, 28);
  FChkUpdate.Caption := 'Verificar e baixar atualizações do GitHub antes de instalar';
  FChkUpdate.Checked := True;

  L := TLabel.Create(T);
  L.Parent := T;
  L.SetBounds(34, 320, 720, 80);
  L.WordWrap := True;
  L.Caption := 'A atualização automática usa somente git pull --ff-only. ' +
    'Se houver alterações locais, nenhum arquivo será sobrescrito automaticamente.';
end;

procedure TfrmInstaller.AddEnvironmentPage;
var
  T: TTabSheet;
  L: TLabel;
begin
  T := TTabSheet.Create(FPages);
  T.PageControl := FPages;
  T.Caption := 'Ambiente';

  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Pasta do projeto:'; L.SetBounds(24, 16, 200, 22);
  FRepoEdit := TEdit.Create(T); FRepoEdit.Parent := T; FRepoEdit.SetBounds(24, 40, 760, 28);

  L := TLabel.Create(T); L.Parent := T; L.Caption := 'lazbuild detectado:'; L.SetBounds(24, 78, 200, 22);
  FLazEdit := TEdit.Create(T); FLazEdit.Parent := T; FLazEdit.SetBounds(24, 102, 760, 28); FLazEdit.ReadOnly := True;

  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Configuração do Lazarus:'; L.SetBounds(24, 140, 220, 22);
  FPCPEdit := TEdit.Create(T); FPCPEdit.Parent := T; FPCPEdit.SetBounds(24, 164, 760, 28); FPCPEdit.ReadOnly := True;

  FEnvMemo := TMemo.Create(T);
  FEnvMemo.Parent := T;
  FEnvMemo.SetBounds(24, 212, 760, 220);
  FEnvMemo.ReadOnly := True;
  FEnvMemo.ScrollBars := ssVertical;
end;

procedure TfrmInstaller.AddPackagesPage;
var
  T: TTabSheet;
  L: TLabel;
begin
  T := TTabSheet.Create(FPages);
  T.PageControl := FPages;
  T.Caption := 'Packages';

  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Packages a instalar:'; L.SetBounds(24, 14, 300, 22);
  FPackageList := TCheckListBox.Create(T);
  FPackageList.Parent := T;
  FPackageList.SetBounds(24, 40, 350, 390);

  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Pré-requisitos:'; L.SetBounds(394, 14, 300, 22);
  FPrereqMemo := TMemo.Create(T);
  FPrereqMemo.Parent := T;
  FPrereqMemo.SetBounds(394, 40, 390, 390);
  FPrereqMemo.ReadOnly := True;
  FPrereqMemo.ScrollBars := ssBoth;
end;

procedure TfrmInstaller.AddReadyPage;
var
  T: TTabSheet;
begin
  T := TTabSheet.Create(FPages);
  T.PageControl := FPages;
  T.Caption := 'Pronto';

  FChkSamples := TCheckBox.Create(T);
  FChkSamples.Parent := T;
  FChkSamples.SetBounds(24, 10, 280, 28);
  FChkSamples.Caption := 'Compilar e validar samples';
  FChkSamples.Checked := True;

  FChkDocs := TCheckBox.Create(T);
  FChkDocs.Parent := T;
  FChkDocs.SetBounds(320, 10, 300, 28);
  FChkDocs.Caption := 'Validar e copiar documentação';
  FChkDocs.Checked := True;

  FReadyMemo := TMemo.Create(T);
  FReadyMemo.Parent := T;
  FReadyMemo.SetBounds(24, 46, 760, 384);
  FReadyMemo.ReadOnly := True;
  FReadyMemo.ScrollBars := ssVertical;
end;

procedure TfrmInstaller.AddProgressPage;
var
  T: TTabSheet;
begin
  T := TTabSheet.Create(FPages);
  T.PageControl := FPages;
  T.Caption := 'Instalando';

  FProgress := TProgressBar.Create(T);
  FProgress.Parent := T;
  FProgress.SetBounds(24, 18, 760, 24);
  FProgress.Min := 0;
  FProgress.Max := 100;

  FLogMemo := TMemo.Create(T);
  FLogMemo.Parent := T;
  FLogMemo.SetBounds(24, 58, 760, 372);
  FLogMemo.ReadOnly := True;
  FLogMemo.ScrollBars := ssBoth;
end;

procedure TfrmInstaller.AddFinishPage;
var
  T: TTabSheet;
begin
  T := TTabSheet.Create(FPages);
  T.PageControl := FPages;
  T.Caption := 'Concluir';
  FFinishMemo := TMemo.Create(T);
  FFinishMemo.Parent := T;
  FFinishMemo.Align := alClient;
  FFinishMemo.BorderSpacing.Around := 26;
  FFinishMemo.ReadOnly := True;
  FFinishMemo.ScrollBars := ssVertical;
end;

procedure TfrmInstaller.UpdateButtons;
begin
  FBack.Enabled := (FPages.ActivePageIndex > 0) and
    (FPages.ActivePageIndex < 4) and not FInstalling;
  FCancel.Enabled := not FInstalling;
  FNext.Enabled := not FInstalling;
  case FPages.ActivePageIndex of
    0, 1, 2: FNext.Caption := 'Avançar >';
    3: FNext.Caption := 'Instalar';
    4: begin FNext.Caption := 'Aguarde...'; FNext.Enabled := False; end;
    5: FNext.Caption := 'Concluir';
  end;
end;

procedure TfrmInstaller.EngineLog(Sender: TObject; const AMsg: string);
begin
  if Assigned(FLogMemo) then
  begin
    FLogMemo.Lines.Add(AMsg);
    FLogMemo.SelStart := Length(FLogMemo.Text);
  end;
  Application.ProcessMessages;
end;

function TfrmInstaller.PrepareEnvironment: Boolean;
begin
  Screen.Cursor := crHourGlass;
  try
    FEngine.RepoRoot := ExpandFileName(FRepoEdit.Text);
    FEnvMemo.Clear;
    Result := FEngine.DetectEnvironment;
    if Result then
    begin
      FLazEdit.Text := FEngine.LazBuild;
      FPCPEdit.Text := FEngine.PrimaryConfigPath;
      FEnvMemo.Lines.Add('Lazarus: ' + FEngine.LazarusVersion);
      FEnvMemo.Lines.Add('FPC: ' + FEngine.FPCVersion);
      FEnvMemo.Lines.Add('CPU alvo: ' + FEngine.TargetCPU);
      FEnvMemo.Lines.Add('OS alvo: ' + FEngine.TargetOS);
      FEnvMemo.Lines.Add('Compilação: ' + IntToStr(FEngine.TargetBits) + ' bits');
      FEnvMemo.Lines.Add('Git: ' + FEngine.Git);
    end
    else
      MessageDlg('Não foi possível detectar Lazarus/FPC.', mtError, [mbOK], 0);
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TfrmInstaller.CheckAndUpdateRepository: Boolean;
var
  Available: Boolean;
  Details, Dirty: string;
  R: Integer;
begin
  Result := True;
  if not FChkUpdate.Checked then Exit;
  if FEngine.Git = '' then
  begin
    MessageDlg('Git não encontrado. A instalação continuará com os arquivos locais.',
      mtWarning, [mbOK], 0);
    Exit;
  end;
  if not FEngine.IsGitRepository then
  begin
    MessageDlg('A pasta selecionada não é um clone Git. A instalação continuará localmente.',
      mtInformation, [mbOK], 0);
    Exit;
  end;
  if FEngine.HasLocalChanges(Dirty) then
  begin
    R := MessageDlg('Existem alterações locais. O instalador não fará atualização automática.' +
      LineEnding + LineEnding + 'Continuar com a versão local?',
      mtWarning, [mbYes, mbNo], 0);
    Exit(R = mrYes);
  end;
  if not FEngine.CheckRemoteUpdate(Available, Details) then
  begin
    R := MessageDlg('Não foi possível verificar atualizações.' + LineEnding + Details +
      LineEnding + LineEnding + 'Continuar com a versão local?',
      mtWarning, [mbYes, mbNo], 0);
    Exit(R = mrYes);
  end;
  if not Available then
  begin
    MessageDlg('O projeto já está atualizado.', mtInformation, [mbOK], 0);
    Exit;
  end;

  R := MessageDlg('Há uma versão mais recente no GitHub.' + LineEnding + LineEnding +
    Details + LineEnding + LineEnding + 'Deseja baixar e atualizar antes de instalar?',
    mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if R = mrCancel then Exit(False);
  if R = mrNo then Exit(True);
  if not FEngine.UpdateRepository(Details) then
  begin
    MessageDlg('Falha ao atualizar:' + LineEnding + Details, mtError, [mbOK], 0);
    Exit(False);
  end;
  MessageDlg('Projeto atualizado com sucesso.' + LineEnding + Details,
    mtInformation, [mbOK], 0);
end;

function TfrmInstaller.PreparePackages: Boolean;
var
  I: Integer;
  P: TPackageInfo;
  Missing, Err: string;
begin
  Result := FEngine.ScanPackages;
  if not Result then
  begin
    MessageDlg('Nenhum openai_*.lpk foi encontrado.', mtError, [mbOK], 0);
    Exit;
  end;
  FPackageList.Clear;
  for I := 0 to FEngine.Packages.Count - 1 do
  begin
    P := TPackageInfo(FEngine.Packages[I]);
    FPackageList.Items.Add(P.Name);
    FPackageList.Checked[I] := True;
  end;
  FPrereqMemo.Clear;
  if FEngine.CheckPrerequisites(Missing) then
    FPrereqMemo.Lines.Add('Todos os pré-requisitos localizados.')
  else
  begin
    FPrereqMemo.Lines.Add('Pré-requisitos não localizados:');
    FPrereqMemo.Lines.Add('');
    FPrereqMemo.Lines.Add(Missing);
  end;
  if not FEngine.BuildInstallOrder(FOrder, Err) then
  begin
    FPrereqMemo.Lines.Add('');
    FPrereqMemo.Lines.Add('ERRO: ' + Err);
    Result := False;
  end;
end;

procedure TfrmInstaller.SyncPackageSelection;
var
  I: Integer;
begin
  for I := 0 to FEngine.Packages.Count - 1 do
    TPackageInfo(FEngine.Packages[I]).Selected := FPackageList.Checked[I];
end;

function TfrmInstaller.PrepareReady: Boolean;
var
  Installed: TStringList;
  Missing, Err: string;
  I: Integer;
begin
  Result := False;
  SyncPackageSelection;
  if not FEngine.CheckPrerequisites(Missing) then
    if MessageDlg('Existem pré-requisitos não localizados.' + LineEnding +
      'Continuar mesmo assim?', mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;
  if not FEngine.BuildInstallOrder(FOrder, Err) then
  begin
    MessageDlg(Err, mtError, [mbOK], 0);
    Exit;
  end;

  Installed := TStringList.Create;
  try
    FEngine.GetInstalledSuitePackages(Installed);
    FReadyMemo.Clear;
    FReadyMemo.Lines.Add('Plataforma: ' + FEngine.TargetCPU + '-' + FEngine.TargetOS +
      ' / ' + IntToStr(FEngine.TargetBits) + ' bits');
    FReadyMemo.Lines.Add('');
    FReadyMemo.Lines.Add('Packages CHATGPT atualmente instalados:');
    if Installed.Count = 0 then FReadyMemo.Lines.Add('  Nenhum.')
    else for I := 0 to Installed.Count - 1 do FReadyMemo.Lines.Add('  ' + Installed[I]);
    FReadyMemo.Lines.Add('');
    FReadyMemo.Lines.Add('Ordem calculada:');
    for I := 0 to FOrder.Count - 1 do
      FReadyMemo.Lines.Add(Format('  %2d. %s', [I + 1, FOrder[I]]));
    FReadyMemo.Lines.Add('');
    FReadyMemo.Lines.Add('O instalador fará backup da configuração, removerá os registros antigos,');
    FReadyMemo.Lines.Add('limpará PPUs, compilará na plataforma acima, registrará os packages e');
    FReadyMemo.Lines.Add('recompilará a IDE uma única vez.');
    Result := True;
  finally
    Installed.Free;
  end;
end;

procedure TfrmInstaller.ExecuteInstallation;
var
  Verify, SampleResult, DocResult: TStringList;
  PackagesOK, SamplesOK, DocsOK: Boolean;
  InstallRoot: string;
begin
  FInstalling := True;
  FProgress.Position := 2;
  FLogMemo.Clear;
  UpdateButtons;
  PackagesOK := False;
  SamplesOK := True;
  DocsOK := True;
  Verify := TStringList.Create;
  SampleResult := TStringList.Create;
  DocResult := TStringList.Create;
  try
    EngineLog(Self, '=== CHATGPT Installer ===');
    EngineLog(Self, 'Target: ' + FEngine.TargetCPU + '-' + FEngine.TargetOS +
      ' / ' + IntToStr(FEngine.TargetBits) + ' bits');

    FProgress.Position := 8;
    if not FEngine.BackupAndRemoveOldPackages(FBackup) then Exit;
    FProgress.Position := 15;
    FEngine.CleanSuiteBuildCaches;
    FProgress.Position := 22;
    if not FEngine.CompileSelected(FOrder) then Exit;
    FProgress.Position := 58;
    if not FEngine.RegisterSelected(FOrder) then Exit;
    FProgress.Position := 72;
    if not FEngine.RebuildIDE then Exit;
    FProgress.Position := 80;
    PackagesOK := FEngine.VerifyInstalled(FOrder, Verify);

    if FChkSamples.Checked then
    begin
      if FEngine.ScanSamples(FSamples) then
        SamplesOK := FEngine.CompileSamples(FSamples, SampleResult)
      else
      begin
        SampleResult.Add('[FALTA] pacote/samples');
        SamplesOK := False;
      end;
    end;

    FProgress.Position := 92;
    if FChkDocs.Checked then
    begin
      DocsOK := FEngine.ValidateDocumentation(DocResult);
      InstallRoot := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'installed_content';
      FEngine.CopyDocumentation(InstallRoot, DocResult);
    end;

    FFinishMemo.Clear;
    if PackagesOK and SamplesOK and DocsOK then
      FFinishMemo.Lines.Add('Instalação concluída com sucesso.')
    else
      FFinishMemo.Lines.Add('Instalação concluída com pendências.');
    FFinishMemo.Lines.Add('');
    FFinishMemo.Lines.Add('Plataforma: ' + IntToStr(FEngine.TargetBits) + ' bits');
    FFinishMemo.Lines.Add('');
    FFinishMemo.Lines.Add('Packages:');
    FFinishMemo.Lines.AddStrings(Verify);
    if FChkSamples.Checked then
    begin
      FFinishMemo.Lines.Add('');
      FFinishMemo.Lines.Add('Samples:');
      FFinishMemo.Lines.AddStrings(SampleResult);
    end;
    if FChkDocs.Checked then
    begin
      FFinishMemo.Lines.Add('');
      FFinishMemo.Lines.Add('Documentação:');
      FFinishMemo.Lines.AddStrings(DocResult);
    end;
    if FBackup <> '' then
    begin
      FFinishMemo.Lines.Add('');
      FFinishMemo.Lines.Add('Backup da configuração anterior:');
      FFinishMemo.Lines.Add(FBackup);
    end;
    FProgress.Position := 100;
  finally
    DocResult.Free;
    SampleResult.Free;
    Verify.Free;
    if FFinishMemo.Lines.Count = 0 then
    begin
      FFinishMemo.Lines.Add('A instalação não foi concluída.');
      FFinishMemo.Lines.Add('Consulte o log da etapa de progresso.');
      if FBackup <> '' then FFinishMemo.Lines.Add('Backup: ' + FBackup);
    end;
    FInstalling := False;
    FPages.ActivePageIndex := 5;
    UpdateButtons;
  end;
end;

procedure TfrmInstaller.BackClick(Sender: TObject);
begin
  if FPages.ActivePageIndex > 0 then Dec(FPages.ActivePageIndex);
  UpdateButtons;
end;

procedure TfrmInstaller.NextClick(Sender: TObject);
begin
  case FPages.ActivePageIndex of
    0:
      begin
        FPages.ActivePageIndex := 1;
        if not PrepareEnvironment then Exit;
        if not CheckAndUpdateRepository then
        begin
          FPages.ActivePageIndex := 0;
          Exit;
        end;
      end;
    1:
      if PreparePackages then FPages.ActivePageIndex := 2;
    2:
      if PrepareReady then FPages.ActivePageIndex := 3;
    3:
      begin
        FPages.ActivePageIndex := 4;
        UpdateButtons;
        Application.ProcessMessages;
        ExecuteInstallation;
      end;
    5: Close;
  end;
  UpdateButtons;
end;

procedure TfrmInstaller.CancelClick(Sender: TObject);
begin
  if FInstalling then Exit;
  if MessageDlg('Cancelar a instalação?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    Close;
end;

end.
