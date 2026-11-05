unit aidronebase;

{ TAIDroneBase
  ------------
  Base comum dos componentes de drone do pacote openai_drone.

  Oferece aos componentes:
    - entrega de eventos na linha principal (OnStatus, OnError,
      OnStateChange, OnTelemetry), a partir das linhas de rede, sem bloquear
      a rede: as mensagens são enfileiradas e entregues por TThread.Queue;
    - contagem do vídeo recebido (OnVideoData é chamado na linha de rede);
    - TAIDroneWorker: linha de trabalho com pausa interrompível;
    - conversões de manche (zona morta, eixo e aceleração para byte).

  Cada componente concreto implementa Connect/Disconnect e o protocolo do
  seu drone, e publica os eventos que fazem sentido para ele. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SyncObjs, Math, aibase;

type
  TAIDroneVideoDataEvent = procedure(Sender: TObject; AData: PByte;
    ACount: Integer) of object;
  TAIDroneMessageEvent = procedure(Sender: TObject; const AMessage: string) of object;

  { TAIDroneBase }

  TAIDroneBase = class(TAIBaseComponent)
  private
    FEventLock: TCriticalSection;
    FPendingStatus: TStringList;
    FPendingErrors: TStringList;
    FStateChanged: Boolean;
    FTelemetryChanged: Boolean;
    FDeliverQueued: Boolean;
    FOnStatus: TAIDroneMessageEvent;
    FOnError: TAIDroneMessageEvent;
    FOnStateChange: TNotifyEvent;
    FOnTelemetry: TNotifyEvent;
    FOnVideoData: TAIDroneVideoDataEvent;
    FVideoBytes: Int64;
    FLastVideoTick: QWord;
    procedure QueueDelivery;
    procedure DeliverEvents;
  public
    { Uso interno das linhas de rede dos componentes (qualquer linha). }
    procedure PostStatus(const AMessage: string);
    procedure PostError(const AMessage: string);
    procedure PostStateChange;
    { Telemetria nova: OnTelemetry é entregue uma vez por lote. }
    procedure PostTelemetry;
    { Chamado na linha de rede com dados de vídeo (já sem cabeçalhos). }
    procedure DoVideoData(AData: PByte; ACount: Integer);
    procedure ResetVideoCounters;
    { Descarta eventos ainda não entregues (use antes de destruir). }
    procedure CancelPendingEvents;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    { True se chegou vídeo no último segundo. }
    function VideoStreaming: Boolean;
    property VideoBytes: Int64 read FVideoBytes;

    { Converte -1..1 em 0..255 (0 -> 127). }
    class function AxisToByte(AValue: Double): Byte; static;
    { Converte 0..1 em 0..255. }
    class function ThrottleToByte(AValue: Double): Byte; static;
    { Zona morta proporcional: |v| <= ADeadZone vira 0 e o restante é
      reescalado para continuar chegando a 1. }
    class function ApplyDeadZone(AValue, ADeadZone: Double): Double; static;
    { Limita a -1..1 tratando NaN como 0. }
    class function ClampAxis(AValue: Double): Double; static;

    { Eventos: os componentes publicam os que usam. }
    property OnStatus: TAIDroneMessageEvent read FOnStatus write FOnStatus;
    property OnError: TAIDroneMessageEvent read FOnError write FOnError;
    property OnStateChange: TNotifyEvent read FOnStateChange write FOnStateChange;
    property OnTelemetry: TNotifyEvent read FOnTelemetry write FOnTelemetry;
    { Linha de rede: só repasse os dados (ex.: TAIH264Decoder.Feed). }
    property OnVideoData: TAIDroneVideoDataEvent read FOnVideoData write FOnVideoData;
  end;

  { TAIDroneWorker: linha de trabalho dos componentes de drone. }

  TAIDroneWorker = class(TThread)
  protected
    { Espera AMs milissegundos, saindo antes se a linha for encerrada. }
    procedure Pause(AMs: Integer);
  public
    constructor Create;
  end;

implementation

{ TAIDroneBase }

constructor TAIDroneBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEventLock := TCriticalSection.Create;
  FPendingStatus := TStringList.Create;
  FPendingErrors := TStringList.Create;
end;

destructor TAIDroneBase.Destroy;
begin
  CancelPendingEvents;
  FPendingErrors.Free;
  FPendingStatus.Free;
  FEventLock.Free;
  inherited Destroy;
end;

procedure TAIDroneBase.CancelPendingEvents;
begin
  TThread.RemoveQueuedEvents(@DeliverEvents);
  FEventLock.Enter;
  try
    FPendingStatus.Clear;
    FPendingErrors.Clear;
    FStateChanged := False;
    FTelemetryChanged := False;
    FDeliverQueued := False;
  finally
    FEventLock.Leave;
  end;
end;

procedure TAIDroneBase.QueueDelivery;
var
  Queue: Boolean;
begin
  // Chamado com FEventLock tomado: uma entrega pendente por vez.
  Queue := not FDeliverQueued;
  FDeliverQueued := True;
  if Queue then
    TThread.Queue(nil, @DeliverEvents);
end;

procedure TAIDroneBase.PostStatus(const AMessage: string);
begin
  FEventLock.Enter;
  try
    FPendingStatus.Add(AMessage);
    QueueDelivery;
  finally
    FEventLock.Leave;
  end;
end;

procedure TAIDroneBase.PostError(const AMessage: string);
begin
  FEventLock.Enter;
  try
    FPendingErrors.Add(AMessage);
    QueueDelivery;
  finally
    FEventLock.Leave;
  end;
end;

procedure TAIDroneBase.PostStateChange;
begin
  FEventLock.Enter;
  try
    FStateChanged := True;
    QueueDelivery;
  finally
    FEventLock.Leave;
  end;
end;

procedure TAIDroneBase.PostTelemetry;
begin
  FEventLock.Enter;
  try
    FTelemetryChanged := True;
    QueueDelivery;
  finally
    FEventLock.Leave;
  end;
end;

procedure TAIDroneBase.DeliverEvents;
var
  Status, Errors: TStringList;
  Changed, Telemetry: Boolean;
  I: Integer;
begin
  Status := TStringList.Create;
  Errors := TStringList.Create;
  try
    FEventLock.Enter;
    try
      Status.Assign(FPendingStatus);
      Errors.Assign(FPendingErrors);
      FPendingStatus.Clear;
      FPendingErrors.Clear;
      Changed := FStateChanged;
      Telemetry := FTelemetryChanged;
      FStateChanged := False;
      FTelemetryChanged := False;
      FDeliverQueued := False;
    finally
      FEventLock.Leave;
    end;

    for I := 0 to Errors.Count - 1 do
    begin
      SetError(Errors[I]);
      Log(llError, Errors[I]);
      if Assigned(FOnError) then
        FOnError(Self, Errors[I]);
    end;
    for I := 0 to Status.Count - 1 do
    begin
      Log(llInfo, Status[I]);
      if Assigned(FOnStatus) then
        FOnStatus(Self, Status[I]);
    end;
    if Changed and Assigned(FOnStateChange) then
      FOnStateChange(Self);
    if Telemetry and Assigned(FOnTelemetry) then
      FOnTelemetry(Self);
  finally
    Errors.Free;
    Status.Free;
  end;
end;

procedure TAIDroneBase.DoVideoData(AData: PByte; ACount: Integer);
begin
  if ACount <= 0 then
    Exit;
  Inc(FVideoBytes, ACount);
  FLastVideoTick := GetTickCount64;
  if Assigned(FOnVideoData) then
    FOnVideoData(Self, AData, ACount);
end;

procedure TAIDroneBase.ResetVideoCounters;
begin
  FVideoBytes := 0;
  FLastVideoTick := 0;
end;

function TAIDroneBase.VideoStreaming: Boolean;
begin
  Result := (FLastVideoTick > 0) and (GetTickCount64 - FLastVideoTick < 1000);
end;

class function TAIDroneBase.AxisToByte(AValue: Double): Byte;
begin
  if IsNan(AValue) then
    Exit(127);
  AValue := EnsureRange(AValue, -1.0, 1.0);
  Result := Byte(EnsureRange(Trunc((AValue + 1.0) * 127.5), 0, 255));
end;

class function TAIDroneBase.ThrottleToByte(AValue: Double): Byte;
begin
  if IsNan(AValue) then
    Exit(0);
  AValue := EnsureRange(AValue, 0.0, 1.0);
  Result := Byte(EnsureRange(Round(AValue * 255.0), 0, 255));
end;

class function TAIDroneBase.ApplyDeadZone(AValue, ADeadZone: Double): Double;
begin
  if IsNan(AValue) then
    Exit(0);
  ADeadZone := EnsureRange(ADeadZone, 0.0, 0.9);
  if Abs(AValue) <= ADeadZone then
    Exit(0);
  Result := (Abs(AValue) - ADeadZone) / (1.0 - ADeadZone);
  if Result > 1 then
    Result := 1;
  if AValue < 0 then
    Result := -Result;
end;

class function TAIDroneBase.ClampAxis(AValue: Double): Double;
begin
  if IsNan(AValue) then
    Exit(0);
  Result := EnsureRange(AValue, -1.0, 1.0);
end;

{ TAIDroneWorker }

constructor TAIDroneWorker.Create;
begin
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TAIDroneWorker.Pause(AMs: Integer);
var
  T: QWord;
begin
  T := GetTickCount64 + QWord(Max(0, AMs));
  while (not Terminated) and (GetTickCount64 < T) do
    Sleep(10);
end;

end.
