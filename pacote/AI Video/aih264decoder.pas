unit aih264decoder;

{ TAIH264Decoder
  ---------------
  Decodificador genérico de fluxo H.264 bruto (Anexo B, com códigos de início
  00 00 00 01) para quadros TBitmap.

  Uso:
    Decoder.Width := 720; Decoder.Height := 576;
    Decoder.OnFrame := @MeuQuadro;       // chamado na linha principal
    Decoder.Start;
    Decoder.Feed(Buffer, Tamanho);       // pode ser chamado de qualquer linha

  A decodificação é feita por um processo ffmpeg em segundo plano, que recebe
  o fluxo pela entrada padrão e devolve quadros BGRA crus pela saída padrão.
  O ffmpeg é procurado, nesta ordem, em FFmpegPath, na pasta do executável e
  no PATH do sistema.

  Serve para qualquer fonte H.264 bruta: drones Wi-Fi, câmeras IP, gravações
  .h264. Width e Height definem o tamanho do quadro entregue (o vídeo é
  redimensionado pelo ffmpeg se necessário). }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Process, Graphics, GraphType, aibase;

type
  TAIH264FrameEvent = procedure(Sender: TObject; ABitmap: TBitmap) of object;
  TAIH264ErrorEvent = procedure(Sender: TObject; const AMessage: string) of object;

  { TAIH264Decoder }

  TAIH264Decoder = class(TAIBaseComponent)
  private
    FFFmpegPath: string;
    FWidth: Integer;
    FHeight: Integer;
    FLowLatency: Boolean;
    FRecordFileName: string;
    FOnFrame: TAIH264FrameEvent;
    FOnError: TAIH264ErrorEvent;

    FProcess: TProcess;
    FReader: TThread;
    FFrameLock: TCriticalSection;
    FWriteLock: TCriticalSection;
    FErrorLock: TCriticalSection;
    FFrame: TBytes;
    FFramePending: Boolean;
    FPendingErrors: TStringList;
    FBitmap: TBitmap;
    FRecord: TFileStream;
    FFramesDecoded: Int64;
    FFramesShown: Int64;
    FBytesFed: Int64;
    FFailed: Boolean;

    function GetActive: Boolean;
    procedure SetActive(AValue: Boolean);
    procedure SetWidth(AValue: Integer);
    procedure SetHeight(AValue: Integer);
    procedure QueueError(const AMessage: string);
    procedure DeliverFrame;
    procedure DeliverErrors;
    procedure FrameReady(const AData: TBytes);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { Inicia o processo de decodificação. Retorna False se o ffmpeg não for
      encontrado ou não iniciar (veja LastError). }
    function Start: Boolean;
    { Encerra o processo e descarta quadros pendentes. }
    procedure Stop;

    { Entrega bytes do fluxo H.264. Seguro para chamar de qualquer linha.
      Inicia o decodificador automaticamente se ainda não estiver ativo. }
    procedure Feed(const ABuffer; ACount: Integer);
    procedure FeedBytes(const AData: TBytes);

    { Caminho efetivo do ffmpeg que será usado ('' se não encontrado). }
    function ResolveFFmpeg: string;
    { Argumentos de linha de comando passados ao ffmpeg. }
    function BuildArguments: TStringArray;

    { Tamanho em bytes de um quadro BGRA entregue pelo ffmpeg. }
    function FrameSize: Integer;

    property Active: Boolean read GetActive write SetActive;
    { Último quadro entregue (válido após o primeiro OnFrame). }
    property Bitmap: TBitmap read FBitmap;
    property FramesDecoded: Int64 read FFramesDecoded;
    property FramesShown: Int64 read FFramesShown;
    property BytesFed: Int64 read FBytesFed;
  published
    property FFmpegPath: string read FFFmpegPath write FFFmpegPath;
    property Width: Integer read FWidth write SetWidth default 640;
    property Height: Integer read FHeight write SetHeight default 480;
    { Reduz a latência (sem bufferização, uma linha de decodificação). }
    property LowLatency: Boolean read FLowLatency write FLowLatency default True;
    { Se preenchido, grava o fluxo H.264 recebido neste arquivo (.h264). }
    property RecordFileName: string read FRecordFileName write FRecordFileName;
    { Chamado na linha principal a cada quadro novo. Quadros que chegam
      enquanto o anterior ainda não foi entregue são substituídos pelo mais
      recente, para nunca acumular atraso. }
    property OnFrame: TAIH264FrameEvent read FOnFrame write FOnFrame;
    property OnError: TAIH264ErrorEvent read FOnError write FOnError;
  end;

