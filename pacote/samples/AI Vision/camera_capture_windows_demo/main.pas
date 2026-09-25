unit main;

{$mode objfpc}{$H+}{$codepage utf8}

interface

uses Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls,
  aiwindowsvideopreview;

type
  TfrmMain = class(TForm)
    pnlTop: TPanel;
    pnlPreview: TPanel;
    lblTitle: TLabel;
    lblCamera: TLabel;
    lblStatus: TLabel;
    lblResolution: TLabel;
    cmbCamera: TComboBox;
    btnRefresh: TButton;
    btnRun: TButton;
    memoLog: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnRefreshClick(Sender: TObject);
    procedure cmbCameraChange(Sender: TObject);
    procedure pnlPreviewResize(Sender: TObject);
  private
    FVideo: TAIWindowsVideoPreview;
    FDevices: TAIVideoDevices;
    procedure UpdateControls;
    procedure ShowError(const AMessage: string);
  end;

var frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FVideo := TAIWindowsVideoPreview.Create;
  btnRefreshClick(nil);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FVideo);
end;

procedure TfrmMain.UpdateControls;
begin
  cmbCamera.Enabled := not FVideo.Active;
  btnRefresh.Enabled := not FVideo.Active;
  btnRun.Enabled := FVideo.Active or (cmbCamera.ItemIndex >= 0);
  if FVideo.Active then btnRun.Caption := 'Parar vídeo'
  else btnRun.Caption := 'Iniciar vídeo';
end;

procedure TfrmMain.ShowError(const AMessage: string);
begin
  lblStatus.Caption := 'Não foi possível iniciar o vídeo. Veja o detalhe abaixo.';
  memoLog.Lines.Add(AMessage);
end;

procedure TfrmMain.btnRefreshClick(Sender: TObject);
var I, Selected: Integer; PreviousID: string;
begin
  if FVideo.Active then Exit;
  PreviousID := '';
  if (cmbCamera.ItemIndex >= 0) and (cmbCamera.ItemIndex < Length(FDevices)) then
    PreviousID := FDevices[cmbCamera.ItemIndex].ID;
  FDevices := FVideo.ListDevices;
  cmbCamera.Items.Clear;
  Selected := -1;
  for I := 0 to High(FDevices) do
  begin
    cmbCamera.Items.Add(FDevices[I].Name);
    if FDevices[I].ID = PreviousID then Selected := I;
  end;
  if (Selected < 0) and (Length(FDevices) > 0) then Selected := 0;
  cmbCamera.ItemIndex := Selected;
  cmbCameraChange(nil);
  if FVideo.LastError <> '' then ShowError(FVideo.LastError)
  else if Length(FDevices) = 0 then
    lblStatus.Caption := 'Nenhuma câmera encontrada. Conecte uma câmera e clique em Atualizar.';
  memoLog.Lines.Add(Format('%d câmera(s) encontrada(s).', [Length(FDevices)]));
  UpdateControls;
end;

procedure TfrmMain.cmbCameraChange(Sender: TObject);
begin
  if not Assigned(FVideo) or FVideo.Active then Exit;
  lblResolution.Caption := 'Resolução: será informada ao iniciar o vídeo';
  if cmbCamera.ItemIndex >= 0 then
    lblStatus.Caption := 'Pronto para transmitir: ' + cmbCamera.Text;
  UpdateControls;
end;

procedure TfrmMain.btnRunClick(Sender: TObject);
begin
  if FVideo.Active then
  begin
    FVideo.Stop;
    lblStatus.Caption := 'Vídeo parado. A câmera foi liberada.';
    lblResolution.Caption := 'Resolução: será informada ao iniciar o vídeo';
    pnlPreview.Invalidate;
    memoLog.Lines.Add('Transmissão encerrada.');
  end
  else if (cmbCamera.ItemIndex >= 0) and (cmbCamera.ItemIndex < Length(FDevices)) then
  begin
    lblStatus.Caption := 'Abrindo ' + cmbCamera.Text + '...';
    if FVideo.Start(FDevices[cmbCamera.ItemIndex].ID, pnlPreview.Handle,
      pnlPreview.ClientWidth, pnlPreview.ClientHeight) then
    begin
      lblStatus.Caption := 'Vídeo ao vivo: ' + FVideo.DeviceName;
      if (FVideo.VideoWidth > 0) and (FVideo.VideoHeight > 0) then
        lblResolution.Caption := Format('Resolução do vídeo: %d × %d pixels',
          [FVideo.VideoWidth, FVideo.VideoHeight])
      else lblResolution.Caption := 'Resolução não informada pela câmera';
      memoLog.Lines.Add(lblStatus.Caption + ' — ' + lblResolution.Caption);
    end
    else ShowError(FVideo.LastError);
  end;
  UpdateControls;
end;

procedure TfrmMain.pnlPreviewResize(Sender: TObject);
begin
  if Assigned(FVideo) then
    FVideo.Resize(pnlPreview.ClientWidth, pnlPreview.ClientHeight);
end;

end.
