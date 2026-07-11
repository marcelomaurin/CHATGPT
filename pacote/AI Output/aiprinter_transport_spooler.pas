unit aiprinter_transport_spooler;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aiprinter_transport,
  {$IFDEF MSWINDOWS}
  Windows
  {$ELSE}
  Process
  {$ENDIF}
  ;

type
  { TAIPrinterSpoolerTransport }

  TAIPrinterSpoolerTransport = class(TInterfacedObject, IAIPrinterTransport)
  private
    FPrinterName: string;
    FDocName: string;
    FTimeoutMs: Integer;
    FLastError: string;
    FIsOpen: Boolean;
    FBuffer: TBytes; // Collect bytes to send in a single document spool
    {$IFDEF MSWINDOWS}
    FPrinterHandle: THandle;
    FDocId: DWORD;
    {$ELSE}
    FTempFile: string;
    {$ENDIF}
  public
    constructor Create(const APrinterName: string; const ADocName: string = 'AI Output');
    destructor Destroy; override;
    
    function Open: Boolean;
    procedure Close;
    function WriteAll(const ABytes: TBytes): Boolean;
    function IsOpen: Boolean;
    function LastError: string;
    procedure SetTimeoutMs(AValue: Integer);
    function GetTimeoutMs: Integer;
  end;

implementation

{$IFDEF MSWINDOWS}
type
  DOC_INFO_1 = record
    pDocName: PChar;
    pOutputFile: PChar;
    pDatatype: PChar;
  end;
  PDOC_INFO_1 = ^DOC_INFO_1;

function OpenPrinterA(pPrinterName: PChar; var phPrinter: THandle; pDefault: Pointer): BOOL; stdcall; external 'winspool.drv' name 'OpenPrinterA';
function ClosePrinter(hPrinter: THandle): BOOL; stdcall; external 'winspool.drv';
function StartDocPrinterA(hPrinter: THandle; Level: DWORD; pDocInfo: Pointer): DWORD; stdcall; external 'winspool.drv' name 'StartDocPrinterA';
function EndDocPrinter(hPrinter: THandle): BOOL; stdcall; external 'winspool.drv';
function StartPagePrinter(hPrinter: THandle): BOOL; stdcall; external 'winspool.drv';
function EndPagePrinter(hPrinter: THandle): BOOL; stdcall; external 'winspool.drv';
function WritePrinter(hPrinter: THandle; pBuf: Pointer; cbBuf: DWORD; var pcWritten: DWORD): BOOL; stdcall; external 'winspool.drv';
{$ENDIF}

constructor TAIPrinterSpoolerTransport.Create(const APrinterName: string; const ADocName: string);
begin
  inherited Create;
  FPrinterName := APrinterName;
  FDocName := ADocName;
  FTimeoutMs := 5000;
  FLastError := '';
  FIsOpen := False;
  SetLength(FBuffer, 0);
  {$IFDEF MSWINDOWS}
  FPrinterHandle := 0;
  FDocId := 0;
  {$ELSE}
  FTempFile := '';
  {$ENDIF}
end;

destructor TAIPrinterSpoolerTransport.Destroy;
begin
  Close;
  inherited Destroy;
end;

function TAIPrinterSpoolerTransport.Open: Boolean;
begin
  FLastError := '';
  {$IFDEF MSWINDOWS}
  if FIsOpen then Exit(True);
  if not OpenPrinterA(PChar(FPrinterName), FPrinterHandle, nil) then
  begin
    FLastError := 'Failed to open OS printer: ' + FPrinterName + ' (Error ' + IntToStr(GetLastError) + ')';
    Exit(False);
  end;
  FIsOpen := True;
  Result := True;
  {$ELSE}
  FIsOpen := True;
  FTempFile := GetTempFilename(GetTempDir, 'cupsraw');
  Result := True;
  {$ENDIF}
end;

procedure TAIPrinterSpoolerTransport.Close;
{$IFDEF MSWINDOWS}
begin
  if not FIsOpen then Exit;
  if FDocId <> 0 then
  begin
    EndPagePrinter(FPrinterHandle);
    EndDocPrinter(FPrinterHandle);
    FDocId := 0;
  end;
  if FPrinterHandle <> 0 then
  begin
    ClosePrinter(FPrinterHandle);
    FPrinterHandle := 0;
  end;
  FIsOpen := False;
end;
{$ELSE}
var
  Proc: TProcess;
  FS: TFileStream;
begin
  if not FIsOpen then Exit;
  FIsOpen := False;
  if (FTempFile <> '') and (Length(FBuffer) > 0) then
  begin
    try
      FS := TFileStream.Create(FTempFile, fmCreate);
      try
        if Length(FBuffer) > 0 then
          FS.WriteBuffer(FBuffer[0], Length(FBuffer));
      finally
        FS.Free;
      end;
      
      Proc := TProcess.Create(nil);
      try
        Proc.Executable := 'lp';
        Proc.Parameters.Add('-d');
        Proc.Parameters.Add(FPrinterName);
        Proc.Parameters.Add('-o');
        Proc.Parameters.Add('raw');
        Proc.Parameters.Add(FTempFile);
        Proc.Options := [poWaitOnExit, poNoConsole];
        Proc.Execute;
      finally
        Proc.Free;
      end;
    except
      on E: Exception do
        FLastError := E.Message;
    end;
    
    if FileExists(FTempFile) then
      DeleteFile(FTempFile);
    FTempFile := '';
  end;
  SetLength(FBuffer, 0);
end;
{$ENDIF}

function TAIPrinterSpoolerTransport.WriteAll(const ABytes: TBytes): Boolean;
var
  OldLen, AddedLen: Integer;
  {$IFDEF MSWINDOWS}
  DocInfo: DOC_INFO_1;
  Written: DWORD;
  {$ENDIF}
begin
  Result := False;
  if not FIsOpen then
  begin
    FLastError := 'Transport is not open.';
    Exit;
  end;
  
  AddedLen := Length(ABytes);
  if AddedLen = 0 then Exit(True);

  OldLen := Length(FBuffer);
  SetLength(FBuffer, OldLen + AddedLen);
  Move(ABytes[0], FBuffer[OldLen], AddedLen);

  {$IFDEF MSWINDOWS}
  if FDocId = 0 then
  begin
    DocInfo.pDocName := PChar(FDocName);
    DocInfo.pOutputFile := nil;
    DocInfo.pDatatype := 'RAW';
    FDocId := StartDocPrinterA(FPrinterHandle, 1, @DocInfo);
    if FDocId = 0 then
    begin
      FLastError := 'Failed to start raw print job (Error ' + IntToStr(GetLastError) + ')';
      Exit;
    end;
    StartPagePrinter(FPrinterHandle);
  end;

  if not WritePrinter(FPrinterHandle, @ABytes[0], AddedLen, Written) then
  begin
    FLastError := 'Failed to write printer spooler (Error ' + IntToStr(GetLastError) + ')';
    Exit;
  end;
  Result := True;
  {$ELSE}
  Result := True;
  {$ENDIF}
end;

function TAIPrinterSpoolerTransport.IsOpen: Boolean;
begin
  Result := FIsOpen;
end;

function TAIPrinterSpoolerTransport.LastError: string;
begin
  Result := FLastError;
end;

procedure TAIPrinterSpoolerTransport.SetTimeoutMs(AValue: Integer);
begin
  FTimeoutMs := AValue;
end;

function TAIPrinterSpoolerTransport.GetTimeoutMs: Integer;
begin
  Result := FTimeoutMs;
end;

end.
