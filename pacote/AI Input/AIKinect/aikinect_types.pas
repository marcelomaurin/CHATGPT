unit aikinect_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type
  { Modelo do hardware }
  TAIKinectModel = (kmAuto, kmXbox360, kmKinectOne, kmAzureKinect);

  { Backend nativo }
  TAIKinectBackendKind = (kbAuto, kbLibFreenect, kbKinectSDK10);

  { LED do Kinect v1 }
  TAIKinectLed = (klOff, klGreen, klRed, klYellow, klBlinkGreen, klBlinkRedYellow);

  { Formatos de saída }
  TAIKinectVideoFormat = (kvRGB, kvIR8Bit);
  TAIKinectDepthFormat = (kdRawMM,      // Word por pixel, milímetros
                          kdGray8,      // bitmap tons de cinza normalizado
                          kdColorized,  // bitmap falsa-cor (near=vermelho, far=azul)
                          kdRegistered);// profundidade alinhada ao RGB

  { Esqueleto — 20 juntas do NUI (SDK 1.8) }
  TAIKinectJointType = (
    kjHipCenter, kjSpine, kjShoulderCenter, kjHead,
    kjShoulderLeft, kjElbowLeft, kjWristLeft, kjHandLeft,
    kjShoulderRight, kjElbowRight, kjWristRight, kjHandRight,
    kjHipLeft, kjKneeLeft, kjAnkleLeft, kjFootLeft,
    kjHipRight, kjKneeRight, kjAnkleRight, kjFootRight);

  TAIKinectTrackState = (ktNotTracked, ktInferred, ktTracked);

  TAIKinectJoint = record
    JointType : TAIKinectJointType;
    X, Y, Z   : Single;              // metros, espaço do sensor
    ScreenX,
    ScreenY   : Integer;             // projeção no frame RGB 640x480
    State     : TAIKinectTrackState;
  end;

  TAIKinectBody = record
    TrackingId : Integer;
    Tracked    : Boolean;
    Joints     : array[TAIKinectJointType] of TAIKinectJoint;
  end;
  TAIKinectBodies = array of TAIKinectBody;

  TAIKinectPoint3D = record
    X, Y, Z : Single;                // metros
    R, G, B : Byte;                  // cor opcional (frame registrado)
  end;
  TAIKinectPointCloud = array of TAIKinectPoint3D;

  { Metadados de correlação temporal e frame }
  TAIKinectFrameSource = (kfsColor, kfsDepth, kfsSkeleton);

  TAIKinectFrameInfo = record
    FrameNumber         : DWord;
    TimestampMS         : Int64;
    TrackingTimestampMS : Int64;
    Width               : Integer;
    Height              : Integer;
    Source              : TAIKinectFrameSource;
  end;

  { Eventos }
  TAIKinectFrameEvent    = procedure(Sender: TObject; const AFrameFile: string) of object;
  TAIKinectFrameWithInfoEvent = procedure(Sender: TObject; const AFrameFile: string;
                             const AInfo: TAIKinectFrameInfo) of object;
  TAIKinectDepthEvent    = procedure(Sender: TObject; const AFrameFile: string;
                             AMinMM, AMaxMM: Word) of object;
  TAIKinectDepthWithInfoEvent = procedure(Sender: TObject; const AFrameFile: string;
                             AMinMM, AMaxMM: Word; const AInfo: TAIKinectFrameInfo) of object;
  TAIKinectSkeletonEvent = procedure(Sender: TObject; const ABodies: TAIKinectBodies) of object;
  TAIKinectSkeletonWithInfoEvent = procedure(Sender: TObject; const ABodies: TAIKinectBodies;
                             const AInfo: TAIKinectFrameInfo) of object;
  TAIKinectBeamEvent     = procedure(Sender: TObject; ABeamAngleDeg: Double;
                             AConfidence: Double) of object;
  TAIKinectErrorEvent    = procedure(Sender: TObject; const AError: string) of object;
  TAIKinectStateEvent    = procedure(Sender: TObject; AActive: Boolean) of object;

function AINewKinectFrameInfo(ASource: TAIKinectFrameSource; AFrameNum: DWord;
  ATimestampMS: Int64; AWidth: Integer = 640; AHeight: Integer = 480): TAIKinectFrameInfo;

implementation

function AINewKinectFrameInfo(ASource: TAIKinectFrameSource; AFrameNum: DWord;
  ATimestampMS: Int64; AWidth: Integer = 640; AHeight: Integer = 480): TAIKinectFrameInfo;
begin
  Result.Source := ASource;
  Result.FrameNumber := AFrameNum;
  Result.TimestampMS := ATimestampMS;
  Result.TrackingTimestampMS := ATimestampMS;
  Result.Width := AWidth;
  Result.Height := AHeight;
end;

end.
