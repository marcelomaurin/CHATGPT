unit aifirmwareflasher;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, serial, fphttpclient, fpjson, jsonparser,
  opensslsockets, LResources
  {$IFDEF MSWINDOWS}
  , Windows, Registry
  {$ENDIF}
  {$IFDEF UNIX}
  , BaseUnix, Unix
  {$ENDIF};

type
  { Supported target board types }
  TAIFlasherBoardType = (
    fbtESP32CAM,      // ESP32-CAM (AI Thinker module)
    fbtESP32,         // ESP32 Generic Dev Board
    fbtArduinoUno,    // Arduino Uno (ATmega328P, 115200 baud)
    fbtArduinoNano,   // Arduino Nano (ATmega328P, 115200/57600 baud)
    fbtArduinoMega    // Arduino Mega 2560 (ATmega2560, 115200 baud)
  );

  TAIFlasherLogEvent = procedure(Sender: TObject; const AMessage: string) of object;
  TAIFlasherProgressEvent = procedure(Sender: TObject; APercent: Integer) of object;
  TAIFlasherFinishedEvent = procedure(Sender: TObject; ASuccess: Boolean; const AErrorMsg: string) of object;

  { TAIFirmwareFlasher }

  TAIFirmwareFlasher = class(TComponent)
  private
    FBoardType: TAIFlasherBoardType;
    FPort: string;
    FBaudRate: Integer;
    FSerialBaudRate: Integer;
    FFirmwareFile: string;
    FFlashAddress: string;
    FEsptoolPath: string;
    FAvrdudePath: string;
    FAvrdudeConfPath: string;
    FDaemonUrl: string;
    FCapturedToken: string;
    FCapturedDeviceId: string;
    FCapturedMac: string;
    FCapturedIp: string;
    FLastLog: string;
    FLastError: string;
    FIsFlashing: Boolean;
    FOnLog: TAIFlasherLogEvent;
    FOnProgress: TAIFlasherProgressEvent;
    FOnFinished: TAIFlasherFinishedEvent;

    procedure DoLog(const AMessage: string);
    procedure DoProgress(APercent: Integer);
    procedure DoFinished(ASuccess: Boolean; const AErrorMsg: string);
    function ParsePercent(const ALine: string): Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Serial port utilities }
    class function NormalizeDeviceName(const AName: string): string;
    procedure ListSerialPorts(APortList: TStrings);
    function AutoDetectTools: Boolean;

    { Flashing and Security token workflows }
    function FlashFirmware: Boolean;
    function RequestSerialToken(ATimeoutMs: Integer = 6000): string;
    function SendTokenToDaemon(const ADaemonUrl: string = ''): Boolean;
    function SaveTokenLocally(const AFilePath: string = ''): Boolean;
    procedure ResetCapturedData;

  published
    property BoardType: TAIFlasherBoardType read FBoardType write FBoardType default fbtESP32CAM;
    property Port: string read FPort write FPort;
    property BaudRate: Integer read FBaudRate write FBaudRate default 921600;
    property SerialBaudRate: Integer read FSerialBaudRate write FSerialBaudRate default 115200;
    property FirmwareFile: string read FFirmwareFile write FFirmwareFile;
    property FlashAddress: string read FFlashAddress write FFlashAddress;
    property EsptoolPath: string read FEsptoolPath write FEsptoolPath;
    property AvrdudePath: string read FAvrdudePath write FAvrdudePath;
    property AvrdudeConfPath: string read FAvrdudeConfPath write FAvrdudeConfPath;
    property DaemonUrl: string read FDaemonUrl write FDaemonUrl;
    property CapturedToken: string read FCapturedToken write FCapturedToken;
    property CapturedDeviceId: string read FCapturedDeviceId write FCapturedDeviceId;
    property CapturedMac: string read FCapturedMac write FCapturedMac;
    property CapturedIp: string read FCapturedIp write FCapturedIp;
    property LastLog: string read FLastLog;
    property LastError: string read FLastError;
    property IsFlashing: Boolean read FIsFlashing;

    property OnLog: TAIFlasherLogEvent read FOnLog write FOnLog;
    property OnProgress: TAIFlasherProgressEvent read FOnProgress write FOnProgress;
    property OnFinished: TAIFlasherFinishedEvent read FOnFinished write FOnFinished;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Hardware', [TAIFirmwareFlasher]);
end;

{ TAIFirmwareFlasher }

