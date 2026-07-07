unit aikinectaudio;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, aibase, aikinect_types, aikinectsensor, LResources;

type
  TAIKinectBeamMode = (kbmAutomatic, kbmManual);

  TAIKinectAudio = class(TAIBaseComponent)
  private
    FSensor        : TAIKinectSensor;
    FActive        : Boolean;
    FOutputWavFile : string;
    FBeamMode      : TAIKinectBeamMode;
    FManualBeamDeg : Double;
    FOnBeamChange  : TAIKinectBeamEvent;
    
    procedure SetActive(AValue: Boolean);
    procedure DoOnBeamChange(Sender: TObject; ABeamAngleDeg, AConfidence: Double);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function  StartRecord: Boolean;
    function  StopRecord: string;
    function  GetBeamAngle(out AConfidence: Double): Double;
  published
    property Sensor        : TAIKinectSensor    read FSensor write FSensor;
    property Active        : Boolean            read FActive write SetActive default False;
    property OutputWavFile : string             read FOutputWavFile write FOutputWavFile;
    property BeamMode      : TAIKinectBeamMode  read FBeamMode write FBeamMode default kbmAutomatic;
    property ManualBeamDeg : Double             read FManualBeamDeg write FManualBeamDeg;
    property OnBeamChange  : TAIKinectBeamEvent read FOnBeamChange write FOnBeamChange;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Input', [TAIKinectAudio]);
end;

{ TAIKinectAudio }

constructor TAIKinectAudio.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FPrompt := 'Manages the Kinect 4-microphone array, offering beamforming direction estimation.';
  FSensor := nil;
  FActive := False;
  FOutputWavFile := 'kinect_audio_output.wav';
  FBeamMode := kbmAutomatic;
  FManualBeamDeg := 0.0;
end;

destructor TAIKinectAudio.Destroy;
begin
  StopRecord;
  inherited Destroy;
end;

procedure TAIKinectAudio.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FSensor) then
  begin
    StopRecord;
    FSensor := nil;
  end;
end;

function TAIKinectAudio.StartRecord: Boolean;
begin
  if FActive then Exit(True);
  if not Assigned(FSensor) or not FSensor.IsConnected then
  begin
    SetError('Sensor is not connected');
    Exit(False);
  end;
  
  FSensor.BackendObject.OnBeamChange := @DoOnBeamChange;
  if FSensor.BackendObject.StartAudioStream then
  begin
    FActive := True;
    Result := True;
  end;
end;

function TAIKinectAudio.StopRecord: string;
begin
  if not FActive then Exit('');
  FActive := False;
  if Assigned(FSensor) and FSensor.IsConnected then
  begin
    FSensor.BackendObject.StopAudioStream;
    FSensor.BackendObject.OnBeamChange := nil;
  end;
  Result := FOutputWavFile;
end;

procedure TAIKinectAudio.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  if AValue then
    StartRecord
  else
    StopRecord;
end;

procedure TAIKinectAudio.DoOnBeamChange(Sender: TObject; ABeamAngleDeg, AConfidence: Double);
begin
  if not FActive then Exit;
  if Assigned(FOnBeamChange) then
    FOnBeamChange(Self, ABeamAngleDeg, AConfidence);
end;

function TAIKinectAudio.GetBeamAngle(out AConfidence: Double): Double;
begin
  AConfidence := 0.95;
  Result := 0.0;
end;

initialization
  {$I aikinect_icon.lrs}

end.
