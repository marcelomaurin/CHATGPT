unit demo_main;
{$mode objfpc}{$H+}{$codepage utf8}
interface
uses Classes,SysUtils,Math,Forms,Controls,StdCtrls,ExtCtrls,Spin,Windows,
  professor_view,presentation_joints,movement_timeline,kinect_retarget,
  aikinect_types,aikinectsensor,aikinectskeleton;
type
  TDemoForm=class(TForm)
  private
    View:TProfessorView;Sensor:TAIKinectSensor;Skeleton:TAIKinectSkeleton;
    Models:TComboBox;Device:TSpinEdit;Status:TLabel;Demo:TCheckBox;Timer:TTimer;
    LastSeen,Started:QWord;Tracking:Integer;Root:string;
    procedure LoadModel(Sender:TObject);
    procedure Connect(Sender:TObject);
    procedure Disconnect(Sender:TObject);
    procedure Frame(Sender:TObject;const Bodies:TAIKinectBodies);
    procedure Tick(Sender:TObject);
    procedure Error(Sender:TObject;const Msg:string);
    function Scene:TPresentationScene;
  public
    constructor Create(AOwner:TComponent);override;
    destructor Destroy;override;
  end;
implementation
function HasArg(const S:string):Boolean;
var I:Integer;
begin
  Result:=False;for I:=1 to ParamCount do
    if (ParamStr(I)='--'+S) or (ParamStr(I)='-'+S) then Exit(True);
end;
procedure Trace(const S:string);
var F:TextFile;
begin
  if not HasArg('smoke') then Exit;
  AssignFile(F,ExtractFilePath(ParamStr(0))+'smoke.log');
  if FileExists(ExtractFilePath(ParamStr(0))+'smoke.log') then Append(F) else Rewrite(F);
  WriteLn(F,S);CloseFile(F);
