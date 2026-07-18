unit aiarm_robotcontrol;

{ TAI_ARM_RobotControl
  ---------------------------------------------------------------------------
  Componente nao-visual que cria e mantem, dentro de um container (ex.: um
  TScrollBox como o FJointsScroll do sample), uma linha de controle por junta
  do TAI_Arm_robot: titulo, info do eixo, valor atual e TTrackBar.

  Uso minimo (substitui MakeJointRow/JointChanged do sample):

    FControl := TAI_ARM_RobotControl.Create(Self);
    FControl.Container := FJointsScroll;
    FControl.Arm := FArm;          // ao setar o segundo, ele monta tudo sozinho

  - Mexeu no slider  -> atualiza a junta -> OnChange do braco dispara
    (viewer redesenha) -> labels atualizam.
  - Braco mudou por fora (IK, LoadFromJSON, ResetAngles) -> o control detecta
    pelo OnChange encadeado e atualiza/recria as linhas.
  - O handler OnChange que o form ja tiver instalado no braco e' PRESERVADO:
    o control guarda o anterior e chama antes do proprio.

  Compatibilidade: compila contra o aiarm_robot.pas atual do repositorio.
  Os pontos marcados com "FASE 1" ganham comportamento extra quando o campo
  PartType existir (pinca/garra mostradas como % de abertura).
  ---------------------------------------------------------------------------}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Graphics, Controls, ExtCtrls, StdCtrls, ComCtrls,
  aiarm_robot;

type

  { TAI_ARM_RobotControlRow }

  TAI_ARM_RobotControlRow = record
    Panel: TPanel;
    Title: TLabel;
    Info: TLabel;
    Value: TLabel;
    Track: TTrackBar;
  end;

  { TAI_ARM_RobotControl }

  TAI_ARM_RobotControl = class(TComponent)
  private
    FArm: TAI_Arm_robot;
    FContainer: TWinControl;
    FRows: array of TAI_ARM_RobotControlRow;
    FPrevOnChange: TAI_Arm_robotChangeEvent;
    FUpdating: Boolean;
    FRowHeight: Integer;
    FRowSpacing: Integer;
    FPanelColor: TColor;
    FTitleColor: TColor;
    FInfoColor: TColor;
    FValueColor: TColor;
    FOnRowsRebuilt: TNotifyEvent;
    procedure SetArm(AValue: TAI_Arm_robot);
    procedure SetContainer(AValue: TWinControl);
    procedure HookArm;
    procedure UnhookArm;
    procedure ArmChanged(Sender: TObject);
    procedure TrackChanged(Sender: TObject);
    procedure ClearRows;
    procedure BuildRow(const AIndex: Integer);
    function JointIsLinear(const AJoint: TAI_Arm_robotJoint): Boolean;
    function RowWidth: Integer;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { Destroi e recria todas as linhas a partir do estado atual do braco. }
    procedure Rebuild;
    { Atualiza apenas posicoes de sliders e labels, sem recriar controles. }
    procedure RefreshValues;
  published
    property Arm: TAI_Arm_robot read FArm write SetArm;
    property Container: TWinControl read FContainer write SetContainer;
    property RowHeight: Integer read FRowHeight write FRowHeight default 84;
    property RowSpacing: Integer read FRowSpacing write FRowSpacing default 8;
    property PanelColor: TColor read FPanelColor write FPanelColor default $262626;
    property TitleColor: TColor read FTitleColor write FTitleColor default clWhite;
    property InfoColor: TColor read FInfoColor write FInfoColor default clSilver;
    property ValueColor: TColor read FValueColor write FValueColor default clAqua;
    { Disparado apos cada Rebuild (util p/ o form ajustar scroll etc.). }
    property OnRowsRebuilt: TNotifyEvent read FOnRowsRebuilt write FOnRowsRebuilt;
  end;

procedure Register;

implementation

uses
  LResources;

procedure Register;
begin
  RegisterComponents('AI Industrial', [TAI_ARM_RobotControl]);
end;

{ TAI_ARM_RobotControl }

constructor TAI_ARM_RobotControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRowHeight := 84;
  FRowSpacing := 8;
  FPanelColor := $262626;
  FTitleColor := clWhite;
  FInfoColor := clSilver;
  FValueColor := clAqua;
  FUpdating := False;
  FPrevOnChange := nil;
end;

destructor TAI_ARM_RobotControl.Destroy;
begin
  UnhookArm;
  ClearRows;
  inherited Destroy;
end;

