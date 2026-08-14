unit uinstaller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Dialogs, CheckLst, installer_engine;

type
  TfrmInstaller = class(TForm)
  private
    FEngine: TInstallerEngine;
    FPages: TPageControl;
    FBack, FNext, FCancel: TButton;
    FRepoEdit, FLazEdit, FPCPEdit: TEdit;
    FBtnBrowseRepo, FBtnBrowseLaz, FBtnBrowsePCP, FBtnRefreshEnv: TButton;
    FRepoStatusLabel: TLabel;
    FOpenDialog: TOpenDialog;
    FEnvMemo, FPrereqMemo, FReadyMemo, FLogMemo, FFinishMemo: TMemo;
    FPackageList: TCheckListBox;
    FProgress: TProgressBar;
    FChkUpdate, FChkSamples, FChkDocs: TCheckBox;
    FOrder, FSamples: TStringList;
    FBackup: string;
    FInstalling: Boolean;
    procedure BuildUI;
    function NewPage(const ACaption: string): TTabSheet;
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
    procedure BrowseRepoClick(Sender: TObject);
    procedure BrowseLazClick(Sender: TObject);
    procedure BrowsePCPClick(Sender: TObject);
    procedure RefreshEnvClick(Sender: TObject);
    procedure RepoEditChange(Sender: TObject);
    procedure ValidateRepoPath;
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

function TfrmInstaller.NewPage(const ACaption: string): TTabSheet;
begin
  Result := TTabSheet.Create(FPages);
  Result.PageControl := FPages;
  Result.Caption := ACaption;
end;

procedure TfrmInstaller.BuildUI;
var
  Header, Footer: TPanel;
  L: TLabel;
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
  L := TLabel.Create(Header);
  L.Parent := Header;
  L.SetBounds(24, 12, 760, 28);
  L.Font.Size := 15;
  L.Font.Style := [fsBold];
  L.Caption := 'Instalação dos componentes CHATGPT';
  L := TLabel.Create(Header);
  L.Parent := Header;
  L.SetBounds(24, 46, 760, 24);
  L.Caption := 'Packages, samples e documentação para Lazarus / Free Pascal';

  Footer := TPanel.Create(Self);
  Footer.Parent := Self;
  Footer.Align := alBottom;
  Footer.Height := 58;
  FBack := TButton.Create(Footer);
  FBack.Parent := Footer;
  FBack.SetBounds(518, 14, 90, 30);
  FBack.Caption := '< Voltar';
  FBack.OnClick := @BackClick;
  FNext := TButton.Create(Footer);
  FNext.Parent := Footer;
  FNext.SetBounds(614, 14, 100, 30);
  FNext.Caption := 'Avançar >';
  FNext.OnClick := @NextClick;
  FCancel := TButton.Create(Footer);
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
  T := NewPage('Bem-vindo');
  L := TLabel.Create(T);
  L.Parent := T;
  L.SetBounds(34, 36, 730, 190);
  L.WordWrap := True;
  L.Font.Size := 12;
  L.Caption := 'Este assistente instala a suíte CHATGPT no Lazarus.' + LineEnding + LineEnding +
    'Ele detecta Lazarus/FPC, identifica 32 ou 64 bits, verifica pré-requisitos, ' +
    'remove a instalação anterior, calcula dependências, compila e instala os packages.' +
    LineEnding + LineEnding + 'Também pode compilar samples e validar/copiar a documentação.' +
    LineEnding + LineEnding + 'Feche o Lazarus antes de continuar.';
  FChkUpdate := TCheckBox.Create(T);
  FChkUpdate.Parent := T;
  FChkUpdate.SetBounds(34, 270, 700, 28);
  FChkUpdate.Caption := 'Verificar e baixar atualizações do GitHub antes de instalar';
  FChkUpdate.Checked := True;
  L := TLabel.Create(T);
  L.Parent := T;
  L.SetBounds(34, 320, 720, 70);
  L.WordWrap := True;
  L.Caption := 'Se houver alterações locais, o instalador não executa pull e não sobrescreve os arquivos.';
end;

procedure TfrmInstaller.ValidateRepoPath;
var
  Dir: string;
  LpkCount: Integer;
  SR: TSearchRec;
