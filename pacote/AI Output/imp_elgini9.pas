unit imp_elgini9;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, imp_generico;

type
  { TIMP_ELGINI9 }

  TIMP_ELGINI9 = class(TIMP_GENERICO)
  private
    FYPos: Integer;
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
    
    // Commands supporting multiple protocols
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
  FYPos := 10;
end;

function TIMP_ELGINI9.NewLine: string;
begin
  if FProtocol in [ppEpl, ppZpl, ppTspl] then
  begin
    Inc(FYPos, 30);
    Result := '';
  end
  else
    Result := LF;
end;

function TIMP_ELGINI9.InitPrint: string;
begin
  FYPos := 10;
  case FProtocol of
    ppZpl:    Result := '^XA' + LF;
    ppTspl:   Result := 'SIZE 4,3' + LF + 'GAP 0,0' + LF + 'CLS' + LF;
    ppEpl:    Result := CR + LF + 'N' + LF;
    ppNative: Result := '';
    else      Result := ESC + '@';
  end;
end;

function TIMP_ELGINI9.LineText(const Info: string): string;
begin
  case FProtocol of
    ppZpl:
    begin
      Result := Format('^FO10,%d^ADN,18,10^FD%s^FS' + LF, [FYPos, Info]);
      Inc(FYPos, 30);
    end;
    ppTspl:
    begin
      Result := Format('TEXT 10,%d,"4",0,1,1,"%s"' + LF, [FYPos, Info]);
      Inc(FYPos, 30);
    end;
    ppEpl:
    begin
      Result := Format('A10,%d,0,4,1,1,N,"%s"' + LF, [FYPos, Info]);
      Inc(FYPos, 30);
    end;
    ppNative:
    begin
      Result := '';
    end;
    else // ppEscPos
      Result := Info + LF;
  end;
end;

function TIMP_ELGINI9.Beep: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + '(A' + #5 + #0 + 'add' + #1 + 'dd';
    else      Result := '';
  end;
end;

// Bold
function TIMP_ELGINI9.Negrito: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + 'E' + #1;
    else      Result := '';
  end;
end;

function TIMP_ELGINI9.Normal: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + 'E' + #0 + ESC + '-' + #0 + #29 + '!' + #0;
    else      Result := '';
  end;
end;

function TIMP_ELGINI9.Sublinhado: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + '-' + #2;
    else      Result := '';
  end;
end;

function TIMP_ELGINI9.DoubleTexto: string;
begin
  case FProtocol of
    ppEscPos: Result := #29 + '!' + #17;
    else      Result := '';
  end;
end;

function TIMP_ELGINI9.Guilhotina: string;
begin
  case FProtocol of
    ppZpl:    Result := '^XZ' + LF;
    ppTspl:   Result := 'PRINT 1,1' + LF;
    ppEpl:    Result := 'P1' + LF;
    ppNative: Result := '';
    else      Result := #29 + 'V' + 'B' + #3;
  end;
end;

function TIMP_ELGINI9.AcionaGaveta: string;
begin
  case FProtocol of
    ppEscPos: Result := #16 + #20 + #1 + #0 + #8;
    else      Result := '';
  end;
end;

function TIMP_ELGINI9.Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string;
var
  HRIPos: string;
begin
  case FProtocol of
    ppZpl:
    begin
      if I = 0 then HRIPos := 'N' else HRIPos := 'Y';
      Result := Format('^FO10,%d^BY%d^BCN,%d,%s,N,N^FD%s^FS' + LF, [FYPos, R, H, HRIPos, Info]);
      Inc(FYPos, H + 20);
    end;
    ppTspl:
    begin
      Result := Format('BARCODE 10,%d,"128",%d,1,0,%d,%d,"%s"' + LF, [FYPos, H, R, R * 2, Info]);
      Inc(FYPos, H + 20);
    end;
    ppEpl:
    begin
      if I = 0 then HRIPos := 'N' else HRIPos := 'B';
      Result := Format('B10,%d,0,3,%d,%d,%d,%s,"%s"' + LF, [FYPos, R, R * 2, H, HRIPos, Info]);
      Inc(FYPos, H + 20);
    end;
    ppNative:
    begin
      Result := '';
    end;
    else // ppEscPos
    begin
      Result := ESC + 'a' + #1 + 
                #29 + 'h' + Chr(H) + 
                #29 + 'w' + Chr(R) + 
                #29 + 'H' + Chr(I) + 
                #29 + 'k' + #4 + Info + #0;
    end;
  end;
end;

function TIMP_ELGINI9.Barra2D(const Info: string): string;
var
  Len: Integer;
  PL, PH: Byte;
begin
  case FProtocol of
    ppZpl:
    begin
      Result := Format('^FO10,%d^BQN,2,4^FDQA,%s^FS' + LF, [FYPos, Info]);
      Inc(FYPos, 120);
    end;
    ppTspl:
    begin
      Result := Format('QRCODE 10,%d,L,4,A,0,"%s"' + LF, [FYPos, Info]);
      Inc(FYPos, 120);
    end;
    ppEpl:
    begin
      Result := Format('b10,%d,Q,m2,g3,"%s"' + LF, [FYPos, Info]);
      Inc(FYPos, 120);
    end;
    ppNative:
    begin
      Result := '';
    end;
    else // ppEscPos
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
  end;
end;

function TIMP_ELGINI9.LoadImagem(X, Y: Integer; const Info: string): string;
begin
  case FProtocol of
    ppEscPos:
      Result := #29 + '(L' + Chr(X) + Chr(Y) + #48 + #67 + #48 + #100 + #100 + #1 +
                #100 + #100 + #10 + #10 + #10 + Info + #1;
    else
      Result := '';
  end;
end;

function TIMP_ELGINI9.ImprimeImagem(X, Y: Integer): string;
begin
  case FProtocol of
    ppEscPos:
      Result := #29 + '(L' + Chr(X) + Chr(Y) + #48 + #69 + #100 + #100 + Chr(X) + Chr(Y);
    else
      Result := '';
  end;
end;

end.
