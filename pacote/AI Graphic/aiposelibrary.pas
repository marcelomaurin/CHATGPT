unit aiposelibrary;

{ ============================================================================
  Maurinsoft CHATGPT - AI Graphic / 3D Avatar Subsystem
  TAIPoseLibrary: Sistema de Poses Base, Poses Padrao e Blending (Tarefas 38 a 40)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, aiavatartypes, aiskeletonrig, fpjson, jsonparser, LResources;

type
  { TAIPoseLibrary }

  TAIPoseLibrary = class(TAIBaseComponent)
  private
    FLibraryPath: string;
    FPoses: TAIAvatarPoseArray;
    
    procedure InitDefaultPoses;
    function MakeBonePose(ABone: TAIHumanoidBone; const AName: string; ARotX, ARotY, ARotZ: Double): TAIAvatarBonePose;
  public
    constructor Create(AOwner: TComponent); override;
    
    // Gerenciamento e Aplicacao de Poses (Tarefas 38 a 40)
    procedure SavePose(const APoseName: string; ARig: TAISkeletonRig);
    procedure LoadPose(const APoseName: string; ARig: TAISkeletonRig);
    procedure ApplyPose(const APoseName: string; ARig: TAISkeletonRig; Intensity: Single = 1.0);
    procedure BlendPoses(const APose1, APose2: string; Factor: Single; ARig: TAISkeletonRig);
    
    function FindPose(const APoseName: string; out APose: TAIAvatarPose): Boolean;
    procedure AddPose(const APose: TAIAvatarPose);
    procedure GetPoseNames(AList: TStrings);
    function GetPoseCount: Integer;

    // Persistencia em JSON
    procedure SaveLibraryToFile(const AFileName: string);
    procedure LoadLibraryFromFile(const AFileName: string);
  published
    property LibraryPath: string read FLibraryPath write FLibraryPath;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAIPoseLibrary]);
end;

{ TAIPoseLibrary }

constructor TAIPoseLibrary.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAIPoseLibrary manages base avatar poses, standard emotion/body presets, and weighted pose blending. Properties: LibraryPath. Methods: SavePose, LoadPose, ApplyPose, BlendPoses, SaveLibraryToFile, LoadLibraryFromFile.';
  FLibraryPath := '';
  SetLength(FPoses, 0);
  InitDefaultPoses;
  ClearError;
end;

function TAIPoseLibrary.MakeBonePose(ABone: TAIHumanoidBone; const AName: string; ARotX, ARotY, ARotZ: Double): TAIAvatarBonePose;
begin
  Result.HumanoidBone := ABone;
  Result.BoneName := AName;
  Result.RotX := ARotX;
  Result.RotY := ARotY;
  Result.RotZ := ARotZ;
  Result.PosX := 0.0;
  Result.PosY := 0.0;
  Result.PosZ := 0.0;
end;

procedure TAIPoseLibrary.InitDefaultPoses;
var
  NeutralPose, ListeningPose, ThinkingPose, ConcernedPose, ConfidentPose, RelaxedPose: TAIAvatarPose;
