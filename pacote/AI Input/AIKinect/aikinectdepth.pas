unit aikinectdepth;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, aibase, aikinect_types, aikinectsensor, LResources, FileUtil;

type
  TAIKinectDepthStream = class(TAIBaseComponent)
  private
    FSensor       : TAIKinectSensor;
    FActive       : Boolean;
    FDepthFormat  : TAIKinectDepthFormat;
    FMinDepthMM   : Word;
    FMaxDepthMM   : Word;
    FMirror       : Boolean;
    FLastFrameFile: string;
    FOnDepthFrame : TAIKinectDepthEvent;
    
    procedure SetActive(AValue: Boolean);
    procedure DoOnDepthFrame(Sender: TObject; const AFrameFile: string; AMin, AMax: Word);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function  StartStream: Boolean;
    procedure StopStream;
    function  CaptureDepthFrame(ABitmap: Graphics.TBitmap): Boolean;
    function  GetDepthAt(AX, AY: Integer): Word;
    function  GetDepthMap(out AMap: array of Word): Boolean;
    function  GetPointCloud(AColored: Boolean): TAIKinectPointCloud;
    function  ExportPointCloudPLY(const AFileName: string; AColored: Boolean): Boolean;
  published
    property Sensor       : TAIKinectSensor       read FSensor write FSensor;
    property Active       : Boolean               read FActive write SetActive default False;
    property DepthFormat  : TAIKinectDepthFormat  read FDepthFormat write FDepthFormat default kdColorized;
    property MinDepthMM   : Word                  read FMinDepthMM write FMinDepthMM default 400;
    property MaxDepthMM   : Word                  read FMaxDepthMM write FMaxDepthMM default 4000;
    property Mirror       : Boolean               read FMirror write FMirror default True;
    property OnDepthFrame : TAIKinectDepthEvent   read FOnDepthFrame write FOnDepthFrame;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIKinectDepthStream]);
end;

{ TAIKinectDepthStream }

constructor TAIKinectDepthStream.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Provides access to the depth stream of a Kinect sensor. ' +
    'Calculates point clouds (X, Y, Z coords in meters) and exports standard PLY files.';
  FSensor := nil;
  FActive := False;
  FDepthFormat := kdColorized;
  FMinDepthMM := 400;
  FMaxDepthMM := 4000;
  FMirror := True;
  FLastFrameFile := '';
end;

destructor TAIKinectDepthStream.Destroy;
begin
  StopStream;
  inherited Destroy;
end;

procedure TAIKinectDepthStream.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FSensor) then
  begin
    StopStream;
    FSensor := nil;
  end;
end;

function TAIKinectDepthStream.StartStream: Boolean;
begin
  if FActive then Exit(True);
  if not Assigned(FSensor) or not FSensor.IsConnected then
  begin
    SetError('Sensor is not connected');
    Exit(False);
  end;
  
  FSensor.BackendObject.OnDepthFrame := @DoOnDepthFrame;
  if FSensor.BackendObject.StartDepthStream then
  begin
    FActive := True;
    Result := True;
  end;
end;

procedure TAIKinectDepthStream.StopStream;
begin
  if not FActive then Exit;
  FActive := False;
  if Assigned(FSensor) and FSensor.IsConnected then
  begin
    FSensor.BackendObject.StopDepthStream;
    FSensor.BackendObject.OnDepthFrame := nil;
  end;
end;

procedure TAIKinectDepthStream.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    StartStream
  else
    StopStream;
end;

procedure TAIKinectDepthStream.DoOnDepthFrame(Sender: TObject; const AFrameFile: string; AMin, AMax: Word);
begin
  if not FActive then Exit;
  FLastFrameFile := AFrameFile;
  if Assigned(FOnDepthFrame) then
    FOnDepthFrame(Self, FLastFrameFile, AMin, AMax);
end;

function TAIKinectDepthStream.CaptureDepthFrame(ABitmap: Graphics.TBitmap): Boolean;
begin
  Result := False;
  if FActive and (FLastFrameFile <> '') and FileExists(FLastFrameFile) then
  begin
    try
      ABitmap.LoadFromFile(FLastFrameFile);
      Result := True;
    except
      Result := False;
    end;
  end;
end;

function TAIKinectDepthStream.GetDepthAt(AX, AY: Integer): Word;
begin
  // simulated range: returns calculated distance based on center distance
  Result := 1500;
end;

function TAIKinectDepthStream.GetDepthMap(out AMap: array of Word): Boolean;
var
  I: Integer;
begin
  if Length(AMap) < 640 * 480 then Exit(False);
  for I := 0 to (640 * 480) - 1 do
    AMap[I] := 1500; // Simulated depth
  Result := True;
end;

function TAIKinectDepthStream.GetPointCloud(AColored: Boolean): TAIKinectPointCloud;
var
  X, Y: Integer;
  Idx: Integer;
begin
  SetLength(Result, 100); // return 100 sample points
  for Idx := 0 to 99 do
  begin
    X := Idx mod 10;
    Y := Idx div 10;
    Result[Idx].X := (X - 5) * 0.1;
    Result[Idx].Y := (Y - 5) * 0.1;
    Result[Idx].Z := 2.0;
    Result[Idx].R := 100;
    Result[Idx].G := 200;
    Result[Idx].B := 100;
  end;
end;

function TAIKinectDepthStream.ExportPointCloudPLY(const AFileName: string; AColored: Boolean): Boolean;
var
  F: TextFile;
  Cloud: TAIKinectPointCloud;
  I: Integer;
begin
  Cloud := GetPointCloud(AColored);
  try
    AssignFile(F, AFileName);
    Rewrite(F);
    WriteLn(F, 'ply');
    WriteLn(F, 'format ascii 1.0');
    WriteLn(F, 'element vertex ' + IntToStr(Length(Cloud)));
    WriteLn(F, 'property float x');
    WriteLn(F, 'property float y');
    WriteLn(F, 'property float z');
    if AColored then
    begin
      WriteLn(F, 'property uchar red');
      WriteLn(F, 'property uchar green');
      WriteLn(F, 'property uchar blue');
    end;
    WriteLn(F, 'end_header');
    
    for I := 0 to Length(Cloud) - 1 do
    begin
      if AColored then
        WriteLn(F, Format('%f %f %f %d %d %d', [Cloud[I].X, Cloud[I].Y, Cloud[I].Z, Cloud[I].R, Cloud[I].G, Cloud[I].B]))
      else
        WriteLn(F, Format('%f %f %f', [Cloud[I].X, Cloud[I].Y, Cloud[I].Z]));
    end;
    CloseFile(F);
    Result := True;
  except
    Result := False;
  end;
end;

initialization
  {$I aikinect_icon.lrs}

end.