procedure TAI_ARM_RobotControl.SetArm(AValue: TAI_Arm_robot);
begin
  if FArm = AValue then Exit;
  UnhookArm;
  if Assigned(FArm) then
    FArm.RemoveFreeNotification(Self);
  FArm := AValue;
  if Assigned(FArm) then
  begin
    FArm.FreeNotification(Self);
    HookArm;
  end;
  Rebuild;
end;

procedure TAI_ARM_RobotControl.SetContainer(AValue: TWinControl);
begin
  if FContainer = AValue then Exit;
  { Linhas antigas pertencem ao container antigo: limpar antes de trocar. }
  ClearRows;
  if Assigned(FContainer) then
    FContainer.RemoveFreeNotification(Self);
  FContainer := AValue;
  if Assigned(FContainer) then
    FContainer.FreeNotification(Self);
  Rebuild;
end;

procedure TAI_ARM_RobotControl.HookArm;
begin
  if FArm = nil then Exit;
  { Encadeia sem apagar o handler que o form ja tenha instalado. Guarda-se
    contra auto-encadeamento em re-hook. }
  if not (FArm.OnChange = @ArmChanged) then
  begin
    FPrevOnChange := FArm.OnChange;
    FArm.OnChange := @ArmChanged;
  end;
end;

procedure TAI_ARM_RobotControl.UnhookArm;
begin
  if FArm = nil then Exit;
  { So restaura se o handler atual ainda for o nosso; se o form trocou por
    conta propria depois, nao interferimos. }
  if FArm.OnChange = @ArmChanged then
    FArm.OnChange := FPrevOnChange;
  FPrevOnChange := nil;
end;

procedure TAI_ARM_RobotControl.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FArm then
    begin
      { O braco esta sendo destruido: nao tocar mais no OnChange dele. }
      FArm := nil;
      FPrevOnChange := nil;
      ClearRows;
    end
    else if AComponent = FContainer then
    begin
      { Container destruido leva os paineis juntos: so zerar referencias. }
      SetLength(FRows, 0);
      FContainer := nil;
    end;
  end;
end;

procedure TAI_ARM_RobotControl.ArmChanged(Sender: TObject);
begin
  { Primeiro o handler original do form (logs, status etc.). }
  if Assigned(FPrevOnChange) then
    FPrevOnChange(Sender);
  if FUpdating then Exit;
  if (FArm <> nil) and (FArm.JointCount <> Length(FRows)) then
    Rebuild
  else
    RefreshValues;
end;

procedure TAI_ARM_RobotControl.TrackChanged(Sender: TObject);
var
  Track: TTrackBar;
  Idx: Integer;
begin
  if FUpdating or (FArm = nil) then Exit;
  if not (Sender is TTrackBar) then Exit;
  Track := TTrackBar(Sender);
  Idx := Track.Tag;
  if (Idx < 0) or (Idx >= FArm.JointCount) then Exit;
  FArm.Joints[Idx].Value := Track.Position;
  { O setter da junta dispara o OnChange do braco -> ArmChanged -> Refresh. }
end;

procedure TAI_ARM_RobotControl.ClearRows;
var
  I: Integer;
begin
  for I := High(FRows) downto 0 do
    if Assigned(FRows[I].Panel) then
      FreeAndNil(FRows[I].Panel); { filhos (labels, track) morrem junto }
  SetLength(FRows, 0);
end;

function TAI_ARM_RobotControl.JointIsLinear(
  const AJoint: TAI_Arm_robotJoint): Boolean;
begin
  Result := SameText(AJoint.JointType, 'prismatic') or
            SameText(AJoint.JointType, 'linear') or
            SameText(AJoint.JointType, 'prismatica');
end;

function TAI_ARM_RobotControl.RowWidth: Integer;
begin
  Result := 320;
  if Assigned(FContainer) then
    Result := Max(320, FContainer.ClientWidth - 2 * FRowSpacing - 16);
end;

procedure TAI_ARM_RobotControl.BuildRow(const AIndex: Integer);
var
  Joint: TAI_Arm_robotJoint;
  Row: TAI_ARM_RobotControlRow;
  TopPos: Integer;
