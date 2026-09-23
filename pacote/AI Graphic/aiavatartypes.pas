unit aiavatartypes;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  Tipos comuns, enums e funcoes de conversao para o Avatar 3D
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math;

type
  { Estados Cognitivos / Motores do Avatar (Tarefa 4) }
  TAIAvatarState = (
    avIdle,
    avListening,
    avThinking,
    avSpeaking,
    avActing,
    avSuccess,
    avError
  );

  { Emoções Faciais e Corporais (Tarefa 5) }
  TAIAvatarEmotion = (
    aeNeutral,
    aeHappy,
    aeSad,
    aeConcerned,
    aeSurprised,
    aeThinking,
    aeConfused,
    aeConfident,
    aeExcited
  );

  { Gestos Expressivos Humanoides (Tarefa 6) }
  TAIAvatarGesture = (
    agNone,
    agWave,
    agNod,
    agShakeHead,
    agExplain,
    agPoint,
    agThink,
    agShrug,
    agCelebrate,
    agListen
  );

  { Alvo de Olhar / Atenção Visual (Tarefas 3 e 54) }
  TAIAvatarLookTarget = (
    ltUser,
    ltCenter,
    ltLeft,
    ltRight,
    ltUp,
    ltDown,
    ltCustomPoint
  );

  { Ossos Humanoides Padronizados (Tarefa 7) }
  TAIHumanoidBone = (
    hbNone,
    hbHips,
    hbSpine,
    hbChest,
    hbNeck,
    hbHead,
    hbLeftShoulder,
    hbLeftUpperArm,
    hbLeftLowerArm,
    hbLeftHand,
    hbRightShoulder,
    hbRightUpperArm,
    hbRightLowerArm,
    hbRightHand,
    hbLeftUpperLeg,
    hbLeftLowerLeg,
    hbLeftFoot,
    hbRightUpperLeg,
    hbRightLowerLeg,
    hbRightFoot,
    hbJaw,
    hbLeftEye,
    hbRightEye,
    hbLeftEyebrow,
    hbRightEyebrow,
    hbUpperLip,
    hbLowerLip
  );

  { Vetores e Estruturas Matematicas 3D (Tarefas 14-27, 29) }
  TVector2D = record
    X, Y: Single;
  end;

  TVector3D = record
    X, Y, Z: Single;
  end;

  TVector4D = record
    X, Y, Z, W: Single;
  end;

  TVector4I = record
    X, Y, Z, W: Integer;
  end;

  TQuaternion = record
    X, Y, Z, W: Single;
  end;

  { Matriz 4x4 (coluna-maior glTF / OpenGL) }
  TMatrix4x4 = array[0..3, 0..3] of Single;

  { Vertice 3D com suporte a Normais, UV e Skinning }
  TAIAvatarVertex = record
    Position: TVector3D;
    Normal: TVector3D;
    UV: TVector2D;
    Joints: TVector4I;
    Weights: TVector4D;
  end;
  TAIAvatarVertexArray = array of TAIAvatarVertex;

  { Material PBR Basico (Tarefa 18) }
  TAIAvatarMaterial = record
    Name: string;
    BaseColorFactor: TVector4D;
    MetallicFactor: Single;
    RoughnessFactor: Single;
    TextureIndex: Integer;
  end;
  TAIAvatarMaterialArray = array of TAIAvatarMaterial;

  { Textura / Imagem glTF (Tarefa 19) }
  TAIAvatarTexture = record
    Name: string;
    MimeType: string;
    Data: TBytes;
    Width: Integer;
    Height: Integer;
  end;
  TAIAvatarTextureArray = array of TAIAvatarTexture;

  { Joint de Skinning (Tarefas 21-25) }
  TAIAvatarSkinJoint = record
    NodeIndex: Integer;
    Name: string;
    HumanoidBone: TAIHumanoidBone;
    ParentJointIndex: Integer;
    InverseBindMatrix: TMatrix4x4;
    LocalMatrix: TMatrix4x4;
    GlobalMatrix: TMatrix4x4;
    FinalBoneMatrix: TMatrix4x4;
  end;
  TAIAvatarSkinJointArray = array of TAIAvatarSkinJoint;

  { Skin glTF (Tarefa 21) }
  TAIAvatarSkin = record
    Name: string;
    SkeletonRootNode: Integer;
    Joints: TAIAvatarSkinJointArray;
  end;
  TAIAvatarSkinArray = array of TAIAvatarSkin;


// Conversões Enum <-> String
function AvatarStateToString(AState: TAIAvatarState): string;
function StringToAvatarState(const S: string): TAIAvatarState;