constructor TAIFirmwareFlasher.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FBoardType := fbtESP32CAM;
  FPort := 'COM19';
  FBaudRate := 921600;
  FSerialBaudRate := 115200;
  FFlashAddress := '0x0';
  FDaemonUrl := 'https://maurinsoft.com.br/casa/api/camera_discovery.php?acao=register_token';
  ResetCapturedData;
  AutoDetectTools;
end;

destructor TAIFirmwareFlasher.Destroy;
begin
  inherited Destroy;
end;

procedure TAIFirmwareFlasher.ResetCapturedData;
begin
  FCapturedToken := '';
  FCapturedDeviceId := '';
  FCapturedMac := '';
  FCapturedIp := '';
  FLastLog := '';
  FLastError := '';
end;

procedure TAIFirmwareFlasher.DoLog(const AMessage: string);
begin
  FLastLog := FLastLog + AMessage + LineEnding;
  if Assigned(FOnLog) then
    FOnLog(Self, AMessage);
end;

procedure TAIFirmwareFlasher.DoProgress(APercent: Integer);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, APercent);
end;

procedure TAIFirmwareFlasher.DoFinished(ASuccess: Boolean; const AErrorMsg: string);
begin
  FIsFlashing := False;
  if Assigned(FOnFinished) then
    FOnFinished(Self, ASuccess, AErrorMsg);
end;

