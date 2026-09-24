unit aikinect_backend;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, aikinect_types;

type
  TAIKinectNativeBackend = class
  protected
    FDeviceIndex: Integer;
    FKinectModel: TAIKinectModel;
    FConnected: Boolean;
    FLastError: string;
    
    // Callback hooks used by subclasses to forward data to stream components
    FOnColorFrame: TAIKinectFrameEvent;
    FOnColorFrameWithInfo: TAIKinectFrameWithInfoEvent;
    FOnDepthFrame: TAIKinectDepthEvent;
    FOnDepthFrameWithInfo: TAIKinectDepthWithInfoEvent;
    FOnSkeletonFrame: TAIKinectSkeletonEvent;
    FOnSkeletonFrameWithInfo: TAIKinectSkeletonWithInfoEvent;
    FOnBeamChange: TAIKinectBeamEvent;
  public
    constructor Create(ADeviceIndex: Integer; AModel: TAIKinectModel); virtual;
    destructor Destroy; override;

    function SupportsColor: Boolean; virtual;
    function SupportsDepth: Boolean; virtual;
    function SupportsSkeleton: Boolean; virtual;
    function SupportsAudio: Boolean; virtual;
    function SupportsTilt: Boolean; virtual;
    function BackendName: string; virtual;

    function Open: Boolean; virtual; abstract;
    procedure Close; virtual; abstract;

    function SetTiltAngle(AAngle: Integer): Boolean; virtual; abstract;
    function SetLedColor(AColor: TAIKinectLed): Boolean; virtual; abstract;
    function ReadAccelerometer(out AX, AY, AZ: Double): Boolean; virtual; abstract;

    function StartColorStream: Boolean; virtual; abstract;
    procedure StopColorStream; virtual; abstract;
    function CopyLastColorFrame(ABitmap: Graphics.TBitmap): Boolean; virtual;
    function GetLastColorFrameInfo(out AInfo: TAIKinectFrameInfo): Boolean; virtual;

    function StartDepthStream: Boolean; virtual; abstract;
    procedure StopDepthStream; virtual; abstract;
    function GetDepthAt(AX, AY: Integer): Word; virtual;
    function CopyDepthMap(out AMap: array of Word): Boolean; virtual;
    function GetDepthPointCloud(out ACloud: TAIKinectPointCloud; AColored: Boolean = False; AStep: Integer = 4): Boolean; virtual;
    function GetLastDepthFrameInfo(out AInfo: TAIKinectFrameInfo): Boolean; virtual;

    procedure ConfigureSkeleton(ASeated: Boolean; ASmooth: Double); virtual;
    function StartSkeletonStream: Boolean; virtual;
    procedure StopSkeletonStream; virtual;
    function GetLastSkeletonFrameInfo(out AInfo: TAIKinectFrameInfo): Boolean; virtual;

    function StartAudioStream: Boolean; virtual;
    procedure StopAudioStream; virtual;

    property Connected: Boolean read FConnected;
    property LastError: string read FLastError;

    property OnColorFrame: TAIKinectFrameEvent read FOnColorFrame write FOnColorFrame;
    property OnColorFrameWithInfo: TAIKinectFrameWithInfoEvent read FOnColorFrameWithInfo write FOnColorFrameWithInfo;
    property OnDepthFrame: TAIKinectDepthEvent read FOnDepthFrame write FOnDepthFrame;
    property OnDepthFrameWithInfo: TAIKinectDepthWithInfoEvent read FOnDepthFrameWithInfo write FOnDepthFrameWithInfo;
    property OnSkeletonFrame: TAIKinectSkeletonEvent read FOnSkeletonFrame write FOnSkeletonFrame;
    property OnSkeletonFrameWithInfo: TAIKinectSkeletonWithInfoEvent read FOnSkeletonFrameWithInfo write FOnSkeletonFrameWithInfo;
    property OnBeamChange: TAIKinectBeamEvent read FOnBeamChange write FOnBeamChange;
  end;

implementation

constructor TAIKinectNativeBackend.Create(ADeviceIndex: Integer; AModel: TAIKinectModel);
begin
  FDeviceIndex := ADeviceIndex;
  FKinectModel := AModel;
  FConnected := False;
  FLastError := '';
end;

destructor TAIKinectNativeBackend.Destroy;
begin
  inherited Destroy;
end;

function TAIKinectNativeBackend.SupportsColor: Boolean;
begin
  Result := True;
end;

function TAIKinectNativeBackend.SupportsDepth: Boolean;
begin
  Result := True;
end;

function TAIKinectNativeBackend.SupportsSkeleton: Boolean;
begin
  Result := False;
end;

function TAIKinectNativeBackend.SupportsAudio: Boolean;
begin
  Result := False;
end;

function TAIKinectNativeBackend.SupportsTilt: Boolean;
begin
  Result := True;
end;

function TAIKinectNativeBackend.BackendName: string;
begin
  Result := 'Generic';
end;

function TAIKinectNativeBackend.CopyLastColorFrame(ABitmap: Graphics.TBitmap): Boolean;
begin
  Result := False;
end;

function TAIKinectNativeBackend.GetLastColorFrameInfo(out AInfo: TAIKinectFrameInfo): Boolean;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  Result := False;
end;

function TAIKinectNativeBackend.GetDepthAt(AX, AY: Integer): Word;
begin
  Result := 0;
end;

function TAIKinectNativeBackend.CopyDepthMap(out AMap: array of Word): Boolean;
begin
  Result := False;
end;

function TAIKinectNativeBackend.GetDepthPointCloud(out ACloud: TAIKinectPointCloud; AColored: Boolean; AStep: Integer): Boolean;
begin
  SetLength(ACloud, 0);
  Result := False;
end;

function TAIKinectNativeBackend.GetLastDepthFrameInfo(out AInfo: TAIKinectFrameInfo): Boolean;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  Result := False;
end;

function TAIKinectNativeBackend.GetLastSkeletonFrameInfo(out AInfo: TAIKinectFrameInfo): Boolean;
begin
  FillChar(AInfo, SizeOf(AInfo), 0);
  Result := False;
end;

procedure TAIKinectNativeBackend.ConfigureSkeleton(ASeated: Boolean; ASmooth: Double);
begin
end;

function TAIKinectNativeBackend.StartSkeletonStream: Boolean;
begin
  FLastError := 'Skeleton tracking not supported by this backend';
  Result := False;
end;

procedure TAIKinectNativeBackend.StopSkeletonStream;
begin
end;

function TAIKinectNativeBackend.StartAudioStream: Boolean;
begin
  FLastError := 'Audio array not supported by this backend';
  Result := False;
end;

procedure TAIKinectNativeBackend.StopAudioStream;
begin
end;

end.
