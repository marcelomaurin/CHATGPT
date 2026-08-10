unit uruntimeinstaller;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Dialogs,
  runtime_engine;

type
  TfrmRuntimeInstaller = class(TForm)
  private
    FEngine: TRuntimeInstallerEngine;
    FPages: TPageControl;
    FBack, FNext, FCancel: TButton;
    FInfoMemo, FReadyMemo, FLogMemo, FFinishMemo: TMemo;
    FDirEdit: TEdit;
    FProgress: TProgressBar;
    FInstalling: Boolean;
    procedure BuildUI;
    procedure AddWelcomePage;
    procedure AddEnvironmentPage;
    procedure AddReadyPage;
    procedure AddProgressPage;
    procedure AddFinishPage;
    procedure UpdateButtons;
    procedure BackClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure EngineLog(Sender: TObject; const AMsg: string);
    function PrepareEnvironment: Boolean;
    function PrepareReady: Boolean;
    procedure ExecuteInstall;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  frmRuntimeInstaller: TfrmRuntimeInstaller;

implementation

constructor TfrmRuntimeInstaller.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 1);
  FEngine := TRuntimeInstallerEngine.Create;
  FEngine.OnLog := @EngineLog;
  BuildUI;
end;

destructor TfrmRuntimeInstaller.Destroy;
begin
  FEngine.Free;
  inherited Destroy;
end;

procedure TfrmRuntimeInstaller.BuildUI;
var H, F: TPanel; L: TLabel;
begin
  Caption := 'CHATGPT-AI Runtime Installer';
  Width := 800;
  Height := 570;
  Position := poScreenCenter;
  BorderIcons := [biSystemMenu, biMinimize];

  H := TPanel.Create(Self); H.Parent := Self; H.Align := alTop; H.Height := 78; H.BevelOuter := bvNone;
  L := TLabel.Create(Self); L.Parent := H; L.SetBounds(22,12,720,28); L.Font.Size := 15; L.Font.Style := [fsBold]; L.Caption := 'CHATGPT-AI Runtime Installer';
  L := TLabel.Create(Self); L.Parent := H; L.SetBounds(22,44,720,22); L.Caption := 'Baixa e instala os runtimes necessários para a máquina local';

  F := TPanel.Create(Self); F.Parent := Self; F.Align := alBottom; F.Height := 56;
  FBack := TButton.Create(Self); FBack.Parent := F; FBack.SetBounds(490,13,90,30); FBack.Caption := '< Voltar'; FBack.OnClick := @BackClick;
  FNext := TButton.Create(Self); FNext.Parent := F; FNext.SetBounds(586,13,100,30); FNext.Caption := 'Avançar >'; FNext.OnClick := @NextClick;
  FCancel := TButton.Create(Self); FCancel.Parent := F; FCancel.SetBounds(692,13,90,30); FCancel.Caption := 'Cancelar'; FCancel.OnClick := @CancelClick;

  FPages := TPageControl.Create(Self); FPages.Parent := Self; FPages.Align := alClient; FPages.ShowTabs := False;
  AddWelcomePage; AddEnvironmentPage; AddReadyPage; AddProgressPage; AddFinishPage;
  FPages.ActivePageIndex := 0;
  UpdateButtons;
end;

procedure TfrmRuntimeInstaller.AddWelcomePage;
var T: TTabSheet; L: TLabel;
begin
  T := TTabSheet.Create(FPages); T.PageControl := FPages; T.Caption := 'Bem-vindo';
  L := TLabel.Create(T); L.Parent := T; L.SetBounds(34,34,700,240); L.WordWrap := True; L.Font.Size := 12;
  L.Caption := 'Este assistente prepara o runtime externo da suíte CHATGPT-AI.' + LineEnding + LineEnding +
    'Ele detecta a plataforma deste instalador, consulta o manifesto oficial, baixa o pacote correspondente do GitHub Releases, valida SHA256, extrai os arquivos e cria chatgpt_ai_runtime.ini.' + LineEnding + LineEnding +
    'O Git continua contendo apenas manifestos, scripts e documentação. Binários, Python, modelos e bibliotecas pesadas permanecem nos Releases.';
end;

