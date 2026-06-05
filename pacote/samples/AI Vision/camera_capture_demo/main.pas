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
    
    edWidth: TEdit;
    edHeight: TEdit;
    edFPS: TEdit;
    
    ImagePreview: TImage;
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
  cbCamera.Items.Add('1');
  cbCamera.Items.Add('2');
  cbCamera.ItemIndex := 0;

  lblStatus.Caption := 'Status: Inativo';
  LogMsg('Demo inicializado. Backend: Python/OpenCV.');
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
  LogMsg('Escaneando cameras...');
  btnListCameras.Enabled := False;
  try
    LList := Camera.ListAvailableCameras;
    try
      cbCamera.Items.Clear;
      if LList.Count = 0 then
      begin
        cbCamera.Items.Add('0');
        cbCamera.ItemIndex := 0;
        LogMsg('Nenhuma camera encontrada. Usando padrao index 0.');
      end
      else
      begin
        for I := 0 to LList.Count - 1 do
        begin
          cbCamera.Items.Add(LList[I]);
        end;
        cbCamera.ItemIndex := 0;
        LogMsg('Scan concluido. ' + IntToStr(LList.Count) + ' camera(s) encontrada(s).');
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
var
  LIndexStr: string;
  LPos: Integer;
begin
  LIndexStr := cbCamera.Text;
  LPos := Pos(' ', LIndexStr);
  if LPos > 0 then
    LIndexStr := Copy(LIndexStr, 1, LPos - 1);

  LogMsg('Capturando frame unico da Camera ' + LIndexStr + '...');
  Camera.CameraIndex := StrToIntDef(LIndexStr, 0);
  Camera.Width := StrToIntDef(edWidth.Text, 640);
  Camera.Height := StrToIntDef(edHeight.Text, 480);

  if Camera.CaptureToImage(ImagePreview) then
    LogMsg('Frame capturado com sucesso.')
  else
    LogMsg('Erro ao capturar frame: ' + Camera.LastError);
end;

procedure TfrmCameraCaptureDemo.btnSaveFrameClick(Sender: TObject);
begin
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
  try
    ImagePreview.Picture.LoadFromFile(AFrameFile);
    lblStatus.Caption := 'Status: Ativo | Frame: ' + ExtractFileName(AFrameFile);
  except
    on E: Exception do
      LogMsg('Erro ao carregar frame na tela: ' + E.Message);
  end;
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