procedure Register;

implementation

{$IFDEF UNIX}
uses
  BaseUnix;
{$ENDIF}

type

  { TAIH264ReaderThread }

  TAIH264ReaderThread = class(TThread)
  private
    FOwner: TAIH264Decoder;
    FOutput: TStream;
    FFrameSize: Integer;
  protected
    procedure Execute; override;
  public
    constructor Create(AOwner: TAIH264Decoder; AOutput: TStream; AFrameSize: Integer);
  end;

procedure Register;
begin
  RegisterComponents('AI Video', [TAIH264Decoder]);
end;

{ TAIH264ReaderThread }

constructor TAIH264ReaderThread.Create(AOwner: TAIH264Decoder; AOutput: TStream;
  AFrameSize: Integer);
begin
  FOwner := AOwner;
  FOutput := AOutput;
  FFrameSize := AFrameSize;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TAIH264ReaderThread.Execute;
var
  Frame: TBytes;
  Got, N: Integer;
begin
  SetLength(Frame, FFrameSize);
  while not Terminated do
  begin
    Got := 0;
    while (Got < FFrameSize) and not Terminated do
    begin
      try
        N := FOutput.Read(Frame[Got], FFrameSize - Got);
      except
        N := 0;
      end;
      if N <= 0 then
        Exit; // processo encerrado
      Inc(Got, N);
    end;
    if Got = FFrameSize then
    begin
      FOwner.FrameReady(Frame);
      Queue(@FOwner.DeliverFrame);
    end;
  end;
end;

{ TAIH264Decoder }

constructor TAIH264Decoder.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category := ccInput;
  Prompt := 'Component TAIH264Decoder decodes a raw H.264 (Annex B) stream into TBitmap frames using an ffmpeg process. Properties: Width, Height (output frame size), FFmpegPath, LowLatency, RecordFileName. Methods: Start, Stop, Feed(const ABuffer; ACount) (thread-safe), FeedBytes. Events: OnFrame(Sender, ABitmap) on the main thread, always the newest frame; OnError.';
  FWidth := 640;
  FHeight := 480;
  FLowLatency := True;
  FFrameLock := TCriticalSection.Create;
  FWriteLock := TCriticalSection.Create;
  FErrorLock := TCriticalSection.Create;
  FPendingErrors := TStringList.Create;
  FBitmap := TBitmap.Create;
end;

destructor TAIH264Decoder.Destroy;
begin
  Stop;
  TThread.RemoveQueuedEvents(@DeliverErrors);
  FBitmap.Free;
  FPendingErrors.Free;
  FErrorLock.Free;
  FWriteLock.Free;
  FFrameLock.Free;
  inherited Destroy;
end;

function TAIH264Decoder.GetActive: Boolean;
begin
  Result := Assigned(FProcess) and FProcess.Running;
end;

procedure TAIH264Decoder.SetActive(AValue: Boolean);
begin
  if csDesigning in ComponentState then
    Exit;
  if AValue then
    Start
  else
    Stop;
end;

procedure TAIH264Decoder.SetWidth(AValue: Integer);
begin
  if AValue < 16 then
    AValue := 16;
  FWidth := AValue;
end;

procedure TAIH264Decoder.SetHeight(AValue: Integer);
begin
  if AValue < 16 then
    AValue := 16;
  FHeight := AValue;
end;

function TAIH264Decoder.FrameSize: Integer;
begin
  Result := FWidth * FHeight * 4;
end;

function TAIH264Decoder.ResolveFFmpeg: string;
const
{$IFDEF WINDOWS}
  ExeName = 'ffmpeg.exe';
{$ELSE}
  ExeName = 'ffmpeg';
{$ENDIF}
var
  Candidate: string;