procedure TfrmRuntimeInstaller.AddEnvironmentPage;
var T: TTabSheet; L: TLabel;
begin
  T := TTabSheet.Create(FPages); T.PageControl := FPages; T.Caption := 'Ambiente';
  FInfoMemo := TMemo.Create(T); FInfoMemo.Parent := T; FInfoMemo.SetBounds(24,24,735,210); FInfoMemo.ReadOnly := True; FInfoMemo.ScrollBars := ssVertical;
  L := TLabel.Create(T); L.Parent := T; L.SetBounds(24,258,280,22); L.Caption := 'Diretório de instalação do runtime:';
  FDirEdit := TEdit.Create(T); FDirEdit.Parent := T; FDirEdit.SetBounds(24,284,735,30);
  L := TLabel.Create(T); L.Parent := T; L.SetBounds(24,330,720,70); L.WordWrap := True;
  L.Caption := 'Você pode alterar o diretório. Em uma atualização, os arquivos serão extraídos novamente no mesmo local e o runtime.ini será regenerado.';
end;

procedure TfrmRuntimeInstaller.AddReadyPage;
var T: TTabSheet;
begin
  T := TTabSheet.Create(FPages); T.PageControl := FPages; T.Caption := 'Pronto';
  FReadyMemo := TMemo.Create(T); FReadyMemo.Parent := T; FReadyMemo.Align := alClient; FReadyMemo.BorderSpacing.Around := 24; FReadyMemo.ReadOnly := True; FReadyMemo.ScrollBars := ssVertical;
end;

procedure TfrmRuntimeInstaller.AddProgressPage;
var T: TTabSheet;
begin
  T := TTabSheet.Create(FPages); T.PageControl := FPages; T.Caption := 'Instalando';
  FProgress := TProgressBar.Create(T); FProgress.Parent := T; FProgress.SetBounds(24,20,735,24); FProgress.Min := 0; FProgress.Max := 100;
  FLogMemo := TMemo.Create(T); FLogMemo.Parent := T; FLogMemo.SetBounds(24,60,735,350); FLogMemo.ReadOnly := True; FLogMemo.ScrollBars := ssBoth;
end;

procedure TfrmRuntimeInstaller.AddFinishPage;
var T: TTabSheet;
begin
  T := TTabSheet.Create(FPages); T.PageControl := FPages; T.Caption := 'Concluir';
  FFinishMemo := TMemo.Create(T); FFinishMemo.Parent := T; FFinishMemo.Align := alClient; FFinishMemo.BorderSpacing.Around := 28; FFinishMemo.ReadOnly := True; FFinishMemo.ScrollBars := ssVertical;
end;

procedure TfrmRuntimeInstaller.EngineLog(Sender: TObject; const AMsg: string);
begin
  if Assigned(FLogMemo) then begin FLogMemo.Lines.Add(AMsg); FLogMemo.SelStart := Length(FLogMemo.Text); end;
  Application.ProcessMessages;
end;

procedure TfrmRuntimeInstaller.UpdateButtons;
begin
  FBack.Enabled := (FPages.ActivePageIndex > 0) and (FPages.ActivePageIndex < 3) and not FInstalling;
  FCancel.Enabled := not FInstalling;
  FNext.Enabled := not FInstalling;
  case FPages.ActivePageIndex of
    0,1: FNext.Caption := 'Avançar >';
    2: FNext.Caption := 'Instalar';
    3: begin FNext.Caption := 'Aguarde...'; FNext.Enabled := False; end;
    4: FNext.Caption := 'Concluir';
  end;
end;

function TfrmRuntimeInstaller.PrepareEnvironment: Boolean;
begin
  Screen.Cursor := crHourGlass;
  try
    FInfoMemo.Clear;
    Result := FEngine.LoadManifest;
    FInfoMemo.Lines.Add('Plataforma: ' + FEngine.PlatformID);
    if not Result then
    begin
      FInfoMemo.Lines.Add('Runtime indisponível para esta plataforma ou manifesto inacessível.');
      MessageDlg('Não foi possível preparar o runtime para ' + FEngine.PlatformID + '.', mtError, [mbOK], 0);
      Exit;
    end;
    FInfoMemo.Lines.Add('Pacote: ' + FEngine.RuntimePackage.ArchiveName);
    FInfoMemo.Lines.Add('URL: ' + FEngine.RuntimePackage.URL);
    FInfoMemo.Lines.Add('Manifesto: ' + FEngine.ManifestFile);
    FDirEdit.Text := FEngine.InstallDir;
    if FEngine.RuntimeAlreadyInstalled then FInfoMemo.Lines.Add('Situação: runtime já instalado; será atualizado.')
    else FInfoMemo.Lines.Add('Situação: nova instalação.');
  finally
    Screen.Cursor := crDefault;
  end;
