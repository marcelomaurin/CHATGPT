unit imp_elginl42dt;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, imp_generico;

type
  { TIMP_ELGINL42DT }

  TIMP_ELGINL42DT = class(TIMP_GENERICO)
  private
    FYPos: Integer;
  public
    constructor Create; override;
    
    function NewLine: string; override;
    // EPL2 / PPLB specific commands
    function InitPrint: string; override;
    function LineText(const Info: string): string; override;
    function Beep: string; override;
    
    function Negrito: string; override;
    function Normal: string; override;
    function Sublinhado: string; override;
    function DoubleTexto: string; override;
    
    function Guilhotina: string; override; // Map to EPL 'P1' (Print)
    function AcionaGaveta: string; override;
    
    function Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string; override;
    function Barra2D(const Info: string): string; override;
  end;

implementation

{ TIMP_ELGINL42DT }

constructor TIMP_ELGINL42DT.Create;
begin
  inherited Create;
  FColuna := 40;
  FYPos := 10;
end;

function TIMP_ELGINL42DT.NewLine: string;
begin
  // In EPL, lines are separated by LF, and we increase Y offset
  Inc(FYPos, 30);
  Result := '';
end;

function TIMP_ELGINL42DT.InitPrint: string;
begin
  FYPos := 10;
  // 'N' clears the image buffer
  Result := CR + LF + 'N' + LF;
end;

function TIMP_ELGINL42DT.LineText(const Info: string): string;
begin
  // EPL command: A x, y, rotation, font, horiz_mult, vert_mult, reverse, "data"
  Result := Format('A10,%d,0,4,1,1,N,"%s"' + LF, [FYPos, Info]);
  Inc(FYPos, 30);
end;

function TIMP_ELGINL42DT.Beep: string;
begin
  Result := ''; // Not standard in EPL
end;

function TIMP_ELGINL42DT.Negrito: string;
begin
  // In EPL, we can use a larger font (e.g. font 5) to simulate bold
  Result := '';
end;

function TIMP_ELGINL42DT.Normal: string;
begin
  Result := '';
end;

function TIMP_ELGINL42DT.Sublinhado: string;
begin
  Result := '';
end;

function TIMP_ELGINL42DT.DoubleTexto: string;
begin
  // EPL double text can be done via multipliers, but standard receipt-style is inline.
  // We return empty as multipliers are set on a per-command basis.
  Result := '';
end;

function TIMP_ELGINL42DT.Guilhotina: string;
begin
  // EPL2 command to print label: P1 (Print 1 copy)
  Result := 'P1' + LF;
end;

function TIMP_ELGINL42DT.AcionaGaveta: string;
begin
  Result := ''; // Label printers do not support cash drawers
end;

function TIMP_ELGINL42DT.Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string;
var
  HRIPos: string;
begin
  // HRI characters print position
  if I = 0 then HRIPos := 'N' else HRIPos := 'B';
  // EPL barcode: B x, y, rotation, barcode_type, narrow_bar, wide_bar, height, human_readable, "data"
  // barcode_type '3' = Code 39
  Result := Format('B10,%d,0,3,%d,%d,%d,%s,"%s"' + LF, [FYPos, R, R * 2, H, HRIPos, Info]);
  Inc(FYPos, H + 20);
end;

function TIMP_ELGINL42DT.Barra2D(const Info: string): string;
begin
  // EPL2 QR Code: b x, y, Q, [parameters], "data"
  // Q = QR Code, m2 = Model 2, g3 = error correction level M
  Result := Format('b10,%d,Q,m2,g3,"%s"' + LF, [FYPos, Info]);
  Inc(FYPos, 120);
end;

end.
