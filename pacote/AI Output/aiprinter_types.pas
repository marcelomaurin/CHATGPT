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