end;

function TfrmRuntimeInstaller.PrepareReady: Boolean;
begin
  Result := Trim(FDirEdit.Text) <> '';
  if not Result then begin MessageDlg('Informe o diretório de instalação.', mtError, [mbOK], 0); Exit; end;
  FEngine.InstallDir := ExpandFileName(FDirEdit.Text);
  FReadyMemo.Clear;
  FReadyMemo.Lines.Add('Plataforma: ' + FEngine.PlatformID);
  FReadyMemo.Lines.Add('Arquivo: ' + FEngine.RuntimePackage.ArchiveName);
  FReadyMemo.Lines.Add('Destino: ' + FEngine.InstallDir);
  FReadyMemo.Lines.Add('');
  FReadyMemo.Lines.Add('O instalador irá:');
  FReadyMemo.Lines.Add('1. baixar o ZIP do GitHub Releases;');
  FReadyMemo.Lines.Add('2. baixar SHA256SUMS.txt;');
  FReadyMemo.Lines.Add('3. validar a integridade do ZIP;');
  FReadyMemo.Lines.Add('4. extrair o runtime;');
  FReadyMemo.Lines.Add('5. gerar chatgpt_ai_runtime.ini;');
  FReadyMemo.Lines.Add('6. validar as ferramentas encontradas.');
end;

procedure TfrmRuntimeInstaller.ExecuteInstall;
var Report: string; OK: Boolean;
begin
  FInstalling := True; UpdateButtons; FLogMemo.Clear; FProgress.Position := 10; OK := False;
  try
    FProgress.Position := 20;
    if not FEngine.DownloadAndInstall then Exit;
    FProgress.Position := 90;
    OK := FEngine.ValidateInstallation(Report);
    FFinishMemo.Clear;
    if OK then FFinishMemo.Lines.Add('Runtime instalado com sucesso.')
    else FFinishMemo.Lines.Add('Runtime instalado, mas a validação encontrou pendências.');
    FFinishMemo.Lines.Add('');
    FFinishMemo.Lines.Add('Diretório: ' + FEngine.InstallDir);
    FFinishMemo.Lines.Add('Plataforma: ' + FEngine.PlatformID);
    FFinishMemo.Lines.Add('');
    FFinishMemo.Lines.Add(Report);
    FProgress.Position := 100;
  finally
    if FFinishMemo.Lines.Count = 0 then begin FFinishMemo.Lines.Add('A instalação do runtime não foi concluída.'); FFinishMemo.Lines.Add('Consulte o log da etapa anterior.'); end;
    FInstalling := False; FPages.ActivePageIndex := 4; UpdateButtons;
  end;
end;

procedure TfrmRuntimeInstaller.BackClick(Sender: TObject);
begin
  if FPages.ActivePageIndex > 0 then FPages.ActivePageIndex := FPages.ActivePageIndex - 1;
  UpdateButtons;
end;

procedure TfrmRuntimeInstaller.NextClick(Sender: TObject);
begin
  case FPages.ActivePageIndex of
    0: begin FPages.ActivePageIndex := 1; if not PrepareEnvironment then Exit; end;
    1: if PrepareReady then FPages.ActivePageIndex := 2;
    2: begin FPages.ActivePageIndex := 3; UpdateButtons; Application.ProcessMessages; ExecuteInstall; end;
    4: Close;
  end;
  UpdateButtons;
end;

procedure TfrmRuntimeInstaller.CancelClick(Sender: TObject);
begin
  if FInstalling then begin FEngine.Cancel; Exit; end;
  if MessageDlg('Cancelar?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then Close;
end;

end.
