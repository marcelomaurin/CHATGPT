unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aibase, aikinect_types, aikinectsensor, aikinectcolor;

type
  { TfrmMain }

  TfrmMain = class(TForm)
    btnClose: TButton;
    btnOpen: TButton;
    imgColor: TImage;
    pnlControl: TPanel;
    
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
    
    // Event handlers
    procedure OnKinectConnect(Sender: TObject);
    procedure OnKinectDisconnect(Sender: TObject);
    procedure OnKinectError(Sender: TObject; const AError: string);
    procedure OnColorFrame(Sender: TObject; const AFrameFile: string);
  private
    FSensor: TAIKinectSensor;
    FColor: TAIKinectColorStream;
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
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FColor) then
    FColor.Active := False;
  if Assigned(FSensor) then
    FSensor.Close;
end;

procedure TfrmMain.btnOpenClick(Sender: TObject);
begin
  if not Assigned(FSensor) then
  begin
    FSensor := TAIKinectSensor.Create(Self);
    FSensor.OnConnect := @OnKinectConnect;
    FSensor.OnDisconnect := @OnKinectDisconnect;
    FSensor.OnError := @OnKinectError;
  end;
  
  if not Assigned(FColor) then
  begin
    FColor := TAIKinectColorStream.Create(Self);
    FColor.Sensor := FSensor;
    FColor.OnFrame := @OnColorFrame;
  end;

  FSensor.DeviceIndex := 0;
  if FSensor.Open then
  begin
    if Assigned(FColor) then
      FColor.Active := True;
    btnOpen.Enabled := False;
    btnClose.Enabled := True;
  end
  else
  begin
    ShowMessage('Falha ao conectar: ' + FSensor.LastError);
  end;
end;

procedure TfrmMain.btnCloseClick(Sender: TObject);
begin
  if Assigned(FColor) then
    FColor.Active := False;
  if Assigned(FSensor) then
    FSensor.Close;
  imgColor.Picture.Clear;
  btnOpen.Enabled := True;
  btnClose.Enabled := False;
end;

procedure TfrmMain.OnKinectConnect(Sender: TObject);
begin
  // Handled on btnOpenClick
end;

procedure TfrmMain.OnKinectDisconnect(Sender: TObject);
begin
  btnOpen.Enabled := True;
  btnClose.Enabled := False;
  imgColor.Picture.Clear;
end;

procedure TfrmMain.OnKinectError(Sender: TObject; const AError: string);
begin
  ShowMessage('Erro no Kinect: ' + AError);
end;

procedure TfrmMain.OnColorFrame(Sender: TObject; const AFrameFile: string);
begin
  try
    imgColor.Picture.LoadFromFile(AFrameFile);
  except
    // ignore temporary file lock issues
  end;
end;

end.