class function TAIFirmwareFlasher.NormalizeDeviceName(const AName: string): string;
begin
  Result := Trim(AName);
  {$IFDEF MSWINDOWS}
  if (Pos('\\.\', Result) <> 1) and (Pos('COM', UpperCase(Result)) = 1) then
    Result := '\\.\' + Result;
  {$ENDIF}
end;

procedure TAIFirmwareFlasher.ListSerialPorts(APortList: TStrings);
{$IFDEF MSWINDOWS}
var
  Reg: TRegistry;
  Names: TStringList;
  I: Integer;
  PortVal: string;
{$ENDIF}
{$IFDEF UNIX}
var
  SR: TSearchRec;
{$ENDIF}
begin
  if APortList = nil then Exit;
  APortList.Clear;

  {$IFDEF MSWINDOWS}
  Reg := TRegistry.Create;
  Names := TStringList.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('HARDWARE\DEVICEMAP\SERIALCOMM') then
    begin
      Reg.GetValueNames(Names);
      for I := 0 to Names.Count - 1 do
      begin
        PortVal := Reg.ReadString(Names[I]);
        if (PortVal <> '') and (APortList.IndexOf(PortVal) < 0) then
          APortList.Add(PortVal);
      end;
      Reg.CloseKey;
    end;
  finally
    Names.Free;
    Reg.Free;
  end;

  // Fallback: If registry is empty, probe common COM1..COM32
  if APortList.Count = 0 then
  begin
    for I := 1 to 32 do
    begin
      PortVal := 'COM' + IntToStr(I);
      APortList.Add(PortVal);
    end;
  end;
  {$ENDIF}

  {$IFDEF UNIX}
  if FindFirst('/dev/ttyUSB*', faAnyFile, SR) = 0 then
  begin
    repeat
      APortList.Add('/dev/' + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  if FindFirst('/dev/ttyACM*', faAnyFile, SR) = 0 then
  begin
    repeat
      APortList.Add('/dev/' + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
  {$ENDIF}
end;

function TAIFirmwareFlasher.AutoDetectTools: Boolean;
var
  UserProfile: string;
  EspDir: string;
  AvrDir: string;
begin
  Result := False;
  {$IFDEF MSWINDOWS}
  UserProfile := SysUtils.GetEnvironmentVariable('USERPROFILE');
  EspDir := UserProfile + '\AppData\Local\Arduino15\packages\esp32\tools\esptool_py';
  if (FEsptoolPath = '') or not FileExists(FEsptoolPath) then
  begin
    if FileExists(EspDir + '\5.3.1\esptool.exe') then
      FEsptoolPath := EspDir + '\5.3.1\esptool.exe'
    else if FileExists(EspDir + '\4.5.1\esptool.exe') then
      FEsptoolPath := EspDir + '\4.5.1\esptool.exe';
  end;

  AvrDir := UserProfile + '\AppData\Local\Arduino15\packages\arduino\tools\avrdude';
  if (FAvrdudePath = '') or not FileExists(FAvrdudePath) then
  begin
    if FileExists(AvrDir + '\8.0.0-arduino1\bin\avrdude.exe') then
    begin
      FAvrdudePath := AvrDir + '\8.0.0-arduino1\bin\avrdude.exe';
      if FAvrdudeConfPath = '' then
        FAvrdudeConfPath := AvrDir + '\8.0.0-arduino1\etc\avrdude.conf';
    end
    else if FileExists(AvrDir + '\6.3.0-arduino17\bin\avrdude.exe') then
    begin
      FAvrdudePath := AvrDir + '\6.3.0-arduino17\bin\avrdude.exe';
      if FAvrdudeConfPath = '' then
        FAvrdudeConfPath := AvrDir + '\6.3.0-arduino17\etc\avrdude.conf';
    end;
  end;
  {$ENDIF}

  Result := (FileExists(FEsptoolPath) or FileExists(FAvrdudePath));
end;

function TAIFirmwareFlasher.ParsePercent(const ALine: string): Integer;
var
  P1, P2: Integer;
  NumStr: string;
begin
  Result := -1;
  P1 := Pos('(', ALine);
  if P1 > 0 then
  begin
    P2 := Pos('%)', ALine);
    if P2 > P1 then
    begin
      NumStr := Trim(Copy(ALine, P1 + 1, P2 - P1 - 1));
      Result := StrToIntDef(NumStr, -1);
    end;
  end;
end;

function TAIFirmwareFlasher.FlashFirmware: Boolean;
var
  Proc: TProcess;
  Buffer: array[0..1023] of Char;
  BytesRead: LongInt;
  LineBuf: string;
  Chunk: string;
  I: Integer;
  Percent: Integer;
  ActualPort: string;
  ActualSpeed: Integer;
begin
  Result := False;
  FIsFlashing := True;
  FLastLog := '';
  FLastError := '';
  DoProgress(0);

  if not FileExists(FFirmwareFile) then
  begin
    FLastError := 'Arquivo de firmware nao encontrado: ' + FFirmwareFile;
    DoLog(FLastError);
    DoFinished(False, FLastError);
    Exit;
  end;

  AutoDetectTools;

  ActualPort := Trim(FPort);
  if ActualPort = '' then
  begin
    FLastError := 'Porta serial nao especificada.';
    DoLog(FLastError);
    DoFinished(False, FLastError);
    Exit;
  end;

  Proc := TProcess.Create(nil);
  try
    Proc.Options := [poUsePipes, poStderrToOutput];
    Proc.ShowWindow := swoHIDE;

    case FBoardType of
      fbtESP32CAM, fbtESP32:
      begin
        if (FEsptoolPath = '') or not FileExists(FEsptoolPath) then
        begin
          FLastError := 'esptool executavel nao encontrado. Configure EsptoolPath.';
          DoLog(FLastError);
          DoFinished(False, FLastError);
          Exit;
        end;

        ActualSpeed := FBaudRate;
        if ActualSpeed <= 0 then ActualSpeed := 921600;

        Proc.Executable := FEsptoolPath;
        Proc.Parameters.Add('--chip');
        Proc.Parameters.Add('esp32');
        Proc.Parameters.Add('--port');
        Proc.Parameters.Add(ActualPort);
        Proc.Parameters.Add('--baud');
        Proc.Parameters.Add(IntToStr(ActualSpeed));
        Proc.Parameters.Add('--before');
        Proc.Parameters.Add('default_reset');
        Proc.Parameters.Add('--after');
        Proc.Parameters.Add('hard_reset');
        Proc.Parameters.Add('write_flash');
        Proc.Parameters.Add('-z');
        Proc.Parameters.Add('--flash_mode');
        Proc.Parameters.Add('dio');
        Proc.Parameters.Add('--flash_freq');
        Proc.Parameters.Add('80m');

        if FBoardType = fbtESP32CAM then
        begin
          Proc.Parameters.Add('--flash_size');
          Proc.Parameters.Add('4MB');
        end;

        if Trim(FFlashAddress) = '' then
          Proc.Parameters.Add('0x0')
        else
          Proc.Parameters.Add(Trim(FFlashAddress));

        Proc.Parameters.Add(FFirmwareFile);
      end;

      fbtArduinoUno, fbtArduinoNano, fbtArduinoMega:
      begin
        if (FAvrdudePath = '') or not FileExists(FAvrdudePath) then
        begin
          FLastError := 'avrdude executavel nao encontrado. Configure AvrdudePath.';
          DoLog(FLastError);
          DoFinished(False, FLastError);
          Exit;
        end;

        Proc.Executable := FAvrdudePath;
        if (FAvrdudeConfPath <> '') and FileExists(FAvrdudeConfPath) then
        begin
          Proc.Parameters.Add('-C');
          Proc.Parameters.Add(FAvrdudeConfPath);
        end;

        Proc.Parameters.Add('-v');

        case FBoardType of
          fbtArduinoUno:
          begin
            Proc.Parameters.Add('-p');
            Proc.Parameters.Add('m328p');
            Proc.Parameters.Add('-c');
            Proc.Parameters.Add('arduino');
            Proc.Parameters.Add('-b');
            Proc.Parameters.Add('115200');
          end;
          fbtArduinoNano:
          begin
            Proc.Parameters.Add('-p');
            Proc.Parameters.Add('m328p');
            Proc.Parameters.Add('-c');
            Proc.Parameters.Add('arduino');
            Proc.Parameters.Add('-b');
            if FBaudRate > 0 then
              Proc.Parameters.Add(IntToStr(FBaudRate))
            else
              Proc.Parameters.Add('115200');
          end;
          fbtArduinoMega:
          begin
            Proc.Parameters.Add('-p');
            Proc.Parameters.Add('m2560');
            Proc.Parameters.Add('-c');
            Proc.Parameters.Add('wiring');
            Proc.Parameters.Add('-b');
            Proc.Parameters.Add('115200');
          end;
        end;

        Proc.Parameters.Add('-P');
        Proc.Parameters.Add(ActualPort);
        Proc.Parameters.Add('-D');
        Proc.Parameters.Add('-U');
        Proc.Parameters.Add('flash:w:' + FFirmwareFile + ':i');
      end;
    end;

    DoLog('Iniciando gravacao...');
    DoLog('Comando: ' + Proc.Executable + ' ' + Proc.Parameters.Text);

    Proc.Execute;

    LineBuf := '';
    while Proc.Running do
    begin
      BytesRead := Proc.Output.NumBytesAvailable;
      if BytesRead > 0 then
      begin
        if BytesRead > SizeOf(Buffer) - 1 then
          BytesRead := SizeOf(Buffer) - 1;
        BytesRead := Proc.Output.Read(Buffer, BytesRead);
        if BytesRead > 0 then
        begin
          Buffer[BytesRead] := #0;
          Chunk := StrPas(Buffer);
          for I := 1 to Length(Chunk) do
          begin
            if Chunk[I] in [#10, #13] then
            begin
              if Trim(LineBuf) <> '' then
              begin
                DoLog(LineBuf);
                Percent := ParsePercent(LineBuf);
                if Percent >= 0 then
                  DoProgress(Percent);
                LineBuf := '';
              end;
            end
            else
              LineBuf := LineBuf + Chunk[I];
          end;
        end;
      end
      else
        Sleep(30);
    end;

    while Proc.Output.NumBytesAvailable > 0 do
    begin
      BytesRead := Proc.Output.Read(Buffer, SizeOf(Buffer) - 1);
      if BytesRead > 0 then
      begin
        Buffer[BytesRead] := #0;
        Chunk := StrPas(Buffer);
        DoLog(Chunk);
      end;
    end;

    Result := (Proc.ExitStatus = 0);
    if Result then
    begin
      DoProgress(100);
      DoLog('>>> Gravacao concluida com SUCESSO! <<<');
      DoFinished(True, '');
    end
    else
    begin
      FLastError := 'Processo de gravacao falhou com codigo de saida: ' + IntToStr(Proc.ExitStatus);
      DoLog('>>> ' + FLastError + ' <<<');
      DoFinished(False, FLastError);
    end;
  finally
    Proc.Free;
  end;
end;

function TAIFirmwareFlasher.RequestSerialToken(ATimeoutMs: Integer): string;
var
  LPortName: string;
  HPort: TSerialHandle;
  BytesRead: LongInt;
  StartTime: QWord;
  Buffer: array[0..255] of Char;
  LineBuf: string;
  FullOutput: string;
  Cmd: string;
  I: Integer;
  P, PEnd: Integer;
  SubStr: string;
  FoundToken: Boolean;
begin
  Result := '';
  ResetCapturedData;
  DoLog('Abrindo porta serial ' + FPort + ' para solicitar token de seguranca...');

  LPortName := NormalizeDeviceName(FPort);
  HPort := SerOpen(LPortName);

  {$IFDEF MSWINDOWS}
  if (HPort = 0) or (HPort = TSerialHandle(INVALID_HANDLE_VALUE)) then
  {$ELSE}
  if HPort <= 0 then
  {$ENDIF}
  begin
    FLastError := 'Nao foi possivel abrir a porta serial ' + FPort + ' para leitura do token.';
    DoLog(FLastError);
    Exit;
  end;

  try
    SerSetParams(HPort, FSerialBaudRate, 8, serial.NoneParity, 1, []);

    Sleep(200);
    FillChar(Buffer, SizeOf(Buffer), 0);
    while SerRead(HPort, Buffer, SizeOf(Buffer)) > 0 do;

    Cmd := 'GET_TOKEN' + #10;
    DoLog('Enviando comando GET_TOKEN pela serial...');
    SerWrite(HPort, Cmd[1], Length(Cmd));

    StartTime := GetTickCount64;
    LineBuf := '';
    FullOutput := '';
    FoundToken := False;

    while (GetTickCount64 - StartTime < QWord(ATimeoutMs)) and not FoundToken do
    begin
      BytesRead := SerRead(HPort, Buffer, SizeOf(Buffer) - 1);
      if BytesRead > 0 then
      begin
        Buffer[BytesRead] := #0;
        for I := 0 to BytesRead - 1 do
        begin
          if Buffer[I] in [#10, #13] then
          begin
            if Trim(LineBuf) <> '' then
            begin
              DoLog('[SERIAL] ' + LineBuf);
              FullOutput := FullOutput + LineBuf + LineEnding;

              // Parse DEVICE_ID=
              P := Pos('DEVICE_ID=', LineBuf);
              if P > 0 then
              begin
                SubStr := Copy(LineBuf, P + 10, Length(LineBuf));
                PEnd := Pos(':', SubStr);
                if PEnd > 0 then FCapturedDeviceId := Copy(SubStr, 1, PEnd - 1)
                else FCapturedDeviceId := Trim(SubStr);
              end;

              // Parse MAC= (Preserva os dois-pontos do endereco MAC)
              P := Pos('MAC=', LineBuf);
              if P > 0 then
              begin
                SubStr := Copy(LineBuf, P + 4, Length(LineBuf));
                PEnd := Pos(':TOKEN=', SubStr);
                if PEnd = 0 then PEnd := Pos(':IP=', SubStr);
                if PEnd > 0 then FCapturedMac := Copy(SubStr, 1, PEnd - 1)
                else if Length(SubStr) >= 17 then FCapturedMac := Copy(SubStr, 1, 17)
                else FCapturedMac := Trim(SubStr);
              end;

              // Parse TOKEN=
              P := Pos('TOKEN=', LineBuf);
              if P = 0 then P := Pos('TOKEN:', LineBuf);
              if P > 0 then
              begin
                if Pos('TOKEN=', LineBuf) > 0 then
                  SubStr := Copy(LineBuf, Pos('TOKEN=', LineBuf) + 6, Length(LineBuf))
                else
                  SubStr := Copy(LineBuf, Pos('TOKEN:', LineBuf) + 6, Length(LineBuf));
                PEnd := Pos(':', SubStr);
                if PEnd > 0 then FCapturedToken := Copy(SubStr, 1, PEnd - 1)
                else FCapturedToken := Trim(SubStr);

                if FCapturedToken <> '' then
                  FoundToken := True;
              end;

              // Parse IP=
              P := Pos('IP=', LineBuf);
              if P > 0 then
              begin
                SubStr := Copy(LineBuf, P + 3, Length(LineBuf));
                PEnd := Pos(':', SubStr);
                if PEnd > 0 then FCapturedIp := Copy(SubStr, 1, PEnd - 1)
                else FCapturedIp := Trim(SubStr);
              end;

              LineBuf := '';
            end;
          end
          else
            LineBuf := LineBuf + Buffer[I];
        end;
      end
      else
        Sleep(50);
    end;

    if FoundToken then
    begin
      Result := FCapturedToken;
      DoLog('>>> TOKEN CAPTURADO COM SUCESSO: ' + FCapturedToken + ' <<<');
      if FCapturedDeviceId <> '' then
        DoLog('Dispositivo: ' + FCapturedDeviceId);
      if FCapturedMac <> '' then
        DoLog('MAC: ' + FCapturedMac);
      if FCapturedIp <> '' then
        DoLog('IP: ' + FCapturedIp);

      SaveTokenLocally('');
    end
    else
    begin
      FLastError := 'Timeout aguardando token pela serial. Verifique se o jumper IO0 foi desconectado e aperte o botao RST da camera.';
      DoLog(FLastError);
    end;
  finally
    SerClose(HPort);
  end;
end;

function TAIFirmwareFlasher.SendTokenToDaemon(const ADaemonUrl: string): Boolean;
var
  LClient: TFPHTTPClient;
  LTargetUrl: string;
  LPayload: string;
  LResponse: string;
  LJson: TJSONObject;
  LStream: TStringStream;
begin
  Result := False;
  if FCapturedToken = '' then
  begin
    FLastError := 'Nenhum token capturado para enviar ao site/daemon.';
    DoLog(FLastError);
    Exit;
  end;

  LTargetUrl := ADaemonUrl;
  if Trim(LTargetUrl) = '' then
    LTargetUrl := FDaemonUrl;
  if Trim(LTargetUrl) = '' then
    LTargetUrl := 'https://maurinsoft.com.br/casa/api/camera_discovery.php?acao=register_token';

  SaveTokenLocally('');

  LJson := TJSONObject.Create;
  try
    LJson.Add('acao', 'register_token');
    LJson.Add('device_id', FCapturedDeviceId);
    LJson.Add('token', FCapturedToken);
    LJson.Add('mac', FCapturedMac);
    LJson.Add('ip', FCapturedIp);
    LPayload := LJson.AsJSON;
  finally
    LJson.Free;
  end;

  LClient := TFPHTTPClient.Create(nil);
  try
    try
      DoLog('Enviando token ao site/daemon: ' + LTargetUrl);
      LClient.AddHeader('Content-Type', 'application/json');
      LClient.AllowRedirect := True;
      LStream := TStringStream.Create(LPayload);
      try
        LClient.RequestBody := LStream;
        LResponse := LClient.Post(LTargetUrl);
        DoLog('Resposta do site: ' + LResponse);
        Result := True;
      finally
        LStream.Free;
      end;
    except
      on E: Exception do
      begin
        FLastError := 'Aviso: Falha ao enviar para ' + LTargetUrl + ' (' + E.Message + '). Token salvo no cofre local.';
        DoLog(FLastError);
        Result := False;
      end;
    end;
  finally
    LClient.Free;
  end;
end;

function TAIFirmwareFlasher.SaveTokenLocally(const AFilePath: string): Boolean;
var
  LTargetFile: string;
  LDir: string;
  LData: TJSONObject;
  LContent: string;
  LFileStream: TStringList;
  LJsonData: TJSONData;
begin
  Result := False;
  if Trim(FCapturedToken) = '' then Exit;

  LTargetFile := AFilePath;
  if Trim(LTargetFile) = '' then
  begin
    {$IFDEF MSWINDOWS}
    LTargetFile := SysUtils.GetEnvironmentVariable('USERPROFILE') + '\.casa\camera_tokens.json';
    {$ELSE}
    LTargetFile := SysUtils.GetEnvironmentVariable('HOME') + '/.casa/camera_tokens.json';
    {$ENDIF}
  end;

  LDir := ExtractFileDir(LTargetFile);
  if (LDir <> '') and not DirectoryExists(LDir) then
    ForceDirectories(LDir);

  LData := nil;
  if FileExists(LTargetFile) then
  begin
    LFileStream := TStringList.Create;
    try
      LFileStream.LoadFromFile(LTargetFile);
      LContent := LFileStream.Text;
      if Trim(LContent) <> '' then
      begin
        try
          LJsonData := GetJSON(LContent);
          if (LJsonData <> nil) and (LJsonData is TJSONObject) then
            LData := TJSONObject(LJsonData)
          else if LJsonData <> nil then
            LJsonData.Free;
        except
          LData := nil;
        end;
      end;
    except
      LData := nil;
    end;
    LFileStream.Free;
  end;

  if LData = nil then
    LData := TJSONObject.Create;

  try
    if FCapturedDeviceId <> '' then
      LData.Strings[FCapturedDeviceId] := FCapturedToken;
    if FCapturedMac <> '' then
      LData.Strings[FCapturedMac] := FCapturedToken;
    if FCapturedIp <> '' then
      LData.Strings[FCapturedIp] := FCapturedToken;

    LFileStream := TStringList.Create;
    try
      LFileStream.Text := LData.FormatJSON();
      LFileStream.SaveToFile(LTargetFile);
      DoLog('Token persistido com sucesso no cofre: ' + LTargetFile);
      Result := True;
    finally
      LFileStream.Free;
    end;
  finally
    LData.Free;
  end;
end;

initialization
  {$I aifirmwareflasher_icon.lrs}

end.
