{===============================================================================
  Kinect Capture Demo
  Demonstra captura do stream de video colorido de um sensor Kinect
  usando os componentes TAIKinectSensor e TAIKinectColorStream do
  pacote openai_input.

  Projeto: https://github.com/marcelomaurin/CHATGPT
  Licenca: conforme a licenca do repositorio principal.
===============================================================================}
unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, StdCtrls, Spin,
  aibase, aikinect_types, aikinectsensor, aikinectcolor, aikinectdepth;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    btnClose: TButton;
    btnOpen: TButton;
    chkDepth: TCheckBox;
    imgColor: TImage;
    imgDepth: TImage;
    lblDevice: TLabel;
    lblFPS: TLabel;
    lblStatus: TLabel;
    memLog: TMemo;
    pnlControl: TPanel;
    seDevice: TSpinEdit;
    tmrFPS: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    procedure tmrFPSTimer(Sender: TObject);

    procedure OnKinectConnect(Sender: TObject);
    procedure OnKinectDisconnect(Sender: TObject);
    procedure OnKinectError(Sender: TObject; const AError: string);
    procedure OnColorFrame(Sender: TObject; const AFrameFile: string);
    procedure OnDepthFrame(Sender: TObject; const AFrameFile: string; AMinMM,
      AMaxMM: Word);
  private
    FSensor: TAIKinectSensor;
    FColor: TAIKinectColorStream;
    FDepth: TAIKinectDepthStream;
    FFrameCount: Integer;
    FLoadFailCount: Integer;
    FDepthLoadFailCount: Integer;
    procedure Log(const AMsg: string);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FSensor := TAIKinectSensor.Create(Self);
  FSensor.OnConnect := @OnKinectConnect;
  FSensor.OnDisconnect := @OnKinectDisconnect;
  FSensor.OnError := @OnKinectError;

  FColor := TAIKinectColorStream.Create(Self);
  FColor.Sensor := FSensor;
  FColor.OnFrame := @OnColorFrame;

  FDepth := TAIKinectDepthStream.Create(Self);
  FDepth.Sensor := FSensor;
  FDepth.OnDepthFrame := @OnDepthFrame;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FDepth) then
    FDepth.Active := False;
  if Assigned(FColor) then
    FColor.Active := False;
  if Assigned(FSensor) then
    FSensor.Close;
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  btnOpen.Enabled := False;
  FSensor.DeviceIndex := seDevice.Value;

  if FSensor.Open then
  begin
    FColor.Active := True;
    FDepth.Active := chkDepth.Checked;
  end
  else
  begin
    lblStatus.Caption := 'Erro';
    Log('Falha ao conectar: ' + FSensor.LastError);
    btnOpen.Enabled := True;
  end;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  if Assigned(FDepth) then
    FDepth.Active := False;
  if Assigned(FColor) then
    FColor.Active := False;
  if Assigned(FSensor) then
    FSensor.Close;
end;

procedure TfrmMain.tmrFPSTimer(Sender: TObject);
begin
  lblFPS.Caption := 'FPS: ' + IntToStr(FFrameCount);
  FFrameCount := 0;
end;

procedure TfrmMain.OnKinectConnect(Sender: TObject);
begin
  lblStatus.Caption := 'Conectado';
  btnOpen.Enabled := False;
  btnClose.Enabled := True;
  seDevice.Enabled := False;
  chkDepth.Enabled := False;
end;

procedure TfrmMain.OnKinectDisconnect(Sender: TObject);
begin
  lblStatus.Caption := 'Desconectado';
  btnOpen.Enabled := True;
  btnClose.Enabled := False;
  seDevice.Enabled := True;
  chkDepth.Enabled := True;
  imgColor.Picture.Clear;
  imgDepth.Picture.Clear;
  FFrameCount := 0;
  lblFPS.Caption := 'FPS: 0';
end;

procedure TfrmMain.OnKinectError(Sender: TObject; const AError: string);
begin
  lblStatus.Caption := 'Erro';
  Log('Erro: ' + AError);
end;

procedure TfrmMain.OnColorFrame(Sender: TObject; const AFrameFile: string);
begin
  Inc(FFrameCount);
  try
    imgColor.Picture.LoadFromFile(AFrameFile);
    FLoadFailCount := 0;
  except
    on E: Exception do
    begin
      Inc(FLoadFailCount);
      if (FLoadFailCount mod 30) = 1 then
        Log('Falha ao carregar frame (' + IntToStr(FLoadFailCount) + '): ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.OnDepthFrame(Sender: TObject; const AFrameFile: string;
  AMinMM, AMaxMM: Word);
begin
  try
    imgDepth.Picture.LoadFromFile(AFrameFile);
    FDepthLoadFailCount := 0;
  except
    on E: Exception do
    begin
      Inc(FDepthLoadFailCount);
      if (FDepthLoadFailCount mod 30) = 1 then
        Log('Falha ao carregar depth (' + IntToStr(FDepthLoadFailCount) + '): ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.Log(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' ' + AMsg);
  while memLog.Lines.Count > 200 do
    memLog.Lines.Delete(0);
end;

end.