begin
  if not Assigned(FRepoStatusLabel) then Exit;
  Dir := IncludeTrailingPathDelimiter(Trim(FRepoEdit.Text)) + 'pacote' + DirectorySeparator + 'packages';
  if DirectoryExists(Dir) then
  begin
    LpkCount := 0;
    if FindFirst(IncludeTrailingPathDelimiter(Dir) + 'openai_*.lpk', faAnyFile, SR) = 0 then
    try
      repeat
        Inc(LpkCount);
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
    FRepoStatusLabel.Font.Color := $008000;
    FRepoStatusLabel.Caption := Format('OK: Projeto CHATGPT válido (%d pacotes encontrados em pacote\packages)', [LpkCount]);
  end
  else
  begin
    FRepoStatusLabel.Font.Color := clRed;
    FRepoStatusLabel.Caption := 'AVISO: Pasta não contém a subpasta pacote\packages';
  end;
end;

procedure TfrmInstaller.RepoEditChange(Sender: TObject);
begin
  ValidateRepoPath;
end;

procedure TfrmInstaller.BrowseRepoClick(Sender: TObject);
var
  SelectedDir: string;
begin
  SelectedDir := Trim(FRepoEdit.Text);
  if SelectDirectory('Selecione a pasta raiz do projeto CHATGPT', '', SelectedDir, True) then
  begin
    FRepoEdit.Text := SelectedDir;
    ValidateRepoPath;
    PrepareEnvironment;
  end;
end;

procedure TfrmInstaller.BrowseLazClick(Sender: TObject);
begin
  if not Assigned(FOpenDialog) then
  begin
    FOpenDialog := TOpenDialog.Create(Self);
    FOpenDialog.Title := 'Selecionar executável lazbuild';
    {$IFDEF Windows}
    FOpenDialog.Filter := 'lazbuild (lazbuild.exe)|lazbuild.exe|Executáveis (*.exe)|*.exe|Todos os arquivos (*.*)|*.*';
    {$ELSE}
    FOpenDialog.Filter := 'lazbuild|lazbuild|Todos os arquivos (*.*)|*.*';
    {$ENDIF}
  end;
  if FileExists(FLazEdit.Text) then
    FOpenDialog.InitialDir := ExtractFilePath(FLazEdit.Text)
  else
    FOpenDialog.InitialDir := 'C:\lazarus';

  if FOpenDialog.Execute then
  begin
    FLazEdit.Text := FOpenDialog.FileName;
    PrepareEnvironment;
  end;
end;

procedure TfrmInstaller.BrowsePCPClick(Sender: TObject);
var
  SelectedDir: string;
begin
  SelectedDir := Trim(FPCPEdit.Text);
  if SelectDirectory('Selecione a pasta de configuração do Lazarus (Primary Config Path)', '', SelectedDir, True) then
  begin
    FPCPEdit.Text := SelectedDir;
    PrepareEnvironment;
  end;
end;

procedure TfrmInstaller.RefreshEnvClick(Sender: TObject);
begin
  PrepareEnvironment;
end;

procedure TfrmInstaller.AddEnvironmentPage;
var
  T: TTabSheet;
  L: TLabel;
