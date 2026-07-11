unit ailistprinters;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Printers;

type
  { TAIListPrinters }

  TAIListPrinters = class(TComponent)
  private
    FPrinters: TStringList;
    function GetDefaultPrinter: string;
    function GetPrinterCount: Integer;
    function GetPrinterName(Index: Integer): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Refresh;
    property Printers: TStringList read FPrinters;
    property DefaultPrinter: string read GetDefaultPrinter;
    property PrinterCount: Integer read GetPrinterCount;
    property PrinterNames[Index: Integer]: string read GetPrinterName;
  published
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIListPrinters]);
end;

constructor TAIListPrinters.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrinters := TStringList.Create;
  Refresh;
end;

destructor TAIListPrinters.Destroy;
begin
  FPrinters.Free;
  inherited Destroy;
end;

procedure TAIListPrinters.Refresh;
begin
  FPrinters.Clear;
  if Assigned(Printer) then
    FPrinters.Assign(Printer.Printers);
end;

function TAIListPrinters.GetDefaultPrinter: string;
begin
  Result := '';
  if Assigned(Printer) and (Printer.Printers.Count > 0) then
  begin
    if (Printer.PrinterIndex >= 0) and (Printer.PrinterIndex < Printer.Printers.Count) then
      Result := Printer.Printers[Printer.PrinterIndex]
    else
      Result := Printer.Printers[0];
  end;
end;

function TAIListPrinters.GetPrinterCount: Integer;
begin
  Result := FPrinters.Count;
end;

function TAIListPrinters.GetPrinterName(Index: Integer): string;
begin
  if (Index >= 0) and (Index < FPrinters.Count) then
    Result := FPrinters[Index]
  else
    Result := '';
end;

end.