begin
  // 1. Pose: Neutral (Tarefa 39)
  NeutralPose.Name := 'Neutral';
  SetLength(NeutralPose.Bones, 5);
  NeutralPose.Bones[0] := MakeBonePose(hbHead, 'Head', 0.0, 0.0, 0.0);
  NeutralPose.Bones[1] := MakeBonePose(hbSpine, 'Spine', 0.0, 0.0, 0.0);
  NeutralPose.Bones[2] := MakeBonePose(hbChest, 'Chest', 0.0, 0.0, 0.0);
  NeutralPose.Bones[3] := MakeBonePose(hbLeftUpperArm, 'LeftUpperArm', 0.0, 0.0, 5.0);
  NeutralPose.Bones[4] := MakeBonePose(hbRightUpperArm, 'RightUpperArm', 0.0, 0.0, -5.0);
  AddPose(NeutralPose);

  // 2. Pose: Listening (Tarefa 39)
  ListeningPose.Name := 'Listening';
  SetLength(ListeningPose.Bones, 4);
  ListeningPose.Bones[0] := MakeBonePose(hbHead, 'Head', 6.0, 4.0, 0.0); // cabeca levemente inclinada
  ListeningPose.Bones[1] := MakeBonePose(hbNeck, 'Neck', 2.0, 0.0, 0.0);
  ListeningPose.Bones[2] := MakeBonePose(hbChest, 'Chest', -2.0, 0.0, 0.0);
  ListeningPose.Bones[3] := MakeBonePose(hbSpine, 'Spine', -1.0, 0.0, 0.0);
  AddPose(ListeningPose);

  // 3. Pose: Thinking (Tarefa 39)
  ThinkingPose.Name := 'Thinking';
  SetLength(ThinkingPose.Bones, 5);
  ThinkingPose.Bones[0] := MakeBonePose(hbHead, 'Head', -8.0, 10.0, -6.0); // olhar distante
  ThinkingPose.Bones[1] := MakeBonePose(hbRightUpperArm, 'RightUpperArm', 45.0, -10.0, 30.0); // braco elevado
  ThinkingPose.Bones[2] := MakeBonePose(hbRightLowerArm, 'RightLowerArm', 75.0, 0.0, 20.0);  // antebraco flexionado em direcao ao queixo
  ThinkingPose.Bones[3] := MakeBonePose(hbLeftUpperArm, 'LeftUpperArm', 5.0, 0.0, 8.0);
  ThinkingPose.Bones[4] := MakeBonePose(hbSpine, 'Spine', 2.0, 4.0, 0.0);
  AddPose(ThinkingPose);

  // 4. Pose: Concerned (Tarefa 39)
  ConcernedPose.Name := 'Concerned';
  SetLength(ConcernedPose.Bones, 4);
  ConcernedPose.Bones[0] := MakeBonePose(hbHead, 'Head', 10.0, 0.0, 0.0); // cabeca mais baixa
  ConcernedPose.Bones[1] := MakeBonePose(hbChest, 'Chest', 5.0, 0.0, 0.0); // peito retraido
  ConcernedPose.Bones[2] := MakeBonePose(hbLeftShoulder, 'LeftShoulder', -4.0, 0.0, 3.0);
  ConcernedPose.Bones[3] := MakeBonePose(hbRightShoulder, 'RightShoulder', -4.0, 0.0, -3.0);
  AddPose(ConcernedPose);

  // 5. Pose: Confident (Tarefa 39)
  ConfidentPose.Name := 'Confident';
  SetLength(ConfidentPose.Bones, 5);
  ConfidentPose.Bones[0] := MakeBonePose(hbHead, 'Head', -4.0, 0.0, 0.0); // cabeca erguida
  ConfidentPose.Bones[1] := MakeBonePose(hbChest, 'Chest', -6.0, 0.0, 0.0); // postura aberta
  ConfidentPose.Bones[2] := MakeBonePose(hbSpine, 'Spine', -3.0, 0.0, 0.0);
  ConfidentPose.Bones[3] := MakeBonePose(hbLeftUpperArm, 'LeftUpperArm', 0.0, 0.0, 12.0);
  ConfidentPose.Bones[4] := MakeBonePose(hbRightUpperArm, 'RightUpperArm', 0.0, 0.0, -12.0);
  AddPose(ConfidentPose);

  // 6. Pose: Relaxed (Tarefa 39)
  RelaxedPose.Name := 'Relaxed';
  SetLength(RelaxedPose.Bones, 4);
  RelaxedPose.Bones[0] := MakeBonePose(hbHead, 'Head', 2.0, 0.0, 3.0);
  RelaxedPose.Bones[1] := MakeBonePose(hbSpine, 'Spine', 3.0, 0.0, 2.0);
  RelaxedPose.Bones[2] := MakeBonePose(hbLeftUpperArm, 'LeftUpperArm', 0.0, 0.0, 4.0);
  RelaxedPose.Bones[3] := MakeBonePose(hbRightUpperArm, 'RightUpperArm', 0.0, 0.0, -4.0);
  AddPose(RelaxedPose);
