unit imp_qr203;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, imp_generico;

type
  { TIMP_QR203 }

  TIMP_QR203 = class(TIMP_GENERICO)
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

{ TIMP_QR203 }

constructor TIMP_QR203.Create;
begin
  inherited Create;
  FColuna := 32; // QR203 (58mm printer) usually has 32 columns
  FYPos := 10;
end;

function TIMP_QR203.NewLine: string;
begin
  if FProtocol in [ppEpl, ppZpl, ppTspl] then
  begin
    Inc(FYPos, 30);
    Result := '';
  end
  else
    Result := LF;
end;

function TIMP_QR203.InitPrint: string;
begin
  FYPos := 10;
  case FProtocol of
    ppZpl:    Result := '^XA' + LF;
    ppTspl:   Result := 'SIZE 2,3' + LF + 'GAP 0,0' + LF + 'CLS' + LF;
    ppEpl:    Result := CR + LF + 'N' + LF;
    ppNative: Result := '';
    else      Result := ESC + '@';
  end;
end;

function TIMP_QR203.LineText(const Info: string): string;
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

function TIMP_QR203.Beep: string;
begin
  case FProtocol of
    ppEscPos: Result := #7; // Bell sound
    else      Result := '';
  end;
end;

function TIMP_QR203.Negrito: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + 'E' + #1;
    else      Result := '';
  end;
end;

// normalise styles
function TIMP_QR203.Normal: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + 'E' + #0 + ESC + '-' + #0 + #29 + '!' + #0;
    else      Result := '';
  end;
end;

function TIMP_QR203.Sublinhado: string;
begin
  case FProtocol of
    ppEscPos: Result := ESC + '-' + #1;
    else      Result := '';
  end;
end;

// double size font
function TIMP_QR203.DoubleTexto: string;
begin
  case FProtocol of
    ppEscPos: Result := #29 + '!' + #17;
    else      Result := '';
  end;
end;

function TIMP_QR203.Guilhotina: string;
begin
  case FProtocol of
    ppZpl:    Result := '^XZ' + LF;
    ppTspl:   Result := 'PRINT 1,1' + LF;
    ppEpl:    Result := 'P1' + LF;
    else      Result := ''; // QR203 doesn't have cutter hardware
  end;
end;

function TIMP_QR203.AcionaGaveta: string;
begin
  Result := '';
end;

function TIMP_QR203.Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string;
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

function TIMP_QR203.Barra2D(const Info: string): string;
var
  Len: Integer;
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
      Len := Length(Info);
      Result := ESC + 'a' + #1 +
                #29 + 'k' + #11 + #3 + #1 + Chr(Len) + Info;
    end;
  end;
end;

end.