begin
  Joint := FArm.Joints[AIndex];
  TopPos := AIndex * (FRowHeight + FRowSpacing) + FRowSpacing;

  Row.Panel := TPanel.Create(FContainer);
  Row.Panel.Parent := FContainer;
  Row.Panel.SetBounds(FRowSpacing, TopPos, RowWidth, FRowHeight);
  Row.Panel.Anchors := [akLeft, akTop, akRight]; { acompanha resize }
  Row.Panel.BevelOuter := bvNone;
  Row.Panel.Color := FPanelColor;

  Row.Title := TLabel.Create(Row.Panel);
  Row.Title.Parent := Row.Panel;
  Row.Title.Left := 12;
  Row.Title.Top := 8;
  Row.Title.Font.Style := [fsBold];
  Row.Title.Font.Color := FTitleColor;
  { Evita "Eixo 1 - 1 - Ombro": se o nome ja comeca com o indice, nao repete. }
  if Pos(IntToStr(AIndex) + ' - ', Joint.Name) = 1 then
    Row.Title.Caption := 'Eixo ' + Joint.Name
  else
    Row.Title.Caption := Format('Eixo %d - %s', [AIndex, Joint.Name]);

  Row.Info := TLabel.Create(Row.Panel);
  Row.Info.Parent := Row.Panel;
  Row.Info.Left := 12;
  Row.Info.Top := 28;
  Row.Info.Font.Color := FInfoColor;
  if JointIsLinear(Joint) then
    Row.Info.Caption := Format('linear  dir=(%.0f, %.0f, %.0f)  len=%.2f',
      [Joint.DirectionX, Joint.DirectionY, Joint.DirectionZ, Joint.Length])
  else
    Row.Info.Caption := Format(
      'direcao=(%.0f, %.0f, %.0f)  rot=(%.0f, %.0f, %.0f)  len=%.2f',
      [Joint.DirectionX, Joint.DirectionY, Joint.DirectionZ,
       Joint.RotationAxisX, Joint.RotationAxisY, Joint.RotationAxisZ,
       Joint.Length]);

  Row.Value := TLabel.Create(Row.Panel);
  Row.Value.Parent := Row.Panel;
  Row.Value.Top := 8;
  Row.Value.Anchors := [akTop, akRight];
  Row.Value.Left := Row.Panel.Width - 90;
  Row.Value.Font.Color := FValueColor;
  Row.Value.Caption := '';

  Row.Track := TTrackBar.Create(Row.Panel);
  Row.Track.Parent := Row.Panel;
  Row.Track.SetBounds(8, FRowHeight - 36, Row.Panel.Width - 16, 30);
  Row.Track.Anchors := [akLeft, akBottom, akRight];
  Row.Track.Min := Round(Joint.MinAngleDeg);
  Row.Track.Max := Max(Round(Joint.MaxAngleDeg), Row.Track.Min + 1);
  Row.Track.Position := EnsureRange(Round(Joint.AngleDeg),
    Row.Track.Min, Row.Track.Max);
  Row.Track.Frequency := 5;
  Row.Track.PageSize := 5;
  Row.Track.Tag := AIndex;
  Row.Track.OnChange := @TrackChanged;
  Row.Track.Enabled := not Joint.IsBase;

  FRows[AIndex] := Row;
end;

procedure TAI_ARM_RobotControl.Rebuild;
var
  I: Integer;
begin
  if csDesigning in ComponentState then Exit; { nada de linhas no designer }
  ClearRows;
  if (FArm = nil) or (FContainer = nil) then Exit;

  FUpdating := True;
  try
    SetLength(FRows, FArm.JointCount);
    for I := 0 to FArm.JointCount - 1 do
      BuildRow(I);
  finally
    FUpdating := False;
  end;

  RefreshValues;
  if Assigned(FOnRowsRebuilt) then
    FOnRowsRebuilt(Self);
end;

procedure TAI_ARM_RobotControl.RefreshValues;
var
  I: Integer;
  Joint: TAI_Arm_robotJoint;
begin
  if (FArm = nil) or (Length(FRows) = 0) then Exit;

  FUpdating := True;
  try
    for I := 0 to FArm.JointCount - 1 do
    begin
      if I > High(FRows) then Break;
      if FRows[I].Track = nil then Continue;
      Joint := FArm.Joints[I];
      FRows[I].Track.Min := Round(Joint.MinAngleDeg);
      FRows[I].Track.Max := Max(Round(Joint.MaxAngleDeg),
        FRows[I].Track.Min + 1);
      FRows[I].Track.Position := EnsureRange(Round(Joint.AngleDeg),
        FRows[I].Track.Min, FRows[I].Track.Max);
      if JointIsLinear(Joint) then
        FRows[I].Value.Caption := Format('%.1f cm', [Joint.Value])
      else
        FRows[I].Value.Caption := Format('%.1f deg', [Joint.Value]);
      { FASE 1: quando Joint.PartType existir, mostrar pinca/garra assim:
        if Joint.PartType in [aptPinca, aptGarra] then
          FRows[I].Value.Caption := Format('%.0f %% aberta',
            [(Joint.Value - Joint.MinValue) /
             Max(1e-9, Joint.MaxValue - Joint.MinValue) * 100]); }
    end;
  finally
    FUpdating := False;
  end;
end;

end.