end;

procedure TAIPoseLibrary.AddPose(const APose: TAIAvatarPose);
var
  I, Idx: Integer;
begin
  // Substituir se ja existir com o mesmo nome
  for I := 0 to High(FPoses) do
  begin
    if SameText(FPoses[I].Name, APose.Name) then
    begin
      FPoses[I] := APose;
      Exit;
    end;
  end;

  Idx := Length(FPoses);
  SetLength(FPoses, Idx + 1);
  FPoses[Idx] := APose;
end;

function TAIPoseLibrary.FindPose(const APoseName: string; out APose: TAIAvatarPose): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FPoses) do
  begin
    if SameText(FPoses[I].Name, APoseName) then
    begin
      APose := FPoses[I];
      Result := True;
      Exit;
    end;
  end;
end;

procedure TAIPoseLibrary.GetPoseNames(AList: TStrings);
var
  I: Integer;
begin
  if AList = nil then Exit;
  AList.Clear;
  for I := 0 to High(FPoses) do
    AList.Add(FPoses[I].Name);
end;

function TAIPoseLibrary.GetPoseCount: Integer;
begin
  Result := Length(FPoses);
end;

procedure TAIPoseLibrary.SavePose(const APoseName: string; ARig: TAISkeletonRig);
var
  NewPose: TAIAvatarPose;
  Count, I: Integer;
  Joint: TBoneJoint;
begin
  if not Assigned(ARig) then
  begin
    SetError('Skeleton rig not assigned.');
    Exit;
  end;

  Count := ARig.GetJointCount;
  NewPose.Name := APoseName;
  SetLength(NewPose.Bones, Count);

  for I := 0 to Count - 1 do
  begin
    Joint := ARig.GetJoint(I);
    NewPose.Bones[I].BoneName := Joint.Name;
    NewPose.Bones[I].HumanoidBone := StringToHumanoidBone(Joint.Name);
    NewPose.Bones[I].RotX := Joint.AngleX;
    NewPose.Bones[I].RotY := Joint.AngleY;
    NewPose.Bones[I].RotZ := Joint.AngleZ;
    NewPose.Bones[I].PosX := Joint.OffsetX;
    NewPose.Bones[I].PosY := Joint.OffsetY;
    NewPose.Bones[I].PosZ := Joint.OffsetZ;
  end;

  AddPose(NewPose);
  Log(llInfo, Format('Pose "%s" saved with %d bones.', [APoseName, Count]));
  FLastResult := 'Pose saved: ' + APoseName;
  FLastSuccess := True;
end;

procedure TAIPoseLibrary.LoadPose(const APoseName: string; ARig: TAISkeletonRig);
begin
  ApplyPose(APoseName, ARig, 1.0);
end;

procedure TAIPoseLibrary.ApplyPose(const APoseName: string; ARig: TAISkeletonRig; Intensity: Single);
var
  Pose: TAIAvatarPose;
  I: Integer;
  BoneName: string;
  EffectiveWeight: Double;