function AvatarEmotionToString(AEmotion: TAIAvatarEmotion): string;
function StringToAvatarEmotion(const S: string): TAIAvatarEmotion;

function AvatarGestureToString(AGesture: TAIAvatarGesture): string;
function StringToAvatarGesture(const S: string): TAIAvatarGesture;

function LookTargetToString(ATarget: TAIAvatarLookTarget): string;
function StringToLookTarget(const S: string): TAIAvatarLookTarget;

function HumanoidBoneToString(ABone: TAIHumanoidBone): string;
function StringToHumanoidBone(const S: string): TAIHumanoidBone;


{ Funcoes Construtoras e Matematicas 3D }
function Vector2D(AX, AY: Single): TVector2D;
function Vector3D(AX, AY, AZ: Single): TVector3D;
function Vector4D(AX, AY, AZ, AW: Single): TVector4D;
function Vector4I(AX, AY, AZ, AW: Integer): TVector4I;
function Quaternion(AX, AY, AZ, AW: Single): TQuaternion;
function IdentityMatrix: TMatrix4x4;
function MatrixMultiply(const A, B: TMatrix4x4): TMatrix4x4;
function MatrixTransformPoint(const M: TMatrix4x4; const P: TVector3D): TVector3D;
function MatrixTransformVector3D(const M: TMatrix4x4; const V: TVector3D): TVector3D;
function QuaternionNormalize(const Q: TQuaternion): TQuaternion;
function QuaternionToMatrix(const Q: TQuaternion): TMatrix4x4;
function MatrixFromTRS(const T: TVector3D; const R: TQuaternion; const S: TVector3D): TMatrix4x4;
function QuaternionSlerp(const Q1, Q2: TQuaternion; T: Single): TQuaternion;


implementation

{ TAIAvatarState }

function AvatarStateToString(AState: TAIAvatarState): string;
begin
  case AState of
    avIdle: Result := 'idle';
    avListening: Result := 'listening';
    avThinking: Result := 'thinking';
    avSpeaking: Result := 'speaking';
    avActing: Result := 'acting';
    avSuccess: Result := 'success';
    avError: Result := 'error';
  else
    Result := 'idle';
  end;
end;

function StringToAvatarState(const S: string): TAIAvatarState;
var
  LowS: string;
begin
  LowS := LowerCase(Trim(S));
  if LowS = 'listening' then Result := avListening
  else if LowS = 'thinking' then Result := avThinking
  else if LowS = 'speaking' then Result := avSpeaking
  else if LowS = 'acting' then Result := avActing
  else if LowS = 'success' then Result := avSuccess
  else if LowS = 'error' then Result := avError
  else Result := avIdle;
end;

{ TAIAvatarEmotion }

function AvatarEmotionToString(AEmotion: TAIAvatarEmotion): string;
begin
  case AEmotion of
    aeNeutral: Result := 'neutral';
    aeHappy: Result := 'happy';
    aeSad: Result := 'sad';
    aeConcerned: Result := 'concerned';
    aeSurprised: Result := 'surprised';
    aeThinking: Result := 'thinking';
    aeConfused: Result := 'confused';
    aeConfident: Result := 'confident';
    aeExcited: Result := 'excited';
  else
    Result := 'neutral';
  end;
end;

function StringToAvatarEmotion(const S: string): TAIAvatarEmotion;
var
  LowS: string;
begin
  LowS := LowerCase(Trim(S));
  if LowS = 'happy' then Result := aeHappy
  else if LowS = 'sad' then Result := aeSad
  else if LowS = 'concerned' then Result := aeConcerned
  else if LowS = 'surprised' then Result := aeSurprised
  else if LowS = 'thinking' then Result := aeThinking
  else if LowS = 'confused' then Result := aeConfused
  else if LowS = 'confident' then Result := aeConfident
  else if LowS = 'excited' then Result := aeExcited
  else Result := aeNeutral;
end;

{ TAIAvatarGesture }

function AvatarGestureToString(AGesture: TAIAvatarGesture): string;
begin
  case AGesture of
    agNone: Result := 'none';
    agWave: Result := 'wave';
    agNod: Result := 'nod';
    agShakeHead: Result := 'shake_head';
    agExplain: Result := 'explain';
    agPoint: Result := 'point';
    agThink: Result := 'think';
    agShrug: Result := 'shrug';
    agCelebrate: Result := 'celebrate';
    agListen: Result := 'listen';
  else
    Result := 'none';
  end;
end;

function StringToAvatarGesture(const S: string): TAIAvatarGesture;
var
  LowS: string;