begin
  Result := '';
  if Trim(FFFmpegPath) <> '' then
  begin
    if FileExists(FFFmpegPath) then
      Exit(FFFmpegPath);
    Candidate := ExeSearch(FFFmpegPath, GetEnvironmentVariable('PATH'));
    if Candidate <> '' then
      Exit(Candidate);
    Exit('');
  end;

  Candidate := ExtractFilePath(ParamStr(0)) + ExeName;
  if FileExists(Candidate) then
    Exit(Candidate);

  Candidate := ExtractFilePath(ParamStr(0)) + 'ffmpeg' + PathDelim + ExeName;
  if FileExists(Candidate) then
    Exit(Candidate);

  Result := ExeSearch(ExeName, GetEnvironmentVariable('PATH'));
end;

function TAIH264Decoder.BuildArguments: TStringArray;
var
  L: TStringList;
  I: Integer;
begin
  Result := nil;
  L := TStringList.Create;
  try
    L.Add('-hide_banner');
    L.Add('-loglevel'); L.Add('quiet');
    L.Add('-nostdin');
    if FLowLatency then
    begin
      L.Add('-fflags'); L.Add('nobuffer');
      L.Add('-flags'); L.Add('low_delay');
      L.Add('-probesize'); L.Add('32');
      L.Add('-analyzeduration'); L.Add('0');
      L.Add('-threads'); L.Add('1');
    end;
    L.Add('-f'); L.Add('h264');
    L.Add('-i'); L.Add('pipe:0');
    L.Add('-an');
    L.Add('-vf'); L.Add(Format('scale=%d:%d', [FWidth, FHeight]));
    L.Add('-pix_fmt'); L.Add('bgra');
    L.Add('-vsync'); L.Add('0');
    L.Add('-f'); L.Add('rawvideo');
    L.Add('pipe:1');

    SetLength(Result, L.Count);
    for I := 0 to L.Count - 1 do
      Result[I] := L[I];
  finally
    L.Free;
  end;
end;

function TAIH264Decoder.Start: Boolean;
var
  Exe: string;
  Args: TStringArray;
  I: Integer;
begin
  Result := False;
  ClearError;

  if GetActive then
    Exit(True);

  Stop;

  Exe := ResolveFFmpeg;
  if Exe = '' then
  begin
    FFailed := True;
    SetError('ffmpeg não encontrado. Coloque o ffmpeg na pasta do programa, ' +
      'no PATH ou informe FFmpegPath.');
    QueueError(LastError);
    Exit;
  end;

  {$IFDEF UNIX}
  // Escrever num pipe cujo processo morreu não pode derrubar a aplicação.
  FpSignal(SIGPIPE, SignalHandler(SIG_IGN));
  {$ENDIF}

  FProcess := TProcess.Create(nil);
  FProcess.Executable := Exe;
  Args := BuildArguments;
  for I := 0 to High(Args) do
    FProcess.Parameters.Add(Args[I]);
  FProcess.Options := [poUsePipes, poNoConsole];
  FProcess.ShowWindow := swoHIDE;

  try
    FProcess.Execute;
  except
    on E: Exception do
    begin
      FreeAndNil(FProcess);
      FFailed := True;
      SetError('Falha ao iniciar o ffmpeg: ' + E.Message);
      QueueError(LastError);
      Exit;
    end;
  end;

  if FRecordFileName <> '' then
  begin
    try
      FRecord := TFileStream.Create(FRecordFileName, fmCreate or fmShareDenyWrite);
    except
      on E: Exception do
      begin
        FRecord := nil;
        QueueError('Não foi possível gravar o vídeo em ' + FRecordFileName +
          ': ' + E.Message);
      end;
    end;
  end;

  FFailed := False;
  FFramesDecoded := 0;
  FFramesShown := 0;
  FBytesFed := 0;
  FReader := TAIH264ReaderThread.Create(Self, FProcess.Output, FrameSize);
  Log(llInfo, 'Decodificador H.264 iniciado: ' + Exe);
  Result := True;
end;

