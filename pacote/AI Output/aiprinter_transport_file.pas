unit aiprinter_transport_file;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprinter_transport;

type
  { TAIPrinterFileTransport }

  TAIPrinterFileTransport = class(TInterfacedObject, IAIPrinterTransport)
  private
    FFilePath: string;
    FTimeoutMs: Integer;
    FFileStream: TFileStream;
    FLastError: string;
    FIsOpen: Boolean;
  public
    constructor Create(const AFilePath: string);
    destructor Destroy; override;
    
    // IAIPrinterTransport
    function Open: Boolean;
    procedure Close;
    function WriteAll(const ABytes: TBytes): Boolean;
    function IsOpen: Boolean;
    function LastError: string;
    procedure SetTimeoutMs(AValue: Integer);
    function GetTimeoutMs: Integer;
  end;

implementation

{ TAIPrinterFileTransport }

constructor TAIPrinterFileTransport.Create(const AFilePath: string);
begin
  inherited Create;
  FFilePath := AFilePath;
  FTimeoutMs := 1000;
  FFileStream := nil;
  FLastError := '';
  FIsOpen := False;
end;

destructor TAIPrinterFileTransport.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TAIPrinterFileTransport.Open: Boolean;
var
  Dir: string;
  IsDevice: Boolean;
begin
  Result := False;
  FLastError := '';
  Close;
  
  try
    IsDevice := (Pos('/dev/', FFilePath) = 1) or (Pos('\\.\', FFilePath) = 1);
    if not IsDevice then
    begin
      Dir := ExtractFileDir(FFilePath);
      if (Dir <> '') and not DirectoryExists(Dir) then
        ForceDirectories(Dir);
    end;
      
    if FileExists(FFilePath) then
      FFileStream := TFileStream.Create(FFilePath, fmOpenWrite or fmShareDenyNone)
    else
      FFileStream := TFileStream.Create(FFilePath, fmCreate);
      
    FIsOpen := True;
    Result := True;
  except
    on E: Exception do
      FLastError := 'Failed to open file: ' + E.Message;
  end;
end;

procedure TAIPrinterFileTransport.Close;
begin
  if Assigned(FFileStream) then
  begin
    FreeAndNil(FFileStream);
  end;
  FIsOpen := False;
end;

function TAIPrinterFileTransport.WriteAll(const ABytes: TBytes): Boolean;
var
  Len: Integer;
begin
  Result := False;
  FLastError := '';
  if not FIsOpen or not Assigned(FFileStream) then
  begin
    FLastError := 'File not open.';
    Exit;
  end;
  
  Len := Length(ABytes);
  if Len = 0 then Exit(True);
  
  try
    FFileStream.WriteBuffer(ABytes[0], Len);
    Result := True;
  except
    on E: Exception do
      FLastError := 'File write failed: ' + E.Message;
  end;
end;

function TAIPrinterFileTransport.IsOpen: Boolean;
begin
  Result := FIsOpen;
end;

function TAIPrinterFileTransport.LastError: string;
begin
  Result := FLastError;
end;

procedure TAIPrinterFileTransport.SetTimeoutMs(AValue: Integer);
begin
  FTimeoutMs := AValue;
end;

function TAIPrinterFileTransport.GetTimeoutMs: Integer;
begin
  Result := FTimeoutMs;
end;

end.
