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
    FOnDepthFrame: TAIKinectDepthEvent;
    FOnSkeletonFrame: TAIKinectSkeletonEvent;
    FOnBeamChange: TAIKinectBeamEvent;
  public
    constructor Create(ADeviceIndex: Integer; AModel: TAIKinectModel); virtual;
    destructor Destroy; override;

    function Open: Boolean; virtual; abstract;
    procedure Close; virtual; abstract;

    function SetTiltAngle(AAngle: Integer): Boolean; virtual; abstract;
    function SetLedColor(AColor: TAIKinectLed): Boolean; virtual; abstract;
    function ReadAccelerometer(out AX, AY, AZ: Double): Boolean; virtual; abstract;

    function StartColorStream: Boolean; virtual; abstract;
    procedure StopColorStream; virtual; abstract;

    function StartDepthStream: Boolean; virtual; abstract;
    procedure StopDepthStream; virtual; abstract;

    procedure ConfigureSkeleton(ASeated: Boolean; ASmooth: Double); virtual;
    function StartSkeletonStream: Boolean; virtual;
    procedure StopSkeletonStream; virtual;

    function StartAudioStream: Boolean; virtual;
    procedure StopAudioStream; virtual;

    property Connected: Boolean read FConnected;
    property LastError: string read FLastError;

    property OnColorFrame: TAIKinectFrameEvent read FOnColorFrame write FOnColorFrame;
    property OnDepthFrame: TAIKinectDepthEvent read FOnDepthFrame write FOnDepthFrame;
    property OnSkeletonFrame: TAIKinectSkeletonEvent read FOnSkeletonFrame write FOnSkeletonFrame;
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