procedure TAIH264Decoder.Stop;
begin
  FWriteLock.Enter;
  try
    if Assigned(FProcess) then
    begin
      try
        FProcess.CloseInput;
      except
      end;
      try
        if FProcess.Running then
          FProcess.Terminate(0);
      except
      end;
    end;
  finally
    FWriteLock.Leave;
  end;

  if Assigned(FReader) then
  begin
    FReader.Terminate;
    FReader.WaitFor;
    TThread.RemoveQueuedEvents(FReader);
    FreeAndNil(FReader);
  end;

  FWriteLock.Enter;
  try
    FreeAndNil(FProcess);
    FreeAndNil(FRecord);
  finally
    FWriteLock.Leave;
  end;

  FFrameLock.Enter;
  try
    FFramePending := False;
  finally
    FFrameLock.Leave;
  end;
end;

procedure TAIH264Decoder.Feed(const ABuffer; ACount: Integer);
var
  Written: Integer;
  P: PByte;
begin
  if ACount <= 0 then
    Exit;

  if not Assigned(FProcess) then
  begin
    if FFailed then
      Exit;
    // Início automático: só a linha principal cria o processo com segurança
    // quando não há nada ativo; chamadas concorrentes ficam serializadas.
    FWriteLock.Enter;
    try
      if not Assigned(FProcess) and not FFailed then
        Start;
    finally
      FWriteLock.Leave;
    end;
    if not Assigned(FProcess) then
      Exit;
  end;

  FWriteLock.Enter;
  try
    if not Assigned(FProcess) then
      Exit;
    if Assigned(FRecord) then
    try
      FRecord.WriteBuffer(ABuffer, ACount);
    except
      FreeAndNil(FRecord);
    end;

    P := @ABuffer;
    Written := 0;
    try
      while Written < ACount do
      begin
        if not FProcess.Running then
          raise EStreamError.Create('processo ffmpeg encerrado');
        Inc(Written, FProcess.Input.Write(P[Written], ACount - Written));
      end;
      Inc(FBytesFed, ACount);
    except
      on E: Exception do
      begin
        FFailed := True;
        QueueError('Decodificador H.264 parou: ' + E.Message);
      end;
    end;
  finally
    FWriteLock.Leave;
  end;
end;

procedure TAIH264Decoder.FeedBytes(const AData: TBytes);
begin
  if Length(AData) > 0 then
    Feed(AData[0], Length(AData));
end;

procedure TAIH264Decoder.FrameReady(const AData: TBytes);
begin
  FFrameLock.Enter;
  try
    if Length(FFrame) <> Length(AData) then
      SetLength(FFrame, Length(AData));
    Move(AData[0], FFrame[0], Length(AData));
    FFramePending := True;
    Inc(FFramesDecoded);
  finally
    FFrameLock.Leave;
  end;
end;

procedure TAIH264Decoder.DeliverFrame;
var
  Raw: TRawImage;
  HasFrame: Boolean;
begin
  FFrameLock.Enter;
  try
    HasFrame := FFramePending and (Length(FFrame) = FrameSize);
    if HasFrame then
    begin
      Raw.Init;
      Raw.Description.Init_BPP32_B8G8R8A8_BIO_TTB(FWidth, FHeight);
      Raw.Data := @FFrame[0];
      Raw.DataSize := Length(FFrame);
      // ADataOwner = False: o LCL copia os pixels, o buffer continua nosso.
      FBitmap.LoadFromRawImage(Raw, False);
      FFramePending := False;
    end;
  finally
    FFrameLock.Leave;
  end;

  if HasFrame then
  begin
    Inc(FFramesShown);
    if Assigned(FOnFrame) then
      FOnFrame(Self, FBitmap);
  end;
end;

procedure TAIH264Decoder.QueueError(const AMessage: string);
begin
  FErrorLock.Enter;
  try
    FPendingErrors.Add(AMessage);
  finally
    FErrorLock.Leave;
  end;
  TThread.Queue(nil, @DeliverErrors);
end;

procedure TAIH264Decoder.DeliverErrors;
var
  Msgs: TStringList;
  I: Integer;
begin
  Msgs := TStringList.Create;
  try
    FErrorLock.Enter;
    try
      Msgs.Assign(FPendingErrors);
      FPendingErrors.Clear;
    finally
      FErrorLock.Leave;
    end;
    for I := 0 to Msgs.Count - 1 do
    begin
      Log(llError, Msgs[I]);
      if Assigned(FOnError) then
        FOnError(Self, Msgs[I]);
    end;
  finally
    Msgs.Free;
  end;
end;

end.
