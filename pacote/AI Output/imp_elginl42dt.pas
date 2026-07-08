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

{ TIMP_ELGINL42DT }

constructor TIMP_ELGINL42DT.Create;
begin
  inherited Create;
  FColuna := 40;
  FYPos := 10;
end;

function TIMP_ELGINL42DT.NewLine: string;
begin
  Inc(FYPos, 30);
  Result := '';
end;

type
  TByteArray = array of Byte;

function TIMP_ELGINL42DT.InitPrint: string;
begin
  FYPos := 10;
  case FProtocol of
    ppZpl:
      Result := '^XA' + LF;
    ppTspl:
      Result := 'SIZE 4,3' + LF + 'GAP 0,0' + LF + 'CLS' + LF;
    ppEscPos:
      Result := ESC + '@';
    ppNative:
      Result := '';
    else // ppEpl / Default
      Result := CR + LF + 'N' + LF;
  end;
end;

function TIMP_ELGINL42DT.LineText(const Info: string): string;
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
    ppEscPos:
    begin
      Result := Info + LF;
    end;
    ppNative:
    begin
      Result := ''; // Handled by printer canvas drawing
    end;
    else // ppEpl
    begin
      Result := Format('A10,%d,0,4,1,1,N,"%s"' + LF, [FYPos, Info]);
      Inc(FYPos, 30);
    end;
  end;
end;

function TIMP_ELGINL42DT.Beep: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + '(A' + #5 + #0 + 'add' + #1 + 'dd';
    ppNative: Result := '';
    else Result := '';
  end;
end;

function TIMP_ELGINL42DT.Negrito: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + 'E' + #1;
    else Result := '';
  end;
end;

function TIMP_ELGINL42DT.Normal: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + 'E' + #0 + ESC + '-' + #0 + #29 + '!' + #0;
    else Result := '';
  end;
end;

function TIMP_ELGINL42DT.Sublinhado: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + '-' + #2;
    else Result := '';
  end;
end;

function TIMP_ELGINL42DT.DoubleTexto: string;
begin
  case FProtocol of
    ppEscPos: Result := #29 + '!' + #17;
    else Result := '';
  end;
end;

function TIMP_ELGINL42DT.Guilhotina: string;
begin
  case FProtocol of
    ppZpl:    Result := '^XZ' + LF;
    ppTspl:   Result := 'PRINT 1,1' + LF;
    ppEscPos: Result := #29 + 'V' + 'B' + #3;
    ppNative: Result := '';
    else // ppEpl
      Result := 'P1' + LF;
  end;
end;

function TIMP_ELGINL42DT.AcionaGaveta: string;
begin
  case FProtocol of
    ppEscPos: Result := #16 + #20 + #1 + #0 + #8;
    else Result := '';
  end;
end;

function TIMP_ELGINL42DT.Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string;
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
    ppEscPos:
    begin
      Result := ESC + 'a' + #1 + 
                #29 + 'h' + Chr(H) + 
                #29 + 'w' + Chr(R) + 
                #29 + 'H' + Chr(I) + 
                #29 + 'k' + #4 + Info + #0;
    end;
    ppNative:
    begin
      Result := '';
    end;
    else // ppEpl
    begin
      if I = 0 then HRIPos := 'N' else HRIPos := 'B';
      Result := Format('B10,%d,0,3,%d,%d,%d,%s,"%s"' + LF, [FYPos, R, R * 2, H, HRIPos, Info]);
      Inc(FYPos, H + 20);
    end;
  end;
end;

function TIMP_ELGINL42DT.Barra2D(const Info: string): string;
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
    ppEscPos:
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
    ppNative:
    begin
      Result := '';
    end;
    else // ppEpl
    begin
      Result := Format('b10,%d,Q,m2,g3,"%s"' + LF, [FYPos, Info]);
      Inc(FYPos, 120);
    end;
  end;
end;

end.
