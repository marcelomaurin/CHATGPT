unit aiprinter_language_base;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprinter_types;

type
  { TAIPrinterLanguageBase }

  TAIPrinterLanguageBase = class
  protected
    FEncoding: TPrinterEncoding;
  public
    constructor Create; virtual;
    
    function Reset: TBytes; virtual; abstract;
    function LineFeed: TBytes; virtual; abstract;
    function TextLine(const S: string): TBytes; virtual; abstract;
    function Align(AAlign: TTextAlign): TBytes; virtual; abstract;
    function Bold(AEnabled: Boolean): TBytes; virtual; abstract;
    function Underline(AEnabled: Boolean): TBytes; virtual; abstract;
    function TextSize(AWidth, AHeight: Byte): TBytes; virtual; abstract;
    function Barcode1D(const ACode: string; H, R, I: Byte; ASymbology: TBarcodeSymbology): TBytes; virtual; abstract;
    function QRCode(const ACode: string; ASize: Byte = 4): TBytes; virtual; abstract;
    
    // Label specific
    function BeginLabel: TBytes; virtual;
    function EndLabel: TBytes; virtual;
    function PrintLabel(ACopies: Integer = 1): TBytes; virtual;
    function Cut(AFull: Boolean): TBytes; virtual;
    function OpenDrawer: TBytes; virtual;
    function Beep: TBytes; virtual;
    
    property Encoding: TPrinterEncoding read FEncoding write FEncoding;
  end;

implementation

{ TAIPrinterLanguageBase }

constructor TAIPrinterLanguageBase.Create;
begin
  inherited Create;
  FEncoding := peRawAscii;
end;

function TAIPrinterLanguageBase.BeginLabel: TBytes;
begin
  SetLength(Result, 0);
end;

function TAIPrinterLanguageBase.EndLabel: TBytes;
begin
  SetLength(Result, 0);
end;

function TAIPrinterLanguageBase.PrintLabel(ACopies: Integer): TBytes;
begin
  SetLength(Result, 0);
end;

// Cut Paper
function TAIPrinterLanguageBase.Cut(AFull: Boolean): TBytes;
begin
  SetLength(Result, 0);
end;

function TAIPrinterLanguageBase.OpenDrawer: TBytes;
begin
  SetLength(Result, 0);
end;

function TAIPrinterLanguageBase.Beep: TBytes;
begin
  SetLength(Result, 0);
end;

end.