begin
  LowS := LowerCase(Trim(S));
  if LowS = 'wave' then Result := agWave
  else if LowS = 'nod' then Result := agNod
  else if (LowS = 'shake_head') or (LowS = 'shakehead') then Result := agShakeHead
  else if LowS = 'explain' then Result := agExplain
  else if LowS = 'point' then Result := agPoint
  else if LowS = 'think' then Result := agThink
  else if LowS = 'shrug' then Result := agShrug
  else if LowS = 'celebrate' then Result := agCelebrate
  else if LowS = 'listen' then Result := agListen
  else Result := agNone;
end;

{ TAIAvatarLookTarget }

function LookTargetToString(ATarget: TAIAvatarLookTarget): string;
begin
  case ATarget of
    ltUser: Result := 'user';
    ltCenter: Result := 'center';
    ltLeft: Result := 'left';
    ltRight: Result := 'right';
    ltUp: Result := 'up';
    ltDown: Result := 'down';
    ltCustomPoint: Result := 'custom_point';
  else
    Result := 'user';
  end;
end;

function StringToLookTarget(const S: string): TAIAvatarLookTarget;
var
  LowS: string;
begin
  LowS := LowerCase(Trim(S));
  if LowS = 'center' then Result := ltCenter
  else if LowS = 'left' then Result := ltLeft
  else if LowS = 'right' then Result := ltRight
  else if LowS = 'up' then Result := ltUp
  else if LowS = 'down' then Result := ltDown
  else if (LowS = 'custom') or (LowS = 'custom_point') then Result := ltCustomPoint
  else Result := ltUser;
end;

{ TAIHumanoidBone }

function HumanoidBoneToString(ABone: TAIHumanoidBone): string;
begin
  case ABone of
    hbHips: Result := 'Hips';
    hbSpine: Result := 'Spine';
    hbChest: Result := 'Chest';
    hbNeck: Result := 'Neck';
    hbHead: Result := 'Head';
    hbLeftShoulder: Result := 'LeftShoulder';
    hbLeftUpperArm: Result := 'LeftUpperArm';
    hbLeftLowerArm: Result := 'LeftLowerArm';
    hbLeftHand: Result := 'LeftHand';
    hbRightShoulder: Result := 'RightShoulder';
    hbRightUpperArm: Result := 'RightUpperArm';
    hbRightLowerArm: Result := 'RightLowerArm';
    hbRightHand: Result := 'RightHand';
    hbLeftUpperLeg: Result := 'LeftUpperLeg';
    hbLeftLowerLeg: Result := 'LeftLowerLeg';
    hbLeftFoot: Result := 'LeftFoot';
    hbRightUpperLeg: Result := 'RightUpperLeg';
    hbRightLowerLeg: Result := 'RightLowerLeg';
    hbRightFoot: Result := 'RightFoot';
    hbJaw: Result := 'Jaw';
    hbLeftEye: Result := 'LeftEye';
    hbRightEye: Result := 'RightEye';
    hbLeftEyebrow: Result := 'LeftEyebrow';
    hbRightEyebrow: Result := 'RightEyebrow';
    hbUpperLip: Result := 'UpperLip';
    hbLowerLip: Result := 'LowerLip';
  else
    Result := 'None';
  end;
end;

function StringToHumanoidBone(const S: string): TAIHumanoidBone;
var
  LowS: string;
