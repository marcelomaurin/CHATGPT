unit imp_qr203;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, imp_generico;

type
  { TIMP_QR203 }

  TIMP_QR203 = class(TIMP_GENERICO)
  public
    constructor Create; override;
    
    function NewLine: string; override;
    function InitPrint: string; override;
    function LineText(const Info: string): string; override;
    function Beep: string; override;
    
    function Negrito: string; override;
    function Normal: string; override;
    function Sublinhado: string; override;
    function DoubleTexto: string; override;
    
    function Guilhotina: string; override;
    function AcionaGaveta: string; override;
    
    function Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string; override;
    function Barra2D(const Info: string): string; override;
  end;

implementation

{ TIMP_QR203 }

constructor TIMP_QR203.Create;
begin
  inherited Create;
  FColuna := 32; // QR203 (58mm printer) usually has 32 columns
end;

function TIMP_QR203.NewLine: string;
begin
  Result := LF;
end;

function TIMP_QR203.InitPrint: string;
begin
  Result := ESC + '@';
end;

function TIMP_QR203.LineText(const Info: string): string;
begin
  Result := Info + LF;
end;

function TIMP_QR203.Beep: string;
begin
  Result := #7; // Standard ASCII bell for small printers
end;

function TIMP_QR203.Negrito: string;
begin
  Result := ESC + 'E' + #1;
end;

function TIMP_QR203.Normal: string;
begin
  Result := ESC + 'E' + #0 + ESC + '-' + #0 + #29 + '!' + #0;
end;

function TIMP_QR203.Sublinhado: string;
begin
  Result := ESC + '-' + #1;
end;

function TIMP_QR203.DoubleTexto: string;
begin
  Result := #29 + '!' + #17;
end;

function TIMP_QR203.Guilhotina: string;
begin
  Result := ''; // QR203 does not have a paper cutter
end;

function TIMP_QR203.AcionaGaveta: string;
begin
  Result := ''; // QR203 does not have drawer output
end;

function TIMP_QR203.Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string;
begin
  // Set height: GS h H
  // Set width: GS w R
  // Set HRI characters print position: GS H I
  // Print Barcode: GS k 4 Info NUL
  Result := ESC + 'a' + #1 +
            #29 + 'h' + Chr(H) +
            #29 + 'w' + Chr(R) +
            #29 + 'H' + Chr(I) +
            #29 + 'k' + #4 + Info + #0;
end;

function TIMP_QR203.Barra2D(const Info: string): string;
var
  Len: Integer;
begin
  // Standard format for Chinese 58mm (QR203) QR codes:
  // GS k 11 [size] [error_correction] [length] [data]
  Len := Length(Info);
  Result := ESC + 'a' + #1 +
            #29 + 'k' + #11 + #3 + #1 + Chr(Len) + Info;
end;

end.