begin
  T := NewPage('Ambiente');

  // 1. Pasta do projeto
  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Pasta raiz do projeto:'; L.SetBounds(24, 10, 300, 20);
  FRepoEdit := TEdit.Create(T); FRepoEdit.Parent := T; FRepoEdit.SetBounds(24, 30, 670, 26);
  FRepoEdit.OnChange := @RepoEditChange;
  FBtnBrowseRepo := TButton.Create(T); FBtnBrowseRepo.Parent := T; FBtnBrowseRepo.SetBounds(702, 30, 100, 26);
  FBtnBrowseRepo.Caption := 'Localizar...'; FBtnBrowseRepo.OnClick := @BrowseRepoClick;

  FRepoStatusLabel := TLabel.Create(T); FRepoStatusLabel.Parent := T; FRepoStatusLabel.SetBounds(24, 58, 778, 18);
  FRepoStatusLabel.Font.Size := 9;
  ValidateRepoPath;

  // 2. Executável lazbuild
  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Executável lazbuild (compilador da IDE):'; L.SetBounds(24, 78, 350, 20);
  FLazEdit := TEdit.Create(T); FLazEdit.Parent := T; FLazEdit.SetBounds(24, 98, 670, 26);
  FBtnBrowseLaz := TButton.Create(T); FBtnBrowseLaz.Parent := T; FBtnBrowseLaz.SetBounds(702, 98, 100, 26);
  FBtnBrowseLaz.Caption := 'Localizar...'; FBtnBrowseLaz.OnClick := @BrowseLazClick;

  // 3. Configuração do Lazarus (PCP)
  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Pasta de configuração do Lazarus (Primary Config Path):'; L.SetBounds(24, 128, 450, 20);
  FPCPEdit := TEdit.Create(T); FPCPEdit.Parent := T; FPCPEdit.SetBounds(24, 148, 670, 26);
  FBtnBrowsePCP := TButton.Create(T); FBtnBrowsePCP.Parent := T; FBtnBrowsePCP.SetBounds(702, 148, 100, 26);
  FBtnBrowsePCP.Caption := 'Localizar...'; FBtnBrowsePCP.OnClick := @BrowsePCPClick;

  // 4. Botão Reanalisar
  FBtnRefreshEnv := TButton.Create(T); FBtnRefreshEnv.Parent := T; FBtnRefreshEnv.SetBounds(24, 180, 160, 28);
  FBtnRefreshEnv.Caption := 'Reanalisar Ambiente'; FBtnRefreshEnv.OnClick := @RefreshEnvClick;

  // 5. Diagnóstico de Plataforma e Compilação
  L := TLabel.Create(T); L.Parent := T;
  L.Caption := 'Diagnóstico de Plataforma, Compilador e Alvos (Windows / Linux / 32 / 64 bits):';
  L.SetBounds(24, 214, 600, 20);

  FEnvMemo := TMemo.Create(T); FEnvMemo.Parent := T; FEnvMemo.SetBounds(24, 234, 778, 200);
  FEnvMemo.ReadOnly := True; FEnvMemo.ScrollBars := ssBoth;
  FEnvMemo.Font.Name := 'Courier New';
  FEnvMemo.Font.Size := 9;
end;

procedure TfrmInstaller.AddPackagesPage;
var
  T: TTabSheet;
  L: TLabel;
begin
  T := NewPage('Packages');
  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Packages a instalar:'; L.SetBounds(24, 14, 300, 22);
  FPackageList := TCheckListBox.Create(T); FPackageList.Parent := T; FPackageList.SetBounds(24, 40, 350, 390);
  L := TLabel.Create(T); L.Parent := T; L.Caption := 'Pré-requisitos:'; L.SetBounds(394, 14, 300, 22);
  FPrereqMemo := TMemo.Create(T); FPrereqMemo.Parent := T; FPrereqMemo.SetBounds(394, 40, 390, 390);
  FPrereqMemo.ReadOnly := True; FPrereqMemo.ScrollBars := ssBoth;
end;

procedure TfrmInstaller.AddReadyPage;
var
  T: TTabSheet;
begin
  T := NewPage('Pronto');
  FChkSamples := TCheckBox.Create(T); FChkSamples.Parent := T; FChkSamples.SetBounds(24, 10, 280, 28);
  FChkSamples.Caption := 'Compilar e validar samples'; FChkSamples.Checked := True;
  FChkDocs := TCheckBox.Create(T); FChkDocs.Parent := T; FChkDocs.SetBounds(320, 10, 300, 28);
  FChkDocs.Caption := 'Validar e copiar documentação'; FChkDocs.Checked := True;
  FReadyMemo := TMemo.Create(T); FReadyMemo.Parent := T; FReadyMemo.SetBounds(24, 46, 760, 384);
  FReadyMemo.ReadOnly := True; FReadyMemo.ScrollBars := ssVertical;
end;

procedure TfrmInstaller.AddProgressPage;
var
  T: TTabSheet;
begin
  T := NewPage('Instalando');
  FProgress := TProgressBar.Create(T); FProgress.Parent := T; FProgress.SetBounds(24, 18, 760, 24);
  FProgress.Min := 0; FProgress.Max := 100;
  FLogMemo := TMemo.Create(T); FLogMemo.Parent := T; FLogMemo.SetBounds(24, 58, 760, 372);
  FLogMemo.ReadOnly := True; FLogMemo.ScrollBars := ssBoth;
end;

procedure TfrmInstaller.AddFinishPage;
var
  T: TTabSheet;
begin
  T := NewPage('Concluir');
  FFinishMemo := TMemo.Create(T); FFinishMemo.Parent := T; FFinishMemo.Align := alClient;
  FFinishMemo.BorderSpacing.Around := 26; FFinishMemo.ReadOnly := True; FFinishMemo.ScrollBars := ssVertical;