end;
constructor TDemoForm.Create(AOwner:TComponent);
var Panel:TPanel;B:TButton;S:TSearchRec;
begin
  Trace('Criando formulario');inherited CreateNew(AOwner);Caption:='Kinect → Avatar do Assistente';Width:=1100;Height:=780;
  Position:=poScreenCenter;
  Root:=SysUtils.GetEnvironmentVariable('ASSISTENTE_ROOT');
  if Root='' then Root:='C:\projetos\maurinsoft\Assistente';
  Windows.SetEnvironmentVariable('ASSISTENTE_MOVEMENTS_FILE',PChar(Root+'\AVATARES\movimentos.json'));
  Started:=GetTickCount64;
  Panel:=TPanel.Create(Self);Panel.Parent:=Self;Panel.Align:=alTop;Panel.Height:=100;
  Models:=TComboBox.Create(Self);Models.Parent:=Panel;Models.SetBounds(12,12,230,28);
  Models.Style:=csDropDownList;Models.OnChange:=@LoadModel;
  Device:=TSpinEdit.Create(Self);Device.Parent:=Panel;Device.SetBounds(255,12,55,28);Device.MinValue:=0;Device.MaxValue:=15;
  B:=TButton.Create(Self);B.Parent:=Panel;B.SetBounds(325,12,140,28);B.Caption:='Conectar Kinect';B.OnClick:=@Connect;
  B:=TButton.Create(Self);B.Parent:=Panel;B.SetBounds(475,12,115,28);B.Caption:='Desconectar';B.OnClick:=@Disconnect;
  Demo:=TCheckBox.Create(Self);Demo.Parent:=Panel;Demo.SetBounds(610,12,260,28);Demo.Caption:='Demonstração sem sensor';
  Status:=TLabel.Create(Self);Status.Parent:=Panel;Status.SetBounds(12,55,1030,35);Status.AutoSize:=False;
  Status.Caption:='Selecione um avatar. Índice do Kinect: 0. Captura: Kinect v1 / SDK 1.8.';
  Sensor:=TAIKinectSensor.Create(Self);Sensor.Backend:=kbKinectSDK10;Sensor.KinectModel:=kmXbox360;Sensor.OnError:=@Error;
  Skeleton:=TAIKinectSkeleton.Create(Self);Skeleton.Sensor:=Sensor;Skeleton.SeatedMode:=False;
  Skeleton.SmoothFactor:=0.5;Skeleton.OnSkeletonFrame:=@Frame;
  Trace('Criando renderizador');View:=TProfessorView.Create(Self,Self);
  if FindFirst(IncludeTrailingPathDelimiter(Root)+'AVATARES\*',faDirectory,S)=0 then begin
    repeat
      if FileExists(Root+'\AVATARES\'+S.Name+'\modelo.gltf') then Models.Items.Add(S.Name);
    until SysUtils.FindNext(S)<>0;SysUtils.FindClose(S);
  end;
  Models.ItemIndex:=Models.Items.IndexOf('professor');
  if (Models.ItemIndex<0) and (Models.Items.Count>0) then Models.ItemIndex:=0;
  Trace('Carregando modelo');if Models.ItemIndex>=0 then LoadModel(nil);Trace('Modelo carregado');
  Timer:=TTimer.Create(Self);Timer.Interval:=33;Timer.OnTimer:=@Tick;
  if HasArg('demo') or HasArg('smoke') then Demo.Checked:=True;
end;
function TDemoForm.Scene:TPresentationScene;
begin Result:=TPresentationScene(View.Scene);end;
procedure TDemoForm.LoadModel(Sender:TObject);
begin
  if Models.ItemIndex<0 then Exit;
  if View.LoadModel(Root+'\AVATARES\'+Models.Text+'\modelo.gltf',False) and Scene.SafetyReady then
    Scene.BeginEditing
  else Status.Caption:='Falha ao carregar avatar: '+View.Diagnostic;
end;
procedure TDemoForm.Connect(Sender:TObject);
begin
  Disconnect(nil);Demo.Checked:=False;Sensor.DeviceIndex:=Device.Value;
  if not Sensor.Open then begin Status.Caption:=Sensor.LastError;Exit;end;
  if not Skeleton.StartTracking then begin Status.Caption:=Skeleton.LastError;Sensor.Close;Exit;end;
  Status.Caption:='Kinect conectado. Fique de corpo inteiro diante do sensor.';
end;
procedure TDemoForm.Disconnect(Sender:TObject);
begin
  Skeleton.StopTracking;Sensor.Close;Tracking:=0;LastSeen:=0;
  Status.Caption:='Captura desligada';
end;
procedure TDemoForm.Error(Sender:TObject;const Msg:string);
begin Status.Caption:=Msg;end;
procedure TDemoForm.Frame(Sender:TObject;const Bodies:TAIKinectBodies);
var I,Selected:Integer;P:TMPoseArray;
begin
  if Demo.Checked or not Scene.SafetyReady then Exit;
  Selected:=-1;
  for I:=0 to High(Bodies) do if Bodies[I].Tracked and (Bodies[I].TrackingId=Tracking) then Selected:=I;
  if Selected<0 then begin
    // Keep the same person through short occlusions; reacquire after one second.
    if (Tracking<>0) and (GetTickCount64-LastSeen<1000) then Exit;
    for I:=0 to High(Bodies) do if Bodies[I].Tracked then begin Selected:=I;Break;end;
  end;
  if Selected<0 then Exit;
  Tracking:=Bodies[Selected].TrackingId;LastSeen:=GetTickCount64;
  P:=Retarget(Scene.EditorRig,Scene.EditorPose,Bodies[Selected],0.35);
  Scene.EditorApply(P);
  Status.Caption:='Rastreando pessoa '+IntToStr(Tracking)+' | '+Scene.MovementBlocked;
end;
procedure TDemoForm.Tick(Sender:TObject);
var P:TMPoseArray;I:Integer;T:Double;
begin
  if HasArg('smoke') and (GetTickCount64-Started>5000) then begin
    if not Scene.SafetyReady then Halt(2);
    Trace('PASS: modelo e esqueleto carregados');Close;Exit;
  end;
  if not Scene.SafetyReady then Exit;
  if Demo.Checked then begin
    if Sensor.IsConnected then Disconnect(nil);
    P:=Scene.EditorRig.RestPose;T:=GetTickCount64/1000;
    I:=Scene.EditorRig.NodeIndex('upperarm01.R');
    if I>=0 then P[I].Rotation:=QMul(P[I].Rotation,MQuaternion(0,0,25*Sin(T*2)));
    Scene.EditorApply(P);Status.Caption:='Demonstração: avatar do Assistente, sem captura física';
  end else if (LastSeen<>0) and (GetTickCount64-LastSeen>1000) then
    Status.Caption:='Pessoa fora do campo de visão. Pose mantida; aguardando rastreamento.';
end;
destructor TDemoForm.Destroy;
begin
  if Assigned(Timer) then Timer.Enabled:=False;
  if Assigned(Skeleton) and Assigned(Sensor) then Disconnect(nil);
  FreeAndNil(View);inherited Destroy;
end;
end.
