program kinect_frame_capture_test;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, SysUtils, FileUtil,
  aikinect_types, aikinectsensor, aikinectcolor;

type
  TKinectFrameCaptureTest = class
  private
    FLog: TextFile;
    FOutputDir: string;
    FFrameFile: string;
    FGotFrame: Boolean;
    procedure Log(const AMsg: string);
    procedure SensorConnect(Sender: TObject);
    procedure SensorDisconnect(Sender: TObject);
    procedure SensorError(Sender: TObject; const AError: string);
    procedure ColorFrame(Sender: TObject; const AFrameFile: string);
  public
    function Run: Integer;
  end;

procedure TKinectFrameCaptureTest.Log(const AMsg: string);
begin
  WriteLn(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AMsg);
  WriteLn(FLog, FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' ' + AMsg);
  Flush(FLog);
end;

procedure TKinectFrameCaptureTest.SensorConnect(Sender: TObject);
begin
  Log('Sensor conectado.');
end;

procedure TKinectFrameCaptureTest.SensorDisconnect(Sender: TObject);
begin
  Log('Sensor desconectado.');
end;

procedure TKinectFrameCaptureTest.SensorError(Sender: TObject; const AError: string);
begin
  Log('Erro do sensor: ' + AError);
end;

procedure TKinectFrameCaptureTest.ColorFrame(Sender: TObject; const AFrameFile: string);
var
  DestFile: string;
begin
  Log('Frame recebido: ' + AFrameFile);
  DestFile := IncludeTrailingPathDelimiter(FOutputDir) + 'captured_color_frame.bmp';
  try
    if FileExists(DestFile) then
      DeleteFile(DestFile);
    if CopyFile(AFrameFile, DestFile) then
    begin
      FFrameFile := DestFile;
      FGotFrame := True;
      Log('Frame salvo em: ' + DestFile);
    end
    else
      Log('Falha ao copiar frame para: ' + DestFile);
  except
    on E: Exception do
      Log('Excecao ao salvar frame: ' + E.ClassName + ': ' + E.Message);
  end;
end;

function TKinectFrameCaptureTest.Run: Integer;
var
  Sensor: TAIKinectSensor;
  Color: TAIKinectColorStream;
  LogFile: string;
  StartTick: QWord;
begin
  Result := 1;
  FOutputDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'capture_output';
  ForceDirectories(FOutputDir);
  LogFile := IncludeTrailingPathDelimiter(FOutputDir) + 'kinect_frame_capture_test.log';

  AssignFile(FLog, LogFile);
  Rewrite(FLog);
  try
    Log('Iniciando teste de captura Kinect SDK10.');
    Log('OutputDir=' + FOutputDir);
    Log('LogFile=' + LogFile);
    Log('PointerSizeBits=' + IntToStr(SizeOf(Pointer) * 8));

    Sensor := TAIKinectSensor.Create(nil);
    Color := TAIKinectColorStream.Create(nil);
    try
      Sensor.DeviceIndex := 0;
      Sensor.Backend := kbKinectSDK10;
      Sensor.KinectModel := kmXbox360;
      Sensor.OnConnect := @SensorConnect;
      Sensor.OnDisconnect := @SensorDisconnect;
      Sensor.OnError := @SensorError;

      Color.Sensor := Sensor;
      Color.TempFolder := FOutputDir;
      Color.AutoDeleteTempFiles := False;
      Color.OnFrame := @ColorFrame;

      Log('Abrindo sensor...');
      if not Sensor.Open then
      begin
        Log('Falha ao abrir sensor: ' + Sensor.LastError);
        Exit(2);
      end;

      Log('Ativando stream colorido...');
      Color.Active := True;
      if not Color.Active then
      begin
        Log('Falha ao iniciar stream colorido: ' + Color.LastError);
        Exit(3);
      end;

      Log('Aguardando primeiro frame por ate 15 segundos...');
      StartTick := GetTickCount64;
      while (not FGotFrame) and ((GetTickCount64 - StartTick) < 15000) do
      begin
        CheckSynchronize(100);
        Sleep(10);
      end;

      if FGotFrame then
      begin
        Log('SUCESSO: frame capturado em ' + FFrameFile);
        Result := 0;
      end
      else
      begin
        Log('FALHA: nenhum frame recebido no tempo limite.');
        Result := 4;
      end;
    finally
      Log('Encerrando stream e sensor...');
      Color.Active := False;
      Sensor.Close;
      Color.Free;
      Sensor.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn('EXCECAO FATAL: ' + E.ClassName + ': ' + E.Message);
      try
        Log('EXCECAO FATAL: ' + E.ClassName + ': ' + E.Message);
      except
      end;
      Result := 99;
    end;
  end;
  CloseFile(FLog);
end;

var
  App: TKinectFrameCaptureTest;
begin
  App := TKinectFrameCaptureTest.Create;
  try
    Halt(App.Run);
  finally
    App.Free;
  end;
end.