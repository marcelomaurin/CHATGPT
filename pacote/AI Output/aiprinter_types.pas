unit aiprinter_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TPrinterLanguage = (
    plEscPos,
    plZpl,
    plTspl,
    plEpl
  );

  TAIPosProtocol = (
    ppEscPos,
    ppEscBema,
    ppEscDaruma,
    ppStarLine,
    ppZPL,
    ppEPL,
    ppTexto,
    ppNativo
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
    ptFile
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

implementation

end.
