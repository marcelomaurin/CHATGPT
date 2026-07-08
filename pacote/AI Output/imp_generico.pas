unit imp_generico;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

const
  LF = #10;
  FF = #12;
  CR = #13;
  HT = #9;
  CAN = #24;
  ESC = #27;

type
  TPrinterProtocol = (ppEscPos, ppNative, ppEpl, ppZpl, ppTspl);

  { TIMP_GENERICO }

  TIMP_GENERICO = class
  protected
    FColuna: Integer;
    FSerial: string;
    FProtocol: TPrinterProtocol;
    function GetSerial: string; virtual;
    procedure SetSerial(const AValue: string); virtual;
  public
    constructor Create; virtual;
    
    function InitPrint: string; virtual;
    function NewLine: string; virtual;
    function LineText(const Info: string): string; virtual;
    function Beep: string; virtual;
    function Negrito: string; virtual;
    function Normal: string; virtual;
    function Sublinhado: string; virtual;
    function DoubleTexto: string; virtual;
    function Guilhotina: string; virtual;
    function AcionaGaveta: string; virtual;
    function Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string; virtual;
    function Barra2D(const Info: string): string; virtual;
    function LoadImagem(X, Y: Integer; const Info: string): string; virtual;
    function ImprimeImagem(X, Y: Integer): string; virtual;
    function Centralizado: string; virtual;
    function AlinhadoEsquerda: string; virtual;
    function AlinhadoDireita: string; virtual;

    property Serial: string read GetSerial write SetSerial;
    property Coluna: Integer read FColuna write FColuna;
    property Protocol: TPrinterProtocol read FProtocol write FProtocol;
  end;

implementation

{ TIMP_GENERICO }

constructor TIMP_GENERICO.Create;
begin
  FColuna := 48;
  FSerial := '';
  FProtocol := ppEscPos;
end;

function TIMP_GENERICO.GetSerial: string;
begin
  Result := FSerial;
end;

procedure TIMP_GENERICO.SetSerial(const AValue: string);
begin
  FSerial := AValue;
end;

function TIMP_GENERICO.InitPrint: string;
begin
  Result := ESC + '@';
end;

function TIMP_GENERICO.NewLine: string;
begin
  Result := LF;
end;

function TIMP_GENERICO.LineText(const Info: string): string;
begin
  Result := Info + LF;
end;

function TIMP_GENERICO.Beep: string;
begin
  Result := #7; // Default ASCII Bell character
end;

function TIMP_GENERICO.Negrito: string;
begin
  Result := '';
end;

function TIMP_GENERICO.Normal: string;
begin
  Result := '';
end;

function TIMP_GENERICO.Sublinhado: string;
begin
  Result := '';
end;

function TIMP_GENERICO.DoubleTexto: string;
begin
  Result := '';
end;

function TIMP_GENERICO.Guilhotina: string;
begin
  Result := '';
end;

function TIMP_GENERICO.AcionaGaveta: string;
begin
  Result := '';
end;

function TIMP_GENERICO.Barra1D(const Info: string; H: Byte; R: Byte; I: Byte): string;
begin
  Result := '';
end;

function TIMP_GENERICO.Barra2D(const Info: string): string;
begin
  Result := '';
end;

function TIMP_GENERICO.LoadImagem(X, Y: Integer; const Info: string): string;
begin
  Result := '';
end;

function TIMP_GENERICO.ImprimeImagem(X, Y: Integer): string;
begin
  Result := '';
end;

function TIMP_GENERICO.Centralizado: string;
begin
  Result := ESC + 'a' + #1;
end;

function TIMP_GENERICO.AlinhadoEsquerda: string;
begin
  Result := ESC + 'a' + #0;
end;

function TIMP_GENERICO.AlinhadoDireita: string;
begin
  Result := ESC + 'a' + #2;
end;

end.