begin
  LowS := LowerCase(Trim(S));
  if LowS = 'hips' then Result := hbHips
  else if LowS = 'spine' then Result := hbSpine
  else if LowS = 'chest' then Result := hbChest
  else if LowS = 'neck' then Result := hbNeck
  else if LowS = 'head' then Result := hbHead
  else if (LowS = 'leftshoulder') or (LowS = 'left_shoulder') then Result := hbLeftShoulder
  else if (LowS = 'leftupperarm') or (LowS = 'left_upper_arm') or (LowS = 'leftarm') then Result := hbLeftUpperArm
  else if (LowS = 'leftlowerarm') or (LowS = 'left_lower_arm') or (LowS = 'leftforearm') then Result := hbLeftLowerArm
  else if (LowS = 'lefthand') or (LowS = 'left_hand') then Result := hbLeftHand
  else if (LowS = 'rightshoulder') or (LowS = 'right_shoulder') then Result := hbRightShoulder
  else if (LowS = 'rightupperarm') or (LowS = 'right_upper_arm') or (LowS = 'rightarm') then Result := hbRightUpperArm
  else if (LowS = 'rightlowerarm') or (LowS = 'right_lower_arm') or (LowS = 'rightforearm') then Result := hbRightLowerArm
  else if (LowS = 'righthand') or (LowS = 'right_hand') then Result := hbRightHand
  else if (LowS = 'leftupperleg') or (LowS = 'left_upper_leg') or (LowS = 'leftupleg') then Result := hbLeftUpperLeg
  else if (LowS = 'leftlowerleg') or (LowS = 'left_lower_leg') or (LowS = 'leftleg') then Result := hbLeftLowerLeg
  else if (LowS = 'leftfoot') or (LowS = 'left_foot') then Result := hbLeftFoot
  else if (LowS = 'rightupperleg') or (LowS = 'right_upper_leg') or (LowS = 'rightupleg') then Result := hbRightUpperLeg
  else if (LowS = 'rightlowerleg') or (LowS = 'right_lower_leg') or (LowS = 'rightleg') then Result := hbRightLowerLeg
  else if (LowS = 'rightfoot') or (LowS = 'right_foot') then Result := hbRightFoot
  else if LowS = 'jaw' then Result := hbJaw
  else if (LowS = 'lefteye') or (LowS = 'left_eye') then Result := hbLeftEye
  else if (LowS = 'righteye') or (LowS = 'right_eye') then Result := hbRightEye
  else if (LowS = 'lefteyebrow') or (LowS = 'left_eyebrow') then Result := hbLeftEyebrow
  else if (LowS = 'righteyebrow') or (LowS = 'right_eyebrow') then Result := hbRightEyebrow
  else if (LowS = 'upperlip') or (LowS = 'upper_lip') then Result := hbUpperLip
  else if (LowS = 'lowerlip') or (LowS = 'lower_lip') then Result := hbLowerLip
  else Result := hbNone;
end;


{ Funcoes Construtoras e Matematicas 3D }

function Vector2D(AX, AY: Single): TVector2D;
begin
  Result.X := AX;
  Result.Y := AY;
end;

function Vector3D(AX, AY, AZ: Single): TVector3D;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
end;

function Vector4D(AX, AY, AZ, AW: Single): TVector4D;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
  Result.W := AW;
end;

function Vector4I(AX, AY, AZ, AW: Integer): TVector4I;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
  Result.W := AW;
end;

function Quaternion(AX, AY, AZ, AW: Single): TQuaternion;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := AZ;
  Result.W := AW;
end;

function IdentityMatrix: TMatrix4x4;
var
  R, C: Integer;
begin
  for C := 0 to 3 do
    for R := 0 to 3 do
      if R = C then Result[C, R] := 1.0 else Result[C, R] := 0.0;
end;

function MatrixMultiply(const A, B: TMatrix4x4): TMatrix4x4;
var
  R, C, K: Integer;
  Sum: Single;
begin
  for C := 0 to 3 do
  begin
    for R := 0 to 3 do
    begin
      Sum := 0.0;
      for K := 0 to 3 do
        Sum := Sum + A[K, R] * B[C, K];
      Result[C, R] := Sum;
    end;
  end;
end;

function MatrixTransformPoint(const M: TMatrix4x4; const P: TVector3D): TVector3D;
var
  W: Single;
begin
  W := M[0, 3] * P.X + M[1, 3] * P.Y + M[2, 3] * P.Z + M[3, 3];
  if Abs(W) < 0.00001 then W := 1.0;
  Result.X := (M[0, 0] * P.X + M[1, 0] * P.Y + M[2, 0] * P.Z + M[3, 0]) / W;
  Result.Y := (M[0, 1] * P.X + M[1, 1] * P.Y + M[2, 1] * P.Z + M[3, 1]) / W;
  Result.Z := (M[0, 2] * P.X + M[1, 2] * P.Y + M[2, 2] * P.Z + M[3, 2]) / W;
end;

function MatrixTransformVector3D(const M: TMatrix4x4; const V: TVector3D): TVector3D;
begin
  Result.X := M[0, 0] * V.X + M[1, 0] * V.Y + M[2, 0] * V.Z;
  Result.Y := M[0, 1] * V.X + M[1, 1] * V.Y + M[2, 1] * V.Z;
  Result.Z := M[0, 2] * V.X + M[1, 2] * V.Y + M[2, 2] * V.Z;
end;

function QuaternionNormalize(const Q: TQuaternion): TQuaternion;
var
  Len: Single;
begin
  Len := Sqrt(Q.X * Q.X + Q.Y * Q.Y + Q.Z * Q.Z + Q.W * Q.W);
  if Len > 0.00001 then
  begin
    Result.X := Q.X / Len;
    Result.Y := Q.Y / Len;
    Result.Z := Q.Z / Len;
    Result.W := Q.W / Len;
  end
  else
  begin
    Result.X := 0.0; Result.Y := 0.0; Result.Z := 0.0; Result.W := 1.0;
  end;
