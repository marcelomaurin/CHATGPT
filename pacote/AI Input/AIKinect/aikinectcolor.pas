unit aikinectcolor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, aibase, aikinect_types, aikinectsensor, LResources, FileUtil;

type
  TAIKinectColorStream = class(TAIBaseComponent)
  private
    FSensor          : TAIKinectSensor;
    FActive          : Boolean;
    FVideoFormat     : TAIKinectVideoFormat;
    FCaptureInterval : Integer;
    FTempFolder      : string;
    FAutoDeleteTemp  : Boolean;
    FLastFrameFile   : string;
    FOnFrame         : TAIKinectFrameEvent;
    FOnStateChange   : TAIKinectStateEvent;
    
    procedure SetActive(AValue: Boolean);
    procedure DoOnColorFrame(Sender: TObject; const AFrameFile: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function  StartStream: Boolean;
    procedure StopStream;
    function  CaptureFrame(ABitmap: Graphics.TBitmap): Boolean;
    function  CaptureToFile(const AFileName: string): Boolean;
  published
    property Sensor          : TAIKinectSensor      read FSensor write FSensor;
    property Active          : Boolean              read FActive write SetActive default False;
    property VideoFormat     : TAIKinectVideoFormat read FVideoFormat write FVideoFormat default kvRGB;
    property CaptureInterval : Integer              read FCaptureInterval write FCaptureInterval default 100;
    property TempFolder      : string               read FTempFolder write FTempFolder;
    property AutoDeleteTempFiles: Boolean           read FAutoDeleteTemp write FAutoDeleteTemp default True;
    property LastFrameFile   : string               read FLastFrameFile;
    property OnFrame         : TAIKinectFrameEvent  read FOnFrame write FOnFrame;
    property OnStateChange   : TAIKinectStateEvent  read FOnStateChange write FOnStateChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIKinectColorStream]);
end;

{ TAIKinectColorStream }

constructor TAIKinectColorStream.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Provides access to the RGB color/IR stream of a Kinect sensor. ' +
    'Sends frame file paths in OnFrame event for downstream AI Vision processing.';
  FSensor := nil;
  FActive := False;
  FVideoFormat := kvRGB;
  FCaptureInterval := 100;
  FTempFolder := GetTempDir;
  FAutoDeleteTemp := True;
  FLastFrameFile := '';
end;

destructor TAIKinectColorStream.Destroy;
begin
  StopStream;
  inherited Destroy;
end;

procedure TAIKinectColorStream.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FSensor) then
  begin
    StopStream;
    FSensor := nil;
  end;
end;

function TAIKinectColorStream.StartStream: Boolean;
begin
  Result := False;
  if FActive then Exit(True);
  if not Assigned(FSensor) or not FSensor.IsConnected then
  begin
    SetError('Sensor is not connected');
    Exit(False);
  end;
  
  try
    FSensor.BackendObject.OnColorFrame := @DoOnColorFrame;
    if FSensor.BackendObject.StartColorStream then
    begin
      FActive := True;
      if Assigned(FOnStateChange) then
        FOnStateChange(Self, True);
      Result := True;
    end
    else
    begin
      SetError(FSensor.BackendObject.LastError);
    end;
  except
    on E: Exception do
    begin
      SetError('Exception in TAIKinectColorStream.StartStream: ' + E.ClassName + ': ' + E.Message);
    end;
  end;
end;

procedure TAIKinectColorStream.StopStream;
begin
  if not FActive then Exit;
  FActive := False;
  if Assigned(FSensor) and FSensor.IsConnected then
  begin
    FSensor.BackendObject.StopColorStream;
    FSensor.BackendObject.OnColorFrame := nil;
  end;
  if Assigned(FOnStateChange) then
    FOnStateChange(Self, False);
end;

procedure TAIKinectColorStream.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    StartStream
  else
    StopStream;
end;

procedure TAIKinectColorStream.DoOnColorFrame(Sender: TObject; const AFrameFile: string);
var
  DestFile: string;
begin
  if not FActive then Exit;
  
  if FTempFolder <> '' then
    DestFile := IncludeTrailingPathDelimiter(FTempFolder) + 'kinect_color_frame.bmp'
  else
    DestFile := AFrameFile;
    
  if DestFile <> AFrameFile then
  begin
    try
      if FileExists(DestFile) and FAutoDeleteTemp then
        DeleteFile(DestFile);
      CopyFile(AFrameFile, DestFile);
    except
      // ignore copy errors
    end;
  end;
  
  FLastFrameFile := DestFile;
  if Assigned(FOnFrame) then
    FOnFrame(Self, FLastFrameFile);
end;

function TAIKinectColorStream.CaptureFrame(ABitmap: Graphics.TBitmap): Boolean;
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

function TAIKinectColorStream.CaptureToFile(const AFileName: string): Boolean;
begin
  Result := False;
  if FActive and (FLastFrameFile <> '') and FileExists(FLastFrameFile) then
  begin
    try
      if FileExists(AFileName) then DeleteFile(AFileName);
      Result := CopyFile(FLastFrameFile, AFileName);
    except
      Result := False;
    end;
  end;
end;

initialization
  {$I aikinect_icon.lrs}

end.
