unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aicameracapture, aibase;

type

  { TfrmCameraCaptureDemo }

  TfrmCameraCaptureDemo = class(TForm)
    pnlLeft: TPanel;
    pnlClient: TPanel;
    pnlLog: TPanel;
    pnlPreviews: TPanel;
    
    PanelPreview: TPanel;
    ImageCaptured: TImage;
    
    cbCamera: TComboBox;
    btnListCameras: TButton;
    btnStart: TButton;
    btnStop: TButton;
    btnCaptureFrame: TButton;
    btnSaveFrame: TButton;
    
    lblCamera: TLabel;
    lblWidth: TLabel;
    lblHeight: TLabel;
    lblFPS: TLabel;
    lblStatus: TLabel;
    lblPreviewTitle: TLabel;
    lblCapturedTitle: TLabel;
    
    edWidth: TEdit;
    edHeight: TEdit;
    edFPS: TEdit;
    
    memLog: TMemo;
    SaveDialog1: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnListCamerasClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnCaptureFrameClick(Sender: TObject);
    procedure btnSaveFrameClick(Sender: TObject);
    
    procedure OnCameraFrame(Sender: TObject; const AFrameFile: string);
    procedure OnCameraError(Sender: TObject; const AError: string);
    procedure OnCameraStateChange(Sender: TObject; AActive: Boolean);
    procedure OnCameraLog(Sender: TObject; Level: TAILogLevel; const Message: string);
  private
    Camera: TAICameraCapture;
    procedure LogMsg(const AMsg: string);
  public

  end;

var
  frmCameraCaptureDemo: TfrmCameraCaptureDemo;

implementation

{$R *.lfm}

{ TfrmCameraCaptureDemo }

procedure TfrmCameraCaptureDemo.FormCreate(Sender: TObject);
begin
  Camera := TAICameraCapture.Create(Self);
  Camera.OnFrame := @OnCameraFrame;
  Camera.OnError := @OnCameraError;
  Camera.OnStateChange := @OnCameraStateChange;
  Camera.OnLog := @OnCameraLog;

  edWidth.Text := IntToStr(Camera.Width);
  edHeight.Text := IntToStr(Camera.Height);
  edFPS.Text := IntToStr(Camera.FPS);
  
  cbCamera.Items.Clear;
  cbCamera.Items.Add('0');
  cbCamera.ItemIndex := 0;

  lblStatus.Caption := 'Status: Inativo';
  LogMsg('Demo inicializado. Backend: Nativo Windows VFW.');
end;

procedure TfrmCameraCaptureDemo.FormDestroy(Sender: TObject);
begin
  Camera.StopCapture;
end;

procedure TfrmCameraCaptureDemo.btnListCamerasClick(Sender: TObject);
var
  LList: TStringList;
  I: Integer;
begin
  LogMsg('Escaneando cameras (VFW)...');
  btnListCameras.Enabled := False;
  try
    LList := Camera.ListAvailableCameras;
    try
      cbCamera.Items.Clear;
      if LList.Count = 0 then
      begin
        cbCamera.Items.Add('0 - Nenhuma encontrada');
        cbCamera.ItemIndex := 0;
        LogMsg('Nenhuma camera encontrada via VFW.');
      end
      else
      begin
        for I := 0 to LList.Count - 1 do
        begin
          cbCamera.Items.Add(LList[I]);
        end;
        cbCamera.ItemIndex := 0;
        LogMsg(Format('Scan concluido. %d camera(s) encontrada(s).', [LList.Count]));
      end;
    finally
      LList.Free;
    end;
  except
    on E: Exception do
      LogMsg('Erro ao escanear cameras: ' + E.Message);
  end;
  btnListCameras.Enabled := True;
end;

procedure TfrmCameraCaptureDemo.btnStartClick(Sender: TObject);
var
  LIndexStr: string;
  LPos: Integer;