end;

procedure TfrmInstaller.UpdateButtons;
begin
  FBack.Enabled := (FPages.ActivePageIndex > 0) and (FPages.ActivePageIndex < 4) and not FInstalling;
  FCancel.Enabled := not FInstalling;
  FNext.Enabled := not FInstalling;
  case FPages.ActivePageIndex of
    0,1,2: FNext.Caption := 'Avançar >';
    3: FNext.Caption := 'Instalar';
    4: begin FNext.Caption := 'Aguarde...'; FNext.Enabled := False; end;
    5: FNext.Caption := 'Concluir';
  end;
end;

procedure TfrmInstaller.EngineLog(Sender: TObject; const AMsg: string);
begin
  FLogMemo.Lines.Add(AMsg);
  FLogMemo.SelStart := Length(FLogMemo.Text);
  Application.ProcessMessages;
end;

function TfrmInstaller.PrepareEnvironment: Boolean;
var
  I: Integer;
  TargetsStr: string;
begin
  Screen.Cursor := crHourGlass;
  try
    FEngine.RepoRoot := ExpandFileName(Trim(FRepoEdit.Text));
    if Trim(FLazEdit.Text) <> '' then
      FEngine.LazBuild := Trim(FLazEdit.Text);
    if Trim(FPCPEdit.Text) <> '' then
      FEngine.PrimaryConfigPath := Trim(FPCPEdit.Text);

    Result := FEngine.DetectEnvironment;
    ValidateRepoPath;
    FEnvMemo.Clear;
    if Result then
    begin
      FLazEdit.Text := FEngine.LazBuild;
      FPCPEdit.Text := FEngine.PrimaryConfigPath;

      FEnvMemo.Lines.Add('=== DIAGNÓSTICO DO AMBIENTE LAZARUS / FPC ===');
      FEnvMemo.Lines.Add('Lazarus IDE: ' + FEngine.LazarusVersion + ' (' + FEngine.LazBuild + ')');
      FEnvMemo.Lines.Add('FPC Compiler: ' + FEngine.FPCVersion + ' (' + FEngine.FPC + ')');
      FEnvMemo.Lines.Add('Configuração (PCP): ' + FEngine.PrimaryConfigPath);
      FEnvMemo.Lines.Add('');
      FEnvMemo.Lines.Add('--- ARQUITETURA E ALVOS DE COMPILAÇÃO ---');
      FEnvMemo.Lines.Add(Format('Alvo Ativo: %s-%s (%d bits)', [FEngine.TargetCPU, FEngine.TargetOS, FEngine.TargetBits]));

      if FEngine.TargetBits = 64 then
        FEnvMemo.Lines.Add('Arquitetura Atual: 64 bits (x86_64 / x64)')
      else
        FEnvMemo.Lines.Add('Arquitetura Atual: 32 bits (i386 / x86)');

      if FEngine.HasWin32 or FEngine.HasWin64 then
      begin
        TargetsStr := '';
        if FEngine.HasWin32 then TargetsStr := TargetsStr + 'win32 (32b) ';
        if FEngine.HasWin64 then TargetsStr := TargetsStr + 'win64 (64b) ';
        FEnvMemo.Lines.Add('[OK] Compilação Windows: DISPONÍVEL (' + Trim(TargetsStr) + ')');
      end
      else
        FEnvMemo.Lines.Add('[AVISO] Compilação Windows: Não detectada no FPC ativo');

      if FEngine.HasLinux32 or FEngine.HasLinux64 then
      begin
        TargetsStr := '';
        if FEngine.HasLinux32 then TargetsStr := TargetsStr + 'linux-i386 ';
        if FEngine.HasLinux64 then TargetsStr := TargetsStr + 'linux-x86_64 ';
        FEnvMemo.Lines.Add('[OK] Compilação Linux: DISPONÍVEL (' + Trim(TargetsStr) + ')');
      end
      else
        FEnvMemo.Lines.Add('[INFO] Compilação Linux: Não instalada (cross-compiler ausente)');

      if FEngine.SupportedTargets.Count > 0 then
      begin
        TargetsStr := '';
        for I := 0 to FEngine.SupportedTargets.Count - 1 do
        begin
          if I > 0 then TargetsStr := TargetsStr + ', ';
          TargetsStr := TargetsStr + FEngine.SupportedTargets[I];
        end;
        FEnvMemo.Lines.Add('Alvos FPC instalados: ' + TargetsStr);
      end;

      FEnvMemo.Lines.Add('');
      if FEngine.Git <> '' then
        FEnvMemo.Lines.Add('Git: ' + FEngine.Git)
      else
        FEnvMemo.Lines.Add('[ATENÇÃO] Git não encontrado no PATH');
    end
    else
      MessageDlg('Não foi possível detectar o Lazarus/FPC nos caminhos informados.', mtError, [mbOK], 0);
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
    MessageDlg('Git não encontrado. Continuando com os arquivos locais.', mtWarning, [mbOK], 0);
    Exit;
  end;
  if not FEngine.IsGitRepository then
  begin
    MessageDlg('A pasta não é um clone Git. Continuando localmente.', mtInformation, [mbOK], 0);
    Exit;
  end;
  if FEngine.HasLocalChanges(Dirty) then
  begin
    R := MessageDlg('Existem alterações locais. A atualização automática foi bloqueada.' +
      LineEnding + 'Continuar com a versão local?', mtWarning, [mbYes, mbNo], 0);
    Result := R = mrYes;
    Exit;
  end;
  if not FEngine.CheckRemoteUpdate(Available, Details) then
  begin
    R := MessageDlg('Não foi possível verificar atualizações.' + LineEnding + Details +
      LineEnding + 'Continuar localmente?', mtWarning, [mbYes, mbNo], 0);
    Result := R = mrYes;
    Exit;
  end;
  if not Available then
  begin
    MessageDlg('O projeto já está atualizado.', mtInformation, [mbOK], 0);
    Exit;
  end;
  R := MessageDlg('Há uma versão mais recente no GitHub.' + LineEnding + Details +
    LineEnding + 'Deseja baixar antes de instalar?', mtConfirmation, [mbYes, mbNo, mbCancel], 0);
  if R = mrCancel then begin Result := False; Exit; end;
  if R = mrNo then Exit;
  Result := FEngine.UpdateRepository(Details);
  if Result then MessageDlg('Projeto atualizado.', mtInformation, [mbOK], 0)
  else MessageDlg('Falha ao atualizar:' + LineEnding + Details, mtError, [mbOK], 0);
