unit aiserialfingerprint;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAISerialFingerprint = class(TPersistent)
  private
    FDeviceName: string;
    FVID: string;
    FPID: string;
    FManufacturer: string;
    FProduct: string;
    FSerialNumber: string;
    FProtocol: string;
    FBoardFamily: string;
    FConfidence: Integer;
  public
    procedure Clear;
    function AsText: string;
  published
    property DeviceName: string read FDeviceName write FDeviceName;
    property VID: string read FVID write FVID;
    property PID: string read FPID write FPID;
    property Manufacturer: string read FManufacturer write FManufacturer;
    property Product: string read FProduct write FProduct;
    property SerialNumber: string read FSerialNumber write FSerialNumber;
    property Protocol: string read FProtocol write FProtocol;
    property BoardFamily: string read FBoardFamily write FBoardFamily;
    property Confidence: Integer read FConfidence write FConfidence;
  end;

implementation

procedure TAISerialFingerprint.Clear;
begin
  FDeviceName := '';
  FVID := '';
  FPID := '';
  FManufacturer := '';
  FProduct := '';
  FSerialNumber := '';
  FProtocol := '';
  FBoardFamily := '';
  FConfidence := 0;
end;

function TAISerialFingerprint.AsText: string;
begin
  Result :=
    'Device=' + FDeviceName + LineEnding +
    'VID=' + FVID + LineEnding +
    'PID=' + FPID + LineEnding +
    'Manufacturer=' + FManufacturer + LineEnding +
    'Product=' + FProduct + LineEnding +
    'Serial=' + FSerialNumber + LineEnding +
    'Protocol=' + FProtocol + LineEnding +
    'BoardFamily=' + FBoardFamily + LineEnding +
    'Confidence=' + IntToStr(FConfidence);
end;

end.