begin
  LIndexStr := cbCamera.Text;
  LPos := Pos(' ', LIndexStr);
  if LPos > 0 then
    LIndexStr := Copy(LIndexStr, 1, LPos - 1);
    
  Camera.CameraIndex := StrToIntDef(LIndexStr, 0);
  Camera.Width := StrToIntDef(edWidth.Text, 640);
  Camera.Height := StrToIntDef(edHeight.Text, 480);
  Camera.FPS := StrToIntDef(edFPS.Text, 30);
  if Camera.FPS > 0 then
    Camera.CaptureInterval := 1000 div Camera.FPS
  else
    Camera.CaptureInterval := 100;

  Camera.PreviewHandle := PanelPreview.Handle;
  Camera.PreviewEnabled := True;

  LogMsg(Format('Iniciando captura da Camera %d (%dx%d, %d FPS)...', [Camera.CameraIndex, Camera.Width, Camera.Height, Camera.FPS]));
  
  btnStart.Enabled := False;
  if Camera.StartCapture then
  begin
    LogMsg('Captura iniciada com sucesso.');
  end
  else
  begin
    LogMsg('Falha ao iniciar captura: ' + Camera.LastError);
    btnStart.Enabled := True;
  end;
end;

procedure TfrmCameraCaptureDemo.btnStopClick(Sender: TObject);
begin
  LogMsg('Parando captura...');
  Camera.StopCapture;
  LogMsg('Captura parada.');
end;

procedure TfrmCameraCaptureDemo.btnCaptureFrameClick(Sender: TObject);
begin
  if not Camera.Active then
  begin
    LogMsg('Erro: A camera deve estar ativa para capturar um frame.');
    Exit;
  end;
  LogMsg('Capturando frame unico para visualizacao...');
  if Camera.CaptureToImage(ImageCaptured) then
    LogMsg('Frame capturado e carregado com sucesso.')
  else
    LogMsg('Erro ao capturar frame: ' + Camera.LastError);
end;

procedure TfrmCameraCaptureDemo.btnSaveFrameClick(Sender: TObject);
begin
  if not Camera.Active then
  begin
    LogMsg('Erro: A camera deve estar ativa para salvar um frame.');
    Exit;
  end;
  if SaveDialog1.Execute then
  begin
    LogMsg('Salvando frame em: ' + SaveDialog1.FileName);
    if Camera.CaptureToFile(SaveDialog1.FileName) then
      LogMsg('Frame salvo com sucesso.')
    else
      LogMsg('Erro ao salvar frame: ' + Camera.LastError);
  end;
end;

procedure TfrmCameraCaptureDemo.OnCameraFrame(Sender: TObject; const AFrameFile: string);
begin
  // O preview visual já é renderizado nativamente no PanelPreview pelo Windows.
  // O evento OnFrame nos notifica sobre a geracao de arquivo temporario, que registramos no log.
  lblStatus.Caption := 'Status: Ativo | Frame salvo: ' + ExtractFileName(AFrameFile);
end;

procedure TfrmCameraCaptureDemo.OnCameraError(Sender: TObject; const AError: string);
begin
  LogMsg('ERROR: ' + AError);
end;

procedure TfrmCameraCaptureDemo.OnCameraStateChange(Sender: TObject; AActive: Boolean);
begin
  if AActive then
  begin
    lblStatus.Caption := 'Status: Ativo';
    btnStart.Enabled := False;
    btnStop.Enabled := True;
  end
  else
  begin
    lblStatus.Caption := 'Status: Inativo';
    btnStart.Enabled := True;
    btnStop.Enabled := False;
  end;
end;

procedure TfrmCameraCaptureDemo.OnCameraLog(Sender: TObject; Level: TAILogLevel; const Message: string);
var
  LPrefix: string;
begin
  case Level of
    llDebug: LPrefix := '[DEBUG] ';
    llInfo: LPrefix := '[INFO] ';
    llWarning: LPrefix := '[WARNING] ';
    llError: LPrefix := '[ERROR] ';
  end;
  LogMsg(LPrefix + Message);
end;

procedure TfrmCameraCaptureDemo.LogMsg(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
