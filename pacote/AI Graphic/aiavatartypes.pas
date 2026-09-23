unit aiavatartypes;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  Tipos comuns, enums e funcoes de conversao para o Avatar 3D
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

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

end.
