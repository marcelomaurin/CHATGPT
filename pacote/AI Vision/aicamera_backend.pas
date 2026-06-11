unit aicamera_backend;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics;

type
  TAICameraBackend = (
    cbAuto,
    cbWindowsVFW,
    cbLinuxV4L2,
    cbNativeStub
  );

  { TAICameraNativeBackend }

  TAICameraNativeBackend = class
  public
    LastError: string;
    function OpenCamera(const ADevice: string; AIndex, AWidth, AHeight, AFPS: Integer; APreviewHandle: THandle; APreviewEnabled: Boolean): Boolean; virtual; abstract;
    procedure CloseCamera; virtual; abstract;
    function CaptureToFile(const AFileName: string): Boolean; virtual; abstract;
    function CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean; virtual;
    function ListCameras(AMaxScan: Integer): TStringList; virtual; abstract;
  end;

implementation

function TAICameraNativeBackend.CaptureToBitmap(out ABmp: Graphics.TBitmap): Boolean;
begin
  Result := False;
  ABmp := nil;
  LastError := 'CaptureToBitmap not implemented on this backend.';
end;

end.
