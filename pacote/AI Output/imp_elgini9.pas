unit imp_elgini9;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, imp_generico;

type
  { TIMP_ELGINI9 }

  TIMP_ELGINI9 = class(TIMP_GENERICO)
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
    
    function LoadImagem(X, Y: Integer; const Info: string): string; override;
    function ImprimeImagem(X, Y: Integer): string; override;
  end;

implementation

{ TIMP_ELGINI9 }

constructor TIMP_ELGINI9.Create;
begin
  inherited Create;
  FColuna := 48;
end;

function TIMP_ELGINI9.NewLine: string;
begin
  Result := LF;
end;

function TIMP_ELGINI9.InitPrint: string;
begin
  Result := ESC + '@';
end;

function TIMP_ELGINI9.LineText(const Info: string): string;
begin
  Result := Info + LF;
end;

function TIMP_ELGINI9.Beep: string;
begin
  Result := ESC + '(A' + #5 + #0 + 'add' + #1 + 'dd';
end;

function TIMP_ELGINI9.Negrito: string;
begin
  Result := ESC + 'E' + #1;
end;

function TIMP_ELGINI9.Normal: string;
begin
  Result := ESC + 'E' + #0 + ESC + '-' + #0 + #29 + '!' + #0;
end;

function TIMP_ELGINI9.Sublinhado: string;
begin
  Result := ESC + '-' + #2;
end;

function TIMP_ELGINI9.DoubleTexto: string;
begin
  Result := #29 + '!' + #17;
end;

function TIMP_ELGINI9.Guilhotina: string;
begin
  Result := #29 + 'V' + 'B' + #3;
end;

function TIMP_ELGINI9.AcionaGaveta: string;
begin
  Result := #16 + #20 + #1 + #0 + #8;
end;

function TIMP_ELGINI9.Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string;
begin
  Result := ESC + 'a' + #1 + 
            #29 + 'h' + Chr(H) + 
            #29 + 'w' + Chr(R) + 
            #29 + 'H' + Chr(I) + 
            #29 + 'k' + #4 + Info + #0;
end;

function TIMP_ELGINI9.Barra2D(const Info: string): string;
var
  Len: Integer;
  PL, PH: Byte;
begin
  Len := Length(Info) + 3;
  PL := Len mod 256;
  PH := Len div 256;
  Result := #29 + '(k' + #4 + #0 + #49 + #67 + #49 + #0 + // Model 2
            #29 + '(k' + #3 + #0 + #49 + #69 + #6 +  // Size (Module width)
            #29 + '(k' + #3 + #0 + #49 + #70 + #48 + // EC Level M
            #29 + '(k' + Chr(PL) + Chr(PH) + #49 + #80 + #48 + Info + // Store data
            #29 + '(k' + #3 + #0 + #49 + #81 + #48;  // Print symbol
end;

function TIMP_ELGINI9.LoadImagem(X, Y: Integer; const Info: string): string;
begin
  Result := #29 + '(L' + Chr(X) + Chr(Y) + #48 + #67 + #48 + #100 + #100 + #1 +
            #100 + #100 + #10 + #10 + #10 + Info + #1;
end;

function TIMP_ELGINI9.ImprimeImagem(X, Y: Integer): string;
begin
  Result := #29 + '(L' + Chr(X) + Chr(Y) + #48 + #69 + #100 + #100 + Chr(X) + Chr(Y);
end;

end.