end;

function TfrmInstaller.PreparePackages: Boolean;
var
  I: Integer;
  P: TPackageInfo;
  Missing, Err: string;
begin
  Result := FEngine.ScanPackages;
  if not Result then begin MessageDlg('Nenhum openai_*.lpk encontrado.', mtError, [mbOK], 0); Exit; end;
  FPackageList.Clear;
  for I := 0 to FEngine.Packages.Count - 1 do
  begin
    P := TPackageInfo(FEngine.Packages[I]);
    FPackageList.Items.Add(P.Name);
    FPackageList.Checked[I] := True;
  end;
  FPrereqMemo.Clear;
  if FEngine.CheckPrerequisites(Missing) then FPrereqMemo.Lines.Add('Todos os pré-requisitos localizados.')
  else begin FPrereqMemo.Lines.Add('Pré-requisitos não localizados:'); FPrereqMemo.Lines.Add(Missing); end;
  if not FEngine.BuildInstallOrder(FOrder, Err) then
  begin
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
    if MessageDlg('Há pré-requisitos não localizados. Continuar?', mtWarning, [mbYes, mbNo], 0) <> mrYes then Exit;
  if not FEngine.BuildInstallOrder(FOrder, Err) then begin MessageDlg(Err, mtError, [mbOK], 0); Exit; end;
  Installed := TStringList.Create;
  try
    FEngine.GetInstalledSuitePackages(Installed);
    FReadyMemo.Clear;
    FReadyMemo.Lines.Add('Plataforma: ' + FEngine.TargetCPU + '-' + FEngine.TargetOS +
      ' / ' + IntToStr(FEngine.TargetBits) + ' bits');
    FReadyMemo.Lines.Add('');
    FReadyMemo.Lines.Add('Instalação anterior:');
    if Installed.Count = 0 then FReadyMemo.Lines.Add('  Nenhuma.')
    else for I := 0 to Installed.Count - 1 do FReadyMemo.Lines.Add('  ' + Installed[I]);
    FReadyMemo.Lines.Add('');
    FReadyMemo.Lines.Add('Ordem de instalação:');
    for I := 0 to FOrder.Count - 1 do FReadyMemo.Lines.Add(Format('  %2d. %s', [I+1, FOrder[I]]));
    FReadyMemo.Lines.Add('');
    FReadyMemo.Lines.Add('Será feito backup, limpeza, compilação, instalação, rebuild da IDE e verificação.');
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
  PackagesOK := False; SamplesOK := True; DocsOK := True;
  Verify := TStringList.Create; SampleResult := TStringList.Create; DocResult := TStringList.Create;
  try
    EngineLog(Self, '=== CHATGPT Installer ===');
    EngineLog(Self, 'Target ' + FEngine.TargetCPU + '-' + FEngine.TargetOS + ' / ' + IntToStr(FEngine.TargetBits) + ' bits');
    FProgress.Position := 8; if not FEngine.BackupAndRemoveOldPackages(FBackup) then Exit;
    FProgress.Position := 15; FEngine.CleanSuiteBuildCaches;
    FProgress.Position := 22; if not FEngine.CompileSelected(FOrder) then Exit;
    FProgress.Position := 58; if not FEngine.RegisterSelected(FOrder) then Exit;
    FProgress.Position := 72; if not FEngine.RebuildIDE then Exit;
    FProgress.Position := 80; PackagesOK := FEngine.VerifyInstalled(FOrder, Verify);
    if FChkSamples.Checked then
      if FEngine.ScanSamples(FSamples) then SamplesOK := FEngine.CompileSamples(FSamples, SampleResult)
      else begin SampleResult.Add('[FALTA] pacote/samples'); SamplesOK := False; end;
    FProgress.Position := 92;
    if FChkDocs.Checked then
    begin
      DocsOK := FEngine.ValidateDocumentation(DocResult);
      InstallRoot := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'installed_content';
      FEngine.CopyDocumentation(InstallRoot, DocResult);
    end;
    FFinishMemo.Clear;
    if PackagesOK and SamplesOK and DocsOK then FFinishMemo.Lines.Add('Instalação concluída com sucesso.')
    else FFinishMemo.Lines.Add('Instalação concluída com pendências.');
    FFinishMemo.Lines.Add(''); FFinishMemo.Lines.Add('Packages:'); FFinishMemo.Lines.AddStrings(Verify);
    if FChkSamples.Checked then begin FFinishMemo.Lines.Add(''); FFinishMemo.Lines.Add('Samples:'); FFinishMemo.Lines.AddStrings(SampleResult); end;
    if FChkDocs.Checked then begin FFinishMemo.Lines.Add(''); FFinishMemo.Lines.Add('Documentação:'); FFinishMemo.Lines.AddStrings(DocResult); end;
    if FBackup <> '' then begin FFinishMemo.Lines.Add(''); FFinishMemo.Lines.Add('Backup: ' + FBackup); end;
    FProgress.Position := 100;
  finally
    DocResult.Free; SampleResult.Free; Verify.Free;
    if FFinishMemo.Lines.Count = 0 then begin FFinishMemo.Lines.Add('A instalação não foi concluída.'); FFinishMemo.Lines.Add('Consulte o log.'); end;
    FInstalling := False;
    FPages.ActivePageIndex := 5;
    UpdateButtons;
  end;
end;

procedure TfrmInstaller.BackClick(Sender: TObject);
begin
  if FPages.ActivePageIndex > 0 then
    FPages.ActivePageIndex := FPages.ActivePageIndex - 1;
  UpdateButtons;
end;

procedure TfrmInstaller.NextClick(Sender: TObject);
begin
  case FPages.ActivePageIndex of
    0:
      begin
        FPages.ActivePageIndex := 1;
        if not PrepareEnvironment then Exit;
        if not CheckAndUpdateRepository then begin FPages.ActivePageIndex := 0; Exit; end;
      end;
    1: if PreparePackages then FPages.ActivePageIndex := 2;
    2: if PrepareReady then FPages.ActivePageIndex := 3;
    3: begin FPages.ActivePageIndex := 4; UpdateButtons; Application.ProcessMessages; ExecuteInstallation; end;
    5: Close;
  end;
  UpdateButtons;
end;

procedure TfrmInstaller.CancelClick(Sender: TObject);
begin
  if FInstalling then Exit;
  if MessageDlg('Cancelar a instalação?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then Close;
end;

end.