begin
  if not Assigned(ARig) then
  begin
    SetError('Skeleton rig not assigned.');
    Exit;
  end;

  if not FindPose(APoseName, Pose) then
  begin
    SetError('Pose not found: ' + APoseName);
    Exit;
  end;

  // Clampar intensidade entre 0.0 e 1.0 (Tarefa 40)
  if Intensity < 0.0 then Intensity := 0.0;
  if Intensity > 1.0 then Intensity := 1.0;
  EffectiveWeight := Intensity;

  for I := 0 to High(Pose.Bones) do
  begin
    BoneName := Pose.Bones[I].BoneName;
    // Se mapeado para osso humanoide, resolve pelo mapeador do rig
    if (Pose.Bones[I].HumanoidBone <> hbNone) and ARig.HasHumanoidBone(Pose.Bones[I].HumanoidBone) then
      BoneName := ARig.GetMappedBoneName(Pose.Bones[I].HumanoidBone);

    if BoneName <> '' then
    begin
      ARig.SetBoneRotation(BoneName,
        Pose.Bones[I].RotX * EffectiveWeight,
        Pose.Bones[I].RotY * EffectiveWeight,
        Pose.Bones[I].RotZ * EffectiveWeight);
    end;
  end;

  ARig.UpdateFK;
  Log(llInfo, Format('Applied pose "%s" with intensity %.2f.', [APoseName, Intensity]));
  FLastResult := 'Pose applied: ' + APoseName;
  FLastSuccess := True;
end;

procedure TAIPoseLibrary.BlendPoses(const APose1, APose2: string; Factor: Single; ARig: TAISkeletonRig);
var
  P1, P2: TAIAvatarPose;
  I, J: Integer;
  BoneName: string;
  R1X, R1Y, R1Z, R2X, R2Y, R2Z: Double;
  BlendedX, BlendedY, BlendedZ: Double;
  FoundP2: Boolean;
begin
  if not Assigned(ARig) then
  begin
    SetError('Skeleton rig not assigned.');
    Exit;
  end;

  if not FindPose(APose1, P1) then
  begin
    SetError('Blend pose 1 not found: ' + APose1);
    Exit;
  end;

  if not FindPose(APose2, P2) then
  begin
    SetError('Blend pose 2 not found: ' + APose2);
    Exit;
  end;

  if Factor < 0.0 then Factor := 0.0;
  if Factor > 1.0 then Factor := 1.0;

  for I := 0 to High(P1.Bones) do
  begin
    BoneName := P1.Bones[I].BoneName;
    if (P1.Bones[I].HumanoidBone <> hbNone) and ARig.HasHumanoidBone(P1.Bones[I].HumanoidBone) then
      BoneName := ARig.GetMappedBoneName(P1.Bones[I].HumanoidBone);

    R1X := P1.Bones[I].RotX;
    R1Y := P1.Bones[I].RotY;
    R1Z := P1.Bones[I].RotZ;

    R2X := 0.0; R2Y := 0.0; R2Z := 0.0;
    FoundP2 := False;
    for J := 0 to High(P2.Bones) do
    begin
      if (P2.Bones[J].HumanoidBone = P1.Bones[I].HumanoidBone) or SameText(P2.Bones[J].BoneName, BoneName) then
      begin
        R2X := P2.Bones[J].RotX;
        R2Y := P2.Bones[J].RotY;
        R2Z := P2.Bones[J].RotZ;
        FoundP2 := True;
        Break;
      end;
    end;

    if not FoundP2 then
    begin
      R2X := R1X; R2Y := R1Y; R2Z := R1Z;
    end;

    BlendedX := R1X + Factor * (R2X - R1X);
    BlendedY := R1Y + Factor * (R2Y - R1Y);
    BlendedZ := R1Z + Factor * (R2Z - R1Z);

    if BoneName <> '' then
      ARig.SetBoneRotation(BoneName, BlendedX, BlendedY, BlendedZ);
  end;

  ARig.UpdateFK;
  Log(llInfo, Format('Blended poses "%s" and "%s" with factor %.2f.', [APose1, APose2, Factor]));
  FLastResult := Format('Blended poses %s and %s (%.2f)', [APose1, APose2, Factor]);
  FLastSuccess := True;
end;