end;

function QuaternionToMatrix(const Q: TQuaternion): TMatrix4x4;
var
  NQ: TQuaternion;
  X, Y, Z, W: Single;
  XX, YY, ZZ, XY, XZ, YZ, WX, WY, WZ: Single;
begin
  NQ := QuaternionNormalize(Q);
  X := NQ.X; Y := NQ.Y; Z := NQ.Z; W := NQ.W;
  XX := X * X; YY := Y * Y; ZZ := Z * Z;
  XY := X * Y; XZ := X * Z; YZ := Y * Z;
  WX := W * X; WY := W * Y; WZ := W * Z;

  Result[0, 0] := 1.0 - 2.0 * (YY + ZZ);
  Result[0, 1] := 2.0 * (XY + WZ);
  Result[0, 2] := 2.0 * (XZ - WY);
  Result[0, 3] := 0.0;

  Result[1, 0] := 2.0 * (XY - WZ);
  Result[1, 1] := 1.0 - 2.0 * (XX + ZZ);
  Result[1, 2] := 2.0 * (YZ + WX);
  Result[1, 3] := 0.0;

  Result[2, 0] := 2.0 * (XZ + WY);
  Result[2, 1] := 2.0 * (YZ - WX);
  Result[2, 2] := 1.0 - 2.0 * (XX + YY);
  Result[2, 3] := 0.0;

  Result[3, 0] := 0.0;
  Result[3, 1] := 0.0;
  Result[3, 2] := 0.0;
  Result[3, 3] := 1.0;
end;

function MatrixFromTRS(const T: TVector3D; const R: TQuaternion; const S: TVector3D): TMatrix4x4;
var
  RM: TMatrix4x4;
begin
  RM := QuaternionToMatrix(R);

  // Apply scale
  Result[0, 0] := RM[0, 0] * S.X;
  Result[0, 1] := RM[0, 1] * S.X;
  Result[0, 2] := RM[0, 2] * S.X;
  Result[0, 3] := 0.0;

  Result[1, 0] := RM[1, 0] * S.Y;
  Result[1, 1] := RM[1, 1] * S.Y;
  Result[1, 2] := RM[1, 2] * S.Y;
  Result[1, 3] := 0.0;

  Result[2, 0] := RM[2, 0] * S.Z;
  Result[2, 1] := RM[2, 1] * S.Z;
  Result[2, 2] := RM[2, 2] * S.Z;
  Result[2, 3] := 0.0;

  // Translation
  Result[3, 0] := T.X;
  Result[3, 1] := T.Y;
  Result[3, 2] := T.Z;
  Result[3, 3] := 1.0;
end;

function QuaternionSlerp(const Q1, Q2: TQuaternion; T: Single): TQuaternion;
var
  Dot, Theta, SinTheta, Scale1, Scale2: Double;
  TargetQ: TQuaternion;
begin
  TargetQ := Q2;
  Dot := Q1.X * TargetQ.X + Q1.Y * TargetQ.Y + Q1.Z * TargetQ.Z + Q1.W * TargetQ.W;

  // Shortest path
  if Dot < 0.0 then
  begin
    Dot := -Dot;
    TargetQ.X := -TargetQ.X;
    TargetQ.Y := -TargetQ.Y;
    TargetQ.Z := -TargetQ.Z;
    TargetQ.W := -TargetQ.W;
  end;

  if Dot > 0.9995 then
  begin
    // Linear interpolation if very close
    Result.X := Q1.X + T * (TargetQ.X - Q1.X);
    Result.Y := Q1.Y + T * (TargetQ.Y - Q1.Y);
    Result.Z := Q1.Z + T * (TargetQ.Z - Q1.Z);
    Result.W := Q1.W + T * (TargetQ.W - Q1.W);
    Result := QuaternionNormalize(Result);
    Exit;
  end;

  Theta := ArcCos(Dot);
  SinTheta := Sin(Theta);
  Scale1 := Sin((1.0 - T) * Theta) / SinTheta;
  Scale2 := Sin(T * Theta) / SinTheta;

  Result.X := Single(Scale1 * Q1.X + Scale2 * TargetQ.X);
  Result.Y := Single(Scale1 * Q1.Y + Scale2 * TargetQ.Y);
  Result.Z := Single(Scale1 * Q1.Z + Scale2 * TargetQ.Z);
  Result.W := Single(Scale1 * Q1.W + Scale2 * TargetQ.W);
  Result := QuaternionNormalize(Result);
end;

end.
