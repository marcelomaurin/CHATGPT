unit aiserial;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, serial, LResources
  {$IFDEF MSWINDOWS}, Windows{$ENDIF};

type
  TAISerialIdleEvent = procedure(Sender: TObject; var AAbort: Boolean) of object;
  TAISerialDataEvent = procedure(Sender: TObject; const AData: string) of object;

  { TAISerialModem }

  TAISerialModem = class(TComponent)
  private
    FPrompt: string;
    FDeviceName: string;
    FBaudRate: Integer;
    FDataBits: Integer;
    FStopBits: Integer;
    FParity: Char; // 'N', 'E', 'O'
    FActive: Boolean;
    FHandle: TSerialHandle;
    FLastError: string;
    FOnIdle: TAISerialIdleEvent;
    FOnConnect: TNotifyEvent;
    FOnDisconnect: TNotifyEvent;
    FOnRXReceive: TAISerialDataEvent;
    FOnTXSend: TAISerialDataEvent;
    procedure SetActive(AValue: Boolean);
    function HandleValid: Boolean;
  public
    { No Windows, COM10 em diante precisa do prefixo \\.\ para abrir. }
    class function NormalizeDeviceName(const AName: string): string;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function OpenPort: Boolean;
    procedure ClosePort;
    function WriteText(const AText: string): Boolean;
    function ReadText(out AText: string): Boolean;
    procedure Poll;
    function SendATCommand(const ACommand: string; out AResponse: string; ATimes: Integer = 2000): Boolean; deprecated 'Use WriteText/Poll';
    function SendSMS(const ANumber, AText: string): Boolean; deprecated 'Use WriteText/Poll';
  published
    property Prompt: string read FPrompt write FPrompt;
    property DeviceName: string read FDeviceName write FDeviceName;
    property BaudRate: Integer read FBaudRate write FBaudRate default 9600;
    property DataBits: Integer read FDataBits write FDataBits default 8;
    property StopBits: Integer read FStopBits write FStopBits default 1;
    property Parity: Char read FParity write FParity default 'N';
    property Active: Boolean read FActive write SetActive default False;
    property LastError: string read FLastError;
    property OnIdle: TAISerialIdleEvent read FOnIdle write FOnIdle;
    property OnConnect: TNotifyEvent read FOnConnect write FOnConnect;
    property OnDisconnect: TNotifyEvent read FOnDisconnect write FOnDisconnect;
    property OnRXReceive: TAISerialDataEvent read FOnRXReceive write FOnRXReceive;
    property OnTXSend: TAISerialDataEvent read FOnTXSend write FOnTXSend;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAISerialModem]);
end;

{ TAISerialModem }

constructor TAISerialModem.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAISerialModem handles serial communication. Use OpenPort, ClosePort, WriteText, ReadText and Poll. Events: OnConnect, OnDisconnect, OnRXReceive and OnTXSend. AI Agent: Use this to interface legacy hardware, sensors and microcontrollers.';
  FDeviceName := 'COM1';
  FBaudRate := 9600;
  FDataBits := 8;
  FStopBits := 1;
  FParity := 'N';
  FActive := False;
  FHandle := 0;
  FLastError := '';
end;

destructor TAISerialModem.Destroy;
begin
  ClosePort;
  inherited Destroy;
end;

class function TAISerialModem.NormalizeDeviceName(const AName: string): string;
begin
  Result := Trim(AName);
  {$IFDEF MSWINDOWS}
  if SameText(Copy(Result, 1, 3), 'COM') and
     (StrToIntDef(Copy(Result, 4, MaxInt), 0) >= 10) then
    Result := '\\.\' + Result;
  {$ENDIF}
end;

function TAISerialModem.HandleValid: Boolean;
begin
  {$IFDEF MSWINDOWS}
  { TSerialHandle e THandle sem sinal: falha vem como INVALID_HANDLE_VALUE. }
  Result := (FHandle <> 0) and (FHandle <> TSerialHandle(INVALID_HANDLE_VALUE));
  {$ELSE}
  Result := FHandle > 0;
  {$ENDIF}
end;

procedure TAISerialModem.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    OpenPort
  else
    ClosePort;
end;

function TAISerialModem.OpenPort: Boolean;
var
  Par: TParityType;
  {$IFDEF MSWINDOWS}
  Timeouts: TCommTimeouts;
  {$ENDIF}