procedure TAIPoseLibrary.SaveLibraryToFile(const AFileName: string);
var
  Doc: TJSONObject;
  PosesArr, BonesArr: TJSONArray;
  PoseObj, BoneObj: TJSONObject;
  I, J: Integer;
  SL: TStringList;
begin
  Doc := TJSONObject.Create;
  PosesArr := TJSONArray.Create;
  try
    for I := 0 to High(FPoses) do
    begin
      PoseObj := TJSONObject.Create;
      PoseObj.Add('name', FPoses[I].Name);
      BonesArr := TJSONArray.Create;

      for J := 0 to High(FPoses[I].Bones) do
      begin
        BoneObj := TJSONObject.Create;
        BoneObj.Add('bone', FPoses[I].Bones[J].BoneName);
        BoneObj.Add('humanoid', HumanoidBoneToString(FPoses[I].Bones[J].HumanoidBone));
        BoneObj.Add('rx', FPoses[I].Bones[J].RotX);
        BoneObj.Add('ry', FPoses[I].Bones[J].RotY);
        BoneObj.Add('rz', FPoses[I].Bones[J].RotZ);
        BonesArr.Add(BoneObj);
      end;

      PoseObj.Add('bones', BonesArr);
      PosesArr.Add(PoseObj);
    end;

    Doc.Add('poses', PosesArr);

    SL := TStringList.Create;
    try
      SL.Text := Doc.FormatJSON();
      SL.SaveToFile(AFileName);
      Log(llInfo, 'Saved pose library to: ' + AFileName);
    finally
      SL.Free;
    end;
  finally
    Doc.Free;
  end;
end;

procedure TAIPoseLibrary.LoadLibraryFromFile(const AFileName: string);
var
  Parser: TJSONParser;
  Data: TJSONData;
  Doc, PoseObj, BoneObj: TJSONObject;
  PosesArr, BonesArr: TJSONArray;
  I, J: Integer;
  SL: TStringList;
  NewPose: TAIAvatarPose;
begin
  if not FileExists(AFileName) then
  begin
    SetError('File not found: ' + AFileName);
    Exit;
  end;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    Parser := TJSONParser.Create(SL.Text);
    try
      Data := Parser.Parse;
      if (Data <> nil) and (Data is TJSONObject) then
      begin
        Doc := TJSONObject(Data);
        PosesArr := Doc.Get('poses', TJSONArray(nil));
        if PosesArr <> nil then
        begin
          for I := 0 to PosesArr.Count - 1 do
          begin
            PoseObj := PosesArr.Objects[I];
            NewPose.Name := PoseObj.Get('name', '');
            BonesArr := PoseObj.Get('bones', TJSONArray(nil));
            if BonesArr <> nil then
            begin
              SetLength(NewPose.Bones, BonesArr.Count);
              for J := 0 to BonesArr.Count - 1 do
              begin
                BoneObj := BonesArr.Objects[J];
                NewPose.Bones[J].BoneName := BoneObj.Get('bone', '');
                NewPose.Bones[J].HumanoidBone := StringToHumanoidBone(BoneObj.Get('humanoid', ''));
                NewPose.Bones[J].RotX := BoneObj.Get('rx', 0.0);
                NewPose.Bones[J].RotY := BoneObj.Get('ry', 0.0);
                NewPose.Bones[J].RotZ := BoneObj.Get('rz', 0.0);
                NewPose.Bones[J].PosX := 0.0;
                NewPose.Bones[J].PosY := 0.0;
                NewPose.Bones[J].PosZ := 0.0;
              end;
            end
            else
              SetLength(NewPose.Bones, 0);

            AddPose(NewPose);
          end;
        end;
        Log(llInfo, Format('Loaded %d poses from %s', [Length(FPoses), AFileName]));
      end;
    finally
      if Assigned(Data) then Data.Free;
      Parser.Free;
    end;
  finally
    SL.Free;
  end;
end;

initialization
  {$I aiposelibrary_icon.lrs}

end.
