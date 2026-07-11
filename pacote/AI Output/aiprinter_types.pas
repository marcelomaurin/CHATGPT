unit aiprinter_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TAIPrinterGeometry = record
    WidthMM: Double;
    HeightMM: Double;
    GapMM: Double;
    MarginLeftMM: Double;
    MarginTopMM: Double;
    MarginRightMM: Double;
    MarginBottomMM: Double;
    Dpi: Integer;
  end;

  TPrinterLanguage = (
    plEscPos,
    plZpl,
    plTspl,
    plEpl
  );

  TAIPosModel = (
    pmGenerico,
    pmElginI9,
    pmElginI7,
    pmElginL42DT,
    pmQR203,
    pmBematech4200,
    pmBematechMP20,
    pmDarumaDR800,
    pmDarumaDR700,
    pmSweda,
    pmTanca,
    pmControlID,
    pmStarTSP100,
    pmZebraZPL,
    pmEltronEPL
  );

  TPrinterRenderMode = (
    rmRawCommand,
    rmNativeCanvas
  );

  TPrinterTransportKind = (
    ptSerial,
    ptTcp9100,
    ptFile,
    ptPrinterRaw
  );

  TPrinterEncoding = (
    peRawAscii,
    peCP437,
    peCP850,
    peWindows1252,
    peUTF8
  );

  TBarcodeSymbology = (
    bsCode39,
    bsCode128,
    bsEan13,
    bsEan8,
    bsItf,
    bsCodabar
  );

  TTextAlign = (
    taLeft,
    taCenter,
    taRight
  );

function MMToDots(const AMillimeters: Double; ADpi: Integer): Integer;
function DefaultGeometry: TAIPrinterGeometry;
function UsableWidthMM(const AG: TAIPrinterGeometry): Double;
function UsableHeightMM(const AG: TAIPrinterGeometry): Double;

implementation

function MMToDots(const AMillimeters: Double; ADpi: Integer): Integer;
begin
  Result := Round(AMillimeters * ADpi / 25.4);
end;

function DefaultGeometry: TAIPrinterGeometry;
begin
  Result.WidthMM := 51;
  Result.HeightMM := 25;
  Result.GapMM := 2;
  Result.MarginLeftMM := 0;
  Result.MarginTopMM := 0;
  Result.MarginRightMM := 0;
  Result.MarginBottomMM := 0;
  Result.Dpi := 203;
end;

function UsableWidthMM(const AG: TAIPrinterGeometry): Double;
begin
  Result := AG.WidthMM - AG.MarginLeftMM - AG.MarginRightMM;
end;

function UsableHeightMM(const AG: TAIPrinterGeometry): Double;
begin
  Result := AG.HeightMM - AG.MarginTopMM - AG.MarginBottomMM;
end;

end.