begin
  Result := False;
  FLastError := '';
  
  if FActive then Exit(True);
  
  FHandle := SerOpen(NormalizeDeviceName(FDeviceName));
  if not HandleValid then
  begin
    FHandle := 0;
    FLastError := 'Failed to open serial port: ' + FDeviceName;
    Exit;
  end;
  
  case FParity of
    'E', 'e': Par := serial.EvenParity;
    'O', 'o': Par := serial.OddParity;
    else Par := serial.NoneParity;
  end;
  
  SerSetParams(FHandle, FBaudRate, FDataBits, Par, FStopBits, []);

  {$IFDEF MSWINDOWS}
  { Leitura nao-bloqueante: Poll/ReadText retornam na hora o que houver
    no buffer, sem travar a interface esperando dados. }
  FillChar(Timeouts, SizeOf(Timeouts), 0);
  Timeouts.ReadIntervalTimeout := MAXDWORD;
  Timeouts.WriteTotalTimeoutConstant := 1000;
  SetCommTimeouts(FHandle, Timeouts);
  PurgeComm(FHandle, PURGE_RXCLEAR or PURGE_TXCLEAR);
  {$ENDIF}
  
  FActive := True;
  Result := True;
  if Assigned(FOnConnect) then
    FOnConnect(Self);
end;

procedure TAISerialModem.ClosePort;
var
  WasActive: Boolean;
begin
  WasActive := FActive;
  if HandleValid then
    SerClose(FHandle);

  FHandle := 0;
  FActive := False;
  if WasActive and Assigned(FOnDisconnect) then
    FOnDisconnect(Self);
end;

function TAISerialModem.WriteText(const AText: string): Boolean;
begin
  Result := False;
  if not FActive or not HandleValid then Exit;
  if AText = '' then Exit(True);

  if SerWrite(FHandle, Pointer(AText)^, Length(AText)) = Length(AText) then
  begin
    Result := True;
    if Assigned(FOnTXSend) then
      FOnTXSend(Self, AText);
  end
  else
    FLastError := 'Failed to write data to serial port.';
end;

function TAISerialModem.ReadText(out AText: string): Boolean;
var
  Buffer: array[0..255] of Char;
  BytesRead: Integer;
begin
  Result := False;
  AText := '';
  if not FActive or not HandleValid then Exit;
  
  FillChar(Buffer, SizeOf(Buffer), 0);
  BytesRead := SerRead(FHandle, Buffer, SizeOf(Buffer) - 1);
  if BytesRead > 0 then
  begin
    SetString(AText, Buffer, BytesRead);
    Result := True;
    if Assigned(FOnRXReceive) then
      FOnRXReceive(Self, AText);
  end;
end;

procedure TAISerialModem.Poll;
var
  Buffer: array[0..255] of Char;
  BytesRead: Integer;
  Data: string;
  I: Integer;
begin
  if not FActive or not HandleValid then Exit;

  for I := 1 to 32 do
  begin
    FillChar(Buffer, SizeOf(Buffer), 0);
    BytesRead := SerRead(FHandle, Buffer, SizeOf(Buffer));
    if BytesRead <= 0 then Exit;
    SetString(Data, Buffer, BytesRead);
    if Assigned(FOnRXReceive) then
      FOnRXReceive(Self, Data);
  end;
end;

function TAISerialModem.SendATCommand(const ACommand: string; out AResponse: string; ATimes: Integer): Boolean;
var
  I: Integer;
  Temp: string;
  Abort: Boolean;
begin
  Result := False;
  AResponse := '';
  if not WriteText(ACommand + #13#10) then Exit;
  
  // Wait loop for modem echo / response
  for I := 1 to ATimes div 50 do
  begin
    Sleep(50);
    if Assigned(FOnIdle) then
    begin
      Abort := False;
      FOnIdle(Self, Abort);
      if Abort then Exit(False);
    end;
    if ReadText(Temp) then
    begin
      AResponse := AResponse + Temp;
      if (Pos('OK', AResponse) > 0) or (Pos('ERROR', AResponse) > 0) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;
end;

function TAISerialModem.SendSMS(const ANumber, AText: string): Boolean;
var
  Resp: string;
begin
  Result := False;
  // AT Commands for GSM Modem text mode
  if not SendATCommand('AT+CMGF=1', Resp) then Exit; // Set Text Mode
  
  Sleep(100);
  if not WriteText('AT+CMGS="' + ANumber + '"' + #13#10) then Exit;
  
  Sleep(200);
  // Send actual message text and close with Ctrl+Z (ASCII 26)
  if not WriteText(AText + #26) then Exit;
  
  Result := True;
end;

initialization
  {$I aiserial_icon.lrs}

end.
