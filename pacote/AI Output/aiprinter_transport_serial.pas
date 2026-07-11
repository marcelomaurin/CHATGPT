unit aiprinter_transport_serial;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, serial, aiprinter_transport;

type
  { TAIPrinterSerialTransport }

  TAIPrinterSerialTransport = class(TInterfacedObject, IAIPrinterTransport)
  private
    FDeviceName: string;
    FBaudRate: Integer;
    FTimeoutMs: Integer;
    FSerialHandle: TSerialHandle;
    FLastError: string;
    FIsOpen: Boolean;
    FDataBits: Integer;
    FParity: TParityType;
    FStopBits: Integer;
  public
    constructor Create(const ADeviceName: string; ABaudRate: Integer);
    destructor Destroy; override;
    
    // ...
    function Open: Boolean;
    procedure Close;
    function WriteAll(const ABytes: TBytes): Boolean;
    function IsOpen: Boolean;
    function LastError: string;
    procedure SetTimeoutMs(AValue: Integer);
    function GetTimeoutMs: Integer;
    
    property DataBits: Integer read FDataBits write FDataBits;
    property Parity: TParityType read FParity write FParity;
    property StopBits: Integer read FStopBits write FStopBits;
  end;

implementation

{ TAIPrinterSerialTransport }

constructor TAIPrinterSerialTransport.Create(const ADeviceName: string; ABaudRate: Integer);
begin
  inherited Create;
  FDeviceName := ADeviceName;
  FBaudRate := ABaudRate;
  FTimeoutMs := 5000;
  FSerialHandle := 0;
  FLastError := '';
  FIsOpen := False;
  FDataBits := 8;
  FParity := NoneParity;
  FStopBits := 1;
end;

destructor TAIPrinterSerialTransport.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TAIPrinterSerialTransport.Open: Boolean;
begin
  Result := False;
  FLastError := '';
  Close;
  
  FSerialHandle := SerOpen(FDeviceName);
  if FSerialHandle <> 0 then
  begin
    SerSetParams(FSerialHandle, FBaudRate, FDataBits, FParity, FStopBits, []);
    FIsOpen := True;
    Result := True;
  end
  else
    FLastError := 'Failed to open serial port: ' + FDeviceName;
end;

procedure TAIPrinterSerialTransport.Close;
begin
  if FSerialHandle <> 0 then
  begin
    SerClose(FSerialHandle);
    FSerialHandle := 0;
  end;
  FIsOpen := False;
end;

function TAIPrinterSerialTransport.WriteAll(const ABytes: TBytes): Boolean;
var
  TotalWritten: Integer;
  Written: Integer;
  Len: Integer;
begin
  Result := False;
  FLastError := '';
  if not FIsOpen or (FSerialHandle = 0) then
  begin
    FLastError := 'Serial port not open.';
    Exit;
  end;
  
  Len := Length(ABytes);
  if Len = 0 then Exit(True);
  
  TotalWritten := 0;
  while TotalWritten < Len do
  begin
    Written := SerWrite(FSerialHandle, ABytes[TotalWritten], Len - TotalWritten);
    if Written <= 0 then
    begin
      FLastError := 'Serial write failed.';
      Exit;
    end;
    Inc(TotalWritten, Written);
  end;
  Result := True;
end;

function TAIPrinterSerialTransport.IsOpen: Boolean;
begin
  Result := FIsOpen;
end;

function TAIPrinterSerialTransport.LastError: string;
begin
  Result := FLastError;
end;

procedure TAIPrinterSerialTransport.SetTimeoutMs(AValue: Integer);
begin
  FTimeoutMs := AValue;
end;

function TAIPrinterSerialTransport.GetTimeoutMs: Integer;
begin
  Result := FTimeoutMs;
end;

end.
